/*
 * CPPlatformString.j
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

@import <Foundation/CPObject.j>

#include "../CoreGraphics/CGGeometry.h"
#include "Platform.h"


#if PLATFORM(DOM)
var DOMIFrameElement    = nil,
    DOMSpanElement      = nil,
    DefaultFont         = nil;
#endif

@implementation CPPlatformString : CPObject
{
}

+ (void)bootstrap
{
#if PLATFORM(DOM)
    var DOMSafeElement = [CPPlatform DOMSafeElement];

    DOMIFrameElement = document.createElement("iframe");
    
    DOMIFrameElement.name = name = "iframe_" + FLOOR(RAND() * 10000);
    DOMIFrameElement.style.position = "absolute";
    DOMIFrameElement.style.left = "-100px";
    DOMIFrameElement.style.top = "-100px";
    DOMIFrameElement.style.width = "1px";
    DOMIFrameElement.style.height = "1px";
    DOMIFrameElement.style.borderWidth = "0px";
    DOMIFrameElement.style.background = "blue";
    DOMIFrameElement.style.overflow = "hidden";
    DOMIFrameElement.style.zIndex = 100000000000;

    DOMSafeElement.appendChild(DOMIFrameElement);

    var DOMIFrameDocument = (DOMIFrameElement.contentDocument || DOMIFrameElement.contentWindow.document);

    DOMIFrameDocument.write("<html><head></head><body></body></html>");
    DOMIFrameDocument.close();

    DOMSpanElement = DOMIFrameDocument.createElement("span");

    DOMSpanElement.style.position = "absolute";
    DOMSpanElement.style.whiteSpace = "pre";
    DOMSpanElement.style.visibility = "visible";
    DOMSpanElement.style.padding = "0px";
    DOMSpanElement.style.margin = "0px";
    DOMSpanElement.style.background = "red";

    DOMIFrameDocument.body.appendChild(DOMSpanElement);
#endif
}

+ (CGSize)sizeOfString:(CPString)aString withFont:(CPFont)aFont forWidth:(float)aWidth
{
#if PLATFORM(DOM)
    if (!aFont)
    {
        if (!DefaultFont)
            DefaultFont = [CPFont systemFontOfSize:12.0];

        aFont = DefaultFont;
    }

    var style = DOMSpanElement.style;

    if (aWidth === NULL)
    {
        style.width = "";
        style.whiteSpace = "pre";
    }
    
    else
    {
        style.width = ROUND(aWidth) + "px";
        
        if (document.attachEvent)
            style.wordWrap = "break-word";
        
        else
        {
            style.whiteSpace = "-o-pre-wrap";
            style.whiteSpace = "-pre-wrap";
            style.whiteSpace = "-moz-pre-wrap";
            style.whiteSpace = "pre-wrap";
        }
    }

    style.font = [aFont cssString];

    if (CPFeatureIsCompatible(CPJavascriptInnerTextFeature))
        DOMSpanElement.innerText = aString;

    else if (CPFeatureIsCompatible(CPJavascriptTextContentFeature))
        DOMSpanElement.textContent = aString;

    return _CGSizeMake(DOMSpanElement.clientWidth, DOMSpanElement.clientHeight);
#else
    return _CGSizeMakeZero();
#endif
}

@end
