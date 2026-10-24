/*
 * CGColorSpace.j
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

@typedef CGColorSpace

kCGColorSpaceModelUnknown       = -1;
kCGColorSpaceModelMonochrome    = 0;
kCGColorSpaceModelRGB           = 1;
kCGColorSpaceModelCMYK          = 2;
kCGColorSpaceModelLab           = 3;
kCGColorSpaceModelDeviceN       = 4;
kCGColorSpaceModelIndexed       = 5;
kCGColorSpaceModelPattern       = 6;

/*
    @global
    @group CGColorSpace
*/
kCGColorSpaceGenericGray        = "CGColorSpaceGenericGray";
/*
    @global
    @group CGColorSpace
*/
kCGColorSpaceGenericRGB         = "CGColorSpaceGenericRGB";
/*
    @global
    @group CGColorSpace
*/
kCGColorSpaceGenericCMYK        = "CGColorSpaceGenericCMYK";
/*
    @global
    @group CGColorSpace
*/
kCGColorSpaceGenericRGBLinear   = "CGColorSpaceGenericRGBLinear";
/*
    @global
    @group CGColorSpace
*/
kCGColorSpaceGenericRGBHDR      = "CGColorSpaceGenericRGBHDR";
/*
    @global
    @group CGColorSpace
*/
kCGColorSpaceAdobeRGB1998       = "CGColorSpaceAdobeRGB1998";
/*
    @global
    @group CGColorSpace
*/
kCGColorSpaceSRGB               = "CGColorSpaceSRGB";

var _CGNamedColorSpaces         = {};

function _CGColorSpaceCreateWithModel(aModel, aComponentCount, aBaseColorSpace)
{
    return { model:aModel, count:aComponentCount, base:aBaseColorSpace };
}

function CGColorSpaceCreateCalibratedGray(aWhitePoint, aBlackPoint, gamma)
{
    return _CGColorSpaceCreateWithModel(kCGColorSpaceModelMonochrome, 1, NULL);
}

function CGColorSpaceCreateCalibratedRGB(aWhitePoint, aBlackPoint, gamma)
{
    return _CGColorSpaceCreateWithModel(kCGColorSpaceModelRGB, 1, NULL);
}

function CGColorSpaceCreateICCBased(aComponentCount, range, profile, alternate)
{
    // FIXME: Do we need to support this?
    return NULL;
}

function CGColorSpaceCreateLab(aWhitePoint, aBlackPoint, aRange)
{
    // FIXME: Do we need to support this?
    return NULL;
}

function CGColorSpaceCreateDeviceCMYK()
{
    return CGColorSpaceCreateWithName(kCGColorSpaceGenericCMYK);
}

function CGColorSpaceCreateDeviceGray()
{
    return CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
}

function CGColorSpaceCreateDeviceRGB()
{
    return CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
}

function CGColorSpaceCreateWithPlatformColorSpace()
{
    // FIXME: This for sure we don't need.
    return NULL;
}

function CGColorSpaceCreateIndexed(aBaseColorSpace, lastIndex, colorTable)
{
    // FIXME: Do we need to support this?
    return NULL;
}

function CGColorSpaceCreatePattern(aBaseColorSpace)
{
    if (aBaseColorSpace)
        return _CGColorSpaceCreateWithModel(kCGColorSpaceModelPattern, aBaseColorSpace.count, aBaseColorSpace);

    return _CGColorSpaceCreateWithModel(kCGColorSpaceModelPattern, 0, NULL);
}

function CGColorSpaceCreateWithName(aName)
{
    var colorSpace = _CGNamedColorSpaces[aName];

    if (colorSpace)
        return colorSpace;

    switch (aName)
    {
        case kCGColorSpaceGenericGray:
            return _CGNamedColorSpaces[aName] = _CGColorSpaceCreateWithModel(kCGColorSpaceModelMonochrome, 1, NULL);

        case kCGColorSpaceGenericRGB:
            return _CGNamedColorSpaces[aName] = _CGColorSpaceCreateWithModel(kCGColorSpaceModelRGB, 3, NULL);

        case kCGColorSpaceGenericCMYK:
            return _CGNamedColorSpaces[aName] = _CGColorSpaceCreateWithModel(kCGColorSpaceModelCMYK, 4, NULL);

        case kCGColorSpaceGenericRGBLinear:
            return _CGNamedColorSpaces[aName] = _CGColorSpaceCreateWithModel(kCGColorSpaceModelRGB, 3, NULL);

        case kCGColorSpaceGenericRGBHDR:
            return _CGNamedColorSpaces[aName] = _CGColorSpaceCreateWithModel(kCGColorSpaceModelRGB, 3, NULL);

        case kCGColorSpaceAdobeRGB1998:
            return _CGNamedColorSpaces[aName] = _CGColorSpaceCreateWithModel(kCGColorSpaceModelRGB, 3, NULL);

        case kCGColorSpaceSRGB:
            return _CGNamedColorSpaces[aName] = _CGColorSpaceCreateWithModel(kCGColorSpaceModelRGB, 3, NULL);
    }

    return NULL;
}

// Getting Information About Color Spaces

function CGColorSpaceCopyICCProfile(aColorSpace)
{
    return NULL;
}

function CGColorSpaceGetNumberOfComponents(aColorSpace)
{
    return aColorSpace.count;
}

function CGColorSpaceGetTypeID(aColorSpace)
{
}

function CGColorSpaceGetModel(aColorSpace)
{
    return aColorSpace.model;
}

function CGColorSpaceGetBaseColorSpace(aColorSpace)
{
}

function CGColorSpaceGetColorTableCount(aColorSpace)
{
}

function CGColorSpaceGetColorTable(aColorSpace)
{
}

// Retaining and Releasing Color Spaces

function CGColorSpaceRelease(aColorSpace)
{
}

function CGColorSpaceRetain(aColorSpace)
{
    return aColorSpace;
}

// FIXME: We should refer to some default values.
function CGColorSpaceStandardizeComponents(aColorSpace, components)
{
    var count = aColorSpace.count;

    // Standardize the alpha value.  We allow the alpha value to have a
    // higher precision than other components since it is not ultimately
    // bound to 256 bits like RGB.
    if (count > components.length)
    {
        components[count] = 1;
        return;
    }

    var component = components[count];

    if (component < 0)
        components[count] = 0;
    else if (component > 1)
        components[count] = 1;
    else
        components[count] = ROUND(component * 1000) / 1000;

    if (aColorSpace.base)
        aColorSpace = aColorSpace.base;

    switch (aColorSpace.model)
    {
        case kCGColorSpaceModelMonochrome:
        case kCGColorSpaceModelRGB:
        case kCGColorSpaceModelCMYK:
        case kCGColorSpaceModelDeviceN:
            while (count--)
            {
                var standardizingComponent = components[count];

                if (standardizingComponent < 0)
                    components[count] = 0;
                else if (standardizingComponent > 1)
                    components[count] = 1;
                else
                    components[count] = ROUND(standardizingComponent * 255) / 255;
            }
            break;

        // We don't currently support these color spaces.
        case kCGColorSpaceModelIndexed:
        case kCGColorSpaceModelLab:
        case kCGColorSpaceModelPattern:
            break;
    }
}
