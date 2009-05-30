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

@import "CPObject.j"
@import "CPRunLoop.j"
@import "CPURLRequest.j"
@import "CPURLResponse.j"


var XMLHTTPRequestUninitialized = 0,
    XMLHTTPRequestLoading       = 1,
    XMLHTTPRequestLoaded        = 2,
    XMLHTTPRequestInteractive   = 3,
    XMLHTTPRequestComplete      = 4;

var CPURLConnectionDelegate = nil;

/*!
    @class CPURLConnection
    @ingroup foundation
    @brief Provides loading of a URL request. 

    An interface to downloading content at a specified URL. Using one of the
    class methods, you can obtain the data.
    
    @delegate -(void)connection:(CPURLConnection)connection didFailWithError:(id)error;
    Called when the connection encounters an error.
    @param connection the connection that had an error
    @param error the error, which is either a javascript DOMException or an http
    status code (javascript number/CPNumber)
    
    @delegate -(void)connection:(CPURLConnection)connection didReceiveResponse:(CPHTTPURLResponse)response;
    Called when the connection receives a response.
    @param connection the connection that received a response
    @param response the received response
    
    @delegate -(void)connection:(CPURLConnection)connection didReceiveData:(CPString)data;
    Called when the connection has received data.
    @param connection the connection that received data
    @param data the received data
    
    @delegate -(void)connectionDidFinishLoading:(CPURLConnection)connection;
    Called when the URL has finished loading.
    @param connection the connection that finished loading
    
    Class Delegate Method:
    
    @delegate -(void)connectionDidReceiveAuthenticationChallenge:(id)connection
    The class delegate allows you to set global behavior for when authentication challenges (401 status codes) are returned.
    
    The recommended way to handle this method is to store a reference to the connection, and then use whatever
    method you have to authenticate yourself.  Once you've authenticated yourself, you should cancel 
    and then start the connection:
    
<pre>
[connection cancel];
[connection start];
</pre>
    
    @param connection the connection that received the authentication challenge.
*/
@implementation CPURLConnection : CPObject
{
    CPURLRequest    _request;
    id              _delegate;
    BOOL            _isCanceled;
    BOOL            _isLocalFileConnection;
    
    XMLHTTPRequest  _XMLHTTPRequest;
}

+ (void)setClassDelegate:(id)delegate
{
    CPURLConnectionDelegate = delegate;
}

/*
    Sends a request for the data from a URL. This is the easiest way to obtain data from a URL.
    @param aRequest contains the URL to request the data from
    @param aURLResponse not used
    @param anError not used
    @return the data at the URL or <code>nil</code> if there was an error
*/
+ (CPData)sendSynchronousRequest:(CPURLRequest)aRequest returningResponse:({CPURLResponse})aURLResponse error:({CPError})anError
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

/*
    Creates a url connection with a delegate to monitor the request progress.
    @param aRequest contains the URL to obtain data from
    @param aDelegate will be sent messages related to the request progress
    @return a connection that can be <code>start<code>ed to initiate the request
*/
+ (CPURLConnection)connectionWithRequest:(CPURLRequest)aRequest delegate:(id)aDelegate
{
    return [[self alloc] initWithRequest:aRequest delegate:aDelegate];
}

/*
    Default class initializer. Use one of the class methods instead.
    @param aRequest contains the URL to contact
    @param aDelegate will receive progress messages
    @param shouldStartImmediately whether the <code>start</code> method should be called from here
    @return the initialized url connection
*/
- (id)initWithRequest:(CPURLRequest)aRequest delegate:(id)aDelegate startImmediately:(BOOL)shouldStartImmediately
{
    self = [super init];
    
    if (self)
    {
        _request = aRequest;
        _delegate = aDelegate;
        _isCanceled = NO;
        
        var path = [_request URL];
        
        // Browsers use "file:", Titanium uses "app:"
        _isLocalFileConnection =    path.indexOf("file:") === 0 || 
                                    ((path.indexOf("http:") !== 0 || path.indexOf("https:") !== 0) && 
                                    window.location &&
                                    (window.location.protocol === "file:" || window.location.protocol === "app:"));
        
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

/*
    return the delegate
*/
- (id)delegate
{
    return _delegate;
}

/*
    Start the connection. Not needed if you used the class method +connectionWithRequest:delegate:
*/
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
        if ([_delegate respondsToSelector:@selector(connection:didFailWithError:)])
            [_delegate connection:self didFailWithError:anException];
    }
}

/*
    Cancels the current request.
*/
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

- (BOOL)isLocalFileConnection
{
    return _isLocalFileConnection;
}

/* @ignore */
- (void)_readyStateDidChange
{
    if (_XMLHTTPRequest.readyState == XMLHTTPRequestComplete)
    {
        var statusCode = _XMLHTTPRequest.status,
            URL = [_request URL];

        if ([_delegate respondsToSelector:@selector(connection:didReceiveResponse:)])
        {
            if (_isLocalFileConnection)
                [_delegate connection:self didReceiveResponse:[[CPURLResponse alloc] initWithURL:URL]];
            else
            {
                var response = [[CPHTTPURLResponse alloc] initWithURL:URL];

                [response _setStatusCode:statusCode];

                [_delegate connection:self didReceiveResponse:response];
            }
        }
        if (!_isCanceled)
        {
            if (statusCode == 401 && [CPURLConnectionDelegate respondsToSelector:@selector(connectionDidReceiveAuthenticationChallenge:)])
                [CPURLConnectionDelegate connectionDidReceiveAuthenticationChallenge:self];
            else
            {
                if ([_delegate respondsToSelector:@selector(connection:didReceiveData:)])
                    [_delegate connection:self didReceiveData:_XMLHTTPRequest.responseText];
                if ([_delegate respondsToSelector:@selector(connectionDidFinishLoading:)])
                    [_delegate connectionDidFinishLoading:self];
            }
        }
    }

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

/* @ignore */
- (void)_XMLHTTPRequest
{
    return _XMLHTTPRequest;
}

@end
