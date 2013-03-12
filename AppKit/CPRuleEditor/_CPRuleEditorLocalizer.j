/*
 * Created by cacaodev@gmail.com.
 * Copyright (c) 2011 Pear, Inc. All rights reserved.
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
@import <Foundation/CPDictionary.j>
@import <Foundation/CPString.j>
@import <Foundation/CPURLConnection.j>
@import <Foundation/CPURLRequest.j>

var LocalizerStringsRegex = new RegExp("\"(.+)\"\\s*=\\s*\"(.+)\"\\s*;\\s*(//.+)?");

@implementation _CPRuleEditorLocalizer : CPObject
{
    CPDictionary    _dictionary @accessors(property=dictionary);
    CPURLConnection connection;
    CPURLRequest    request;
}

- (void)loadContentOfURL:(CPURL)aURL
{
    request = [CPURLRequest requestWithURL:aURL];
    connection = [CPURLConnection connectionWithRequest:request delegate:self];
}

- (void)reloadIfNeeded
{
    if (connection !== nil) // Connection waiting
    {
        connection = nil;

        var data = [CPURLConnection sendSynchronousRequest:request returningResponse:NULL];
        [self loadContent:[data rawString]];
    }
}

- (void)connection:(CPURLConnection)aConnection didReceiveData:(CPString)rawString
{
    if (connection !== nil && rawString !== nil)
        [self loadContent:rawString];

    connection = nil;
}

- (void)loadContent:(CPString)aContent
{
    var dict = @{},
        lines = [aContent componentsSeparatedByString:"\n"],
        count = [lines count];

    for (var i = 0 ; i < count ; i++)
    {
        var line = [lines objectAtIndex:i];

        if (line.length > 1)
        {
            var match = LocalizerStringsRegex.exec(line);

            if (match && match.length >= 3)
                [dict setObject:match[2] forKey:match[1]];
        }
    }

    _dictionary = [CPDictionary dictionaryWithDictionary:dict];
}

- (CPString)localizedStringForString:(CPString)aString
{
    [self reloadIfNeeded];

    if (_dictionary !== nil && aString !== nil)
    {
        var localized = [_dictionary objectForKey:aString];

        if (localized !== nil)
            return localized;
    }

    return aString;
}

@end
