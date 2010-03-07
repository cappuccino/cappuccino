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

@implementation CPButton (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];
        NIB_CONNECTION_EQUIVALENCY_TABLE[[cell UID]] = self;

        if (![self NS_isCheckBox] && ![self NS_isRadio])
        {
            _controlSize = CPRegularControlSize;
            _title = [cell title];

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
            self._title = [cell title];
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
    // We need to do a bit of magic to determine if this is a checkbox or radio button.
    var cell = [aCoder decodeObjectForKey:@"NSCell"],
        alternateImage = [cell alternateImage];

    if ([alternateImage isKindOfClass:[NSButtonImageSource class]])
    {
        if ([alternateImage imageName] === @"NSSwitch")
            _isCheckBox = YES;

        else if ([alternateImage imageName] === @"NSRadioButton")
        {
            _isRadio = YES;
            self._radioGroup = [CPRadioGroup new];
        }
    }

    return [self NS_initWithCoder:aCoder];
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
    BOOL        _isBordered     @accessors(readonly, getter=isBordered);
    int         _bezelStyle     @accessors(readonly, getter=bezelStyle);

    CPString    _title          @accessors(readonly, getter=title);
    CPImage     _alternateImage @accessors(readonly, getter=alternateImage);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        var buttonFlags = [aCoder decodeIntForKey:@"NSButtonFlags"],
            buttonFlags2 = [aCoder decodeIntForKey:@"NSButtonFlags2"];

        _isBordered = (buttonFlags & 0x00800000) ? YES : NO;
        _bezelStyle = (buttonFlags2 & 0x7) | ((buttonFlags2 & 0x20) >> 2);

        // NSContents for NSButton is actually the title
        _title = [aCoder decodeObjectForKey:@"NSContents"];
        // ... and _objectValue is _state
        _objectValue = [self state];

        _alternateImage = [aCoder decodeObjectForKey:@"NSAlternateImage"];
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
