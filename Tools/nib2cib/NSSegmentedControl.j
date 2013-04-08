/*
 * NSSegmentedControl.j
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

@import <AppKit/CPSegmentedControl.j>

@import "NSCell.j"

@class Nib2Cib


@implementation CPSegmentedControl (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    _segments = [];
    _themeStates = [];

    return [super NS_initWithCoder:aCoder];
}

- (void)NS_initWithCell:(NSCell)cell
{
    [super NS_initWithCell:cell];

    var frame = [self frame],
        originalWidth = frame.size.width;

    frame.size.width = 0;
    frame.origin.x = MAX(frame.origin.x - 4.0, 0.0);

    [self setFrame:frame];

    _segments           = [cell segments];
    _selectedSegment    = [cell selectedSegment];
    _segmentStyle       = [cell segmentStyle];
    _trackingMode       = [cell trackingMode];

    [self setValue:CPCenterTextAlignment forThemeAttribute:@"alignment"];

    // HACK

    for (var i = 0; i < _segments.length; i++)
    {
        _themeStates[i] = _segments[i].selected ? CPThemeStateSelected : CPThemeStateNormal;

        [self tileWithChangedSegment:i];
    }

    // Adjust for differences between Cocoa and Cappuccino widget framing.
    frame.origin.x += 6;

    if ([[Nib2Cib defaultTheme] name] == @"Aristo2")
        frame.size.height += 1;

    frame.size.width = originalWidth;
    [self setFrame:frame];
}

@end

@implementation NSSegmentedControl : CPSegmentedControl
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
    return [CPSegmentedControl class];
}

@end

@implementation NSSegmentedCell : NSActionCell
{
    CPArray                 _segments           @accessors(readonly, getter=segments);
    int                     _selectedSegment    @accessors(readonly, getter=selectedSegment);
    int                     _segmentStyle       @accessors(readonly, getter=segmentStyle);
    CPSegmentSwitchTracking _trackingMode       @accessors(readonly, getter=trackingMode);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _segments           = [aCoder decodeObjectForKey:"NSSegmentImages"];
        _selectedSegment    = [aCoder decodeObjectForKey:"NSSelectedSegment"];

        if (_selectedSegment === nil)
            _selectedSegment = -1;

        _segmentStyle       = [aCoder decodeIntForKey:"NSSegmentStyle"];
        _trackingMode       = [aCoder decodeIntForKey:"NSTrackingMode"];

        if (_trackingMode == CPSegmentSwitchTrackingSelectOne && _selectedSegment == -1)
            _selectedSegment = 0;
    }

    return self;
}

@end


@implementation _CPSegmentItem (CPCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        image       = [aCoder decodeObjectForKey:"NSSegmentItemImage"];
        label       = [aCoder decodeObjectForKey:"NSSegmentItemLabel"];
        menu        = [aCoder decodeObjectForKey:"NSSegmentItemMenu"];
        selected    = [aCoder decodeBoolForKey:"NSSegmentItemSelected"];
        enabled     = ![aCoder decodeBoolForKey:"NSSegmentItemDisabled"];
        tag         = [aCoder decodeIntForKey:"NSSegmentItemTag"];
        width       = [aCoder decodeIntForKey:"NSSegmentItemWidth"];

        frame       = CGRectMakeZero();

        // NSSegmentItemImageScaling
        // NSSegmentItemTooltip
    }

    return self;
}

@end

@implementation NSSegmentItem : _CPSegmentItem
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPSegmentItem class];
}

@end

