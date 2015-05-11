/*
 * AppController.j
 * CPAnimatablePropertyContainerTest
 *
 * Created by You on December 3, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

CPLogRegister(CPLogConsole);

var ANIMATIONS_NAMES = ["Fade In", "Fade Out", "Background Color", "Frame Origin", "Bounce", "Frame Size", "Frame"];

@implementation AppController : CPObject
{
    @outlet CPWindow theWindow; //this "outlet" is connected automatically by the Cib

    @outlet CPBox group1Box;
    @outlet CPBox group2Box;

    @outlet CPView animationSandbox;

    CPView leftView;
    CPView rightView;

    CPArray animations;

    float   duration1 @accessors;
    float   duration2 @accessors;

    CPString message1 @accessors;
    CPString message2 @accessors;

    CPInteger selectedTimingFunction1 @accessors;
    CPInteger selectedTimingFunction2 @accessors;

    CPString timingFunction1 @accessors;
    CPString timingFunction2 @accessors;
}

- (id)init
{
    self = [super init];

    animations = [CPArray array];

    [ANIMATIONS_NAMES enumerateObjectsUsingBlock:function(anim, idx)
    {
        var dict = [CPDictionary dictionaryWithObjectsAndKeys:anim, @"name", NO, @"enabled1", NO, @"enabled2"];
        [animations addObject:dict];
    }];

    duration1 = 1.0;
    duration2 = 1.0;

    message1 = @"Done for View 1";
    message2 = @"Done for View 2";

    timingFunction1 = @"0,1,1,0";
    timingFunction2 = @"0,1,1,0";

    selectedTimingFunction1 = 1;
    selectedTimingFunction2 = 1;

    return self;
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

    [[theWindow contentView] setBackgroundColor:[CPColor colorWithRed:1 green:238/255 blue:185/255 alpha:1]];
    [animationSandbox setBackgroundColor:[CPColor whiteColor]];

    [self revert:nil];
    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

- (IBAction)runAnimationsGroup1:(id)sender
{
    [[CPAnimationContext currentContext] setDuration:duration1];
    [[CPAnimationContext currentContext] setTimingFunction:[self timingFunctionForGroup:1 fromPopUp:selectedTimingFunction1]];
    [[CPAnimationContext currentContext] setCompletionHandler:[self completionHandlerFromString:message1]];

    [self runAnimationsForGroup:1];
}

- (IBAction)runAnimationsGroup2:(id)sender
{
    [[CPAnimationContext currentContext] setDuration:duration2];
    [[CPAnimationContext currentContext] setTimingFunction:[self timingFunctionForGroup:2 fromPopUp:selectedTimingFunction2]];
    [[CPAnimationContext currentContext] setCompletionHandler:[self completionHandlerFromString:message2]];

    [self runAnimationsForGroup:2];
}

- (IBAction)animate:(id)sender
{
    [[CPAnimationContext currentContext] setDuration:duration1];
    [[CPAnimationContext currentContext] setTimingFunction:[self timingFunctionForGroup:1 fromPopUp:selectedTimingFunction2]];
    [[CPAnimationContext currentContext] setCompletionHandler:[self completionHandlerFromString:message1]];

    var tag = [sender tag];
    var width = tag ? 100 : 200;
    [[sender animator] setFrameSize:CGSizeMake(width, CGRectGetHeight([sender frame]))];

    [sender setTag:(1 - tag)];
}

- (IBAction)runBothGroups:(id)sender
{
    [CPAnimationContext runAnimationGroup:function(context)
    {
        [context setDuration:duration1];
        [context setTimingFunction:[self timingFunctionForGroup:1 fromPopUp:selectedTimingFunction1]];
        [self runAnimationsForGroup:1];

    } completionHandler:function()
    {
        CPLogConsole(message1);
    }];

    [CPAnimationContext runAnimationGroup:function(context)
    {
        [context setDuration:duration2];
        [context setTimingFunction:[self timingFunctionForGroup:2 fromPopUp:selectedTimingFunction2]];
        [self runAnimationsForGroup:2];

    } completionHandler:function()
    {
        CPLogConsole(message2);
    }];
}

/*
- (IBAction)runInGroups:(id)sender
{
    [CPAnimationContext beginGrouping];

    [[CPAnimationContext currentContext] setDuration:duration1];
    [[CPAnimationContext currentContext] setTimingFunction:[self timingFunctionFromString:timingFunction1]];
    [[CPAnimationContext currentContext] setCompletionHandler:[self completionHandlerFromString:message1]];
    [self runAnimationsForGroup:1];

    [CPAnimationContext endGrouping];


    [CPAnimationContext beginGrouping];

    [[CPAnimationContext currentContext] setDuration:duration2];
    [[CPAnimationContext currentContext] setCompletionHandler:[self completionHandlerFromString:message2]];
    [self runAnimationsForGroup:2];

    [CPAnimationContext endGrouping];
}

- (IBAction)emptyGroupTest:(id)sender
{
    [CPAnimationContext beginGrouping];

    [[CPAnimationContext currentContext] setDuration:10];
    [[CPAnimationContext currentContext] setCompletionHandler:function()
    {
        CPLogConsole("Context duration is 10s but no animations were set. We run the completionHandler (this message) immediately and return");
    }];

    [CPAnimationContext endGrouping];
}
*/
- (IBAction)removeFromSuperview:(id)sender
{
    [[leftView animator] removeFromSuperview];
    [[rightView animator] removeFromSuperview];
}

