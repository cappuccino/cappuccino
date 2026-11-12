/*
 * CPColor.j
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
@import "CPGraphicsContext.j"

@import "CGColor.j"

@import "_CPObject+Theme.j"
@import "CPAppearance.j"
@import "CPCompatibility.j"
@import "CPImage.j"
@import "_CPAssetCatalog.j"

@global _CPRaiseInvalidAbstractInvocation


/*!
    Orientation to use with \c CPColorPattern for vertical patterns.
*/
CPColorPatternIsVertical = YES;

/*!
    Orientation to use with \c CPColorPattern for horizontal patterns.
*/
CPColorPatternIsHorizontal = NO;

/// @cond IGNORE

var _redComponent        = 0,
    _greenComponent      = 1,
    _blueComponent       = 2,
    _alphaCompnent       = 3;

var _hueComponent        = 0,
    _saturationComponent = 1,
    _brightnessComponent = 2;

var cachedBlackColor,
    cachedRedColor,
    cachedGreenColor,
    cachedBlueColor,
    cachedYellowColor,
    cachedGrayColor,
    cachedLightGrayColor,
    cachedDarkGrayColor,
    cachedWhiteColor,
    cachedBrownColor,
    cachedCyanColor,
    cachedMagentaColor,
    cachedOrangeColor,
    cachedPurpleColor,
    cachedClearColor,
    cachedThemeColor;

/*
    The catalog that holds the system colours, as in AppKit.
*/
var _CPColorSystemCatalogName = @"System";

/*
    The catalog that holds a theme's own colours: the colours that have no System name. The
    theme gives their values in the attribute "theme-colors" of CPColor (see
    _CPThemeColorValue). The catalog name does not contain a theme's name, so that a theme
    and a bundle that extends it resolve the same colour names.
*/
var _CPColorThemeCatalogName = @"Theme";

/*
    The colours of the System catalog, with each colour's value when the current theme gives
    it none. These are the names that Interface Builder writes into a XIB and that AppKit
    resolves, including older names that it still resolves and one private name. Where
    Cappuccino already produced a value, the entry keeps it: the four colours that CPColor
    and Aristo2 already defined, and the three that nib2cib maps (controlColor,
    controlBackgroundColor, gridColor). Every other entry is AppKit's value for the Aqua
    appearance on macOS 27, in sRGB.
*/
var _CPSystemColorDefaults = {
        "_sourceListBackgroundColor":                   [0.9647, 0.9647, 0.9647, 0.8],
        "alternateSelectedControlColor":                [0.22, 0.46, 0.84, 1.0],
        "alternateSelectedControlTextColor":            [1.0, 1.0, 1.0, 1.0],
        "alternatingContentBackgroundColor":            [0.9569, 0.9608, 0.9608, 1.0],
        "controlAccentColor":                           [0.0, 0.4784, 1.0, 1.0],
        "controlBackgroundColor":                       [1.0, 1.0, 1.0, 1.0],
        "controlColor":                                 [175.0 / 255.0, 175.0 / 255.0, 175.0 / 255.0, 1.0],
        "controlDarkShadowColor":                       [0.0, 0.0, 0.0, 1.0],
        "controlHighlightColor":                        [1.0, 1.0, 1.0, 1.0],
        "controlLightHighlightColor":                   [1.0, 1.0, 1.0, 1.0],
        "controlShadowColor":                           [0.0, 0.0, 0.0, 0.2667],
        "controlTextColor":                             [0.0, 0.0, 0.0, 0.8471],
        "disabledControlTextColor":                     [0.0, 0.0, 0.0, 0.2471],
        "findHighlightColor":                           [1.0, 1.0, 0.0, 1.0],
        "gridColor":                                    [204.0 / 255.0, 204.0 / 255.0, 204.0 / 255.0, 1.0],
        "headerColor":                                  [0.6667, 0.6667, 0.6667, 1.0],
        "headerTextColor":                              [0.0, 0.0, 0.0, 0.8471],
        "highlightColor":                               [1.0, 1.0, 1.0, 1.0],
        "keyboardFocusIndicatorColor":                  [0.0, 0.4039, 0.9569, 0.498],
        "knobColor":                                    [0.6, 0.6, 0.7333, 1.0],
        "labelColor":                                   [0.0, 0.0, 0.0, 0.8471],
        "linkColor":                                    [0.0, 0.4078, 0.8549, 1.0],
        "placeholderTextColor":                         [0.0, 0.0, 0.0, 0.498],
        "quaternaryLabelColor":                         [0.0, 0.0, 0.0, 0.098],
        "quaternarySystemFillColor":                    [0.0, 0.0, 0.0, 0.0275],
        "quinaryLabelColor":                            [0.0, 0.0, 0.0, 0.0471],
        "quinarySystemFillColor":                       [0.0, 0.0, 0.0, 0.0078],
        "scrollBarColor":                               [0.6667, 0.6667, 0.6667, 1.0],
        "secondaryLabelColor":                          [0.0, 0.0, 0.0, 0.498],
        "secondarySelectedControlColor":                [0.83, 0.83, 0.83, 1.0],
        "secondarySystemFillColor":                     [0.0, 0.0, 0.0, 0.0784],
        "selectedContentBackgroundColor":               [0.0, 0.3922, 0.8824, 1.0],
        "selectedControlColor":                         [0.702, 0.702, 0.702, 1.0],
        "selectedControlTextColor":                     [0.0, 0.0, 0.0, 0.8471],
        "selectedKnobColor":                            [0.4, 0.4, 0.6, 1.0],
        "selectedMenuItemColor":                        [0.2588, 0.4667, 0.9569, 1.0],
        "selectedMenuItemTextColor":                    [1.0, 1.0, 1.0, 1.0],
        "selectedTextBackgroundColor":                  [0.6, 0.8, 1.0, 1.0],
        "selectedTextColor":                            [1.0, 1.0, 1.0, 1.0],
        "separatorColor":                               [0.0, 0.0, 0.0, 0.1],
        "shadowColor":                                  [0.0, 0.0, 0.0, 1.0 / 3.0],
        "systemBlueColor":                              [0.0, 0.5333, 1.0, 1.0],
        "systemBrownColor":                             [0.6745, 0.498, 0.3686, 1.0],
        "systemCyanColor":                              [0.0, 0.7529, 0.9098, 1.0],
        "systemFillColor":                              [0.0, 0.0, 0.0, 0.098],
        "systemGrayColor":                              [0.5569, 0.5569, 0.5765, 1.0],
        "systemGreenColor":                             [0.2039, 0.7804, 0.349, 1.0],
        "systemIndigoColor":                            [0.3804, 0.3333, 0.9608, 1.0],
        "systemMintColor":                              [0.0, 0.7843, 0.702, 1.0],
        "systemOrangeColor":                            [1.0, 0.5529, 0.1569, 1.0],
        "systemPinkColor":                              [1.0, 0.1765, 0.3333, 1.0],
        "systemPurpleColor":                            [0.7961, 0.1882, 0.8784, 1.0],
        "systemRedColor":                               [1.0, 0.2196, 0.2353, 1.0],
        "systemTealColor":                              [0.0, 0.7647, 0.8157, 1.0],
        "systemYellowColor":                            [1.0, 0.8, 0.0, 1.0],
        "tertiaryLabelColor":                           [0.0, 0.0, 0.0, 0.2588],
        "tertiarySystemFillColor":                      [0.0, 0.0, 0.0, 0.0471],
        "textBackgroundColor":                          [1.0, 1.0, 1.0, 1.0],
        "textColor":                                    [0.0, 0.0, 0.0, 1.0],
        "textInsertionPointColor":                      [0.0, 0.0, 0.0, 1.0],
        "underPageBackgroundColor":                     [0.9647, 0.9647, 0.9647, 1.0],
        "unemphasizedSelectedContentBackgroundColor":   [0.8627, 0.8627, 0.8627, 1.0],
        "unemphasizedSelectedTextBackgroundColor":      [0.8627, 0.8627, 0.8627, 1.0],
        "unemphasizedSelectedTextColor":                [0.0, 0.0, 0.0, 1.0],
        "windowBackgroundColor":                        [1.0, 1.0, 1.0, 1.0],
        "windowFrameColor":                             [0.6667, 0.6667, 0.6667, 1.0],
        "windowFrameTextColor":                         [0.0, 0.0, 0.0, 0.8471]
    },
    _CPSystemColors = {},
    _CPSystemColorDefaultValues = {},
    _CPThemeColors = {},
    _CPThemeColorMissingNames = {};

/*
    Returns the theme attribute of CPColor that holds a theme's values for the system colour
    aName: the name in lower case with words joined by hyphens, as the attributes that CPColor
    already had (alternateSelectedControlColor is "alternate-selected-control-color"). A
    private name keeps its leading underscore.
*/
function _CPThemeAttributeForSystemColorName(aName)
{
    var isPrivate = aName.charAt(0) === "_",
        baseName = isPrivate ? aName.substring(1) : aName;

    return (isPrivate ? "_" : "") + baseName.replace(/([A-Z])/g, "-$1").toLowerCase();
}

/*
    Returns the value of the system colour aName for anAppearance: the current theme's value for
    anAppearance (see _CPThemeAttributeValueForAppearance), then the value in
    _CPSystemColorDefaults.
*/
function _CPSystemColorValue(aName, anAppearance)
{
    var attribute = [[CPTheme defaultTheme] attributeWithName:_CPThemeAttributeForSystemColorName(aName) forClass:[CPColor defaultThemeClass]],
        themeValue = _CPThemeAttributeValueForAppearance(attribute, anAppearance);

    if (themeValue)
        return themeValue;

    var defaultValue = _CPSystemColorDefaultValues[aName];

    if (!defaultValue)
        defaultValue = _CPSystemColorDefaultValues[aName] = [[CPColor alloc] _initWithRGBA:_CPSystemColorDefaults[aName].slice()];

    return defaultValue;
}

/*
    Returns the value of the theme colour aName for anAppearance. The attribute "theme-colors"
    of the current theme holds, for each appearance state, a dictionary from colour name to
    colour. The lookup takes the dictionaries in the order of -bestMatchFromAppearancesWithNames:
    for anAppearance and uses the first one that holds aName, then the dictionary for every
    appearance. A name that no dictionary holds is a defect of the theme: it logs one warning
    and gives the clear colour.
*/
function _CPThemeColorValue(aName, anAppearance)
{
    var theme = [CPTheme defaultTheme],
        values = [[theme attributeWithName:@"theme-colors" forClass:[CPColor defaultThemeClass]] values];

    if (values)
    {
        var matchingNames = _CPAppearanceMatchingNames([anAppearance name]);

        for (var i = 0, count = matchingNames.length; i < count; i++)
        {
            var state = _CPThemeStateForAppearanceName(matchingNames[i]),
                value = state ? [[values objectForKey:String(state)] objectForKey:aName] : nil;

            if (value)
                return value;
        }

        var normalValue = [[values objectForKey:String(CPThemeStateNormal)] objectForKey:aName];

        if (normalValue)
            return normalValue;
    }

    if (!_CPThemeColorMissingNames.hasOwnProperty(aName))
    {
        _CPThemeColorMissingNames[aName] = YES;
        CPLog.warn("Theme colour: the theme " + [theme name] + " gives no value for \"" + aName + "\"");
    }

    return [CPColor clearColor];
}

