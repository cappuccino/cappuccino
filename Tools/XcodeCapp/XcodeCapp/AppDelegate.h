//
//  AppDelegate.h
//  XcodeCapp
//
//  Created by Alexandre Wilhelm on 5/5/15.
//  Copyright (c) 2015 cappuccino-project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>

@class XCCMainController;


@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSMenu                         *statusMenu;
    IBOutlet NSUserDefaultsController       *preferencesController;
    IBOutlet NSPanel                        *aboutWindow;
    IBOutlet NSWindow                       *preferencesWindow;

    NSImage                                 *imageStatusInactive;
    NSImage                                 *imageStatusProcessing;
    NSImage                                 *imageStatusError;
    NSStatusItem                            *statusItem;
}

@property IBOutlet  XCCMainController       *mainWindowController;
@property NSOperationQueue                  *mainOperationQueue;
@property NSString                          *version;

- (IBAction)openAbout:(id)aSender;
- (IBAction)openPreferences:(id)aSender;

@end