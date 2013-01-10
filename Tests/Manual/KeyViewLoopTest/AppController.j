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
    @outlet CPWindow keyWindow;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    [keyWindow makeKeyAndOrderFront:self];
}

@end


@implementation MyWindow : CPWindow

- (@action)addField:(id)sender
{
    var field = [CPTextField textFieldWithStringValue:@"" placeholder:@"" width:96];

    [field setFrameOrigin:CGPointMake(20, 120)];
    [[self contentView] addSubview:field];

    [sender setEnabled:NO];
}

- (@action)recalc:(id)sender
{
    [self recalculateKeyViewLoop];
}

@end
