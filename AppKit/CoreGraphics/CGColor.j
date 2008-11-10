/*
 * CGColor.j
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

//import "CGPattern.j"
@import "CGColorSpace.j"


// FIXME: Move this to Objective-J.js!!!
var CFTypeGlobalCount = 0;

function CFHashCode(aCFObject)
{
    if (!aCFObject.hash)
        aCFObject.hash = ++CFTypeGlobalCount;
        
    return aCFObject;
}

kCGColorWhite   = "kCGColorWhite";
kCGColorBlack   = "kCGColorBlack";
kCGColorClear   = "kCGColorClear";

var _CGColorMap = { };

function CGColorGetConstantColor(aColorName)
{
    alert("FIX ME");
}

/*!
    This function is for source compatability.    
*/
function CGColorRetain(aColor)
{
    return aColor;
}

/*!
    This function is for source compatability.    
*/
function CGColorRelease()
{
}

/*!
    Creates a new <objj>CGColor</objj>.
    @param aColorSpace the <objj>CGColorSpace</objj> of the color
    @param components the color's intensity values plus alpha
    @return CGColor the new color object
    @group CGColor
*/
function CGColorCreate(aColorSpace, components)
{
    if (!aColorSpace || !components)
        return NULL;

    var components = components.slice();
    
    CGColorSpaceStandardizeComponents(aColorSpace, components);
    
    var UID = CFHashCode(aColorSpace) + components.join("");
    
    if (_CGColorMap[UID])
        return _CGColorMap[UID];
    
    return _CGColorMap[UID] = { colorspace:aColorSpace, pattern:NULL, components:components };
}

/*!
    Creates a copy of a color... but not really. <objj>CGColor</objj>s
    are immutable, so to be efficient, this function will just
    return the same object that was passed in.
    @param aColor the <objj>CGColor</objj> to 'copy'
    @return CGColor the color copy
    @group CGColor
*/
function CGColorCreateCopy(aColor)
{
    // Colors should be treated as immutable, so don't mutate it!
    return aColor;
}

/*!
    Creates a gray color object.
    @param gray the value to use for the color intensities (<code>0.0-1.0</code>)
    @param alpha the gray's alpha value (<code>0.0-1.0</code>)
    @return CGColor the new gray color object
    @group CGColor
*/
function CGColorCreateGenericGray(gray, alpha)
{
    return CGColorCreate(0, [gray, alpha]);
}

/*!
    Creates an RGB color.
    @param red the red component (<code>0.0-1.0</code>)
    @param green the green component (<code>0.0-1.0</code>)
    @param blue the blue component (<code>0.0-1.0</code>)
    @param alpha the alpha component (<code>0.0-1.0</code>)
    @return CGColor the RGB based color
    @group CGColor
*/
function CGColorCreateGenericRGB(red, green, blue, alpha)
{
    return CGColorCreate(0, [red, green, blue, alpha]);
}

/*!
    Creates a CMYK color.
    @param cyan the cyan component (<code>0.0-1.0</code>)
    @param magenta the magenta component (<code>0.0-1.0</code>)
    @param yellow the yellow component (<code>0.0-1.0</code>)
    @param black the black component (<code>0.0-1.0</code>)
    @param alpha the alpha component (<code>0.0-1.0</code>)
    @return CGColor the CMYK based color
    @group CGColor
*/
function CGColorCreateGenericCMYK(cyan, magenta, yellow, black, alpha)
{
    return CGColorCreate(0, [cyan, magenta, yellow, black, alpha]);
}

/*!
    Creates a copy of the color with a specified alpha.
    @param aColor the color object to copy
    @param anAlpha the new alpha component for the copy (<code>0.0-1.0</code>)
    @return CGColor the new copy
    @group CGColor
*/
function CGColorCreateCopyWithAlpha(aColor, anAlpha)
{
    var components = aColor.components;
    
    if (!aColor || anAlpha == components[components.length - 1])
    	return aColor;

    if (aColor.pattern)
        var copy = CGColorCreateWithPattern(aColor.colorspace, aColor.pattern, components);
    else
        var copy = CGColorCreate(aColor.colorspace, components);

    copy.components[components.length - 1] = anAlpha;
    
    return copy;
}

/*!
    Creates a color using the specified pattern.
    @param aColorSpace the <objj>CGColorSpace</objj>
    @param aPattern the pattern image
    @param components the color components plus the alpha component
    @return CGColor the patterned color
    @group CGColor
*/
function CGColorCreateWithPattern(aColorSpace, aPattern, components)
{
    if (!aColorSpace || !aPattern || !components)
        return NULL;

    return { colorspace:aColorSpace, pattern:aPattern, components:components.slice() };
}

/*!
    Determines if two colors are the same.
    @param lhs the first <objj>CGColor</objj>
    @param rhs the second <objj>CGColor</objj>
    @return <code>YES</code> if the two colors are equal.
    <code>NO</code> otherwise.
*/
function CGColorEqualToColor(lhs, rhs)
{
    if (lhs == rhs)
        return true;
        
    if (!lhs || !rhs)
        return false;

    var lhsComponents = lhs.components,
        rhsComponents = rhs.components,
        lhsComponentCount = lhsComponents.length;

    if (lhsComponentCount != rhsComponents.length)
        return false;
    
    while (lhsComponentCount--) 
        if (lhsComponents[lhsComponentCount] != rhsComponents[lhsComponentCount])
            return false;
            
    if (lhs.pattern != rhs.pattern)
        return false;
        
    if (CGColorSpaceEqualToColorSpace(lhs.colorspace, rhs.colorspace))
        return false;
        
    return true;
}

/*!
    Returns the color's alpha component.
    @param aColor the color
    @return float the alpha component (<code>0.0-1.0</code>)
    @group CGColor
*/
function CGColorGetAlpha(aColor)
{
    var components = aColor.components;
    
    return components[components.length - 1];
}

/*!
    Returns the <objj>CGColor</objj>'s color space.
    @return <objj>CGColorSpace</objj>
    @group CGColor
*/
function CGColorGetColorSpace(aColor)
{
    return aColor.colorspace;
}

/*!
    Returns the <objj>CGColor</objj>'s components
    including the alpha in an array.
    @param aColor the color
    @return CPArray the color's components
*/
function CGColorGetComponents(aColor)
{
    return aColor.components;
}

/*!
    Returns the number of color components
    (including alpha) in the specified color.
    @param aColor the <objj>CGColor</objj>
    @return CPNumber the number of components
    @group CGColor
*/
function CGColorGetNumberOfComponents(aColor)
{
    return aColor.components.length;
}

/*!
    Gets the <objj>CGColor</objj>'s pattern.
    @param a <objj>CGColor</objj>
    @return CGPatternFIXME the pattern image
    @group CGColor
*/
function CGColorGetPattern(aColor)
{
    return aColor.pattern;
}

/*    var components = aColor.components;
    
    case :  _CGCSSForColor[CFGetHash(aColor)] = "rgba(" + ROUND(components[0] * 255.0) + ',' + ROUND(components[0] * 255.0) + ',' ROUND(components[0] * 255.0) + ',' + ROUND(components[0] * 255.0);
        	_cssString = (hasAlpha ? "rgba(" : "rgb(") + 
        	    parseInt(_components[0] * 255.0) + ", " + 
        	    parseInt(_components[1] * 255.0) + ", " + 
        	    parseInt(_components[2] * 255.0) + 
        	    (hasAlpha ?  (", " + _components[3]) : "") + ")";

function CFStringFromColor()
{

}
*/
