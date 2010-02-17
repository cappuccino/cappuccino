/*
 * CPThemeBlend.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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

@import <AppKit/CPTheme.j>
@import <AppKit/_CPCibCustomResource.j>
@import <AppKit/_CPCibKeyedUnarchiver.j>

/*!
    @ingroup appkit
*/

@implementation CPThemeBlend : CPObject
{
    CPBundle    _bundle;
    CPArray     _themes @accessors(readonly, getter=themes);
    id          _loadDelegate;
}

- (id)initWithContentsOfURL:(CPURL)aURL
{
    self = [super init];
    
    if (self)
    {
        _bundle = [[CPBundle alloc] initWithPath:aURL];
    }
    
    return self;
}

- (void)loadWithDelegate:(id)aDelegate
{
    _loadDelegate = aDelegate;
    
    [_bundle loadWithDelegate:self];
}

- (void)bundleDidFinishLoading:(CPBundle)aBundle
{
    var themes = [_bundle objectForInfoDictionaryKey:@"CPKeyedThemes"],
        count = themes.length;

    while (count--)
    {
        var path = [aBundle pathForResource:themes[count]],
            unarchiver = [[_CPThemeKeyedUnarchiver alloc]
                            initForReadingWithData:[[CPURL URLWithString:path] staticResourceData]
                            bundle:_bundle];

        [unarchiver decodeObjectForKey:@"root"];

        [unarchiver finishDecoding];
    }

    [_loadDelegate blendDidFinishLoading:self];
}

@end
