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

@import "CGColor.j"

@import "CPCompatibility.j"
@import "CPImage.j"

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
    Orientation to use with \c CPColorPattern for vertical patterns.
*/
CPColorPatternIsVertical = YES;

/*!
    Orientation to use with \c CPColorPattern for horizontal patterns.
*/
CPColorPatternIsHorizontal = NO;

/*!
    To create a simple color with a pattern image:

    <code>CPColorWithImages(name, width, height{, bundle})</code>

    To create a color with a three part pattern image:

    <code>CPColorWithImages(slices{, orientation})</code>

    where slices is an array of three [name, width, height{, bundle}] arrays,
    and orientation is \c CPColorPatternIsVertical or \ref CPColorPatternIsHorizontal.
    If orientatation is not passed, it defaults to \ref CPColorPatternIsHorizontal.

    To create a color with a nine part pattern image:

    <code>CPColorWithImages(slices);</code>

    where slices is an array of nine [name, width, height{, bundle}] arrays.
*/
function CPColorWithImages()
{
    if (arguments.length < 3)
    {
        var slices = arguments[0],
            imageSlices = [];

        for (var i = 0; i < slices.length; ++i)
        {
            var slice = slices[i];

            imageSlices.push(slice ? CPImageInBundle(slice[0], CGSizeMake(slice[1], slice[2]), slice[3]) : nil);
        }

        if (imageSlices.length === 3)
            return [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:imageSlices isVertical:arguments[1] || CPColorPatternIsHorizontal]];
        else
            return [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:imageSlices]];
    }
    else if (arguments.length === 3 || arguments.length === 4)
    {
        return [CPColor colorWithPatternImage:CPImageInBundle(arguments[0], CGSizeMake(arguments[1], arguments[2]), arguments[3])];
    }
    else
    {
        return nil;
    }
}

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
    Creates a new color in HSB space.

    @param hue the hue value
    @param saturation the saturation value
    @param brightness the brightness value

    @return the initialized color
*/
+ (CPColor)colorWithHue:(float)hue saturation:(float)saturation brightness:(float)brightness
{
    return [self colorWithHue:hue saturation:saturation brightness:brightness alpha:1.0];
}

+ (CPColor)colorWithHue:(float)hue saturation:(float)saturation brightness:(float)brightness alpha:(float)alpha
{
    if (saturation === 0.0)
        return [CPColor colorWithCalibratedWhite:brightness / 100.0 alpha:alpha];

    var f = hue % 60,
        p = (brightness * (100 - saturation)) / 10000,
        q = (brightness * (6000 - saturation * f)) / 600000,
        t = (brightness * (6000 - saturation * (60 -f))) / 600000,
        b =  brightness / 100.0;

    switch (FLOOR(hue / 60))
    {
        case 0: return [CPColor colorWithCalibratedRed:b green:t blue:p alpha:alpha];
        case 1: return [CPColor colorWithCalibratedRed:q green:b blue:p alpha:alpha];
        case 2: return [CPColor colorWithCalibratedRed:p green:b blue:t alpha:alpha];
        case 3: return [CPColor colorWithCalibratedRed:p green:q blue:b alpha:alpha];
        case 4: return [CPColor colorWithCalibratedRed:t green:p blue:b alpha:alpha];
        case 5: return [CPColor colorWithCalibratedRed:b green:p blue:q alpha:alpha];
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
    Returns an array with the HSB values for this color.
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
        ROUND(hue * 360.0),
        ROUND(saturation * 100.0),
        ROUND(brightness * 100.0)
    ];
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
            var imgDescription = [slices[i] description];

            description += imgDescription.replace(/^/mg, "        ") + ",\n";
        }

        description = description.substr(0, description.length - 2) + "\n    ]\n}";
    }
    else
        description += [patternImage description].replace(/^/mg, "    ") + "\n}";

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

/// @endcond
