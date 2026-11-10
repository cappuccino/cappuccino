/*
 * CPAppearance.j
 * AppKit
 *
 * Created by Antoine Mercadal.
 * Copyright 2015, Cappuccino Project.
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
@import "_CPAppearanceManager.j"

@global CPApp

/*
    Each name has AppKit's string with the CP prefix in place of NS, so that nib2cib maps an
    archived NSAppearance name by replacing the prefix. AppKit's high-contrast strings omit
    "HighContrast": NSAppearanceNameAccessibilityHighContrastAqua is "NSAppearanceNameAccessibilityAqua".
*/
CPAppearanceNameAqua                                    = @"CPAppearanceNameAqua";
CPAppearanceNameDarkAqua                                = @"CPAppearanceNameDarkAqua";
CPAppearanceNameLightContent                            = @"CPAppearanceNameLightContent";
CPAppearanceNameVibrantDark                             = @"CPAppearanceNameVibrantDark";
CPAppearanceNameVibrantLight                            = @"CPAppearanceNameVibrantLight";
CPAppearanceNameAccessibilityHighContrastAqua           = @"CPAppearanceNameAccessibilityAqua";
CPAppearanceNameAccessibilityHighContrastDarkAqua       = @"CPAppearanceNameAccessibilityDarkAqua";
CPAppearanceNameAccessibilityHighContrastVibrantLight   = @"CPAppearanceNameAccessibilityVibrantLight";
CPAppearanceNameAccessibilityHighContrastVibrantDark    = @"CPAppearanceNameAccessibilityVibrantDark";

var _CPAppearanceCurrent = nil,
    _CPAppearancesRegistry = @{};

/*
    Returns the names an appearance matches, closest first, for
    -bestMatchFromAppearancesWithNames:. As in AppKit:
    - a match keeps lightness, so a light appearance matches no dark name, and the reverse;
    - a vibrant appearance falls back to the plain appearance of the same lightness, and a
      plain appearance matches no vibrant name;
    - light content falls back to Aqua;
    - any other name matches only itself.
    A high-contrast vibrant appearance gives up vibrancy before high contrast. Every
    high-contrast appearance then falls back to normal contrast. An appearance of normal
    contrast matches no high-contrast name.
*/
function _CPAppearanceMatchingNames(aName)
{
    switch (aName)
    {
        case CPAppearanceNameVibrantLight:
            return [CPAppearanceNameVibrantLight, CPAppearanceNameAqua];

        case CPAppearanceNameVibrantDark:
            return [CPAppearanceNameVibrantDark, CPAppearanceNameDarkAqua];

        case CPAppearanceNameAccessibilityHighContrastAqua:
            return [CPAppearanceNameAccessibilityHighContrastAqua, CPAppearanceNameAqua];

        case CPAppearanceNameAccessibilityHighContrastDarkAqua:
            return [CPAppearanceNameAccessibilityHighContrastDarkAqua, CPAppearanceNameDarkAqua];

        case CPAppearanceNameAccessibilityHighContrastVibrantLight:
            return [CPAppearanceNameAccessibilityHighContrastVibrantLight, CPAppearanceNameAccessibilityHighContrastAqua,
                    CPAppearanceNameVibrantLight, CPAppearanceNameAqua];

        case CPAppearanceNameAccessibilityHighContrastVibrantDark:
            return [CPAppearanceNameAccessibilityHighContrastVibrantDark, CPAppearanceNameAccessibilityHighContrastDarkAqua,
                    CPAppearanceNameVibrantDark, CPAppearanceNameDarkAqua];

        case CPAppearanceNameLightContent:
            return [CPAppearanceNameLightContent, CPAppearanceNameAqua];

        default:
            return [aName];
    }
}


@protocol CPAppearanceCustomization <CPObject>

@required
- (CPAppearance)appearance;
- (void)setAppearance:(CPAppearance)appearance;
- (CPAppearance)effectiveAppearance;

@optional
/*
    Deprecated: the effective appearance derives from the chain of view, superviews, window,
    application and system, so no class implements a setter for it.
*/
- (void)setEffectiveAppearance:(CPAppearance)appearance;

@end

CPThemeStateAppearanceAqua             = CPThemeState("appearance-aqua");
CPThemeStateAppearanceLightContent     = CPThemeState("appearance-light-content");
CPThemeStateAppearanceVibrantLight     = CPThemeState("appearance-vibrant-light");
CPThemeStateAppearanceVibrantDark      = CPThemeState("appearance-vibrant-dark");

/*
    Each of the nine appearances has a theme state. A view holds the state of its effective
    appearance (see -[CPView _applyEffectiveAppearance:]). The states also key the value that
    a theme gives a named colour or image for an appearance (see CPColor.j and CPImage.j).
*/
CPThemeStateAppearanceDarkAqua                              = CPThemeState("appearance-dark-aqua");
CPThemeStateAppearanceAccessibilityHighContrastAqua         = CPThemeState("appearance-accessibility-high-contrast-aqua");
CPThemeStateAppearanceAccessibilityHighContrastDarkAqua     = CPThemeState("appearance-accessibility-high-contrast-dark-aqua");
CPThemeStateAppearanceAccessibilityHighContrastVibrantLight = CPThemeState("appearance-accessibility-high-contrast-vibrant-light");
CPThemeStateAppearanceAccessibilityHighContrastVibrantDark  = CPThemeState("appearance-accessibility-high-contrast-vibrant-dark");

