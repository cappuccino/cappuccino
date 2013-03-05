/*
 * CPRunLoop.j
 * Foundation
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

@import "CPArray.j"
@import "CPDate.j"
@import "CPObject.j"
@import "CPString.j"

/*!
    @global
    @group CPRunLoopMode
*/
CPDefaultRunLoopMode    = @"CPDefaultRunLoopMode";

function _CPRunLoopPerformCompare(lhs, rhs)
{
    return [rhs order] - [lhs order];
}

var _CPRunLoopPerformPool           = [],
    _CPRunLoopPerformPoolCapacity   = 5;

/* @ignore */
@implementation _CPRunLoopPerform : CPObject
{
    id          _target;
    SEL         _selector;
    id          _argument;
    unsigned    _order;
    CPArray     _runLoopModes;
    BOOL        _isValid;
}

+ (void)_poolPerform:(_CPRunLoopPerform)aPerform
{
    if (!aPerform || _CPRunLoopPerformPool.length >= _CPRunLoopPerformPoolCapacity)
        return;

    _CPRunLoopPerformPool.push(aPerform);
}

+ (_CPRunLoopPerform)performWithSelector:(SEL)aSelector target:(id)aTarget argument:(id)anArgument order:(unsigned)anOrder modes:(CPArray)modes
{
    if (_CPRunLoopPerformPool.length)
    {
        var perform = _CPRunLoopPerformPool.pop();

        perform._target = aTarget;
        perform._selector = aSelector;
        perform._argument = anArgument;
        perform._order = anOrder;
        perform._runLoopModes = modes;
        perform._isValid = YES;

        return perform;
    }

    return [[self alloc] initWithSelector:aSelector target:aTarget argument:anArgument order:anOrder modes:modes];
}

- (id)initWithSelector:(SEL)aSelector target:(SEL)aTarget argument:(id)anArgument order:(unsigned)anOrder modes:(CPArray)modes
{
    self = [super init];

    if (self)
    {
        _selector = aSelector;
        _target = aTarget;
        _argument = anArgument;
        _order = anOrder;
        _runLoopModes = modes;
        _isValid = YES;
    }

    return self;
}

- (SEL)selector
{
    return _selector;
}

- (id)target
{
    return _target;
}

- (id)argument
{
    return _argument;
}

- (unsigned)order
{
    return _order;
}

- (BOOL)fireInMode:(CPString)aRunLoopMode
{
    if (!_isValid)
        return YES;

    if ([_runLoopModes containsObject:aRunLoopMode])
    {
        [_target performSelector:_selector withObject:_argument];

        return YES;
    }

    return NO;
}

- (void)invalidate
{
    _isValid = NO;
}

@end

var CPRunLoopLastNativeRunLoop = 0;

/*!
    @class CPRunLoop
    @ingroup foundation
    @brief The main run loop for the application.

    CPRunLoop instances handle various utility tasks that must be performed repetitively in an application, such as processing input events.

    There is one run loop per application, which may always be obtained through the +currentRunLoop method,
*/
@implementation CPRunLoop : CPObject
{
    BOOL    _runLoopLock;

    Object  _timersForModes; //should be a dictionary to allow lookups by mode
    Object  _nativeTimersForModes;
    CPDate  _nextTimerFireDatesForModes;
    BOOL    _didAddTimer;
    CPDate  _effectiveDate;

    CPArray _orderedPerforms;
    int     _runLoopInsuranceTimer;
}

/*
    @ignore
*/
+ (void)initialize
{
    if (self !== [CPRunLoop class])
        return;

    CPMainRunLoop = [[CPRunLoop alloc] init];
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _orderedPerforms = [];

        _timersForModes = {};
        _nativeTimersForModes = {};
        _nextTimerFireDatesForModes = {};
    }

    return self;
}

/*!
    Returns the application's singleton CPRunLoop.
*/
+ (CPRunLoop)currentRunLoop
{
    return CPMainRunLoop;
}

/*!
    Returns the application's singleton CPRunLoop.
*/
+ (CPRunLoop)mainRunLoop
{
    return CPMainRunLoop;
}

/*!
    Performs the specified selector on the specified target. The method will be invoked synchronously.
    @param aSelector the selector of the method to invoke
    @param aTarget the target of the selector
    @param anArgument the method argument
    @param anOrder the message priority
    @param modes the modes variable isn't respected.
*/
- (void)performSelector:(SEL)aSelector target:(id)aTarget argument:(id)anArgument order:(int)anOrder modes:(CPArray)modes
{
    var perform = [_CPRunLoopPerform performWithSelector:aSelector target:aTarget argument:anArgument order:anOrder modes:modes],
        count = _orderedPerforms.length;

    // We sort ourselves in reverse because we iterate this list backwards.
    while (count--)
        if (anOrder < [_orderedPerforms[count] order])
            break;

    _orderedPerforms.splice(count + 1, 0, perform);
}

/*!
    Cancels the specified selector and target.
    @param aSelector the selector of the method to invoke
    @param aTarget the target to invoke the method on
    @param the argument for the method
*/
- (void)cancelPerformSelector:(SEL)aSelector target:(id)aTarget argument:(id)anArgument
{
    var count = _orderedPerforms.length;

    while (count--)
    {
        var perform = _orderedPerforms[count];

        if ([perform selector] === aSelector && [perform target] == aTarget && [perform argument] == anArgument)
            [_orderedPerforms[count] invalidate];
    }
}

