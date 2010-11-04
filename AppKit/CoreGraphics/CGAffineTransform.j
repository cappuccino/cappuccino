/*
 * CGAffineTransform.j
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

@import "CGGeometry.j"


#define _function(inline) function inline { return _##inline; }

_function(CGAffineTransformMake(a, b, c, d, tx, ty))
_function(CGAffineTransformMakeIdentity())
_function(CGAffineTransformMakeCopy(anAffineTransform))

_function(CGAffineTransformMakeScale(sx, sy))
_function(CGAffineTransformMakeTranslation(tx, ty))
_function(CGAffineTransformTranslate(aTransform, tx, ty))
_function(CGAffineTransformScale(aTransform, sx, sy))

_function(CGAffineTransformConcat(lhs, rhs))
_function(CGPointApplyAffineTransform(aPoint, aTransform))
_function(CGSizeApplyAffineTransform(aSize, aTransform))

_function(CGAffineTransformIsIdentity(aTransform))
_function(CGAffineTransformEqualToTransform(lhs, rhs))

_function(CGStringCreateWithCGAffineTransform(aTransform))

/*
    FIXME: !!!!
    @return void
    @group CGAffineTransform
*/
function CGAffineTransformCreateCopy(aTransform)
{
    return _CGAffineTransformMakeCopy(aTransform);
}

/*!
    Returns a transform that rotates a coordinate system.
    @param anAngle the amount in radians for the transform
    to rotate a coordinate system
    @return CGAffineTransform the transform with a specified
    rotation
    @group CGAffineTransform
*/
function CGAffineTransformMakeRotation(anAngle)
{
    var sin = SIN(anAngle),
        cos = COS(anAngle);
        
    return _CGAffineTransformMake(cos, sin, -sin, cos, 0.0, 0.0);
}

/*!
    Rotates a transform.
    @param aTransform the transform to rotate
    @param anAngle the amount to rotate in radians
    @return void
    @group CGAffineTransform
*/
function CGAffineTransformRotate(aTransform, anAngle)
{
    var sin = SIN(anAngle),
        cos = COS(anAngle);

    return {
            a:aTransform.a * cos + aTransform.c * sin,
            b:aTransform.b * cos + aTransform.d * sin,
            c:aTransform.c * cos - aTransform.a * sin,
            d:aTransform.d * cos - aTransform.b * sin,
            tx:aTransform.tx,
            ty:aTransform.ty
        };
}

/*!
    Inverts a transform.
    @param aTransform the transform to invert
    @return CGAffineTransform an inverted transform
    @group CGAffineTransform
*/
function CGAffineTransformInvert(aTransform)
{
    var determinant = 1 / (aTransform.a * aTransform.d - aTransform.b * aTransform.c);

    return {
        a:determinant * aTransform.d,
        b:-determinant * aTransform.b,
        c:-determinant * aTransform.c,
        d:determinant * aTransform.a,
        tx:determinant * (aTransform.c * aTransform.ty - aTransform.d * aTransform.tx),
        ty:determinant * (aTransform.b * aTransform.tx - aTransform.a * aTransform.ty)
    };
}

/*!
    Applies a transform to the rectangle's points. The transformed rectangle
    will be the smallest box that contains the transformed points.
    @param aRect the rectangle to transform
    @param anAffineTransform the transform to apply
    @return CGRect the new transformed rectangle
    @group CGAffineTransform
*/
function CGRectApplyAffineTransform(aRect, anAffineTransform)
{
    var top = _CGRectGetMinY(aRect),
        left = _CGRectGetMinX(aRect),
        right = _CGRectGetMaxX(aRect),
        bottom = _CGRectGetMaxY(aRect),
        topLeft = CGPointApplyAffineTransform(_CGPointMake(left, top), anAffineTransform),
        topRight = CGPointApplyAffineTransform(_CGPointMake(right, top), anAffineTransform),
        bottomLeft = CGPointApplyAffineTransform(_CGPointMake(left, bottom), anAffineTransform),
        bottomRight = CGPointApplyAffineTransform(_CGPointMake(right, bottom), anAffineTransform),
        minX = MIN(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x),
        maxX = MAX(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x),
        minY = MIN(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y),
        maxY = MAX(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y);
        
    return _CGRectMake(minX, minY, (maxX - minX), (maxY - minY));
}

/*!
    Creates and returns a string representation of an affine transform.
    @param anAffineTransform the transform to represent as a string
    @return CPString a string describing the transform
    @group CGAffineTransform
*/
function CPStringFromCGAffineTransform(anAffineTransform)
{
    return '{' + anAffineTransform.a + ", " + anAffineTransform.b + ", " + anAffineTransform.c + ", " + anAffineTransform.d + ", " + anAffineTransform.tx + ", " + anAffineTransform.ty + '}';
}
