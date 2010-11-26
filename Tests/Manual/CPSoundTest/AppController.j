/*
 * AppController.j
 * CPSoundTest
 *
 * Created by Alexander Ljungberg on November 18, 2010.
 * Copyright 2010, WireLoad, LLC All rights reserved.
 */

@import <Foundation/CPObject.j>

@implementation AppController : CPObject
{
    CPSound theSound;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],

        label = [[CPTextField alloc] initWithFrame:CGRectMake(15, 15, 500, 24)],
        button = [[CPButton alloc] initWithFrame:CGRectMake(15, 40, 100, 30)],
        repeatButton = [[CPButton alloc] initWithFrame:CGRectMake(110, 40, 100, 30)];

    [label setStringValue:"Use the buttons to play a an echoy blippy sound."];
    [contentView addSubview:label];

    [button setTitle:"Play Cyber-jump-powerup Sound"];
    [button sizeToFit];

    var path = [[CPBundle bundleForClass:[self class]] pathForResource:@"31822_ihatetoregister_blip.mp3"];
    theSound = [[CPSound alloc] initWithContentsOfFile:path byReference:NO];

    [button setTarget:theSound];
    [button setAction:@selector(play)];
    [contentView addSubview:button];

    [repeatButton setTitle:"Toggle Looping"];
    [repeatButton sizeToFit];
    [repeatButton setTarget:self];
    [repeatButton setAction:@selector(toggleRepeat:)];
    [repeatButton setFrameOrigin:CGPointMake(CGRectGetMaxX([button frame]) + 15, 40)];

    [contentView addSubview:repeatButton];

    [theWindow orderFront:self];

}

- (void)toggleRepeat:(id)sender
{
    if ([theSound loops])
    {
        [theSound stop];
        [theSound setLoops:NO];
    }
    else
    {
        [theSound setLoops:YES];
    }
}

@end
