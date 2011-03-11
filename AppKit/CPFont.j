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

@import <Foundation/CPObject.j>
@import <Foundation/CPBundle.j>

@import "CPView.j"


var _CPFonts                        = {},
    _CPFontSystemFontFace           = @"Arial, sans-serif",
    _CPFontSystemFontSize           = 12,
    _CPFontDefaultSystemFontFace    = @"Arial, sans-serif",
    _CPFontDefaultSystemFontSize    = 12,
    _CPFontFallbackFaces            = _CPFontDefaultSystemFontFace.split(", "),
    _CPFontStripRegExp              = new RegExp("(^\\s*[\"']?|[\"']?\\s*$)", "g");


#define _CPFontNormalizedNames(aName)  _CPFontNormalizedNameArray(aName).join(", ")
#define _CPCachedFont(aName, aSize, isBold, isItalic)  _CPFonts[_CPFontCreateCSSString(_CPFontNormalizedNames(aName), aSize, isBold, isItalic)]

/*!
    @ingroup appkit
    @class CPFont

    The CPFont class allows control of the fonts used for displaying text anywhere on the screen. The primary method for getting a particular font is through one of the class methods that take a name and/or size as arguments, and return the appropriate CPFont.
*/
@implementation CPFont : CPObject
{
    CPString    _name;
    float       _size;
    float       _ascender;
    float       _descender;
    float       _lineHeight;
    BOOL        _isBold         @accessors(readonly, getter=isBold);
    BOOL        _isItalic       @accessors(readonly, getter=isItalic);

    CPString    _cssString;
}

+ (void)initialize
{
    var systemFontFace = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPSystemFontFace"];

    if (!systemFontFace)
        systemFontFace = [[CPBundle bundleForClass:[CPView class]] objectForInfoDictionaryKey:@"CPSystemFontFace"];

    if (systemFontFace)
        [self setSystemFontFace:systemFontFace];

    var systemFontSize = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPSystemFontSize"];

    if (!systemFontSize)
        systemFontSize = [[CPBundle bundleForClass:[CPView class]] objectForInfoDictionaryKey:@"CPSystemFontSize"];

    if (systemFontSize)
        _CPFontSystemFontSize = systemFontSize;
}

/*!
    Returns the default system font face, which may consist of several comma-separated family names.
*/
+ (CPString)systemFontFace
{
    return _CPFontSystemFontFace;
}

/*!
    Sets the default system font face, which may consist of several comma-separated family names.
*/
+ (CPString)setSystemFontFace:(CPString)aFace
{
    _CPFontSystemFontFace = _CPFontNormalizedNames(aFace);
}

/*!
    Returns the default system font size.
*/
+ (float)systemFontSize
{
    return _CPFontSystemFontSize;
}

/*!
    Sets the default system font size.
*/
+ (float)setSystemFontSize:(float)size
{
    if (size > 0)
        _CPFontSystemFontSize = size;
}

/*!
    Returns a font with the specified name and size.
    @param aName the name of the font
    @param aSize the size of the font (in px)
    @return the requested font
*/
+ (CPFont)fontWithName:(CPString)aName size:(float)aSize
{
    return _CPCachedFont(aName, aSize, NO, NO) || [[CPFont alloc] _initWithName:aName size:aSize bold:NO italic:NO];
}

/*!
    Returns a font with the specified name, size and style.
    @param aName the name of the font
    @param aSize the size of the font (in px)
    @param italic whether the font should be italicized
    @return the requested font
*/
+ (CPFont)fontWithName:(CPString)aName size:(float)aSize italic:(BOOL)italic
{
    return _CPCachedFont(aName, aSize, NO, NO) || [[CPFont alloc] _initWithName:aName size:aSize bold:NO italic:italic];
}

/*!
    Returns a bold font with the specified name and size.
    @param aName the name of the font
    @param aSize the size of the font (in px)
    @return the requested bold font
*/
+ (CPFont)boldFontWithName:(CPString)aName size:(float)aSize
{
    return _CPCachedFont(aName, aSize, YES, NO) || [[CPFont alloc] _initWithName:aName size:aSize bold:YES italic:NO];
}

/*!
    Returns a bold font with the specified name, size and style.
    @param aName the name of the font
    @param aSize the size of the font (in px)
    @param italic whether the font should be italicized
    @return the requested font
*/
+ (CPFont)boldFontWithName:(CPString)aName size:(float)aSize italic:(BOOL)italic
{
    return _CPCachedFont(aName, aSize, NO, NO) || [[CPFont alloc] _initWithName:aName size:aSize bold:YES italic:italic];
}

/*!
    Returns the system font scaled to the specified size
    @param aSize the size of the font (in px)
    @return the requested system font
*/
+ (CPFont)systemFontOfSize:(CPSize)aSize
{
    return _CPCachedFont(_CPFontSystemFontFace, aSize, NO, NO) || [[CPFont alloc] _initWithName:_CPFontSystemFontFace size:aSize bold:NO italic:NO];
}

