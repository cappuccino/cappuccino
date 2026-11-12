/*
 * CAKeyframeAnimation.j
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
@import "CAPropertyAnimation.j"

/*!
    @global
    Simple linear interpolation between keyframe values.
*/
kCAAnimationLinear = @"linear";

/*!
    @global
    Discrete interpolation where values jump directly from one keyframe to the next.
*/
kCAAnimationDiscrete = @"discrete";

/*!
    @global
    Paced interpolation produces an even pace throughout the animation.
*/
kCAAnimationPaced = @"paced";

/*!
    @global
    Cubic spline interpolation using tension, continuity, and bias values.
*/
kCAAnimationCubic = @"cubic";

/*!
    @global
    Cubic spline interpolation with paced timing.
*/
kCAAnimationCubicPaced = @"cubicPaced";

/*!
    @global
    The object rotates to match the tangent of the path.
*/
kCAAnimationRotateAuto = @"auto";

/*!
    @global
    The object rotates to match the tangent of the path, plus 180 degrees.
*/
kCAAnimationRotateAutoReverse = @"autoReverse";

/*!
    @ingroup appkit
    @class CAKeyframeAnimation
    An object that provides keyframe-based animation capabilities for a layer property.
*/
@implementation CAKeyframeAnimation : CAPropertyAnimation
{
    CPArray     _values @accessors(property=values);
    CPArray     _keyTimes @accessors(property=keyTimes);
    CPArray     _timingFunctions @accessors(property=timingFunctions);
    id          _path @accessors(property=path);
    CPString    _calculationMode @accessors(property=calculationMode);
    CPString    _rotationMode @accessors(property=rotationMode);
    CPArray     _tensionValues @accessors(property=tensionValues);
    CPArray     _continuityValues @accessors(property=continuityValues);
    CPArray     _biasValues @accessors(property=biasValues);
}

/*!
    Initializes a newly allocated keyframe animation instance with default empty arrays.
    @return the initialized keyframe animation instance
*/
- (id)init
{
    self = [super init];

    _values = [CPArray array];
    _keyTimes = [CPArray array];
    _timingFunctions = [CPArray array];
    _tensionValues = [CPArray array];
    _continuityValues = [CPArray array];
    _biasValues = [CPArray array];

    return self;
}

@end
