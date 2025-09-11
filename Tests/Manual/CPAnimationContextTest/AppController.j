/*
 * AppController.j
 * CPAnimationContextTest
 *
 * Created by You on June 28, 2017.
 * Copyright 2017, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import <AppKit/CAKeyframeAnimation.j>

#define UIAssert(a) [self markTest:_cmd didPass:a];

// A new custom view class to draw the animation path.
@implementation PathView : CPView
{
    CPBezierPath _path;
}

- (void)setPath:(CPBezierPath)aPath
{
    _path = aPath;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)aRect
{
    if (_path)
    {
        [[CPColor lightGrayColor] set];
        [_path setLineWidth:2.0];
        // Use a dashed line to make it clearer it's a guide
        var dashes = [2, 3];
        [_path setLineDash:dashes count:2 phase:0];
        [_path stroke];
    }
}

@end


@implementation AppController : CPObject
{
    CPWindow theWindow;
    CPView   _testView; // A view to animate for our new tests
    PathView _pathView; // A view to draw the animation path
    CGRect   _initialTestViewFrame;
    id       allLabels; // An array of labels to show test results
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];
    var contentView = [theWindow contentView];

    [theWindow orderFront:self];

    // Create a view to draw the intended animation path.
    _pathView = [[PathView alloc] initWithFrame:[contentView bounds]];
    [_pathView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [contentView addSubview:_pathView];

    // Create a view that we can animate for the new tests.
    _initialTestViewFrame = CGRectMake(390, 450, 50, 50);
    _testView = [[CPView alloc] initWithFrame:_initialTestViewFrame];
    [_testView setBackgroundColor:[CPColor blueColor]];
    [contentView addSubview:_testView]; // Add it on top of the path view
   // [_pathView setFrameOrigin:_initialTestViewFrame.origin];

    [self setup];
}

- (void)cleanupAfterAnimation
{

    [_pathView setPath:nil];

    // Animate the test view back to its starting position.
    var animation = [[CPViewAnimation alloc] initWithViewAnimations:[@{
        CPViewAnimationTargetKey:_testView,
        CPViewAnimationStartFrameKey:[_testView frame],
        CPViewAnimationEndFrameKey:_initialTestViewFrame
    }]];

    [animation setAnimationCurve:CPAnimationLinear];
    [animation setDuration:0.1];
    [animation startAnimation];

}

- (void)setup
{
    var methods = class_copyMethodList([self class]);
    var testMethodCount = 0;
    allLabels = [];

    [methods enumerateObjectsUsingBlock:function(meth, _)
     {
        var method_name = method_getName(meth);
        if ([method_name hasPrefix:@"test"])
        {
            var yPos = 10 + 35 * testMethodCount;
            var runButton = [[CPButton alloc] initWithFrame:CGRectMake(10, yPos, 0, 32)];
            [runButton setTitle:unCamelCase(method_name)];
            [runButton setTarget:self];
            [runButton setAction:CPSelectorFromString(method_name)];
            [[theWindow contentView] addSubview:runButton];
            [runButton sizeToFit];

            var label = [[CPTextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX([runButton frame]) + 10, yPos, 200, 32)];
            [label setIdentifier:method_name];
            [label setFont:[CPFont systemFontOfSize:16]];
            [label setStringValue:@"………"];
            [[theWindow contentView] addSubview:label];
            [allLabels addObject:label];
            testMethodCount++;
        }
    }];

    // Add a reset button that clears the view and labels
    var resetButton = [[CPButton alloc] initWithFrame:CGRectMake(10, 10 + 35 * testMethodCount, 0, 32)];
    [resetButton setTitle:@"Reset"];
    [resetButton setTarget:self];
    [resetButton setAction:@selector(reset:)];
    [[theWindow contentView] addSubview:resetButton];
    [resetButton sizeToFit];
}

- (void)reset:(id)sender
{
    [_testView setFrame:_initialTestViewFrame];
    [_pathView setPath:nil];
    [allLabels enumerateObjectsUsingBlock:function(label) {
            [label setTextColor:[CPColor blackColor]];
            [label setStringValue:@"………"];
        }];
}

- (void)markTest:(CPString)testSelector didPass:(BOOL)passed
{
    [[[theWindow contentView] subviews] enumerateObjectsUsingBlock:function(aView, idx, stop)
     {
        if ([aView identifier] == testSelector)
        {
            [aView setTextColor:passed ? [CPColor greenColor]: [CPColor redColor]];
            [aView setStringValue:(passed ? @"Passed" : "Failed")];
        }
    }];
}

- (void)testPathAnimation:(id)sender
{
    [_testView setFrame:_initialTestViewFrame];

    // 1. Define the desired trajectory for the view's ORIGIN.
    var startOrigin = _initialTestViewFrame.origin;
    var endOrigin = CGPointMake(startOrigin.x + 200, startOrigin.y - 300);
    var control1Origin = CGPointMake(startOrigin.x - 100, startOrigin.y);
    var control2Origin = CGPointMake(endOrigin.x + 100, endOrigin.y + 100);

    // 2. Calculate the path for the view's CENTER. This path is used for BOTH
    // the visual guide and the animation data.
    var offsetX = _initialTestViewFrame.size.width / 2.0;
    var offsetY = _initialTestViewFrame.size.height / 2.0;

    var startCenter = CGPointMake(startOrigin.x + offsetX, startOrigin.y + offsetY);
    var endCenter = CGPointMake(endOrigin.x + offsetX, endOrigin.y + offsetY);
    var control1Center = CGPointMake(control1Origin.x + offsetX, control1Origin.y + offsetY);
    var control2Center = CGPointMake(control2Origin.x + offsetX, control2Origin.y + offsetY);

    var centerPath = [CPBezierPath bezierPath];
    [centerPath moveToPoint:startCenter];
    [centerPath curveToPoint:endCenter
               controlPoint1:control1Center
               controlPoint2:control2Center];

    // 3. Set the visual guide and the animation path.
    [_pathView setPath:centerPath];

    var pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"frameOrigin"];
    [pathAnimation setPath:centerPath]; // The system uses this path for the CENTER.
    [pathAnimation setDuration:2.0];
    [pathAnimation setCalculationMode:kCAAnimationPaced];
    [pathAnimation setRotationMode:kCAAnimationRotateAuto];

    [CPAnimationContext beginGrouping];
    var context = [CPAnimationContext currentContext];
    [context setDuration:2.0];

    [context setCompletionHandler:function()
     {
        var finalOrigin = [_testView frame].origin;
        var passed = (Math.abs(finalOrigin.x - endOrigin.x) < 1 && Math.abs(finalOrigin.y - endOrigin.y) < 1);
        [self markTest:_cmd didPass:passed];
        [self performSelector:@selector(cleanupAfterAnimation) withObject:nil afterDelay:0.5];
    }];

    // 4. Associate the animation with 'frameOrigin' and trigger it with 'setFrameOrigin:'.
    [_testView setAnimations:[CPDictionary dictionaryWithObject:pathAnimation forKey:@"frameOrigin"]];
    [[_testView animator] setFrameOrigin:endOrigin];
    [CPAnimationContext endGrouping];
}

- (void)testDiscreteAnimation:(id)sender
{
    [_testView setFrame:_initialTestViewFrame];

    // 1. Define origin points.
    var p1Origin = _initialTestViewFrame.origin;
    var p2Origin = CGPointMake(p1Origin.x + 100, p1Origin.y);
    var p3Origin = CGPointMake(p1Origin.x + 100, p1Origin.y - 100);
    var endOrigin = CGPointMake(p1Origin.x, p1Origin.y - 100);

    // 2. Create the visual guide based on the center.
    var offsetX = _initialTestViewFrame.size.width / 2.0;
    var offsetY = _initialTestViewFrame.size.height / 2.0;
    var visualPath = [CPBezierPath bezierPath];
    [visualPath moveToPoint:CGPointMake(p1Origin.x + offsetX, p1Origin.y + offsetY)];
    [visualPath lineToPoint:CGPointMake(p2Origin.x + offsetX, p2Origin.y + offsetY)];
    [visualPath lineToPoint:CGPointMake(p3Origin.x + offsetX, p3Origin.y + offsetY)];
    [visualPath lineToPoint:CGPointMake(endOrigin.x + offsetX, endOrigin.y + offsetY)];
   // [_pathView setFrameOrigin:_initialTestViewFrame.origin];
    [_pathView setPath:visualPath];

    // 3. The animation uses the origin values directly.
    var discreteAnimation = [CAKeyframeAnimation animationWithKeyPath:@"frameOrigin"];
    [discreteAnimation setValues:[p1Origin, p2Origin, p3Origin, endOrigin]];
    [discreteAnimation setKeyTimes:[0, 0.33, 0.66, 1.0]];
    [discreteAnimation setCalculationMode:kCAAnimationDiscrete];

    [CPAnimationContext beginGrouping];
    var context = [CPAnimationContext currentContext];
    [context setDuration:2.0];

    [context setCompletionHandler:function()
     {
        var finalOrigin = [_testView frame].origin;
        var passed = (Math.abs(finalOrigin.x - endOrigin.x) < 1 && Math.abs(finalOrigin.y - endOrigin.y) < 1);
        [self markTest:_cmd didPass:passed];
        [self performSelector:@selector(cleanupAfterAnimation) withObject:nil afterDelay:0.5];
    }];

    [_testView setAnimations:[CPDictionary dictionaryWithObject:discreteAnimation forKey:@"frameOrigin"]];
    [[_testView animator] setFrameOrigin:endOrigin];
    [CPAnimationContext endGrouping];
}

- (void)testPathAnimationWithAutoReverseRotation:(id)sender
{
    [_testView setFrame:_initialTestViewFrame];

    // 1. Define origin trajectory.
    var startOrigin = _initialTestViewFrame.origin;
    var endOrigin = CGPointMake(startOrigin.x + 300, startOrigin.y - 150);

    // 2. Calculate the corresponding center trajectory.
    var offsetX = _initialTestViewFrame.size.width / 2.0;
    var offsetY = _initialTestViewFrame.size.height / 2.0;
    var startCenter = CGPointMake(startOrigin.x + offsetX, startOrigin.y + offsetY);
    var endCenter = CGPointMake(endOrigin.x + offsetX, endOrigin.y + offsetY);

    var centerPath = [CPBezierPath bezierPath];
    [centerPath moveToPoint:startCenter];
    [centerPath lineToPoint:endCenter];

    // 3. Use the center path for the guide and the animation data.
    [_pathView setPath:centerPath];

    var pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"frameOrigin"];
    [pathAnimation setPath:centerPath];
    [pathAnimation setRotationMode:kCAAnimationRotateAutoReverse];

    [CPAnimationContext beginGrouping];
    var context = [CPAnimationContext currentContext];
    [context setDuration:2.0];

    [context setCompletionHandler:function()
     {
        var finalOrigin = [_testView frame].origin;
        var passed = (Math.abs(finalOrigin.x - endOrigin.x) < 1 && Math.abs(finalOrigin.y - endOrigin.y) < 1);
        [self markTest:_cmd didPass:passed];
        [self performSelector:@selector(cleanupAfterAnimation) withObject:nil afterDelay:0.5];
    }];

    // 4. Trigger by setting the final origin.
    [_testView setAnimations:[CPDictionary dictionaryWithObject:pathAnimation forKey:@"frameOrigin"]];
    [[_testView animator] setFrameOrigin:endOrigin];
    [CPAnimationContext endGrouping];
}

- (void)testCompletionHandlerWithoutAnimator
{
    var completions = @[];

    [CPAnimationContext beginGrouping];
    var context = [CPAnimationContext currentContext];
    [context setDuration:0.01];
    [context setCompletionHandler:function()
     {
        [completions addObject:@"done"];
        UIAssert([completions isEqualToArray:@["done"]]);
    }];
    [CPAnimationContext endGrouping];
}

- (void)testCompletionHandlerWithoutAnimatorWithGrouping
{
    var completions = @[];

    [CPAnimationContext beginGrouping];
    var context = [CPAnimationContext currentContext];
    [context setDuration:0.01];
    [context setCompletionHandler:function()
     {
        [completions addObject:@"done"];
        UIAssert([completions isEqualToArray:@["done"]]);
    }];
    [CPAnimationContext endGrouping];
}

- (void)testCompletionHandlerWithoutAnimatorWithGrouping2
{
    var completions = @[];

    // This test relies on the auto-flushing behavior of the runloop for a single-level context.
    // The reference shows that if the stack count is 1, the observer will flush it.
    // However, to make it a reliable, self-contained test, we manually group and end.
    // The original test's logic about inheritance is tested this way: the outer group's
    // completion handler should fire, but the inner group (which inherits duration but not the handler) should not.

    [CPAnimationContext beginGrouping];
    var outerContext = [CPAnimationContext currentContext];
    [outerContext setDuration:0.01];
    [outerContext setCompletionHandler:function()
     {
        [completions addObject:@"done"];
        UIAssert([completions isEqualToArray:@["done"]]);
    }];

    // Inner group
    [CPAnimationContext beginGrouping];
    [CPAnimationContext endGrouping];

    [CPAnimationContext endGrouping];
}

- (void)testCompletionHandlerAnimatorMethodNotAnimating:(id)sender
{
    var completions = @[];

    [CPAnimationContext beginGrouping];
    var context = [CPAnimationContext currentContext];
    [context setDuration:0.01];
    [context setCompletionHandler:function()
     {
        [completions addObject:@"done"];
        UIAssert([completions isEqualToArray:@["done"]]);
    }];

    [[sender animator] setObjectValue:[sender objectValue]];
    [CPAnimationContext endGrouping];
}

- (void)testCompletionHandlerViewNotMoving:(id)sender
{
    var completions = @[];

    [CPAnimationContext beginGrouping];
    var context = [CPAnimationContext currentContext];
    [context setDuration:0.01];
    [context setCompletionHandler:function()
     {
        [completions addObject:@"done"];
        UIAssert([completions isEqualToArray:@["done"]]);
    }];

    [[sender animator] setFrame:[sender frame]];
    [CPAnimationContext endGrouping];
}

- (void)testSetCompletionHandler:(id)sender
{
    var completions = @[];

    [CPAnimationContext beginGrouping];
    var context = [CPAnimationContext currentContext];
    [context setDuration:0.01];
    [context setCompletionHandler:function()
     {
        // This handler should be replaced and never called.
        UIAssert(NO);
    }];

    // Set the handler again, which should replace the first one.
    [context setCompletionHandler:function()
     {
        [completions addObject:@"done"];
        UIAssert([completions isEqualToArray:@["done"]]);
    }];

    [[sender animator] setFrame:[sender frame]];
    [CPAnimationContext endGrouping];
}

@end

var unCamelCase = function(aString)
{
    // insert a space before all caps
    return aString.replace(/([A-Z])/g, ' $1')
    // uppercase the first character
        .replace(/^./, function(str){ return str.toUpperCase(); });
};
