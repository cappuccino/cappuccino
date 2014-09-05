/*
 * AppController.j
 * CPTextFieldEditingStyleTest
 *
 * Created by Alexandre Wilhelm on June 9, 2014.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;
    @outlet CPTextField textField;
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
    [textField setPlaceholderString:@"I'm a nice placeholder"];
    [theWindow setFullPlatformWindow:YES];
}

- (IBAction)changeStyle:(id)sender
{
    [textField setTextColor:[CPColor redColor]];
    [textField setFont:[CPFont boldSystemFontOfSize:10]];
    [textField setAlignment:CPRightTextAlignment];
}

@end
