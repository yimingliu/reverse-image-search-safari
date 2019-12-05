//
//  ViewController.m
//  ReverseImageSearch
//
//  Created by Yiming Liu on 11/29/19.
//  Copyright © 2019 Yiming Liu. All rights reserved.
//

#import "ViewController.h"
#import <SafariServices/SFSafariApplication.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.appNameLabel.stringValue = @"ReverseImageSearch";
    
    NSDictionary *appDefaults = [self createAppDefaults];
    NSUserDefaults* defaults = [self userDefaults:appDefaults];
    NSUserDefaultsController *defaultsController = [[NSUserDefaultsController alloc] initWithDefaults:defaults initialValues:appDefaults];
    NSArray *keys = [appDefaults allKeys];
    keys = [keys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString* key in keys)
    {
        NSButton* checkbox = [NSButton checkboxWithTitle:key target:nil action:nil];
        [checkbox bind:@"value"
                           toObject:defaultsController
                   withKeyPath:[NSString stringWithFormat:@"values.%@", key]
                   options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"NSContinuouslyUpdatesValue"]];
        [self.stackView addArrangedSubview:checkbox];
    }
}

- (IBAction)openSafariExtensionPreferences:(id)sender {
    [SFSafariApplication showPreferencesForExtensionWithIdentifier:@"com.yimingliu.ReverseImageSearchExt" completionHandler:^(NSError * _Nullable error) {
        if (error) {
            // Insert code to inform the user something went wrong.
        }
    }];
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
    return appDefaults;
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

@end
