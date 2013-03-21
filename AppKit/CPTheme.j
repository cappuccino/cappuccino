/*
 * CPTheme.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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
@import <Foundation/CPMutableArray.j>
@import <Foundation/CPString.j>
@import <Foundation/CPKeyedUnarchiver.j>

@class CPView

var CPThemesByName          = { },
    CPThemeDefaultTheme     = nil,
    CPThemeDefaultHudTheme  = nil;


/*!
    @ingroup appkit
*/

@implementation CPTheme : CPObject
{
    CPString        _name;
    CPDictionary    _attributes;
}

+ (void)setDefaultTheme:(CPTheme)aTheme
{
    CPThemeDefaultTheme = aTheme;
}

+ (CPTheme)defaultTheme
{
    return CPThemeDefaultTheme;
}

/*!
    Set the default HUD theme. If set to nil, the default described in defaultHudTheme
    will be used.
*/
+ (void)setDefaultHudTheme:(CPTheme)aTheme
{
    CPThemeDefaultHudTheme = aTheme;
}

/*!
    The default HUD theme is (sometimes) used for windows with the CPHUDBackgroundWindowMask
    style mask. The default is theme with the name of the default theme with -HUD appended
    at the end.
*/
+ (CPTheme)defaultHudTheme
{
    if (!CPThemeDefaultHudTheme)
        CPThemeDefaultHudTheme = [CPTheme themeNamed:[[self defaultTheme] name] + "-HUD"];
    return CPThemeDefaultHudTheme;
}

+ (CPTheme)themeNamed:(CPString)aName
{
    return CPThemesByName[aName];
}

- (id)initWithName:(CPString)aName
{
    self = [super init];

    if (self)
    {
        _name = aName;
        _attributes = @{};

        CPThemesByName[_name] = self;
    }

    return self;
}

- (CPString)name
{
    return _name;
}

/*!
    Returns an array of names of themed classes defined in this theme, as found in its
    ThemeDescriptors.j file.

    NOTE: The names are not class names (such as "CPButton"), but the names returned
    by the class' +defaultThemeClass method. For example, the name for CPCheckBox is "check-box",
    as defined in CPCheckBox::themeClass.
*/
- (CPArray)classNames
{
    return [_attributes allKeys];
}

/*!
    Returns a dictionary of all theme attributes defined for the given class, as found in the
    theme's ThemeDescriptors.j file. The keys of the dictionary are attribute names, and the values
    are instances of _CPThemeAttribute.

    For a description of valid values for \c aClass, see \ref attributeNamesForClass:.

    @param aClass The themed class whose attributes you want to retrieve
    @return       A dictionary of attributes or nil
*/
- (CPDictionary)attributesForClass:(id)aClass
{
    if (!aClass)
        return nil;

    var className = nil;

    if ([aClass isKindOfClass:[CPString class]])
    {
        // See if it is a class name
        var theClass = CPClassFromString(aClass);

        if (theClass)
            aClass = theClass;
        else
            className = aClass;
    }

    if (!className)
    {
        if ([aClass isKindOfClass:[CPView class]])
        {
            if ([aClass respondsToSelector:@selector(defaultThemeClass)])
                className = [aClass defaultThemeClass];
            else if ([aClass respondsToSelector:@selector(themeClass)])
            {
                CPLog.warn(@"%@ themeClass is deprecated in favor of defaultThemeClass", CPStringFromClass(aClass));
                className = [aClass themeClass];
            }
            else
                return nil;
        }
        else
            [CPException raise:CPInvalidArgumentException reason:@"aClass must be a class object or a string."];
    }

    return [_attributes objectForKey:className];
}

/*!
    Returns an array of names of all theme attributes defined for the given class, as found in the
    theme's ThemeDescriptors.j file.

    The \c aClass parameter can be one of the following:

    - A class instance, for example the result of [CPCheckBox class]. The class must be a subclass
      of CPView.
    - A class name, for example "CPCheckBox".
    - A themed class name, for example "check-box".

    If \c aClass does not refer to a themed class in this theme, nil is returned.

    @param aClass The themed class whose attributes you want to retrieve
    @return       An array of attribute names or nil
*/
- (CPDictionary)attributeNamesForClass:(id)aClass
{
    var attributes = [self attributesForClass:aClass];

    if (attributes)
        return [attributes allKeys];
    else
        return [CPArray array];
}

