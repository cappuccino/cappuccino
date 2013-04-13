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
@class Nib2Cib

var IBDefaultFontSizeTableHeader = 11.0;

@implementation CPTableColumn (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [self init];

    if (self)
    {
        _identifier = [aCoder decodeObjectForKey:@"NSIdentifier"];

        var dataViewCell = [aCoder decodeObjectForKey:@"NSDataCell"],
            viewClass = nil;

        if ([dataViewCell isKindOfClass:[NSImageCell class]])
            viewClass = CPImageView;
        else if ([dataViewCell isKindOfClass:[NSTextFieldCell class]])
            viewClass = CPTextField;
        else if ([dataViewCell isKindOfClass:[NSButtonCell class]])
            viewClass = CPButton;
        else if ([dataViewCell isKindOfClass:[NSLevelIndicatorCell class]])
            viewClass = CPLevelIndicator;

        if (viewClass)
            _dataView = [self makeDataViewOfClass:viewClass withCell:dataViewCell];

        [_dataView setValue:[dataViewCell alignment] forThemeAttribute:@"alignment"];

        var headerCell = [aCoder decodeObjectForKey:@"NSHeaderCell"],
            headerView = [[_CPTableColumnHeaderView alloc] initWithFrame:CGRectMakeZero()],
            theme = [Nib2Cib defaultTheme];

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

- (id)makeDataViewOfClass:(Class)aClass withCell:(NSCell)aCell
{
    var dataView = [[aClass alloc] initWithFrame:CGRectMakeZero()];

    // Set the theme state to make sure the data view's theme attributes are correct
    [dataView setThemeState:CPThemeStateTableDataView];
    [dataView NS_initWithCell:aCell];

    if (aClass === CPTextField)
    {
        // Text cells have to have their font replaced
        [[Converter sharedConverter] replaceFontForObject:dataView];

        // If a text cell has a custom color, we have to set the selected color,
        // otherwise it defaults to the custom color.
        var textColor = [aCell textColor],
            defaultColor = [self valueForDataViewThemeAttribute:@"text-color" inState:CPThemeStateNormal];

        if (![textColor isEqual:defaultColor])
        {
            var selectedColor = [self valueForDataViewThemeAttribute:@"text-color" inState:CPThemeStateTableDataView | CPThemeStateSelectedDataView];

            [dataView setValue:selectedColor forThemeAttribute:@"text-color" inState:CPThemeStateTableDataView | CPThemeStateSelectedDataView];
            [dataView setValue:textColor forThemeAttribute:@"text-color" inState:CPThemeStateTableDataView | CPThemeStateSelectedDataView | CPThemeStateEditing];
        }
    }

    return dataView;
}

- (id)valueForDataViewThemeAttribute:(CPString)attribute inState:(int)state
{
    var themes = [[Nib2Cib sharedNib2Cib] themes];

    for (var i = 0; i < themes.length; ++i)
    {
        var value = [themes[i] valueForAttributeWithName:attribute inState:state forClass:CPTextField];

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
