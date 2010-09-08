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


var _CPButtonBezelStyleHeights = {};
_CPButtonBezelStyleHeights[CPRoundedBezelStyle] = 18;
_CPButtonBezelStyleHeights[CPTexturedRoundedBezelStyle] = 20;
_CPButtonBezelStyleHeights[CPHUDBezelStyle] = 20;

var NSButtonIsBorderedMask = 0x00800000,
    NSButtonAllowsMixedStateMask = 0x1000000,

    // The image position is contained in the third byte, and the values
    // don't really follow much of a pattern.
    NSButtonImagePositionMask = 0xFF0000,
    NSButtonImagePositionShift = 16,
    NSButtonNoImagePositionMask = 0x04,
    NSButtonImageAbovePositionMask = 0x0C,
    NSButtonImageBelowPositionMask = 0x1C;
    NSButtonImageRightPositionMask = 0x2C,
    NSButtonImageLeftPositionMask = 0x3C,
    NSButtonImageOnlyPositionMask = 0x44,
    NSButtonImageOverlapsPositionMask = 0x6C;


@implementation CPButton (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];
        NIB_CONNECTION_EQUIVALENCY_TABLE[[cell UID]] = self;

        _title = [cell title];

        if (![self NS_isCheckBox] && ![self NS_isRadio])
        {
            _controlSize = CPRegularControlSize;

            [self setBordered:[cell isBordered]];
            _bezelStyle = [cell bezelStyle];

            // clean up:
            switch (_bezelStyle)
            {
                // implemented:
                case CPRoundedBezelStyle:
                case CPTexturedRoundedBezelStyle:
                case CPHUDBezelStyle:
                    break;
                // approximations:
                case CPRoundRectBezelStyle:
                    _bezelStyle = CPRoundedBezelStyle;
                    break;
                case CPSmallSquareBezelStyle:
                case CPThickSquareBezelStyle:
                case CPThickerSquareBezelStyle:
                case CPRegularSquareBezelStyle:
                case CPTexturedSquareBezelStyle:
                case CPShadowlessSquareBezelStyle:
                    _bezelStyle = CPTexturedRoundedBezelStyle;
                    break;
                case CPRecessedBezelStyle:
                    _bezelStyle = CPHUDBezelStyle;
                    break;
                // unsupported
                case CPRoundedDisclosureBezelStyle:
                case CPHelpButtonBezelStyle:
                case CPCircularBezelStyle:
                case CPDisclosureBezelStyle:
                    CPLog.warn("Unsupported bezel style: " + _bezelStyle);
                    _bezelStyle = CPHUDBezelStyle;
                    break;
                // error:
                default:
                    CPLog.error("Unknown bezel style: " + _bezelStyle);
                    _bezelStyle = CPHUDBezelStyle;
            }

            if ([cell isBordered])
            {
                CPLog.info("Adjusting CPButton height from " +_frame.size.height+ " / " + _bounds.size.height+" to " + 24);
                _frame.size.height = 24.0;
                _frame.origin.y += 4.0;
                _bounds.size.height = 24.0;
            }
        }
        else
        {
            if (![self isKindOfClass:CPCheckBox] && ![self isKindOfClass:CPRadio])
            {
                if ([self NS_isCheckBox])
                    return [[CPCheckBox alloc] NS_initWithCoder:aCoder];
                else
                    return [[CPRadio alloc] NS_initWithCoder:aCoder];
            }

            [self setBordered:YES];
        }
    }

    return self;
}

- (BOOL)NS_isCheckBox
{
    return NO;
}

- (BOOL)NS_isRadio
{
    return NO;
}

@end

@implementation CPRadio (NS)

- (BOOL)NS_isRadio
{
    return YES;
}

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super NS_initWithCoder:aCoder])
        _radioGroup = [CPRadioGroup new];

    return self;
}

@end

@implementation CPCheckBox (NS)

- (BOOL)NS_isCheckBox
{
    return YES;
}

@end

@implementation NSButton : CPButton
{
    BOOL    _isCheckBox @accessors(readonly, getter=NS_isCheckBox);
    BOOL    _isRadio @accessors(readonly, getter=NS_isRadio);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    // We need to do a bit of magic to determine if this is a checkbox or radio button
    // BEFORE we can initialize the rest of the object.
    var cell = [aCoder decodeObjectForKey:@"NSCell"],
        alternateImage = [cell alternateImage];

    if ([alternateImage isKindOfClass:[NSButtonImageSource class]])
    {
        if ([alternateImage imageName] === @"NSSwitch")
            _isCheckBox = YES;

        else if ([alternateImage imageName] === @"NSRadioButton")
        {
            _isRadio = YES;
            _radioGroup = [CPRadioGroup new];
        }
    }

    self = [self NS_initWithCoder:aCoder];

    self._allowsMixedState = [cell allowsMixedState];
    [self setImagePosition:[cell imagePosition]];

    [self setKeyEquivalent:[cell keyEquivalent]];
    self._keyEquivalentModifierMask = [cell keyEquivalentModifierMask];

    return self;
}

- (Class)classForKeyedArchiver
{
    if ([self NS_isCheckBox])
        return [CPCheckBox class];

    if ([self NS_isRadio])
        return [CPRadio class];

    return [CPButton class];
}

@end

@implementation NSButtonCell : NSActionCell
{
    BOOL        _isBordered         @accessors(readonly, getter=isBordered);
    int         _bezelStyle         @accessors(readonly, getter=bezelStyle);

    CPString    _title              @accessors(readonly, getter=title);
    CPImage     _alternateImage     @accessors(readonly, getter=alternateImage);

    BOOL        _allowsMixedState   @accessors(readonly, getter=allowsMixedState);
    BOOL        _imagePosition      @accessors(readonly, getter=imagePosition);

    CPString    _keyEquivalent  @accessors(readonly, getter=keyEquivalent);
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

        // NSContents for NSButton is actually the title
        _title = [aCoder decodeObjectForKey:@"NSContents"];
        // ... and _objectValue is _state
        _objectValue = [self state];

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

        _keyEquivalent = [aCoder decodeObjectForKey:@"NSKeyEquivalent"];
        _keyEquivalentModifierMask = buttonFlags2 >> 8;
    }

    return self;
}

@end

@implementation NSButtonImageSource : CPObject
{
    CPString    _imageName @accessors(readonly, getter=imageName);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
        _imageName = [aCoder decodeObjectForKey:@"NSImageName"];

    return self;
}

@end
