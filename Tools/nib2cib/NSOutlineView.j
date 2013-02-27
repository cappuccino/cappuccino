/*
 * NSOutlineView.j
 * nib2cib
 *
 * Created by Andreas Falk.
 * Copyright 2009, Andreas Falk.
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

@import <AppKit/CPOutlineView.j>


@implementation CPOutlineView (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        if ([aCoder containsValueForKey:"NSOutlineViewOutlineTableColumnKey"])
            _outlineTableColumn = [aCoder decodeObjectForKey:@"NSOutlineViewOutlineTableColumnKey"];
        else
            _outlineTableColumn = [[self tableColumns] objectAtIndex:0];

        if ([aCoder containsValueForKey:"NSOutlineViewIndentationPerLevelKey"])
            _indentationPerLevel = [aCoder decodeFloatForKey:@"NSOutlineViewIndentationPerLevelKey"];
        else
            _indentationPerLevel = 16;

        _outlineViewDataSource = [aCoder decodeObjectForKey:@"NSDataSource"];
        _outlineViewDelegate = [aCoder decodeObjectForKey:@"NSDelegate"];
    }

    return self;
}

@end


@implementation NSOutlineView : CPOutlineView
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [self NS_initWithCoder:aCoder];

    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];
        [self NS_initWithCell:cell];
    }

    return self;
}

- (Class)classForKeyedArchiver
{
    return [CPOutlineView class];
}

@end
