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

- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];

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

    [self lockFocus];

    var context = [[CPGraphicsContext currentContext] graphicsPort];
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

    [self unlockFocus];
}

@end

@implementation GradientView : CPView
{
}

- (id)init
{
    if(self = [super init])
    {
    }
    return self;
}

- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        linearGradientPointStart = CGPointMake(0, 50),
        linearGradientPointEnd = CGPointMake(100, 50),
        ellipseRect = CGRectMake(110, 10, 80, 80),
        gradientColors = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [236 / 255, 126 / 255, 25 / 255, 1 , 255 / 255, 248 / 255, 197 / 255, 1], [0,1], 2);

    // test CGContextDrawLinearGradient
    CGContextBeginPath(context);
    CGContextAddRect(context, CGRectMake(0, 0, 100, 100));
    CGContextDrawLinearGradient(context, gradientColors, linearGradientPointStart, linearGradientPointEnd, 0);
    CGContextClosePath(context);

    // test CGContextDrawRadialGradient
    CGContextBeginPath(context);
    CGContextAddEllipseInRect(context, ellipseRect);
    CGContextDrawRadialGradient(context, gradientColors, CGPointMake(CGRectGetMidX(ellipseRect), CGRectGetMidY(ellipseRect)), 0, CGPointMake(CGRectGetMidX(ellipseRect), CGRectGetMidY(ellipseRect)), 40,0);
    CGContextClosePath(context);
}

@end



@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

    [label setStringValue:@"Hello World!"];
    [label setFont:[CPFont boldSystemFontOfSize:24.0]];

    [label sizeToFit];

    [label setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [label setCenter:[contentView center]];

    [contentView addSubview:label];
    [contentView addSubview:[[DiamondView alloc] initWithFrame:CGRectMake(100, 100, 200, 200)]];
    [contentView addSubview:[[GradientView alloc] initWithFrame:CGRectMake(100, 320, 200, 200)]];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

@end
