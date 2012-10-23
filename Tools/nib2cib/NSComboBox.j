/*
 * NSComboBox.j
 * nib2cib
 *
 * Created by Aparajita Fishman.
 * Copyright (c) 2012, The Cappuccino Foundation
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

@import <AppKit/CPTextField.j>
@import <AppKit/CPComboBox.j>

@import "NSTextField.j"


@implementation CPComboBox (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];

        _items = [cell itemList];
        _usesDataSource = [cell usesDataSource];
        _completes = [cell completes];
        _numberOfVisibleItems = [cell visibleItemCount];
        _hasVerticalScroller = [cell hasVerticalScroller];
        [self setButtonBordered:[cell borderedButton]];

        // Make sure the height is clipped to the max given by the theme
        var maxSize = [[[Converter sharedConverter] themes][0] valueForAttributeWithName:@"max-size" forClass:[CPComboBox class]],
            size = [self frameSize];

        [self setFrameSize:CGSizeMake(size.width, MIN(size.height, maxSize.height))];

        // Adjust for differences between Cocoa and Cappuccino widget framing.
        _frame.origin.x += 1;
    }

    return self;
}

@end

@implementation NSComboBox : CPComboBox

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPComboBox class];
}

@end

@implementation NSComboBoxCell : NSTextFieldCell
{
    int     _visibleItemCount       @accessors(readonly, getter=visibleItemCount);
    BOOL    _hasVerticalScroller    @accessors(readonly, getter=hasVerticalScroller);
    BOOL    _usesDataSource         @accessors(readonly, getter=usesDataSource);
    BOOL    _completes              @accessors(readonly, getter=completes);
    CPArray _itemList               @accessors(readonly, getter=itemList);
    BOOL    _borderedButton         @accessors(readonly, getter=borderedButton);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _visibleItemCount = [aCoder decodeIntForKey:@"NSVisibleItemCount"];
        _hasVerticalScroller = [aCoder decodeBoolForKey:@"NSHasVerticalScroller"];
        _usesDataSource = [aCoder decodeBoolForKey:@"NSUsesDataSource"];
        _completes = [aCoder decodeBoolForKey:@"NSCompletes"];

        if (!_usesDataSource)
            _itemList = [aCoder decodeObjectForKey:@"NSPopUpListData"] || [];
        else
            _itemList = [];

        // NSButtonBordered key is present only if the value is NO, go figure
        _borderedButton = [aCoder containsValueForKey:@"NSButtonBordered"] ? [aCoder decodeBoolForKey:@"NSButtonBordered"] : YES;
    }

    return self;
}

@end
