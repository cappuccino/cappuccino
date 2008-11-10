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

@import <Foundation/CPObject.j>
@import <Foundation/CPArray.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPPropertyListSerialization.j>


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

/*! @class CPPasteboard

    <objj>CPPasteBoard</objj> is the object responsible for cut/copy/paste and drag&drop operations. 
*/
@implementation CPPasteboard : CPObject
{
    CPArray         _types;
    CPDictionary    _owners;
    CPDictionary    _provided;
    
    unsigned        _changeCount;
    CPString        _stateUID;
}

/*
    @ignore
*/
+ (void)initialize
{
    if (self != [CPPasteboard class])
        return;

    [self setVersion:1.0];
    
    CPPasteboards = [CPDictionary dictionary];
}

/*!
    Returns a new instance of a pasteboard
*/
+ (id)generalPasteboard
{
    return [CPPasteboard pasteboardWithName:CPGeneralPboard];
}

/*!
    Returns a pasteboard with the specified name. If the pasteboard doesn't exist, it will be created.
    @param aName the name of the pasteboard
    @return the requested pasteboard
*/
+ (id)pasteboardWithName:(CPString)aName
{
    var pasteboard = [CPPasteboards objectForKey:aName];
    
    if (pasteboard)
        return pasteboard;
    
    pasteboard = [[CPPasteboard alloc] _initWithName:aName];
    [CPPasteboards setObject:pasteboard forKey:aName];
    
    return pasteboard;
}

/* @ignore */
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

/*!
    Adds supported data types to the pasteboard
    @param types the data types
    @param anOwner the object that contains the data types
    @return the pasteboard's change count
*/
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

/*!
    Sets the data types that this pasteboard will contain.
    @param type the data types it will support
    @param anOwner the object that contains the the data
    @return the pasteboard's change count
*/
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

/*!
    Sets the pasteboard data for the specified type
    @param aData the data
    @param aType the data type being set
    @return <code>YES</code> if the data was successfully written to the pasteboard
*/
- (BOOL)setData:(CPData)aData forType:(CPString)aType
{
    [_provided setObject:aData forKey:aType];
    
    return YES;
}

/*!
    Writes the specified property list as data for the specified type
    @param aPropertyList the property list to write
    @param aType the data type
    @return <code>YES</code> if the property list was successfully written to the pasteboard
*/
- (BOOL)setPropertyList:(id)aPropertyList forType:(CPString)aType
{
    return [self setData:[CPPropertyListSerialization dataFromPropertyList:aPropertyList format:CPPropertyListXMLFormat_v1_0 errorDescription:nil] forType:aType];
}

/*!
    Sets the specified string as data for the specified type
    @param aString the string to write
    @param aType the data type
    @return <code>YES</code> if the string was successfully written to the pasteboard
*/
- (void)setString:(CPString)aString forType:(CPString)aType
{
    return [self setPropertyList:aString forType:aType];
}

// Determining Types
/*!
    Checks the pasteboard's types for a match with the types listen in the specified array. The array should
    be ordered by the requestor's most preferred data type first.
    @param anArray an array of requested types ordered by preference
    @return the highest match with the pasteboard's supported types or <code>nil</code> if no match was found
*/
- (CPString)availableTypeFromArray:(CPArray)anArray
{
    return [_types firstObjectCommonWithArray:anArray];
}

/*!
    Returns the pasteboards supported types
*/
- (CPArray)types
{
    return _types;
}

// Reading data
/*!
    Returns the number of changes that have occurred to this pasteboard
*/
- (unsigned)changeCount
{
    return _changeCount;
}

/*!
    Returns the pasteboard data for the specified data type
    @param aType the requested data type
    @return the requested data or <code>nil</code> if the data doesn't exist
*/
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

/*!
    Returns the property list for the specified data type
    @param aType the requested data type
    @return the property list or <code>nil</code> if the list was not found
*/
- (id)propertyListForType:(CPString)aType
{
    var data = [self dataForType:aType];
    
    if (data)
        return [CPPropertyListSerialization propertyListFromData:data format:CPPropertyListXMLFormat_v1_0 errorDescription:nil];
        
    return nil;
}

/*!
    Returns the string for the specified data type
    @param aType the requested data type
    @return the string or <code>nil</code> if the string was not found
*/
- (CPString)stringForType:(CPString)aType
{
    return [self propertyListForType:aType];
}

/* @ignore */
- (CPString)_generateStateUID
{
    var bits = 32;
        
    _stateUID = @"";
    
    while (bits--)
        _stateUID += FLOOR(RAND() * 16.0).toString(16).toUpperCase();

    return _stateUID;
}

/* @ignore */
- (CPString)_stateUID
{
    return _stateUID;
}

@end
