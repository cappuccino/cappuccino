/*
 * AppController.j
 * CPAnimationContextTest
 *
 * Created by You on June 28, 2017.
 * Copyright 2017, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

#define UIAssert(a) [self markTest:_cmd didPass:a];

@implementation AppController : CPObject
{
    CPWindow theWindow;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];
    var contentView = [theWindow contentView];

    [theWindow orderFront:self];

    [self setup];
    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (void)setup
{
    var methods = class_copyMethodList([self class]);
    var testMethodCount = 0;
    [methods enumerateObjectsUsingBlock:function(meth, _)
    {
        var method_name = method_getName(meth);
        if ([method_name hasPrefix:@"test"])
        {
            var runButton = [[CPButton alloc] initWithFrame:CGRectMake(10,10 + 35*testMethodCount,0,32)];
            [runButton setTitle:unCamelCase(method_name)];
            [runButton setTarget:self];
            [runButton setAction:CPSelectorFromString(method_name)];
            [[theWindow contentView] addSubview:runButton];
            [runButton sizeToFit];

            var label = [[CPTextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX([runButton frame]) + 10, 10 + 35*testMethodCount,200,32)];
            [label setIdentifier:method_name];
            [label setFont:[CPFont systemFontOfSize:16]];
            [label setStringValue:@"………"];
            [[theWindow contentView] addSubview:label];
            testMethodCount++;
        }
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

/*
   ===================
   ====== TESTS ======
   ===================
*/

- (void)testCompletionHandlerWithoutAnimator
{
    var completions = @[];

    var ctx = [CPAnimationContext currentContext];
    [ctx setDuration:0.1];
    [ctx setCompletionHandler:function()
    {
        [completions addObject:@"done"];
        UIAssert([completions isEqualToArray:@["done"]]);
    }];
}

- (void)testCompletionHandlerWithoutAnimatorWithGrouping
{
    var completions = @[];

    var ctx = [CPAnimationContext currentContext];
    [ctx setDuration:0.1];

    [CPAnimationContext beginGrouping];
    [ctx setCompletionHandler:function()
    {
        [completions addObject:@"done"];
        UIAssert([completions isEqualToArray:@["done"]]);
    }];

    [CPAnimationContext endGrouping];
}

- (void)testCompletionHandlerWithoutAnimatorWithGrouping2
{
    var completions = @[];

    var ctx = [CPAnimationContext currentContext];
    [ctx setDuration:0.1];
    [ctx setCompletionHandler:function()
    {
        [completions addObject:@"done"];
        UIAssert([completions isEqualToArray:@["done"]]);
    }];

    // Cocoa : When grouping begins, the grouping context inherits
    // the duration & timingFunction properties from the current context
    // but NOT the completionHandler.
    // In this test, the completion handler should be performed once as part
    // of the current context (with no animations) but not as part of the
    // grouping context.
    [CPAnimationContext beginGrouping];

    [CPAnimationContext endGrouping];
}

- (void)testCompletionHandlerAnimatorMethodNotAnimating:(id)sender
{
    var completions = @[];

    [CPAnimationContext beginGrouping];

    var ctx = [CPAnimationContext currentContext];
    [ctx setDuration:0.1];
    [ctx setCompletionHandler:function()
    {
        [completions addObject:@"done"];
        UIAssert([completions isEqualToArray:@["done"]]);
    }];

    [[sender animator] setObjectValue:0];

    [CPAnimationContext endGrouping];
}

- (void)testCompletionHandlerViewNotMoving:(id)sender
{
    var completions = @[];

    [CPAnimationContext beginGrouping];

    var ctx = [CPAnimationContext currentContext];
    [ctx setDuration:0.1];
    [ctx setCompletionHandler:function()
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

    var ctx = [CPAnimationContext currentContext];
    [ctx setDuration:0.1];
    [ctx setCompletionHandler:function()
    {
        CPLog.debug("We should never be here");
        UIAssert(NO);
    }];

    [ctx setCompletionHandler:function()
    {
        [completions addObject:@"done"];
        UIAssert([completions isEqualToArray:@["done"]]);
    }];

    [[sender animator] setFrame:[sender frame]];
}

@end

var unCamelCase = function(aString)
{
        // insert a space before all caps
    return aString.replace(/([A-Z])/g, ' $1')
        // uppercase the first character
        .replace(/^./, function(str){ return str.toUpperCase(); });
};
