/*
 * NSTextField.j
 * nib2cib
 *
 * Created by Alexander Ljungberg.
 * Copyright 2011, WireLoad Inc.
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

@import <AppKit/CPFont.j>
@import <AppKit/CPTokenField.j>

@import "NSControl.j"
@import "NSCell.j"
@import "NSTextField.j"

@implementation CPTokenField (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    return [super NS_initWithCoder:aCoder];
}

/*!
    Intialise the receiver given a cell. This method is meant for reuse by controls which contain
    cells other than CPTokenField itself.
*/
- (void)NS_initWithCell:(NSCell)cell
{
    [super NS_initWithCell:cell];

    // Uncomment if we add support for token styles.
    // _style = [cell tokenStyle];
}

@end

@implementation NSTokenField : CPTokenField

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
    return [CPTokenField class];
}

@end

@implementation NSTokenFieldCell : NSTextFieldCell
{
    int _tokenStyle  @accessors(readonly, getter=tokenStyle);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _tokenStyle = [aCoder decodeIntForKey:@"NSTokenStyle"];
    }

    return self;
}

@end
