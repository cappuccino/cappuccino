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

@import "CPFlashMovie.j"
@import "CPView.j"


var IEFlashCLSID = "clsid:D27CDB6E-AE6D-11cf-96B8-444553540000";

/*!
    @ingroup appkit
*/
@implementation CPFlashView : CPView
{
    CPFlashMovie    _flashMovie;
    
    CPDictionary    _params;
    CPDictionary    _paramElements;
#if PLATFORM(DOM)    
    DOMElement      _DOMParamElement;
    DOMElement      _DOMObjectElement;
    DOMElement      _DOMInnerObjectElement;
#endif
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
#if PLATFORM(DOM)
        if (!CPBrowserIsEngine(CPInternetExplorerBrowserEngine))
        {
            _DOMObjectElement = document.createElement(@"object");
            _DOMObjectElement.width = @"100%";
            _DOMObjectElement.height = @"100%";
            _DOMObjectElement.style.top = @"0px";
            _DOMObjectElement.style.left = @"0px";
            _DOMObjectElement.type = @"application/x-shockwave-flash";
            _DOMObjectElement.setAttribute(@"classid", IEFlashCLSID);
            
            _DOMParamElement = document.createElement(@"param");
            _DOMParamElement.name = @"movie";
            
            _DOMInnerObjectElement = document.createElement(@"object");
            _DOMInnerObjectElement.width = @"100%";
            _DOMInnerObjectElement.height = @"100%";
            
            _DOMObjectElement.appendChild(_DOMParamElement);
            _DOMObjectElement.appendChild(_DOMInnerObjectElement);
            
            _DOMElement.appendChild(_DOMObjectElement);
        }
        else
            [self _rebuildIEObjects];
#endif
    }
    
    return self;
}

- (void)setFlashMovie:(CPFlashMovie)aFlashMovie
{
    if (_flashMovie == aFlashMovie)
        return;
        
    _flashMovie = aFlashMovie;
#if PLATFORM(DOM)
    if (!CPBrowserIsEngine(CPInternetExplorerBrowserEngine))
    {
        _DOMParamElement.value = [aFlashMovie filename];
        _DOMInnerObjectElement.data = [aFlashMovie filename];
    }
    else
        [self _rebuildIEObjects];
#endif
}

- (CPFlashMovie)flashMovie
{
    return _flashMovie;
}

- (void)setFlashVars:(CPDictionary)aDictionary
{
    var varString = @"",
        enumerator = [aDictionary keyEnumerator];
    
    var key;
    while (key = [enumerator nextObject])
        varString = [varString stringByAppendingFormat:@"&%@=%@", key, [aDictionary objectForKey:key]];
    
    if (!_params)
        _params = [CPDictionary dictionary];
    
    [_params setObject:varString forKey:@"flashvars"];
    [self setParameters:_params];
}

- (CPDictionary)flashVars
{
    return [_params objectForKey:@"flashvars"];
}

- (void)setParameters:(CPDictionary)aDictionary
{
#if PLATFORM(DOM)
    if (_paramElements && !CPBrowserIsEngine(CPInternetExplorerBrowserEngine))
    {
        var elements = [_paramElements allValues],
            count = [elements count];
        
        for (var i = 0; i < count; i++)
            _DOMObjectElement.removeChild([elements objectAtIndex:i]);
    }
#endif
    _params = aDictionary;
#if PLATFORM(DOM)
    if (!CPBrowserIsEngine(CPInternetExplorerBrowserEngine))
    {
        _paramElements = [CPDictionary dictionary];
        
        var enumerator = [_params keyEnumerator],
            key;
        
        while (key = [enumerator nextObject] && _DOMObjectElement)
        {
            var param = document.createElement(@"param");
            param.name = key;
            param.value = [_params objectForKey:key];
            
            _DOMObjectElement.appendChild(param);
            
            [_paramElements setObject:param forKey:key];
        }
    }
    else
        [self _rebuildIEObjects];
#endif
}

- (CPDictionary)parameters
{
    return _params;
}

#if PLATFORM(DOM)
- (void)_rebuildIEObjects
{
    _DOMElement.innerHTML = @"";
    if (![_flashMovie filename])
        return;
    
    var paramString = [CPString stringWithFormat:@"<param name='movie' value='%@' />", [_flashMovie filename]],
        paramEnumerator = [_params keyEnumerator],
        key;
    
    while (key = [paramEnumerator nextObject])
        paramString = [paramString stringByAppendingFormat:@"<param name='%@' value='%@' />", key, [_params objectForKey:key]];
    
    _DOMObjectElement = document.createElement(@"object");
    _DOMElement.appendChild(_DOMObjectElement);
    
    _DOMObjectElement.outerHTML = [CPString stringWithFormat:@"<object classid=%@ width=%@ height=%@>%@</object>", IEFlashCLSID, CGRectGetWidth([self bounds]), CGRectGetHeight([self bounds]), paramString];
}
#endif

- (void)mouseDragged:(CPEvent)anEvent
{
    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
}

- (void)mouseDown:(CPEvent)anEvent
{
    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
}

- (void)mouseUp:(CPEvent)anEvent
{
    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
}

@end
