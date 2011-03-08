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

var OS = require("os"),
    fontinfo = require("fontinfo").fontinfo;

var IBDefaultFontFace = @"Lucida Grande",
    IBDefaultFontSize = 13.0;

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

    return [self _initWithName:name size:size bold:isBold italic:isItalic];
}

@end

@implementation NSFont : CPFont

+ (void)initialize
{
    CPLog.debug("NSFont: default IB font: %s %f", IBDefaultFontFace, IBDefaultFontSize);
}

+ (id)cibFontForNibFont:(CPFont)aFont
{
    var name = [aFont familyName];

    if (name === IBDefaultFontFace)
    {
        var size = [aFont size];

        if (size === IBDefaultFontSize)
            return nil;
        else
            return [[CPFont alloc] _initWithName:[CPFont systemFontFace] size:size bold:[aFont isBold] italic:[aFont isItalic]];
    }

    return [aFont copy];
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
