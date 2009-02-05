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

@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>

@import "CAMediaTimingFunction.j"

/*
    This is an animation class.
*/
@implementation CAAnimation : CPObject
{
    BOOL    _isRemovedOnCompletion;
    id      _delegate;
}

/*!
    Creates a new CAAnimation instance
    @return a new CAAnimation instance
*/
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

/*!
    Returns <code>YES</code>
    @return <code>YES</code>
*/
- (void)shouldArchiveValueForKey:(CPString)aKey
{
    return YES;
}

/*!
    Returns <code>nil</code>
    @return <code>nil</code>
*/
+ (id)defaultValueForKey:(CPString)aKey
{
    return nil;
}

/*!
    Specifies whether this animation should be removed after it has completed.
    @param <code>YES</code> means the animation should be removed
*/
- (void)setRemovedOnCompletion:(BOOL)isRemovedOnCompletion
{
    _isRemovedOnCompletion = isRemovedOnCompletion;
}

/*!
    Returns <code>YES</code> if the animation is removed after completion
*/
- (BOOL)removedOnCompletion
{
    return _isRemovedOnCompletion;
}

/*!
    Returns <code>YES</code> if the animation is removed after completion
*/
- (BOOL)isRemovedOnCompletion
{
    return _isRemovedOnCompletion;
}

/*!
    Returns the animation's timing function. If <code>nil</code>, then it has a linear pacing.
*/
- (CAMediaTimingFunction)timingFunction
{
    // Linear Pacing
    return nil;
}

/*!
    Sets the animation delegate
    @param aDelegate the new delegate
*/
- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

/*!
    Returns the animation's delegate
*/
- (id)delegate
{
    return _delegate;
}

- (void)runActionForKey:(CPString)aKey object:(id)anObject arguments:(CPDictionary)arguments
{
    [anObject addAnimation:self forKey:aKey];
}

@end

/*
    
*/
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

/*!
    A CABasicAnimation is a simple animation that moves a
    CALayer from one point to another over a specified
    period of time.
*/
@implementation CABasicAnimation : CAPropertyAnimation
{
    id  _fromValue;
    id  _toValue;
    id  _byValue;
}

/*!
    Sets the starting position for the animation.
    @param aValue the animation starting position
*/
- (void)setFromValue:(id)aValue
{
    _fromValue = aValue;
}

/*!
    Returns the animation's starting position.
*/
- (id)fromValue
{
    return _fromValue;
}

/*!
    Sets the ending position for the animation.
    @param aValue the animation ending position
*/
- (void)setToValue:(id)aValue
{
    _toValue = aValue;
}

/*!
    Returns the animation's ending position.
*/
- (id)toValue
{
    return _toValue;
}

/*!
    Sets the optional byValue for animation interpolation.
    @param aValue the byValue
*/
- (void)setByValue:(id)aValue
{
    _byValue = aValue;
}

/*!
    Returns the animation's byValue.
*/
- (id)byValue
{
    return _byValue;
}

@end
