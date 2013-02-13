/*
 * NSCustomView.j
 * nib2cib
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

@import <AppKit/_CPCibCustomView.j>

@import "NSView.j"

@global CP_NSMapClassName


var _CPCibCustomViewClassNameKey    = @"_CPCibCustomViewClassNameKey";

@implementation NSCustomView : CPView
{
    CPString    _className;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
        _className = [aCoder decodeObjectForKey:@"NSClassName"];

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:CP_NSMapClassName(_className) forKey:_CPCibCustomViewClassNameKey];
}

- (CPString)classForKeyedArchiver
{
    return [_CPCibCustomView class];
}

@end

