/*
 * CPTimer.j
 * Foundation
 *
 * Created by Nick Takayama.
 * Copyright 2008.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "CPDate.j"
@import "CPInvocation.j"
@import "CPObject.j"
@import "CPRunLoop.j"

/*!
    @class CPTimer
    @ingroup foundation

    @brief A timer object that can send a message after the given time interval.
*/
@implementation CPTimer : CPObject
{
    CPTimeInterval      _timeInterval;
    CPInvocation        _invocation;
    Function            _callback;

    BOOL                _repeats;
    BOOL                _isValid;
    CPDate              _fireDate;
    id                  _userInfo;
}

/*!
    Returns a new CPTimer object and adds it to the current CPRunLoop object in the default mode.
*/
+ (CPTimer)scheduledTimerWithTimeInterval:(CPTimeInterval)seconds invocation:(CPInvocation)anInvocation repeats:(BOOL)shouldRepeat
{
    var timer = [[self alloc] initWithFireDate:[CPDate dateWithTimeIntervalSinceNow:seconds] interval:seconds invocation:anInvocation repeats:shouldRepeat];

    [[CPRunLoop currentRunLoop] addTimer:timer forMode:CPDefaultRunLoopMode];

    return timer;
}

/*!
    Returns a new CPTimer object and adds it to the current CPRunLoop object in the default mode.
*/
+ (CPTimer)scheduledTimerWithTimeInterval:(CPTimeInterval)seconds target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)shouldRepeat
{
    var timer =  [[self alloc] initWithFireDate:[CPDate dateWithTimeIntervalSinceNow:seconds] interval:seconds target:aTarget selector:aSelector userInfo:userInfo repeats:shouldRepeat];

    [[CPRunLoop currentRunLoop] addTimer:timer forMode:CPDefaultRunLoopMode];

    return timer;
}

/*!
    Returns a new CPTimer object and adds it to the current CPRunLoop object in the default mode.
*/
+ (CPTimer)scheduledTimerWithTimeInterval:(CPTimeInterval)seconds callback:(Function)aFunction repeats:(BOOL)shouldRepeat
{
    var timer = [[self alloc] initWithFireDate:[CPDate dateWithTimeIntervalSinceNow:seconds] interval:seconds callback:aFunction repeats:shouldRepeat];

    [[CPRunLoop currentRunLoop] addTimer:timer forMode:CPDefaultRunLoopMode];

    return timer;
}

/*!
    Returns a new CPTimer that, when added to a run loop, will fire after seconds.
*/
+ (CPTimer)timerWithTimeInterval:(CPTimeInterval)seconds invocation:(CPInvocation)anInvocation repeats:(BOOL)shouldRepeat
{
    return [[self alloc] initWithFireDate:[CPDate dateWithTimeIntervalSinceNow:seconds] interval:seconds invocation:anInvocation repeats:shouldRepeat];
}

/*!
    Returns a new CPTimer that, when added to a run loop, will fire after seconds.
*/
+ (CPTimer)timerWithTimeInterval:(CPTimeInterval)seconds target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)shouldRepeat
{
    return [[self alloc] initWithFireDate:[CPDate dateWithTimeIntervalSinceNow:seconds] interval:seconds target:aTarget selector:aSelector userInfo:userInfo repeats:shouldRepeat];
}

/*!
    Returns a new CPTimer that, when added to a run loop, will fire after seconds.
*/
+ (CPTimer)timerWithTimeInterval:(CPTimeInterval)seconds callback:(Function)aFunction repeats:(BOOL)shouldRepeat
{
    return [[self alloc] initWithFireDate:[CPDate dateWithTimeIntervalSinceNow:seconds] interval:seconds callback:aFunction repeats:shouldRepeat];
}

/*!
    Initializes a new CPTimer that, when added to a run loop, will fire at date and then, if repeats is YES, every seconds after that.
*/
- (id)initWithFireDate:(CPDate)aDate interval:(CPTimeInterval)seconds invocation:(CPInvocation)anInvocation repeats:(BOOL)shouldRepeat
{
    self = [super init];

    if (self)
    {
        _timeInterval = seconds;
        _invocation = anInvocation;
        _repeats = shouldRepeat;
        _isValid = YES;
        _fireDate = aDate;
    }

    return self;
}

