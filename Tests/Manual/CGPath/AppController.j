/*
 * AppController.j
 * CGPath
 *
 * Created by You on May 23, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    var pathView = [[PathView alloc] initWithFrame:CGRectMake(0.0, 0.0, 500.0, 500.0)];
    [contentView addSubview:pathView];

    var pathMouseOverView = [[PathMouseOverView alloc] initWithFrame:CGRectMake(500.0, 0.0, 500.0, 500.0)];
    [contentView addSubview:pathMouseOverView];

    [theWindow orderFront:self];
}

@end

@implementation PathMouseOverView : CPView
{
    id path1;
    id path2;
    id path3;
}

- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];

    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextBeginPath(context);
    path1 = CGPathCreateMutable();
    CGPathMoveToPoint(path1, nil, 100, 100);
    CGPathAddLineToPoint(path1, nil, 150, 50);
    CGPathAddLineToPoint(path1, nil, 200, 100);
    CGContextAddPath(context, path1);
    CGContextClosePath(context);
    CGContextStrokePath(context);

    CGContextBeginPath(context);
    path2 = CGPathCreateMutable();
    CGPathAddRect( path2, nil, CGRectMake(250, 50, 100, 100));
    CGContextAddPath(context, path2);
    CGContextClosePath(context);
    CGContextStrokePath(context);

    CGContextBeginPath(context);
    path3 = CGPathWithEllipseInRect( CGRectMake(100, 150, 100, 100))
    CGContextAddPath(context, path3);
    CGContextClosePath(context);
    CGContextStrokePath(context);
}

- (void)mouseMoved:(CPEvent)anEvent
{
    var location = [self convertPointFromBase:[anEvent locationInWindow]],
        context = CGBitmapGraphicsContextCreate();

    if (CGPathContainsPoint(path1, nil, location, nil))
        console.log("Mouse is in the triangle");

    if (CGPathContainsPoint(path2, nil, location, nil))
        console.log("Mouse is in rectangle");

    if (CGPathContainsPoint(path3, nil, location, nil))
        console.log("Mouse is in the circle");
}

@end



@implementation PathView : CPView
{

}

- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];

    var context = [[CPGraphicsContext currentContext] graphicsPort];

    // Test to create a pie chart
    CGContextBeginPath(context);
    var path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, 100, 100);
    CGPathAddArc(path, nil,100, 100, 70, 0, 2.615500255957057, YES);
    CGPathAddLineToPoint(path, nil, 100, 100);
    CGPathAddArc(path, nil,100, 100, 70, 2.615500255957057, 6.148960361810042, YES);
    CGPathAddLineToPoint(path, nil, 100, 100);
    CGPathAddArc(path, nil,100, 100, 70, 6.148960361810042, 0, YES);
    CGPathAddLineToPoint(path, nil, 100, 100);
    CGContextAddPath(context, path);
    CGContextStrokePath(context);
    CGContextClosePath(context);

    // Test to create an arc without a start point
    CGContextBeginPath(context);
    path = CGPathCreateMutable();
    CGPathAddArc(path, nil,300, 100, 70, 0, 2.615500255957057, YES);
    CGContextAddPath(context, path);
    CGContextStrokePath(context);
    CGContextClosePath(context);

    // Test to create an arc with a start point
    CGContextBeginPath(context);
    path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, 100, 250);
    CGPathAddArc(path, nil,100, 300, 70, 0, 2.615500255957057, YES);
    CGContextAddPath(context, path);
    CGContextStrokePath(context);
    CGContextClosePath(context);
}

@end