/*
    Returns the theme state that keys a theme's values for the appearance named aName, or
    nil for a name without one.
*/
function _CPThemeStateForAppearanceName(aName)
{
    switch (aName)
    {
        case CPAppearanceNameAqua:
            return CPThemeStateAppearanceAqua;

        case CPAppearanceNameDarkAqua:
            return CPThemeStateAppearanceDarkAqua;

        case CPAppearanceNameLightContent:
            return CPThemeStateAppearanceLightContent;

        case CPAppearanceNameVibrantLight:
            return CPThemeStateAppearanceVibrantLight;

        case CPAppearanceNameVibrantDark:
            return CPThemeStateAppearanceVibrantDark;

        case CPAppearanceNameAccessibilityHighContrastAqua:
            return CPThemeStateAppearanceAccessibilityHighContrastAqua;

        case CPAppearanceNameAccessibilityHighContrastDarkAqua:
            return CPThemeStateAppearanceAccessibilityHighContrastDarkAqua;

        case CPAppearanceNameAccessibilityHighContrastVibrantLight:
            return CPThemeStateAppearanceAccessibilityHighContrastVibrantLight;

        case CPAppearanceNameAccessibilityHighContrastVibrantDark:
            return CPThemeStateAppearanceAccessibilityHighContrastVibrantDark;

        default:
            return nil;
    }
}

/*
    The names of the nine appearances that have a theme state.
*/
var _CPAppearanceNamesWithState = [
        CPAppearanceNameAqua,
        CPAppearanceNameDarkAqua,
        CPAppearanceNameLightContent,
        CPAppearanceNameVibrantLight,
        CPAppearanceNameVibrantDark,
        CPAppearanceNameAccessibilityHighContrastAqua,
        CPAppearanceNameAccessibilityHighContrastDarkAqua,
        CPAppearanceNameAccessibilityHighContrastVibrantLight,
        CPAppearanceNameAccessibilityHighContrastVibrantDark
    ];

/*
    The composite of the nine appearance states. A view unsets it, apart from its own state,
    when it applies an appearance, and the archive of a theme state leaves it out.
*/
_CPThemeStateAppearanceAll = CPThemeState.apply(nil, _CPAppearanceNamesWithState.map(_CPThemeStateForAppearanceName));

/*
    Gives CPTheme the fallback order of each appearance state, so that a theme attribute value
    keyed by one appearance serves the appearances that fall back to it, in the order of
    -bestMatchFromAppearancesWithNames: (see -[_CPThemeAttribute valueForState:]).
*/
function _CPAppearanceRegisterThemeStateFallbacks()
{
    var fallbacks = {};

    for (var i = 0, count = _CPAppearanceNamesWithState.length; i < count; i++)
    {
        var name = _CPAppearanceNamesWithState[i],
            matchingNames = _CPAppearanceMatchingNames(name),
            states = [];

        for (var j = 1, matchCount = matchingNames.length; j < matchCount; j++)
            states.push(_CPThemeStateForAppearanceName(matchingNames[j]));

        fallbacks[String(_CPThemeStateForAppearanceName(name))] = states;
    }

    _CPThemeRegisterAppearanceStateFallbacks(fallbacks);
}

_CPAppearanceRegisterThemeStateFallbacks();

/*
    Returns the application's effective appearance, or the system appearance before the
    application exists. This is the end of every appearance chain, and the current drawing
    appearance outside layout and drawing.
*/
function _CPAppearanceForApplication()
{
    if (typeof CPApp !== "undefined" && CPApp)
        return [CPApp effectiveAppearance];

    return [[_CPAppearanceManager sharedManager] systemAppearance];
}

/*
    Makes anAppearance the current drawing appearance and returns the previous raw value of
    the slot, nil included, for _CPAppearanceEndDrawing(). Calls nest in any order.
*/
function _CPAppearanceBeginDrawing(anAppearance)
{
    var previous = _CPAppearanceCurrent;

    _CPAppearanceCurrent = anAppearance;

    return previous;
}

/*
    Restores the value that _CPAppearanceBeginDrawing() returned.
*/
function _CPAppearanceEndDrawing(aPreviousValue)
{
    _CPAppearanceCurrent = aPreviousValue;
}

/*
    Returns the value that the theme attribute anAttribute holds for anAppearance: the value for
    the closest appearance, in the order of -bestMatchFromAppearancesWithNames:; then the value
    for every appearance; or nil when anAttribute holds neither. System colours and system
    images take their theme values this way.
*/
function _CPThemeAttributeValueForAppearance(anAttribute, anAppearance)
{
    var values = [anAttribute values];

    if (!values)
        return nil;

    var matchingNames = _CPAppearanceMatchingNames([anAppearance name]);

    for (var i = 0, count = matchingNames.length; i < count; i++)
    {
        var state = _CPThemeStateForAppearanceName(matchingNames[i]),
            value = state ? [values objectForKey:String(state)] : nil;

        if (value)
            return value;
    }

    return [values objectForKey:String(CPThemeStateNormal)];
}


