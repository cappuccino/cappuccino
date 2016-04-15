/*
 * AppController.j
 * CPAnimatableControls
 *
 * Created by You on March 4, 2015.
 * Copyright 2015, Your Company All rights reserved.
 */
CPLogRegister(CPLogConsole);
@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@class CPAnimationContext

@implementation AppController : CPObject
{
    @outlet CPWindow           theWindow;
    @outlet CPButton           button;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
}

- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];
}

- (@action)setButtonTextColor:(id)sender
{
    [[CPAnimationContext currentContext] setDuration:1];
    [[button animator] setTextColor:[CPColor redColor]];
}

- (@action)setButtonFont:(id)sender
{
    [[CPAnimationContext currentContext] setDuration:2];
    [[button animator] setFont:[CPFont boldFontWithName:@"Monaco" size:14 italic:YES]];
}

- (@action)setButtonFontSize:(id)sender
{
    [[CPAnimationContext currentContext] setDuration:0.5];
    [[button animator] setFontSize:22];
}

@end
