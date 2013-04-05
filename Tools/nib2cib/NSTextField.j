/*
 * NSTextField.j
 * AppKit
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

@import <AppKit/CPFont.j>
@import <AppKit/CPTextField.j>

@import "NSCell.j"
@import "NSControl.j"

@implementation CPTextField (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    return [super NS_initWithCoder:aCoder];
}

- (void)NS_initWithCell:(NSCell)cell
{
    [super NS_initWithCell:cell];

    [self setEditable:[cell isEditable]];
    [self setEnabled:[cell isEnabled]];
    [self setSelectable:[cell isSelectable]];
    [self setSendsActionOnEndEditing:[cell sendsActionOnEndEditing]];

    [self setBordered:[cell isBordered]];
    [self setBezeled:[cell isBezeled]];
    [self setBezelStyle:[cell bezelStyle]];
    [self setDrawsBackground:[cell drawsBackground]];

    [self setLineBreakMode:[cell lineBreakMode]];
    [self setAlignment:[cell alignment]];
    [self setTextFieldBackgroundColor:[cell backgroundColor]];

    [self setPlaceholderString:[cell placeholderString]];

    var textColor = [cell textColor],
        defaultColor = [self currentValueForThemeAttribute:@"text-color"];

    // Don't change the text color if it is not the default, that messes up the theme lookups later
    if (![textColor isEqual:defaultColor])
        [self setTextColor:[cell textColor]];

    // Only adjust the origin and size if this is a bezeled textfield.
    // This ensures that labels positioned in IB are properly positioned after nibcib.
    var frame = [self frame];

    if ([self isBezeled])
    {
        [self setFrameOrigin:CGPointMake(frame.origin.x - 4.0, frame.origin.y - 3.0)];
        [self setFrameSize:CGSizeMake(frame.size.width + 8.0, frame.size.height + 7.0)];
    }
    else
    {
        [self setFrameOrigin:CGPointMake(frame.origin.x + 3.0, frame.origin.y)];
        [self setFrameSize:CGSizeMake(frame.size.width - 6.0, frame.size.height)];
    }

    CPLog.debug("NSTextField: title=\"" + [self stringValue] + "\", placeholder=" + ([cell placeholderString] == null ? "<none>" : '"' + [cell placeholderString] + '"') + ", isBordered=" + [self isBordered] + ", isBezeled="  + [self isBezeled] + ", bezelStyle=" + [self bezelStyle]);

    if ([self formatter])
        CPLog.debug(">> Formatter: " + [[self formatter] description]);
}

@end

@implementation NSTextField : CPTextField

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
    return [CPTextField class];
}

@end

@implementation NSTextFieldCell : NSCell
{
    CPTextFieldBezelStyle   _bezelStyle         @accessors(readonly, getter=bezelStyle);
    BOOL                    _drawsBackground    @accessors(readonly, getter=drawsBackground);
    CPColor                 _backgroundColor    @accessors(readonly, getter=backgroundColor);
    CPColor                 _textColor          @accessors(readonly, getter=textColor);
    CPString                _placeholderString  @accessors(readonly, getter=placeholderString);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _bezelStyle         = [aCoder decodeObjectForKey:@"NSTextBezelStyle"] || CPTextFieldSquareBezel;
        _drawsBackground    = [aCoder decodeBoolForKey:@"NSDrawsBackground"];
        _backgroundColor    = [aCoder decodeObjectForKey:@"NSBackgroundColor"];
        _textColor          = [aCoder decodeObjectForKey:@"NSTextColor"];
        _placeholderString  = [aCoder decodeObjectForKey:@"NSPlaceholderString"];
    }

    return self;
}

@end
