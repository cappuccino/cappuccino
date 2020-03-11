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
@import <Foundation/CPBundle.j>

@class CPView
@class _CPThemeAttribute
@class CPImage
@class CPColor
@class CPApplication

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
        if ([aClass respondsToSelector:@selector(defaultThemeClass)])
        {
            className = [aClass defaultThemeClass];
        }
        else if ([aClass respondsToSelector:@selector(themeClass)])
        {
            CPLog.warn(@"%@ themeClass is deprecated in favor of defaultThemeClass", CPStringFromClass(aClass));
            className = [aClass themeClass];
        }
        else
        {
            return nil;
        }
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
- (id)valueForAttributeWithName:(CPString)aName inState:(ThemeState)aState forClass:(id)aClass
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

    while ((attributeName = [attributeNames nextObject]) != nil)
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

#pragma mark -
#pragma mark CSS Theming

// The code below adds support for CSS theming with 100% compatibility with current theming system.
// The idea is to extend CPColor and CPImage with CSS components and adapt low level UI components to
// support this new kind of CPColor/CPImage. See CPImageView, CPView and _CPImageAndTextView.
//
// To be considered and treated as CSS based, a theme must set to YES the attribute "css-based" for CPView
// in the theDescriptor (default value is NO), like in the example below :
//
// + (CPView)themedView
// {
//     var view = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
//
//     [self registerThemeValues:[[@"css-based", YES]] forView:view];
//
//     return view;
// }
//
// You can use the method -(BOOL)isCSSBased on a theme to determine how to cope with it in your own code.
//
// The method -(void)setCSSResourcesPath is meant to be used only by CPThemeBlend during theme loading in order to
// replace the special path "%%" in CSS components (like in url(%%packed.png) ) with the path to the theme blend resources folder.
//
// DYNAMIC ATTRIBUTES SET:
//
// If the default theme is CSS based and exposes some dynamic attributes (like Aristo3 does for color schema), you can switch "live"
// to another set of values by calling [CPTheme updateDefaultThemeDynamicAttributesSetWithSet:aDynamicSet] where aDynamicSet is a
// dictionary with keys being the names of exposed dynamic attributes (see the themeDescriptor.j of the CSS based theme you use)
// and values, accordingly to the type of the corresponding default values provided by the theme (CPColor, a CSS color string, ...).
// You can provide key-value pairs for a subset of the exposed dynamic attributes. If no key-value pair is specified for a dynamic
// attribute, the theme default value will be used.
//
// To restore default theme values, simply pass nil as dynamic set : [CPTheme updateDefaultThemeDynamicAttributesSetWithSet:nil]
//
// During theme loading, if your application responds to -(CPDictionary)themeDynamicAttributesSet, the returned values set is directly
// applied to the default set. This avoids displaying the theme with its default values and then redisplaying it with your values.
// The -(CPDictionary)themeDynamicAttributesSet must be declared in a CPApplication category (and not in your application delegate) as
// it will be called during application initialisation, before the delegate has been defined.
//
// To use default theme values, simply return nil.
//
//
// TYPICAL USAGE:
//
// One can imagine that a user can choose between some predefined color schemas. You can store this user preference in standard user defaults:
//
//      [[CPUserDefaults standardUserDefaults] setObject:ConstantRepresentingAColorSchema forKey:@"userTheme"];
//      [[CPUserDefaults standardUserDefaults] synchronize];
//
// As you want to use the choosen color schema at run time, you've implemented -(CPDictionary)themeDynamicAttributesSet (see below), so updating
// the UI as soon as the user has made his choice is easy :
//
//      [CPTheme updateDefaultThemeDynamicAttributesSetWithSet:[[CPApplication sharedApplication] themeDynamicAttributesSet]];
//
// If the user chooses the theme default color schema, you can then simply remove the user default:
//
//      [[CPUserDefaults standardUserDefaults] removeObjectForKey:@"userTheme"];
//      [[CPUserDefaults standardUserDefaults] synchronize];
//
// Your CPApplication category could then be something like:
//
//      @implementation CPApplication (themeColorSchema)
//
//      - (CPDictionary)themeDynamicAttributesSet
//      {
//          var userTheme = [[CPUserDefaults standardUserDefaults] objectForKey:@"userTheme"];
//
//          if (!userTheme)

