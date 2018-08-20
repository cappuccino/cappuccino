/*
 * AppController.j
 * PopUpButtonTest
 *
 * Created by Glenn L. Austin on June 26, 2013.
 * Copyright 2013, Austin-Soft.com All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
	@outlet CPButton	clearButton;
	@outlet CPButton	escButton;
	@outlet CPTextField	wasPressedLabel;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

- (@action)clearButtonPressed:(id)sender {
	[wasPressedLabel setStringValue:@"No"];
}

- (@action)escButtonPressed:(id)sender {
	[wasPressedLabel setStringValue:@"Yes"];
}

@end
