/*
 * _CPCibKeyedUnarchiver.j
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

@import <Foundation/CPKeyedUnarchiver.j>
@import <Foundation/CPBundle.j>

@implementation _CPCibKeyedUnarchiver : CPKeyedUnarchiver
{
    BOOL            _awakenCustomResources              @accessors(getter=awakenCustomResources);
    CPBundle        _bundle                             @accessors(getter=bundle);
    CPDictionary    _externalObjectsForProxyIdentifiers @accessors(setter=setExternalObjectsForProxyIdentifiers:);
    CPString        _cibName                            @accessors(getter=cibName);
}

- (id)initForReadingWithData:(CPData)data bundle:(CPBundle)aBundle awakenCustomResources:(BOOL)shouldAwakenCustomResources
{
    return [self initForReadingWithData:data bundle:aBundle awakenCustomResources:shouldAwakenCustomResources cibName:@""];
}

- (id)initForReadingWithData:(CPData)data bundle:(CPBundle)aBundle awakenCustomResources:(BOOL)shouldAwakenCustomResources cibName:(CPString)aCibName
{
    self = [super initForReadingWithData:data];

    if (self)
    {
        _bundle = aBundle;
        _awakenCustomResources = shouldAwakenCustomResources;
        _cibName = aCibName;

        [self setDelegate:self];
    }

    return self;
}

- (id)externalObjectForProxyIdentifier:(CPString)anIdentifier
{
    return [_externalObjectsForProxyIdentifiers objectForKey:anIdentifier];
}

- (void)replaceObjectAtUID:(int)aUID withObject:(id)anObject
{
    _objects[aUID] = anObject;
}

- (id)objectAtUID:(int)aUID
{
    return _objects[aUID];
}

@end
