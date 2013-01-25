/*
 * CGGradient.j
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

@import "CGColor.j"
@import "CGColorSpace.j"


kCGGradientDrawsBeforeStartLocation = 1 << 0;
kCGGradientDrawsAfterEndLocation    = 1 << 1;

function CGGradientCreateWithColorComponents(aColorSpace, components, locations, count)
{
    if (locations === undefined || locations === NULL)
    {
        var num_of_colors = components.length / 4,
            locations = [];

        for (var idx = 0; idx < num_of_colors; idx++)
            locations.push( idx / (num_of_colors - 1) );
    }

    if (count === undefined || count === NULL)
        count = locations.length;

    var colors = [];

    while (count--)
    {
        var offset = count * 4;
        colors[count] = CGColorCreate(aColorSpace, components.slice(offset, offset + 4));
    }

    return CGGradientCreateWithColors(aColorSpace, colors, locations);
}

function CGGradientCreateWithColors(aColorSpace, colors, locations)
{
    return { colorspace:aColorSpace, colors:colors, locations:locations };
}

function CGGradientRelease()
{
}

function CGGradientRetain(aGradient)
{
    return aGradient;
}
