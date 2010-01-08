/*
 * CPPlatform+DOM.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2010, 280 North, Inc.
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

var DOMSafeElement              = NULL,
    screenNeedsInitialization   = [CPPlatform isBrowser];

@implementation CPPlatform (DOM)

+ (DOMElement)DOMSafeElement
{
    if (!DOMSafeElement)
    {
        DOMSafeElement = document.createElement("div");

        DOMSafeElement.style.position = "absolute";
        DOMSafeElement.style.left = "-100000px";
        DOMSafeElement.style.top = "-100000px";
        DOMSafeElement.style.overflow = "visible";

        document.body.appendChild(DOMSafeElement);
    }

    return DOMSafeElement;
}

+ (void)initializeScreenIfNecessary
{
    if (!screenNeedsInitialization)
        return;

    screenNeedsInitialization = NO;

    var body = document.body;

    body.removeChild(DOMSafeElement);

    body.innerHTML = ""; // Get rid of anything that might be lingering in the body element.
    body.style.overflow = "hidden";

    body.appendChild(DOMSafeElement);

    if (document.documentElement)
        document.documentElement.style.overflow = "hidden";
}

@end
