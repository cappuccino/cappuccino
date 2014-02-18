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

function ThemeState(stateNames)
{
    this._stateNames = stateNames;

    var stateNameKeys = [];
    for (key in stateNames)
    {
        if (!stateNames.hasOwnProperty(key))
            continue;
        stateNameKeys.push(key);
    }
    stateNameKeys.sort();
    this._stateNameString = stateNameKeys[0];
    if (this._stateNameString === undefined)
        this._stateNameString = "";

    var stateNameLength = stateNameKeys.length;
    for (var stateIndex = 1; stateIndex < stateNameLength; stateIndex++)
        this._stateNameString = this._stateNameString + "+" + stateNameKeys[stateIndex];
}

ThemeState.prototype.toString = function()
{
    return this._stateNameString;
}

ThemeState.prototype.hasThemeState = function(aState)
{
    if (aState === undefined || aState === nil || aState._stateNames === undefined)
        return false;
    // We can do this in O(n) because both states have their stateNames already sorted.
    for (var stateName in aState._stateNames)
    {
        if (!aState._stateNames.hasOwnProperty(stateName))
            continue;
        if (!this._stateNames[stateName])
            return false;
    }
    return true;
}

var CPThemeStates = {};

/*
 * This method can be called in multiple ways:
 *    CPThemeState('state1') - creates a new CPThemeState that corresponds to the string 'state1'
 *    CPThemeState('state1', 'state2') - creates a new CPThemeState made up of both 'state1' or 'state2'
 *    CPThemeState('state1+state2') - The same as CPThemeState('state1', 'state2')
 *    CPThemeState(state1, state2) - creates a new CPThemeState that corresponds to both state1 or state2
 *                                   where state1 and state2 are not strings but are themselves CPThemeStates.
 */
function CPThemeState()
{
    if (arguments.length < 1)
        throw "CPThemeState() must be called with at least one string argument";

    var stateNames = {};
    for (var argIndex = 0; argIndex < arguments.length; argIndex++)
    {
        if (arguments[argIndex] === [CPNull null] || arguments[argIndex] === nil || arguments[argIndex] === undefined)
            continue;

        if (typeof arguments[argIndex] === 'object')
        {
            for (var stateName in arguments[argIndex]._stateNames)
            {
                if (!arguments[argIndex]._stateNames.hasOwnProperty(stateName))
                    continue;
                stateNames[stateName] = true;
            }
        }
        else
        {
            var allNames = arguments[argIndex].split('+');
            for (var nameIndex = 0; nameIndex < allNames.length; nameIndex++)
                stateNames[allNames[nameIndex]] = true;
        }
    }

    var themeState = CPThemeState._cacheThemeState(new ThemeState(stateNames));
    return themeState;
}

CPThemeState.subtractThemeStates = function(aState1, aState2)
{
    if (aState2 === undefined || aState2 === nil || aState2 === [CPNull null])
        return aState1;

    var newThemeState = new ThemeState({});
    for (var stateName in aState1._stateNames)
    {
        if (!aState1._stateNames.hasOwnProperty(stateName))
            continue;

        if (!aState2._stateNames[stateName])
            newThemeState[stateName] = true;
    }

    return CPThemeState._cacheThemeState(newThemeState);
}

CPThemeState._cacheThemeState = function(aState)
{
    // We do this caching so themeState equality works.  Basically, doing CPThemeState('foo+bar') === CPThemeState('bar', 'foo') will return true.
    var themeState = CPThemeStates[String(aState)];
    if (themeState === undefined)
    {
        themeState = aState;
        CPThemeState[String(themeState)] = themeState;
    }
    return themeState;
}

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

CPThemeStateNormal           = CPThemeState("normal");
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
    return ([_values count] === 1) && ([_values allKeys][0] === CPThemeStateNormal);
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

    var componentStates = aState._stateNames;
    for (var state in componentStates)
    {
        if (componentStates.hasOwnProperty(state))
        {
            if ((aValue === undefined) || (aValue === nil))
                [_values removeObjectForKey:state];
            else
                [_values setObject:aValue forKey:state];
        }
    }
}

- (id)value
{
    return [self valueForState:CPThemeStateNormal];
}

// If aState is a state comprised of multiple CPThemeStates, this will return the value for the first state it finds.
- (id)valueForState:(CPThemeState)aState
{
    var stateName = String(aState);
    var value = _cache[stateName];

    // This can be nil.
    if (value !== undefined)
        return value;

    value = [_values objectForKey:stateName];

    // If we don't have a value, and we have a non-normal state...
    if ((value === undefined || value === nil) && aState !== CPThemeStateNormal)
    {
        for (var state in aState._stateNames)
        {
            if (!aState._stateNames.hasOwnProperty(state))
                continue;

            value = [_values objectForKey:state];
            if (value !== undefined && value !== nil)
                break;
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

    _cache[stateName] = value;

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

        if (onlyKey !== CPThemeStateNormal)
            [aCoder encodeObject:String(onlyKey) forKey:@"state"];

        [aCoder encodeObject:[_values objectForKey:onlyKey] forKey:@"value"];
    }
    else
    {
        var encodedValues = @{};

        while (count--)
        {
            var key = keys[count];

            [encodedValues setObject:[_values objectForKey:key] forKey:String(key)];
        }

        [aCoder encodeObject:encodedValues forKey:@"values"];
    }
}

@end

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
