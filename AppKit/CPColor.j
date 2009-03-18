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


var _redComponent        = 0,
    _greenComponent      = 1,
    _blueComponent       = 2,
    _alphaCompnent       = 3;
    
var _hueComponent        = 0,
    _saturationComponent = 1,
    _brightnessComponent = 2;

/*! @code CPColor

    <code>CPColor</code> can be used to represent color
    in an RGB or HSB model with an optional transparency value.</p>

    <p>It also provides some class helper methods that
    returns instances of commonly used colors.</p>

    <p>The class does not have a <code>set:</code> method
    like NextStep based frameworks to change the color of
    the current context. To change the color of the current
    context, use CGContextSetFillColor().
*/
@implementation CPColor : CPObject
{
    CPArray     _components;

    CPImage     _patternImage;
    CPString    _cssString;    
}

/*!
    Creates a color in the RGB color space, with an alpha value.
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
    return [[CPColor alloc] _initWithRGBA:[red, green, blue, alpha]];
}

/*!
    Creates a new color object with <code>white</code> for the RGB components.
    For the alpha component, a value of 1.0 is opaque, and 0.0 means completely transparent.
    
    @param white a float between 0.0 and 1.0
    @param alpha the alpha component between 0.0 and 1.0
    
    @return a color initialized to the values specified
*/
+ (CPColor)colorWithCalibratedWhite:(float)white alpha:(float)alpha
{
    return [[CPColor alloc] _initWithRGBA:[white, white, white, alpha]];
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
    if(saturation == 0.0)
        return [CPColor colorWithCalibratedWhite: brightness/100.0 alpha: 1.0];
    
    var f = hue % 60,
        p = (brightness * (100 - saturation)) / 10000,
        q = (brightness * (6000 - saturation * f)) / 600000,
        t = (brightness * (6000 - saturation * (60 -f))) / 600000,
        b =  brightness / 100.0;
        
    switch(FLOOR(hue / 60))
    {
        case 0: return [CPColor colorWithCalibratedRed: b green: t blue: p alpha: 1.0];
        case 1: return [CPColor colorWithCalibratedRed: q green: b blue: p alpha: 1.0];
        case 2: return [CPColor colorWithCalibratedRed: p green: b blue: t alpha: 1.0];
        case 3: return [CPColor colorWithCalibratedRed: p green: q blue: b alpha: 1.0];
        case 4: return [CPColor colorWithCalibratedRed: t green: p blue: b alpha: 1.0];
        case 5: return [CPColor colorWithCalibratedRed: b green: p blue: q alpha: 1.0];            
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
    return [[CPColor alloc] _initWithRGBA: hexToRGB(hex)];
}

/*!
    Returns a black color object. (RGBA=[0.0, 0.0, 0.0, 1.0])
*/
+ (CPColor)blackColor
{
    return [[CPColor alloc] _initWithRGBA:[0.0, 0.0, 0.0, 1.0]];
}

/*!
    Returns a blue color object. (RGBA=[0.0, 0.0, 1.0, 1.0])
*/
+ (CPColor)blueColor
{
    return [[CPColor alloc] _initWithRGBA:[0.0, 0.0, 1.0, 1.0]];
}

/*!
    Returns a dark gray color object. (RGBA=[0.33 ,0.33, 0.33, 1.0])
*/
+ (CPColor)darkGrayColor
{
    return [CPColor colorWithCalibratedWhite:1.0 / 3.0 alpha:1.0];
}

/*!
    Returns a gray color object. (RGBA=[0.5, 0.5, 0.5, 1.0])
*/
+ (CPColor)grayColor
{
    return [CPColor colorWithCalibratedWhite:0.5 alpha: 1.0];
}

/*!
    Returns a green color object. (RGBA=[0.0, 1.0, 0.0, 1.0])
*/
+ (CPColor)greenColor
{
    return [[CPColor alloc] _initWithRGBA:[0.0, 1.0, 0.0, 1.0]];
}

/*!
    Returns a light gray color object (RGBA=[0.66, 0.66, 0.66, 1.0])
*/
+ (CPColor)lightGrayColor
{
    return [CPColor colorWithCalibratedWhite:2.0 / 3.0 alpha:1.0];
}

/*!
    Returns a red color object (RGBA=[1.0, 0.0, 0.0, 1.0])
*/
+ (CPColor)redColor
{
    return [[CPColor alloc] _initWithRGBA:[1.0, 0.0, 0.0, 1.0]];
}

/*!
    Returns a white color object (RGBA=[1.0, 1.0, 1.0, 1.0])
*/
+ (CPColor)whiteColor
{
    return [[CPColor alloc] _initWithRGBA:[1.0, 1.0, 1.0, 1.0]];
}

/*!
    Returns a yellow color object (RGBA=[1.0, 1.0, 0.0, 1.0])
*/
+ (CPColor)yellowColor
{
    return [[CPColor alloc] _initWithRGBA:[1.0, 1.0, 0.0, 1.0]];
}

/*!
    Returns a shadow looking color (RGBA=[0.0, 0.0, 0.0, 0.33])
*/
+ (CPColor)shadowColor
{
    return [[CPColor alloc] _initWithRGBA:[0.0, 0.0, 0.0, 1.0 / 3.0]];
}

/*!
    Creates a color using a tile pattern with <code>anImage</code>
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
    if(aString.indexOf("rgb") == CPNotFound)
        return nil;
        
    self = [super init];
    
    var startingIndex = aString.indexOf("(");
    var parts = aString.substring(startingIndex+1).split(',');
    
    _components = [
        parseInt(parts[0], 10) / 255.0,
        parseInt(parts[1], 10) / 255.0,
        parseInt(parts[2], 10) / 255.0,
        parts[3] ? parseInt(parts[3], 10) / 255.0 : 1.0        
    ]
    
    _cssString = aString;
    
    return self;
}

/* @ignore */
- (id)_initWithRGBA:(CPArray)components
{
    self = [super init];
    
    if (self)
    {
        _components = components;
        
		if (!CPFeatureIsCompatible(CPCSSRGBAFeature) && _components[3] != 1.0 && window.Base64 && window.CRC32)
		{
			var bytes = [0x89,0x50,0x4e,0x47,0xd,0xa,0x1a,0xa,0x0,0x0,0x0,0xd,0x49,0x48,0x44,0x52,0x0,0x0,0x0,0x1,0x0,0x0,0x0,0x1,0x8,0x3,0x0,0x0,0x0,0x28,0xcb,0x34,0xbb,0x0,0x0,0x3,0x0,0x50,0x4c,0x54,0x45,0xff,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x17,0x89,0x99,0x55,0x0,0x0,0x0,0x1,0x74,0x52,0x4e,0x53,0x0,0x40,0xe6,0xd8,0x66,0x0,0x0,0x0,0x10,0x49,0x44,0x41,0x54,0x78,0xda,0x62,0x60,0x0,0x0,0x0,0x0,0xff,0xff,0x3,0x0,0x0,0x2,0x0,0x1,0x24,0x7f,0x24,0xf1,0x0,0x0,0x0,0x0,0x49,0x45,0x4e,0x44,0xae,0x42,0x60,0x82,0xff];
			var r_off = 41;
			var g_off = 42;
			var b_off = 43;
			var a_off = 821;
			var plte_crc_off = 809;
			var trns_crc_off = 822;
			var plte_type_off = 37;
			var trns_type_off = 817;
			
			bytes[r_off] = Math.round(_components[0]*255);
			bytes[g_off] = Math.round(_components[1]*255);
			bytes[b_off] = Math.round(_components[2]*255);
			bytes[a_off] = Math.round(_components[3]*255);
            
			// calculate new CRCs
			var new_plte_crc = integerToBytes(CRC32.getCRC(bytes, plte_type_off, 4+768), 4);
			var new_trns_crc = integerToBytes(CRC32.getCRC(bytes, trns_type_off, 4+1), 4);
            
			// overwrite old CRCs with new ones
			for (var i = 0; i < 4; i++)
			{
				bytes[plte_crc_off+i] = new_plte_crc[i];
				bytes[trns_crc_off+i] = new_trns_crc[i];
			}
            
			// Base64 encode, strip whitespace and build data URL
			var base64image = Base64.encode(bytes); //.replace(/[\s]/g, "");
			
			_cssString = "url(\"data:image/png;base64," + base64image + "\")";
		}
		else
		{
        	var hasAlpha = CPFeatureIsCompatible(CPCSSRGBAFeature) && _components[3] != 1.0;
        		
        	_cssString = (hasAlpha ? "rgba(" : "rgb(") + 
        	    parseInt(_components[0] * 255.0) + ", " + 
        	    parseInt(_components[1] * 255.0) + ", " + 
        	    parseInt(_components[2] * 255.0) + 
        	    (hasAlpha ?  (", " + _components[3]) : "") + ")";
		}
    }
    return self;
}

/* @ignore */
- (id)_initWithPatternImage:(CPImage)anImage
{
    self = [super init];
    
    if (self)
    {
        _patternImage = anImage;
        _cssString = "url(\"" + _patternImage._filename + "\")";
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
    if(saturation == 0)
        hue = 0;
    else
    {
        var rr = (max - red) / delta;
        var gr = (max - green) / delta;
        var br = (max - blue) / delta;
        
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
    return rgbToHex([self redComponent], [self greenComponent], [self blueComponent])
}

- (CPString)description
{
    return [super description]+" "+[self cssString];
}

@end

var CPColorComponentsKey    = @"CPColorComponentsKey",
    CPColorPatternImageKey  = @"CPColorPatternImageKey";

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

var hexCharacters = "0123456789ABCDEF";

/*!
    Used for the CPColor <code>colorWithHexString:</code> implementation
    @ignore
    @class CPColor
    @return an array of rgb components
*/
function hexToRGB(hex) 
{
    if ( hex.length == 3 )
        hex = hex.charAt(0) + hex.charAt(0) + hex.charAt(1) + hex.charAt(1) + hex.charAt(2) + hex.charAt(2);
    if(hex.length != 6)
        return null;

    hex = hex.toUpperCase();

    for(var i=0; i<hex.length; i++)
        if(hexCharacters.indexOf(hex.charAt(i)) == -1)
            return null;
            
    var red   = (hexCharacters.indexOf(hex.charAt(0)) * 16 + hexCharacters.indexOf(hex.charAt(1))) / 255.0;
    var green = (hexCharacters.indexOf(hex.charAt(2)) * 16 + hexCharacters.indexOf(hex.charAt(3))) / 255.0;
    var blue  = (hexCharacters.indexOf(hex.charAt(4)) * 16 + hexCharacters.indexOf(hex.charAt(5))) / 255.0;
    
    return [red, green, blue, 1.0];
}

function integerToBytes(integer, length) {
	if (!length)
		length = (integer == 0) ? 1 : Math.round((Math.log(integer)/Math.log(2))/8+0.5);
		
	var bytes = new Array(length);
	for (var i = length-1; i >= 0; i--) {
		bytes[i] = integer & 255;
		integer = integer >> 8
	}
	return bytes;
}

function rgbToHex(r,g,b) {
    return byteToHex(r) + byteToHex(g) + byteToHex(b);
}

function byteToHex(n) {
    if (!n || isNaN(n)) return "00";
    n = ROUND(MIN(255,MAX(0,256*n)));
    return  hexCharacters.charAt((n - n % 16) / 16) +
            hexCharacters.charAt(n % 16);
}

// Toll-Free bridge CPColor to CGColor.
//CGColor.prototype.isa = CPColor;
//[CPColor initialize];

//http://dev.mootools.net/browser/trunk/Source/Utilities/Color.js?rev=1184
