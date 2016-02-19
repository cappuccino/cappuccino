/*
 * AppController.j
 * CPTextFieldTest
 *
 * Created by You on February 18, 2016.
 * Copyright 2016, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "CPResponder+Cucapp.j"

@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
    @outlet CPTextField textField;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
    [textField setCucappIdentifier:@"text-field-cucapp-identifier"];
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

@end
