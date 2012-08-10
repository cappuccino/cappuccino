//
//  AppDelegate.m
//  TestSheet
//
//  Created by Joe Semolian on 4/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "SheetWindowController.h"

@implementation AppController

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSLog(@"[%@ %s]", [self className], sel_getName(_cmd));

    // Insert code here to initialize your application
    _sheetController = [[SheetWindowController alloc] initWithWindowNibName:@"Window"];
                        
    [_sheetController newWindow:self];
}

- (void)newDocument:(id)sender
{
    [_sheetController newWindow:sender];
}

@end