/*
    @ignore
*/
- (void)performSelectors
{
    [self limitDateForMode:CPDefaultRunLoopMode];
}

/*!
    Registers a given timer with a given input mode.
*/
- (void)addTimer:(CPTimer)aTimer forMode:(CPString)aMode
{
    // FIXME: Timer already added...
    if (_timersForModes[aMode])
        _timersForModes[aMode].push(aTimer);
    else
        _timersForModes[aMode] = [aTimer];

    _didAddTimer = YES;

    if (!aTimer._lastNativeRunLoopsForModes)
        aTimer._lastNativeRunLoopsForModes = {};

    aTimer._lastNativeRunLoopsForModes[aMode] = CPRunLoopLastNativeRunLoop;

    // FIXME: Hack for not doing this in CommonJS
    if ([CFBundle.environments() indexOfObject:("Browser")] !== CPNotFound)
    {
        if (!_runLoopInsuranceTimer)
            _runLoopInsuranceTimer = window.setNativeTimeout(function()
            {
                [self limitDateForMode:CPDefaultRunLoopMode];
            }, 0);
    }
}

/*!
    Performs one pass through the run loop in the specified mode and returns the date at which the next timer is scheduled to fire.
*/
- (CPDate)limitDateForMode:(CPString)aMode
{
    //simple locking to try to prevent concurrent iterating over timers
    if (_runLoopLock)
        return;

    _runLoopLock = YES;

    // FIXME: Hack for not doing this in CommonJS
    if ([CFBundle.environments() indexOfObject:("Browser")] !== CPNotFound)
    {
        if (_runLoopInsuranceTimer)
        {
            window.clearNativeTimeout(_runLoopInsuranceTimer);
            _runLoopInsuranceTimer = nil;
        }
    }

    var now = _effectiveDate ? [_effectiveDate laterDate:[CPDate date]] : [CPDate date],
        nextFireDate = nil,
        nextTimerFireDate = _nextTimerFireDatesForModes[aMode];

    // Perform Timers if necessary

    if (_didAddTimer || nextTimerFireDate && nextTimerFireDate <= now)
    {
        _didAddTimer = NO;

        // Cancel existing window.setTimeout
        if (_nativeTimersForModes[aMode] !== nil)
        {
            window.clearNativeTimeout(_nativeTimersForModes[aMode]);

            _nativeTimersForModes[aMode] = nil;
        }

        // Empty timers to avoid catastrophe if a timer is added during a timer fire.
        var timers = _timersForModes[aMode],
            index = timers.length;

        _timersForModes[aMode] = nil;

        // If we're running in CommonJS (unit tests) we shouldn't wait for at least 1 native run loop
        // since those will never happen.
        var hasNativeTimers = [CFBundle.environments() indexOfObject:("Browser")] !== CPNotFound;

        // Loop through timers looking for ones that had fired
        while (index--)
        {
            var timer = timers[index];

            if ((!hasNativeTimers || timer._lastNativeRunLoopsForModes[aMode] < CPRunLoopLastNativeRunLoop) && timer._isValid && timer._fireDate <= now)
                [timer fire];

            // Timer may or may not still be valid
            if (timer._isValid)
                nextFireDate = (nextFireDate === nil) ? timer._fireDate : [nextFireDate earlierDate:timer._fireDate];

            else
            {
                // FIXME: Is there an issue with reseting the fire date in -fire? or adding it back to the run loop?...
                timer._lastNativeRunLoopsForModes[aMode] = 0;

                timers.splice(index, 1);
            }
        }

        // Timers may have been added during the firing of timers
        // They do NOT get a shot at firing, because they certainly
        // haven't gone through one native timer.
        var newTimers = _timersForModes[aMode];

        if (newTimers && newTimers.length)
        {
            index = newTimers.length;

            while (index--)
            {
                var timer = newTimers[index];

                if ([timer isValid])
                    nextFireDate = (nextFireDate === nil) ? timer._fireDate : [nextFireDate earlierDate:timer._fireDate];
                else
                    newTimers.splice(index, 1);
            }

            _timersForModes[aMode] = newTimers.concat(timers);
        }
        else
            _timersForModes[aMode] = timers;

        _nextTimerFireDatesForModes[aMode] = nextFireDate;

        //initiate a new window.setTimeout if there are any timers
        if (_nextTimerFireDatesForModes[aMode] !== nil)
            _nativeTimersForModes[aMode] = window.setNativeTimeout(function()
                {
                    _effectiveDate = nextFireDate;
                    _nativeTimersForModes[aMode] = nil;
                    ++CPRunLoopLastNativeRunLoop;
                    [self limitDateForMode:aMode];
                    _effectiveDate = nil;
                }, MAX(0, [nextFireDate timeIntervalSinceNow] * 1000));
    }

    // Run loop performers
    var performs = _orderedPerforms,
        index = performs.length;

    _orderedPerforms = [];

    while (index--)
    {
        var perform = performs[index];

        if ([perform fireInMode:CPDefaultRunLoopMode])
        {
            [_CPRunLoopPerform _poolPerform:perform];

            performs.splice(index, 1);
        }
    }

    if (_orderedPerforms.length)
    {
        _orderedPerforms = _orderedPerforms.concat(performs);
        _orderedPerforms.sort(_CPRunLoopPerformCompare);
    }
    else
        _orderedPerforms = performs;

    _runLoopLock = NO;

    return nextFireDate;
}

@end
