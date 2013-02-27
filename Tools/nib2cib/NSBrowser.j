/*
 * NSBrowser.j
 * nib2cib
 *
 * Created by Andrew Hankinson.
 * Copyright 2013.
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
@import <AppKit/CPBrowser.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPColor.j>

@implementation CPBrowser (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super NS_initWithCoder:aCoder])
    {
        var flags = [aCoder decodeIntForKey:@"NSBrFlags"];

        _columnWidths = [];
        _allowsEmptySelection     = (flags & 0x10000000) ? YES : NO;
        _allowsMultipleSelection  = (flags & 0x08000000) ? YES : NO;
        _minColumnWidth = [aCoder decodeFloatForKey:@"NSMinColumnWidth"];
        _rowHeight = [aCoder decodeFloatForKey:@"NSBrowserRowHeight"];

        _prototypeView = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        [_prototypeView setVerticalAlignment:CPCenterVerticalTextAlignment];
        [_prototypeView setValue:[CPColor whiteColor] forThemeAttribute:"text-color" inState:CPThemeStateSelectedDataView];
        [_prototypeView setLineBreakMode:CPLineBreakByTruncatingTail];
    }

    return self;
}

@end

@implementation NSBrowser : CPBrowser

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
    return [CPBrowser class];
}

@end
