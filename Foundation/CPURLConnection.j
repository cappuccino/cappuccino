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

@import "CPData.j"
@import "CPObject.j"
@import "CPRunLoop.j"
@import "CPURLRequest.j"
@import "CPURLResponse.j"
@import "CPOperationQueue.j"
@import "CPOperation.j"

@protocol CPURLConnectionDelegate <CPObject>

- (void)connection:(CPURLConnection)anURLConnection didFailWithError:(CPException)anError;
- (void)connection:(CPURLConnection)anURLConnection didReceiveData:(CPString)aData;
- (void)connection:(CPURLConnection)anURLConnection didReceiveResponse:(CPString)aResponse;
- (void)connectionDidFinishLoading:(CPURLConnection)anURLConnection;
- (void)connectionDidReceiveAuthenticationChallenge:(CPURLConnection)anURLConnection;

@end

@typedef HTTPRequest

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
    CPURLRequest                    _originalRequest        @accessors(readonly, getter=originalRequest);
    CPURLRequest                    _request                @accessors(readonly, getter=currentRequest);
    id  <CPURLConnectionDelegate>   _delegate;
    BOOL                            _isCanceled;
    BOOL                            _isLocalFileConnection;

    HTTPRequest                     _HTTPRequest;

    CPOperationQueue                _operationQueue;
    CPOperation                     _connectionOperation @accessors(readonly, getter=operation);
}

+ (void)setClassDelegate:(id <CPURLConnectionDelegate>)delegate
{
    CPURLConnectionDelegate = delegate;
}

/*
    Sends a request for the data from a URL. This is the easiest way to obtain data from a URL.
    @param aRequest contains the URL to request the data from
    @param aURLResponse not used
    @param anError not used
    @return the data at the URL or \c nil if there was an error
*/
+ (CPData)sendSynchronousRequest:(CPURLRequest)aRequest returningResponse:(/*{*/CPURLResponse/*}*/)aURLResponse
{
    try
    {
        var aCFHTTPRequest = new CFHTTPRequest();
        aCFHTTPRequest.setWithCredentials([aRequest withCredentials]);

        aCFHTTPRequest.open([aRequest HTTPMethod], [[aRequest URL] absoluteString], NO);

        var fields = [aRequest allHTTPHeaderFields],
            key = nil,
            keys = [fields keyEnumerator];

        while ((key = [keys nextObject]) !== nil)
            aCFHTTPRequest.setRequestHeader(key, [fields objectForKey:key]);

        aCFHTTPRequest.send([aRequest HTTPBody]);

        if (!aCFHTTPRequest.success())
            return nil;

        return [CPData dataWithRawString:aCFHTTPRequest.responseText()];
    }
    catch (anException)
    {
    }

    return nil;
}

/*
    Loads the data for a URL request and executes a function on an operation queue when the request completes or fails.
    @param aRequest contains the URL to obtain data from.
    @param aQueue The operation queue to which the function is dispatched when the request completes or failed.
    @param aHandler The function to execute.
    @discussion If the request completes successfully, the data parameter of the function contains the resource data, and the error parameter is nil. If the request fails, the data parameter is nil and the error parameter contain information about the failure.
*/
+ (CPURLConnection)sendAsynchronousRequest:(CPURLRequest)aRequest queue:(CPOperationQueue)aQueue completionHandler:(Function)aHandler
{
    return [[self alloc] _initWithRequest:aRequest queue:aQueue completionHandler:aHandler];
}

/*
    Creates a url connection with a delegate to monitor the request progress.
    @param aRequest contains the URL to obtain data from
    @param aDelegate will be sent messages related to the request progress
    @return a connection that can be \c started to initiate the request
*/
+ (CPURLConnection)connectionWithRequest:(CPURLRequest)aRequest delegate:(id)aDelegate
{
    return [[self alloc] initWithRequest:aRequest delegate:aDelegate];
}

/*
    Default class initializer. Use one of the class methods instead.
    @param aRequest contains the URL to contact
    @param aDelegate will receive progress messages
    @param shouldStartImmediately whether the \c -start method should be called from here
    @return the initialized url connection
*/
- (id)initWithRequest:(CPURLRequest)aRequest delegate:(id <CPURLConnectionDelegate>)aDelegate startImmediately:(BOOL)shouldStartImmediately
{
    self = [super init];

    if (self)
    {
        _delegate = aDelegate;
        _operationQueue = nil;
        _connectionOperation = nil;

        [self _initWithRequest:aRequest];
    }

    if (shouldStartImmediately)
        [self start];

    return self;
}

- (void)_initWithRequest:(CPURLRequest)aRequest
{
	_request = aRequest;
    _originalRequest = [aRequest copy];
	_isCanceled = NO;

	var URL = [_request URL],
	    scheme = [URL scheme];

	// Browsers use "file:", Titanium uses "app:"
	_isLocalFileConnection =    scheme === "file" ||
                                ((scheme === "http" || scheme === "https") &&
                                 window.location &&
                                 (window.location.protocol === "file:" || window.location.protocol === "app:"));

    _HTTPRequest = new CFHTTPRequest();
    _HTTPRequest.setTimeout([aRequest timeoutInterval] * 1000);
    _HTTPRequest.setWithCredentials([aRequest withCredentials]);
}

