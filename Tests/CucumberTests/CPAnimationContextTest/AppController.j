/*
 * AppController.j
 * AdvancedHelloWorld
 *
 * Created by You on December 8, 2011.
 * Copyright 2011, Your Company All rights reserved.
 */
/*
    This Cucapp tests the following:
        • CPAnimationContext -setCompletionHandler: is called and the end value is correct when the frame of a view is animated.
            Tested for a vanilla view (no drawing, no layout), a view with custom drawing, with custom layout, with both.
        • CPAnimationContext CPView special keyPaths CPAnimationTriggerOrderIn and CPAnimationTriggerOrderOut.
            Checks that adding or removing the animator to/from the superview does not throw an error and the superview final value is correct.
*/

@import <Foundation/CPObject.j>

@import "CPResponder+Cucapp.j"

@class ColorView

var ANIMATION_DURATION = 0.9;

@implementation AppController : CPObject
{
    /* this "outlet" is connected automatically by the Cib */
    CPWindow    theWindow;

    /* We create the outlets of the textfields here */
    @outlet DrawView         drawView;
    @outlet CustomLayoutView layoutView;
    @outlet CustomLayoutDrawView layoutDrawView;

    CPInteger testNumber;
    CPString passed;
}

- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];
    [layoutView setNeedsLayout];
    [layoutDrawView setNeedsLayout];
    testNumber = 0;
    passed = "";
}

- (void)testDidPass
{
    passed = "true";
    testNumber++;
}

- (IBAction)test:(id)sender
{
    passed = "false";
    [self performSelector:CPSelectorFromString("test" + testNumber)];
}

- (void)test0
{
    vanillaView = [[ColorView alloc] initWithFrame:CGRectMake(30,30,148,115)];
    [vanillaView setBackgroundColor:[vanillaView color]];

    var fadeOut = [CABasicAnimation animationWithKeyPath:@"alphaValue"];
    [fadeOut setFromValue:1];
    [fadeOut setToValue:0];
    [fadeOut setDuration:ANIMATION_DURATION];

    [vanillaView setAnimations:@{@"CPAnimationTriggerOrderOut":fadeOut}];

    var ctx = [CPAnimationContext currentContext];
    [ctx setCompletionHandler:function()
    {
        if ([vanillaView superview] == [theWindow contentView] && [vanillaView alphaValue] == 1)
            [self testDidPass];
    }];

    [[theWindow contentView] addSubview:vanillaView];
}

- (void)test1
{
    [self move:vanillaView];
}

- (void)test2
{
    [self move:drawView];
}

- (void)test3
{
    [self move:layoutView];
}

- (void)test4
{
    [self move:layoutDrawView];
}

- (void)test5
{
    var ctx = [CPAnimationContext currentContext];
    [ctx setCompletionHandler:function()
    {
        if ([vanillaView superview] == nil && [vanillaView alphaValue] == 1)
            [self testDidPass];
    }];

    [[vanillaView animator] removeFromSuperview];
}

- (void)move:(CPView)view
{
    var destinationRect = CGRectMake(200 *testNumber,200,200,200);
    var ctx = [CPAnimationContext currentContext];
    [ctx setDuration:ANIMATION_DURATION];
    [ctx setCompletionHandler:function()
    {
        if (CGRectEqualToRect([view frame], destinationRect))
            [self testDidPass];
    }];

    [[view animator] setFrame:destinationRect];
}

@end


@implementation ColorView : CPView
{
    CPColor color @accessors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    color = [CPColor randomColor];

    return self;
}

- (void)viewDidMoveToSuperview
{
    [self setBackgroundColor:color];
}

@end

@implementation DrawView : CPView
{
    CPColor color;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    color = [CPColor randomColor];

    return self;
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds];

    CGContextSetLineWidth(context, 2);
    CGContextSetStrokeColor(context, [CPColor blackColor]);
    CGContextSetFillColor(context, color);

    CGContextBeginPath(context);
    CGContextFillRect(context, bounds);

    var height = CGRectGetHeight(bounds),
        width = CGRectGetWidth(bounds);

    CGContextStrokeLineSegments(context, [CGPointMake(10,0), CGPointMake(10, height),
                                          CGPointMake(0, 10), CGPointMake(CGRectGetWidth(aRect), 10),
                                          CGPointMake(width - 10, 0), CGPointMake(width - 10, height),
                                          CGPointMake(0, height - 10), CGPointMake(width, height - 10)], 8);
}

@end

@implementation CustomLayoutView : ColorView
{
}

- (void)layoutSubviews
{
    [self setBackgroundColor:color];

    var subviews = [self subviews],
        count = [subviews count] - 1;

    var dx = (CGRectGetWidth([self frame]) - 100) / count,
        dy = (CGRectGetHeight([self frame]) - 26) / count

    [subviews enumerateObjectsUsingBlock:function(view, idx, stop)
    {
        [view setFrameOrigin:CGPointMake(dx * idx, dy * idx)];
    }];
}

@end

@implementation CustomLayoutDrawView : DrawView
{
}

- (void)layoutSubviews
{
    var subviews = [self subviews],
        count = [subviews count] - 1;

    var dx = (CGRectGetWidth([self frame]) - 100) / count,
        dy = (CGRectGetHeight([self frame]) - 26) / count

    [subviews enumerateObjectsUsingBlock:function(view, idx, stop)
    {
        [view setFrameOrigin:CGPointMake(dx * idx, dy * idx)];
    }];
}

@end
