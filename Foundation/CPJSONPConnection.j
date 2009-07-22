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
 
@import <Foundation/CPObject.j>


CPJSONPConnectionCallbacks = {};

CPJSONPCallbackReplacementString = @"${JSONP_CALLBACK}";

/*! 
    @ingroup foundation
    @brief Allows cross domain connections using JSONP protocol.

    Important note: CPJSONPConnection is <strong>only</strong> for JSONP APIs.
    If aren't sure you <strong>need</strong>
    <a href="http://ajaxian.com/archives/jsonp-json-with-padding">JSON<strong>P</strong></a>,
    you most likely don't want to use CPJSONPConnection, but rather the more standard
    CPURLConnection. CPJSONPConnection is designed for cross-domain
    connections, and if you are making requests to the same domain (as most web
    applications do), you do not need it.
*/
@implementation CPJSONPConnection : CPObject
{
    CPURLRequest    _request;
    id              _delegate;
    
    CPString        _callbackParameter;
    DOMElement      _scriptTag;
}

/*! @deprecated */
+ (CPJSONPConnection)sendRequest:(CPURLRequest)aRequest callback:(CPString)callbackParameter delegate:(id)aDelegate 
{
    return [self connectionWithRequest:aRequest callback:callbackParameter delegate:aDelegate];
}

+ (CPJSONPConnection)connectionWithRequest:(CPURLRequest)aRequest callback:(CPString)callbackParameter delegate:(id)aDelegate
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
    
    if (!_callbackParameter && [_request URL].indexOf(CPJSONPCallbackReplacementString) < 0)
         [CPException raise:CPInvalidArgumentException reason:@"JSONP source specified without callback parameter or CPJSONPCallbackReplacementString in URL."];

    if(shouldStartImmediately)
        [self start];
        
    return self;
}

- (void)start
{
    try
    {
        CPJSONPConnectionCallbacks["callback"+[self UID]] = function(data)
        {
            [_delegate connection:self didReceiveData:data];
            [self removeScriptTag];
    
            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        };

        var head = document.getElementsByTagName("head").item(0),
            source = [_request URL];    

        if (_callbackParameter)
        {
            source += (source.indexOf('?') < 0) ? "?" : "&";
            source += _callbackParameter+"=CPJSONPConnectionCallbacks.callback"+[self UID];
        }
        else if (source.indexOf(CPJSONPCallbackReplacementString) >= 0)
        {
            source = [source stringByReplacingOccurrencesOfString:CPJSONPCallbackReplacementString withString:"CPJSONPConnectionCallbacks.callback"+[self UID]];
        }
        else
            return;
        
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
    
    if(_scriptTag && _scriptTag.parentNode == head)
        head.removeChild(_scriptTag);

    CPJSONPConnectionCallbacks["callback"+[self UID]] = nil;
    delete CPJSONPConnectionCallbacks["callback"+[self UID]];
}

- (void)cancel
{
    [self removeScriptTag];
}

@end
