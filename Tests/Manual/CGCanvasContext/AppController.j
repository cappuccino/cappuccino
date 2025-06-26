/*
 * AppController.j
 * NewApplication
 *
 * Created by You on November 16, 2011.
 * Copyright 2011, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

@implementation DiamondView : CPView
{
}

// 1. Initialize the view to be layer-backed.
- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    if (self)
    {
        // This is the crucial step. It tells the view to create a CALayer
        // and use it for all drawing and transformations.
        [self setWantsLayer:YES];
    }
    return self;
}

- (void)drawInContext:(CGContext)aContext
{
    CGContextSetFillColor(aContext, [CPColor grayColor]);
    CGContextFillRect(aContext, [self bounds]);
debugger
}

// 2. Implement the layer drawing delegate method.
// This method is called instead of drawRect: when a view is layer-backed.
- (void)drawLayer:(CALayer)aLayer inContext:(CGContextRef)aContext
{
    // The drawing rectangle is now the layer's bounds, not a parameter.
    var aRect = [aLayer bounds];
debugger

    var points = [CPArray array],
        minX = CGRectGetMinX(aRect),
        midX = CGRectGetMidX(aRect),
        maxX = CGRectGetMaxX(aRect),
        minY = CGRectGetMinY(aRect),
        midY = CGRectGetMidY(aRect),
        maxY = CGRectGetMaxY(aRect),
        quarterX = minX + (maxX - minX)/4;

    [points addObject:CGPointMake(midX, minY)];
    [points addObject:CGPointMake(maxX, midY)];
    [points addObject:CGPointMake(midX, maxY)];
    [points addObject:CGPointMake(minX, midY)];
    [points addObject:CGPointMake(midX, minY)];

    // NOTE: [self lockFocus] and [self unlockFocus] are NOT needed here.
    // The graphics context is provided directly.

    // Use the provided context 'aContext'.
    CGContextSetLineWidth(aContext, 2);
    CGContextSetStrokeColor(aContext, [CPColor blueColor]);

    // test CGContextAddLines
    CGContextBeginPath(aContext);
    CGContextAddLines(aContext, points, NULL);

    // test CGContextAddQuadCurveToPoint
    CGContextAddQuadCurveToPoint(aContext, quarterX, midY, midX, maxY);
    CGContextStrokePath(aContext);

    // test CGContextStrokeRectWithWidth
    var innerRect = CGRectInset(aRect, CGRectGetWidth(aRect)/2 - 10, CGRectGetHeight(aRect)/2 - 10);
    CGContextStrokeRectWithWidth(aContext, innerRect, 4);

    CGContextSetTextPosition(aContext, innerRect.origin.x + 10, innerRect.origin.x + 10);
    CGContextSetFillColor(aContext, [CPColor blueColor]);
    CGContextShowText(aContext, 'Hello World Canvas!');
}

@end


@implementation AppController : CPObject
{
    DiamondView _diamondView;
    var         _lastSliderAngle;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // Use a larger window to fit all elements
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0, 0, 600, 400) styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    // --- Create and place the DiamondView ---
    _diamondView = [[DiamondView alloc] initWithFrame:CGRectMake(50, 100, 200, 200)];
    [contentView addSubview:_diamondView];


    // --- Create and configure the circular slider ---
    var rotationSlider = [[CPSlider alloc] initWithFrame:CGRectMake(350, 125, 30, 30)];
    [rotationSlider setSliderType:CPCircularSlider];
    [rotationSlider setMinValue:0.0];
    [rotationSlider setMaxValue:360.0];
    [rotationSlider setFloatValue:0.0];
    [rotationSlider setTarget:self];
    [rotationSlider setAction:@selector(sliderDidChange:)];
    [contentView addSubview:rotationSlider];


    // --- Create and add the original label ---
    var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    [label setStringValue:@"Do you see the Hello World Canvas?"];
    [label setFont:[CPFont boldSystemFontOfSize:24.0]];
    [label sizeToFit];
    [label setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [label setCenter:[contentView center]];
    [contentView addSubview:label];


    // --- Initialize state and show the window ---
    _lastSliderAngle = [rotationSlider floatValue];
    [theWindow orderFront:self];
}

// This method is called every time the slider's value changes.
- (void)sliderDidChange:(id)sender
{
    var newAngle = [sender floatValue];
    var deltaAngle = newAngle - _lastSliderAngle;

    // This call now operates on the explicitly created layer of the DiamondView.
    [_diamondView rotateByAngle:deltaAngle];

    _lastSliderAngle = newAngle;
}

@end
