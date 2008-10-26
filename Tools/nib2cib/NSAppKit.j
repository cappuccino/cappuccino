/*
 * NSAppKit.j
 * nib2cib
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

@import "NSButton.j"
@import "NSCell.j"
@import "NSControl.j"
@import "NSCustomObject.j"
@import "NSCustomView.j"
@import "NSFont.j"
@import "NSIBObjectData.j"
print("1");
@import "NSNibConnector.j"
print("1");
@import "NSResponder.j"
print("1");
@import "NSSlider.j"
print("1");
@import "NSView.j"
print("1");
@import "NSWindowTemplate.j"
print("1");
@import "NSSplitView.j"
print("1");

function CP_NSMapClassName(aClassName)
{
    if (aClassName == @"NSView")
        return "CPView";

    if (aClassName == @"NSWindow")
        return @"CPWindow";
    
    return aClassName;
}
