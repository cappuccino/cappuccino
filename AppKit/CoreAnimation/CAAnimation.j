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
    BOOL                    _isRemovedOnCompletion;
    id                      _delegate;
    CAMediaTimingFunction   _timingFunction @accessors(property=timingFunction);
    double                  _duration @accessors(property=duration);
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

    _isRemovedOnCompletion = YES;
    _timingFunction = nil;
    _duration = 0.0;
    _delegate = nil;

    return self;
}

/*!
    Returns \c YES
    @return \c YES
*/
- (void)shouldArchiveValueForKey:(CPString)aKey
{
    return YES;
}

/*!
    Returns \c nil
    @return \c nil
*/
+ (id)defaultValueForKey:(CPString)aKey
{
    return nil;
}

/*!
    Specifies whether this animation should be removed after it has completed.
    @param \c YES means the animation should be removed
*/
- (void)setRemovedOnCompletion:(BOOL)isRemovedOnCompletion
{
    _isRemovedOnCompletion = isRemovedOnCompletion;
}

/*!
    Returns \c YES if the animation is removed after completion
*/
- (BOOL)removedOnCompletion
{
    return _isRemovedOnCompletion;
}

/*!
    Returns \c YES if the animation is removed after completion
*/
- (BOOL)isRemovedOnCompletion
{
    return _isRemovedOnCompletion;
}

/*!
    Returns the animation's timing function. If \c nil, then it has a linear pacing.
*/
- (CAMediaTimingFunction)timingFunction
{
    // Linear Pacing
    return _timingFunction;
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