/// @endcond

@class _CPCatalogColor

/*!
    @ingroup appkit

    \c CPColor can be used to represent color
    in an RGB or HSB model with an optional transparency value.</p>

    <p>It also provides some class helper methods that
    returns instances of commonly used colors.</p>
*/
@implementation CPColor : CPObject <CPTheme>
{
    CPArray     _components;

    CPImage     _patternImage;
    CPString    _cssString;
}
@global document

// MARK: -
// MARK: Theming

+ (CPString)defaultThemeClass
{
    return "color";
}

/*
    Besides its own attributes, CPColor has one attribute for each system colour, which holds
    the theme's values for that colour (see _CPSystemColorValue), and the attribute
    "theme-colors", which holds the values of the theme's own colours (see
    _CPThemeColorValue).
*/
+ (CPDictionary)themeAttributes
{
    var attributes = @{
            @"alternate-selected-control-color":        [CPNull null],
            @"secondary-selected-control-color":        [CPNull null],
            @"selected-text-background-color":          [CPNull null],
            @"selected-text-inactive-background-color": [CPNull null],
            @"css-based":                               NO,
            @"theme-colors":                            [CPNull null]
        };

    for (var colorName in _CPSystemColorDefaults)
    {
        var attributeName = _CPThemeAttributeForSystemColorName(colorName);

        if (![attributes containsKey:attributeName])
            [attributes setObject:[CPNull null] forKey:attributeName];
    }

    return attributes;
}


// MARK: -
// MARK: Static methods

/*!
    Creates a color in the RGB colorspace, with an alpha value.
    Each component should be between the range of 0.0 to 1.0. For
    the alpha component, a value of 1.0 is opaque, and 0.0 means
    completely transparent.

    @param red the red component of the color
    @param green the green component of the color
    @param blue the blue component of the color
    @param alpha the alpha component

    @return a color initialized to the values specified
*/
+ (CPColor)colorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    return [[CPColor alloc] _initWithRGBA:[MAX(0.0, MIN(1.0, red)), MAX(0.0, MIN(1.0, green)), MAX(0.0, MIN(1.0, blue)), MAX(0.0, MIN(1.0, alpha))]];
}

/*!
    @deprecated in favor of colorWithRed:green:blue:alpha:

    Creates a color in the RGB colorspace, with an alpha value.
    Each component should be between the range of 0.0 to 1.0. For
    the alpha component, a value of 1.0 is opaque, and 0.0 means
    completely transparent.

    @param red the red component of the color
    @param green the green component of the color
    @param blue the blue component of the color
    @param alpha the alpha component

    @return a color initialized to the values specified
*/
+ (CPColor)colorWithCalibratedRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    return [self colorWithRed:red green:green blue:blue alpha:alpha];
}


/*!
    Creates a new color object with \c white for the RGB components.
    For the alpha component, a value of 1.0 is opaque, and 0.0 means completely transparent.

    @param white a float between 0.0 and 1.0
    @param alpha the alpha component between 0.0 and 1.0

    @return a color initialized to the values specified
*/
+ (CPColor)colorWithWhite:(float)white alpha:(float)alpha
{
    return [[CPColor alloc] _initWithRGBA:[white, white, white, alpha]];
}

/*!
    @deprecated in favor of colorWithWhite:alpha:

    Creates a new color object with \c white for the RGB components.
    For the alpha component, a value of 1.0 is opaque, and 0.0 means completely transparent.

    @param white a float between 0.0 and 1.0
    @param alpha the alpha component between 0.0 and 1.0

    @return a color initialized to the values specified
*/
+ (CPColor)colorWithCalibratedWhite:(float)white alpha:(float)alpha
{
    return [self colorWithWhite:white alpha:alpha];
}

/*!
    Creates a new color based on the given HSB components.

    Note: earlier versions of this method took a hue component as degrees between 0-360,
    and saturation and brightness components as percent between 0-100. This method has
    now been corrected to take all components in the 0-1 range as in Cocoa.

    @param hue the hue component (0.0-1.0)
    @param saturation the saturation component (0.0-1.0)
    @param brightness the brightness component (0.0-1.0)

    @return the initialized color
*/
+ (CPColor)colorWithHue:(float)hue saturation:(float)saturation brightness:(float)brightness
{
    return [self colorWithHue:hue saturation:saturation brightness:brightness alpha:1.0];
}