/*!
    @ingroup appkit

    A CPAppareance represents the appearance of an to a subset of UI elements.
    This is a very lightweight implementation of the NSAppearance system, but
    We are using it for compliance, and especially for the CPVisualEffectView
*/
@implementation CPAppearance : CPObject
{
    BOOL            _allowsVibrancy     @accessors(property=allowsVibrancy);

    CPString        _name;
}


// MARK: -
// MARK: Class Methods

/*!
    Returns the current appearance, which is the current drawing appearance. AppKit deprecates
    this method in favour of +currentDrawingAppearance and -performAsCurrentDrawingAppearance:.
*/
+ (CPAppearance)currentAppearance
{
    /*
        The slot stays empty for the default. Storing the default here made it permanent:
        the first read stored Aqua, so the default never followed a change of the
        application's or the system's appearance.
    */
    return _CPAppearanceCurrent || _CPAppearanceForApplication();
}

/*!
    Sets the current appearance. \c nil selects the default, the application's effective
    appearance.
    @param anAppearance the new current appearance, or \c nil
*/
+ (void)setCurrentAppearance:(CPAppearance)anAppearance
{
    _CPAppearanceCurrent = anAppearance;
}

/*!
    Returns the appearance used to resolve colours and images while drawing. A view lays out
    and draws with its effective appearance as the current drawing appearance. Outside layout
    and drawing it is the application's effective appearance, unless +setCurrentAppearance:
    or -performAsCurrentDrawingAppearance: has set another.
*/
+ (CPAppearance)currentDrawingAppearance
{
    return [self currentAppearance];
}

/*! Returns the CPAppearance object with the given name
    @param name the name of the appearance
*/
+ (CPAppearance)appearanceNamed:(CPString)aName
{
    if (![_CPAppearancesRegistry containsKey:aName])
    {
        [_CPAppearancesRegistry setObject:[[CPAppearance alloc] initWithAppearanceNamed:aName bundle:nil]
                                   forKey:aName];
    }

    return [_CPAppearancesRegistry objectForKey:aName];
}


// MARK: -
// MARK: Initialization

/*! Creates a CPAppearance object initialized to the specified appearance file in the specified bundle
    This method does actually nothing special. It just creates a default appearance object
*/
- (id)initWithAppearanceNamed:(CPString)aName bundle:(CPBundle)bundle
{
    if (self = [super init])
    {
        _name = aName;
        _allowsVibrancy = YES;

        if ([_CPAppearancesRegistry containsKey:aName])
            [CPException raise:CPInternalInconsistencyException reason:"Appearance with name '" + aName + "' is already declared."];

        [_CPAppearancesRegistry setObject:self forKey:aName];
    }

    return self;
}


// MARK: -
// MARK: Implementation

- (CPString)name
{
    return _name;
}

/*!
    Returns the name in \c appearances that most closely matches the receiver, or \c nil if
    none matches. A match keeps the receiver's lightness, so a light appearance matches no
    dark name. A vibrant appearance falls back to the plain appearance of the same lightness,
    and a high-contrast appearance to the appearance of normal contrast.
    @param appearances the names of the appearances the caller supports
    @return the closest name, or \c nil
*/
- (CPString)bestMatchFromAppearancesWithNames:(CPArray)appearances
{
    var matchingNames = _CPAppearanceMatchingNames(_name);

    for (var i = 0, count = matchingNames.length; i < count; i++)
    {
        if ([appearances containsObject:matchingNames[i]])
            return matchingNames[i];
    }

    return nil;
}

/*!
    Makes the receiver the current drawing appearance while \c aBlock runs, then restores
    the previous one, also when \c aBlock raises an exception.
    @param aBlock the function to run
*/
- (void)performAsCurrentDrawingAppearance:(Function)aBlock
{
    var previousAppearance = _CPAppearanceBeginDrawing(self);

    try
    {
        aBlock();
    }
    finally
    {
        _CPAppearanceEndDrawing(previousAppearance);
    }
}

- (BOOL)isEqual:(id)anObject
{
    if (![anObject isKindOfClass:CPAppearance])
        return NO;

    return self._name == anObject._name;
}

- (CPString)description
{
    return @"<CPAppearance @" + [self UID] + @" name: " + _name + ">";
}


// MARK: -
// MARK: CPCoding

/*
    A decoded appearance was a second instance beside the shared one of its name. A view
    compared appearances by identity, so a view whose appearance came from an archive or a
    cib never took an appearance state. Decoding now returns the shared instance.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    var name = [aCoder decodeObjectForKey:@"_name"];

    if (!name)
        return nil;

    return [CPAppearance appearanceNamed:name];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_name forKey:@"_name"];
    [aCoder encodeBool:_allowsVibrancy forKey:@"_allowsVibrancy"];
}

@end
