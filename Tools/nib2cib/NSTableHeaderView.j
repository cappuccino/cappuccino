/*
 * NSTableHeaderView.j
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

@class CPTableView
@class Nib2Cib


@implementation CPTableHeaderView (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super NS_initWithCoder:aCoder])
    {
        _tableView = [aCoder decodeObjectForKey:"NSTableView"];

        // change the default height
        if (_bounds.size.height === 17)
        {
            var theme = [Nib2Cib defaultTheme],
                height = [theme valueForAttributeWithName:@"default-row-height" forClass:CPTableView];

            _bounds.size.height = height;
            _frame.size.height = height;
        }

        _drawsColumnLines = YES;
    }

    return self;
}

@end

@implementation NSTableHeaderView : CPTableHeaderView
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPTableHeaderView class];
}

@end
