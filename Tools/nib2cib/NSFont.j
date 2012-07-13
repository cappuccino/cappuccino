/*
 * NSFont.j
 * nib2cib
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

IBDefaultFontFace = @"Lucida Grande";
IBDefaultFontSize = 13.0;

var OS = require("os"),
    fontinfo = require("cappuccino/fontinfo").fontinfo;

@implementation CPFont (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var name = [aCoder decodeObjectForKey:@"NSName"],
        size = [aCoder decodeDoubleForKey:@"NSSize"],
        isBold = false,
        isItalic = false,
        info = fontinfo(name, size);

    if (info)
    {
        name = info.familyName;
        isBold = info.bold;
        isItalic = info.italic;
    }

    // NOTE: We save the nib fonts as is, and determine system status later
    var font = [self _initWithName:name
                          size:size
                          bold:isBold
                        italic:isItalic
                        system:NO];

    CPLog.debug("NSFont: %s", [NSFont descriptorForFont:font]);

    return font;
}

- (id)cibFontForNibFont
{
    if (_name === IBDefaultFontFace)
    {
        if (_size === IBDefaultFontSize && !_isBold && !_isItalic)
            return nil;
        else
            return [[CPFont alloc] _initWithName:_CPFontSystemFacePlaceholder
                                            size:_size == IBDefaultFontSize ? CPFontCurrentSystemSize : _size
                                            bold:_isBold
                                          italic:_isItalic
                                          system:YES];
    }

    return self;
}

@end

@implementation NSFont : CPFont

+ (void)initialize
{
    if (self !== [NSFont class])
        return;

    CPLog.debug("NSFont: default IB font: %s %f", IBDefaultFontFace, IBDefaultFontSize);
}

+ (CPString)descriptorForFont:(CPFont)aFont
{
    var styleAttributes = [];

    if ([aFont isBold])
        styleAttributes.push("bold");

    if ([aFont isItalic])
        styleAttributes.push("italic");

    styleAttributes = styleAttributes.join(" ");

    var systemAttributes = [];

    if ([aFont isSystem])
    {
        systemAttributes.push("system face");

        if ([aFont size] === IBDefaultFontSize)
            systemAttributes.push("system size");
    }

    systemAttributes = systemAttributes.join(", ");

    return [CPString stringWithFormat:@"%s%s %d%s", [aFont familyName], styleAttributes ? " " + styleAttributes : "", [aFont size], systemAttributes ? " (" + systemAttributes + ")" : ""];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPFont class];
}

@end
