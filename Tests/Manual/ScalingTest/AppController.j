/*
 * AppController.j
 * ScalingTest
 *
 * Created by You on July 23, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@implementation AppController : CPObject
{
    @outlet CPWindow        theWindow;
    @outlet CPSlider        sliderView1;
    @outlet CPSlider        sliderView2;
    @outlet CPView          view1;
    @outlet CPView          view2;
    @outlet CPView          view3;
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

- (IBAction)slider1:(id)sender
{
    var factor = [sender objectValue];
    [view1 setScaleSize:CGSizeMake(factor, factor)];
    // [view1 scaleUnitSquareToSize:CGSizeMake(factor, factor)];
    // [view1 setNeedsDisplay:YES];
}

- (IBAction)slider2:(id)sender
{
    var factor = [sender objectValue];
    [view2 setScaleSize:CGSizeMake(factor, factor)];
    // [view2 scaleUnitSquareToSize:CGSizeMake(factor, factor)];
    // [view2 setNeedsDisplay:YES];
}

- (IBAction)slider3:(id)sender
{
    var factor = [sender objectValue];
    [view3 setScaleSize:CGSizeMake(factor, factor)];
    // [view2 scaleUnitSquareToSize:CGSizeMake(factor, factor)];
    // [view2 setNeedsDisplay:YES];
}

- (IBAction)button1:(id)sender
{
    alert("Jolie click !!!");
}

- (IBAction)button2:(id)sender
{
    alert("Nice click !!!");
}

- (IBAction)button3:(id)sender
{
    alert("Wunderbar !!!");
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return 15;
}

@end