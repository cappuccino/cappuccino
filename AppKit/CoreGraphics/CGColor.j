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
import "CGColorSpace.j"

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

function CGColorRetain(aColor)
{
    return aColor;
}

function CGColorRelease()
{
}

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

function CGColorCreateCopy(aColor)
{
    // Colors should be treated as immutable, so don't mutate it!
    return aColor;
}

function CGColorCreateGenericGray(gray, alpha)
{
    return CGColorCreate(0, [gray, alpha]);
}

function CGColorCreateGenericRGB(red, green, blue, alpha)
{
    return CGColorCreate(0, [red, green, blue, alpha]);
}

function CGColorCreateGenericCMYK(cyan, magenta, yellow, black, alpha)
{
    return CGColorCreate(0, [cyan, magenta, yellow, black, alpha]);
}

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

function CGColorCreateWithPattern(aColorSpace, aPattern, components)
{
    if (!aColorSpace || !aPattern || !components)
        return NULL;

    return { colorspace:aColorSpace, pattern:aPattern, components:components.slice() };
}

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

function CGColorGetAlpha(aColor)
{
    var components = aColor.components;
    
    return components[components.length - 1];
}

function CGColorGetColorSpace(aColor)
{
    return aColor.colorspace;
}

function CGColorGetComponents(aColor)
{
    return aColor.components;
}

function CGColorGetNumberOfComponents(aColor)
{
    return aColor.components.length;
}

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
