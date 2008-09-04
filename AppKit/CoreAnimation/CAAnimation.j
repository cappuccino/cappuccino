/*
 * CAAnimation.j
 * AppKit
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

import <Foundation/CPObject.j>
import <Foundation/CPString.j>

import "CAMediaTimingFunction.j"


@implementation CAAnimation : CPObject
{
    BOOL    _isRemovedOnCompletion;
}

+ (id)animation
{
    return [[self alloc] init];
}

- (id)init
{
    self = [super init];
    
    if (self)
        _isRemovedOnCompletion = YES;
        
    return self;
}

- (void)shouldArchiveValueForKey:(CPString)aKey
{
    return YES;
}

+ (id)defaultValueForKey:(CPString)aKey
{
    return nil;
}

- (void)setRemovedOnCompletion:(BOOL)isRemovedOnCompletion
{
    _isRemovedOnCompletion = isRemovedOnCompletion;
}

- (BOOL)removedOnCompletion
{
    return _isRemovedOnCompletion;
}

- (BOOL)isRemovedOnCompletion
{
    return _isRemovedOnCompletion;
}

- (CAMediaTimingFunction)timingFunction
{
    // Linear Pacing
    return nil;
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

- (id)delegate
{
    return _delegate;
}

- (void)runActionForKey:(CPString)aKey object:(id)anObject arguments:(CPDictionary)arguments
{
    [anObject addAnimation:self forKey:aKey];
}

@end

@implementation CAPropertyAnimation : CAAnimation
{
    CPString    _keyPath;
    
    BOOL        _isCumulative;
    BOOL        _isAdditive;
}

+ (id)animationWithKeyPath:(CPString)aKeyPath
{
    var animation = [self animation];
    
    [animation setKeypath:aKeyPath];
    
    return animation;
}

- (void)setKeyPath:(CPString)aKeyPath
{
    _keyPath = aKeyPath;
}

- (CPString)keyPath
{
    return _keyPath;
}

- (void)setCumulative:(BOOL)isCumulative
{
    _isCumulative = isCumulative;
}

- (BOOL)cumulative
{
    return _isCumulative;
}

- (BOOL)isCumulative
{
    return _isCumulative;
}

- (void)setAdditive:(BOOL)isAdditive
{
    _isAdditive = isAdditive;
}

- (BOOL)additive
{
    return _isAdditive;
}

- (BOOL)isAdditive
{
    return _isAdditive;
}

@end

@implementation CABasicAnimation : CAPropertyAnimation
{
    id  _fromValue;
    id  _toValue;
    id  _byValue;
}

- (void)setFromValue:(id)aValue
{
    _fromValue = aValue;
}

- (id)fromValue
{
    return _fromValue;
}

- (void)setToValue:(id)aValue
{
    _toValue = aValue;
}

- (id)toValue
{
    return _toValue;
}

- (void)setByValue:(id)aValue
{
    _byValue = aValue;
}

- (id)byValue
{
    return _byValue;
}

@end
