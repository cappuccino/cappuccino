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


@import <AppKit/CPTableColumn.j>
@import <AppKit/CPTableHeaderView.j>
@import <AppKit/CPButton.j>

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
            [_dataView setImageScaling:[dataViewCell imageScaling]];
            [_dataView setImageAlignment:[dataViewCell imageAlignment]];
        }
        else if ([dataViewCell isKindOfClass:[NSTextFieldCell class]])
        {
            _dataView = [[CPTextField alloc] initWithFrame:CPRectMakeZero()];

            var font = [dataViewCell font],
                selectedFont = nil;

            if (font)
                font = [font cibFontForNibFont];

            if (!font)
                font = [CPFont systemFontOfSize:[CPFont systemFontSize]];

            var selectedFont = [CPFont boldFontWithName:[font familyName] size:[font size]];

            [_dataView setFont:font];
            [_dataView setValue:selectedFont forThemeAttribute:@"font" inState:CPThemeStateSelectedDataView];

            [_dataView setLineBreakMode:CPLineBreakByTruncatingTail];

            [_dataView setValue:CPCenterVerticalTextAlignment forThemeAttribute:@"vertical-alignment"];
            [_dataView setValue:CGInsetMake(0.0, 5.0, 0.0, 5.0) forThemeAttribute:@"content-inset"];

            var textColor = [dataViewCell textColor],
                defaultColor = [_dataView currentValueForThemeAttribute:@"text-color"];

            // Don't change the text color if it is not the default, that messes up the theme lookups later
            if (![textColor isEqual:defaultColor])
                [_dataView setTextColor:[dataViewCell textColor]];
        }
        else if ([dataViewCell isKindOfClass:[NSButtonCell class]])
        {
            _dataView = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
            _dataView = [_dataView NS_initWithCell:dataViewCell];
        }
        else if ([dataViewCell isKindOfClass:[NSLevelIndicatorCell class]])
        {
            _dataView = [[CPLevelIndicator alloc] initWithFrame:CGRectMakeZero()];
            _dataView = [_dataView NS_initWithCell:dataViewCell];
        }

        [_dataView setValue:[dataViewCell alignment] forThemeAttribute:@"alignment"];

        var headerCell = [aCoder decodeObjectForKey:@"NSHeaderCell"],
            headerView = [[_CPTableColumnHeaderView alloc] initWithFrame:CPRectMakeZero()];

        [headerView setStringValue:[headerCell objectValue]];
        [headerView setValue:[dataViewCell alignment] forThemeAttribute:@"text-alignment"];

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
