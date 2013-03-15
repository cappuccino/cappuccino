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

CPFontDefaultSystemFontFace = @"Arial, sans-serif";
CPFontDefaultSystemFontSize = 12;

/*!
    To create a font of a size that will dynamically reflect the current
    system font size, use this for the size argument.
*/
CPFontCurrentSystemSize = -1;

// For internal use only by this class and subclasses
_CPFontSystemFacePlaceholder = "_CPFontSystemFacePlaceholder";

var _CPFontCache          = {},
    _CPSystemFontCache    = {},
    _CPFontSystemFontFace = CPFontDefaultSystemFontFace,
    _CPFontSystemFontSize = 12,
    _CPFontFallbackFaces  = CPFontDefaultSystemFontFace.split(", "),
    _CPFontStripRegExp    = new RegExp("(^\\s*[\"']?|[\"']?\\s*$)", "g");


#define _CPRealFontSize(aSize)  (aSize <= 0 ? _CPFontSystemFontSize : aSize)
#define _CPFontNormalizedNames(aName)  _CPFontNormalizedNameArray(aName).join(", ")
#define _CPCachedFont(aName, aSize, isBold, isItalic)  _CPFontCache[_CPFontCreateCSSString(_CPFontNormalizedNames(aName), aSize, isBold, isItalic)]
#define _CPUserFont(aName, aSize, isBold, isItalic)  _CPCachedFont(aName, aSize, isBold, isItalic) || [[CPFont alloc] _initWithName:aName size:aSize bold:isBold italic:isItalic system:NO]

#define _CPSystemFontCacheKey(aSize, isBold)  (String(aSize) + (isBold ? "b" : ""))
#define _CPCachedSystemFont(aSize, isBold)  _CPSystemFontCache[_CPSystemFontCacheKey(aSize, isBold)]
#define _CPSystemFont(aSize, isBold)  (_CPCachedSystemFont(aSize, isBold) || [[CPFont alloc] _initWithName:_CPFontSystemFacePlaceholder size:aSize bold:isBold italic:NO system:YES])

/*!
@ingroup appkit
@class CPFont

The CPFont class allows control of the fonts used for displaying text anywhere on the screen.
The primary method for getting a particular font is through one of the class methods that take
a name and/or size as arguments, and return the appropriate CPFont.

### System fonts
When you create a font using \c -systemFontOfSize: or \c -boldSystemFontOfSize:, a proxy font is
created that always refers to the current system font face and size. By default the system
font face/size is Arial 12px, with a fallback to sans-serif 12px. You may configure this at
runtime in two ways:

- By sending [CPFont setSystemFontFace:<face>] and/or [CPFont setSystemFontSize:<size>].
  Note that if you change the system font face or size during runtime, the next time
  any view using a system font is redrawn, it will show the new font.
- By configuring Info.plist for your application or for AppKit. You can set the font face
  by adding a CPSystemFontFace string item to the Info.plist, and you can set the font size
  by adding a CPSystemFontSize integer item to the Info.plist.

Note that in either case, you can specify a comma-delimited list of fonts as the font face.
Do not quote enclose font faces that contain spaces, that is done automatically when a CSS
representation of a font is requested.

The browser will use the first available font in the list you supply. CPFont always ensures
that Arial and sans-serif are in the CSS representation of a font as a fallback, so there is
no need to add them to the end of your font list.

### nib2cib conversion
Fonts are converted by nib2cib according to the following algorithm:

- If the font family is Lucida Grande, then a system font will be created.
- If the font is Lucida Grande 13 (plain), the "default" font will be used at runtime.
  The default font is taken from the "font" theme attribute if one exists,
  otherwise from the current system font face and size.
- Lucida Grande of any size other than 13 will retain its size.
- Fonts using any family other than Lucida Grande will be used as is, including the size.

### Using custom web fonts
The configurability of CPFont makes it easy to use a custom web font as the system font.
For example, if you want to use the google font Asap as the system font, you would do the
following:

- Add a <link> to the <head> of index-debug.html and index.html:
@code
<link href='http://fonts.googleapis.com/css?family=Asap:400,700' rel='stylesheet' type='text/css'>
@endcode
- Specify Asap as the system font in Info.plist by adding the following item:
@code
<key>CPSystemFontFace</key>
<string>Asap</string>
@endcode
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
    BOOL        _isSystem       @accessors(readonly, getter=isSystem);

    CPString    _cssString;
}

+ (void)initialize
{
    if (self !== [CPFont class])
        return;

    var systemFontFace = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPSystemFontFace"];

    if (!systemFontFace)
        systemFontFace = [[CPBundle bundleForClass:[CPView class]] objectForInfoDictionaryKey:@"CPSystemFontFace"];

    if (systemFontFace)
        _CPFontSystemFontFace = _CPFontNormalizedNames(systemFontFace);

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
    var normalizedFaces = _CPFontNormalizedNames(aFace);

    if (normalizedFaces === _CPFontSystemFontFace)
        return;

    [self _invalidateSystemFontCache]
    _CPFontSystemFontFace = aFace;
}

/*!
    Returns the default system font size.
*/
+ (float)systemFontSize
{
    return _CPFontSystemFontSize;
}

