/*
 * CGGeometry.h
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

#define _CGPointMake(x_, y_) { x:x_, y:y_ }
#define _CGPointMakeCopy(aPoint) _CGPointMake(aPoint.x, aPoint.y)
#define _CGPointMakeZero() _CGPointMake(0.0, 0.0)

#define _CGPointEqualToPoint(lhsPoint, rhsPoint) (lhsPoint.x == rhsPoint.x && lhsPoint.y == rhsPoint.y)
#define _CGStringFromPoint(aPoint) ("{" + aPoint.x + ", " + aPoint.y + "}")

#define _CGSizeMake(width_, height_) { width:width_, height:height_ }
#define _CGSizeMakeCopy(aSize) _CGSizeMake(aSize.width, aSize.height)
#define _CGSizeMakeZero() _CGSizeMake(0.0, 0.0)

#define _CGSizeEqualToSize(lhsSize, rhsSize) (lhsSize.width == rhsSize.width && lhsSize.height == rhsSize.height)
#define _CGStringFromSize(aSize) ("{" + aSize.width + ", " + aSize.height + "}")

#define _CGRectMake(x, y, width, height) { origin: _CGPointMake(x, y), size: _CGSizeMake(width, height) }
#define _CGRectMakeZero() _CGRectMake(0.0, 0.0, 0.0, 0.0)
#define _CGRectMakeCopy(aRect) _CGRectMake(aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height)
#define _CGRectCreateCopy(aRect) _CGRectMake(aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height)

#define _CGRectEqualToRect(lhsRect, rhsRect) (_CGPointEqualToPoint(lhsRect.origin, rhsRect.origin) && _CGSizeEqualToSize(lhsRect.size, rhsRect.size))
#define _CGStringFromRect(aRect) ("{" + _CGStringFromPoint(aRect.origin) + ", " + _CGStringFromSize(aRect.size) + "}")

#define _CGRectOffset(aRect, dX, dY) _CGRectMake(aRect.origin.x + dX, aRect.origin.y + dY, aRect.size.width, aRect.size.height)
#define _CGRectInset(aRect, dX, dY) _CGRectMake(aRect.origin.x + dX, aRect.origin.y + dY, aRect.size.width - 2 * dX, aRect.size.height - 2 * dY)

#define _CGRectGetHeight(aRect) (aRect.size.height)
#define _CGRectGetMaxX(aRect) (aRect.origin.x + aRect.size.width)
#define _CGRectGetMaxY(aRect) (aRect.origin.y + aRect.size.height)
#define _CGRectGetMidX(aRect) (aRect.origin.x + (aRect.size.width) / 2.0)
#define _CGRectGetMidY(aRect) (aRect.origin.y + (aRect.size.height) / 2.0)
#define _CGRectGetMinX(aRect) (aRect.origin.x)
#define _CGRectGetMinY(aRect) (aRect.origin.y)
#define _CGRectGetWidth(aRect) (aRect.size.width)

#define _CGRectIsEmpty(aRect) (aRect.size.width <= 0.0 || aRect.size.height <= 0.0)
#define _CGRectIsNull(aRect) (aRect.size.width <= 0.0 || aRect.size.height <= 0.0)

#define _CGRectContainsPoint(aRect, aPoint) (aPoint.x >= _CGRectGetMinX(aRect) && aPoint.y >= _CGRectGetMinY(aRect) && aPoint.x < _CGRectGetMaxX(aRect) && aPoint.y < _CGRectGetMaxY(aRect))

#define _CGInsetMake(_top, _right, _bottom, _left) { top:(_top), right:(_right), bottom:(_bottom), left:(_left)  }
#define _CGInsetMakeCopy(anInset) _CGInsetMake(anInset.top, anInset.right, anInset.bottom, anInset.left)
#define _CGInsetMakeZero() _CGInsetMake(0, 0, 0, 0)
#define _CGInsetIsEmpty(anInset) ((anInset).top === 0 && (anInset).right === 0 && (anInset).bottom === 0 && (anInset).left === 0)

// DEPRECATED
#define _CGPointCreateCopy(aPoint) _CGPointMake(aPoint.x, aPoint.y)
#define _CGSizeCreateCopy(aSize) _CGSizeMake(aSize.width, aSize.height)
