/*
 * NSButton.j
 * nib2cib
 *
 * Portions based on NSButtonCell.m (09/09/2008) in Cocotron (http://www.cocotron.org/)
 * Copyright (c) 2006-2007 Christopher J. W. Lloyd
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

@import <AppKit/CPButton.j>
@import <AppKit/CPCheckBox.j>
@import <AppKit/CPRadio.j>

@import "NSCell.j"
@import "NSControl.j"

@class Nib2Cib

@global NIB_CONNECTION_EQUIVALENCY_TABLE


var NSButtonIsBorderedMask = 0x00800000,
    NSButtonAllowsMixedStateMask = 0x1000000,

    // The image position is contained in the third byte, and the values
    // don't really follow much of a pattern.
    NSButtonImagePositionMask = 0xFF0000,
    NSButtonImagePositionShift = 16,
    NSButtonNoImagePositionMask = 0x04,
    NSButtonImageAbovePositionMask = 0x0C,
    NSButtonImageBelowPositionMask = 0x1C,
    NSButtonImageRightPositionMask = 0x2C,
    NSButtonImageLeftPositionMask = 0x3C,
    NSButtonImageOnlyPositionMask = 0x44,
    NSButtonImageOverlapsPositionMask = 0x6C,

    // You cannot set neither highlightsBy nor showsStateBy in IB,
    // but you can set button type which implicitly sets the masks.
    // Note that you cannot set NSPushInCellMask for showsStateBy.
    NSHighlightsByPushInCellMask = 0x80000000,
    NSHighlightsByContentsCellMask = 0x08000000,
    NSHighlightsByChangeGrayCellMask =  0x04000000,
    NSHighlightsByChangeBackgroundCellMask = 0x02000000,
    NSShowsStateByContentsCellMask = 0x40000000,
    NSShowsStateByChangeGrayCellMask = 0x20000000,
    NSShowsStateByChangeBackgroundCellMask = 0x10000000;


@implementation CPButton (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    return [super NS_initWithCoder:aCoder];
}

/*!
    Intialise a button given a cell. This method is meant for reuse by controls which contain
    cells other than CPButton itself.
*/
- (void)NS_initWithCell:(NSCell)cell
{
    [super NS_initWithCell:cell];

    var alternateImage = [cell alternateImage],
        positionOffsetSizeWidth = 0,
        positionOffsetOriginX = 0,
        positionOffsetOriginY = 0;

    if ([alternateImage isKindOfClass:[NSButtonImageSource class]])
    {
        /*
            Because CPCheckBox and CPRadio are direct subclasses,
            we can just change the class of this object. In the
            case of CPRadio, we can add its _radioGroup ivar by setting it
            directly on self.

            When swizzling the class, make sure to update the theme
            attributes.
        */
        if ([alternateImage imageName] === @"NSSwitch")
        {
            self.isa = [CPCheckBox class];
        }
        else if ([alternateImage imageName] === @"NSRadioButton")
        {
            self.isa = [CPRadio class];
            self._radioGroup = [CPRadioGroup new];
        }

        _themeClass = [[self class] defaultThemeClass];
        alternateImage = nil;
    }

    NIB_CONNECTION_EQUIVALENCY_TABLE[[cell UID]] = self;

    _title = [cell title];
    _alternateTitle = [cell alternateTitle];
    _controlSize = CPRegularControlSize;

    [self setBordered:[cell isBordered]];
    _bezelStyle = [cell bezelStyle];

    var fixedHeight;

    // Map Cocoa bezel styles to Cappuccino bezel styles and adjust frame
    switch (_bezelStyle)
    {
        // implemented:
        case CPRoundedBezelStyle:  // Push IB style
            positionOffsetOriginY = 6;
            positionOffsetOriginX = 6;
            positionOffsetSizeWidth = -12
            fixedHeight = YES;
            break;

        case CPTexturedRoundedBezelStyle:  // Round Textured IB style
            positionOffsetOriginY = 2;
            positionOffsetOriginX = -2;
            positionOffsetSizeWidth = 0;
            fixedHeight = YES;
            break;

        case CPHUDBezelStyle:
            fixedHeight = YES;
            break;

        // approximations:
        case CPRoundRectBezelStyle:  // Round Rect IB style
            positionOffsetOriginY = -3;
            positionOffsetOriginX = -2;
            positionOffsetSizeWidth = 0;
            _bezelStyle = CPRoundedBezelStyle;
            fixedHeight = YES;
            break;

        case CPSmallSquareBezelStyle:  // Gradient IB style
            positionOffsetOriginX = -2;
            positionOffsetSizeWidth = 0;
            _bezelStyle = CPTexturedRoundedBezelStyle;
            fixedHeight = NO;
            break;

        case CPThickSquareBezelStyle:  // Bevel IB style
        case CPThickerSquareBezelStyle:
        case CPRegularSquareBezelStyle:
            positionOffsetOriginY = 3;
            positionOffsetOriginX = 0;
            positionOffsetSizeWidth = -4;
            _bezelStyle = CPTexturedRoundedBezelStyle;
            fixedHeight = NO;
            break;

        case CPTexturedSquareBezelStyle:  // Textured IB style
            positionOffsetOriginY = 4;
            positionOffsetOriginX = -1;
            positionOffsetSizeWidth = -2;
            _bezelStyle = CPTexturedRoundedBezelStyle;
            fixedHeight = NO;
            break;

        case CPShadowlessSquareBezelStyle:  // Square IB style
            positionOffsetOriginY = 5;
            positionOffsetOriginX = -2;
            positionOffsetSizeWidth = 0;
            _bezelStyle = CPTexturedRoundedBezelStyle;
            fixedHeight = NO;
            break;

        case CPRecessedBezelStyle:  // Recessed IB style
            positionOffsetOriginY = -3;
            positionOffsetOriginX = -2;
            positionOffsetSizeWidth = 0;
            _bezelStyle = CPHUDBezelStyle;
            fixedHeight = YES;
            break;

        // unsupported
        case CPRoundedDisclosureBezelStyle:
        case CPHelpButtonBezelStyle:
        case CPCircularBezelStyle:
        case CPDisclosureBezelStyle:
            CPLog.warn("NSButton [%s]: unsupported bezel style: %d", _title == null ? "<no title>" : '"' + _title + '"', _bezelStyle);
            _bezelStyle = CPHUDBezelStyle;
            fixedHeight = YES;
            break;

        // error:
        default:
            CPLog.warn("NSButton [%s]: unknown bezel style: %d", _title == null ? "<no title>" : '"' + _title + '"', _bezelStyle);
            _bezelStyle = CPHUDBezelStyle;
            fixedHeight = YES;
    }

    if ([cell isBordered] || [self isKindOfClass:[CPRadio class]] || [self isKindOfClass:[CPCheckBox class]])
    {
        /*
            Try to figure out the intention of the theme in regards to fixed height buttons.

            - If there is a min height and a max height and they are the same, the theme must
              not support variable button heights. In that case all buttons are considered fixed height.
            - If there is just a max height, use that for only for fixed height buttons.
            - If there is no max height either, don't do any height adjustments.
        */
        var theme = [Nib2Cib defaultTheme],
            minSize = [theme valueForAttributeWithName:@"min-size" forClass:[self class]],
            maxSize = [theme valueForAttributeWithName:@"max-size" forClass:[self class]],
            adjustHeight = NO;

        if (minSize.height > 0 && maxSize.height > 0 && minSize.height === maxSize.height)
        {
            adjustHeight = YES;
            fixedHeight = minSize.height === maxSize.height;
        }
        else if (minSize.height < 0 && maxSize.height > 0)
            adjustHeight = fixedHeight;
        else
            adjustHeight = minSize.height > 0 || maxSize.height > 0;

        if (adjustHeight)
        {
            var oldHeight = _frame.size.height;

            if (minSize.height > 0)
                _frame.size.height = _bounds.size.height = MAX(_frame.size.height, minSize.height);

            if (maxSize.height > 0)
                _frame.size.height = _bounds.size.height = MIN(_frame.size.height, maxSize.height);

            if (_frame.size.height !== oldHeight)
                CPLog.debug("NSButton [%s]: adjusted height from %d to %d", _title == null ? "<no title>" : '"' + _title + '"', oldHeight, _frame.size.height);
        }

        if ([cell isBordered])
        {
            // Reposition the buttons according to its particular offsets
            _frame.origin.x += positionOffsetOriginX;
            _frame.origin.y += positionOffsetOriginY;
            _frame.size.width += positionOffsetSizeWidth;
            _bounds.size.width += positionOffsetSizeWidth;
        }
    }

    _keyEquivalent = [cell keyEquivalent];
    _keyEquivalentModifierMask = [cell keyEquivalentModifierMask];
    _imageDimsWhenDisabled = YES;

    _allowsMixedState = [cell allowsMixedState];
    [self setImage:[cell normalImage]];
    [self setAlternateImage:alternateImage];
    [self setImagePosition:[cell imagePosition]];

    [self setEnabled:[cell isEnabled]];

    _highlightsBy = [cell highlightsBy];
    _showsStateBy = [cell showsStateBy];
}