//              // Return nil to have the theme default color schema
//              return nil;
//
//          switch (userTheme)
//          {
//              case ConstantRepresentingAColorSchema:
//                  return @{
//                           @"ExposedDynamicAttribute1":    [CPColor colorWithRed:245.0/255.0 green:164.0/255.0 blue:9.0/255.0 alpha:0.85],
//                           @"ExposedDynamicAttribute2":    [CPColor colorWithRed:245.0/255.0 green:164.0/255.0 blue:9.0/255.0 alpha:0.85],
//                           @"ExposedDynamicAttribute3":    @"rgb(245,164,9)",
//                           @"ExposedDynamicAttribute4":    @"url(./Resources/mypacked.png)"
//                          };
//                  break;
//
//              case AnotherConstantRepresentingAColorSchema:
//                  return @{
//                           @"ExposedDynamicAttribute1":    [CPColor colorWithRed:39.0/255.0 green:216.0/255.0 blue:93.0/255.0 alpha:0.85],
//                           @"ExposedDynamicAttribute3":    @"rgb(39,216,93)"
//                          };
//                  break;
//
//              ...
//          }
//      }
//
//      @end

var _savedThemesByName = { };

@implementation CPTheme (CSSTheming)

- (void)_initializeDynamicAttributesAndResourcesPathWithBundle:(CPBundle)aBundle
{
    // First, save a template of the theme so dynamic attributes and images placeholders are preserved
    _savedThemesByName[_name] = [CPKeyedArchiver archivedDataWithRootObject:self];

    // Then, compute the dynamic attributes set that will be applied to the theme
    // Does the application delegate provide a dynamic attributes set ?
    var dynamicSet = ([[CPApplication sharedApplication] respondsToSelector:@selector(themeDynamicAttributesSet)]) ? [[CPApplication sharedApplication] themeDynamicAttributesSet] : nil;

    // Take the one defined in the theme
    var defaultDynamicSet = [self valueForAttributeWithName:@"dynamic-set" forClass:[CPView class]];

    // Update the default dynamic attributes set with the one provided by the application
    [dynamicSet enumerateKeysAndObjectsUsingBlock:function(aKey, anObject, stop)
     {
         [defaultDynamicSet setObject:anObject forKey:aKey];
     }];

    // Apply the resulting set
    [self applyDynamicSet:defaultDynamicSet];

    // Then fix resources path in CSS directives
    [self setCSSResourcesPath:[aBundle resourcePath]];
}

+ (void)updateDefaultThemeDynamicAttributesSetWithSet:(CPDictionary)dynamicSet
{
    // First, get a copy of the theme template
    var newTheme = [CPKeyedUnarchiver unarchiveObjectWithData:_savedThemesByName[[CPThemeDefaultTheme name]]];

    // Take the dynamic set defined in the theme
    var defaultDynamicSet = [newTheme valueForAttributeWithName:@"dynamic-set" forClass:[CPView class]];

    // Update the default dynamic attributes set with the one provided by the application
    [dynamicSet enumerateKeysAndObjectsUsingBlock:function(aKey, anObject, stop)
     {
         [defaultDynamicSet setObject:anObject forKey:aKey];
     }];

    // Apply the resulting set to the theme
    [newTheme applyDynamicSet:defaultDynamicSet];

    // Then, fix resources path in CSS directives
    [newTheme setCSSResourcesPath:[[[[CPApplication sharedApplication] themeBlend] bundle] resourcePath]];

    // Now apply the new theme variation
    [CPTheme setDefaultTheme:newTheme];

    var windows = [[CPApplication sharedApplication] windows];

    for (var i = 0, count = windows.length; i < count; i++)
    {
        [windows[i] _setThemeIncludingDescendants:newTheme];
    }

    // Update the menu bar
    [CPMenu updateMenuBarAttributesWithTheme:newTheme];
}

