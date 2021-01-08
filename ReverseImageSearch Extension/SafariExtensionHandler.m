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
    NSString *search_uri = [self getSearchEngineString:command];
    // it turns out using URLQueryAllowedCharacterSet doesn't actually percent-encode for some reason.  Go figure.
    image_uri = [image_uri stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    if (search_uri)
    {
        search_uri = [NSString stringWithFormat:search_uri, image_uri];
        [page getContainingTabWithCompletionHandler:^(SFSafariTab * _Nonnull tab) {
            [tab getContainingWindowWithCompletionHandler:^(SFSafariWindow * _Nullable window) {
                NSUserDefaults *defaults = [self userDefaults:[self createAppDefaults]];
                BOOL result_in_background = [defaults boolForKey:@"prefResultInBackground"];
                NSLog(@"result in background:  %d", result_in_background);
                [window openTabWithURL:[NSURL URLWithString:search_uri] makeActiveIfPossible:!result_in_background completionHandler:^(SFSafariTab * _Nullable tab) {
                    // do nothing
                }];
            }];
        }];
//        [SFSafariApplication getActiveWindowWithCompletionHandler:^(SFSafariWindow * _Nullable activeWindow) {
//            [activeWindow openTabWithURL:[NSURL URLWithString:search_uri] makeActiveIfPossible:YES completionHandler:^(SFSafariTab *tab) {
//                NSLog(@"Page opened");
//            }];
//        }];
    }

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
