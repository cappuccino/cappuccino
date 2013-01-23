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
    This function is for source compatibility.
*/
function CGColorRetain(aColor)
{
    return aColor;
}

/*!
    This function is for source compatibility.
*/
function CGColorRelease()
{
}

/*!
    Creates a new CGColor.
    @param aColorSpace the CGColorSpace of the color
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
    Creates a copy of a color... but not really. CGColors
    are immutable, so to be efficient, this function will just
    return the same object that was passed in.
    @param aColor the CGColor to 'copy'
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
    @param gray the value to use for the color intensities (\c 0.\c 0-\c 1.\c 0).
    @param alpha the gray's alpha value (\c 0.\c 0-\c 1.\c 0).
    @return CGColor the new gray color object
    @group CGColor
*/
function CGColorCreateGenericGray(gray, alpha)
{
    return CGColorCreate(CGColorSpaceCreateDeviceRGB(), [gray, gray, gray, alpha]);
}

/*!
    Creates an RGB color.
    @param red the red component (\c 0.\c 0-\c 1.\c 0)..
    @param green the green component (\c 0.\c 0-\c 1.\c 0).
    @param blue the blue component (\c 0.\c 0-\c 1.\c 0).
    @param alpha the alpha component (\c 0.\c 0-\c 1.\c 0).
    @return CGColor the RGB based color
    @group CGColor
*/
function CGColorCreateGenericRGB(red, green, blue, alpha)
{
    return CGColorCreate(CGColorSpaceCreateDeviceRGB(), [red, green, blue, alpha]);
}

/*!
    Creates a CMYK color.
    @param cyan the cyan component (\c 0.\c 0-\c 1.\c 0).
    @param magenta the magenta component (\c 0.\c 0-\c 1.\c 0).
    @param yellow the yellow component (\c 0.\c 0-\c 1.\c 0).
    @param black the black component (\c 0.\c 0-\c 1.\c 0).
    @param alpha the alpha component (\c 0.\c 0-\c 1.\c 0).
    @return CGColor the CMYK based color
    @group CGColor
*/
function CGColorCreateGenericCMYK(cyan, magenta, yellow, black, alpha)
{
    return CGColorCreate(CGColorSpaceCreateDeviceCMYK(),
                         [cyan, magenta, yellow, black, alpha]);
}

/*!
    Creates a copy of the color with a specified alpha.
    @param aColor the color object to copy
    @param anAlpha the new alpha component for the copy (\c 0.\c 0-\c 1.\c 0).
    @return CGColor the new copy
    @group CGColor
*/
function CGColorCreateCopyWithAlpha(aColor, anAlpha)
{
    if (!aColor)
        return aColor; // Avoid error null pointer in next line

    var components = aColor.components.slice();

    if (anAlpha == components[components.length - 1])
        return aColor;

    // set new alpha value now so that a potentially a new cache entry is made and
    // not that an existing cache entry is mutated.
    components[components.length - 1] = anAlpha;

    if (aColor.pattern)
        return CGColorCreateWithPattern(aColor.colorspace, aColor.pattern, components);
    else
        return CGColorCreate(aColor.colorspace, components);
}

/*!
    Creates a color using the specified pattern.
    @param aColorSpace the CGColorSpace
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
    @param lhs the first CGColor
    @param rhs the second CGColor
    @return \c YES if the two colors are equal.
    \c NO otherwise.
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
    @return float the alpha component (\c 0.\c 0-\c 1.\c 0).
    @group CGColor
*/
function CGColorGetAlpha(aColor)
{
    var components = aColor.components;

    return components[components.length - 1];
}

/*!
    Returns the CGColor's color space.
    @return CGColorSpace
    @group CGColor
*/
function CGColorGetColorSpace(aColor)
{
    return aColor.colorspace;
}

/*!
    Returns the CGColor's components
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
    @param aColor the CGColor
    @return CPNumber the number of components
    @group CGColor
*/
function CGColorGetNumberOfComponents(aColor)
{
    return aColor.components.length;
}

/*!
    Gets the CGColor's pattern.
    @param a CGColor
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
