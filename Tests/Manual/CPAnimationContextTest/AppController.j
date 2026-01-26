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
@import <AppKit/CAAnimationGroup.j>

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

- (void)testGroupAnimation:(id)sender
{
    // Reset state
    [_testView setFrame:_initialTestViewFrame];
    [_testView setAlphaValue:1.0];
    [_pathView setPath:nil]; // Clear the path view as we aren't using it here

    // Ensure the view is layer-backed.
    // Without this, [_testView layer] returns nil.
    [_testView setWantsLayer:YES];

    var layer = [_testView layer];

    // 1. Define the start and end positions
    // CALayer 'position' corresponds to the center of the view (anchorPoint 0.5,0.5)
    var startPos = [layer position];
    
    // Safety check in case layer creation failed (though setWantsLayer:YES should ensure it)
    if (!startPos) startPos = CGPointMake(0,0);

    var endPos = CGPointMake(startPos.x + 150, startPos.y + 50);

    // 2. Create a Position Animation
    var moveAnim = [CABasicAnimation animationWithKeyPath:@"position"];
    [moveAnim setFromValue:startPos];
    [moveAnim setToValue:endPos];
    [moveAnim setDuration:1.0];

    // 3. Create an Opacity Animation
    var fadeAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [fadeAnim setFromValue:1.0];
    [fadeAnim setToValue:0.25];
    [fadeAnim setDuration:1.0];

    // 4. Group them
    // This tests the recursive logic in CAAnimationGroup and the timer logic in CALayer
    var group = [CAAnimationGroup group];
    [group setAnimations:[moveAnim, fadeAnim]];
    [group setDuration:1.0];

    // 5. Run the animation on the layer
    [layer addAnimation:group forKey:@"groupTest"];

    // 6. Verify results after the animation completes (1.0s duration + 0.1s buffer)
    [self performSelector:@selector(_verifyGroupAnimation:) withObject:endPos afterDelay:1.1];
}

- (void)_verifyGroupAnimation:(CGPoint)expectedPos
{
    var layer = [_testView layer],
        currentPos = [layer position],
        currentOpacity = [layer opacity];

    // Allow for small floating point differences
    var posPassed = (Math.abs(currentPos.x - expectedPos.x) < 1.0 && Math.abs(currentPos.y - expectedPos.y) < 1.0);
    var opacityPassed = (Math.abs(currentOpacity - 0.25) < 0.05);

    [self markTest:@selector(testGroupAnimation:) didPass:(posPassed && opacityPassed)];
    
    // Reset for next test
    [self performSelector:@selector(cleanupAfterAnimation) withObject:nil afterDelay:0.5];
}

- (void)testManualRotation:(id)sender
{
    // 1. Cleanup previous test view
    if (_testView)
        [_testView removeFromSuperview];

    // 2. Setup the RotatableView
    // View is 100x100, but the blue box drawn inside is 70x70 to allow room to spin.
    var frame = CGRectMake(390, 450, 100, 100);
    _testView = [[RotatableView alloc] initWithFrame:frame];
    [[theWindow contentView] addSubview:_testView];
    
    // Ensure layer-backed so we have a layer to animate
    [_testView setWantsLayer:YES];
    
    var layer = [_testView layer];

    // 3. Define the Animation
    // Animation is performed on _testView
    [layer setDelegate:_testView];
    var rotationAnim = [CABasicAnimation animationWithKeyPath:@"angle"];
    
    // Rotate 360 degrees (2 * PI)
    [rotationAnim setFromValue:0.0];
    [rotationAnim setToValue:2 * PI];
    [rotationAnim setDuration:2.0];
    
    // Use an easing function for smooth start/stop
    [rotationAnim setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    
    // 4. Add to Layer
    [layer addAnimation:rotationAnim forKey:@"rotateTest"];
    
    // 5. Verify results after animation
    [self performSelector:@selector(_verifyRotation:) withObject:nil afterDelay:2.1];
}

- (void)_verifyRotation:(id)sender
{
    var layer = [_testView layer];
    var endAngle = [layer angle];
    
    // Check if we reached approx 2*PI (6.28)
    var passed = (Math.abs(endAngle - (2 * PI)) < 0.1);
    
    [self markTest:@selector(testManualRotation:) didPass:passed];
    
    // Reset view
    [self performSelector:@selector(cleanupAfterAnimation) withObject:nil afterDelay:0.5];
}

@end

/* 
   A custom view that draws a box with a line in it.
   We draw the box smaller than the view bounds to prevent clipping during rotation.
*/
@implementation RotatableView : CPView
{
    float _angle;
}

- (void)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    _angle = 0;

    return self;
}

