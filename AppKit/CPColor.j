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

@import "CPCompatibility.j"
@import "CPImage.j"


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
    cachedShadowColor,
    cachedClearColor;

/// @endcond

/*!
    @ingroup appkit

    \c CPColor can be used to represent color
    in an RGB or HSB model with an optional transparency value.</p>

    <p>It also provides some class helper methods that
    returns instances of commonly used colors.</p>
*/
@implementation CPColor : CPObject
{
    CPArray     _components;

    CPImage     _patternImage;
    CPString    _cssString;
}

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
+ (CPColor)colorWithHexString:(string)hex
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
    Returns a shadow looking color (RGBA=[0.0, 0.0, 0.0, 0.33])
*/

+ (CPColor)shadowColor
{
    if (!cachedShadowColor)
        cachedShadowColor = [[CPColor alloc] _initWithRGBA:[0.0, 0.0, 0.0, 1.0 / 3.0]];

    return cachedShadowColor;
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

+ (CPColor)alternateSelectedControlColor
{
    return [[CPColor alloc] _initWithRGBA:[0.22, 0.46, 0.84, 1.0]];
}

+ (CPColor)secondarySelectedControlColor
{
    return [[CPColor alloc] _initWithRGBA:[0.83, 0.83, 0.83, 1.0]];
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
    }

    return self;
}

- (void)_initCSSStringFromComponents
{
    var hasAlpha = CPFeatureIsCompatible(CPCSSRGBAFeature) && _components[3] != 1.0;

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

@end

/// @cond IGNORE
var CPColorComponentsKey    = @"CPColorComponentsKey",
    CPColorPatternImageKey  = @"CPColorPatternImageKey";
/// @endcond

@implementation CPColor (CPCoding)

/*!
    Initializes this color from the data archived in a coder.
    @param aCoder the coder from which the color will be loaded
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    if ([aCoder containsValueForKey:CPColorPatternImageKey])
        return [self _initWithPatternImage:[aCoder decodeObjectForKey:CPColorPatternImageKey]];

    return [self _initWithRGBA:[aCoder decodeObjectForKey:CPColorComponentsKey]];
}

/*!
    Archives this color into a coder.
    @param aCoder the coder into which the color will be archived.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    if (_patternImage)
        [aCoder encodeObject:_patternImage forKey:CPColorPatternImageKey];
    else
        [aCoder encodeObject:_components forKey:CPColorComponentsKey];
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
            numParts;

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
            isVertical = orientation === PatternIsVertical;

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