- (void)setCSSResourcesPath:(CPString)pathToResources
{
    [_attributes enumerateKeysAndObjectsUsingBlock:function(aKey, anObject, stop)
     {
         [anObject enumerateKeysAndObjectsUsingBlock:function(aKey2, anObject2, stop2)
          {
              // anObject2 is now a _CPThemeAttribute

              [[anObject2 values] enumerateKeysAndObjectsUsingBlock:function(aKey3, anObject3, stop3)
               {
                   if (anObject3.isa && ([anObject3 isKindOfClass:CPImage] || [anObject3 isKindOfClass:CPColor]) && [anObject3 cssDictionary])
                   {
                       // We have a CSS defined image or color
                       [self _fixPathInCSSDictionary:[anObject3 cssDictionary]       withPathToResources:pathToResources];
                       [self _fixPathInCSSDictionary:[anObject3 cssBeforeDictionary] withPathToResources:pathToResources];
                       [self _fixPathInCSSDictionary:[anObject3 cssAfterDictionary]  withPathToResources:pathToResources];
                   }
               }];
          }];
     }];
}

- (void)_fixPathInCSSDictionary:(CPDictionary)aDictionary withPathToResources:(CPString)pathToResources
{
    [aDictionary enumerateKeysAndObjectsUsingBlock:function(aKey, anObject, stop)
     {
         [aDictionary setObject:[anObject stringByReplacingOccurrencesOfString:@"%%" withString:pathToResources] forKey:aKey];
     }];
}

- (void)applyDynamicSet:(CPDictionary)dynamicSet
{
    [_attributes enumerateKeysAndObjectsUsingBlock:function(aKey, anObject, stop)
     {
         [anObject enumerateKeysAndObjectsUsingBlock:function(aKey2, anObject2, stop2)
          {
              var anObject2Values = [anObject2 values];

              [anObject2Values enumerateKeysAndObjectsUsingBlock:function(aKey3, anObject3, stop3)
               {
                   if (anObject3.isa)
                   {
                       if (([anObject3 isKindOfClass:CPImage] || [anObject3 isKindOfClass:CPColor]) && [anObject3 cssDictionary])
                       {
                           // We have a CSS defined image or color
                           [self _applyDynamicSet:dynamicSet toCSSDictionary:[anObject3 cssDictionary]];
                           [self _applyDynamicSet:dynamicSet toCSSDictionary:[anObject3 cssBeforeDictionary]];
                           [self _applyDynamicSet:dynamicSet toCSSDictionary:[anObject3 cssAfterDictionary]];
                       }
                       else if ([anObject3 isKindOfClass:CPString])
                       {
                           // We have a direct string value
                           if ([dynamicSet containsKey:anObject3])
                               [anObject2Values setObject:[dynamicSet objectForKey:anObject3] forKey:aKey3];
                       }
                   }
               }];
          }];
     }];
}

- (void)_applyDynamicSet:(CPDictionary)dynamicSet toCSSDictionary:(CPDictionary)aDictionary
{
    [aDictionary enumerateKeysAndObjectsUsingBlock:function(aKey, anObject, stop)
     {
         if ([dynamicSet containsKey:anObject])
             [aDictionary setObject:[dynamicSet objectForKey:anObject] forKey:aKey];
     }];
}

- (BOOL)isCSSBased
{
    return !![self valueForAttributeWithName:@"css-based" forClass:[CPView class]];
}

@end

#pragma mark -

/*!
 * ThemeStates are immutable objects representing a particular ThemeState.  Applications should never be creating
 * ThemeStates directly but should instead use the CPThemeState function.
 */
function ThemeState(stateNames)
{
    var stateNameKeys = [];
    this._stateNames = {};

    for (var key in stateNames)
    {
        if (!stateNames.hasOwnProperty(key))
            continue;

        if (key !== 'normal')
        {
            this._stateNames[key] = true;
            stateNameKeys.push(key);
        }
    }

    if (stateNameKeys.length === 0)
    {
        stateNameKeys.push('normal');
        this._stateNames['normal'] = true;
    }

    stateNameKeys.sort();
    this._stateNameString = stateNameKeys[0];

    var stateNameLength = stateNameKeys.length;

    for (var stateIndex = 1; stateIndex < stateNameLength; stateIndex++)
        this._stateNameString = this._stateNameString + "+" + stateNameKeys[stateIndex];

    this._stateNameCount = stateNameLength;
}