/*!
    Calibrated colors are not supported in Cappuccino.

    This method has the same result as [CPColor colorWithHue:saturation:brightness:alpha:].
*/
+ (CPColor)colorWithCalibratedHue:(float)hue saturation:(float)saturation brightness:(float)brightness alpha:(float)alpha
{
    return [self colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

/*!
    Creates a new color based on the given HSB components.

    Note: earlier versions of this method took a hue component as degrees between 0-360,
    and saturation and brightness components as percent between 0-100. This method has
    now been corrected to take all components in the 0-1 range as in Cocoa.

    @param hue the hue component (0.0-1.0)
    @param saturation the saturation component (0.0-1.0)
    @param brightness the brightness component (0.0-1.0)
    @param alpha the opacity component (0.0-1.0)

    @return the initialized color
*/
+ (CPColor)colorWithHue:(float)hue saturation:(float)saturation brightness:(float)brightness alpha:(float)alpha
{
    // Clamp values.
    hue = MAX(MIN(hue, 1.0), 0.0);
    saturation = MAX(MIN(saturation, 1.0), 0.0);
    brightness = MAX(MIN(brightness, 1.0), 0.0);

    if (saturation === 0.0)
        return [CPColor colorWithCalibratedWhite:brightness alpha:alpha];

    var f = (hue * 360) % 60,
        p = (brightness * (1 - saturation)),
        q = (brightness * (60 - saturation * f)) / 60,
        t = (brightness * (60 - saturation * (60 - f))) / 60,
        b = brightness;

    switch (FLOOR(hue * 6))
    {
        case 0:
        case 6:
            return [CPColor colorWithCalibratedRed:b green:t blue:p alpha:alpha];
        case 1:
            return [CPColor colorWithCalibratedRed:q green:b blue:p alpha:alpha];
        case 2:
            return [CPColor colorWithCalibratedRed:p green:b blue:t alpha:alpha];
        case 3:
            return [CPColor colorWithCalibratedRed:p green:q blue:b alpha:alpha];
        case 4:
            return [CPColor colorWithCalibratedRed:t green:p blue:b alpha:alpha];
        case 5:
            return [CPColor colorWithCalibratedRed:b green:p blue:q alpha:alpha];
    }
}

/*!
    Creates an RGB color from a hexadecimal string. For example,
    the a string of "FFFFFF" would return a white CPColor.
    "FF0000" would return a pure red, "00FF00" would return a
    pure blue, and "0000FF" would return a pure green.

    @param hex a 6 character long string of hex

    @return an initialized RGB color
*/
+ (CPColor)colorWithHexString:(CPString)hex
{
    var rgba = hexToRGB(hex);
    return rgba ? [[CPColor alloc] _initWithRGBA: rgba] : null;
}

/*!
    Creates a color in the sRGB colorspace with the given components and alpha values.
    Values below 0.0 are treated as 0.0 and values above 1.0 are treated as 1.0.
*/
+ (CPColor)colorWithSRGBRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    // TODO If Cappuccino is ported to a colorspace aware platform, this color should be in
    // sRGBColorSpace.
    return [self colorWithRed:red green:green blue:blue alpha:alpha];
}

/*!
    Returns a black color object. (RGBA=[0.0, 0.0, 0.0, 1.0])
*/
+ (CPColor)blackColor
{
    if (!cachedBlackColor)
        cachedBlackColor = [[CPColor alloc] _initWithRGBA:[0.0, 0.0, 0.0, 1.0]];

    return cachedBlackColor;
}

/*!
    Returns a blue color object. (RGBA=[0.0, 0.0, 1.0, 1.0])
*/
+ (CPColor)blueColor
{
    if (!cachedBlueColor)
        cachedBlueColor = [[CPColor alloc] _initWithRGBA:[0.0, 0.0, 1.0, 1.0]];

    return cachedBlueColor;
}

/*!
    Returns a dark gray color object. (RGBA=[0.33 ,0.33, 0.33, 1.0])
*/
+ (CPColor)darkGrayColor
{
    if (!cachedDarkGrayColor)
        cachedDarkGrayColor = [CPColor colorWithCalibratedWhite:1.0 / 3.0 alpha:1.0];

    return cachedDarkGrayColor;
}

/*!
    Returns a gray color object. (RGBA=[0.5, 0.5, 0.5, 1.0])
*/
+ (CPColor)grayColor
{
    if (!cachedGrayColor)
        cachedGrayColor = [CPColor colorWithCalibratedWhite:0.5 alpha: 1.0];

    return cachedGrayColor;
}

/*!
    Returns a green color object. (RGBA=[0.0, 1.0, 0.0, 1.0])
*/
+ (CPColor)greenColor
{
    if (!cachedGreenColor)
        cachedGreenColor = [[CPColor alloc] _initWithRGBA:[0.0, 1.0, 0.0, 1.0]];

    return cachedGreenColor;
}

/*!
    Returns a light gray color object (RGBA=[0.66, 0.66, 0.66, 1.0])
*/
+ (CPColor)lightGrayColor
{
    if (!cachedLightGrayColor)
        cachedLightGrayColor = [CPColor colorWithCalibratedWhite:2.0 / 3.0 alpha:1.0];

    return cachedLightGrayColor;
}

/*!
    Returns a red color object (RGBA=[1.0, 0.0, 0.0, 1.0])
*/
+ (CPColor)redColor
{
    if (!cachedRedColor)
        cachedRedColor = [[CPColor alloc] _initWithRGBA:[1.0, 0.0, 0.0, 1.0]];

    return cachedRedColor;
}

/*!
    Returns a white color object (RGBA=[1.0, 1.0, 1.0, 1.0])
*/
+ (CPColor)whiteColor
{
    if (!cachedWhiteColor)
        cachedWhiteColor = [[CPColor alloc] _initWithRGBA:[1.0, 1.0, 1.0, 1.0]];

    return cachedWhiteColor;
}

/*!
    Returns a yellow color object (RGBA=[1.0, 1.0, 0.0, 1.0])
*/
+ (CPColor)yellowColor
{
    if (!cachedYellowColor)
        cachedYellowColor = [[CPColor alloc] _initWithRGBA:[1.0, 1.0, 0.0, 1.0]];

    return cachedYellowColor;
}

/*!
    Returns a brown color object (RGBA=[0.6, 0.4, 0.2, 1.0])
*/
+ (CPColor)brownColor
{
    if (!cachedBrownColor)
        cachedBrownColor = [[CPColor alloc] _initWithRGBA:[0.6, 0.4, 0.2, 1.0]];

    return cachedBrownColor;
}

/*!
    Returns a cyan color object (RGBA=[0.0, 1.0, 1.0, 1.0])
*/
+ (CPColor)cyanColor
{
    if (!cachedCyanColor)
        cachedCyanColor = [[CPColor alloc] _initWithRGBA:[0.0, 1.0, 1.0, 1.0]];

    return cachedCyanColor;
}

/*!
    Returns a magenta color object (RGBA=[1.0, 0.0, 1.0, 1.0])
*/
+ (CPColor)magentaColor
{
    if (!cachedMagentaColor)
        cachedMagentaColor = [[CPColor alloc] _initWithRGBA:[1.0, 0.0, 1.0, 1.0]];

    return cachedMagentaColor;
}

/*!
    Returns a orange color object (RGBA=[1.0, 0.5, 0.0, 1.0])
*/
+ (CPColor)orangeColor
{
    if (!cachedOrangeColor)
        cachedOrangeColor = [[CPColor alloc] _initWithRGBA:[1.0, 0.5, 0.0, 1.0]];

    return cachedOrangeColor;
}

/*!
    Returns a purple color object (RGBA=[0.5, 0.0, 0.5, 1.0])
*/
+ (CPColor)purpleColor
{
    if (!cachedPurpleColor)
        cachedPurpleColor = [[CPColor alloc] _initWithRGBA:[0.5, 0.0, 0.5, 1.0]];

    return cachedPurpleColor;
}

/*!
    Returns the shadow colour of the System catalog. Unless the theme gives it another value,
    it is black with an alpha of 1/3 (RGBA=[0.0, 0.0, 0.0, 0.33]).
*/
+ (CPColor)shadowColor
{
    return [self _systemColorNamed:@"shadowColor"];
}

/*!
    Returns a clear color (RGBA=[0.0, 0.0, 0.0, 0.0])
*/

+ (CPColor)clearColor
{
    if (!cachedClearColor)
        cachedClearColor = [self colorWithCalibratedWhite:0.0 alpha:0.0];

    return cachedClearColor;
}

+ (CPColor)_cachedThemeColor
{
    if (!cachedThemeColor)
        cachedThemeColor = [self colorWithCalibratedWhite:0.0 alpha:0.0];

    return cachedThemeColor;
}

// MARK: -
// MARK: System Colors

/*!
    Returns the colour named \c aColorName in the catalog named \c aCatalogName, or \c nil if
    there is none. The System catalog holds the system colours, such as \c labelColor and
    \c windowBackgroundColor, which Interface Builder writes into a XIB by name. A catalog
    colour keeps its name and resolves to a value whenever it is used: the current theme's
    value for the current drawing appearance (see
    +[CPAppearance currentDrawingAppearance]), or the colour's default when the theme gives
    none.

    The catalog \c Theme holds a theme's own colours. For it, the method returns a colour
    for any name, because a theme's archive is decoded before the theme gives values. A
    name that the current theme does not give resolves to the clear colour.
    @param aCatalogName the name of the catalog
    @param aColorName the name of the colour
    @return the named colour, or \c nil
*/
+ (CPColor)colorWithCatalogName:(CPString)aCatalogName colorName:(CPString)aColorName
{
    if (aCatalogName === _CPColorThemeCatalogName && aColorName)
        return [self _themeColorNamed:aColorName];

    if (aCatalogName !== _CPColorSystemCatalogName || !_CPSystemColorDefaults.hasOwnProperty(aColorName))
        return nil;

    return [self _systemColorNamed:aColorName];
}

+ (CPColor)_themeColorNamed:(CPString)aColorName
{
    var color = _CPThemeColors.hasOwnProperty(aColorName) ? _CPThemeColors[aColorName] : nil;

    if (!color)
        color = _CPThemeColors[aColorName] = [[_CPCatalogColor alloc] _initWithCatalogName:_CPColorThemeCatalogName colorName:aColorName];

    return color;
}

+ (CPColor)_systemColorNamed:(CPString)aColorName
{
    var color = _CPSystemColors[aColorName];

    if (!color)
        color = _CPSystemColors[aColorName] = [[_CPCatalogColor alloc] _initWithCatalogName:_CPColorSystemCatalogName colorName:aColorName];

    return color;
}

/*!
    Returns the colour named \c aName in the main bundle's asset catalog, or \c nil if there
    is none (see +colorNamed:bundle:).
    @param aName the name of the colour
    @return the named colour, or \c nil
*/
+ (CPColor)colorNamed:(CPString)aName
{
    return [self colorNamed:aName bundle:nil];
}

/*!
    Returns the colour named \c aName in the asset catalog of \c aBundle, or \c nil if there
    is none. A \c nil bundle means the main bundle. The asset catalog comes from the
    bundle's \c .xcassets directories, which the build compiles. An asset colour keeps its
    name and resolves to the catalog's value for the current drawing appearance (see
    +[CPAppearance currentDrawingAppearance]) whenever it is used.
    @param aName the name of the colour
    @param aBundle the bundle that holds the asset catalog, or \c nil for the main bundle
    @return the named colour, or \c nil
*/
+ (CPColor)colorNamed:(CPString)aName bundle:(CPBundle)aBundle
{
    return [[_CPAssetCatalog catalogForBundle:aBundle] colorNamed:aName];
}

/*
    The system colours. Each method returns the colour of that name in the System catalog,
    which resolves against the current theme and the current drawing appearance (see
    +colorWithCatalogName:colorName:).
*/
+ (CPColor)alternateSelectedControlColor
{
    return [self _systemColorNamed:@"alternateSelectedControlColor"];
}

+ (CPColor)alternateSelectedControlTextColor
{
    return [self _systemColorNamed:@"alternateSelectedControlTextColor"];
}

+ (CPColor)alternatingContentBackgroundColor
{
    return [self _systemColorNamed:@"alternatingContentBackgroundColor"];
}

+ (CPColor)controlAccentColor
{
    return [self _systemColorNamed:@"controlAccentColor"];
}

+ (CPColor)controlBackgroundColor
{
    return [self _systemColorNamed:@"controlBackgroundColor"];
}

+ (CPColor)controlColor
{
    return [self _systemColorNamed:@"controlColor"];
}

+ (CPColor)controlDarkShadowColor
{
    return [self _systemColorNamed:@"controlDarkShadowColor"];
}

+ (CPColor)controlHighlightColor
{
    return [self _systemColorNamed:@"controlHighlightColor"];
}

+ (CPColor)controlLightHighlightColor
{
    return [self _systemColorNamed:@"controlLightHighlightColor"];
}

+ (CPColor)controlShadowColor
{
    return [self _systemColorNamed:@"controlShadowColor"];
}

+ (CPColor)controlTextColor
{
    return [self _systemColorNamed:@"controlTextColor"];
}

+ (CPColor)disabledControlTextColor
{
    return [self _systemColorNamed:@"disabledControlTextColor"];
}

+ (CPColor)findHighlightColor
{
    return [self _systemColorNamed:@"findHighlightColor"];
}

+ (CPColor)gridColor
{
    return [self _systemColorNamed:@"gridColor"];
}

+ (CPColor)headerColor
{
    return [self _systemColorNamed:@"headerColor"];
}

+ (CPColor)headerTextColor
{
    return [self _systemColorNamed:@"headerTextColor"];
}

+ (CPColor)highlightColor
{
    return [self _systemColorNamed:@"highlightColor"];
}

+ (CPColor)keyboardFocusIndicatorColor
{
    return [self _systemColorNamed:@"keyboardFocusIndicatorColor"];
}

+ (CPColor)knobColor
{
    return [self _systemColorNamed:@"knobColor"];
}

+ (CPColor)labelColor
{
    return [self _systemColorNamed:@"labelColor"];
}

+ (CPColor)linkColor
{
    return [self _systemColorNamed:@"linkColor"];
}

+ (CPColor)placeholderTextColor
{
    return [self _systemColorNamed:@"placeholderTextColor"];
}

+ (CPColor)quaternaryLabelColor
{
    return [self _systemColorNamed:@"quaternaryLabelColor"];
}

+ (CPColor)quaternarySystemFillColor
{
    return [self _systemColorNamed:@"quaternarySystemFillColor"];
}

+ (CPColor)quinaryLabelColor
{
    return [self _systemColorNamed:@"quinaryLabelColor"];
}

+ (CPColor)quinarySystemFillColor
{
    return [self _systemColorNamed:@"quinarySystemFillColor"];
}

+ (CPColor)scrollBarColor
{
    return [self _systemColorNamed:@"scrollBarColor"];
}

+ (CPColor)secondaryLabelColor
{
    return [self _systemColorNamed:@"secondaryLabelColor"];
}

+ (CPColor)secondarySelectedControlColor
{
    return [self _systemColorNamed:@"secondarySelectedControlColor"];
}

+ (CPColor)secondarySystemFillColor
{
    return [self _systemColorNamed:@"secondarySystemFillColor"];
}

+ (CPColor)selectedContentBackgroundColor
{
    return [self _systemColorNamed:@"selectedContentBackgroundColor"];
}

+ (CPColor)selectedControlColor
{
    return [self _systemColorNamed:@"selectedControlColor"];
}

+ (CPColor)selectedControlTextColor
{
    return [self _systemColorNamed:@"selectedControlTextColor"];
}

+ (CPColor)selectedKnobColor
{
    return [self _systemColorNamed:@"selectedKnobColor"];
}

+ (CPColor)selectedMenuItemColor
{
    return [self _systemColorNamed:@"selectedMenuItemColor"];
}

+ (CPColor)selectedMenuItemTextColor
{
    return [self _systemColorNamed:@"selectedMenuItemTextColor"];
}

+ (CPColor)selectedTextColor
{
    return [self _systemColorNamed:@"selectedTextColor"];
}

+ (CPColor)separatorColor
{
    return [self _systemColorNamed:@"separatorColor"];
}

+ (CPColor)systemBlueColor
{
    return [self _systemColorNamed:@"systemBlueColor"];
}

+ (CPColor)systemBrownColor
{
    return [self _systemColorNamed:@"systemBrownColor"];
}

+ (CPColor)systemCyanColor
{
    return [self _systemColorNamed:@"systemCyanColor"];
}

+ (CPColor)systemFillColor
{
    return [self _systemColorNamed:@"systemFillColor"];
}

+ (CPColor)systemGrayColor
{
    return [self _systemColorNamed:@"systemGrayColor"];
}

+ (CPColor)systemGreenColor
{
    return [self _systemColorNamed:@"systemGreenColor"];
}

+ (CPColor)systemIndigoColor
{
    return [self _systemColorNamed:@"systemIndigoColor"];
}

+ (CPColor)systemMintColor
{
    return [self _systemColorNamed:@"systemMintColor"];
}

+ (CPColor)systemOrangeColor
{
    return [self _systemColorNamed:@"systemOrangeColor"];
}

+ (CPColor)systemPinkColor
{
    return [self _systemColorNamed:@"systemPinkColor"];
}

+ (CPColor)systemPurpleColor
{
    return [self _systemColorNamed:@"systemPurpleColor"];
}

+ (CPColor)systemRedColor
{
    return [self _systemColorNamed:@"systemRedColor"];
}

+ (CPColor)systemTealColor
{
    return [self _systemColorNamed:@"systemTealColor"];
}

+ (CPColor)systemYellowColor
{
    return [self _systemColorNamed:@"systemYellowColor"];
}

+ (CPColor)tertiaryLabelColor
{
    return [self _systemColorNamed:@"tertiaryLabelColor"];
}

+ (CPColor)tertiarySystemFillColor
{
    return [self _systemColorNamed:@"tertiarySystemFillColor"];
}

+ (CPColor)textBackgroundColor
{
    return [self _systemColorNamed:@"textBackgroundColor"];
}

+ (CPColor)textColor
{
    return [self _systemColorNamed:@"textColor"];
}

+ (CPColor)textInsertionPointColor
{
    return [self _systemColorNamed:@"textInsertionPointColor"];
}

+ (CPColor)underPageBackgroundColor
{
    return [self _systemColorNamed:@"underPageBackgroundColor"];
}

+ (CPColor)unemphasizedSelectedContentBackgroundColor
{
    return [self _systemColorNamed:@"unemphasizedSelectedContentBackgroundColor"];
}

+ (CPColor)unemphasizedSelectedTextBackgroundColor
{
    return [self _systemColorNamed:@"unemphasizedSelectedTextBackgroundColor"];
}

+ (CPColor)unemphasizedSelectedTextColor
{
    return [self _systemColorNamed:@"unemphasizedSelectedTextColor"];
}

+ (CPColor)windowBackgroundColor
{
    return [self _systemColorNamed:@"windowBackgroundColor"];
}

+ (CPColor)windowFrameColor
{
    return [self _systemColorNamed:@"windowFrameColor"];
}

+ (CPColor)windowFrameTextColor
{
    return [self _systemColorNamed:@"windowFrameTextColor"];
}

/*!
    Raises an exception: only a catalog colour has a catalog name, as in AppKit (see
    +colorWithCatalogName:colorName:).
*/
- (CPString)catalogNameComponent
{
    [CPException raise:CPInvalidArgumentException reason:@"*** -catalogNameComponent is not valid for a color that is not a catalog color"];
}

/*!
    Raises an exception: only a catalog colour has a colour name, as in AppKit (see
    +colorWithCatalogName:colorName:).
*/
- (CPString)colorNameComponent
{
    [CPException raise:CPInvalidArgumentException reason:@"*** -colorNameComponent is not valid for a color that is not a catalog color"];
}

/*!
    Creates a color using a tile pattern with \c anImage
    @param the image to tile
    @return a tiled image color object
*/
+ (CPColor)colorWithPatternImage:(CPImage)anImage
{
    return [[CPColor alloc] _initWithPatternImage:anImage];
}

/*!
    Creates a CPColor from a valid CSS RGB string. Example, "rgb(32,64,129)".

    @param aString a CSS color string
    @return a color initialized to the value in the css string
*/
+ (CPColor)colorWithCSSString:(CPString)aString
{
    return [[CPColor alloc] _initWithCSSString: aString];
}

+ (CPColor)selectedTextBackgroundColor
{
    return [self _systemColorNamed:@"selectedTextBackgroundColor"];
}

+ (CPColor)_selectedTextBackgroundColorUnfocussed
{
    return [[self _cachedThemeColor] valueForThemeAttribute:@"selected-text-inactive-background-color"] || [CPColor colorWithHexString:"CCCCCC"];
}

/* @ignore */
- (id)_initWithCSSString:(CPString)aString
{
    if (aString.indexOf("rgb") == CPNotFound)
        return nil;

    self = [super init];

    var startingIndex = aString.indexOf("("),
        parts = aString.substring(startingIndex + 1).split(',');

    _components = [
        parseInt(parts[0], 10) / 255.0,
        parseInt(parts[1], 10) / 255.0,
        parseInt(parts[2], 10) / 255.0,
        parts[3] ? parseFloat(parts[3], 10) : 1.0
    ];

    // We can't reuse aString as _cssString because the browser might not support the `rgba` syntax, and aString might
    // use it (issue #1413.)
    [self _initCSSStringFromComponents];

    _theme = [CPTheme defaultTheme];
    _themeState = CPThemeStateNormal;
    [self _loadThemeAttributes];

    return self;
}

/* @ignore */
- (id)_initWithRGBA:(CPArray)components
{
    self = [super init];

    if (self)
    {
        _components = components;

        [self _initCSSStringFromComponents];

        _theme = [CPTheme defaultTheme];
        _themeState = CPThemeStateNormal;
        [self _loadThemeAttributes];
    }

    return self;
}

- (void)_initCSSStringFromComponents
{
    // Fix to avoid a problem when compiling a theme (missing the alpha component as theme compiler doesn't have CSS rgba capability)
    var hasAlpha = YES;
    if (CPDOMAvailable)
    {
        hasAlpha = CPFeatureIsCompatible(CPCSSRGBAFeature) && _components[3] != 1.0;
    }

    _cssString = (hasAlpha ? "rgba(" : "rgb(") +
        parseInt(_components[0] * 255.0) + ", " +
        parseInt(_components[1] * 255.0) + ", " +
        parseInt(_components[2] * 255.0) +
        (hasAlpha ?  (", " + _components[3]) : "") + ")";
}

/* @ignore */
- (id)_initWithPatternImage:(CPImage)anImage
{
    self = [super init];

    if (self)
    {
        _patternImage = anImage;
        _cssString = "url(\"" + [_patternImage filename] + "\")";
        _components = [0.0, 0.0, 0.0, 1.0];

        _theme = [CPTheme defaultTheme];
        _themeState = CPThemeStateNormal;
        [self _loadThemeAttributes];
    }

    return self;
}

/*!
    Returns the image being used as the pattern for the tile in this color.
*/
- (CPImage)patternImage
{
    return _patternImage;
}

/*!
    Returns the alpha component of this color.
*/
- (float)alphaComponent
{
    return _components[3];
}

/*!
    Returns the blue component of this color.
*/
- (float)blueComponent
{
    return _components[2];
}

/*!
    Returns the green component of this color.
*/
- (float)greenComponent
{
    return _components[1];
}

/*!
    Return the red component of this color.
*/
- (float)redComponent
{
    return _components[0];
}

/*!
    Returns the RGBA components of this color in an array.
    The index values are ordered as:
<pre>
<b>Index</b>   <b>Component</b>
0       Red
1       Green
2       Blue
3       Alpha
</pre>
*/
- (CPArray)components
{
    return _components;
}

/*!
    Returns a new color with the same RGB as the receiver but a new alpha component.

    @param anAlphaComponent the alpha component for the new color

    @return a new color object
*/
- (CPColor)colorWithAlphaComponent:(float)anAlphaComponent
{
    var components = _components.slice();

    components[components.length - 1] = anAlphaComponent;

    return [[[self class] alloc] _initWithRGBA:components];
}

/*!
    Returns the receiver. This method is a placeholder that does nothing but may be implemented in the future.
*/
- (CPColor)colorUsingColorSpaceName:(id)aColorSpaceName
{
    return self;
}

/*!
    Returns an array with the HSB values for this color.

    The values are expressed as fractions between 0.0-1.0.

    The index values are ordered as:
<pre>
<b>Index</b>   <b>Component</b>
0       Hue
1       Saturation
2       Brightness
</pre>
*/
- (CPArray)hsbComponents
{
    var red   = ROUND(_components[_redComponent] * 255.0),
        green = ROUND(_components[_greenComponent] * 255.0),
        blue  = ROUND(_components[_blueComponent] * 255.0);

    var max   = MAX(red, green, blue),
        min   = MIN(red, green, blue),
        delta = max - min;

    var brightness = max / 255.0,
        saturation = (max != 0) ? delta / max : 0;

    var hue;

    if (saturation == 0)
    {
        hue = 0;
    }
    else
    {
        var rr = (max - red) / delta,
            gr = (max - green) / delta,
            br = (max - blue) / delta;

        if (red == max)
            hue = br - gr;
        else if (green == max)
            hue = 2 + rr - br;
        else
            hue = 4 + gr - rr;

        hue /= 6;
        if (hue < 0)
            hue++;
    }

    return [
        hue,
        saturation,
        brightness
    ];
}

/*!
    Returns the hue component, the H in HSB, of the receiver.
*/
- (float)hueComponent
{
    return [self hsbComponents][0];
}

/*!
    Returns the saturation component, the S in HSB, of the receiver.
*/
- (float)saturationComponent
{
    return [self hsbComponents][1];
}

/*!
    Returns the brightness component, the B in HSB, of the receiver.
*/
- (float)brightnessComponent
{
    return [self hsbComponents][2];
}

/*!
    Returns the CSS representation of this color. The color will
    be in one of the following forms:
<pre>
rgb(22,44,88)
rgba(22,44,88,0.5)  // if there is an alpha
url("data:image/png;base64,BASE64ENCODEDDATA")  // if there is a pattern image
</pre>
*/
- (CPString)cssString
{
    return _cssString;
}

/*
    Returns the colour that the receiver gives in the current drawing appearance. A plain
    colour gives itself. _CPDynamicColor gives the colour of its name in that appearance.
*/
- (CPColor)_resolvedColor
{
    return self;
}

/*!
    Returns a 6 character long hex string of this color.
*/
- (CPString)hexString
{
    return rgbToHex([self redComponent], [self greenComponent], [self blueComponent]);
}

- (BOOL)isEqual:(CPColor)aColor
{
    if (!aColor)
        return NO;

    if (aColor === self)
        return YES;

    if (![aColor isKindOfClass:CPColor])
        return NO;

    if (_patternImage || [aColor patternImage])
        return [_patternImage isEqual:[aColor patternImage]];

    // We don't require the components to be equal beyond 8 bits since otherwise
    // simple rounding errors will make two colours which are exactly the same on
    // screen compare unequal.
    return ROUND([self redComponent] * 255.0) == ROUND([aColor redComponent] * 255.0) &&
           ROUND([self greenComponent] * 255.0) == ROUND([aColor greenComponent] * 255.0) &&
           ROUND([self blueComponent] * 255.0) == ROUND([aColor blueComponent] * 255.0) &&
           [self alphaComponent] == [aColor alphaComponent];
}

- (CPString)description
{
    var description = [super description],
        patternImage = [self patternImage];

    if ([self isCSSBased])
        return description + "\n" + [self cssDictionary]+ "\nBefore:\n" + [self cssBeforeDictionary] + "\nAfter:\n" + [self cssAfterDictionary];

    if (!patternImage)
        return description + " " + [self cssString];

    description += " {\n";

    if ([patternImage isThreePartImage] || [patternImage isNinePartImage])
    {
        var slices = [patternImage imageSlices];

        if ([patternImage isThreePartImage])
            description += "    orientation: " + ([patternImage isVertical] ? "vertical" : "horizontal") + ",\n";

        description += "    patternImage (" + slices.length + " part): [\n";

        for (var i = 0; i < slices.length; ++i)
        {
            var imgDescription = [slices[i] description] || "nil";

            description += imgDescription.replace(/^/mg, "        ") + ",\n";
        }

        description = description.substr(0, description.length - 2) + "\n    ]\n}";
    }
    else
        description += ([patternImage description] || "nil").replace(/^/mg, "    ") + "\n}";

    return description;
}

@end

@implementation CPColor (CoreGraphicsExtensions)

/*!
    Set's the receiver to be the fill and stroke color in the current graphics context
*/
- (void)set
{
    [self setFill];
    [self setStroke];
}

/*!
    Set's the receiver to be the fill color in the current graphics context
*/
- (void)setFill
{
    var ctx = [[CPGraphicsContext currentContext] graphicsPort];
    CGContextSetFillColor(ctx, self);
}

/*!
    Set's the receiver to be the stroke color in the current graphics context
*/
- (void)setStroke
{
    var ctx = [[CPGraphicsContext currentContext] graphicsPort];
    CGContextSetStrokeColor(ctx, self);
}

@end

@implementation CPColor (Debugging)

+ (CPColor)randomColor
{
    return [CPColor colorWithRed:RAND() green:RAND() blue:RAND() alpha:1.0];
}

+ (CPColor)checkerBoardColor
{
    // Thanks to cocco http://stackoverflow.com/a/18368212/76900.
    return [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAQMAAAAlPW0iAAAABlBMVEX////MzMw46qqDAAAAEElEQVQImWNg+M+AFeEQBgB+vw/xfUUZkgAAAABJRU5ErkJggg=="]];
}

@end

// MARK: -
// MARK: CSS Theming

// The code below adds support for CSS theming with 100% compatibility with current theming system.
// The idea is to extend CPColor (and CPImage) with CSS components and adapt low level UI components to
// support this new kind of CPColor/CPImage. See CPImageView, CPView and _CPImageAndTextView.
//
// To create a CPColor that uses CSS, simply use the new class method :
// + (CPColor)colorWithCSSDictionary:(CPDictionary)aDictionary beforeDictionary:(CPDictionary)beforeDictionary afterDictionary:(CPDictionary)afterDictionary
// where beforeDictionary & afterDictionary are related to ::before & ::after pseudo-elements.
// If you don't need them, just use the simplified class method :
// + (CPColor)colorWithCSSDictionary:(CPDictionary)aDictionary
//
// Example :
// buttonCssColor = [CPColor colorWithCSSDictionary:@{
//                                                    @"background-color": A3ColorBackgroundWhite,
//                                                    @"border-color": A3ColorActiveBorder,
//                                                    @"border-style": @"solid",
//                                                    @"border-width": @"1px",
//                                                    @"border-radius": @"3px",
//                                                    @"box-sizing": @"border-box"
//                                                    }
//                                 beforeDictionary:@{
//                                                    @"background-color": @"rgb(225,225,225)",
//                                                    @"bottom": @"3px",
//                                                    @"content": @"''",
//                                                    @"position": @"absolute",
//                                                    @"right": @"21px",
//                                                    @"top": @"3px",
//                                                    @"width": @"1px"
//                                                    }
//                                  afterDictionary:@{
//                                                    @"content": @"''",
//                                                    @"bottom": @"3px",
//                                                    @"right": @"6px",
//                                                    @"top": @"1px",
//                                                    @"position": @"absolute",
//                                                    @"height": @"14px",
//                                                    @"width": @"9px",
//                                                    @"margin": @"2px 0px 2px 0px",
//                                                    @"background-image": @"url(%%packed.png)",
//                                                    @"background-position": @"0px -64px",
//                                                    @"background-repeat": @"no-repeat",
//                                                    @"background-size": @"100px 400px"
//                                                    }];
//
// Remark : Please note the special URL of the background image used in this example : url(%%packed.png)
//          During theme loading, "%%" will be replaced by the path to the theme blend resources folder.
//          Typically, a CSS theme will use some (rare) images all packed together in a single image resource (see packed.png in Aristo3 theme)
//
//          Also, please note that if you don't use one of the CSS components, you can either set it to nil (best solution) or to an empty dictionary, like :
//          aCssColor = [CPColor colorWithCSSDictionary:@{} beforeDictionary:nil afterDictionary:@{ ... }];
//
// You can use -(BOOL)isCSSBased to determine how to cope with it in your code.
// -(BOOL)hasCSSDictionary, -(BOOL)hasCSSBeforeDictionary and -(BOOL)hasCSSAfterDictionary are convience methods you can use.
//
// Remark : +(void)restorePreviousCSSState and -(DOMElement)applyCSSColorForView are meant to be used by low level UI widgets (like CPView) to implement
//          CSS theme support.

/*
    A value in a CSS dictionary of a colour or an image is a string, a colour, or an array of
    strings and colours. A colour can be a named colour, so that the dictionary follows the
    appearance: [CPColor separatorColor], or @[@"0 0 0 3px ", aColor] for a value with more
    than a colour. The dictionary keeps the objects; each value is converted when it is
    written, in the current drawing appearance.
*/

/*
    Returns the CSS text of aValue, a value of a CSS dictionary: a string gives itself; a
    colour gives its CSS string in the current drawing appearance; an array gives its members,
    each converted, joined with no separator. A number gives its decimal text, as the DOM
    writes it. Any other value is a defect of the dictionary and raises.
*/
function _CPCSSValueString(aValue)
{
    if (typeof aValue === "string")
        return aValue;

    if (typeof aValue === "number")
        return String(aValue);

    if (aValue && aValue.isa)
    {
        if ([aValue isKindOfClass:CPColor])
            return [aValue cssString];

        if ([aValue isKindOfClass:CPArray])
        {
            var text = "";

            for (var i = 0, count = aValue.length; i < count; i++)
                text += _CPCSSValueString(aValue[i]);

            return text;
        }
    }

    [CPException raise:CPInvalidArgumentException reason:"A CSS dictionary value must be a string, a colour or an array of these, not " + aValue];
}

/*
    Returns YES when aValue, a value of a CSS dictionary, is a colour or an array that holds
    one.
*/
function _CPCSSValueHoldsColor(aValue)
{
    if (!aValue || !aValue.isa || typeof aValue === "string")
        return NO;

    if ([aValue isKindOfClass:CPColor])
        return YES;

    if ([aValue isKindOfClass:CPArray])
    {
        for (var i = 0, count = aValue.length; i < count; i++)
            if (_CPCSSValueHoldsColor(aValue[i]))
                return YES;
    }

    return NO;
}

function _CPCSSDictionaryHoldsColor(aDictionary)
{
    var values = [aDictionary allValues];

    for (var i = 0, count = [values count]; i < count; i++)
        if (_CPCSSValueHoldsColor(values[i]))
            return YES;

    return NO;
}

/*
    Returns YES when a CSS dictionary of anObject, a colour or an image, holds a colour. Such
    an object writes other CSS in another appearance, although it is the same object.

    The result is computed at each call and not kept on the object, because a dictionary
    changes after the object is made: a theme replaces placeholder strings with the values of
    its dynamic set in place (see -[CPTheme applyDynamicSet:]).
*/
function _CPCSSObjectIsAppearanceDependent(anObject)
{
    return _CPCSSDictionaryHoldsColor([anObject cssDictionary]) ||
           _CPCSSDictionaryHoldsColor([anObject cssBeforeDictionary]) ||
           _CPCSSDictionaryHoldsColor([anObject cssAfterDictionary]);
}

function _CPCSSDictionaryText(aDictionary)
{
    var text = "",
        keys = [aDictionary allKeys];

    for (var i = 0, count = [keys count]; i < count; i++)
        text += keys[i] + ": " + _CPCSSValueString([aDictionary objectForKey:keys[i]]) + "; ";

    return text;
}

/*
    Returns the CSS that anObject, a colour or an image, writes in the current drawing
    appearance: its three dictionaries with every value converted, as one string. A setter
    compares it with the text of its last write to decide whether to write again.
*/
function _CPCSSObjectText(anObject)
{
    return _CPCSSDictionaryText([anObject cssDictionary]) +
           "::before { " + _CPCSSDictionaryText([anObject cssBeforeDictionary]) + "} " +
           "::after { " + _CPCSSDictionaryText([anObject cssAfterDictionary]) + "}";
}

@implementation CPColor (CSSTheming)
{
    CPDictionary    _cssDictionary              @accessors(property=cssDictionary);
    CPDictionary    _cssBeforeDictionary        @accessors(property=cssBeforeDictionary);
    CPDictionary    _cssAfterDictionary         @accessors(property=cssAfterDictionary);
}

+ (CPColor)colorWithCSSDictionary:(CPDictionary)aDictionary
{
    return [[CPColor alloc] _initWithCSSDictionary:aDictionary beforeDictionary:nil afterDictionary:nil];
}

+ (CPColor)colorWithCSSDictionary:(CPDictionary)aDictionary beforeDictionary:(CPDictionary)beforeDictionary afterDictionary:(CPDictionary)afterDictionary
{
    return [[CPColor alloc] _initWithCSSDictionary:aDictionary beforeDictionary:beforeDictionary afterDictionary:afterDictionary];
}

- (id)_initWithCSSDictionary:(CPDictionary)aDictionary beforeDictionary:(CPDictionary)beforeDictionary afterDictionary:(CPDictionary)afterDictionary
{
    self = [super init];

    if (self)
    {
        _cssDictionary       = aDictionary;
        _cssBeforeDictionary = beforeDictionary;
        _cssAfterDictionary  = afterDictionary;
        _components          = [0.0, 0.0, 0.0, 1.0];

        _theme = [CPTheme defaultTheme];
        _themeState = CPThemeStateNormal;
        [self _loadThemeAttributes];
    }

    return self;
}

- (BOOL)isCSSBased
{
    return !!(_cssDictionary || _cssBeforeDictionary || _cssAfterDictionary);
}

- (BOOL)hasCSSDictionary
{
    return ([_cssDictionary count] > 0);
}

- (BOOL)hasCSSBeforeDictionary
{
    return ([_cssBeforeDictionary count] > 0);
}

- (BOOL)hasCSSAfterDictionary
{
    return ([_cssAfterDictionary count] > 0);
}

+ (void)restorePreviousCSSState:(CPArrayRef)aPreviousStateRef forDOMElement:(DOMElement)aDOMElement
{
    var aPreviousState = @deref(aPreviousStateRef);

    for (var i = 0, count = aPreviousState.length; i < count; i++)
        aDOMElement.style[aPreviousState[i][0]] = aPreviousState[i][1];

    @deref(aPreviousStateRef) = @[];
}

/*
    Writes the receiver's CSS into the DOM. Each value is converted with _CPCSSValueString in
    the current drawing appearance, which the caller sets to the view's appearance.
*/
- (DOMElement)applyCSSColorForView:(CPView)aView onDOMElement:(DOMElement)aDOMElement styleNode:(DOMElement)aStyleNode previousState:(CPArrayRef)aPreviousStateRef
{
    var aPreviousState = @deref(aPreviousStateRef);

    [_cssDictionary enumerateKeysAndObjectsUsingBlock:function(aKey, anObject, stop)
     {
         [aPreviousState addObject:@[aKey, aDOMElement.style[aKey]]];
         aDOMElement.style[aKey] = _CPCSSValueString(anObject);
     }];

    if ([self hasCSSBeforeDictionary] || [self hasCSSAfterDictionary])
    {
        // We need to create a unique class name

        var styleClassName = @".CP" + [aView UID],
        styleContent = @"";

        if ([self hasCSSBeforeDictionary])
        {
            styleContent += styleClassName + @"::before { ";

            [_cssBeforeDictionary enumerateKeysAndObjectsUsingBlock:function(aKey, anObject, stop)
             {
                 styleContent += aKey + ": " + _CPCSSValueString(anObject) + "; ";
             }];

            styleContent += "} ";
        }

        if ([self hasCSSAfterDictionary])
        {
            styleContent += styleClassName + @"::after { ";

            [_cssAfterDictionary enumerateKeysAndObjectsUsingBlock:function(aKey, anObject, stop)
             {
                 styleContent += aKey + ": " + _CPCSSValueString(anObject) + "; ";
             }];

            styleContent += "} ";
        }

        var styleDescription = document.createTextNode(styleContent);

        if (!aStyleNode)
        {
            aStyleNode = document.createElement("style");

            aView._DOMElement.insertBefore(aStyleNode, aView._DOMElement.firstChild);

            aStyleNode.appendChild(styleDescription);
        }
        else
        {
            aStyleNode.replaceChild(styleDescription, aStyleNode.firstChild);
        }

        [aView setDOMClassName:@"CP"+[aView UID]];
    }
    else
    {
        // no before/after so remove aStyleNode if existing

        if (aStyleNode)
        {
            aView._DOMElement.removeChild(aStyleNode);
            aStyleNode = nil;
        }
    }

    // Return actualised values

    @deref(aPreviousStateRef) = aPreviousState;

    return aStyleNode;
}

@end

// MARK: -

/// @cond IGNORE
var CPColorComponentsKey            = @"CPColorComponentsKey",
    CPColorPatternImageKey          = @"CPColorPatternImageKey",
    CPColorCssDictionaryKey         = @"CPColorCssDictionaryKey",
    CPColorCssBeforeDictionaryKey   = @"CPColorCssBeforeDictionaryKey",
    CPColorCssAfterDictionaryKey    = @"CPColorCssAfterDictionaryKey",
    CPColorCatalogNameKey           = @"CPColorCatalogNameKey",
    CPColorNameKey                  = @"CPColorNameKey",
    CPColorCatalogAlphaKey          = @"CPColorCatalogAlphaKey",
    CPColorAssetNameKey             = @"CPColorAssetNameKey",
    CPColorAssetBundlePathKey       = @"CPColorAssetBundlePathKey";
/// @endcond

@implementation CPColor (CPCoding)

/*!
    Initializes this color from the data archived in a coder.
    @param aCoder the coder from which the color will be loaded
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    if ([aCoder containsValueForKey:CPColorCatalogNameKey])
    {
        var catalogColor = [CPColor colorWithCatalogName:[aCoder decodeObjectForKey:CPColorCatalogNameKey]
                                               colorName:[aCoder decodeObjectForKey:CPColorNameKey]];

        if (catalogColor && [aCoder containsValueForKey:CPColorCatalogAlphaKey])
            catalogColor = [catalogColor colorWithAlphaComponent:[aCoder decodeFloatForKey:CPColorCatalogAlphaKey]];

        return catalogColor;
    }

    if ([aCoder containsValueForKey:CPColorAssetNameKey])
    {
        var bundlePath = [aCoder decodeObjectForKey:CPColorAssetBundlePathKey],
            bundle = bundlePath ? [CPBundle bundleWithPath:bundlePath] : [CPBundle mainBundle],
            assetColor = [CPColor colorNamed:[aCoder decodeObjectForKey:CPColorAssetNameKey] bundle:bundle];

        if (assetColor && [aCoder containsValueForKey:CPColorCatalogAlphaKey])
            assetColor = [assetColor colorWithAlphaComponent:[aCoder decodeFloatForKey:CPColorCatalogAlphaKey]];

        return assetColor;
    }

    if ([aCoder containsValueForKey:CPColorPatternImageKey])
        self = [self _initWithPatternImage:[aCoder decodeObjectForKey:CPColorPatternImageKey]];
    else if ([aCoder containsValueForKey:CPColorCssDictionaryKey])
        self = [self _initWithCSSDictionary:[aCoder decodeObjectForKey:CPColorCssDictionaryKey]
                           beforeDictionary:[aCoder decodeObjectForKey:CPColorCssBeforeDictionaryKey]
                            afterDictionary:[aCoder decodeObjectForKey:CPColorCssAfterDictionaryKey]];
    else
        self = [self _initWithRGBA:[aCoder decodeObjectForKey:CPColorComponentsKey]];

    [self _decodeThemeObjectsWithCoder:aCoder];

    return self;
}

/*!
    Archives this color into a coder.
    @param aCoder the coder into which the color will be archived.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    if (_patternImage)
        [aCoder encodeObject:_patternImage forKey:CPColorPatternImageKey];
    else if (_cssDictionary)
    {
        [aCoder encodeObject:_cssDictionary       forKey:CPColorCssDictionaryKey];
        [aCoder encodeObject:_cssBeforeDictionary forKey:CPColorCssBeforeDictionaryKey];
        [aCoder encodeObject:_cssAfterDictionary  forKey:CPColorCssAfterDictionaryKey];
    }
    else
        [aCoder encodeObject:_components forKey:CPColorComponentsKey];

    [self _encodeThemeObjectsWithCoder:aCoder];
}

@end


/*
    A colour whose value depends on the drawing appearance. It holds no value of its own and
    resolves to a colour whenever it is used (see -_resolvedColor), so that it follows the
    current theme and the current drawing appearance. Every method that reads the colour's
    value reads the resolved colour. A colour made with -colorWithAlphaComponent: stays
    dynamic and replaces the alpha of the resolved colour. Subclasses implement
    -_valueInAppearance: and -_dynamicCopy.
*/
@implementation _CPDynamicColor : CPColor
{
    float       _alphaOverride;
}

- (id)_initDynamicColor
{
    self = [super init];

    if (self)
        _alphaOverride = nil;

    return self;
}

/*
    Returns the colour's value in anAppearance, before any alpha override.
*/
- (CPColor)_valueInAppearance:(CPAppearance)anAppearance
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

/*
    Returns a new colour of the receiver's kind and name, without alpha override.
*/
- (_CPDynamicColor)_dynamicCopy
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (CPColor)_resolvedColor
{
    var color = [self _valueInAppearance:[CPAppearance currentDrawingAppearance]];

    if (_alphaOverride !== nil)
        color = [color colorWithAlphaComponent:_alphaOverride];

    return color;
}

- (CPImage)patternImage
{
    return [[self _resolvedColor] patternImage];
}

- (float)alphaComponent
{
    return [[self _resolvedColor] alphaComponent];
}

- (float)blueComponent
{
    return [[self _resolvedColor] blueComponent];
}

- (float)greenComponent
{
    return [[self _resolvedColor] greenComponent];
}

- (float)redComponent
{
    return [[self _resolvedColor] redComponent];
}

- (CPArray)components
{
    return [[self _resolvedColor] components];
}

- (CPArray)hsbComponents
{
    return [[self _resolvedColor] hsbComponents];
}

- (CPString)cssString
{
    return [[self _resolvedColor] cssString];
}

- (CPColor)colorWithAlphaComponent:(float)anAlphaComponent
{
    var color = [self _dynamicCopy];

    color._alphaOverride = anAlphaComponent;

    return color;
}

/*
    Returns the resolved colour, as AppKit converts a catalog colour to a colour space.
*/
- (CPColor)colorUsingColorSpaceName:(id)aColorSpaceName
{
    return [self _resolvedColor];
}

- (BOOL)isCSSBased
{
    return [[self _resolvedColor] isCSSBased];
}

- (BOOL)hasCSSDictionary
{
    return [[self _resolvedColor] hasCSSDictionary];
}

- (BOOL)hasCSSBeforeDictionary
{
    return [[self _resolvedColor] hasCSSBeforeDictionary];
}

- (BOOL)hasCSSAfterDictionary
{
    return [[self _resolvedColor] hasCSSAfterDictionary];
}

- (CPDictionary)cssDictionary
{
    return [[self _resolvedColor] cssDictionary];
}

- (CPDictionary)cssBeforeDictionary
{
    return [[self _resolvedColor] cssBeforeDictionary];
}

- (CPDictionary)cssAfterDictionary
{
    return [[self _resolvedColor] cssAfterDictionary];
}

- (DOMElement)applyCSSColorForView:(CPView)aView onDOMElement:(DOMElement)aDOMElement styleNode:(DOMElement)aStyleNode previousState:(CPArrayRef)aPreviousStateRef
{
    return [[self _resolvedColor] applyCSSColorForView:aView onDOMElement:aDOMElement styleNode:aStyleNode previousState:aPreviousStateRef];
}

/*
    Draws with the colour that the receiver has in the current drawing appearance.
*/
- (void)setFill
{
    [[self _resolvedColor] setFill];
}

- (void)setStroke
{
    [[self _resolvedColor] setStroke];
}

- (Class)classForKeyedArchiver
{
    return [CPColor class];
}

- (void)_encodeAlphaOverrideWithCoder:(CPCoder)aCoder
{
    if (_alphaOverride !== nil)
        [aCoder encodeFloat:_alphaOverride forKey:CPColorCatalogAlphaKey];
}

@end


/*
    A colour of a catalog: the System catalog or the theme catalog. It keeps its catalog name
    and colour name and takes its value from the current theme (see _CPSystemColorValue and
    _CPThemeColorValue).
*/
@implementation _CPCatalogColor : _CPDynamicColor
{
    CPString    _catalogName;
    CPString    _colorName;
}

- (id)_initWithCatalogName:(CPString)aCatalogName colorName:(CPString)aColorName
{
    self = [super _initDynamicColor];

    if (self)
    {
        _catalogName = aCatalogName;
        _colorName = aColorName;
    }

    return self;
}

- (CPColor)_valueInAppearance:(CPAppearance)anAppearance
{
    if (_catalogName === _CPColorThemeCatalogName)
        return _CPThemeColorValue(_colorName, anAppearance);

    return _CPSystemColorValue(_colorName, anAppearance);
}

- (_CPDynamicColor)_dynamicCopy
{
    return [[_CPCatalogColor alloc] _initWithCatalogName:_catalogName colorName:_colorName];
}

- (CPString)catalogNameComponent
{
    return _catalogName;
}

- (CPString)colorNameComponent
{
    return _colorName;
}

/*
    Two catalog colours are equal when they name the same colour with the same alpha. A
    catalog colour and a colour of fixed value are equal when the catalog colour resolves
    to that value, as a system colour method returned a fixed colour before.
*/
- (BOOL)isEqual:(CPColor)aColor
{
    if (aColor === self)
        return YES;

    if ([aColor isKindOfClass:[_CPCatalogColor class]])
        return _catalogName === aColor._catalogName && _colorName === aColor._colorName && _alphaOverride === aColor._alphaOverride;

    return [[self _resolvedColor] isEqual:aColor];
}

- (CPString)description
{
    return @"Catalog color: " + _catalogName + @" " + _colorName + (_alphaOverride !== nil ? @", alpha " + _alphaOverride : @"");
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_catalogName forKey:CPColorCatalogNameKey];
    [aCoder encodeObject:_colorName forKey:CPColorNameKey];
    [self _encodeAlphaOverrideWithCoder:aCoder];
}

@end


/*
    A colour of a bundle's asset catalog (see +colorNamed:bundle:). It keeps its name and
    catalog and takes its value from the catalog's entry for the appearance. It is archived by
    its name and, outside the main bundle, its bundle path.
*/
@implementation _CPAssetColor : _CPDynamicColor
{
    CPString            _assetName;
    _CPAssetCatalog     _catalog;
}

- (id)_initWithAssetName:(CPString)aName catalog:(_CPAssetCatalog)aCatalog
{
    self = [super _initDynamicColor];

    if (self)
    {
        _assetName = aName;
        _catalog = aCatalog;
    }

    return self;
}

- (CPColor)_valueInAppearance:(CPAppearance)anAppearance
{
    return [_catalog _colorValueForAssetNamed:_assetName appearance:anAppearance];
}

- (_CPDynamicColor)_dynamicCopy
{
    return [[_CPAssetColor alloc] _initWithAssetName:_assetName catalog:_catalog];
}

/*
    Two asset colours are equal when they name the same asset of the same catalog with the
    same alpha. An asset colour and a colour of fixed value are equal when the asset colour
    resolves to that value.
*/
- (BOOL)isEqual:(CPColor)aColor
{
    if (aColor === self)
        return YES;

    if ([aColor isKindOfClass:[_CPAssetColor class]])
        return _assetName === aColor._assetName && _catalog === aColor._catalog && _alphaOverride === aColor._alphaOverride;

    return [[self _resolvedColor] isEqual:aColor];
}

- (CPString)description
{
    return @"Asset color: " + _assetName + (_alphaOverride !== nil ? @", alpha " + _alphaOverride : @"");
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    var bundle = [_catalog bundle];

    [aCoder encodeObject:_assetName forKey:CPColorAssetNameKey];

    if (bundle !== [CPBundle mainBundle])
        [aCoder encodeObject:[bundle bundlePath] forKey:CPColorAssetBundlePathKey];

    [self _encodeAlphaOverrideWithCoder:aCoder];
}

@end


/// @cond IGNORE
var hexCharacters = "0123456789ABCDEF";

/*
    Used for the CPColor +colorWithHexString: implementation.
    Returns an array of rgb components.
*/
var hexToRGB = function(hex)
{
    if (hex.length == 3)
        hex = hex.charAt(0) + hex.charAt(0) + hex.charAt(1) + hex.charAt(1) + hex.charAt(2) + hex.charAt(2);

    if (hex.length != 6)
        return null;

    hex = hex.toUpperCase();

    for (var i = 0; i < hex.length; i++)
        if (hexCharacters.indexOf(hex.charAt(i)) == -1)
            return null;

    var red   = (hexCharacters.indexOf(hex.charAt(0)) * 16 + hexCharacters.indexOf(hex.charAt(1))) / 255.0,
        green = (hexCharacters.indexOf(hex.charAt(2)) * 16 + hexCharacters.indexOf(hex.charAt(3))) / 255.0,
        blue  = (hexCharacters.indexOf(hex.charAt(4)) * 16 + hexCharacters.indexOf(hex.charAt(5))) / 255.0;

    return [red, green, blue, 1.0];
};

var rgbToHex = function(r,g,b)
{
    return byteToHex(r) + byteToHex(g) + byteToHex(b);
};

var byteToHex = function(n)
{
    if (!n || isNaN(n))
        return "00";

    n = FLOOR(MIN(255, MAX(0, 256 * n)));

    return hexCharacters.charAt((n - n % 16) / 16) +
           hexCharacters.charAt(n % 16);
};

/*!
    To create a simple color with a pattern image:
        CPColorWithImages(name, width, height{, bundle})

    To create a color with a three-part/nine-part image using a pattern string:
        CPColorWithImages(pattern, attributes{, bundle})

    <pattern> must have one or more placeholders. There are there possible
    placeholders available that together can be used to build a filename:

    style     A top-level style, for example normal (empty) and "default".
    state     The state of a view, for example "highlighted" and "disabled".
    position  The position of an image within a 3-part or 9-part image.
              This must be provided.

    Each placeholder is filled with the values you pass in a the attributes object.
    Neither style nor state are necessary, if you omit them the next level of the
    hierarchy is the top level.

    Attributes
    ----------
    styles: [...]
    An array of style names. For example, if you want to generate the filenames
    "button-bezel" and "default-button-bezel", you would use ["", "default"]
    for the styles.

    states: [...]
    An array of state names.

    positions: <spec>
    Specifies the naming convention for the slices of the image. For 3-part images,
    <spec> may be one of:

        "@"     Equivalent to ["left", "center", "right"] for horizontal
                images, ["top", "center", "bottom"] for vertical images
        "#"     Equivalent to ["0", "1", "2"]
        [...]   An array of any three literal strings

    For 9-part images, <spec> may be one of:

        "@" | "abbrev"  Equivalent to ["top-left", "top", "top-right",
                                       "left", "center", "right",
                                       "bottom-left", "bottom", "bottom-right"]
        "full"          Equivalent to ["top-left", "top-center", "top-right",
                                       "center-left", "center-center", "center-right",
                                       "bottom-left", "bottom-center", "bottom-right"]
        "#"              Equivalent to ["0", "1", "2", "3", "4", "5", "6", "7", "8"]
        [...]           An array of any nine literal strings

    width: <number>
    The width of the left image for horizontal 3-part images, the top image for
    vertical 3-part images, or the top left corner for 9-part images.

    height: <number>
    The height of the left image for horizontal 3-part images, the top image for
    vertical 3-part images, or the top left corner for 9-part images.

    centerWidth: <number>
    For a horizontal 3-part image that has a center slice width that is not 1.0,
    set this for the width of the center slice. If omitted, it defaults
    to 1.0. Not used for 9-part images.

    rightWidth: <number>
    For a horizontal 3-part image that has different left/right slice widths,
    or a 9-part image that has different left/right corner slice widths,
    set this for the width of the right slice. If omitted, the "width"
    value is used for left and right widths.

    centerHeight: <number>
    For a vertical 3-part image that has a center slice height that is not 1.0,
    set this for the height of the center slice. If omitted, it defaults
    to 1.0. Not used for 9-part images.

    bottomHeight: <number>
    For a vertical image that has different top/bottom slice heights,
    or a 9-part image that has different top/bottom corner slice heights,
    set this for the height of the bottom slice. If omitted, the "height"
    value is used for top and bottom heights.

    centerIsNil: <BOOL>
    For 9-part images, if the center image is nil, set this to YES.
    If omitted or set to NO, a center image must be provided.

    separator: <string>
    The separator to use between components of the pattern.
    If it is omitted, it defaults to "-".

    orientation: PatternIsHorizontal | PatternIsVertical
    The orientation of the image. This must be specified for 3-part images,
    it should NOT be specified for 9-part images.

    Using a pattern, all of this:

    bezelColor = PatternColor(
        [
            ["button-bezel-left.png", 4.0, 24.0],
            ["button-bezel-center.png", 1.0, 24.0],
            ["button-bezel-right.png", 4.0, 24.0]
        ],
        PatternIsHorizontal),

    highlightedBezelColor = PatternColor(
        [
            ["button-bezel-highlighted-left.png", 4.0, 24.0],
            ["button-bezel-highlighted-center.png", 1.0, 24.0],
            ["button-bezel-highlighted-right.png", 4.0, 24.0]
        ],
        PatternIsHorizontal),

    disabledBezelColor = PatternColor(
        [
            ["button-bezel-disabled-left.png", 4.0, 24.0],
            ["button-bezel-disabled-center.png", 1.0, 24.0],
            ["button-bezel-disabled-right.png", 4.0, 24.0]
        ],
        PatternIsHorizontal),

    defaultBezelColor = PatternColor(
        [
            ["default-button-bezel-left.png", 4.0, 24.0],
            ["default-button-bezel-center.png", 1.0, 24.0],
            ["default-button-bezel-right.png", 4.0, 24.0]
        ],
        PatternIsHorizontal),

    defaultHighlightedBezelColor = PatternColor(
        [
            ["default-button-bezel-highlighted-left.png", 4.0, 24.0],
            ["default-button-bezel-highlighted-center.png", 1.0, 24.0],
            ["default-button-bezel-highlighted-right.png", 4.0, 24.0]
        ],
        PatternIsHorizontal),

    defaultDisabledBezelColor = PatternColor(
        [
            ["default-button-bezel-disabled-left.png", 4.0, 24.0],
            ["default-button-bezel-disabled-center.png", 1.0, 24.0],
            ["default-button-bezel-disabled-right.png", 4.0, 24.0]
        ],
        PatternIsHorizontal)

    can be replaced with this:

    bezelColors = PatternColor(
        "{style}button-bezel{state}{position}.png",
        {
            styles: ["", "default"],
            states: ["", "highlighted", "disabled"],
            positions: "@",
            width: 4.0,
            height: 24.0,
            orientation: PatternIsHorizontal
        })

    Which would effectively create the following object:

    {
        "@":
        {
            "@": <ThreePartImage>:
            [
                ["button-bezel-left.png", 4.0, 24.0],
                ["button-bezel-center.png", 1.0, 24.0],
                ["button-bezel-right.png", 4.0, 24.0]
            ],
            "highlighted": <ThreePartImage>:
            [
                ["button-bezel-highlighted-left.png", 4.0, 24.0],
                ["button-bezel-highlighted-center.png", 1.0, 24.0],
                ["button-bezel-highlighted-right.png", 4.0, 24.0]
            ],
            "disabled": <ThreePartImage>:
            [
                ["button-bezel-disabled-left.png", 4.0, 24.0],
                ["button-bezel-disabled-center.png", 1.0, 24.0],
                ["button-bezel-disabled-right.png", 4.0, 24.0]
            ]
        },

        "default":
        {
            "@": <ThreePartImage>:
            [
                ["default-button-bezel-left.png", 4.0, 24.0],
                ["default-button-bezel-center.png", 1.0, 24.0],
                ["default-button-bezel-right.png", 4.0, 24.0]
            ],
            "highlighted": <ThreePartImage>:
            [
                ["default-button-bezel-highlighted-left.png", 4.0, 24.0],
                ["default-button-bezel-highlighted-center.png", 1.0, 24.0],
                ["default-button-bezel-highlighted-right.png", 4.0, 24.0]
            ],
            "disabled": <ThreePartImage>:
            [
                ["default-button-bezel-disabled-left.png", 4.0, 24.0],
                ["button-bezel-disabled-center.png", 1.0, 24.0],
                ["default-button-bezel-disabled-right.png", 4.0, 24.0]
            ]
        }
    }

    To reference empty names in the pattern color, use the key "@".
    So, for example, to reference the "default" style, "disabled" state,
    you would use the following expression:

    bezelColors["@"]["disabled"]

    To create a color with a three-part pattern image explicitly:
        CPColorWithImages(slices, orientation)

    where slices is an array of three [name, width, height{, bundle}] arrays,
    and orientation is CPColorPatternIsVertical or CPColorPatternIsHorizontal.

    To create a color with a nine-part pattern image explicitly:
        CPColorWithImages(slices);

    where slices is an array of nine [name, width, height{, bundle}] arrays.
*/
function CPColorWithImages()
{
    var slices = nil,
        numParts = 0,
        isVertical = false,
        imageFactory = CPImageInBundle,
        args = Array.prototype.slice.apply(arguments);

    if (typeof(args[args.length - 1]) === "function")
        imageFactory = args.pop();

    switch (args.length)
    {
        case 1:
            return imageFromSlices(args[0], isVertical, imageFactory);

        case 2:
            // New-style 3-part and 9-part images
            if (typeof(args[0]) === "string")
                return patternColorsFromPattern.call(this, args[0], args[1], imageFactory);

            return imageFromSlices(args[0], args[1], imageFactory);

        case 3:
        case 4:
            return [CPColor colorWithPatternImage:imageFactory(args[0], args[1], args[2], args[3])];

        default:
            throw("ERROR: Invalid argument count: " + args.length);
    }
}

var imageFromSlices = function(slices, isVertical, imageFactory)
{
    var imageSlices = [];

    for (var i = 0; i < slices.length; ++i)
    {
        var slice = slices[i];

        imageSlices.push(slice ? imageFactory(slice[0], slice[1], slice[2], slice[3]) : nil);
    }

    switch (slices.length)
    {
        case 3:
            return [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:imageSlices isVertical:isVertical]];

        case 9:
            return [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:imageSlices]];

        default:
            throw("ERROR: Invalid number of image slices: " + slices.length);
    }
};

