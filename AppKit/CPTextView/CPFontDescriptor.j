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
/*
    Font descriptor dictionary keys
*/

/*
    CPFontNameAttribute contains a CPString that specified the font name
    (may be an name list like: 'Marker Felt, Lucida Grande, Helvetica')
*/
CPFontNameAttribute = @"CPFontNameAttribute";
/*
    CPFontSizeAttribute contains a CPString that specified the font size
    (as a float value)
*/
CPFontSizeAttribute = @"CPFontSizeAttribute";
/*
    CPFontTraitsAttribute a CPDictionary that contains font traits keys
    (CPFontSymbolicTrait or CPFontWeightTrait)
*/
CPFontTraitsAttribute = @"CPFontTraitsAttribute";

// Font traits dictionary keys
/*
    CPFontSymbolicTrait a CPNumber that contains CPFontFamilyClass and
    typeface information flags. 
*/
CPFontSymbolicTrait = @"CPFontSymbolicTrait";

/*
    CPFontWeightTrait
    We use CPString with CSS string values for font weight
    (normal | bold | bolder | lighter | 100 | 200 | 300 | 400 
    | 500 | 600 | 700 | 800 | 900)
    NOTE: Cocoa compatibility issue: NSFontWeightTrait are NSNumber for
    font weight (from -1.0 to 1.0, 0.0 for normal weight).
*/
CPFontWeightTrait = @"CPFontWeightTrait";

/*
    CPFontFamilyClass
*/
CPFontUnknownClass              = (0 << 28);
CPFontOldStyleSerifsClass       = (1 << 28);
CPFontTransitionalSerifsClass   = (2 << 28);
CPFontModernSerifsClass         = (3 << 28);
CPFontClarendonSerifsClass      = (4 << 28);
CPFontSlabSerifsClass           = (5 << 28);
CPFontFreeformSerifsClass       = (7 << 28);
CPFontSansSerifClass            = (8 << 28);

CPFontSerifClass = (CPFontOldStyleSerifsClass | CPFontTransitionalSerifsClass |
                    CPFontModernSerifsClass | CPFontClarendonSerifsClass |
                    CPFontSlabSerifsClass | CPFontFreeformSerifsClass);

CPFontFamilyClassMask = 0xF0000000;

/*
    Typeface information
*/
CPFontItalicTrait       = (1 << 0);
CPFontBoldTrait         = (1 << 1);
CPFontExpandedTrait     = (1 << 5); /* TODO: CCS 3 font-stretch */
CPFontCondensedTrait    = (1 << 6);

CPFontSmallCapsTrait    = (1 << 7);

/*!
    @ingroup appkit
    @class CPFontDescriptor
*/
@implementation CPFontDescriptor : CPObject
{
    CPDictionary _attributes;
}

/*!
    Returns a font descriptor with the specified attributes.

    @param attributes a dictionary that describe the desired font descriptor
    @return the requested font descriptor
*/
+ (CPFontDescriptor)fontDescriptorWithFontAttributes:(CPDictionary)attributes
{
    return [[CPFontDescriptor alloc] initWithFontAttributes:attributes];
}

/*!
    Returns a font descriptor with the specified name and size.

    @param fontName the name of the font
    @param aSize the size of the font (in points)
    @return the requested font descriptor
*/
+ (CPFontDescriptor)fontDescriptorWithName:(CPString)fontName size:(float)size
{
    return [[CPFontDescriptor alloc] initWithFontAttributes:[CPDictionary dictionaryWithObjects:[fontName, [CPString stringWithString:size + '']] forKeys:[CPFontNameAttribute,CPFontSizeAttribute]]];
}

/*!
    Initialize a font descriptor with the specified attributes.

    @param attributes a dictionary that describe the desired font descriptor
    @return the requested font descriptor
*/
- (id)initWithFontAttributes:(CPDictionary)attributes
{
    self = [super init];

    if (self)
    {
        _attributes = [[CPMutableDictionary alloc] init];

        if (attributes)
            [_attributes addEntriesFromDictionary:attributes];
    }

    return self;
}