/*!
    Returns a theme attribute defined for the given class, as found in the
    theme's ThemeDescriptors.j file.

    \c aName should be the attribute name as you would pass to the method
    CPView::valueForThemeAttribute:.

    For a description of valid values for \c aClass, see \ref attributeNamesForClass:.

    @param aName  The name of the attribute you want to retrieve
    @param aClass The themed class in which to look for the attribute
    @return       An instance of _CPThemeAttribute or nil
*/
- (_CPThemeAttribute)attributeWithName:(CPString)aName forClass:(id)aClass
{
    var attributes = [self attributesForClass:aClass];

    if (!attributes)
        return nil;

    return [attributes objectForKey:aName];
}

/*!
    Returns the value for a theme attribute in its normal state, as defined for the given class
    in the theme's ThemeDescriptors.j file.

    \c aName should be the attribute name as you would pass to the method
    CPView::valueForThemeAttribute:.

    For a description of valid values for \c aClass, see \ref attributeNamesForClass:.

    @param aName  The name of the attribute whose value you want to retrieve
    @param aClass The themed class in which to look for the attribute
    @return       A value or nil
*/
- (id)valueForAttributeWithName:(CPString)aName forClass:(id)aClass
{
    return [self valueForAttributeWithName:aName inState:CPThemeStateNormal forClass:aClass];
}

/*!
    Returns the value for a theme attribute in a given state, as defined for the given class
    in the theme's ThemeDescriptors.j file. This is the equivalent of the method
    CPView::valueForThemeAttribute:inState:, but retrieves the value from the theme definition as
    opposed to a single view's current theme state.

    For a description of valid values for \c aClass, see \ref attributeNamesForClass:.

    @param aName  The name of the attribute whose value you want to retrieve
    @param aState The state qualifier for the attribute
    @param aClass The themed class in which to look for the attribute
    @return       A value or nil
*/
- (id)valueForAttributeWithName:(CPString)aName inState:(CPThemeState)aState forClass:(id)aClass
{
    var attribute = [self attributeWithName:aName forClass:aClass];

    if (!attribute)
        return nil;

    return [attribute valueForState:aState];
}

- (void)takeThemeFromObject:(id)anObject
{
    var attributes = [anObject _themeAttributeDictionary],
        attributeName = nil,
        attributeNames = [attributes keyEnumerator],
        objectThemeClass = [anObject themeClass];

    while ((attributeName = [attributeNames nextObject]) !== nil)
        [self _recordAttribute:[attributes objectForKey:attributeName] forClass:objectThemeClass];
}

- (void)_recordAttribute:(_CPThemeAttribute)anAttribute forClass:(CPString)aClass
{
    if (![anAttribute hasValues])
        return;

    var attributes = [_attributes objectForKey:aClass];

    if (!attributes)
    {
        attributes = @{};

        [_attributes setObject:attributes forKey:aClass];
    }

    var name = [anAttribute name],
        existingAttribute = [attributes objectForKey:name];

    if (existingAttribute)
        [attributes setObject:[existingAttribute attributeMergedWithAttribute:anAttribute] forKey:name];
    else
        [attributes setObject:anAttribute forKey:name];
}

@end

var CPThemeNameKey          = @"CPThemeNameKey",
    CPThemeAttributesKey    = @"CPThemeAttributesKey";

@implementation CPTheme (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _name = [aCoder decodeObjectForKey:CPThemeNameKey];
        _attributes = [aCoder decodeObjectForKey:CPThemeAttributesKey];

        CPThemesByName[_name] = self;
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_name forKey:CPThemeNameKey];
    [aCoder encodeObject:_attributes forKey:CPThemeAttributesKey];
}

@end

