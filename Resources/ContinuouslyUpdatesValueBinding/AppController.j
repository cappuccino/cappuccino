/*
 * CPContinuouslyUpdatesValueBindingAppDelegate.j
 * BindingContiniouslyUpdatesValue
 *
 * Created by Alexander Ljungberg on March 27, 2011.
 * Copyright 2011, WireLoad All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation CPContinuouslyUpdatesValueBindingAppDelegate : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib

    CPTextField textFieldA;
    CPTextField textFieldB;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
    console.log(textFieldA);
    var binderClass = [[textFieldA class] _binderClassForBinding:CPValueBinding],
        theBinding = [binderClass getBinding:CPValueBinding forObject:textFieldA];
    console.log(theBinding);
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
