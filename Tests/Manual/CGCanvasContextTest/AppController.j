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

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    if (self)
    {
        [self setWantsLayer:YES];
        [[self layer] setDelegate:self];
        [[self layer] setBackgroundColor:[CPColor lightGrayColor]];
        [[self layer] setNeedsDisplay];
    }
    return self;
}

- (void)drawLayer:(CALayer)aLayer inContext:(CGContextRef)context
{
    var aRect = [aLayer bounds];

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

    CGContextSaveGState(context);

    CGContextSetLineWidth(context, 2);
    CGContextSetStrokeColor(context, [CPColor blueColor]);

    // test CGContextAddLines
    CGContextBeginPath(context);
    CGContextAddLines(context, points, NULL);

    // test CGContextAddQuadCurveToPoint
    CGContextAddQuadCurveToPoint(context, quarterX, midY, midX, maxY);
    CGContextStrokePath(context);

    // test CGContextStrokeRectWithWidth
    var innerRect = CGRectInset(aRect, CGRectGetWidth(aRect)/2 - 10, CGRectGetHeight(aRect)/2 - 10);
    CGContextStrokeRectWithWidth(context, innerRect, 4);

    CGContextSetTextPosition(context, innerRect.origin.x + 10, innerRect.origin.x + 10);
    CGContextSetFillColor(context, [CPColor blueColor]);
    CGContextShowText(context, 'Hello World Canvas!');

    CGContextRestoreGState(context);
}
@end

@implementation AppController : CPObject
{
    DiamondView _diamondView;
    var         _lastSliderAngle;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    // --- Create and place the DiamondView ---
    _diamondView = [[DiamondView alloc] initWithFrame:CGRectMake(50, 100, 200, 200)];
    [contentView addSubview:_diamondView];


    // --- Create and configure the circular slider ---
    var label2 = [[CPTextField alloc] initWithFrame:CGRectMake(350, 100, 130, 30)];
    [label2 setStringValue:@"Rotate via rotateByAngle:"];
    [label2 setFont:[CPFont boldSystemFontOfSize:24.0]];
    [label2 sizeToFit];
    [contentView addSubview:label2];

    var rotationSlider = [[CPSlider alloc] initWithFrame:CGRectMake(350, 125, 30, 30)];
    [rotationSlider setSliderType:CPCircularSlider];
    [rotationSlider setMinValue:0.0];
    [rotationSlider setMaxValue:360.0];
    [rotationSlider setFloatValue:0.0];
    [rotationSlider setTarget:self];
    [rotationSlider setAction:@selector(sliderDidChange:)];
    [contentView addSubview:rotationSlider];

    var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    [label setStringValue:@"Do you see the Hello World Canvas?"];
    [label setFont:[CPFont boldSystemFontOfSize:24.0]];
    [label sizeToFit];
    [label setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [label setCenter:[contentView center]];
    [contentView addSubview:label];

    _lastSliderAngle = [rotationSlider floatValue];
    [theWindow orderFront:self];
}

// This method is called every time the slider's value changes.
- (void)sliderDidChange:(id)sender
{
    var newAngle = [sender floatValue];
    var deltaAngle = newAngle - _lastSliderAngle;
    [_diamondView rotateByAngle:deltaAngle];
    _lastSliderAngle = newAngle;
}

@end
