/*
 * AppController.j
 * CPStepperNibTest
 *
 * Created by cacaodev on February 7, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet CPStepper stepper;
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
    var contentView = [theWindow contentView];

    [[contentView viewWithTag:1000] setIntValue:[stepper increment]];
    [[contentView viewWithTag:1001] setIntValue:[stepper minValue]];
    [[contentView viewWithTag:1002] setIntValue:[stepper maxValue]];
    [[contentView viewWithTag:1003] setState:[stepper valueWraps] ? CPOnState : CPOffState];
    [[contentView viewWithTag:1005] setState:[stepper autorepeat] ? CPOnState : CPOffState];
    [[contentView viewWithTag:1004] setIntValue:[stepper objectValue]];

    [theWindow setFullPlatformWindow:YES];
}

- (IBAction)setWraps:(id)sender
{
    [stepper setValueWraps:[sender state]];
}

- (IBAction)setMin:(id)sender
{
    [stepper setMinValue:[sender intValue]];
}

- (IBAction)setMax:(id)sender
{
    [stepper setMaxValue:[sender intValue]];
}

- (IBAction)setIncrement:(id)sender
{
    [stepper setIncrement:[sender intValue]];
}

- (IBAction)setAutorepeat:(id)sender
{
    [stepper setAutorepeat:[sender state]];
}

@end
