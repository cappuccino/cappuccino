/*
 * CPJSONPConnection.j
 * Foundation
 *
 * Created by Ross Boucher.
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
 
import <Foundation/CPObject.j>

CPJSONPConnectionCallbacks = {};

@implementation CPJSONPConnection : CPObject
{
    CPURLRequest    _request;
    id              _delegate;
    
    CPString        _callbackParameter;
    DOMElement      _scriptTag;
}

+ (CPData)sendRequest:(CPURLRequest)aRequest callback:(CPString)callbackParameter delegate:(id)aDelegate 
{
    return [[[self class] alloc] initWithRequest:aRequest callback:callbackParameter delegate:aDelegate startImmediately:YES];;
}

- (id)initWithRequest:(CPURLRequest)aRequest callback:(CPString)aString delegate:(id)aDelegate 
{
    return [self initWithRequest:aRequest callback:aString delegate:aDelegate startImmediately: NO];
}

- (id)initWithRequest:(CPURLRequest)aRequest callback:(CPString)aString delegate:(id)aDelegate startImmediately:(BOOL)shouldStartImmediately
{
    self = [super init];
    
    _request = aRequest;
    _delegate = aDelegate;
    
    _callbackParameter = aString;
    
    CPJSONPConnectionCallbacks["callback"+[self hash]] = function(data)
    {
        [_delegate connection:self didReceiveData:data];
        [self removeScriptTag];

        [[CPRunLoop currentRunLoop] performSelectors];
    };

    if(shouldStartImmediately)
        [self start];
        
    return self;
}

- (void)start
{
    try
    {
        var head = document.getElementsByTagName("head").item(0);
        
        var source = [_request URL];    
        source += (source.indexOf('?') < 0) ? "?" : "&";
        source += _callbackParameter+"=CPJSONPConnectionCallbacks.callback"+[self hash];

        _scriptTag = document.createElement("script");
        _scriptTag.setAttribute("type", "text/javascript");
        _scriptTag.setAttribute("charset", "utf-8");
        _scriptTag.setAttribute("src", source);
        
        head.appendChild(_scriptTag);
    }
    catch (exception)
    {
        [_delegate connection: self didFailWithError: exception];
        [self removeScriptTag];
    }
}

- (void)removeScriptTag
{
    var head = document.getElementsByTagName("head").item(0);
    
    if(_scriptTag.parentNode == head)
        head.removeChild(_scriptTag);

    CPJSONPConnectionCallbacks["callback"+[self hash]] = nil;
    delete CPJSONPConnectionCallbacks["callback"+[self hash]];
}

- (void)cancel
{
    [self removeScriptTag];
}

@end