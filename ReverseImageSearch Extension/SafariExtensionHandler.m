//
//  SafariExtensionHandler.m
//  ReverseImageSearch Extension
//
//  Created by Yiming Liu on 12/18/18.
//  Copyright © 2018 Yiming Liu. All rights reserved.
//

#import "SafariExtensionHandler.h"
#import "SafariExtensionViewController.h"

@interface SafariExtensionHandler ()

@end

@implementation SafariExtensionHandler

- (void)messageReceivedWithName:(NSString *)messageName fromPage:(SFSafariPage *)page userInfo:(NSDictionary *)userInfo {
    // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
//    [page getPagePropertiesWithCompletionHandler:^(SFSafariPageProperties *properties) {
//        NSLog(@"The extension received a message (%@) from a script injected into (%@) with userInfo (%@)", messageName, properties.url, userInfo);
//    }];
}

//- (void)toolbarItemClickedInWindow:(SFSafariWindow *)window {
//    // This method will be called when your toolbar item is clicked.
//    NSLog(@"The extension's toolbar item was clicked");
//}

//- (void)validateToolbarItemInWindow:(SFSafariWindow *)window validationHandler:(void (^)(BOOL enabled, NSString *badgeText))validationHandler {
//    // This method will be called whenever some state changes in the passed in window. You should use this as a chance to enable or disable your toolbar item and set badge text.
//    validationHandler(YES, nil);
//}

- (void)validateContextMenuItemWithCommand:(NSString *)command inPage:(SFSafariPage *)page userInfo:(NSDictionary<NSString *,id> *)userInfo validationHandler:(void (^)(BOOL shouldHide, NSString *text))validationHandler
{
    NSDictionary *search_engines = [self searchEngines];
    NSString* search_engine_path = [search_engines objectForKey:command];
    NSUserDefaults *defaults = [self userDefaults:[self createAppDefaults]];
    BOOL is_active = [defaults boolForKey:command];
    if (search_engine_path && is_active)
    {
        NSString *target_uri = [userInfo objectForKey:@"uri"];
        if (target_uri)
            validationHandler(NO, nil);
        else
            validationHandler(YES, nil);
    }
    else
    {
        validationHandler(YES, nil);
    }
}

- (NSString *)getSearchEngineString:(NSString *)name
{
    NSDictionary *search_engines = [self searchEngines];
    NSString* search_engine_path = [search_engines objectForKey:name];
    return search_engine_path;
}

