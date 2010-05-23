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

var _CPFonts                = {},
    _CPFontSystemFontFace   = @"Arial, sans-serif",
    _CPWrapRegExp           = new RegExp("\\s*,\\s*", "g");


#define _CPCreateCSSString(aName, aSize, isBold) (isBold ? @"bold " : @"") + ROUND(aSize) + @"px " + ((aName === _CPFontSystemFontFace) ? aName : (@"\"" + aName.replace(_CPWrapRegExp, '", "') + @"\", " + _CPFontSystemFontFace))
#define _CPCachedFont(aName, aSize, isBold) _CPFonts[_CPCreateCSSString(aName, aSize, isBold)]

/*! 
    @ingroup appkit
    @class CPFont

    The CPFont class allows control of the fonts used for displaying text anywhere on the screen. The primary method for getting a particular font is through one of the class methods that take a name and/or size as arguments, and return the appropriate CPFont.
*/
@implementation CPFont : CPObject
{
    CPString    _name;
    float       _size;
    BOOL        _isBold;
    
    CPString    _cssString;
}

/*!
    Returns a font with the specified name and size.
    @param aName the name of the font
    @param aSize the size of the font (in points)
    @return the requested font
*/
+ (CPFont)fontWithName:(CPString)aName size:(float)aSize
{
    return _CPCachedFont(aName, aSize, NO) || [[CPFont alloc] _initWithName:aName size:aSize bold:NO];
}

/*!
    Returns a bold font with the specified name and size.
    @param aName the name of the font
    @param aSize the size of the font (in points)
    @return the requested bold font
*/
+ (CPFont)boldFontWithName:(CPString)aName size:(float)aSize
{
    return _CPCachedFont(aName, aSize, YES) || [[CPFont alloc] _initWithName:aName size:aSize bold:YES];
}

/*!
    Returns the system font scaled to the specified size
    @param aSize the size of the font (in points)
    @return the requested system font
*/
+ (CPFont)systemFontOfSize:(CPSize)aSize
{
    return _CPCachedFont(_CPFontSystemFontFace, aSize, NO) || [[CPFont alloc] _initWithName:_CPFontSystemFontFace size:aSize bold:NO];
}

/*!
    Returns the bold system font scaled to the specified size
    @param aSize the size of the font (in points)
    @return the requested bold system font
*/
+ (CPFont)boldSystemFontOfSize:(CPSize)aSize
{
    return _CPCachedFont(_CPFontSystemFontFace, aSize, YES) || [[CPFont alloc] _initWithName:_CPFontSystemFontFace size:aSize bold:YES];
}

/*  FIXME Font Descriptor
    @ignore
*/
- (id)_initWithName:(CPString)aName size:(float)aSize bold:(BOOL)isBold
{   
    self = [super init];
    
    if (self)
    {
        _name = aName;
        _size = aSize;
        _isBold = isBold;
        
        _cssString = _CPCreateCSSString(_name, _size, _isBold);
        
        _CPFonts[_cssString] = self;
    }
    
    return self;
}

/*!
    Returns the font size (in points)
*/
- (float)size
{
    return _size;
}

/*!
    Returns the font as a CSS string
*/
- (CPString)cssString
{
    return _cssString;
}

/*!
    Returns the font's family name
*/
- (CPString)familyName
{
    return _name;
}

- (BOOL)isEqual:(id)anObject
{
    return [anObject isKindOfClass:[CPFont class]] && [anObject cssString] === [self cssString];
}

- (CPString)description
{
    return [CPString stringWithFormat:@"%@ %@ %f pt.", [super description], [self familyName], [self size]];
}

@end

var CPFontNameKey   = @"CPFontNameKey",
    CPFontSizeKey   = @"CPFontSizeKey",
    CPFontIsBoldKey = @"CPFontIsBoldKey";

@implementation CPFont (CPCoding)

/*!
    Initializes the font from a coder.
    @param aCoder the coder from which to read the font data
    @return the initialized font
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    return [self _initWithName:[aCoder decodeObjectForKey:CPFontNameKey]
        size:[aCoder decodeFloatForKey:CPFontSizeKey]
        bold:[aCoder decodeBoolForKey:CPFontIsBoldKey]];
}

/*!
    Writes the font information out to a coder.
    @param aCoder the coder to which the data will be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_name forKey:CPFontNameKey];
    [aCoder encodeFloat:_size forKey:CPFontSizeKey];
    [aCoder encodeBool:_isBold forKey:CPFontIsBoldKey];
}

@end
