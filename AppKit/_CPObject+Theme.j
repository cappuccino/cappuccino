/*
 * AppKit.j
 * AppKit
 *
 * Created by Alexandre Wilhelm.
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

@import <Foundation/Foundation.j>

@import "CPTheme.j"

var CachedThemeAttributes       = nil;

var CPViewThemeClassKey             = @"CPViewThemeClassKey",
    CPViewThemeStateKey             = @"CPViewThemeStateKey";

@protocol CPTheme

- (CPString)themeClass;
- (void)setThemeClass:(CPString)theClass;

- (CPTheme)theme;
- (void)setTheme:(CPTheme)aTheme;

- (unsigned)themeState;
- (BOOL)hasThemeState:(ThemeState)aState;
- (BOOL)setThemeState:(ThemeState)aState;
- (BOOL)unsetThemeState:(ThemeState)aState;
- (BOOL)hasThemeAttribute:(CPString)aName;

- (void)objectDidChangeTheme;

- (void)setValue:(id)aValue forThemeAttribute:(CPString)aName inState:(ThemeState)aState;
- (void)setValue:(id)aValue forThemeAttribute:(CPString)aName;
- (id)valueForThemeAttribute:(CPString)aName inState:(ThemeState)aState;
- (id)valueForThemeAttribute:(CPString)aName;
- (id)currentValueForThemeAttribute:(CPString)aName;
- (void)registerThemeValues:(CPArray)themeValues;
- (void)registerThemeValues:(CPArray)themeValues inherit:(CPArray)inheritedValues;

@end

@implementation CPObject (ObjectTheming)
{
    // Theming Support
    CPTheme             _theme;
    CPString            _themeClass;
    JSObject            _themeAttributes;
    unsigned            _themeState;
}


#pragma mark -
#pragma mark Theme State

- (unsigned)themeState
{
    return _themeState;
}

- (BOOL)hasThemeState:(ThemeState)aState
{
    if (aState.isa && [aState isKindOfClass:CPArray])
        return _themeState.hasThemeState.apply(_themeState, aState);

    return _themeState.hasThemeState(aState);
}

- (BOOL)setThemeState:(ThemeState)aState
{
    if (aState && aState.isa && [aState isKindOfClass:CPArray])
        aState = CPThemeState.apply(null, aState);

    if (_themeState.hasThemeState(aState))
        return NO;

    _themeState = CPThemeState(_themeState, aState);

    return YES;
}

- (BOOL)unsetThemeState:(ThemeState)aState
{
    if (aState && aState.isa && [aState isKindOfClass:CPArray])
        aState = CPThemeState.apply(null, aState);

    var oldThemeState = _themeState;
    _themeState = _themeState.without(aState);

    if (oldThemeState === _themeState)
        return NO;

    return YES;
}

#pragma mark Theme Attributes

+ (CPString)defaultThemeClass
{
    return nil;
}

+ (CPDictionary)themeAttributes
{
    return nil;
}

- (CPString)themeClass
{
    if (_themeClass)
        return _themeClass;

    return [[self class] defaultThemeClass];
}

- (void)setThemeClass:(CPString)theClass
{
    _themeClass = theClass;

    [self _loadThemeAttributes];
}

+ (CPArray)_themeAttributes
{
    if (!CachedThemeAttributes)
        CachedThemeAttributes = {};

    var theClass = [self class],
        CPObjectClass = [CPObject class],
        attributes = [],
        nullValue = [CPNull null];

    for (; theClass && theClass !== CPObjectClass; theClass = [theClass superclass])
    {
        var cachedAttributes = CachedThemeAttributes[class_getName(theClass)];

        if (cachedAttributes)
        {
            attributes = attributes.length ? attributes.concat(cachedAttributes) : attributes;
            CachedThemeAttributes[[self className]] = attributes;

            break;
        }

        var attributeDictionary = [theClass themeAttributes];

        if (!attributeDictionary)
            continue;

        var attributeKeys = [attributeDictionary allKeys],
            attributeCount = attributeKeys.length;

        while (attributeCount--)
        {
            var attributeName = attributeKeys[attributeCount],
                attributeValue = [attributeDictionary objectForKey:attributeName];

            attributes.push(attributeValue === nullValue ? nil : attributeValue);
            attributes.push(attributeName);
        }
    }

    return attributes;
}

- (void)_loadThemeAttributes
{
    var theClass = [self class],
        attributes = [theClass _themeAttributes],
        count = attributes.length;

    if (!count)
        return;

    var theme = [self theme],
        themeClass = [self themeClass];

    _themeAttributes = {};

    while (count--)
    {
        var attributeName = attributes[count--],
            attribute = [[_CPThemeAttribute alloc] initWithName:attributeName defaultValue:attributes[count]];

        [attribute setParentAttribute:[theme attributeWithName:attributeName forClass:themeClass]];

        _themeAttributes[attributeName] = attribute;
    }
}

- (CPTheme)theme
{
    return _theme;
}

- (void)setTheme:(CPTheme)aTheme
{
    if (_theme === aTheme)
        return;

    _theme = aTheme;

    [self objectDidChangeTheme];
}

- (void)objectDidChangeTheme
{
    if (!_themeAttributes)
        return;

    var theme = [self theme],
        themeClass = [self themeClass];

    for (var attributeName in _themeAttributes)
    {
        if (_themeAttributes.hasOwnProperty(attributeName))
            [_themeAttributes[attributeName] setParentAttribute:[theme attributeWithName:attributeName forClass:themeClass]];
    }

}

- (CPDictionary)_themeAttributeDictionary
{
    var dictionary = @{};

    if (_themeAttributes)
    {
        var theme = [self theme];

        for (var attributeName in _themeAttributes)
        {
            if (_themeAttributes.hasOwnProperty(attributeName))
                [dictionary setObject:_themeAttributes[attributeName] forKey:attributeName];
        }
    }

    return dictionary;
}

- (void)setValue:(id)aValue forThemeAttribute:(CPString)aName inState:(ThemeState)aState
{
   if (aState.isa && [aState isKindOfClass:CPArray])
        aState = CPThemeState.apply(null, aState);

    if (!_themeAttributes || !_themeAttributes[aName])
        [CPException raise:CPInvalidArgumentException reason:[self className] + " does not contain theme attribute '" + aName + "'"];

    [_themeAttributes[aName] setValue:aValue forState:aState];
}

- (void)setValue:(id)aValue forThemeAttribute:(CPString)aName
{
    if (!_themeAttributes || !_themeAttributes[aName])
        [CPException raise:CPInvalidArgumentException reason:[self className] + " does not contain theme attribute '" + aName + "'"];

    [_themeAttributes[aName] setValue:aValue];
}

- (id)valueForThemeAttribute:(CPString)aName inState:(ThemeState)aState
{
   if (aState.isa && [aState isKindOfClass:CPArray])
        aState = CPThemeState.apply(null, aState);

    if (!_themeAttributes || !_themeAttributes[aName])
        [CPException raise:CPInvalidArgumentException reason:[self className] + " does not contain theme attribute '" + aName + "'"];

    return [_themeAttributes[aName] valueForState:aState];
}

- (id)valueForThemeAttribute:(CPString)aName
{
    if (!_themeAttributes || !_themeAttributes[aName])
        [CPException raise:CPInvalidArgumentException reason:[self className] + " does not contain theme attribute '" + aName + "'"];

    return [_themeAttributes[aName] value];
}

- (id)currentValueForThemeAttribute:(CPString)aName
{
    if (!_themeAttributes || !_themeAttributes[aName])
        [CPException raise:CPInvalidArgumentException reason:[self className] + " does not contain theme attribute '" + aName + "'"];

    return [_themeAttributes[aName] valueForState:_themeState];
}

- (BOOL)hasThemeAttribute:(CPString)aName
{
    return (_themeAttributes && _themeAttributes[aName] !== undefined);
}

/*!
    Registers theme values encoded in an array at runtime. The format of the data in the array
    is the same as that used by ThemeDescriptors.j, with the exception that you need to use
    CPColorWithImages() in place of PatternColor(). For more information see the comments
    at the top of ThemeDescriptors.j.

    @param themeValues array of theme values
*/
- (void)registerThemeValues:(CPArray)themeValues
{
    for (var i = 0; i < themeValues.length; ++i)
    {
        var attributeValueState = themeValues[i],
            attribute = attributeValueState[0],
            value = attributeValueState[1],
            state = attributeValueState[2];

        if (state)
            [self setValue:value forThemeAttribute:attribute inState:state];
        else
            [self setValue:value forThemeAttribute:attribute];
    }
}