- (IBAction)revert:(id)sender
{
    [self setupGroup1:nil];
    [self setupGroup2:nil];
}
/*
- (IBAction)addSubview:(id)sender
{
    [[theWindow contentView] addSubview:];
}
*/
- (void)runAnimationsForGroup:(CPInteger)group
{
    var aView = group == 1 ? leftView : rightView,
        enabledKey = @"enabled" + group;

    var enabledIndexes = [animations indexesOfObjectsPassingTest:function(obj, idx)
    {
        return [obj objectForKey:enabledKey];
    }];

    if ([enabledIndexes count] == 0)
        return;

    if ([enabledIndexes containsIndex:0])
    {
        [aView setAlphaValue:0];
        [[aView animator] setAlphaValue:1];
    }
    else if ([enabledIndexes containsIndex:1])
    {
        [[aView animator] setAlphaValue:0];
    }

    if ([enabledIndexes containsIndex:2])
    {
        [[aView animator] setBackgroundColor:[CPColor magentaColor]];
    }

    if ([enabledIndexes containsIndex:6])
    {
        var frame = CGRectMakeCopy([aView frame]),
            origin = frame.origin,
            size = frame.size;

        origin.x += 450;
        origin.y += 200;

        size.width += 100;
        size.height += 100;

        [[aView animator] setFrame:frame];
        return;
    }

    if ([enabledIndexes containsIndex:4])
    {
        [[aView animations] setObject:[self bounceAnimation:aView] forKey:@"frameOrigin"];

        var origin = CGPointMakeCopy([aView frameOrigin]);
        [[aView animator] setFrameOrigin:origin];
    }
    else if ([enabledIndexes containsIndex:3])
    {
        [[aView animations] removeObjectForKey:@"frameOrigin"];

        var origin = CGPointMakeCopy([aView frameOrigin]);
        origin.x +=550;
        origin.y +=300;
        [[aView animator] setFrameOrigin:origin];
    }

    if ([enabledIndexes containsIndex:5])
    {
        var size = CGSizeMakeCopy([aView frameSize]);
        size.width += 300;
        size.height += 200;
        [[aView animator] setFrameSize:size];
    }
}

- (CAMediaTimingFunction)controlsPointsForGroup:(CPInteger)aGroup
{
    var aString = (aGroup == 1) ? timingFunction1 : timingFunction2;

    if (!aString || ![aString length])
        return nil;

    var controlsPoints = [aString componentsSeparatedByString:@","];

    return [[controlsPoints[0] floatValue], [controlsPoints[1] floatValue], [controlsPoints[2] floatValue], [controlsPoints[3] floatValue]];
}

- (CAMediaTimingFunction)timingFunctionForGroup:(CPInteger)aGroup fromPopUp:(CPInteger)selectedTag
{
    var controlsPoints;

    switch (selectedTag)
    {
        case 1: controlsPoints = [0, 0, 1, 1];
        break;
        case 2: controlsPoints = [0.42, 0, 1, 1];
        break;
        case 3: controlsPoints = [0, 0, 0.58, 1];
        break;
        case 4: controlsPoints = [0.42, 0, 0.58, 1];
        break;
        case 0: controlsPoints = [self controlsPointsForGroup:aGroup];
        break;
    }

    return [CAMediaTimingFunction functionWithControlPoints:controlsPoints[0] :controlsPoints[1] :controlsPoints[2] :controlsPoints[3]];
}

- (Function)completionHandlerFromString:(CPString)aMessage
{
    if (!aMessage || ![aMessage length])
        return nil;

    var s = new Date();
    return function()
    {
        var e = new Date() - s;
        CPLogConsole(aMessage + " in " + e + " ms");
    };
}