var patternColorsFromPattern = function(pattern, attributes, imageFactory)
{
    if (pattern.match(/^.*\{[^}]+\}/))
    {
        var width = attributes["width"],
            height = attributes["height"],
            separator = attributes["separator"] || "-",
            orientation = attributes["orientation"],
            rightWidth,
            bottomHeight,
            centerWidthHeight,
            centerIsNil,
            numParts,
            isVertical;

        // positions are mandatory
        if (pattern.indexOf("{position}") < 0)
            throw("ERROR: Pattern strings must have a {position} placeholder (\"" + pattern + "\")");

        if (orientation === undefined)
        {
            numParts = 9;

            if (attributes["centerIsNil"] !== undefined)
                centerIsNil = attributes["centerIsNil"];
        }
        else
        {
            numParts = 3;
            isVertical = orientation === CPColorPatternIsVertical;

            if (isVertical)
            {
                if (attributes["centerHeight"])
                    centerWidthHeight = attributes["centerHeight"];
            }
            else
            {
                if (attributes["centerWidth"])
                    centerWidthHeight = attributes["centerWidth"];
            }
        }

        if (attributes["rightWidth"])
            rightWidth = attributes["rightWidth"];

        if (attributes["bottomHeight"])
            bottomHeight = attributes["bottomHeight"];

        var positions = attributes["positions"] || "@",
            states = nil,
            styles = nil;

        if (numParts === 3)
        {
            if (positions === "@")
            {
                if (isVertical)
                    positions = ["top", "center", "bottom"];
                else
                    positions = ["left", "center", "right"];
            }
            else if (positions === "#")
                positions = ["0", "1", "2"];
            else
                throw("ERROR: Invalid positions: " + positions)
        }
        else // numParts === 9
        {
            if (positions === "@" || positions === "abbrev")
                positions = ["top-left", "top", "top-right", "left", "center", "right", "bottom-left", "bottom", "bottom-right"];
            else if (positions === "full")
                positions = ["top-left", "top-center", "top-right", "center-left", "center-center", "center-right", "bottom-left", "bottom-center", "bottom-right"];
            else if (positions === "#")
                positions = ["0", "1", "2", "3", "4", "5", "6", "7", "8"];
            else
                throw("ERROR: Invalid positions: " + positions)
        }

        // states
        if (pattern.indexOf("{state}") >= 0)
        {
            states = attributes["states"];

            if (!states)
                throw("ERROR: {state} placeholder in the pattern (\"" + pattern + "\") but no states item in the attributes");
        }

        // styles
        if (pattern.indexOf("{style}") >= 0)
        {
            styles = attributes["styles"];

            if (!styles)
                throw("ERROR: {style} placeholder in the pattern (\"" + pattern + "\") but no styles item in the attributes");
        }

        // Now assemble the hierarchy
        var placeholder = "{position}",
            pos = pattern.indexOf(placeholder),
            i;

        for (i = 0; i < positions.length; ++i)
            positions[i] = pattern.replace(placeholder, pos === 0 ? positions[i] + separator : separator + positions[i]);

        var slices = positions,
            object = slices,
            key,
            sep;

        if (states)
        {
            placeholder = "{state}";
            pos = pattern.indexOf(placeholder);
            object = {};

            for (i = 0; i < states.length; ++i)
            {
                var state = states[i];
                key = state || "@";
                sep = state ? separator : "";

                object[key] = slices.slice(0);
                replacePlaceholderInArray(object[key], placeholder, pos === 0 ? state + sep : sep + state);
            }
        }

        if (styles)
        {
            placeholder = "{style}";
            pos = pattern.indexOf(placeholder);

            var styleObject = {};

            for (i = 0; i < styles.length; ++i)
            {
                var style = styles[i];
                key = style || "@";
                sep = style ? separator : "";

                if (states)
                {
                    styleObject[key] = cloneObject(object);
                    replacePlaceholderInObject(styleObject[key], placeholder, pos === 0 ? style + sep : sep + style);
                }
                else
                {
                    styleObject[key] = slices.slice(0);
                    replacePlaceholderInArray(styleObject[key], placeholder, pos === 0 ? style + sep : sep + style);
                }
            }

            object = styleObject;
        }

        if (styles || states)
        {
            if (numParts === 3)
                makeThreePartSlicesFromObject(object, width, height, centerWidthHeight, rightWidth, bottomHeight, isVertical);
            else
                makeNinePartSlicesFromObject(object, width, height, rightWidth, bottomHeight, centerIsNil);

            makeImagesFromObject(object, isVertical, imageFactory);
            return object;
        }
        else
        {
            if (numParts === 3)
                makeThreePartSlicesFromArray(object, width, height, centerWidthHeight, rightWidth, bottomHeight, isVertical);
            else
                makeNinePartSlicesFromArray(object, width, height, rightWidth, bottomHeight, centerIsNil);

            return imageFromSlices(object, isVertical, imageFactory);
        }
    }
    else
        throw("ERROR: No placeholders in slice pattern (\"" + pattern + "\")");
};