/*!
    Initializes a new CPTimer that, when added to a run loop, will fire at date and then, if repeats is YES, every seconds after that.
*/
- (id)initWithFireDate:(CPDate)aDate interval:(CPTimeInterval)seconds target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)shouldRepeat
{
    var invocation = [CPInvocation invocationWithMethodSignature:1];

    [invocation setTarget:aTarget];
    [invocation setSelector:aSelector];
    [invocation setArgument:self atIndex:2];

    self = [self initWithFireDate:aDate interval:seconds invocation:invocation repeats:shouldRepeat];

    if (self)
        _userInfo = userInfo;

    return self;
}

/*!
    Initializes a new CPTimer that, when added to a run loop, will fire at date and then, if repeats is YES, every seconds after that.
*/
- (id)initWithFireDate:(CPDate)aDate interval:(CPTimeInterval)seconds callback:(Function)aFunction repeats:(BOOL)shouldRepeat
{
    self = [super init];

    if (self)
    {
        _timeInterval = seconds;
        _callback = aFunction;
        _repeats = shouldRepeat;
        _isValid = YES;
        _fireDate = aDate;
    }

    return self;
}

/*!
    Returns the receiver’s time interval.
*/
- (CPTimeInterval)timeInterval
{
   return _timeInterval;
}

/*!
    Returns the date at which the receiver will fire.
*/
- (CPDate)fireDate
{
   return _fireDate;
}

/*!
    Resets the receiver to fire next at a given date.
*/
- (void)setFireDate:(CPDate)aDate
{
    _fireDate = aDate;
}

/*!
    Causes the receiver’s message to be sent to its target.
*/
- (void)fire
{
    if (!_isValid)
        return;

    if (_callback)
        _callback();
    else
        [_invocation invoke];

    if (!_isValid)
        return;

    if (_repeats)
        _fireDate = [CPDate dateWithTimeIntervalSinceNow:_timeInterval];

    else
        [self invalidate];
}

/*!
    Returns a Boolean value that indicates whether the receiver is currently valid.
*/
- (BOOL)isValid
{
   return _isValid;
}

/*!
    Stops the receiver from ever firing again and requests its removal from its CPRunLoop object.
*/
- (void)invalidate
{
   _isValid = NO;
   _userInfo = nil;
   _invocation = nil;
   _callback = nil;
}

/*!
    Returns the receiver's userInfo object.
*/
- (id)userInfo
{
   return _userInfo;
}

@end

var CPTimersTimeoutID       = 1000,
    CPTimersForTimeoutIDs   = {};

var _CPTimerBridgeTimer = function(codeOrFunction, aDelay, shouldRepeat, functionArgs)
{
    var timeoutID = CPTimersTimeoutID++,
        theFunction = nil;

    if (typeof codeOrFunction === "string")
    {
        theFunction = function()
        {
            new Function(codeOrFunction)();

            if (!shouldRepeat)
                CPTimersForTimeoutIDs[timeoutID] = nil;
        }
    }
    else
    {
        if (!functionArgs)
            functionArgs = [];

        theFunction = function()
        {
            codeOrFunction.apply(window, functionArgs);

            if (!shouldRepeat)
                CPTimersForTimeoutIDs[timeoutID] = nil;
        }
    }

    // A call such as setTimeout(f) is technically invalid but browsers seem to treat it as setTimeout(f, 0), so so will we.
    aDelay = aDelay | 0.0;

    CPTimersForTimeoutIDs[timeoutID] = [CPTimer scheduledTimerWithTimeInterval:aDelay / 1000 callback:theFunction repeats:shouldRepeat];

    return timeoutID;
};

// Avoid "TypeError: Result of expression 'window' [undefined] is not an object" when running unit tests.
// We can't use a regular PLATFORM(DOM) check because that platform constant is not defined in Foundation.
if (typeof(window) !== 'undefined')
{
    window.setTimeout = function(codeOrFunction, aDelay)
    {
        return _CPTimerBridgeTimer(codeOrFunction, aDelay, NO, Array.prototype.slice.apply(arguments, [2]));
    };

    window.clearTimeout = function(aTimeoutID)
    {
        var timer = CPTimersForTimeoutIDs[aTimeoutID];

        if (timer)
            [timer invalidate];

        CPTimersForTimeoutIDs[aTimeoutID] = nil;
    };

    window.setInterval = function(codeOrFunction, aDelay, functionArgs)
    {
        return _CPTimerBridgeTimer(codeOrFunction, aDelay, YES, Array.prototype.slice.apply(arguments, [2]));
    };

    window.clearInterval = function(aTimeoutID)
    {
        window.clearTimeout(aTimeoutID);
    };
}
