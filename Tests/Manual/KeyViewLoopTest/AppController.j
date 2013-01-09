/*
 * AppController.j
 * KeyViewLoopTest
 *
 * Created by You on January 7, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    @outlet CPWindow customNoInitial;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    [customNoInitial makeKeyAndOrderFront:self];
}

@end


@implementation MyWindow : CPWindow

- (@action)addField:(id)sender
{
    var field = [CPTextField textFieldWithStringValue:@"" placeholder:@"" width:96];

    [field setFrameOrigin:CGPointMake(43, 135)];
    [[self contentView] addSubview:field];

    [sender setEnabled:NO];
    [self makeFirstResponder:[[self contentView] viewWithTag:1]];
}

- (@action)recalc:(id)sender
{
    [self recalculateKeyViewLoop];
    [self makeFirstResponder:[[self contentView] viewWithTag:1]];
}

@end
