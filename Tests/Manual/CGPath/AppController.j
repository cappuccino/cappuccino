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

    var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

    [label setStringValue:@"Hello World!"];
    [label setFont:[CPFont boldSystemFontOfSize:24.0]];

    [label sizeToFit];

    [label setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [label setCenter:[contentView center]];

    [contentView addSubview:label];

    var pathView = [[PathView alloc] initWithFrame:CGRectMake(0.0, 0.0, 500.0, 500.0)];
    [contentView addSubview:pathView];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

@end

@implementation PathView : CPView
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
