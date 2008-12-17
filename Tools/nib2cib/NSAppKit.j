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
@import "NSColor.j"
@import "NSColorWell.j"
@import "NSControl.j"
@import "NSCustomObject.j"
@import "NSCustomView.j"
@import "NSFont.j"
@import "NSIBObjectData.j"
@import "NSMenu.j"
@import "NSMenuItem.j"
@import "NSNibConnector.j"
@import "NSPopUpButton.j"
@import "NSResponder.j"
@import "NSSegmentedControl.j"
@import "NSSlider.j"
@import "NSSplitView.j"
@import "NSTabView.j"
@import "NSTabViewItem.j"
@import "NSTextField.j"
@import "NSToolbar.j"
@import "NSView.j"
@import "NSWindowTemplate.j"
@import "WebView.j"


function CP_NSMapClassName(aClassName)
{
    switch (aClassName)
    {
        case @"NSApplication":  return @"CPApplication";
        case @"NSObject":       return @"CPObject";
        case @"NSView":         return @"CPView";
        case @"NSWindow":       return @"CPWindow";
        
        default:                CPLog.warn("No class name mapping for \"" + aClassName + "\"");
    }

    return aClassName;
}