- (CAKeyframeAnimation)bounceAnimation:(CPView)aView
{
    var anim = [CAKeyframeAnimation animation],
        easein = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn],
        easeout = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    [anim setKeyTimes:[0, 0.25, 0.5, 0.75, 1]];
    var origin = CGPointMakeCopy([aView frameOrigin]);
    [anim setValues:[origin, CGPointMake(origin.x, origin.y + 50), origin, CGPointMake(origin.x, origin.y + 25), origin]];
    [anim setTimingFunctions:[easeout, easein, easeout, easein]];

    return anim;
}

- (CABasicAnimation)fadeOutAnimation
{
    var animation = [CABasicAnimation animationWithKeyPath:@"alphaValue"];
    [animation setDuration:0.2];
    [animation setFromValue:1];
    [animation setToValue:0];

    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];

    return animation;
}

- (IBAction)setupGroup1:(id)sender
{
    var contentView = [group1Box contentView];

    var hasSubviews = [[contentView viewWithTag:1000] state] * 2,
        customLayout = [[contentView viewWithTag:1001] state] * 4,
        customDraw  = [[contentView viewWithTag:1002] state] * 8,
        customDrawSubviews = [[contentView viewWithTag:1003] state],
        autoLayout = [[contentView viewWithTag:1004] state],
        options = hasSubviews | customLayout | customDraw;

    [leftView removeFromSuperview];
    leftView = [self viewWithOptions:options];

    if (leftView)
    {
        [leftView setFrame:CGRectMake(0, 0, 200, 200)];
        [animationSandbox addSubview:leftView];
    }

    if (hasSubviews)
        [self addSubviewsToView:leftView autoLayout:(autoLayout && !customLayout) customDrawSubviews:customDrawSubviews];
}

- (IBAction)setupGroup2:(id)sender
{
    var contentView = [group2Box contentView];

    var hasSubviews = [[contentView viewWithTag:1000] state] * 2,
        customLayout = [[contentView viewWithTag:1001] state] * 4,
        customDraw  = [[contentView viewWithTag:1002] state] * 8,
        options = hasSubviews | customLayout | customDraw;

    [rightView removeFromSuperview];
    rightView = [self viewWithOptions:options];

    if (rightView)
    {
        [rightView setFrame:CGRectMake(250, 0, 200, 200)];
        [animationSandbox addSubview:rightView];
    }

    if (leftView)
        [animationSandbox addSubview:leftView];

    if (hasSubviews)
        [self addSubviewsToView:rightView autoLayout:!customLayout customDrawSubviews:NO];
}

- (void)viewWithOptions:(CPInteger)options
{
    var view = nil,
        hasSubviews = NO;

    switch (options)
    {
        case 0: view = [[ColorView alloc] initWithFrame:CGRectMakeZero()];
        break;

        case 2: view = [[ColorView alloc] initWithFrame:CGRectMakeZero()];
                hasSubviews = YES;
        break;

        case 4:
        case 6: view = [[CustomLayoutView alloc] initWithFrame:CGRectMakeZero()];
                [view setBackgroundColor:[CPColor randomColor]];
                hasSubviews = YES;
        break;

        case 12:
        case 14: view = [[CustomLayoutDrawView alloc] initWithFrame:CGRectMakeZero()];
                 hasSubviews = YES;
        break;

        case 8: view = [[DrawView alloc] initWithFrame:CGRectMakeZero()];
        break;

        case 10: view = [[DrawView alloc] initWithFrame:CGRectMakeZero()];
                hasSubviews = YES;
        break;

    }

    var anims = [CPDictionary dictionaryWithObject:[self fadeOutAnimation] forKey:@"CPAnimationTriggerOrderOut"];
    [view setAnimations:anims];

    return view;
}

- (void)addSubviewsToView:(CPView)aView autoLayout:(BOOL)autoLayout customDrawSubviews:(BOOL)customDrawSubviews
{
    var subViewClass = customDrawSubviews ? [DrawView class] : [ColorView class];

    for (var i = 0; i < 5; i++)
    {
        var view = [[subViewClass alloc] initWithFrame:CGRectMake(50, i * 40, 80, 26)];
        if (autoLayout)
            [view setAutoresizingMask:CPViewWidthSizable|CPViewMinYMargin];

        [aView addSubview:view];
    }
}

@end

@implementation ColorView : CPView
{
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    [self setBackgroundColor:[CPColor randomColor]];

    return self;
}

@end

@implementation DrawView : CPView
{
    CPColor color @accessors;
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

@implementation CustomLayoutView : CPView
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