- (void)contextMenuItemSelectedWithCommand:(NSString *)command
                                    inPage:(SFSafariPage *)page userInfo:(NSDictionary<NSString *, id> *)userInfo
{
    NSString *image_uri = [userInfo valueForKey:@"uri"];
    if (!image_uri)
        return;

    // ukiyo-e.org no longer accepts a GET search URL.  Image-URL search is now a
    // multipart POST that returns a JSON results path, which we then open in a tab.
    if ([command isEqualToString:@"ukiyo-e"])
    {
        [self searchUkiyoEWithImageURI:image_uri inPage:page];
        return;
    }

    NSString *search_uri = [self getSearchEngineString:command];
    // it turns out using URLQueryAllowedCharacterSet doesn't actually percent-encode for some reason.  Go figure.
    NSString *encoded_uri = [image_uri stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    if (search_uri)
    {
        search_uri = [NSString stringWithFormat:search_uri, encoded_uri];
        [self openURL:[NSURL URLWithString:search_uri] inPage:page];
    }
}

// ukiyo-e.org image search: POST the raw image URL as multipart/form-data, then
// open the results page returned in the JSON response.  This runs in native code
// via NSURLSession, so it is not subject to browser CORS restrictions.
- (void)searchUkiyoEWithImageURI:(NSString *)image_uri inPage:(SFSafariPage *)page
{
    NSString *endpoint = [self getSearchEngineString:@"ukiyo-e"];
    NSURL *url = endpoint ? [NSURL URLWithString:endpoint] : nil;
    if (!url)
        return;

    NSString *boundary = @"----ReverseImageSearchBoundary";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
   forHTTPHeaderField:@"Content-Type"];

    NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"url\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[image_uri dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    request.HTTPBody = body;

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data)
        {
            NSLog(@"ReverseImageSearch: ukiyo-e POST failed: %@", error);
            return;
        }
        NSError *json_error = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&json_error];
        if (![json isKindOfClass:[NSDictionary class]])
        {
            NSLog(@"ReverseImageSearch: ukiyo-e response was not JSON: %@", json_error);
            return;
        }
        // The response is remote and untrusted: validate the JSON shape before
        // using it, so an unexpected type (e.g. a number or object) cannot crash us.
        id status = [json objectForKey:@"status"];
        id results = [json objectForKey:@"results"];
        if (![status isKindOfClass:[NSString class]] ||
            ![results isKindOfClass:[NSString class]] ||
            ![(NSString *)status isEqualToString:@"SUCCESS"] ||
            [(NSString *)results length] == 0)
        {
            NSLog(@"ReverseImageSearch: ukiyo-e search was unsuccessful: %@", json);
            return;
        }
        NSURL *results_url = [NSURL URLWithString:(NSString *)results relativeToURL:url];
        if (!results_url)
        {
            NSLog(@"ReverseImageSearch: ukiyo-e returned an invalid results path: %@", results);
            return;
        }
        // URLWithString:relativeToURL: ignores the base when results is absolute,
        // so an off-site value (e.g. https://evil.com) would otherwise be opened.
        // Restrict results to the configured endpoint's host over https.  Deriving
        // the host from the (trusted, local) endpoint avoids drift if the plist
        // changes, and fails safe: a nil host rejects every candidate.
        if (![results_url.scheme isEqualToString:@"https"] ||
            ![results_url.host isEqualToString:url.host])
        {
            NSLog(@"ReverseImageSearch: ukiyo-e returned an off-site results URL: %@", results_url);
            return;
        }
        [self openURL:results_url inPage:page];
    }];
    [task resume];
}

- (void)openURL:(NSURL *)url inPage:(SFSafariPage *)page
{
    if (!url)
        return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [page getContainingTabWithCompletionHandler:^(SFSafariTab * _Nonnull tab) {
            [tab getContainingWindowWithCompletionHandler:^(SFSafariWindow * _Nullable window) {
                NSUserDefaults *defaults = [self userDefaults:[self createAppDefaults]];
                BOOL result_in_background = [defaults boolForKey:@"prefResultInBackground"];
                [window openTabWithURL:url makeActiveIfPossible:!result_in_background completionHandler:^(SFSafariTab * _Nullable tab) {
                    // do nothing
                }];
            }];
        }];
    });
}

- (SFSafariExtensionViewController *)popoverViewController {
    return [SafariExtensionViewController sharedController];
}

- (NSDictionary *)searchEngines
{
    static NSDictionary *search_engines;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [[NSBundle mainBundle] pathForResource:@"search_engines" ofType:@"plist"];
        search_engines = [NSDictionary dictionaryWithContentsOfFile:path];
    });
    return search_engines;
}

- (NSUserDefaults *)userDefaults:(NSDictionary *)appDefaults
{
    NSUserDefaults* defaults = [[NSUserDefaults alloc] initWithSuiteName:@"XLREUF5H62.groups.reverseimagesearch"];
    [defaults registerDefaults:appDefaults];
    return defaults;
}

- (NSDictionary *)createAppDefaults
{
    NSDictionary *searchEngines = [self searchEngines];
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
    for (NSString *key in searchEngines)
    {
        [appDefaults setValue:@YES forKey:key];
    }
    [appDefaults setValue:@NO forKey:@"prefResultInBackground"];
    return appDefaults;
}

@end
