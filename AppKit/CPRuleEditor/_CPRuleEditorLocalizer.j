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

#pragma mark - Whole Sentence Formatting & Reordering Helpers

// Constructs the English-matching format representation of a single view
- (CPString)_englishRepresentationForView:(id)aView
{
    if ([aView isKindOfClass:[CPPopUpButton class]])
    {
        var selectedItem = [aView selectedItem];
        if (selectedItem)
        {
            var originalTitle = [selectedItem representedObject] || selectedItem._originalTitle || [selectedItem title];
            return "%[" + originalTitle + "]@";
        }
        return "%[]@";
    }
    else if ([aView isKindOfClass:[CPTextField class]] && ![aView isEditable])
    {
        return [aView stringValue];
    }
    else
    {
        return "%@";
    }
}

// Builds the current formatting lookup key (e.g. "%[property]@ %[is]@ %@")
- (CPString)formattingKeyForViews:(NSArray *)views
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

// Localizes all popup menu options within the row under their proper context
- (void)localizeMenuItemsForViews:(NSArray *)views
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
                    item._originalTitle = [item title];
                }

                // Temporarily select item to formulate the unique localization key
                [view selectItem:item];

                var tempKey = [self formattingKeyForViews:views];
                var tempPattern = [self localizedStringForString:tempKey];

                if (tempPattern !== tempKey)
                {
                    // Search for this view position's translation inside the pattern (e.g. %2$[son iguales]@)
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

            // Restore initial selection
            if (selectedItem)
            {
                [view selectItem:selectedItem];
            }
        }
    }
}

// Translates labels and reorders the active subviews based on positional formatting string
- (NSArray *)localizeAndReorderViews:(NSArray *)views
{
    var key = [self formattingKeyForViews:views];
    var localizedPattern = [self localizedStringForString:key];

    if (localizedPattern === key)
    {
        return views;
    }

    var newViews = [CPMutableArray array];
    
    // Pattern to extract index and translation: %1$[translation]@ or %1$@
    var regex = /%(\d+)\$(?:\[([^\]]+)\])?@/g;
    var lastIndex = 0;
    var match;

    while ((match = regex.exec(localizedPattern)) !== null)
    {
        // 1. Insert any leading static text (e.g. " y ")
        var literalText = localizedPattern.substring(lastIndex, match.index);
        if (literalText.length > 0)
        {
            var label = [CPTextField labelWithString:literalText];
            [newViews addObject:label];
        }

        // 2. Identify the original view corresponding to the positional index
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
                else if (typeof originalView.setStringValue === "function")
                {
                    [originalView setStringValue:translatedValue];
                }
            }

            [newViews addObject:originalView];
        }

        lastIndex = regex.lastIndex;
    }

    // 3. Append trailing static text
    if (lastIndex < localizedPattern.length)
    {
        var literalText = localizedPattern.substring(lastIndex);
        if (literalText.length > 0)
        {
            var label = [CPTextField labelWithString:literalText];
            [newViews addObject:label];
        }
    }

    return newViews;
}

@end