/*!
    Returns a new font descriptor that is the same as the receiver but with the
    specified attributes taking precedence over the existing ones.

    @param attributes a dictionary that describe the desired font descriptor
    @return the new font descriptor
*/
- (CPFontDescriptor)fontDescriptorByAddingAttributes:(CPDictionary)attributes
{
    var attrib = [_attributes copy];
    [attrib addEntriesFromDictionary:attributes];

    return [[CPFontDescriptor alloc] initWithFontAttributes:attrib];
}

/*!
    Returns a new font descriptor that is the same as the receiver but with the specified size taking precedence over the existing ones.

    @param aSize the new size
    @return the new font descriptor
*/
- (CPFontDescriptor)fontDescriptorWithSize:(float)aSize
{
    var attrib = [_attributes copy];
    [attrib setObject:[CPString stringWithString:aSize + ''] forKey:CPFontSizeAttribute];

    return [[CPFontDescriptor alloc] initWithFontAttributes:attrib];
}

/*!
    Returns a new font descriptor that is the same as the receiver but with
    the specified symbolic traits taking precedence over the existing ones.

    @param symbolicTraits the desired new symbolic traits
    @return the new font descriptor
*/
- (CPFontDescriptor)fontDescriptorWithSymbolicTraits:(CPFontSymbolicTraits)symbolicTraits
{
    var attrib = [_attributes copy];

    if ([attrib objectForKey:CPFontTraitsAttribute])
        [[attrib objectForKey:CPFontTraitsAttribute] setObject:[CPNumber numberWithUnsignedInt:symbolicTraits]
                                                     forKey:CPFontSymbolicTrait];
    else
        [attrib setObject:[CPDictionary dictionaryWithObject:[CPNumber numberWithUnsignedInt:symbolicTraits]
                forKey:CPFontSymbolicTrait] forKey:CPFontTraitsAttribute];

    return [[CPFontDescriptor alloc] initWithFontAttributes:attrib];
}

- (id)objectForKey:(id)aKey
{
    return [_attributes objectForKey:aKey];
}

- (CPDictionary)fontAttributes
{
    return _attributes;
}

- (float)pointSize
{
    var value = [_attributes objectForKey:CPFontSizeAttribute];

    if (value)
        return [value floatValue];

    return 0.0;
}

- (CPFontSymbolicTraits)symbolicTraits
{
    var traits = [_attributes objectForKey:CPFontTraitsAttribute];

    if (traits && [traits objectForKey:CPFontSymbolicTrait])
        return [[traits objectForKey:CPFontSymbolicTrait] unsignedIntValue];

    return 0;
}

@end

var CPFontDescriptorAttributesKey = @"CPFontDescriptorAttributesKey";

@implementation CPFontDescriptor (CPCoding)

/*!
    Initializes the font descriptor from a coder.

    @param aCoder the coder from which to read the font descriptor data
    @return the initialized font
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    return [self initWithFontAttributes:[aCoder decodeObjectForKey:CPFontDescriptorAttributesKey]];
}

/*!
    Writes the font descriptor to a coder.

    @param aCoder the coder to which the data will be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_attributes forKey:CPFontDescriptorAttributesKey];
}

@end

var _wrapNameRegEx = new RegExp(/(\w+\s+\w+)(,*)/g);

/*
    Helper methods to CPFont for generating CSS font style
*/
@implementation CPFontDescriptor (CPFontCSSHelper)

- (CPString)fontStyleCSSString
{
    if ([self symbolicTraits] & CPFontItalicTrait)
            return @"italic";

    return @"normal";
}

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

- (CPString)fontSizeCSSString
{
    if ([_attributes objectForKey:CPFontSizeAttribute])
        return [[_attributes objectForKey:CPFontSizeAttribute] intValue] + "px";

    return @"";
}

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

- (CPString)fontVariantCSSString
{
    if ([self symbolicTraits] & CPFontSmallCapsTrait)
        return @"small-caps";

    return @"normal";
}

- (CPString)cssString
{
    return [CPString stringWithString:[self fontStyleCSSString] + " "
                                + [self fontVariantCSSString] + " "
                                + [self fontWeightCSSString] + " "
                                + [self fontSizeCSSString] + " "
                                + [self fontFamilyCSSString]];
}

@end