/*!
    Returns the bold system font scaled to the specified size
    @param aSize the size of the font (in px)
    @return the requested bold system font
*/
+ (CPFont)boldSystemFontOfSize:(CPSize)aSize
{
    return _CPCachedFont(_CPFontSystemFontFace, aSize, YES, NO) || [[CPFont alloc] _initWithName:_CPFontSystemFontFace size:aSize bold:YES italic:NO];
}

/*  FIXME Font Descriptor
    @ignore
*/
- (id)_initWithName:(CPString)aName size:(float)aSize bold:(BOOL)isBold
{
    return [self _initWithName:aName size:aSize bold:isBold italic:NO];
}

- (id)_initWithName:(CPString)aName size:(float)aSize bold:(BOOL)isBold italic:(BOOL)isItalic
{
    self = [super init];

    if (self)
    {
        _name = _CPFontNormalizedNames(aName);
        _size = aSize;
        _ascender = 0;
        _descender = 0;
        _lineHeight = 0;
        _isBold = isBold;
        _isItalic = isItalic;

        _cssString = _CPFontCreateCSSString(_name, _size, _isBold, _isItalic);

        _CPFonts[_cssString] = self;
    }

    return self;
}

/*!
    Returns the distance of the longest ascender's top y-coordinate from the baseline (in CSS px)
*/
- (float)ascender
{
    if (!_ascender)
        [self _getMetrics];

    return _ascender;
}

/*!
    Returns the bottom y coordinate (in CSS px), offset from the baseline, of the receiver's longest descender.
    Thus, if the longest descender extends 2 px below the baseline, descender will return –2.
*/
- (float)descender
{
    if (!_descender)
        [self _getMetrics];

    return _descender;
}

/*!
    Returns the default line height.

    NOTE: This was moved from NSFont to NSLayoutManager in Cocoa, but since there is no CPLayoutManager, it has been kept here.
*/
- (float)defaultLineHeightForFont
{
    if (!_lineHeight)
        [self _getMetrics];

    return _lineHeight;
}

/*!
    Returns the font size (in CSS px)
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
    return [anObject isKindOfClass:[CPFont class]] && [anObject cssString] === _cssString;
}

- (CPString)description
{
    return [CPString stringWithFormat:@"%@ %@", [super description], [self cssString]];
}

- (id)copy
{
    return [[CPFont alloc] _initWithName:_name size:_size bold:_isBold italic:_isItalic];
}

- (void)_getMetrics
{
    var metrics = [CPString metricsOfFont:self];

    _ascender = [metrics objectForKey:@"ascender"];
    _descender = [metrics objectForKey:@"descender"];
    _lineHeight = [metrics objectForKey:@"lineHeight"];
}

@end

var CPFontNameKey     = @"CPFontNameKey",
    CPFontSizeKey     = @"CPFontSizeKey",
    CPFontIsBoldKey   = @"CPFontIsBoldKey",
    CPFontIsItalicKey = @"CPFontIsItalicKey";

@implementation CPFont (CPCoding)

/*!
    Initializes the font from a coder.
    @param aCoder the coder from which to read the font data
    @return the initialized font
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    var fontName = [aCoder decodeObjectForKey:CPFontNameKey],
        size = [aCoder decodeFloatForKey:CPFontSizeKey],
        isBold = [aCoder decodeBoolForKey:CPFontIsBoldKey],
        isItalic = [aCoder decodeBoolForKey:CPFontIsItalicKey];

    return [self _initWithName:fontName size:size bold:isBold italic:isItalic];
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
    [aCoder encodeBool:_isItalic forKey:CPFontIsItalicKey];
}

@end


// aName must normalized
var _CPFontCreateCSSString = function(aName, aSize, isBold, isItalic)
{
    // aName might be a string or an array of preprocessed names
    var properties = (isItalic ? "italic " : "") + (isBold ? "bold " : "") + aSize + "px ";

    return properties + _CPFontConcatNameWithFallback(aName);
};

var _CPFontConcatNameWithFallback = function(aName)
{
    var names = _CPFontNormalizedNameArray(aName),
        fallbackFaces = _CPFontFallbackFaces.slice(0);

    // Remove the fallback names used in the names passed in
    for (var i = 0; i < names.length; ++i)
    {
        for (var j = 0; j < fallbackFaces.length; ++j)
        {
            if (names[i].toLowerCase() === fallbackFaces[j].toLowerCase())
            {
                fallbackFaces.splice(j, 1);
                break;
            }
        }

        if (names[i].indexOf(" ") > 0)
            names[i] = '"' + names[i] + '"';
    }

    return names.concat(fallbackFaces).join(", ");
};

var _CPFontNormalizedNameArray = function(aName)
{
    var names = aName.split(",");

    for (var i = 0; i < names.length; ++i)
        names[i] = names[i].replace(_CPFontStripRegExp, "");

    return names;
};
