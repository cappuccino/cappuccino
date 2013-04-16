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


function CGAffineTransformMake(a, b, c, d, tx, ty)
{
    return { a:a, b:b, c:c, d:d, tx:tx, ty:ty };
}

function CGAffineTransformMakeIdentity()
{
    return { a:1.0, b:0.0, c:0.0, d:1.0, tx:0.0, ty:0.0 };
}

function CGAffineTransformMakeCopy(anAffineTransform)
{
    return { a:anAffineTransform.a, b:anAffineTransform.b, c:anAffineTransform.c, d:anAffineTransform.d, tx:anAffineTransform.tx, ty:anAffineTransform.ty };
}

function CGAffineTransformMakeScale(sx, sy)
{
    return { a:sx, b:0.0, c:0.0, d:sy, tx:0.0, ty:0.0 };
}

function CGAffineTransformMakeTranslation(tx, ty)
{
    return { a:1.0, b:0.0, c:0.0, d:1.0, tx:tx, ty:ty };
}

function CGAffineTransformTranslate(aTransform, tx, ty)
{
    return CGAffineTransformMake(aTransform.a, aTransform.b, aTransform.c, aTransform.d, aTransform.tx + aTransform.a * tx + aTransform.c * ty, aTransform.ty + aTransform.b * tx + aTransform.d * ty);
}

function CGAffineTransformScale(aTransform, sx, sy)
{
    return CGAffineTransformMake(aTransform.a * sx, aTransform.b * sx, aTransform.c * sy, aTransform.d * sy, aTransform.tx, aTransform.ty);
}


function CGAffineTransformConcat(lhs, rhs)
{
    return CGAffineTransformMake(lhs.a * rhs.a + lhs.b * rhs.c, lhs.a * rhs.b + lhs.b * rhs.d, lhs.c * rhs.a + lhs.d * rhs.c, lhs.c * rhs.b + lhs.d * rhs.d, lhs.tx * rhs.a + lhs.ty * rhs.c + rhs.tx, lhs.tx * rhs.b + lhs.ty * rhs.d + rhs.ty);
}

function CGAffineTransformConcatTo(lhs, rhs, to)
{
    var tx = lhs.tx * rhs.a + lhs.ty * rhs.c + rhs.tx;

    to.ty = lhs.tx * rhs.b + lhs.ty * rhs.d + rhs.ty;
    to.tx = tx;

    var a = lhs.a * rhs.a + lhs.b * rhs.c,
        b = lhs.a * rhs.b + lhs.b * rhs.d,
        c = lhs.c * rhs.a + lhs.d * rhs.c;

    to.d = lhs.c * rhs.b + lhs.d * rhs.d;
    to.a = a;
    to.b = b;
    to.c = c;
}

function CGPointApplyAffineTransform(aPoint, aTransform)
{
    return { x:aPoint.x * aTransform.a + aPoint.y * aTransform.c + aTransform.tx,
             y:aPoint.x * aTransform.b + aPoint.y * aTransform.d + aTransform.ty };
}

function CGSizeApplyAffineTransform(aSize, aTransform)
{
    return { width:aSize.width * aTransform.a + aSize.height * aTransform.c,
             height:aSize.width * aTransform.b + aSize.height * aTransform.d };
}


function CGAffineTransformIsIdentity(aTransform)
{
    return (aTransform.a === 1.0 &&
            aTransform.b === 0.0 &&
            aTransform.c === 0.0 &&
            aTransform.d === 1.0 &&
            aTransform.tx === 0.0 &&
            aTransform.ty === 0.0);
}

function CGAffineTransformEqualToTransform(lhs, rhs)
{
    return (lhs.a === rhs.a &&
            lhs.b === rhs.b &&
            lhs.c === rhs.c &&
            lhs.d === rhs.d &&
            lhs.tx === rhs.tx &&
            lhs.ty === rhs.ty);
}


function CGStringCreateWithCGAffineTransform(aTransform)
{
    return (" [[ " + aTransform.a + ", " + aTransform.b + ", 0 ], [ " + aTransform.c + ", " + aTransform.d + ", 0 ], [ " + aTransform.tx + ", " + aTransform.ty + ", 1]]");
}


/*
    FIXME: !!!!
    @return void
    @group CGAffineTransform
*/
CGAffineTransformCreateCopy = CGAffineTransformMakeCopy;

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

    return CGAffineTransformMake(cos, sin, -sin, cos, 0.0, 0.0);
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
    var top = CGRectGetMinY(aRect),
        left = CGRectGetMinX(aRect),
        right = CGRectGetMaxX(aRect),
        bottom = CGRectGetMaxY(aRect),
        topLeft = CGPointApplyAffineTransform(CGPointMake(left, top), anAffineTransform),
        topRight = CGPointApplyAffineTransform(CGPointMake(right, top), anAffineTransform),
        bottomLeft = CGPointApplyAffineTransform(CGPointMake(left, bottom), anAffineTransform),
        bottomRight = CGPointApplyAffineTransform(CGPointMake(right, bottom), anAffineTransform),
        minX = MIN(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x),
        maxX = MAX(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x),
        minY = MIN(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y),
        maxY = MAX(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y);

    return CGRectMake(minX, minY, (maxX - minX), (maxY - minY));
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