/*!
    Registers theme values encoded in an array at runtime. The format of the data in the array
    is the same as that used by ThemeDescriptors.j, with the exception that you need to use
    CPColorWithImages() in place of PatternColor(). The values in \c inheritedValues are
    registered first, then those in \c themeValues override/augment the inherited values.
    For more information see the comments at the top of ThemeDescriptors.j.

    @param themeValues array of base theme values
    @param inheritedValues array of overridden/additional theme values
*/
- (void)registerThemeValues:(CPArray)themeValues inherit:(CPArray)inheritedValues
{
    // Register inherited values first, then override those with the subtheme values.
    if (inheritedValues)
        [self registerThemeValues:inheritedValues];

    if (themeValues)
        [self registerThemeValues:themeValues];
}

- (void)_encodeThemeObjectsWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:[self themeClass] forKey:CPViewThemeClassKey];
    [aCoder encodeObject:String(_themeState) forKey:CPViewThemeStateKey];

    for (var attributeName in _themeAttributes)
    {
        if (_themeAttributes.hasOwnProperty(attributeName))
            CPThemeAttributeEncode(aCoder, _themeAttributes[attributeName]);
    }
}

- (void)_decodeThemeObjectsWithCoder:(CPCoder)aCoder
{
    _theme = [CPTheme defaultTheme];
    _themeClass = [aCoder decodeObjectForKey:CPViewThemeClassKey];
    _themeState = CPThemeState([aCoder decodeObjectForKey:CPViewThemeStateKey]);
    _themeAttributes = {};

    var theClass = [self class],
        themeClass = [self themeClass],
        attributes = [theClass _themeAttributes],
        count = attributes.length;

    while (count--)
    {
        var attributeName = attributes[count--];

        _themeAttributes[attributeName] = CPThemeAttributeDecode(aCoder, attributeName, attributes[count], _theme, themeClass);
    }
}

@end