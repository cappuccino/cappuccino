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

import "CPObject.j"
import "CPArray.j"
import "CPString.j"

CPDefaultRunLoopMode    = @"CPDefaultRunLoopMode";

function _CPRunLoopPerformCompare(lhs, rhs)
{
    return [rhs order] - [lhs order];
}

var _CPRunLoopPerformPool           = [],
    _CPRunLoopPerformPoolCapacity   = 5;

@implementation _CPRunLoopPerform : CPObject
{
    id          _target;
    SEL         _selector;
    id          _argument;
    unsigned    _order;
    CPArray     _runLoopModes;
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
        perform._arguments = anArgument;
        perform._order = anOrder;
        perform._runLoopModes = modes;
        
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
    if ([_runLoopModes containsObject:aRunLoopMode])
    {
        [_target performSelector:_selector withObject:_argument];
        
        return YES;
    }
    
    return NO;
}

@end

@implementation CPRunLoop : CPObject
{
    CPArray _queuedPerforms;
    CPArray _orderedPerforms;
    BOOL    _isPerformingSelectors;
}

+ (void)initialize
{
    if (self != [CPRunLoop class])
        return;

    CPMainRunLoop = [[CPRunLoop alloc] init];
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _queuedPerforms = [];
        _orderedPerforms = [];
    }
    
    return self;
}

+ (CPRunLoop)currentRunLoop
{
    return CPMainRunLoop;
}

+ (CPRunLoop)mainRunLoop
{
    return CPMainRunLoop;
}

- (void)performSelector:(SEL)aSelector target:(id)aTarget argument:(id)anArgument order:(int)anOrder modes:(CPArray)modes
{
    var perform = [_CPRunLoopPerform performWithSelector:aSelector target:aTarget argument:anArgument order:anOrder modes:modes];

    if (_isPerformingSelectors)
        _queuedPerforms.push(perform);
    else
    {
        var count = _orderedPerforms.length;
    
        // We sort ourselves in reverse because we iterate this list backwards.
        while (count--)
            if (anOrder < [_orderedPerforms[count] order])
                break;
        
        _orderedPerforms.splice(count + 1, 0, perform);
    }
}

- (void)cancelPerformSelector:(SEL)aSelector target:(id)aTarget argument:(id)anArgument
{
    var count = _orderedPerforms.length;
    
    while (count--)
    {
        var perform = _orderedPerforms[count];
        
        if ([perform selector] == aSelector && [perform target] == aTarget && [perform argument] == anArgument)
            [_orderedPerforms removeObjectAtIndex:count];
    }
}

- (void)performSelectors
{
    if (_isPerformingSelectors)
        return;
        
    _isPerformingSelectors = YES;
    
    var index = _orderedPerforms.length;
    
    while (index--)
    {
        var perform = _orderedPerforms[index];
        
        if ([perform fireInMode:CPDefaultRunLoopMode])
        {
            [_CPRunLoopPerform _poolPerform:perform];
            
            _orderedPerforms.splice(index, 1);
        }
    }
    
    _isPerformingSelectors = NO;
    
    if (_queuedPerforms.length)
    {
        _orderedPerforms = _orderedPerforms.concat(_queuedPerforms);
        _orderedPerforms.sort(_CPRunLoopPerformCompare);
    }
    
    _queuedPerforms = [];
}

@end