+ (float)systemFontSizeForControlSize:(CPControlSize)aSize
{
    // TODO These sizes should be themable or made less arbitrary in some other way.
    switch (aSize)
    {
        case CPSmallControlSize:
            return _CPFontSystemFontSize - 1;

        case CPMiniControlSize:
            return _CPFontSystemFontSize - 2;

        case CPRegularControlSize:
        default:
            return _CPFontSystemFontSize;
    }
}

/*!
    Sets the default system font size.
*/
+ (float)setSystemFontSize:(float)size
{
    if (size > 0 && size !== _CPFontSystemFontSize)
    {
        [self _invalidateSystemFontCache];
        _CPFontSystemFontSize = size;
    }
}

+ (void)_invalidateSystemFontCache
{
    var systemSize = String(_CPFontSystemFontSize),
        currentSize = String(CPFontCurrentSystemSize);

    for (key in _CPSystemFontCache)
    {
        if (_CPSystemFontCache.hasOwnProperty(key) &&
            (key.indexOf(systemSize) === 0 || key.indexOf(currentSize) === 0))
        {
            delete _CPSystemFontCache[key];
        }
    }
}

/*!
    Returns a font with the specified name and size.
    @param aName the name of the font
    @param aSize the size of the font (in px). 0 or negative will create a font
           in the current system font size.
    @return the requested font
*/
+ (CPFont)fontWithName:(CPString)aName size:(float)aSize
{
    return _CPUserFont(aName, aSize <= 0 ? _CPFontSystemFontSize : aSize, NO, NO);
}

/*!
    Returns a font with the specified name, size and style.
    @param aName the name of the font
    @param aSize the size of the font (in px). 0 or negative will create a font
           in the current system font size.
    @param italic whether the font should be italicized
    @return the requested font
*/
+ (CPFont)fontWithName:(CPString)aName size:(float)aSize italic:(BOOL)italic
{
    return _CPUserFont(aName, aSize <= 0 ? _CPFontSystemFontSize : aSize, NO, italic);
}

/*!
    Returns a bold font with the specified name and size.
    @param aName the name of the font
    @param aSize the size of the font (in px). 0 or negative will create a font
           in the current system font size.
    @return the requested bold font
*/
+ (CPFont)boldFontWithName:(CPString)aName size:(float)aSize
{
    return _CPUserFont(aName, aSize <= 0 ? _CPFontSystemFontSize : aSize, YES, NO);
}

/*!
    Returns a bold font with the specified name, size and style.
    @param aName the name of the font
    @param aSize the size of the font (in px). 0 or negative will create a font
           in the current system font size.
    @param italic whether the font should be italicized
    @return the requested font
*/
+ (CPFont)boldFontWithName:(CPString)aName size:(float)aSize italic:(BOOL)italic
{
    return _CPUserFont(aName, aSize <= 0 ? _CPFontSystemFontSize : aSize, YES, italic);
}

/*!
    Internal font getter like fontWithName:size:italic: with a bold selector.
*/
+ (CPFont)_fontWithName:(CPString)aName size:(float)aSize bold:(BOOL)bold italic:(BOOL)italic
{
    return _CPUserFont(aName, aSize <= 0 ? _CPFontSystemFontSize : aSize, bold, italic);
}

