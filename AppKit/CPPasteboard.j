/*
 * CPPasteboard.j
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
import <Foundation/CPArray.j>
import <Foundation/CPDictionary.j>
import <Foundation/CPPropertyListSerialization.j>


CPGeneralPboard         = @"CPGeneralPboard";
CPFontPboard            = @"CPFontPboard";
CPRulerPboard           = @"CPRulerPboard";
CPFindPboard            = @"CPFindPboard";
CPDragPboard            = @"CPDragPboard";

CPColorPboardType       = @"CPColorPboardType";
CPFilenamesPboardType   = @"CPFilenamesPboardType";
CPFontPboardType        = @"CPFontPboardType";
CPHTMLPboardType        = @"CPHTMLPboardType";
CPStringPboardType      = @"CPStringPboardType";
CPURLPboardType         = @"CPURLPboardType";
CPImagePboardType       = @"CPImagePboardType";

var CPPasteboards = nil;

@implementation CPPasteboard : CPObject
{
    CPArray         _types;
    CPDictionary    _owners;
    CPDictionary    _provided;
    
    unsigned        _changeCount;
    CPString        _stateUID;
}

+ (void)initialize
{
    if (self != [CPPasteboard class])
        return;

    [self setVersion:1.0];
    
    CPPasteboards = [CPDictionary dictionary];
}

+ (id)generalPasteboard
{
    return [CPPasteboard pasteboardWithName:CPGeneralPboard];
}

+ (id)pasteboardWithName:(CPString)aName
{
    var pasteboard = [CPPasteboards objectForKey:aName];
    
    if (pasteboard)
        return pasteboard;
    
    pasteboard = [[CPPasteboard alloc] _initWithName:aName];
    [CPPasteboards setObject:pasteboard forKey:aName];
    
    return pasteboard;
}

- (id)_initWithName:(CPString)aName
{
    self = [super init];
    
    if (self)
    {
        _name = aName;
        _types = [];
        
        _owners = [CPDictionary dictionary];
        _provided = [CPDictionary dictionary];
        
        _changeCount = 0;
    }
    
    return self;
}

- (unsigned)addTypes:(CPArray)types owner:(id)anOwner
{
    var i = 0,
        count = types.length;
    
    for (; i < count; ++i)
    {
        var type = types[i];
        
        if(![_owners objectForKey:type])
        {
            [_types addObject:type];
            [_provided removeObjectForKey:type];
        }
        
        [_owners setObject:anOwner forKey:type];
    }
    
    return ++_changeCount;
}

- (unsigned)declareTypes:(CPArray)types owner:(id)anOwner
{
    [_types setArray:types];

    _owners = [CPDictionary dictionary];
    _provided = [CPDictionary dictionary];

    var count = _types.length;
    
    while (count--)
        [_owners setObject:anOwner forKey:_types[count]];
        
    return ++_changeCount;
}

- (BOOL)setData:(CPData)aData forType:(CPString)aType
{
    [_provided setObject:aData forKey:aType];
    
    return YES;
}

- (BOOL)setPropertyList:(id)aPropertyList forType:(CPString)aType
{
    return [self setData:[CPPropertyListSerialization dataFromPropertyList:aPropertyList format:CPPropertyListXMLFormat_v1_0 errorDescription:nil] forType:aType];
}

- (void)setString:(CPString)aString forType:(CPString)aType
{
    return [self setPropertyList:aString forType:aType];
}

// Determining Types

- (CPString)availableTypeFromArray:(CPArray)anArray
{
    return [_types firstObjectCommonWithArray:anArray];
}

- (CPArray)types
{
    return _types;
}

// Reading data

- (unsigned)changeCount
{
    return _changeCount;
}

- (CPData)dataForType:(CPString)aType
{
    var data = [_provided objectForKey:aType];
    
    if (data)
        return data;
        
    var owner = [_owners objectForKey:aType];
    
    if (owner)
    {
        [owner pasteboard:self provideDataForType:aType];
        
        ++_changeCount;
        
        return [_provided objectForKey:aType];
    }
    
    return nil;
}

- (id)propertyListForType:(CPString)aType
{
    var data = [self dataForType:aType];
    
    if (data)
        return [CPPropertyListSerialization propertyListFromData:data format:CPPropertyListXMLFormat_v1_0 errorDescription:nil];
        
    return nil;
}

- (CPString)stringForType:(CPString)aType
{
    return [self propertyListForType:aType];
}

- (CPString)_generateStateUID
{
    var bits = 32;
        
    _stateUID = @"";
    
    while (bits--)
        _stateUID += FLOOR(RAND() * 16.0).toString(16).toUpperCase();

    return _stateUID;
}

- (CPString)_stateUID
{
    return _stateUID;
}

@end
