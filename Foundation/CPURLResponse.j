/*
 * CPURLResponse.j
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


/*
    CPURL       _URL;
    CPString    _MIMEType;
    unsigned    _expectedContentLength;
    CPString    _textEncodingName;
*/
/*!
    Contains protocol agnostic information about a request to a specific URL.
*/
@implementation CPURLResponse : CPObject
{
}
/*
Creating a Response
Ð initWithURL:MIMEType:expectedContentLength:textEncodingName:  
Getting the Response Properties
Ð expectedContentLength  
Ð suggestedFilename  
Ð MIMEType  
Ð textEncodingName  
Ð URL  
*/
@end

/*!
    Represents the response to an http request.
*/
@implementation CPHTTPURLResponse : CPURLResponse
{
    int _statusCode;
}

/* @ignore */
- (id)_initWithStatusCode:(int)aStatusCode
{
    self = [super init];
    
    if (self)
        _statusCode = aStatusCode;
    
    return self;
}

/*!
    Returns the HTTP status code.
*/
- (int)statusCode
{
    return _statusCode;
}

@end
