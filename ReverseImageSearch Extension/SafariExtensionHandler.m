//
//  SafariExtensionHandler.m
//  ReverseImageSearch Extension
//
//  Created by Yiming Liu on 12/18/18.
//  Copyright © 2018 Yiming Liu. All rights reserved.
//

#import "SafariExtensionHandler.h"
#import "SafariExtensionViewController.h"

NSString *const GOOGLE_BASE_URI = @"https://www.google.com/searchbyimage?image_url=%@";
NSString *const BING_BASE_URI = @"https://www.bing.com/images/search?q=imgurl:%@&view=detailv2&selectedIndex=0&pageurl=&mode=ImageViewer&iss=sbi";

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
    
    NSString *target_uri = [userInfo valueForKey:@"uri"];
    //NSLog(@"Got to here with 2 %@ %@ %@", entity_id, id_type, site);
    if ([command isEqualToString:@"search-google"] || [command isEqualToString:@"search-bing"])
    {
        //NSLog(@"URI %@", target_uri);
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

- (void)contextMenuItemSelectedWithCommand:(NSString *)command
                                    inPage:(SFSafariPage *)page userInfo:(NSDictionary<NSString *, id> *)userInfo
{
    NSString *image_uri = [userInfo valueForKey:@"uri"];
    NSString *search_uri = NULL;
    // it turns out using URLQueryAllowedCharacterSet doesn't actually percent-encode for some reason.  Go figure.
    image_uri = [image_uri stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    if ([command isEqualToString:@"search-google"] && image_uri)
    {
        search_uri = [NSString stringWithFormat:GOOGLE_BASE_URI, image_uri];
    }
    else if ([command isEqualToString:@"search-bing"] && image_uri)
    {
        search_uri = [NSString stringWithFormat:BING_BASE_URI, image_uri];
    }
    //    NSLog(@"Image URI:  %@", image_uri);
    //    NSLog(@"Search URI:  %@", search_uri);
    if (search_uri)
    {
        [page getContainingTabWithCompletionHandler:^(SFSafariTab * _Nonnull tab) {
            [tab getContainingWindowWithCompletionHandler:^(SFSafariWindow * _Nullable window) {
                [window openTabWithURL:[NSURL URLWithString:search_uri] makeActiveIfPossible:YES completionHandler:^(SFSafariTab * _Nullable tab) {
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

@end
