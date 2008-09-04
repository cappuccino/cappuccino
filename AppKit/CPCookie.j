/*
 * CPCookie.j
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

import <Foundation/CPObject.j>
import <Foundation/CPString.j>


@implementation CPCookie : CPObject
{
    CPString    _cookieName;
    CPString    _cookieValue;
    
    CPString    _expires;
}

- (id)initWithName:(CPString)aName
{
    self = [super init];
    
    _cookieName  = aName;
    _cookieValue = [self _readCookieValue];

    return self;
}

- (CPString)value
{
    return _cookieValue;
}

- (CPString)name
{
    return _cookieName;
}

- (CPString)expires
{
    return _expires;
}

- (void)setValue:(CPString)value expires:(CPDate)date domain:(CPString)domain
{
    if(date)
        var expires = "; expires="+date.toGMTString();
    else 
        var expires = "";
        
    if(domain)
        domain = "; domain="+domain;
    else 
        domain = "";
        
	document.cookie = _cookieName+"="+value+expires+"; path=/"+domain;        
}

- (CPString)_readCookieValue
{
	var nameEQ = _cookieName + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return "";
}

@end

//http://www.quirksmode.org/js/cookies.html