var replacePlaceholderInArray = function(array, find, replacement)
{
    for (var i = 0; i < array.length; ++i)
        array[i] = array[i].replace(find, replacement);
};

var replacePlaceholderInObject = function(object, find, replacement)
{
    for (var key in object)
        if (object.hasOwnProperty(key))
            if (object[key].constructor === Array)
                replacePlaceholderInArray(object[key], find, replacement);
            else
                replacePlaceholderInObject(object[key], find, replacement);
};

var cloneObject = function(object)
{
    var clone = {};

    for (var key in object)
        if (object.hasOwnProperty(key))
            if (object[key].constructor === Array)
                clone[key] = object[key].slice(0);
            else if (typeof(object[key]) === "object")
                clone[key] = cloneObject(object[key]);
            else
                clone[key] = object[key];

    return clone;
};

var makeThreePartSlicesFromObject = function(object, width, height, centerWidthHeight, rightWidth, bottomHeight, isVertical)
{
    for (var key in object)
        if (object.hasOwnProperty(key))
            if (object[key].constructor === Array)
                makeThreePartSlicesFromArray(object[key], width, height, centerWidthHeight, rightWidth, bottomHeight, isVertical);
            else // object
                makeThreePartSlicesFromObject(object[key], width, height, centerWidthHeight, rightWidth, bottomHeight, isVertical);
};

