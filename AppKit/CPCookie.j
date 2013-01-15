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

@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>


/*!
    @ingroup appkit
    @class CPCookie
    CPCookie is the Cappuccino interface to a web browser cookie. You can set the name
*/
@implementation CPCookie : CPObject
{
    CPString    _cookieName;
    CPString    _cookieValue;

    CPString    _expires;
}

/*!
    Initializes a cookie with a given name \c aName.
    @param the name for the cookie
*/
- (id)initWithName:(CPString)aName
{
    self = [super init];

    _cookieName  = aName;
    _cookieValue = [self _readCookieValue];

    return self;
}

/*!
    Returns the cookie's data value
*/
- (CPString)value
{
    return _cookieValue;
}

/*!
    Returns the cookie's name
*/
- (CPString)name
{
    return _cookieName;
}

/*!
    Returns the cookie's expiration date
*/
- (CPString)expires
{
    return _expires;
}

/*!
    Sets a value, expiration date, and domain for the cookie
    @param value the cookie's value
    @param date the cookie's expiration date
    @param domain the cookie's domain
*/
- (void)setValue:(CPString)value expires:(CPDate)date domain:(CPString)domain
{
    if (date)
        var expires = "; expires=" + date.toGMTString();
    else
        var expires = "";

    if (domain)
        domain = "; domain=" + domain;
    else
        domain = "";

#if PLATFORM(DOM)
    document.cookie = _cookieName + "=" + value + expires + "; path=/" + domain;
#else
    _cookieValue = value;
    _expires = expires;
#endif
}

/* @ignore */
- (CPString)_readCookieValue
{
#if PLATFORM(DOM)
    var nameEQ = _cookieName + "=",
        ca = document.cookie.split(';');

    for (var i = 0; i < ca.length; i++)
    {
        var c = ca[i];

        while (c.charAt(0) == ' ')
            c = c.substring(1, c.length);

        if (c.indexOf(nameEQ) == 0)
            return c.substring(nameEQ.length, c.length);
    }
#endif
    return "";
}

@end

//http://www.quirksmode.org/js/cookies.html
