/*
 * AppController.j
 * CPTextFieldMovementsTest
 *
 * Created by Alexandre Wilhelm on October 29, 2013.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import "CustomTextField.j"

@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
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

- (void)controlTextDidEndEditing:(CPNotification)aNotification
{
    var movement = [[aNotification userInfo] valueForKey:@"CPTextMovement"];

    console.log("controlTextDidEndEditing");

    switch (movement)
    {
        case CPCancelTextMovement:
            console.log(@"CPCancelTextMovement");
            break;

        case CPLeftTextMovement:
            console.log(@"CPLeftTextMovement");
            break;

        case CPRightTextMovement:
            console.log(@"CPRightTextMovement");
            break;

        case CPUpTextMovement:
            console.log(@"CPUpTextMovement");
            break;

        case CPDownTextMovement:
            console.log(@"CPDownTextMovement");
            break;

        case CPReturnTextMovement:
            console.log(@"CPReturnTextMovement");
            break;

        case CPBacktabTextMovement:
            console.log(@"CPBacktabTextMovement");
            break;

        case CPTabTextMovement:
            console.log(@"CPTabTextMovement");
            break;

        case CPOtherTextMovement:
            console.log(@"CPOtherTextMovement");
            break;
    }
}

@end
