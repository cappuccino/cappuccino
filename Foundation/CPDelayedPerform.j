/*
 * CPDelayedPerform.j
 * Foundation
 *
 * Portions based on NSDelayedPerform.m (2013-03-03) in Cocotron (http://www.cocotron.org/)
 * Copyright (c) 2006-2007 Christopher J. W. Lloyd
 *
 * Created by Alexander Ljungberg.
 * Copyright 2013, SlevenBits Ltd.
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

@import "CPObject.j"
@import "CPRunLoop.j"
@import "CPString.j"

@implementation CPDelayedPerform : CPObject
{
    id  _object;
    SEL _selector;
    id  _argument;
}

+ (CPDelayedPerform)delayedPerformWithObject:anObject selector:(SEL)aSelector argument:anArgument
{
    return [[self alloc] initWithObject:anObject selector:aSelector argument:anArgument];
}

- (id)initWithObject:(id)anObject selector:(SEL)aSelector argument:(id)anArgument
{
    if (self = [super init])
    {
        _object = anObject;
        _selector = aSelector;
        _argument = anArgument;
    }

    return self;
}

- (BOOL)isEqualToPerform:(CPDelayedPerform)anOther
{
    if (!anOther || !anOther.isa)
        return NO;

    if (_object !== anOther._object)
        return NO;

    if (!_selector || !anOther._selector)
        return YES;

    if (_selector !== anOther._selector)
        return NO;

    if (_argument !== anOther._argument)
        return NO;

   return YES;
}

- (void)perform
{
    try
    {
        [_object performSelector:_selector withObject:_argument];
    }
    catch(ex)
    {
        CPLog(@"exception %@ raised during delayed perform", ex);
    }
}

@end

@implementation CPRunLoop(CPDelayedPerform)

- (void)invalidateTimerWithDelayedPerform:(CPDelayedPerform)aDelayedPerform
{
    for (var aKey in _timersForModes)
    {
        if (!_timersForModes.hasOwnProperty(aKey))
            continue;

        var timersForMode = _timersForModes[aKey];
        for (var i = 0, count = [timersForMode count]; i < count; i++)
        {
            var aTimer = [timersForMode objectAtIndex:i],
                userInfo = [aTimer userInfo];

            if ([userInfo isKindOfClass:CPDelayedPerform] && [userInfo isEqualToPerform:aDelayedPerform])
                [aTimer invalidate];
        }
    }
}

@end

@implementation CPObject(CPDelayedPerform)

+ (void)cancelPreviousPerformRequestsWithTarget:target selector:(SEL)selector object:argument
{
    var aDelayedPerform = [CPDelayedPerform delayedPerformWithObject:target selector:selector argument:argument];

    [[CPRunLoop currentRunLoop] invalidateTimerWithDelayedPerform:aDelayedPerform];
}

+ (void)cancelPreviousPerformRequestsWithTarget:target
{
    var aDelayedPerform = [CPDelayedPerform delayedPerformWithObject:target selector:NULL argument:nil];

    [[CPRunLoop currentRunLoop] invalidateTimerWithDelayedPerform:aDelayedPerform];
}

+ (void)_delayedPerform:(CPTimer)aTimer
{
    var aDelayedPerform = [aTimer userInfo];

    [aDelayedPerform perform];
}

+ (void)object:object performSelector:(SEL)selector withObject:argument afterDelay:(CPTimeInterval)delay inModes:(CPArray)modes
{
    var aDelayedPerform = [CPDelayedPerform delayedPerformWithObject:object selector:selector argument:argument],
        aTimer = [CPTimer timerWithTimeInterval:delay target:[CPObject class] selector:@selector(_delayedPerform:) userInfo:aDelayedPerform repeats:NO];

    for (var i = 0, count = [modes count]; i < count; i++)
        [[CPRunLoop currentRunLoop] addTimer:aTimer forMode:[modes objectAtIndex:i]];
}

- (void)performSelector:(SEL)selector withObject:object afterDelay:(CPTimeInterval)delay
{
    [[self class] object:self performSelector:selector withObject:object afterDelay:delay inModes:[CPArray arrayWithObject:CPDefaultRunLoopMode]];
}

- (void)performSelector:(SEL)selector withObject:object afterDelay:(CPTimeInterval)delay inModes:(CPArray)modes
{
    [[self class] object:self performSelector:selector withObject:object afterDelay:delay inModes:modes];
}

@end
