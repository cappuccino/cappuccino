/*
 * AppController.j
 * RuntimeAttributesTest
 *
 * Created by aparajita on March 26, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    CPView      firstResponder;
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
    //[theWindow setFullPlatformWindow:YES];
}

- (void)setInitialResponder:(CPInteger)tag
{
    [theWindow setInitialFirstResponder:[[theWindow contentView] viewWithTag:tag]];
}

- (void)setValue:(id)value forUndefinedKey:(CPString)key
{
    console.log("setValue:" + value + " forKey:" + key);
}

@end