- (void)setAngle:(float)anAngle
{
    _angle = anAngle;
    [self display];
}

- (float)angle
{
    return _angle;
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds],
        cx = CGRectGetWidth(bounds) / 2.0,
        cy = CGRectGetHeight(bounds) / 2.0;

    // 1. Clear Context
    CGContextClearRect(context, bounds);

    // 2. Precompute Trig
    var cosA = Math.cos(_angle),
        sinA = Math.sin(_angle);

    /* 
       Helper closure to transform a local point (x,y) relative to center 
       into global view coordinates.
    */
    var getPoint = function(localX, localY)
    {
        // Rotation Matrix:
        // x' = x*cos - y*sin
        // y' = x*sin + y*cos
        var rotX = localX * cosA - localY * sinA;
        var rotY = localX * sinA + localY * cosA;

        // Translate back to view center
        return CGPointMake(cx + rotX, cy + rotY);
    };

    // --- DRAW BLUE SQUARE (70x70) ---
    var s = 35.0; // half size
    
    // Calculate the 4 corners manually
    var p1 = getPoint(-s, -s); // Top-Left
    var p2 = getPoint( s, -s); // Top-Right
    var p3 = getPoint( s,  s); // Bottom-Right
    var p4 = getPoint(-s,  s); // Bottom-Left

    CGContextBeginPath(context);
    CGContextMoveToPoint(context, p1.x, p1.y);
    CGContextAddLineToPoint(context, p2.x, p2.y);
    CGContextAddLineToPoint(context, p3.x, p3.y);
    CGContextAddLineToPoint(context, p4.x, p4.y);
    CGContextClosePath(context);
    
    [[CPColor greenColor] setFill];
    CGContextFillPath(context);

    // --- DRAW RED MARKER (Top-Left Corner) ---
    // A 20x20 square in the top-left of the blue box
    // Local coords relative to center: x from -35 to -15, y from -35 to -15
    var r1 = getPoint(-35, -35);
    var r2 = getPoint(-15, -35);
    var r3 = getPoint(-15, -15);
    var r4 = getPoint(-35, -15);

    CGContextBeginPath(context);
    CGContextMoveToPoint(context, r1.x, r1.y);
    CGContextAddLineToPoint(context, r2.x, r2.y);
    CGContextAddLineToPoint(context, r3.x, r3.y);
    CGContextAddLineToPoint(context, r4.x, r4.y);
    CGContextClosePath(context);

    [[CPColor redColor] setFill];
    CGContextFillPath(context);

    // --- DRAW WHITE POINTER LINE ---
    // Line from Center (0,0) to Right Edge (35, 0)
    var lineStart = getPoint(0, 0);
    var lineEnd   = getPoint(35, 0);

    CGContextBeginPath(context);
    CGContextMoveToPoint(context, lineStart.x, lineStart.y);
    CGContextAddLineToPoint(context, lineEnd.x, lineEnd.y);
    
    [[CPColor whiteColor] setStroke];
    CGContextSetLineWidth(context, 3.0);
    CGContextStrokePath(context);
}

@end

var unCamelCase = function(aString)
{
    // insert a space before all caps
    return aString.replace(/([A-Z])/g, ' $1')
    // uppercase the first character
        .replace(/^./, function(str){ return str.toUpperCase(); });
};
