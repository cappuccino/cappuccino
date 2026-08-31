/*
 * CPFontDescriptor.j
 * AppKit
 *
 * Created by Emmanuel Maillard on 07/03/10.
 * Copyright Emmanuel Maillard 2010.
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

/*!
 @global
 Key for font name attribute (may be a comma-separated list like 'Marker Felt, Lucida Grande, Helvetica').
 */
CPFontNameAttribute = @"CPFontNameAttribute";

/*!
 @global
 Key for font size attribute (in points).
 */
CPFontSizeAttribute = @"CPFontSizeAttribute";

/*!
 @global
 Key for font traits dictionary attribute.
 */
CPFontTraitsAttribute = @"CPFontTraitsAttribute";

/*!
 @global
 Font traits dictionary key for symbolic traits (combination of typeface and family flags).
 */
CPFontSymbolicTrait = @"CPFontSymbolicTrait";

/*!
 @global
 Font traits dictionary key for CSS font weight.
 */
CPFontWeightTrait = @"CPFontWeightTrait";

/*!
 @global
 Font family design classification constants.
 */
CPFontUnknownClass              = 0 << 28;
CPFontOldStyleSerifsClass       = 1 << 28;
CPFontTransitionalSerifsClass   = 2 << 28;
CPFontModernSerifsClass         = 3 << 28;
CPFontClarendonSerifsClass      = 4 << 28;
CPFontSlabSerifsClass           = 5 << 28;
CPFontFreeformSerifsClass       = 7 << 28;
CPFontSansSerifClass            = 8 << 28;

/*!
 @global
 Mask matching all serif font family classes.
 */
CPFontSerifClass = (CPFontOldStyleSerifsClass | CPFontTransitionalSerifsClass |
                    CPFontModernSerifsClass | CPFontClarendonSerifsClass |
                    CPFontSlabSerifsClass | CPFontFreeformSerifsClass);

/*!
 @global
 Bitmask used to extract the font family class from symbolic traits.
 */
CPFontFamilyClassMask = 0xF0000000;

/*!
 @global
 Symbolic typeface trait bitmask flags.
 */
CPFontItalicTrait       = 1 << 0;
CPFontBoldTrait         = 1 << 1;
CPFontExpandedTrait     = 1 << 5;
CPFontCondensedTrait    = 1 << 6;
CPFontSmallCapsTrait    = 1 << 7;

/*!
 @ingroup appkit
 @class CPFontDescriptor
 CPFontDescriptor encapsulates font dictionaries and attributes (such as family, size, face, and traits)
 for querying, creating, and manipulating typography.
 */
@implementation CPFontDescriptor : CPObject
{
    CPDictionary _attributes;
}

/*!
 Creates and returns a font descriptor initialized with the specified attributes.
 @param attributes a dictionary describing the font attributes
 @return the initialized font descriptor
 */
+ (CPFontDescriptor)fontDescriptorWithFontAttributes:(CPDictionary)attributes
{
    return [[CPFontDescriptor alloc] initWithFontAttributes:attributes];
}

/*!
 Creates and returns a font descriptor initialized with the specified font name and size.
 @param fontName the name or family name of the font
 @param size the size of the font (in points)
 @return the initialized font descriptor
 */
+ (CPFontDescriptor)fontDescriptorWithName:(CPString)fontName size:(float)size
{
    return [[CPFontDescriptor alloc] initWithFontAttributes:[CPDictionary dictionaryWithObjects:[fontName, [CPString stringWithString:size + '']] forKeys:[CPFontNameAttribute, CPFontSizeAttribute]]];
}

/*!
 Initializes a font descriptor with the specified attributes dictionary.
 @param attributes a dictionary describing the font attributes
 @return the initialized font descriptor
 */
- (id)initWithFontAttributes:(CPDictionary)attributes
{
    if (self = [super init])
    {
        _attributes = [[CPMutableDictionary alloc] init];

        if (attributes)
            [_attributes addEntriesFromDictionary:attributes];
    }

    return self;
}

/*!
 Returns a new font descriptor copy with the specified attributes taking precedence over existing ones.
 @param attributes a dictionary of attributes to merge/override
 @return a new \c CPFontDescriptor instance
 */
- (CPFontDescriptor)fontDescriptorByAddingAttributes:(CPDictionary)attributes
{
    var attrib = [_attributes copy];

    [attrib addEntriesFromDictionary:attributes];

    return [[CPFontDescriptor alloc] initWithFontAttributes:attrib];
}

/*!
 Returns a new font descriptor copy with the specified font size taking precedence.
 @param aSize the new size in points
 @return a new \c CPFontDescriptor instance
 */
- (CPFontDescriptor)fontDescriptorWithSize:(float)aSize
{
    var attrib = [_attributes copy];

    [attrib setObject:[CPString stringWithString:aSize + ''] forKey:CPFontSizeAttribute];

    return [[CPFontDescriptor alloc] initWithFontAttributes:attrib];
}

/*!
 Returns a new font descriptor copy with the specified symbolic traits taking precedence.
 @param symbolicTraits the new symbolic trait bitmask
 @return a new \c CPFontDescriptor instance
 */
