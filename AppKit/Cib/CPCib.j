/*
 * CPCib.j
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
@import <Foundation/CPURLConnection.j>
@import <Foundation/CPURLRequest.j>

@import "_CPCibCustomObject.j"
@import "_CPCibCustomResource.j"
@import "_CPCibCustomView.j"
@import "_CPCibKeyedUnarchiver.j"
@import "_CPCibObjectData.j"
@import "_CPCibWindowTemplate.j"


CPCibOwner              = @"CPCibOwner",
CPCibTopLevelObjects    = @"CPCibTopLevelObjects",
CPCibReplacementClasses = @"CPCibReplacementClasses";
    
var CPCibObjectDataKey  = @"CPCibObjectDataKey";

@implementation CPCib : CPObject
{
    CPData      _data;
    CPBundle    _bundle;
}

- (id)initWithContentsOfURL:(CPURL)aURL
{
    self = [super init];
    
    if (self)
        _data = [CPURLConnection sendSynchronousRequest:[CPURLRequest requestWithURL:aURL] returningResponse:nil error:nil];
    
    return self;
}

- (id)initWithCibNamed:(CPString)aName bundle:(CPBundle)aBundle
{
    self = [self initWithContentsOfURL:aName];
    
    if (self)
    {
        _bundle = aBundle;
    }
    
    return self;
}

- (BOOL)instantiateCibWithExternalNameTable:(CPDictionary)anExternalNameTable
{
    var unarchiver = [[_CPCibKeyedUnarchiver alloc] initForReadingWithData:_data bundle:_bundle],
        replacementClasses = [anExternalNameTable objectForKey:CPCibReplacementClasses];

    if (replacementClasses)
    {
        var key = nil,
            keyEnumerator = [replacementClasses keyEnumerator];

        while (key = [keyEnumerator nextObject])
            [unarchiver setClass:[replacementClasses objectForKey:key] forClassName:key];
    }

    var objectData = [unarchiver decodeObjectForKey:CPCibObjectDataKey];

    if (!objectData || ![objectData isKindOfClass:[_CPCibObjectData class]])
        return NO;

    var owner = [anExternalNameTable objectForKey:CPCibOwner],
        topLevelObjects = [anExternalNameTable objectForKey:CPCibTopLevelObjects];

    [objectData instantiateWithOwner:owner topLevelObjects:topLevelObjects]
    [objectData establishConnectionsWithOwner:owner topLevelObjects:topLevelObjects];
    [objectData awakeWithOwner:owner topLevelObjects:topLevelObjects];

    var menu;

    if ((menu = [objectData mainMenu]) != nil)
    {
         [CPApp setMainMenu:menu];
         [CPMenu setMenuBarVisible:YES];
    }

    // Display Visible Windows.
    [objectData displayVisibleWindows];

    return YES;
}

- (BOOL)instantiateCibWithOwner:(id)anOwner topLevelObjects:(CPArray)topLevelObjects
{
    [CPDictionary dictionaryWithObjectsAndKeys:anOwner, CPCibOwner, topLevelObjects, CPCibTopLevelObjects];
    return [self instantiate];
}

@end
