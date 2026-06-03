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
    if (connection != nil) // Connection waiting
    {
        connection = nil;

        var data = [CPURLConnection sendSynchronousRequest:request returningResponse:NULL];
        [self loadContent:[data rawString]];
    }
}

- (void)connection:(CPURLConnection)aConnection didReceiveData:(CPString)rawString
{
    if (connection != nil && rawString != nil)
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

    // Post notification to let the rule editor know the translation dictionary is ready
    [[CPNotificationCenter defaultCenter] postNotificationName:@"_CPRuleEditorLocalizerDidLoadNotification" object:self];
}

- (CPString)localizedStringForString:(CPString)aString
{
    [self reloadIfNeeded];

    if (_dictionary != nil && aString != nil)
    {
        var localized = [_dictionary objectForKey:aString];

        if (localized != nil)
            return localized;
    }

    return aString;
}

#pragma mark - Formatting & Reordering Helpers

- (CPString)_englishRepresentationForView:(id)aView
{
    if ([aView isKindOfClass:[CPPopUpButton class]])
    {
        var selectedItem = [aView selectedItem];
        if (selectedItem)
        {
            var originalTitle = selectedItem._originalTitle;
            
            // Fallback: If not cached directly, inspect representedObject payload dictionary
            if (!originalTitle)
            {
                var rep = [selectedItem representedObject];
                if (rep && typeof rep === "object" && [rep respondsToSelector:@selector(objectForKey:)])
                {
                    originalTitle = [rep objectForKey:@"value"];
                }
                else if (rep && typeof rep === "string")
                {
                    originalTitle = rep;
                }
            }
            if (!originalTitle)
            {
                originalTitle = [selectedItem title];
            }
            return "%[" + originalTitle + "]@";
        }
        return "%[]@";
    }
    else if ([aView isKindOfClass:[CPTextField class]] && ![aView isEditable])
    {
        return aView._originalText || [aView stringValue];
    }
    else
    {
        return "%@";
    }
}

- (CPString)formattingKeyForViews:(CPArray)views
{
    var keyParts = [];
    var count = [views count];
    for (var i = 0; i < count; i++)
    {
        var view = [views objectAtIndex:i];
        [keyParts addObject:[self _englishRepresentationForView:view]];
    }
    return [keyParts componentsJoinedByString:@" "];
}

- (void)localizeMenuItemsForViews:(CPArray)views
{
    var count = [views count];
    for (var i = 0; i < count; i++)
    {
        var view = [views objectAtIndex:i];
        if ([view isKindOfClass:[CPPopUpButton class]])
        {
            var menuItems = [view itemArray];
            var menuItemsCount = [menuItems count];
            var selectedItem = [view selectedItem];

            for (var j = 0; j < menuItemsCount; j++)
            {
                var item = [menuItems objectAtIndex:j];
                
                if (!item._originalTitle)
                {
                    var rep = [item representedObject];
                    if (rep && typeof rep === "object" && [rep respondsToSelector:@selector(objectForKey:)])
                    {
                        item._originalTitle = [rep objectForKey:@"value"];
                    }
                    else
                    {
                        item._originalTitle = [item title];
                    }
                }

                // Temporarily select item to generate formatting key context
                [view selectItem:item];

                var tempKey = [self formattingKeyForViews:views];
                var tempPattern = [self localizedStringForString:tempKey];

                if (tempPattern !== tempKey)
                {
                    var regex = /%(\d+)\$(?:\[([^\]]+)\])?@/g;
                    var match;
                    while ((match = regex.exec(tempPattern)) !== null)
                    {
                        var position = parseInt(match[1], 10) - 1;
                        var translatedValue = match[2];

                        if (position === i && translatedValue)
                        {
                            [item setTitle:translatedValue];
                            break;
                        }
                    }
                }
            }

            if (selectedItem)
            {
                [view selectItem:selectedItem];
            }
        }
    }
}

- (CPArray)localizeAndReorderViews:(CPArray)views
{
    var key = [self formattingKeyForViews:views];
    var localizedPattern = [self localizedStringForString:key];

    if (localizedPattern === key)
    {
        return views;
    }

    var newViews = [CPMutableArray array];
    var regex = /%(\d+)\$(?:\[([^\]]+)\])?@/g;
    var lastIndex = 0;
    var match;

    while ((match = regex.exec(localizedPattern)) !== null)
    {
        var literalText = localizedPattern.substring(lastIndex, match.index);
        
        // Only add a label if there are actual non-whitespace characters (like 'y')
        if (literalText.length > 0 && /\S/.test(literalText))
        {
            var label = [CPTextField labelWithTitle:literalText];
            [newViews addObject:label];
        }

        var position = parseInt(match[1], 10) - 1;
        var translatedValue = match[2];

        if (position >= 0 && position < [views count])
        {
            var originalView = [views objectAtIndex:position];

            if (translatedValue !== undefined && translatedValue !== null)
            {
                if ([originalView isKindOfClass:[CPPopUpButton class]])
                {
                    var selectedItem = [originalView selectedItem];
                    if (selectedItem)
                    {
                        if (!selectedItem._originalTitle)
                        {
                            selectedItem._originalTitle = [selectedItem title];
                        }
                        [selectedItem setTitle:translatedValue];
                    }
                }
                else if ([originalView respondsToSelector:@selector(setStringValue:)])
                {
                    [originalView setStringValue:translatedValue];

                    // Recalculate frame size if it is a static CPTextField to avoid visual clipping
                    if ([originalView isKindOfClass:[CPTextField class]] && ![originalView isEditable])
                    {
                        var font = [originalView font] || [CPFont systemFontOfSize:[CPFont systemFontSize]],
                            size = [translatedValue sizeWithFont:font];
                        [originalView setFrameSize:CGSizeMake(size.width + 4, CGRectGetHeight([originalView frame]))];
                    }
                }
            }

            [newViews addObject:originalView];
        }

        lastIndex = regex.lastIndex;
    }

    if (lastIndex < localizedPattern.length)
    {
        var literalText = localizedPattern.substring(lastIndex);
        
        // Only add a label if there are actual non-whitespace characters
        if (literalText.length > 0 && /\S/.test(literalText))
        {
            var label = [CPTextField labelWithTitle:literalText];
            [newViews addObject:label];
        }
    }

    return newViews;
}

@end