@implementation _CPThemeKeyedUnarchiver : CPKeyedUnarchiver
{
    CPBundle    _bundle;
}

- (id)initForReadingWithData:(CPData)data bundle:(CPBundle)aBundle
{
    self = [super initForReadingWithData:data];

    if (self)
        _bundle = aBundle;

    return self;
}

- (CPBundle)bundle
{
    return _bundle;
}

- (BOOL)awakenCustomResources
{
    return YES;
}

@end

var CPThemeStates       = {},
    CPThemeStateNames   = {},
    CPThemeStateCount   = 0;

function CPThemeState(aStateName)
{
    var state = CPThemeStates[aStateName];

    if (state === undefined)
    {
        if (aStateName.indexOf('+') === -1)
            state = 1 << CPThemeStateCount++;
        else
        {
            var state = 0,
                states = aStateName.split('+'),
                count = states.length;

            while (count--)
            {
                var stateName = states[count],
                    individualState = CPThemeStates[stateName];

                if (individualState === undefined)
                {
                    individualState = 1 << CPThemeStateCount++;
                    CPThemeStates[stateName] = individualState;
                    CPThemeStateNames[individualState] = stateName;
                }

                state |= individualState;
            }
        }

        CPThemeStates[aStateName] = state;
        CPThemeStateNames[state] = aStateName;
    }

    return state;
}

function CPThemeStateName(aState)
{
    var name = CPThemeStateNames[aState];

    if (name !== undefined)
        return name;

    if (!(aState & (aState - 1)))
        return "";

    var state = 1,
        name = "";

    for (; state < aState; state <<= 1)
        if (aState & state)
            name += (name.length === 0 ? '' : '+') + CPThemeStateNames[state];

    CPThemeStateNames[aState] = name;

    return name;
}

CPThemeStateNames[0]         = "normal";
CPThemeStateNormal           = CPThemeStates["normal"] = 0;
CPThemeStateDisabled         = CPThemeState("disabled");
CPThemeStateHovered          = CPThemeState("hovered");
CPThemeStateHighlighted      = CPThemeState("highlighted");
CPThemeStateSelected         = CPThemeState("selected");
CPThemeStateTableDataView    = CPThemeState("tableDataView");
CPThemeStateSelectedDataView = CPThemeState("selectedTableDataView");
CPThemeStateGroupRow         = CPThemeState("CPThemeStateGroupRow");
CPThemeStateBezeled          = CPThemeState("bezeled");
CPThemeStateBordered         = CPThemeState("bordered");
CPThemeStateEditable         = CPThemeState("editable");
CPThemeStateEditing          = CPThemeState("editing");
CPThemeStateVertical         = CPThemeState("vertical");
CPThemeStateDefault          = CPThemeState("default");
CPThemeStateCircular         = CPThemeState("circular");
CPThemeStateAutocompleting   = CPThemeState("autocompleting");
CPThemeStateMainWindow       = CPThemeState("mainWindow");
CPThemeStateKeyWindow        = CPThemeState("keyWindow");

@implementation _CPThemeAttribute : CPObject
{
    CPString            _name;
    id                  _defaultValue;
    CPDictionary        _values @accessors(readonly, getter=values);

    JSObject            _cache;
    _CPThemeAttribute   _themeDefaultAttribute;
}

- (id)initWithName:(CPString)aName defaultValue:(id)aDefaultValue
{
    self = [super init];

    if (self)
    {
        _cache = { };
        _name = aName;
        _defaultValue = aDefaultValue;
        _values = @{};
    }

    return self;
}

- (CPString)name
{
    return _name;
}

- (id)defaultValue
{
    return _defaultValue;
}

- (BOOL)hasValues
{
    return [_values count] > 0;
}

- (BOOL)isTrivial
{
    return ([_values count] === 1) && (Number([_values allKeys][0]) === CPThemeStateNormal);
}

- (void)setValue:(id)aValue
{
    _cache = {};

    if (aValue === undefined || aValue === nil)
        _values = @{};
    else
        _values = @{ String(CPThemeStateNormal): aValue };
}

