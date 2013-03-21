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
        zIndex = (anIndex === CPNotFound ? count : anIndex),
        isVisible = aWindow._isVisible;

    // If the window is already a resident of this layer, remove it.
    if (isVisible)
    {
        // Adjust the z-index to start at the window being inserted
        zIndex = MIN(zIndex, aWindow._index);

        // If the window being inserted is below the insertion index,
        // the index will be one less after we remove the window below.
        if (aWindow._index < anIndex)
            --anIndex;

        [_windows removeObjectAtIndex:aWindow._index];
    }
    else
        ++count;

    if (anIndex === CPNotFound || anIndex >= count)
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

        if ([aWindow isFullPlatformWindow])
            [aWindow setFrame:[aWindow._platformWindow usableContentFrame]];
    }
}

- (CPArray)orderedWindows
{
    return _windows;
}

/*!
    Places \c aWindow within an element that clips it to the global rect \c clipRect.

    NOTE: This is only meant for temporary usage during animation and should be balanced
    with a call to removeClipForWindow:. No attempt is made to make the clipping element follow
    changes to the window.
*/
- (void)clipWindow:(CPWindow)aWindow toRect:(CGRect)clipRect
{
    // First check to see if the window is already clipped.
    // If so, just update its rect.
    var windowElement = aWindow._DOMElement,
        clip = document.createElement("div"),
        style = clip.style;

    style = clip.style;
    style.className = "cpwindowclip";
    style.position = "absolute";
    style.overflow = "hidden";

    style.left = clipRect.origin.x + "px";
    style.top = clipRect.origin.y + "px";
    style.width = clipRect.size.width + "px";
    style.height = clipRect.size.height + "px";

    // Replace the window with the clip element, then put it inside the clip
    var parent = windowElement.parentNode;
    CPDOMDisplayServerInsertBefore(parent, clip, windowElement);
    CPDOMDisplayServerRemoveChild(parent, windowElement);
    CPDOMDisplayServerAppendChild(clip, windowElement);
}

/*!
    Unclips a window that was previously clipped with clipWindow:toWindow:.
    If the window was not clipped, a warning is logged.
*/
- (void)removeClipForWindow:(CPWindow)aWindow
{
    var windowElement = aWindow._DOMElement,
        clip = windowElement.parentNode,
        parent = clip.parentNode;

    CPDOMDisplayServerRemoveChild(clip, windowElement);
    [aWindow setFrameOrigin:CGPointMake([aWindow frame].origin.x, clip.offsetTop)];
    CPDOMDisplayServerInsertBefore(parent, windowElement, clip);
    CPDOMDisplayServerRemoveChild(parent, clip);
}

@end
