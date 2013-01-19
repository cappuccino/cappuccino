/*
 * NSColor.j
 * nib2cib
 *
 * Portions based on NSColor.m (12/18/2008) in Cocotron (http://www.cocotron.org/)
 * Copyright (c) 2006-2007 Christopher J. W. Lloyd
 *
 * Created by Thomas Robinson.
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

@import <Foundation/CPData.j>
@import <AppKit/CPColor.j>


var NSUnknownColorSpaceModel    = -1,
    NSGrayColorSpaceModel       = 0,
    NSRGBColorSpaceModel        = 1,
    NSCMYKColorSpaceModel       = 2,
    NSLABColorSpaceModel        = 3,
    NSDeviceNColorSpaceModel    = 4,
    NSIndexedColorSpaceModel    = 5,
    NSPatternColorSpaceModel    = 6;

@implementation CPColor (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var colorSpace = [aCoder decodeIntForKey:@"NSColorSpace"],
        result;

    switch (colorSpace)
    {
        case 1: // [NSColor colorWithCalibratedRed:values[0] green:values[1] blue:values[2] alpha:values[3]];
        case 2: // [NSColor colorWithDeviceRed:values[0] green:values[1] blue:values[2] alpha:values[3]];

            // NSComponents data
            // NSCustomColorSpace NSColorSpace
            var rgb         = [aCoder decodeBytesForKey:@"NSRGB"],
                string      = CFData.bytesToString(rgb),
                components  = [string componentsSeparatedByString:@" "],
                values      = [0, 0, 0, 1];

            for (var i = 0; i < components.length && i < 4; i++)
                values[i] = [components[i] floatValue];

            result = [CPColor colorWithCalibratedRed:values[0] green:values[1] blue:values[2] alpha:values[3]];
            break;

        case 3: // [NSColor colorWithCalibratedWhite:values[0] alpha:values[1]];
        case 4: // [NSColor colorWithDeviceWhite:values[0] alpha:values[1]];

            var bytes       = [aCoder decodeBytesForKey:@"NSWhite"],
                string      = CFData.bytesToString(bytes),
                components  = [string componentsSeparatedByString:@" "],
                values      = [0, 1];

            for (var i = 0; i < components.length && i < 2; i++)
                values[i] = [components[i] floatValue];

            result = [CPColor colorWithCalibratedWhite:values[0] alpha:values[1]];
            break;

/*
        case 5:
            var cmyk        = [aCoder decodeBytesForKey:@"NSCMYK"],
                string      = CFData.bytesToString(rgb),
                components  = [string componentsSeparatedByString:@" "],
                values      = [0,0,0,0,1];

            for (var i = 0; i < components.length && i < 5; i++)
                values[i] = [components[i] floatValue];

            result = [CPColor colorWithDeviceCyan:values[0] magenta:values[1] yellow:values[2] black:values[3] alpha:values[4]];
            break;
*/

        case 6: // named color
            var catalogName = [aCoder decodeObjectForKey:@"NSCatalogName"],
                colorName   = [aCoder decodeObjectForKey:@"NSColorName"],
                color       = [aCoder decodeObjectForKey:@"NSColor"],
                result      = nil;

            if (catalogName === @"System")
            {
                switch (colorName)
                {
                    case "controlColor":
                        result = [CPColor colorWithCalibratedWhite:175.0 / 255.0 alpha:1.0];
                        break;

                    case "controlBackgroundColor":
                        result = [CPColor whiteColor];
                        break;

                    case "gridColor":
                        result = [CPColor colorWithCalibratedWhite:204.0 / 255.0 alpha:1.0];
                        break;

                    default:
                        result = color;
                }
            }
            else
                result = color;
            break;

        default:
            CPLog.warn(@"-[%@ %s] unknown color space %d", self.isa, _cmd, colorSpace);
            result  = [CPColor blackColor];
            break;
    }

    return result;
}

@end

@implementation NSColor : CPColor
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPColor class];
}

@end