ThemeState.prototype.toString = function()
{
    return this._stateNameString;
}

ThemeState.prototype.hasThemeState = function(aState)
{
    if (!aState || !aState._stateNames)
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

ThemeState.prototype.isSubsetOf = function(aState)
{
    if (aState._stateNameCount < this._stateNameCount)
        return false;

    for (var key in this._stateNames)
    {
        if (!this._stateNames.hasOwnProperty(key))
            continue;

        if (!aState._stateNames[key])
            return false;
    }
    return true;
}

ThemeState.prototype.without = function(aState)
{
    if (!aState || aState === [CPNull null])
        return this;

    var firstTransform = CPThemeWithoutTransform[this._stateNameString],
        result;

    if (firstTransform)
    {
        result = firstTransform[aState._stateNameString];

        if (result)
            return result;
    }

    var newStates = {};

    for (var stateName in this._stateNames)
    {
        if (!this._stateNames.hasOwnProperty(stateName))
            continue;

        if (!aState._stateNames[stateName])
            newStates[stateName] = true;
    }

    result = ThemeState._cacheThemeState(new ThemeState(newStates));

    if (!firstTransform)
        firstTransform = CPThemeWithoutTransform[this._stateNameString] = {};

    firstTransform[aState._stateNameString] = result;

    return result;
}

ThemeState.prototype.and  = function(aState)
{
    var firstTransform = CPThemeAndTransform[this._stateNameString],
        result;

    if (firstTransform)
    {
        result = firstTransform[aState._stateNameString];

        if (result)
            return result;
    }

    result = CPThemeState(this, aState);

    if (!firstTransform)
        firstTransform = CPThemeAndTransform[this._stateNameString] = {};

    firstTransform[aState._stateNameString] = result;

    return result;
}

var CPThemeStates = {},
    CPThemeWithoutTransform = {},
    CPThemeAndTransform = {};

ThemeState._cacheThemeState = function(aState)
{
    // We do this caching so themeState equality works.  Basically, doing CPThemeState('foo+bar') === CPThemeState('bar', 'foo') will return true.
    var themeState = CPThemeStates[String(aState)];

    if (themeState === undefined)
    {
        themeState = aState;
        CPThemeStates[String(themeState)] = themeState;
    }

    return themeState;
}

/*!
 * This method can be called in multiple ways:
 *    CPThemeState('state1') - creates a new CPThemeState that corresponds to the string 'state1'
 *    CPThemeState('state1', 'state2') - creates a new composite CPThemeState made up of both 'state1' or 'state2'
 *    CPThemeState('state1+state2') - The same as CPThemeState('state1', 'state2')
 *    CPThemeState(state1, state2) - creates a new composite CPThemeState made up of state1 and state2
 *                                   where state1 and state2 are not strings but are themselves CPThemeStates.
 */
function CPThemeState()
{
    if (arguments.length < 1)
        throw "CPThemeState() must be called with at least one string argument";

    var themeState;

    if (arguments.length === 1 && typeof arguments[0] === 'string')
    {
        themeState = CPThemeStates[arguments[0]];

        if (themeState !== undefined)
            return themeState;
    }

    var stateNames = {};

    for (var argIndex = 0; argIndex < arguments.length; argIndex++)
    {
        if (arguments[argIndex] === [CPNull null] || !arguments[argIndex])
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

    themeState = ThemeState._cacheThemeState(new ThemeState(stateNames));
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

CPThemeStateNormal              = CPThemeState("normal");
CPThemeStateDisabled            = CPThemeState("disabled");
CPThemeStateHovered             = CPThemeState("hovered");
CPThemeStateHighlighted         = CPThemeState("highlighted");
CPThemeStateSelected            = CPThemeState("selected");
CPThemeStateTableDataView       = CPThemeState("tableDataView");
CPThemeStateSelectedDataView    = CPThemeState("selectedTableDataView");
CPThemeStateGroupRow            = CPThemeState("CPThemeStateGroupRow");
CPThemeStateBezeled             = CPThemeState("bezeled");
CPThemeStateBordered            = CPThemeState("bordered");
CPThemeStateEditable            = CPThemeState("editable");
CPThemeStateEditing             = CPThemeState("editing");
CPThemeStateVertical            = CPThemeState("vertical");
CPThemeStateDefault             = CPThemeState("default");
CPThemeStateCircular            = CPThemeState("circular");
CPThemeStateAutocompleting      = CPThemeState("autocompleting");
CPThemeStateFirstResponder      = CPThemeState("firstResponder");
CPThemeStateMainWindow          = CPThemeState("mainWindow");
CPThemeStateKeyWindow           = CPThemeState("keyWindow");
CPThemeStateControlSizeRegular  = CPThemeState("controlSizeRegular");
CPThemeStateControlSizeSmall    = CPThemeState("controlSizeSmall");
CPThemeStateControlSizeMini     = CPThemeState("controlSizeMini");

CPThemeStateNormalString        = String(CPThemeStateNormal);


@implementation _CPThemeAttribute : CPObject
{
    CPString            _name;
    id                  _defaultValue;
    CPDictionary        _values @accessors(readonly, getter=values);

    JSObject            _cache;
    _CPThemeAttribute   _themeDefaultAttribute;
}

- (id)initWithName:(CPString)aName defaultValue:(id)aDefaultValue defaultAttribute:(_CPThemeAttribute)aDefaultAttribute
{
    self = [super init];

    if (self)
    {
        _cache = { };
        _name = aName;
        _defaultValue = aDefaultValue;

        if (aDefaultAttribute)
            _themeDefaultAttribute = aDefaultAttribute;
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

- (_CPThemeAttribute)attributeBySettingValue:(id)aValue
{
    return [self attributeBySettingValue:aValue forState:CPThemeStateNormal];
}

- (_CPThemeAttribute)attributeBySettingValue:(id)aValue forState:(ThemeState)aState
{
    var shouldRemoveValue = aValue == nil,
        attribute = [[_CPThemeAttribute alloc] initWithName:_name defaultValue:_defaultValue defaultAttribute:_themeDefaultAttribute],
        values = _values;

    if (values != null)
    {
        values = [values copy];

        if (shouldRemoveValue)
            [values removeObjectForKey:String(aState)];
        else
            [values setObject:aValue forKey:String(aState)];

        attribute._values = values;
    }
    else if (!shouldRemoveValue)
    {
        values = [[CPDictionary alloc] init];
        [values setObject:aValue forKey:String(aState)];
        attribute._values = values;
    }

    return attribute;
}

- (id)value
{
    return [self valueForState:CPThemeStateNormal];
}

- (id)valueForState:(ThemeState)aState
{
    // First, search in cache.
    var stateName = String(aState),
        value = _cache[stateName];

    // This can be nil.
    if (value !== undefined)
        return value;

    // Not in cache. OK, search in values.
    value = [_values objectForKey:stateName];

    if (value != nil)
        return _cache[stateName] = value;

    // No direct match in values.
    // If this is a composite state, find the closest partial subset match.
    if (aState._stateNameCount > 1)
    {
        var largestThemeState = [self largestThemeStateMatchForState:aState returnedValue:@ref(value)];

        if ((value !== undefined) && (value !== nil))
            return _cache[stateName] = value;
    }

    // Still don't have a value? OK, let's use the normal value.
    value = [_values objectForKey:String(CPThemeStateNormal)];

    if (value != nil)
        return _cache[stateName] = value;

    // No normal value, try asking _themeDefaultAttribute
    value = [_themeDefaultAttribute valueForState:aState];

    if (value != nil)
        return _cache[stateName] = value;

    // Well, last option, use default value
    value = _defaultValue;

    // Class theme attributes cannot use nil because it's a dictionary.
    // So transform CPNull into nil.
    if (value === [CPNull null])
        value = nil;

    return _cache[stateName] = value;
}

- (CPInteger)largestThemeStateMatchForState:(ThemeState)aState returnedValue:(id)valueRef
{
    var stateName = String(aState),
        value,
        states = [_values allKeys],
        count = states ? states.length : 0,
        largestThemeState = 0;

    while (count--)
    {
        var stateObject = CPThemeState(states[count]);

        if (stateObject.isSubsetOf(aState) && stateObject._stateNameCount > largestThemeState)
        {
            value = [_values objectForKey:states[count]];
            largestThemeState = stateObject._stateNameCount;
        }
    }

    // _themeDefaultAttribute may have a larger theme state match. If so, we have to take it. If not, we take our closest match.
    var defaultAttributeFoundValue,
        defaultAttributeMatchLength = [_themeDefaultAttribute largestThemeStateMatchForState:aState returnedValue:@ref(defaultAttributeFoundValue)];

    if (defaultAttributeMatchLength > largestThemeState)
    {
        value = defaultAttributeFoundValue;
        largestThemeState = defaultAttributeMatchLength;
    }

    @deref(valueRef) = value;
    return largestThemeState;
}

- (_CPThemeAttribute)attributeBySettingParentAttribute:(_CPThemeAttribute)anAttribute
{
    if (_themeDefaultAttribute === anAttribute)
        return self;

    var attribute = [[_CPThemeAttribute alloc] initWithName:_name defaultValue:_defaultValue defaultAttribute:anAttribute];

    attribute._values = [_values copy];

    return attribute;
}

- (_CPThemeAttribute)attributeMergedWithAttribute:(_CPThemeAttribute)anAttribute
{
    var mergedAttribute = [[_CPThemeAttribute alloc] initWithName:_name defaultValue:_defaultValue defaultAttribute:_themeDefaultAttribute];

    mergedAttribute._values = [_values copy];

    if (anAttribute._values)
        mergedAttribute._values ? [mergedAttribute._values addEntriesFromDictionary:anAttribute._values] : [anAttribute._values copy];

    return mergedAttribute;
}

- (CPString)description
{
    return [super description] + @" Name: " + _name + @", defaultAttribute: " + _themeDefaultAttribute + @", defaultValue: " + _defaultValue + @", values: " + _values;
}

@end


// This is used to pass 'parrentAttribute' to the coder
var ParentAttributeForCoder = nil;

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
        _themeDefaultAttribute = ParentAttributeForCoder;

        if ([aCoder containsValueForKey:@"value"])
        {
            var state;

            if ([aCoder containsValueForKey:@"state"])
                state = [aCoder decodeObjectForKey:@"state"];
            else
                state = CPThemeStateNormalString;

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

                [_values setObject:[encodedValues objectForKey:key] forKey:key];
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
        count = keys ? keys.length : 0;

    if (count === 1)
    {
        var onlyKey = keys[0];

        if (onlyKey !== String(CPThemeStateNormal))
            [aCoder encodeObject:onlyKey forKey:@"state"];

        [aCoder encodeObject:[_values objectForKey:onlyKey] forKey:@"value"];
    }
    else
    {
        var encodedValues = @{};

        while (count--)
        {
            var key = keys[count];

            [encodedValues setObject:[_values objectForKey:key] forKey:key];
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

        if (state === CPThemeStateNormalString)
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

function CPThemeAttributeDecode(aCoder, attribute)
{
    var key = "$a" + attribute._name;

    if ([aCoder containsValueForKey:key])
    {
        ParentAttributeForCoder = attribute._themeDefaultAttribute;

        var decodedAttribute = [aCoder decodeObjectForKey:key];

        ParentAttributeForCoder = nil;

        if (!decodedAttribute || !decodedAttribute.isa || ![decodedAttribute isKindOfClass:[_CPThemeAttribute class]])
            attribute = [attribute attributeBySettingValue:decodedAttribute];
        else
            attribute = decodedAttribute;
    }

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
