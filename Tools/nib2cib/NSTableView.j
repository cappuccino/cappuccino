/*
 * NSTableView.j
 * nib2cib
 *
 * Created by Thomas Robinson.
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


@import <AppKit/CPTableView.j>

@implementation CPTableView (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];
    
    if (self)
    {
        var flags = [aCoder decodeIntForKey:@"NSTvFlags"];
        
        //_dataSource = [aCoder decodeObjectForKey:CPTableViewDataSourceKey];
        //_delegate = [aCoder decodeObjectForKey:CPTableViewDelegateKey];
        
        //_headerView = [aCoder decodeObjectForKey:@"NSHeaderView"];
        //[_headerView setTableView:self];
        
        //_cornerView = [aCoder decodeObjectForKey:@"NSCornerView"];
    
        _tableColumns = [aCoder decodeObjectForKey:@"NSTableColumns"];
        [_tableColumns makeObjectsPerformSelector:@selector(setTableView:) withObject:self];

        _rowHeight = [aCoder decodeFloatForKey:@"NSRowHeight"];
        _intercellSpacing = CGSizeMake([aCoder decodeFloatForKey:"NSIntercellSpacingWidth"], [aCoder decodeFloatForKey:"NSIntercellSpacingHeight"]);
        
        _allowsMultipleSelection = (flags & 0x08000000) ? YES : NO;
        _allowsEmptySelection = (flags & 0x10000000) ? YES : NO;
    }
    
    return self;
}

@end

@implementation NSTableView : CPTableView
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPTableView class];
}

@end
