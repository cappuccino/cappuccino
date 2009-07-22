/*
 * CPFlashView.j
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

@import "CPDOMWindowBridge.j"
@import "CPFlashMovie.j"
@import "CPView.j"

/*!
    @ingroup appkit
*/
@implementation CPFlashView : CPView
{
    CPFlashMovie    _flashMovie;
    
    DOMElement      _DOMEmbedElement;
    DOMElement      _DOMMParamElement;
    DOMElement      _DOMObjectElement;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _DOMObjectElement = document.createElement("object");
        _DOMObjectElement.width = "100%";
        _DOMObjectElement.height = "100%";
        _DOMObjectElement.style.top = "0px";
        _DOMObjectElement.style.left = "0px";
        
        _DOMParamElement = document.createElement("param");
        _DOMParamElement.name = "movie";
        
        _DOMObjectElement.appendChild(_DOMParamElement);
        
        var param = document.createElement("param");
        
        param.name = "wmode";
        param.value = "transparent";
        
        _DOMObjectElement.appendChild(param);
        
        _DOMEmbedElement = document.createElement("embed");

        _DOMEmbedElement.type = "application/x-shockwave-flash";
        _DOMEmbedElement.setAttribute("wmode", "transparent");
        _DOMEmbedElement.width = "100%";
        _DOMEmbedElement.height = "100%";

        // IE requires this thing to be in the _DOMElement and not the _DOMObjectElement.
        _DOMElement.appendChild(_DOMEmbedElement);
                
        _DOMElement.appendChild(_DOMObjectElement);
    }
    
    return self;
}

- (void)setFlashMovie:(CPFlashMovie)aFlashMovie
{
    if (_flashMovie == aFlashMovie)
        return;
        
    _flashMovie = aFlashMovie;
    
    _DOMParamElement.value = aFlashMovie._fileName;
    
    if (_DOMEmbedElement)
       _DOMEmbedElement.src = aFlashMovie._fileName;
}

- (CPFlashMovie)flashMovie
{
    return _flashMovie;
}

- (void)mouseDragged:(CPEvent)anEvent
{
    [[CPDOMWindowBridge sharedDOMWindowBridge] _propagateCurrentDOMEvent:YES];
}

- (void)mouseDown:(CPEvent)anEvent
{
    [[CPDOMWindowBridge sharedDOMWindowBridge] _propagateCurrentDOMEvent:YES];
}

- (void)mouseUp:(CPEvent)anEvent
{
    [[CPDOMWindowBridge sharedDOMWindowBridge] _propagateCurrentDOMEvent:YES];
}

@end
