/*
 * CAPropertyAnimation.j
 * AppKit
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

@import "CAAnimation.j"

/*!
    @ingroup appkit
    @class CAPropertyAnimation
    CAPropertyAnimation is an abstract subclass of CAAnimation for creating animations
    that manipulate the value of a target property identified by a key path.
*/
@implementation CAPropertyAnimation : CAAnimation
{
    CPString    _keyPath;

    BOOL        _isCumulative;
    BOOL        _isAdditive;
}

/*!
    Initializes a newly allocated property animation instance with default values.
    @return the initialized animation instance
*/
- (id)init
{
    self = [super init];

    _keyPath = nil;
    _isCumulative = NO;
    _isAdditive = NO;

    return self;
}

/*!
    Creates and returns a new animation instance targeting the property at the given key path.
    @param aKeyPath the key path to animate
    @return a new \c CAPropertyAnimation instance
*/
+ (id)animationWithKeyPath:(CPString)aKeyPath
{
    var animation = [self animation];

    [animation setKeyPath:aKeyPath];

    return animation;
}

/*!
    Sets the key path that specifies the property to be animated.
    @param aKeyPath the property key path
*/
- (void)setKeyPath:(CPString)aKeyPath
{
    _keyPath = aKeyPath;
}

/*!
    Returns the key path of the property being animated.
    @return the key path string
*/
- (CPString)keyPath
{
    return _keyPath;
}

/*!
    Sets whether the animation's value accumulates across repeat cycles.
    @param isCumulative \c YES to accumulate values, \c NO otherwise
*/
- (void)setCumulative:(BOOL)isCumulative
{
    _isCumulative = isCumulative;
}

/*!
    Returns whether the animation's value accumulates across repeat cycles.
    @return \c YES if cumulative, otherwise \c NO
*/
- (BOOL)cumulative
{
    return _isCumulative;
}

/*!
    Returns whether the animation's value accumulates across repeat cycles.
    @return \c YES if cumulative, otherwise \c NO
*/
- (BOOL)isCumulative
{
    return _isCumulative;
}

/*!
    Sets whether the value produced by the animation is added to the current property value.
    @param isAdditive \c YES to make the animation additive, \c NO otherwise
*/
- (void)setAdditive:(BOOL)isAdditive
{
    _isAdditive = isAdditive;
}

/*!
    Returns whether the animation value is added to the current property value.
    @return \c YES if additive, otherwise \c NO
*/
- (BOOL)additive
{
    return _isAdditive;
}

/*!
    Returns whether the animation value is added to the current property value.
    @return \c YES if additive, otherwise \c NO
*/
- (BOOL)isAdditive
{
    return _isAdditive;
}

@end
