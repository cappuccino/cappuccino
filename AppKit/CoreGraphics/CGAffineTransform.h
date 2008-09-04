/*
 * CGAffineTransform.h
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

#include "CGGeometry.h"

#define _CGAffineTransformMake(a_, b_, c_, d_, tx_, ty_) { a:a_, b:b_, c:c_, d:d_, tx:tx_, ty:ty_ }
#define _CGAffineTransformMakeIdentity() _CGAffineTransformMake(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
#define _CGAffineTransformMakeCopy(aTransform) _CGAffineTransformMake(aTransform.a, aTransform.b, aTransform.c, aTransform.d, aTransform.tx, aTransform.ty)

#define _CGAffineTransformMakeScale(sx, sy) _CGAffineTransformMake(sx, 0.0, 0.0, sy, 0.0, 0.0)
#define _CGAffineTransformMakeTranslation(tx, ty) _CGAffineTransformMake(1.0, 0.0, 0.0, 1.0, tx, ty)

#define _CGAffineTransformTranslate(aTransform, tx, ty) _CGAffineTransformMake(aTransform.a, aTransform.b, aTransform.c, aTransform.d, aTransform.tx + aTransform.a * tx + aTransform.c * ty, aTransform.ty + aTransform.b * tx + aTransform.d * ty)
#define _CGAffineTransformScale(aTransform, sx, sy) _CGAffineTransformMake(aTransform.a * sx, aTransform.b * sx, aTransform.c * sy, aTransform.d * sy, aTransform.tx, aTransform.ty)

#define _CGAffineTransformConcat(lhs, rhs) _CGAffineTransformMake(lhs.a * rhs.a + lhs.b * rhs.c, lhs.a * rhs.b + lhs.b * rhs.d, lhs.c * rhs.a + lhs.d * rhs.c, lhs.c * rhs.b + lhs.d * rhs.d, lhs.tx * rhs.a + lhs.ty * rhs.c + rhs.tx, lhs.tx * rhs.b + lhs.ty * rhs.d + rhs.ty)

#define _CGPointApplyAffineTransform(aPoint, aTransform) _CGPointMake(aPoint.x * aTransform.a + aPoint.y * aTransform.c + aTransform.tx, aPoint.x * aTransform.b + aPoint.y * aTransform.d + aTransform.ty)
#define _CGSizeApplyAffineTransform(aSize, aTransform) _CGSizeMake(aSize.width * aTransform.a + aSize.height * aTransform.c, aSize.width * aTransform.b + aSize.height * aTransform.d)
#define _CGRectApplyAffineTransform(aRect, aTransform) { origin:_CGPointApplyAffineTransform(aRect.origin, aTransform), size:_CGSizeApplyAffineTransform(aRect.size, aTransform) }

#define _CGAffineTransformIsIdentity(aTransform) (aTransform.a == 1 && aTransform.b == 0 && aTransform.c == 0 && aTransform.d == 1 && aTransform.tx == 0 && aTransform.ty == 0)
#define _CGAffineTransformEqualToTransform(lhs, rhs) (lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c && lhs.d == rhs.d && lhs.tx == rhs.tx && lhs.ty == rhs.ty)

#define _CGStringCreateWithCGAffineTransform(aTransform) (" [[ " + aTransform.a + ", " + aTransform.b + ", 0 ], [ " + aTransform.c + ", " + aTransform.d + ", 0 ], [ " + aTransform.tx + ", " + aTransform.ty + ", 1]]")

#define _CGAffineTransformConcatTo(lhs, rhs, to) \
var tx = lhs.tx * rhs.a + lhs.ty * rhs.c + rhs.tx;\
to.ty = lhs.tx * rhs.b + lhs.ty * rhs.d + rhs.ty;\
to.tx = tx;\
var a = lhs.a * rhs.a + lhs.b * rhs.c,\
    b = lhs.a * rhs.b + lhs.b * rhs.d,\
    c = lhs.c * rhs.a + lhs.d * rhs.c;\
to.d = lhs.c * rhs.b + lhs.d * rhs.d;\
to.a = a;\
to.b = b;\
to.c = c;\

/*
a  b  0 cos sin 0
c  d  0 -sin cos 0
tx ty 1 0 0 1
*/