- (id)_initWithRequest:(CPURLRequest)aRequest queue:(CPOperationQueue)aQueue completionHandler:(Function)aHandler
{
    self = [super init];

    if (self)
    {
        _delegate = nil;
        _operationQueue = aQueue;
        _connectionOperation = [[_AsynchronousConnectionOperation alloc] initWithFunction:aHandler];

        [self _initWithRequest:aRequest];
        [self start];
    }

    return self;
}

- (id)initWithRequest:(CPURLRequest)aRequest delegate:(id <CPURLConnectionDelegate>)aDelegate
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
        _HTTPRequest.open([_request HTTPMethod], [[_request URL] absoluteString], YES);

        _HTTPRequest.onreadystatechange = function() { [self _readyStateDidChange]; };
        _HTTPRequest.ontimeout = function() { [self _didTimeout]; };

        var fields = [_request allHTTPHeaderFields],
            key = nil,
            keys = [fields keyEnumerator];

        while ((key = [keys nextObject]) !== nil)
            _HTTPRequest.setRequestHeader(key, [fields objectForKey:key]);

        _HTTPRequest.send([_request HTTPBody]);
    }
    catch (anException)
    {
        [self _sendDelegateDidFailWithError:anException];
    }
}

- (void)_sendDelegateDidFailWithError:(CPException)anException
{
    if ([_delegate respondsToSelector:@selector(connection:didFailWithError:)])
        [_delegate connection:self didFailWithError:anException];
    else if (_connectionOperation !== nil)
        [self _connectionOperationDidReceiveResponse:nil data:nil error:anException];
}

/*
    Cancels the current request.
*/
- (void)cancel
{
    _isCanceled = YES;

    try
    {
        _HTTPRequest.abort();

        if (_connectionOperation)
            [_connectionOperation cancel];
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

/*!
    @ignore
*/
- (void)_didTimeout
{
    var exception = [CPException exceptionWithName:@"Timeout exception"
                                            reason:"The request timed out."
                                          userInfo:@{}];

    [self _sendDelegateDidFailWithError:exception];
}
/* @ignore */
- (void)_readyStateDidChange
{
    if (_HTTPRequest.readyState() === CFHTTPRequest.CompleteState && !_HTTPRequest.isTimeoutRequest())
    {
        var statusCode = _HTTPRequest.status(),
            URL = [_request URL];

        if (statusCode === 401 && [CPURLConnectionDelegate respondsToSelector:@selector(connectionDidReceiveAuthenticationChallenge:)])
            [CPURLConnectionDelegate connectionDidReceiveAuthenticationChallenge:self];
        else
        {
            var response;

            if (_isLocalFileConnection)
                response = [[CPURLResponse alloc] initWithURL:URL];
            else
            {
                response = [[CPHTTPURLResponse alloc] initWithURL:URL];
                [response _setStatusCode:statusCode];
                [response _setAllResponseHeaders:_HTTPRequest.getAllResponseHeaders()];
            }

            if ([_delegate respondsToSelector:@selector(connection:didReceiveResponse:)])
                [_delegate connection:self didReceiveResponse:response];

            if (!_isCanceled)
            {
                if ([_delegate respondsToSelector:@selector(connection:didReceiveData:)])
                    [_delegate connection:self didReceiveData:_HTTPRequest.responseText()];
                else if (_connectionOperation !== nil)
                    [self _connectionOperationDidReceiveResponse:response data:_HTTPRequest.responseText() error:nil];

                if ([_delegate respondsToSelector:@selector(connectionDidFinishLoading:)])
                    [_delegate connectionDidFinishLoading:self];
            }
        }
    }

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

/* @ignore */
- (HTTPRequest)_HTTPRequest
{
    return _HTTPRequest;
}

- (void)_connectionOperationDidReceiveResponse:(CPURLResponse)aResponse data:(CPData)aData error:(CPError)anError
{
    [_connectionOperation _setResponse:aResponse data:aData error:anError];

    if (_operationQueue)
        [_operationQueue addOperation:_connectionOperation];
    else
    {
        // Do we need to send CPOperation KVO notifications ?
        [_connectionOperation main];
    }
}

@end

/* @ignore */
@implementation _AsynchronousConnectionOperation : CPOperation
{
    BOOL          _didReceiveResponse;

    CPURLResponse _response;
    CPData        _data;
    CPError       _error;
    Function      _operationFunction;
}

/* @ignore */
- (id)initWithFunction:(Function)aFunction
{
    self = [super init];

    if (self)
    {
        _didReceiveResponse = NO;
        _response = nil;
        _data = nil;
        _error = nil;
        _operationFunction = aFunction;
    }

    return self;
}

- (void)_setResponse:(CPURLResponse)aResponse data:(CPData)aData error:(CPError)anError
{
    _didReceiveResponse = YES;
    _response = aResponse;
    _data = aData;
    _error = anError;
}

/* @ignore */
- (void)main
{
    _operationFunction(_response, _data, _error);
}

/* @ignore */
- (BOOL)isReady
{
    return (_didReceiveResponse && [super isReady]);
}

@end

@implementation CPURLConnection (Deprecated)

+ (CPData)sendSynchronousRequest:(CPURLRequest)aRequest returningResponse:(/*{*/CPURLResponse/*}*/)aURLResponse error:(id)anError
{
    _CPReportLenientDeprecation(self, _cmd, @selector(sendSynchronousRequest:returningResponse:));

    return [self sendSynchronousRequest:aRequest returningResponse:aURLResponse];
}

- (HTTPRequest)_XMLHTTPRequest
{
    _CPReportLenientDeprecation(self, _cmd, @selector(_HTTPRequest));

    return [self _HTTPRequest];
}

@end
