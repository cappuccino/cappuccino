/*
 * AppController.j
 * pauseDisplayServer
 *
 * Created by Blair Duncan on August 16, 2013.
 * Copyright 2013, SGL Studio, BBDO Toronto All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import <Foundation/CPInvocation.j>

@implementation AppController : CPObject
{
    CPButton    button;
    CPTextField label;
    CPString    message;
    BOOL        shouldBePaused;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    label = [CPTextField labelWithTitle:@""];
    [label setCenter:[contentView center]];
    [contentView addSubview:label];

    message = "Click to simulate many screen updates. The Display Server is:"
    button = [CPButton buttonWithTitle:message + " NOT paused (default)."];
    [button setTarget:self]
    [button setAction:@selector(buttonClick:)];
    [button setCenter:[contentView center]];
    [contentView addSubview:button];

    [theWindow orderFront:self];
}

- (void)buttonClick:(id)sender
{
    [sender setTitle:@""];
    var newTitle = message + " paused.";
    if (shouldBePaused)
    {
        [_CPDisplayServer pause]
        newTitle = message + " NOT paused (default).";
        shouldBePaused = NO;
    }        
    else
        shouldBePaused = YES;

    [self addItems:[newTitle componentsSeparatedByString:""]];
}

- (void)addItems:(CPArray)items  
{
    [button setTitle:[button title] + [items firstObject]];
    [items removeObjectAtIndex:0];
    if ([items count])
    {
        [CPTimer scheduledTimerWithTimeInterval:0
                                     invocation:[CPInvocation invocationWithTarget:self selector:@selector(addItems:) withObjects:items]
                                        repeats:NO];
    }
    else    
        [_CPDisplayServer resume];
}

@end


@implementation CPInvocation (BDAdditions)

+ (id)invocationWithTarget:(id)aTarget selector:(@selector)aSelector
{
    return [CPInvocation invocationWithTarget:aTarget selector:aSelector withObjects:nil];
}

/*!
    Creates an invocation, with any number of arguments.
    @param aTarget the target to send the message to
    @param aSelector the message to send
    @param objects... comma seperated objects to pass to the selector
    @return a new invocation
*/
+ (id)invocationWithTarget:(id)aTarget selector:(@selector)aSelector withObjects:(id)objects
{
    var invocation = [CPInvocation invocationWithMethodSignature:aSelector];
    invocation._arguments = (Array.prototype.slice.apply(arguments, [2]));
    return invocation;
}


@end