@end

@implementation NSButton : CPButton

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
    return [CPButton class];
}

@end

@implementation NSButtonCell : NSActionCell
{
    BOOL        _isBordered         @accessors(readonly, getter=isBordered);
    int         _bezelStyle         @accessors(readonly, getter=bezelStyle);

    CPString    _title              @accessors(readonly, getter=title);
    CPString    _alternateTitle     @accessors(readonly, getter=alternateTitle);
    CPImage     _normalImage        @accessors(readonly, getter=normalImage);
    CPImage     _alternateImage     @accessors(readonly, getter=alternateImage);

    BOOL        _allowsMixedState   @accessors(readonly, getter=allowsMixedState);
    BOOL        _imagePosition      @accessors(readonly, getter=imagePosition);

    int         _highlightsBy       @accessors(readonly, getter=highlightsBy);
    int         _showsStateBy       @accessors(readonly, getter=showsStateBy);

    CPString    _keyEquivalent      @accessors(readonly, getter=keyEquivalent);
    unsigned    _keyEquivalentModifierMask @accessors(readonly, getter=keyEquivalentModifierMask);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        var buttonFlags = [aCoder decodeIntForKey:@"NSButtonFlags"],
            buttonFlags2 = [aCoder decodeIntForKey:@"NSButtonFlags2"],
            cellFlags2 = [aCoder decodeIntForKey:@"NSCellFlags2"],
            position = (buttonFlags & NSButtonImagePositionMask) >> NSButtonImagePositionShift;

        _isBordered = (buttonFlags & NSButtonIsBorderedMask) ? YES : NO;
        _bezelStyle = (buttonFlags2 & 0x7) | ((buttonFlags2 & 0x20) >> 2);

        // NSContents/NSAlternateContents for NSButton is actually the title/alternate title
        _title = [aCoder decodeObjectForKey:@"NSContents"];
        _alternateTitle = [aCoder decodeObjectForKey:@"NSAlternateContents"];
        // ... and _objectValue is _state
        _objectValue = [self state];

        _normalImage = [aCoder decodeObjectForKey:@"NSNormalImage"];
        _alternateImage = [aCoder decodeObjectForKey:@"NSAlternateImage"];
        _allowsMixedState = (cellFlags2 & NSButtonAllowsMixedStateMask) ? YES : NO;

        // Test in decreasing order of mask value to ensure the correct match,
        // because some of the positions don't care about some bits.

        if ((position & NSButtonImageOverlapsPositionMask) == NSButtonImageOverlapsPositionMask)
            _imagePosition = CPImageOverlaps;
        else if ((position & NSButtonImageOnlyPositionMask) == NSButtonImageOnlyPositionMask)
            _imagePosition = CPImageOnly;
        else if ((position & NSButtonImageLeftPositionMask) == NSButtonImageLeftPositionMask)
            _imagePosition = CPImageLeft;
        else if ((position & NSButtonImageRightPositionMask) == NSButtonImageRightPositionMask)
            _imagePosition = CPImageRight;
        else if ((position & NSButtonImageBelowPositionMask) == NSButtonImageBelowPositionMask)
            _imagePosition = CPImageBelow;
        else if ((position & NSButtonImageAbovePositionMask) == NSButtonImageAbovePositionMask)
            _imagePosition = CPImageAbove;
        else if ((position & NSButtonNoImagePositionMask) == NSButtonNoImagePositionMask)
            _imagePosition = CPNoImage;

        _highlightsBy = CPNoCellMask;

        if (buttonFlags & NSHighlightsByPushInCellMask)
            _highlightsBy |= CPPushInCellMask;
        if (buttonFlags & NSHighlightsByContentsCellMask)
            _highlightsBy |= CPContentsCellMask;
        if (buttonFlags & NSHighlightsByChangeGrayCellMask)
            _highlightsBy |= CPChangeGrayCellMask;
        if (buttonFlags & NSHighlightsByChangeBackgroundCellMask)
            _highlightsBy |= CPChangeBackgroundCellMask;

        _showsStateBy = CPNoCellMask;

        if (buttonFlags & NSShowsStateByContentsCellMask)
            _showsStateBy |= CPContentsCellMask;
        if (buttonFlags & NSShowsStateByChangeGrayCellMask)
            _showsStateBy |= CPChangeGrayCellMask;
        if (buttonFlags & NSShowsStateByChangeBackgroundCellMask)
            _showsStateBy |= CPChangeBackgroundCellMask;

        _keyEquivalent = [aCoder decodeObjectForKey:@"NSKeyEquivalent"];
        _keyEquivalentModifierMask = buttonFlags2 >> 8;
    }

    return self;
}

@end

@implementation NSButtonImageSource : CPObject
{
    CPString _imageName @accessors(readonly, getter=imageName);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
        _imageName = [aCoder decodeObjectForKey:@"NSImageName"];

    return self;
}

@end
