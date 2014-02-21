/*
 * _NSCornerView.j
 * nib2cib
 *
 * Created by Ross Boucher.
 * Copyright 2010, 280 North, Inc.
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

@import <AppKit/CPTableHeaderView.j>
@import <AppKit/_CPCornerView.j>
@import <AppKit/CPScroller.j>
@import <AppKit/CPTableView.j>

@class Nib2Cib

@global CPThemeStateVertical
@global CPThemeStateScrollViewLegacy

@implementation _CPCornerView (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    return self = [super NS_initWithCoder:aCoder];
}

@end

@implementation _NSCornerView : _CPCornerView
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self =  [super NS_initWithCoder:aCoder];

    if (self)
    {
        var theme = [Nib2Cib defaultTheme],
            height = [theme valueForAttributeWithName:@"default-row-height" forClass:[CPTableView class]],
            width = [theme valueForAttributeWithName:@"scroller-width" inState:CPThemeStateVertical | CPThemeStateScrollViewLegacy forClass:[CPScroller class]];

        _frame.size.height = height;
        _bounds.size.height = height;
        _frame.size.width = width;
        _bounds.size.width = width;
    }

    return self;
}

- (Class)classForKeyedArchiver
{
    return [_CPCornerView class];
}

@end
