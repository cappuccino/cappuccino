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

/*!
 @ingroup appkit
 @class CAAnimation
 CAAnimation is the abstract superclass for animations in Cappuccino's Core Animation support.
 */
@implementation CAAnimation : CPObject
{
    BOOL                    _isRemovedOnCompletion;
    id                      _delegate;
    CAMediaTimingFunction   _timingFunction @accessors(property=timingFunction);
    double                  _duration @accessors(property=duration);
}

/*!
 Creates and returns a new \c CAAnimation instance.
 @return a new \c CAAnimation instance
 */
+ (id)animation
{
    return [[self alloc] init];
}

/*!
 Initializes a newly allocated animation instance with default values.
 @return the initialized animation instance
 */
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
 Returns whether the value for a given key should be archived.
 @param aKey the key to check
 @return \c YES if the value should be archived
 */
- (BOOL)shouldArchiveValueForKey:(CPString)aKey
{
    return YES;
}

/*!
 Returns the default value associated with the specified key.
 @param aKey the key to inspect
 @return the default value, or \c nil
 */
+ (id)defaultValueForKey:(CPString)aKey
{
    return nil;
}

/*!
 Specifies whether this animation should be removed after it has completed.
 @param isRemovedOnCompletion \c YES if the animation should be removed on completion
 */
- (void)setRemovedOnCompletion:(BOOL)isRemovedOnCompletion
{
    _isRemovedOnCompletion = isRemovedOnCompletion;
}

/*!
 Returns whether the animation is removed after completion.
 @return \c YES if the animation is removed after completion
 */
- (BOOL)removedOnCompletion
{
    return _isRemovedOnCompletion;
}

/*!
 Returns whether the animation is removed after completion.
 @return \c YES if the animation is removed after completion
 */
- (BOOL)isRemovedOnCompletion
{
    return _isRemovedOnCompletion;
}

/*!
 Returns the animation's timing function. If \c nil, linear pacing is used.
 @return the timing function, or \c nil
 */
- (CAMediaTimingFunction)timingFunction
{
    // Linear Pacing
    return _timingFunction;
}

/*!
 Sets the animation's delegate.
 @param aDelegate the new delegate
 */
- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

/*!
 Returns the animation's delegate.
 @return the animation's delegate
 */
- (id)delegate
{
    return _delegate;
}

/*!
 Executes the action on the given object for the specified key.
 @param aKey the identifier of the action
 @param anObject the target object of the animation
 @param arguments additional arguments for the action
 */
- (void)runActionForKey:(CPString)aKey object:(id)anObject arguments:(CPDictionary)arguments
{
    [anObject addAnimation:self forKey:aKey];
}

@end