- (CPFontDescriptor)fontDescriptorWithSymbolicTraits:(CPFontSymbolicTraits)symbolicTraits
{
    var attrib = [_attributes copy];

    if ([attrib objectForKey:CPFontTraitsAttribute])
    {
        [[attrib objectForKey:CPFontTraitsAttribute] setObject:[CPNumber numberWithUnsignedInt:symbolicTraits]
                                                        forKey:CPFontSymbolicTrait];
    }
    else
    {
        [attrib setObject:[CPDictionary dictionaryWithObject:[CPNumber numberWithUnsignedInt:symbolicTraits]
                                                      forKey:CPFontSymbolicTrait]
                   forKey:CPFontTraitsAttribute];
    }

    return [[CPFontDescriptor alloc] initWithFontAttributes:attrib];
}

/*!
 Returns the attribute value associated with a given key.
 @param aKey the attribute key name
 @return the attribute value, or \c nil
 */
- (id)objectForKey:(id)aKey
{
    return [_attributes objectForKey:aKey];
}

/*!
 Returns the dictionary of font attributes for the descriptor.
 @return the attributes dictionary
 */
- (CPDictionary)fontAttributes
{
    return _attributes;
}

/*!
 Returns the point size attribute of the font descriptor.
 @return the point size as a float value
 */
- (float)pointSize
{
    var value = [_attributes objectForKey:CPFontSizeAttribute];

    return value ? [value floatValue] : 0.0;
}

/*!
 Returns the symbolic traits bitmask of the font descriptor.
 @return the symbolic traits bitmask
 */
- (CPFontSymbolicTraits)symbolicTraits
{
    var traits = [_attributes objectForKey:CPFontTraitsAttribute];

    return (traits && [traits objectForKey:CPFontSymbolicTrait]) ? [[traits objectForKey:CPFontSymbolicTrait] unsignedIntValue] : 0;
}

@end

/* @ignore */
var CPFontDescriptorAttributesKey = @"CPFontDescriptorAttributesKey";

/*!
 @category CPFontDescriptor (CPCoding)
 */
@implementation CPFontDescriptor (CPCoding)

/*!
 Initializes the font descriptor from a coder.
 @param aCoder the coder object
 @return the unarchived font descriptor
 */
- (id)initWithCoder:(CPCoder)aCoder
{
    return [self initWithFontAttributes:[aCoder decodeObjectForKey:CPFontDescriptorAttributesKey]];
}

/*!
 Archives the font descriptor attributes into a coder.
 @param aCoder the coder object
 */
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_attributes forKey:CPFontDescriptorAttributesKey];
}

@end

/* @ignore */
var _wrapNameRegEx = new RegExp(/(\w+\s+\w+)(,*)/g);

/*!
 @category CPFontDescriptor (CPFontCSSHelper)
 Helper methods for generating CSS font representations from font descriptors.
 */
@implementation CPFontDescriptor (CPFontCSSHelper)

/*!
 Returns the CSS font-style string (e.g. \c @"italic" or \c @"normal").
 @return the CSS font style string
 */
- (CPString)fontStyleCSSString
{
    return [self symbolicTraits] & CPFontItalicTrait ? @"italic" : @"normal";
}

/*!
 Returns the CSS font-weight string (e.g. \c @"bold", \c @"normal", or numerical weight).
 @return the CSS font weight string
 */
- (CPString)fontWeightCSSString
{
    var traitsAttributes = [_attributes objectForKey:CPFontTraitsAttribute];

    if (traitsAttributes)
    {
        /* give preference to CPFontWeightTrait */
        if ([traitsAttributes objectForKey:CPFontWeightTrait])
            return [traitsAttributes objectForKey:CPFontWeightTrait];

        /* else fallback to facetype symbolic traits */
        if ([self symbolicTraits] & CPFontBoldTrait)
            return @"bold";
    }

    return @"normal";
}

/*!
 Returns the CSS font-size string with pixel units (e.g. \c @"12px").
 @return the CSS font size string
 */
- (CPString)fontSizeCSSString
{
    return [_attributes objectForKey:CPFontSizeAttribute] ? [[_attributes objectForKey:CPFontSizeAttribute] intValue] + "px" : @"";
}

/*!
 Returns the CSS font-family string.
 @return the formatted CSS font family string
 */
- (CPString)fontFamilyCSSString
{
    var aName = @"";

    if ([_attributes objectForKey:CPFontNameAttribute])
        aName += [_attributes objectForKey:CPFontNameAttribute].replace(_wrapNameRegEx, '"$1"$2');

    var symbolicTraits = [self symbolicTraits];

    if (symbolicTraits)
    {
        if ((symbolicTraits & CPFontFamilyClassMask) & CPFontSansSerifClass)
            aName += @", sans-serif";
        else if ((symbolicTraits & CPFontFamilyClassMask) & CPFontSerifClass)
            aName += @", serif";
    }

    return aName;
}

/*!
 Returns the CSS font-variant string (e.g. \c @"small-caps" or \c @"normal").
 @return the CSS font variant string
 */
- (CPString)fontVariantCSSString
{
    if ([self symbolicTraits] & CPFontSmallCapsTrait)
        return @"small-caps";

    return @"normal";
}

/*!
 Returns the complete shorthand CSS font property string.
 @return the CSS font shorthand string
 */
- (CPString)cssString
{
    return [CPString stringWithString:[self fontStyleCSSString] + " "
            + [self fontVariantCSSString] + " "
            + [self fontWeightCSSString] + " "
            + [self fontSizeCSSString] + " "
            + [self fontFamilyCSSString]];
}

@end
