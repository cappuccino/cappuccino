/*
 * CGContextDIV.j
 * AppKit
 *
 * Created by Robert Grant.
 * Copyright 2015, plasq LLC.
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

@import "CGContext.j"

function CGDIVGraphicsContext()
{
    CGContext.call(this);
    
    this.DOMElement = document.createElement("div");

    this.hasPath = NO;
}

CGDIVGraphicsContext.prototype = Object.create(CGContext.prototype);

CGDIVGraphicsContext.prototype.constructor = CGDIVGraphicsContext;

function CGDIVGraphicsContextCreate()
{
    return new CGDIVGraphicsContext();
}

CGDIVGraphicsContext.prototype.clearRect = function(aRect)
{
    while (this.DOMElement.firstChild)
    {
        this.DOMElement.removeChild(this.DOMElement.firstChild);
    }
}

CGDIVGraphicsContext.prototype.fillRects = function(rects, count)
{
    if (arguments[1] === undefined)
        var count = rects.length;

    for (var i = 0; i < count; i++)
    {
        var rect = rects[i];
        
        var div = document.createElement("div");

        div.style.overflow = "hidden";
        div.style.position = "absolute";
        div.style.visibility = "visible";

        CPDOMDisplayServerSetStyleLeftTop(div, NULL, CGRectGetMinX(rect), CGRectGetMinY(rect));
        CPDOMDisplayServerSetStyleSize(div, CGRectGetWidth(rect), CGRectGetHeight(rect));
        
        div.style.backgroundColor = this.gState.fillStyle;
        this.DOMElement.appendChild(div);
    }
}
