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
@import "_CPCibCustomView.j"
@import "_CPCibKeyedUnarchiver.j"
@import "_CPCibObjectData.j"
@import "_CPCibWindowTemplate.j"


CPCibOwner              = @"CPCibOwner",
CPCibTopLevelObjects    = @"CPCibTopLevelObjects";
    
var CPCibObjectDataKey  = @"CPCibObjectDataKey";

@implementation CPCib : CPObject
{
    CPData  _data;
}

- (id)initWithContentsOfURL:(CPURL)aURL
{
    self = [super init];
    
    if (self)
        _data = [CPURLConnection sendSynchronousRequest:[CPURLRequest requestWithURL:aURL] returningResponse:nil error:nil];
    
    return self;
}

- (BOOL)instantiateCibWithExternalNameTable:(CPDictionary)anExternalNameTable
{
    var unarchiver = [[_CPCibKeyedUnarchiver alloc] initForReadingWithData:_data],
        objectData = [unarchiver decodeObjectForKey:CPCibObjectDataKey];

    if (!objectData || ![objectData isKindOfClass:[_CPCibObjectData class]])
        return NO;
    
    [objectData establishConnectionsWithExternalNameTable:anExternalNameTable];
    
    var owner = [anExternalNameTable objectForKey:CPCibOwner],
        topLevelObjects = [anExternalNameTable objectForKey:CPCibTopLevelObjects];
        
    var menu;
    if ((menu = [objectData mainMenu]) != nil)
    {
         [CPApp setMainMenu:menu];
         [CPMenu setMenuBarVisible:YES];
    }
    
    if (topLevelObjects)
        [topLevelObjects addObjectsFromArray:[objectData topLevelObjects]];
    
    /*
//    [objectData establishConnectionsWithOwner:owner topLevelObjects:topLevelObjects];
//    [objectData cibInstantiateWithOwner:owner topLevelObjects:topLevelObjects];
//    alert([objectData description]);
//    alert([unarchiver._archive description]);
    
	NSMutableArray *t;
	NSEnumerator *e;
	id o;
	id owner;
	id rootObject;
#if 0
	NSLog(@"instantiateCibWithExternalNameTable=%@", table);
#endif
	if(![decoded isKindOfClass:[NSIBObjectData class]])
		return NO;
	owner=[table objectForKey:NSCibOwner];
	rootObject=[decoded rootObject];
#if 0
	NSLog(@"establishConnections");
#endif
	[decoded establishConnectionsWithExternalNameTable:table];
#if 0
	NSLog(@"awakeFromCib %d objects", [decodedObjects count]);
#endif
#if 0
	NSLog(@"objects 2=%@", decodedObjects);
#endif

    // FIXME: shouldn't be accessing private variables.
    var objects = unarchiver._objects,
        count = [objects count];
    
    // The order in which objects receive the awakeFromCib message is not guaranteed.
    while (count--)
    {
        var object = objects[count];
        
        if ([object respondsToSelector:@selector(awakeFromCib)])
            [object awakeFromCib];
    }

//    if ([owner respondsToSelector:@selector(awakeFromCib)])
//        [owner awakeFromCib];
    // Display visible windows.
    
    return YES;*/
}

- (BOOL)instantiateCibWithOwner:(id)anOwner topLevelObjects:(CPArray)topLevelObjects
{
    [CPDictionary dictionaryWithObjectsAndKeys:anOwner, CPCibOwner, topLevelObjects, CPCibTopLevelObjects];
    return [self instantiate];
}

@end