var makeThreePartSlicesFromArray = function(array, width, height, centerWidthHeight, rightWidth, bottomHeight, isVertical)
{
    array[0] = [array[0], width, height];

    if (isVertical)
    {
        array[1] = [array[1], width, centerWidthHeight ? centerWidthHeight : 1.0];
        array[2] = [array[2], width, bottomHeight ? bottomHeight : height];
    }
    else
    {
        array[1] = [array[1], centerWidthHeight ? centerWidthHeight : 1.0, height];
        array[2] = [array[2], rightWidth ? rightWidth : width, height];
    }
};

var makeNinePartSlicesFromObject = function(object, width, height, rightWidth, bottomHeight, centerIsNil)
{
    for (var key in object)
        if (object.hasOwnProperty(key))
            if (object[key].constructor === Array)
                makeNinePartSlicesFromArray(object[key], width, height, rightWidth, bottomHeight, centerIsNil);
            else // object
                makeNinePartSlicesFromObject(object[key], width, height, rightWidth, bottomHeight, centerIsNil);
};

var makeNinePartSlicesFromArray = function(array, width, height, rightWidth, bottomHeight, centerIsNil)
{
    rightWidth = rightWidth ? rightWidth : width;
    bottomHeight = bottomHeight ? bottomHeight : height;

    array[0] = [array[0], width, height];                // top-left
    array[1] = [array[1], 1.0, height];                  // top
    array[2] = [array[2], rightWidth, height];           // top-right
    array[3] = [array[3], width, 1.0];                   // left
    array[4] = centerIsNil ? nil : [array[4], 1.0, 1.0]; // center
    array[5] = [array[5], rightWidth, 1.0];              // right
    array[6] = [array[6], width, bottomHeight];          // bottom-left
    array[7] = [array[7], 1.0, bottomHeight];            // bottom
    array[8] = [array[8], rightWidth, bottomHeight];     // bottom-right
};

var makeImagesFromObject = function(object, isVertical, imageFactory)
{
    for (var key in object)
        if (object.hasOwnProperty(key))
            if (object[key].constructor === Array)
                object[key] = imageFromSlices(object[key], isVertical, imageFactory);
            else // object
                makeImagesFromObject(object[key], isVertical, imageFactory);
};

/// @endcond
