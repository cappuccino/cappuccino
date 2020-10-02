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

@global NIB_CONNECTION_EQUIVALENCY_TABLE

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
    [self setBackgroundColor:[cell backgroundColor]];

    [self setPlaceholderString:[cell placeholderString]];

    [self _setUsesSingleLineMode:[cell usesSingleLineMode]];
    [self _setWraps:[cell wraps]];
    [self _setScrolls:[cell scrolls]];

    var textColor = [cell textColor],
        defaultColor = [self currentValueForThemeAttribute:@"text-color"];

    // Don't change the text color if it is not the default, that messes up the theme lookups later
    if (![textColor isEqual:defaultColor])
        [self setTextColor:[cell textColor]];

    CPLog.debug("NSTextField: title=\"" + [self stringValue] + "\", placeholder=" + ([cell placeholderString] == null ? "<none>" : '"' + [cell placeholderString] + '"') + ", isBordered=" + [self isBordered] + ", isBezeled="  + [self isBezeled] + ", bezelStyle=" + [self bezelStyle]);

    if ([self formatter])
        CPLog.debug(">> Formatter: " + [[self formatter] description]);
}

// Labels WITHOUT background use a special adjustment frame.
// As we can't just let the theming system choose, we have to
// adapt _nib2cibAdjustment
- (CGRect)_nib2CibAdjustment
{
    // Theme has not been loaded yet.
    // Get attribute value directly from the theme or from the default value of the object otherwise.
    var theme      = [Nib2Cib defaultTheme],
        themeState = [self themeState];

    // Is this a label with a background ?
    if (!([self hasThemeState:CPThemeStateBezeled] || [self hasThemeState:CPThemeStateBordered]) && [self drawsBackground])

        // Yes, so use normal frame adjustment (that is, consider it's bezeled)
        themeState = themeState.and(CPThemeStateBezeled);

    var frameAdjustment = [theme valueForAttributeWithName:@"nib2cib-adjustment-frame" inState:themeState forClass:[self class]];

    if (frameAdjustment)
        return frameAdjustment;

    if ([self hasThemeAttribute:@"nib2cib-adjustment-frame"])
    {
        frameAdjustment = [self valueForThemeAttribute:@"nib2cib-adjustment-frame" inState:themeState];

        if (frameAdjustment)
            return frameAdjustment;
    }

    return nil;
}

@end

@implementation NSTextField : CPTextField

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [self NS_initWithCoder:aCoder];

    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];

        // If we have bindings/connections connected to the text field cell make sure they are replaced
        NIB_CONNECTION_EQUIVALENCY_TABLE[[cell UID]] = self;

        [self NS_initWithCell:cell];
        [self _adjustNib2CibSize];
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
