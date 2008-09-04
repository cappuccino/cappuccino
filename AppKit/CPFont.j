/*
 * CPFont.j
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

var _CPFonts                = {};
    _CPFontSystemFontFace   = @"Arial";

#define _CPCachedFont(aName, aSize, isBold) _CPFonts[(isBold ? @"bold " : @"") + ROUND(aSize) + @"px '" + aName + @"'"]

@implementation CPFont : CPObject
{
    CPString    _name;
    float       _size;
    BOOL        _isBold;
    
    CPString    _cssString;
}

+ (id)fontWithName:(CPString)aName size:(float)aSize
{
    return _CPCachedFont(aName, aSize, NO) || [[CPFont alloc] _initWithName:aName size:aSize bold:NO];
}

+ (id)boldFontWithName:(CPString)aName size:(float)aSize
{
    return _CPCachedFont(aName, aSize, YES) || [[CPFont alloc] _initWithName:aName size:aSize bold:YES];
}

+ (id)systemFontOfSize:(CPSize)aSize
{
    return _CPCachedFont(_CPFontSystemFontFace, aSize, NO) || [[CPFont alloc] _initWithName:_CPFontSystemFontFace size:aSize bold:NO];
}

+ (id)boldSystemFontOfSize:(CPSize)aSize
{
    return _CPCachedFont(_CPFontSystemFontFace, aSize, YES) || [[CPFont alloc] _initWithName:_CPFontSystemFontFace size:aSize bold:YES];
}
// FIXME Font Descriptor
- (id)_initWithName:(CPString)aName size:(float)aSize bold:(BOOL)isBold
{   
    self = [super init];
    
    if (self)
    {
        _name = aName;
        _size = aSize;
        _isBold = isBold;
        
        _cssString = (_isBold ? @"bold " : @"") + ROUND(aSize) + @"px '" + aName + @"'";
        
        _CPFonts[_cssString] = self;
    }
    
    return self;
}

- (float)size
{
    return _size;
}

- (CPString)cssString
{
    return _cssString;
}

- (CPString)familyName
{
    return _name;
}

@end

var CPFontNameKey   = @"CPFontNameKey",
    CPFontSizeKey   = @"CPFontSizeKey",
    CPFontIsBoldKey = @"CPFontIsBoldKey";

@implementation CPFont (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self _initWithName:[aCoder decodeObjectForKey:CPFontNameKey]
        size:[aCoder decodeFloatForKey:CPFontSizeKey]
        bold:[aCoder decodeBoolForKey:CPFontIsBoldKey]];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_name forKey:CPFontNameKey];
    [aCoder encodeFloat:_size forKey:CPFontSizeKey];
    [aCoder encodeBool:_isBold forKey:CPFontIsBoldKey];
}

@end
