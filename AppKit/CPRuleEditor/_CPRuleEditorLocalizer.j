/*
 *     Created by cacaodev@gmail.com.
 *     Copyright (c) 2011 Pear, Inc. All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPString.j>

var LocalizerStringsRegex = new RegExp("\"(.+)\"\\s*=\\s*\"(.+)\"\\s*;\\s*(//.+)?");

@implementation _CPRuleEditorLocalizer : CPObject
{
    CPDictionary    _dictionary @accessors(property=dictionary);
    CPURLConnection connection;
    CPURLRequest    resquest;
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
    var dict = [CPDictionary dictionary],
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