- (void)setValue:(id)aValue forState:(CPThemeState)aState
{
    _cache = { };

    if ((aValue === undefined) || (aValue === nil))
        [_values removeObjectForKey:String(aState)];
    else
        [_values setObject:aValue forKey:String(aState)];
}

- (id)value
{
    return [self valueForState:CPThemeStateNormal];
}

- (id)valueForState:(CPThemeState)aState
{
    var value = _cache[aState];

    // This can be nil.
    if (value !== undefined)
        return value;

    value = [_values objectForKey:String(aState)];

    // If we don't have a value, and we have a non-normal state...
    if ((value === undefined || value === nil) && aState !== CPThemeStateNormal)
    {
        // If this is a composite state (not a power of 2), find the closest partial subset match.
        if (aState & (aState - 1))
        {
            var highestOneCount = 0,
                states = [_values allKeys],
                count = states.length;

            while (count--)
            {
                // states[count] is a string!
                var state = Number(states[count]);

                // A & B = A iff A < B
                if ((state & aState) === state)
                {
                    var oneCount = cachedNumberOfOnes[state];

                    if (oneCount === undefined)
                        oneCount = numberOfOnes(state);

                    if (oneCount > highestOneCount)
                    {
                        highestOneCount = oneCount;
                        value = [_values objectForKey:String(state)];
                    }
                }
            }
        }

        // Still don't have a value? OK, let's use the normal value.
        if (value === undefined || value === nil)
            value = [_values objectForKey:String(CPThemeStateNormal)];
    }

    if (value === undefined || value === nil)
        value = [_themeDefaultAttribute valueForState:aState];

    if (value === undefined || value === nil)
    {
        value = _defaultValue;

        // Class theme attributes cannot use nil because it's a dictionary.
        // So transform CPNull into nil.
        if (value === [CPNull null])
            value = nil;
    }

    _cache[aState] = value;

    return value;
}

- (void)setParentAttribute:(_CPThemeAttribute)anAttribute
{
    if (_themeDefaultAttribute === anAttribute)
        return;

    _cache = { };
    _themeDefaultAttribute = anAttribute;
}

- (_CPThemeAttribute)attributeMergedWithAttribute:(_CPThemeAttribute)anAttribute
{
    var mergedAttribute = [[_CPThemeAttribute alloc] initWithName:_name defaultValue:_defaultValue];

    mergedAttribute._values = [_values copy];
    [mergedAttribute._values addEntriesFromDictionary:anAttribute._values];

    return mergedAttribute;
}

@end

@implementation _CPThemeAttribute (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _cache = {};

        _name = [aCoder decodeObjectForKey:@"name"];
        _defaultValue = [aCoder decodeObjectForKey:@"defaultValue"];
        _values = @{};

        if ([aCoder containsValueForKey:@"value"])
        {
            var state = CPThemeStateNormal;

            if ([aCoder containsValueForKey:@"state"])
                state = CPThemeState([aCoder decodeObjectForKey:@"state"]);

            [_values setObject:[aCoder decodeObjectForKey:"value"] forKey:state];
        }
        else
        {
            var encodedValues = [aCoder decodeObjectForKey:@"values"],
                keys = [encodedValues allKeys],
                count = keys.length;

            while (count--)
            {
                var key = keys[count];

                [_values setObject:[encodedValues objectForKey:key] forKey:CPThemeState(key)];
            }
        }
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_defaultValue forKey:@"defaultValue"];

    var keys = [_values allKeys],
        count = keys.length;

    if (count === 1)
    {
        var onlyKey = keys[0];

        if (Number(onlyKey) !== CPThemeStateNormal)
            [aCoder encodeObject:CPThemeStateName(Number(onlyKey)) forKey:@"state"];

        [aCoder encodeObject:[_values objectForKey:onlyKey] forKey:@"value"];
    }
    else
    {
        var encodedValues = @{};

        while (count--)
        {
            var key = keys[count];

            [encodedValues setObject:[_values objectForKey:key] forKey:CPThemeStateName(Number(key))];
        }

        [aCoder encodeObject:encodedValues forKey:@"values"];
    }
}

