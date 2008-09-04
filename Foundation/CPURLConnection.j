/*
 * CPURLConnection.j
 * Foundation
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

import "CPObject.j"
import "CPRunLoop.j"
import "CPURLRequest.j"
import "CPURLResponse.j"


var XMLHTTPRequestUninitialized = 0,
    XMLHTTPRequestLoading       = 1,
    XMLHTTPRequestLoaded        = 2,
    XMLHTTPRequestInteractive   = 3,
    XMLHTTPRequestComplete      = 4;

var CPURLConnectionDelegate = nil;

@implementation CPURLConnection : CPObject
{
    CPURLRequest    _request;
    id              _delegate;
    BOOL            _isCanceled;
    
    XMLHTTPRequest  _XMLHTTPRequest;
}

+ (void)setClassDelegate:(id)delegate
{
    CPURLConnectionDelegate = delegate;
}

+ (CPData)sendSynchronousRequest:(CPURLRequest)aRequest returningResponse:(CPURLResponse **)aURLResponse error:(CPError **)anError
{
    try
    {
        var request = objj_request_xmlhttp();
        
        request.open([aRequest HTTPMethod], [aRequest URL], NO);
        
        var fields = [aRequest allHTTPHeaderFields],
            key = nil,
            keys = [fields keyEnumerator];
        
        while (key = [keys nextObject])
            request.setRequestHeader(key, [fields objectForKey:key]);
        
        request.send([aRequest HTTPBody]);
        
        return [CPData dataWithString:request.responseText];
    }
    catch (anException)
    {
    }
    
    return nil;
}

+ (CPURLConnection)connectionWithRequest:(CPURLRequest)aRequest delegate:(id)aDelegate
{
    return [[self alloc] initWithRequest:aRequest delegate:aDelegate];
}

- (id)initWithRequest:(CPURLRequest)aRequest delegate:(id)aDelegate startImmediately:(BOOL)shouldStartImmediately
{
    self = [super init];
    
    if (self)
    {
        _request = aRequest;
        _delegate = aDelegate;
        _isCanceled = NO;
        
        _XMLHTTPRequest = objj_request_xmlhttp();
            
        if (shouldStartImmediately)
            [self start];
    }
    
    return self;
}

- (id)initWithRequest:(CPURLRequest)aRequest delegate:(id)aDelegate
{
    return [self initWithRequest:aRequest delegate:aDelegate startImmediately:YES];
}

- (id)delegate
{
    return _delegate;
}

- (void)start
{
    _isCanceled = NO;

    try
    {   
        _XMLHTTPRequest.open([_request HTTPMethod], [_request URL], YES);
        
        _XMLHTTPRequest.onreadystatechange = function() { [self _readyStateDidChange]; }

        var fields = [_request allHTTPHeaderFields],
            key = nil,
            keys = [fields keyEnumerator];
        
        while (key = [keys nextObject])
            _XMLHTTPRequest.setRequestHeader(key, [fields objectForKey:key]);
        
        _XMLHTTPRequest.send([_request HTTPBody]);
    }
    catch (anException)
    {
        [_delegate connection:self didFailWithError:anException];
    }
}

- (void)cancel
{
    _isCanceled = YES;
    
    try
    {
        _XMLHTTPRequest.abort();
    }
    // We expect an exception in some browsers like FireFox.
    catch (anException)
    {
    }
}

- (void)_readyStateDidChange
{
    if (_XMLHTTPRequest.readyState == XMLHTTPRequestComplete)
    {
        var statusCode = _XMLHTTPRequest.status;
        
        if ([_delegate respondsToSelector:@selector(connection:didReceiveResponse:)])
            [_delegate connection:self didReceiveResponse:[[CPHTTPURLResponse alloc] _initWithStatusCode:statusCode]];
            
        if (!_isCanceled)
        {
            if (statusCode == 200)
            {
                [_delegate connection:self didReceiveData:_XMLHTTPRequest.responseText];
                [_delegate connectionDidFinishLoading:self];
            }
            else if (statusCode == 401 && [CPURLConnectionDelegate respondsToSelector:@selector(connectionDidReceiveAuthenticationChallenge:)])
                [CPURLConnectionDelegate connectionDidReceiveAuthenticationChallenge:self];
            else
                [_delegate connection:self didFailWithError:_XMLHTTPRequest.status]
        }
    }

    [[CPRunLoop currentRunLoop] performSelectors];
}

- (void)_XMLHTTPRequest
{
    return _XMLHTTPRequest;
}

@end
