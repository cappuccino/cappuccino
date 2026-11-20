/*
 * CAMediaTimingFunction.j
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
@import <Foundation/CPDictionary.j>
@import <Foundation/CPString.j>

/*!
    @global
    Linear pacing animation timing curve.
*/
kCAMediaTimingFunctionLinear        = @"kCAMediaTimingFunctionLinear";

/*!
    @global
    Ease-in pacing animation timing curve (starts slowly and accelerates towards the end).
*/
kCAMediaTimingFunctionEaseIn        = @"kCAMediaTimingFunctionEaseIn";

/*!
    @global
    Ease-out pacing animation timing curve (starts quickly and decelerates towards the end).
*/
kCAMediaTimingFunctionEaseOut       = @"kCAMediaTimingFunctionEaseOut";

/*!
    @global
    Ease-in-ease-out pacing animation timing curve (starts slowly, speeds up in the middle, and slows down at the end).
*/
kCAMediaTimingFunctionEaseInEaseOut = @"kCAMediaTimingFunctionEaseInEaseOut";

/* @ignore */
var CAMediaNamedTimingFunctions = nil;

/*!
    @ingroup appkit
    @class CAMediaTimingFunction
    A CAMediaTimingFunction represents the timing curve of an animation as a cubic Bézier curve.
*/
@implementation CAMediaTimingFunction : CPObject
{
    float _c1x;
    float _c1y;
    float _c2x;
    float _c2y;
}

/*!
    Returns a predefined media timing function matching the given name.
    @param aName the name of the predefined timing curve (e.g. \c kCAMediaTimingFunctionLinear)
    @return the predefined timing function instance
*/
+ (id)functionWithName:(CPString)aName
{
    if (!CAMediaNamedTimingFunctions)
    {
        CAMediaNamedTimingFunctions = @{};

        [CAMediaNamedTimingFunctions setObject:[CAMediaTimingFunction functionWithControlPoints:0.0 :0.0 :1.0 :1.0] forKey:kCAMediaTimingFunctionLinear];
        [CAMediaNamedTimingFunctions setObject:[CAMediaTimingFunction functionWithControlPoints:0.42 :0.0 :1.0 :1.0] forKey:kCAMediaTimingFunctionEaseIn];
        [CAMediaNamedTimingFunctions setObject:[CAMediaTimingFunction functionWithControlPoints:0.0 :0.0 :0.58 :1.0] forKey:kCAMediaTimingFunctionEaseOut];
        [CAMediaNamedTimingFunctions setObject:[CAMediaTimingFunction functionWithControlPoints:0.42 :0.0 :0.58 :1.0] forKey:kCAMediaTimingFunctionEaseInEaseOut];
    }

    return [CAMediaNamedTimingFunctions objectForKey:aName];
}

/*!
    Creates and returns a new media timing function with custom cubic Bézier control points.
    @param c1x the x-coordinate of the first control point
    @param c1y the y-coordinate of the first control point
    @param c2x the x-coordinate of the second control point
    @param c2y the y-coordinate of the second control point
    @return a new \c CAMediaTimingFunction instance
*/
+ (id)functionWithControlPoints:(float)c1x :(float)c1y :(float)c2x :(float)c2y
{
    return [[self alloc] initWithControlPoints:c1x :c1y :c2x :c2y];
}

/*!
    Initializes a newly allocated media timing function with custom cubic Bézier control points.
    @param c1x the x-coordinate of the first control point
    @param c1y the y-coordinate of the first control point
    @param c2x the x-coordinate of the second control point
    @param c2y the y-coordinate of the second control point
    @return the initialized \c CAMediaTimingFunction instance
*/
- (id)initWithControlPoints:(float)c1x :(float)c1y :(float)c2x :(float)c2y
{
    self = [super init];

    if (self)
    {
        _c1x = c1x;
        _c1y = c1y;
        _c2x = c2x;
        _c2y = c2y;
    }

    return self;
}

/*!
    Retrieves the coordinates of the control point at the specified index.
    @param anIndex the index of the control point (0, 1, 2, or 3)
    @param reference an array of two floats that will receive the (x, y) coordinates
*/
- (void)getControlPointAtIndex:(CPUInteger)anIndex values:(float/*[2]*/)reference
{
    if (anIndex == 0)
    {
        reference[0] = 0;
        reference[1] = 0;
    }
    else if (anIndex == 1)
    {
        reference[0] = _c1x;
        reference[1] = _c1y;
    }
    else if (anIndex == 2)
    {
        reference[0] = _c2x;
        reference[1] = _c2y;
    }
    else
    {
        reference[0] = 1.0;
        reference[1] = 1.0;
    }
}

@end
