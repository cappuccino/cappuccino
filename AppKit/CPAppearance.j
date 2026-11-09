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
- (void)setEffectiveAppearance:(CPAppearance)appearance;

@end

CPThemeStateAppearanceAqua             = CPThemeState("appearance-aqua");
CPThemeStateAppearanceLightContent     = CPThemeState("appearance-light-content");
CPThemeStateAppearanceVibrantLight     = CPThemeState("appearance-vibrant-light");
CPThemeStateAppearanceVibrantDark      = CPThemeState("appearance-vibrant-dark");


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

/*! Returns the current default CPAppearance
*/
+ (CPAppearance)currentAppearance
{
    if (!_CPAppearanceCurrent)
        _CPAppearanceCurrent = [CPAppearance appearanceNamed:CPAppearanceNameAqua];

    return _CPAppearanceCurrent;
}

/*! Sets the current default CPAppearance
    @param appearance the new current appearance
*/
+ (void)setCurrentAppearance:(CPAppearance)anAppearance
{
    _CPAppearanceCurrent = anAppearance;
}

/*!
    Returns the appearance used to resolve colours and images while drawing. It is the
    current appearance: Aqua, unless +setCurrentAppearance: or
    -performAsCurrentDrawingAppearance: has set another.
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
    var previousAppearance = _CPAppearanceCurrent;

    _CPAppearanceCurrent = self;

    try
    {
        aBlock();
    }
    finally
    {
        _CPAppearanceCurrent = previousAppearance;
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

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        _name           = [aCoder decodeObjectForKey:@"_name"];
        _allowsVibrancy = [aCoder decodeBoolForKey:@"_allowsVibrancy"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_name forKey:@"_name"];
    [aCoder encodeBool:_allowsVibrancy forKey:@"_allowsVibrancy"];
}

@end
