//
//  ViewController.h
//  ReverseImageSearch
//
//  Created by Yiming Liu on 11/29/19.
//  Copyright © 2019 Yiming Liu. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (weak, nonatomic) IBOutlet NSTextField * appNameLabel;
@property (weak, nonatomic) IBOutlet NSStackView * stackView;
@property (weak, nonatomic) IBOutlet NSButton * prefOpenBackground;

- (IBAction)openSafariExtensionPreferences:(id)sender;

@end

