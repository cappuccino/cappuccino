/*
 * NSTableColumn.j
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

@import <AppKit/CPLevelIndicator.j>
@import <AppKit/CPTableColumn.j>
@import <AppKit/CPTableHeaderView.j>
@import <AppKit/CPButton.j>

@import "NSButton.j"
@import "NSImageView.j"
@import "NSLevelIndicator.j"
@import "NSTextField.j"

@class Converter

var IBDefaultFontSizeTableHeader = 11.0;

@implementation CPTableColumn (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [self init];

    if (self)
    {
        _identifier = [aCoder decodeObjectForKey:@"NSIdentifier"];

        var dataViewCell = [aCoder decodeObjectForKey:@"NSDataCell"];

        if ([dataViewCell isKindOfClass:[NSImageCell class]])
        {
            _dataView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
            [_dataView NS_initWithCell:dataViewCell];
        }
        else if ([dataViewCell isKindOfClass:[NSTextFieldCell class]])
        {
            _dataView = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
            [_dataView NS_initWithCell:dataViewCell];
            [[Converter sharedConverter] replaceFontForObject:_dataView];

            // Make sure the font is registered for data view states.
            // We will attempt to honor italic/bold for selected state.
            var font = [_dataView font],
                selectedFont = [self valueForSelectedDataViewThemeAttribute:@"font"] || font,
                name = [font familyName],
                size = [font size],
                italic = [font isItalic],
                bold = [font isBold],
                selectedFont = bold ? [CPFont boldFontWithName:name size:size italic:italic] :
                                      [CPFont fontWithName:name size:size italic:italic];

            [_dataView setValue:font forThemeAttribute:@"font" inState:CPThemeStateTableDataView];
            [_dataView setValue:selectedFont forThemeAttribute:@"font" inState:CPThemeStateTableDataView | CPThemeStateSelectedDataView];
            [_dataView setValue:font forThemeAttribute:@"font" inState:CPThemeStateTableDataView | CPThemeStateEditing];

            // Also make sure to set the selected color, by default it will use the cells color
            var color = [_dataView textColor],
                selectedColor = [self valueForSelectedDataViewThemeAttribute:@"text-color"] || color;

            [_dataView setValue:color forThemeAttribute:@"text-color" inState:CPThemeStateTableDataView];
            [_dataView setValue:selectedColor forThemeAttribute:@"text-color" inState:CPThemeStateTableDataView | CPThemeStateSelectedDataView]
        }
        else if ([dataViewCell isKindOfClass:[NSButtonCell class]])
        {
            _dataView = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
            [_dataView NS_initWithCell:dataViewCell];
        }
        else if ([dataViewCell isKindOfClass:[NSLevelIndicatorCell class]])
        {
            _dataView = [[CPLevelIndicator alloc] initWithFrame:CGRectMakeZero()];
            [_dataView NS_initWithCell:dataViewCell];
        }

        [_dataView setValue:[dataViewCell alignment] forThemeAttribute:@"alignment"];

        var headerCell = [aCoder decodeObjectForKey:@"NSHeaderCell"],
            headerView = [[_CPTableColumnHeaderView alloc] initWithFrame:CGRectMakeZero()],
            theme = [[Converter sharedConverter] themes][0];

        [headerView setStringValue:[headerCell objectValue]];
        [headerView setFont:[headerCell font]];
        [headerView setAlignment:[headerCell alignment]];

        if ([[headerCell font] familyName] === IBDefaultFontFace && [[headerCell font] size] == IBDefaultFontSizeTableHeader)
        {
            [headerView setTextColor:[theme valueForAttributeWithName:@"text-color" forClass:_CPTableColumnHeaderView]];
            [headerView setFont:[theme valueForAttributeWithName:@"font" forClass:_CPTableColumnHeaderView]];
        }

        [self setHeaderView:headerView];

        _width = [aCoder decodeFloatForKey:@"NSWidth"];
        _minWidth = [aCoder decodeFloatForKey:@"NSMinWidth"];
        _maxWidth = [aCoder decodeFloatForKey:@"NSMaxWidth"];

        _resizingMask = [aCoder decodeIntForKey:@"NSResizingMask"];
        _isHidden = [aCoder decodeBoolForKey:@"NSHidden"];

        _isEditable = [aCoder decodeBoolForKey:@"NSIsEditable"];

        _sortDescriptorPrototype = [aCoder decodeObjectForKey:@"NSSortDescriptorPrototype"];
    }

    return self;
}

- (id)valueForSelectedDataViewThemeAttribute:(CPString)attribute
{
    var themes = [[Converter sharedConverter] themes];

    for (var i = 0; i < themes.length; ++i)
    {
        var value = [themes[i] valueForAttributeWithName:attribute inState:CPThemeStateTableDataView | CPThemeStateSelectedDataView forClass:CPTextField];

        if (value)
            return value;
    }

    return nil;
}

@end

@implementation NSTableColumn : CPTableColumn
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPTableColumn class];
}

@end


@implementation NSTableHeaderCell : NSActionCell
{
}

@end