@end

var cachedNumberOfOnes = [  0 /*000000*/, 1 /*000001*/, 1 /*000010*/, 2 /*000011*/, 1 /*000100*/, 2 /*000101*/, 2 /*000110*/,
                            3 /*000111*/, 1 /*001000*/, 2 /*001001*/, 2 /*001010*/, 3 /*001011*/, 2 /*001100*/, 3 /*001101*/,
                            3 /*001110*/, 4 /*001111*/, 1 /*010000*/, 2 /*010001*/, 2 /*010010*/, 3 /*010011*/, 2 /*010100*/,
                            3 /*010101*/, 3 /*010110*/, 4 /*010111*/, 2 /*011000*/, 3 /*011001*/, 3 /*011010*/, 4 /*011011*/,
                            3 /*011100*/, 4 /*011101*/, 4 /*011110*/, 5 /*011111*/, 1 /*100000*/, 2 /*100001*/, 2 /*100010*/,
                            3 /*100011*/, 2 /*100100*/, 3 /*100101*/, 3 /*100110*/, 4 /*100111*/, 2 /*101000*/, 3 /*101001*/,
                            3 /*101010*/, 4 /*101011*/, 3 /*101100*/, 4 /*101101*/, 4 /*101110*/, 5 /*101111*/, 2 /*110000*/,
                            3 /*110001*/, 3 /*110010*/, 4 /*110011*/, 3 /*110100*/, 4 /*110101*/, 4 /*110110*/, 5 /*110111*/,
                            3 /*111000*/, 4 /*111001*/, 4 /*111010*/, 5 /*111011*/, 4 /*111100*/, 5 /*111101*/, 5 /*111110*/,
                            6 /*111111*/ ];

var numberOfOnes = function(aNumber)
{
    var count = 0,
        slot = aNumber;

    while (aNumber)
    {
        ++count;
        aNumber &= (aNumber - 1);
    }

    cachedNumberOfOnes[slot] = count;

    return count;
};

numberOfOnes.displayName = "numberOfOnes";

function CPThemeAttributeEncode(aCoder, aThemeAttribute)
{
    var values = aThemeAttribute._values,
        count = [values count],
        key = "$a" + [aThemeAttribute name];

    if (count === 1)
    {
        var state = [values allKeys][0];

        if (Number(state) === 0)
        {
            [aCoder encodeObject:[values objectForKey:state] forKey:key];

            return YES;
        }
    }

    if (count >= 1)
    {
        [aCoder encodeObject:aThemeAttribute forKey:key];

        return YES;
    }

    return NO;
}

function CPThemeAttributeDecode(aCoder, anAttributeName, aDefaultValue, aTheme, aClass)
{
    var key = "$a" + anAttributeName;

    if (![aCoder containsValueForKey:key])
        var attribute = [[_CPThemeAttribute alloc] initWithName:anAttributeName defaultValue:aDefaultValue];

    else
    {
        var attribute = [aCoder decodeObjectForKey:key];

        if (!attribute.isa || ![attribute isKindOfClass:[_CPThemeAttribute class]])
        {
            var themeAttribute = [[_CPThemeAttribute alloc] initWithName:anAttributeName defaultValue:aDefaultValue];

            [themeAttribute setValue:attribute];

            attribute = themeAttribute;
        }
    }

    if (aTheme && aClass)
        [attribute setParentAttribute:[aTheme attributeWithName:anAttributeName forClass:aClass]];

    return attribute;
}

/* TO AUTO CREATE THESE:
function bit_count(bits)
    {
        var count = 0;

        while (bits)
        {
            ++count;
            bits &= (bits - 1);
        }

        return count ;
    }

zeros = "000000000";

function pad(string, digits)
{
    return zeros.substr(0, digits - string.length) + string;
}

var str = ""
str += '[';
for (i = 0;i < Math.pow(2,6);++i)
{
    str += bit_count(i) + " /*" + pad(i.toString(2),6) + "*" + "/, ";
}
print(str+']');

*/
