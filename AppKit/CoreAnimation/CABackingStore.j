/*
 * CABackingStore.j
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

@import "CGGeometry.j"
@import "CPCompatibility.j"

#define PIXEL(pixels) pixels + "px";


function CABackingStoreGetContext(aBackingStore)
{
    return aBackingStore.context;
}

if (CPFeatureIsCompatible(CPHTMLCanvasFeature))
{

CABackingStoreCreate = function()
{
    var DOMElement = document.createElement("canvas");
    
    DOMElement.style.position = "absolute";
    
    // FIXME: Consolidate drawImage to support this.
    return { context:DOMElement.getContext("2d"), buffer:DOMElement, _image:DOMElement };
}

CABackingStoreSetSize = function(aBackingStore, aSize)
{
    var buffer = aBackingStore.buffer;
    
    buffer.width = aSize.width;
    buffer.height = aSize.height;
    buffer.style.width = PIXEL(aSize.width);
    buffer.style.height = PIXEL(aSize.height);
}
}
else
{

CABackingStoreCreate = function()
{
    var context = CGBitmapGraphicsContextCreate();
    
    context.buffer = "";
    
    return { context:context };
}

CABackingStoreSetSize = function(aBackingStore, aSize)
{
}

}