/*!
    Returns the system font scaled to the specified size
    @param aSize the size of the font (in px). 0 creates a static font
           in the current system font size. Negative creates a font
           that dynamically tracks the current system font size.
    @return the requested system font
*/
+ (CPFont)systemFontOfSize:(CGSize)aSize
{
    return _CPSystemFont(aSize === 0 ? _CPFontSystemFontSize : aSize, NO);
}

/*!
    Returns the bold system font scaled to the specified size
    @param aSize the size of the font (in px). 0 creates a static font
           in the current system font size. Negative creates a font
           that dynamically tracks the current system font size.
    @return the requested bold system font
*/
+ (CPFont)boldSystemFontOfSize:(CGSize)aSize
{
    return _CPSystemFont(aSize === 0 ? _CPFontSystemFontSize : aSize, YES);
}

- (id)_initWithName:(CPString)aName size:(float)aSize bold:(BOOL)isBold italic:(BOOL)isItalic system:(BOOL)isSystem
{
    self = [super init];

    if (self)
    {
        _size = aSize;
        _ascender = 0;
        _descender = 0;
        _lineHeight = 0;
        _isBold = isBold;
        _isItalic = isItalic;
        _isSystem = isSystem;

        if (isSystem)
        {
            _name = aName;
            _cssString = _CPFontCreateCSSString(_CPFontSystemFontFace, _size, _isBold, _isItalic);
            _CPSystemFontCache[_CPSystemFontCacheKey(_size, _isBold)] = self;
        }
        else
        {
            _name = _CPFontNormalizedNames(aName);
            _cssString = _CPFontCreateCSSString(_name, _size, _isBold, _isItalic);
            _CPFontCache[_cssString] = self;
        }
    }

    return self;
}

/*!
    Returns the distance of the longest ascender's top y-coordinate from the baseline (in CSS px)
*/
- (float)ascender
{
    var font = _isSystem ? _CPSystemFont(_size, _isBold) : self;

    if (!font._ascender)
        [font _getMetrics];

    return font._ascender;
}

/*!
    Returns the bottom y coordinate (in CSS px), offset from the baseline, of the receiver's longest descender.
    Thus, if the longest descender extends 2 px below the baseline, descender will return –2.
*/
- (float)descender
{
    var font = _isSystem ? _CPSystemFont(_size, _isBold) : self;

    if (!font._descender)
        [font _getMetrics];

    return font._descender;
}

/*!
    Returns the default line height.

    NOTE: This was moved from NSFont to NSLayoutManager in Cocoa, but since there is no CPLayoutManager, it has been kept here.
*/
- (float)defaultLineHeightForFont
{
    var font = _isSystem ? _CPSystemFont(_size, _isBold) : self;

    if (!font._lineHeight)
        [font _getMetrics];

    return font._lineHeight;
}

/*!
    Returns the font size (in CSS px)
*/
- (float)size
{
    return _CPRealFontSize(_size);
}

/*!
    Returns the font as a CSS string
*/
- (CPString)cssString
{
    var font = _isSystem ? _CPSystemFont(_size, _isBold) : self;

    return font._cssString;
}

/*!
    Returns the font's family name
*/
- (CPString)familyName
{
    if (_isSystem)
        return _CPFontSystemFontFace;

    return _name;
}

- (BOOL)isSystemSize
{
    return _size <= 0;
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
    return [[CPFont alloc] _initWithName:_name size:_size bold:_isBold italic:_isItalic system:_isSystem];
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
    CPFontIsItalicKey = @"CPFontIsItalicKey",
    CPFontIsSystemKey = @"CPFontIsSystemKey";

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
        isItalic = [aCoder decodeBoolForKey:CPFontIsItalicKey],
        isSystem = [aCoder decodeBoolForKey:CPFontIsSystemKey];

    return [self _initWithName:fontName size:size bold:isBold italic:isItalic system:isSystem];
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
    [aCoder encodeBool:_isSystem forKey:CPFontIsSystemKey];
}

@end


// aName must be normalized
var _CPFontCreateCSSString = function(aName, aSize, isBold, isItalic)
{
    var properties = (isItalic ? "italic " : "") + (isBold ? "bold " : "") + _CPRealFontSize(aSize) + "px ";

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
