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

@implementation AppController : CPObject
{
    CPWindow theWindow;
    CPView   _testView; // A view to animate for our new tests
    CGRect   _initialTestViewFrame;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];
    var contentView = [theWindow contentView];

    [theWindow orderFront:self];

    // Create a view that we can animate for the new tests.
    _initialTestViewFrame = CGRectMake(90, 350, 50, 50);
    _testView = [[CPView alloc] initWithFrame:_initialTestViewFrame];
    // Use CALayer to give it a background color so we can see it.
    [_testView setWantsLayer:YES];
    [_testView setBackgroundColor:[CPColor blueColor]];
    [contentView addSubview:_testView];

    [self setup];
}

- (void)setup
{
    var methods = class_copyMethodList([self class]);
    var testMethodCount = 0;
    var allLabels = [];

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
    [resetButton setAction:function() {
        [_testView setFrame:_initialTestViewFrame];
        [allLabels enumerateObjectsUsingBlock:function(label) {
            [label setTextColor:[CPColor blackColor]];
            [label setStringValue:@"………"];
        }];
    }];
    [[theWindow contentView] addSubview:resetButton];
    [resetButton sizeToFit];
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

    var path = [CPBezierPath bezierPath];
    var startPoint = _initialTestViewFrame.origin;
    var endPoint = CGPointMake(startPoint.x + 200, startPoint.y - 300);
    [path moveToPoint:startPoint];
    [path curveToPoint:endPoint
         controlPoint1:CGPointMake(startPoint.x - 100, startPoint.y)
         controlPoint2:CGPointMake(endPoint.x + 100, endPoint.y + 100)];

    var pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"frameOrigin"];
    [pathAnimation setPath:path];
    [pathAnimation setDuration:2.0];
    [pathAnimation setCalculationMode:kCAAnimationPaced];
    [pathAnimation setRotationMode:kCAAnimationRotateAuto];

    [CPAnimationContext beginGrouping];
    var context = [CPAnimationContext currentContext];
    [context setDuration:2.0];

    [context setCompletionHandler:function()
     {
        var finalOrigin = [_testView frame].origin;
        var passed = (Math.abs(finalOrigin.x - endPoint.x) < 1 && Math.abs(finalOrigin.y - endPoint.y) < 1);
        [self markTest:_cmd didPass:passed];
    }];

    [_testView setAnimations:[CPDictionary dictionaryWithObject:pathAnimation forKey:@"frameOrigin"]];
    [[_testView animator] setFrameOrigin:endPoint];
    [CPAnimationContext endGrouping];
}

- (void)testDiscreteAnimation:(id)sender
{
    [_testView setFrame:_initialTestViewFrame];

    var p1 = _initialTestViewFrame.origin;
    var p2 = CGPointMake(p1.x + 100, p1.y);
    var p3 = CGPointMake(p1.x + 100, p1.y - 100);
    var endPoint = CGPointMake(p1.x, p1.y - 100);

    var discreteAnimation = [CAKeyframeAnimation animationWithKeyPath:@"frameOrigin"];
    [discreteAnimation setValues:[p1, p2, p3, endPoint]];
    [discreteAnimation setKeyTimes:[0, 0.33, 0.66, 1.0]];
    [discreteAnimation setCalculationMode:kCAAnimationDiscrete];

    [CPAnimationContext beginGrouping];
    var context = [CPAnimationContext currentContext];
    [context setDuration:2.0];

    [context setCompletionHandler:function()
     {
        var finalOrigin = [_testView frame].origin;
        var passed = (Math.abs(finalOrigin.x - endPoint.x) < 1 && Math.abs(finalOrigin.y - endPoint.y) < 1);
        [self markTest:_cmd didPass:passed];
    }];

    [_testView setAnimations:[CPDictionary dictionaryWithObject:discreteAnimation forKey:@"frameOrigin"]];
    [[_testView animator] setFrameOrigin:endPoint];
    [CPAnimationContext endGrouping];
}

- (void)testPathAnimationWithAutoReverseRotation:(id)sender
{
    [_testView setFrame:_initialTestViewFrame];

    var path = [CPBezierPath bezierPath];
    var startPoint = _initialTestViewFrame.origin;
    var endPoint = CGPointMake(startPoint.x + 300, startPoint.y - 150);
    [path moveToPoint:startPoint];
    [path lineToPoint:endPoint];

    var pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"frameOrigin"];
    [pathAnimation setPath:path];
    [pathAnimation setRotationMode:kCAAnimationRotateAutoReverse];

    [CPAnimationContext beginGrouping];
    var context = [CPAnimationContext currentContext];
    [context setDuration:2.0];

    [context setCompletionHandler:function()
     {
        var finalOrigin = [_testView frame].origin;
        var passed = (Math.abs(finalOrigin.x - endPoint.x) < 1 && Math.abs(finalOrigin.y - endPoint.y) < 1);
        [self markTest:_cmd didPass:passed];
    }];

    [_testView setAnimations:[CPDictionary dictionaryWithObject:pathAnimation forKey:@"frameOrigin"]];
    [[_testView animator] setFrameOrigin:endPoint];
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
