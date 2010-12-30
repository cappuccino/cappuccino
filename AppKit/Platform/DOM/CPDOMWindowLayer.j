/*
 * CPDOMWindowLayer.j
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

@import <Foundation/CPArray.j>
@import <Foundation/CPObject.j>


@implementation CPDOMWindowLayer : CPObject
{
    int         _level;
    CPArray     _windows;
    DOMElement  _DOMElement;
}

- (id)initWithLevel:(int)aLevel
{
    self = [super init];
    
    if (self)
    {
        _level = aLevel;
        
        _windows = [];
        
        _DOMElement = document.createElement("div");
        _DOMElement.style.position = "absolute";
        _DOMElement.style.top = "0px";
        _DOMElement.style.left = "0px";
        _DOMElement.style.width = "1px";
        _DOMElement.style.height = "1px";
    }
    
    return self;
}

- (int)level
{
    return _level;
}

- (void)removeWindow:(CPWindow)aWindow
{
    if (!aWindow._isVisible)
        return;

    var index = aWindow._index,
        count = _windows.length - 1;

    CPDOMDisplayServerRemoveChild(_DOMElement, aWindow._DOMElement);

    [_windows removeObjectAtIndex:aWindow._index];

    for (; index < count; ++index)
    {
        _windows[index]._index = index;
        _windows[index]._DOMElement.style.zIndex = index;
    }
    
    aWindow._isVisible = NO;
}

- (void)insertWindow:(CPWindow)aWindow atIndex:(unsigned)anIndex
{
    // We will have to adjust the z-index of all windows starting at this index.
    var count = [_windows count],
        zIndex = (anIndex == CPNotFound ? count : anIndex),
        isVisible = aWindow._isVisible;
    
    // If the window is already a resident of this layer, remove it.    
    if (isVisible)
    {
        zIndex = MIN(zIndex, aWindow._index);
        [_windows removeObjectAtIndex:aWindow._index];
    }
    else
        ++count;
    
    if (anIndex == CPNotFound || anIndex >= count)
        [_windows addObject:aWindow];
    else
        [_windows insertObject:aWindow atIndex:anIndex];
    
    // Adjust all the affected z-indexes.
    for (; zIndex < count; ++zIndex)
    {
        _windows[zIndex]._index = zIndex;
        _windows[zIndex]._DOMElement.style.zIndex = zIndex;
    }

    // If the window is not already a resident of this layer, add it.
    if (aWindow._DOMElement.parentNode !== _DOMElement)
    {
        CPDOMDisplayServerAppendChild(_DOMElement, aWindow._DOMElement);

        aWindow._isVisible = YES;
        
        if ([aWindow isFullBridge])
            [aWindow setFrame:[aWindow._platformWindow usableContentFrame]];
    }
}

- (CPArray)orderedWindows
{
    return _windows;
}

@end
