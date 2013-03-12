/*
 * AppController.j
 * CPFlashviewTest
 *
 * Created by Blair Duncan on April 23, 2012.
 * Copyright 2012, SGL Studio, BBDO Toronto All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        flashView;

    flashView = [[CPFlashView alloc] initWithFrame:CGRectMake(0,0,320,240)],
    [flashView setFlashMovie:[CPFlashMovie flashMovieWithFile:@"http://flashjournalism.com/examples/airplane.swf"]];

    // note:
    // if both flashParams and flashVars are used flashParams must be setup first

    var flashParameters = @{};
    [flashVars setObject:@"SampleParam" forKey:"SampleParamKey"];
    [flashView setParameters:flashParameters];

    var flashVars = @{};
    [flashVars setObject:@"SampleVar" forKey:"SampleVarKey"];
    [flashView setFlashVars:flashVars];


    [flashView setCenter:[contentView center]];
    [contentView addSubview:flashView];
    [theWindow orderFront:self];
}

@end
