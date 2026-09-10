/*
 * AppController.j
 *
 * Created by __Me__ on __Date__.
 * Copyright 2008 __MyCompanyName__. All rights reserved.
 */

CPLogRegister(CPLogConsole);

@import <Foundation/CPObject.j>
@import <AppKit/CPObjectController.j>

@implementation AppController : CPObject
{
    CPSlider       slider;
    CPTextField    textField;

    Track          track @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    textField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

    [textField setAlignment:CPCenterTextAlignment];
    [textField setStringValue:@"Hello World!"];
    [textField setFont:[CPFont boldSystemFontOfSize:24.0]];

    [textField sizeToFit];

    [textField setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [textField setFrameOrigin:CGPointMake((CGRectGetWidth([contentView bounds]) - CGRectGetWidth([textField frame])) / 2.0, (CGRectGetHeight([contentView bounds]) - CGRectGetHeight([textField frame])) / 2.0)];

    [contentView addSubview:textField];

    var textFrame = [textField frame];

    slider = [[CPSlider alloc] initWithFrame:CGRectMake(CGRectGetMinX(textFrame), CGRectGetMaxY(textFrame)+10, CGRectGetWidth(textFrame), 12)];

    [slider setContinuous:YES];

    [contentView addSubview:slider];

    var button = [[CPButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(textFrame)+25, CGRectGetMaxY(textFrame)+40, 100, 18)];

    [button setTitle:@"mute"];

    [button setTarget:self];
    [button setAction:@selector(muteTrack:)];

    [contentView addSubview:button];


    track = [[Track alloc] init];
    [track setVolume:5.0];


    //SET UP AN OBJECT CONTROLLER

    var controller = [[CPObjectController alloc] init];
    [controller bind:@"contentObject" toObject:self withKeyPath:@"track" options:nil];

    [textField bind:CPValueBinding toObject:controller withKeyPath:@"selection.volume" options:nil];
    [slider bind:CPValueBinding toObject:controller withKeyPath:@"selection.volume" options:nil];

    [theWindow orderFront:self];
}

- (IBAction)muteTrack:(id)sender
{
    [track setVolume:0.0];
}


@end


@implementation Track : CPObject
{
    float      volume @accessors;
    CPString   title @accessors;
}

@end
