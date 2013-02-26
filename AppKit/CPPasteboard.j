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
@import <Foundation/CPData.j>
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
CPImagesPboardType      = @"CPImagesPboardType";
CPVideosPboardType      = @"CPVideosPboardType";

UTF8PboardType          = @"public.utf8-plain-text";

// Deprecated
CPImagePboardType       = @"CPImagePboardType";


var CPPasteboards = nil,
    supportsNativePasteboard = NO;

/*!
    @ingroup appkit
    @class CPPasteboard

    CPPasteBoard is the object responsible for cut/copy/paste and drag&drop operations.
*/
@implementation CPPasteboard : CPObject
{
    CPArray         _types;
    CPDictionary    _owners;
    CPDictionary    _provided;

    unsigned        _changeCount;
    CPString        _stateUID;

    WebScriptObject _nativePasteboard;
}

/*
    @ignore
*/
+ (void)initialize
{
    if (self !== [CPPasteboard class])
        return;

    [self setVersion:1.0];

    CPPasteboards = @{};

    if (typeof window.cpPasteboardWithName !== "undefined")
        supportsNativePasteboard = YES;
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
//        _name = aName;
        _types = [];

        _owners = @{};
        _provided = @{};

        _changeCount = 0;

        if (supportsNativePasteboard)
        {
            _nativePasteboard = window.cpPasteboardWithName(aName);
            [self _synchronizePasteboard];
        }
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

        if (![_owners objectForKey:type])
        {
            [_types addObject:type];
            [_provided removeObjectForKey:type];
        }

        [_owners setObject:anOwner forKey:type];
    }

    if (_nativePasteboard)
    {
        var nativeTypes = [types copy];
        if ([types containsObject:CPStringPboardType])
            nativeTypes.push(UTF8PboardType);

        _nativePasteboard.addTypes_(nativeTypes);
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
    [self _declareTypes:types owner:anOwner updateNativePasteboard:YES];
}

/*! @ignore */
- (unsigned)_declareTypes:(CPArray)types owner:(id)anOwner updateNativePasteboard:(BOOL)shouldUpdate
{
    [_types setArray:types];

    _owners = @{};
    _provided = @{};

    var count = _types.length;

    while (count--)
        [_owners setObject:anOwner forKey:_types[count]];

    if (_nativePasteboard && shouldUpdate)
    {
        var nativeTypes = [types copy];
        if ([types containsObject:CPStringPboardType])
            nativeTypes.push(UTF8PboardType);

        _nativePasteboard.declareTypes_(nativeTypes);
        _changeCount = _nativePasteboard.changeCount();
    }
    return ++_changeCount;
}

/*!
    Sets the pasteboard data for the specified type
    @param aData the data
    @param aType the data type being set
    @return \c YES if the data was successfully written to the pasteboard
*/
- (BOOL)setData:(CPData)aData forType:(CPString)aType
{
    [_provided setObject:aData forKey:aType];

    if (aType === CPStringPboardType)
        [self setData:aData forType:UTF8PboardType];

    return YES;
}

/*!
    Writes the specified property list as data for the specified type
    @param aPropertyList the property list to write
    @param aType the data type
    @return \c YES if the property list was successfully written to the pasteboard
*/
- (BOOL)setPropertyList:(id)aPropertyList forType:(CPString)aType
{
    return [self setData:[CPPropertyListSerialization dataFromPropertyList:aPropertyList format:CPPropertyList280NorthFormat_v1_0] forType:aType];
}

/*!
    Sets the specified string as data for the specified type
    @param aString the string to write
    @param aType the data type
    @return \c YES if the string was successfully written to the pasteboard
*/
- (void)setString:(CPString)aString forType:(CPString)aType
{
    [self setPropertyList:aString forType:aType];
}

// Determining Types
/*!
    Checks the pasteboard's types for a match with the types listed in the specified array. The array should
    be ordered by the requestor's most preferred data type first.
    @param anArray an array of requested types ordered by preference
    @return the highest match with the pasteboard's supported types or \c nil if no match was found
*/
- (CPString)availableTypeFromArray:(CPArray)anArray
{
    return [anArray firstObjectCommonWithArray:[self types]];
}

/*!
    Returns the pasteboards supported types
*/
- (CPArray)types
{
    [self _synchronizePasteboard];
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
    @return the requested data or \c nil if the data doesn't exist
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
        return [_provided objectForKey:aType];
    }

    if (aType === CPStringPboardType)
        return [self dataForType:UTF8PboardType];

    return nil;
}

- (void)_synchronizePasteboard
{
    if (_nativePasteboard && _nativePasteboard.changeCount() > _changeCount)
    {
        var nativeTypes = [_nativePasteboard.types() copy];
        if ([nativeTypes containsObject:UTF8PboardType])
            nativeTypes.push(CPStringPboardType);

        [self _declareTypes:nativeTypes owner:self updateNativePasteboard:NO];

        _changeCount = _nativePasteboard.changeCount();
    }
}

/*! @ignore
    method provided for integration with native pasteboard
*/
- (void)pasteboard:(CPPasteboard)aPasteboard provideDataForType:(CPString)aType
{
    if (aType === CPStringPboardType)
    {
        var string = _nativePasteboard.stringForType_(UTF8PboardType);

        [self setString:string forType:CPStringPboardType];
        [self setString:string forType:UTF8PboardType];
    }
    else
        [self setString:_nativePasteboard.stringForType_(aType) forType:aType];
}

/*!
    Returns the property list for the specified data type
    @param aType the requested data type
    @return the property list or \c nil if the list was not found
*/
- (id)propertyListForType:(CPString)aType
{
    var data = [self dataForType:aType];

    if (data)
        return [CPPropertyListSerialization propertyListFromData:data format:CPPropertyList280NorthFormat_v1_0];

    return nil;
}

/*!
    Returns the string for the specified data type
    @param aType the requested data type
    @return the string or \c nil if the string was not found
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

#if PLATFORM(DOM)

var DOMDataTransferPasteboard = nil;

@implementation _CPDOMDataTransferPasteboard : CPPasteboard
{
    DataTransfer    _dataTransfer;
}

+ (_CPDOMDataTransferPasteboard)DOMDataTransferPasteboard
{
    if (!DOMDataTransferPasteboard)
        DOMDataTransferPasteboard = [[_CPDOMDataTransferPasteboard alloc] init];

    return DOMDataTransferPasteboard;
}

- (void)_setDataTransfer:(DataTransfer)aDataTransfer
{
    _dataTransfer = aDataTransfer;
}

- (void)_setPasteboard:(CPPasteboard)aPasteboard
{
    _dataTransfer.clearData();

    var types = [aPasteboard types],
        count = types.length;

    while (count--)
    {
        var type = types[count];

        if (type === CPStringPboardType)
            _dataTransfer.setData(type, [aPasteboard stringForType:type]);
        else
            _dataTransfer.setData(type, [[aPasteboard dataForType:type] rawString]);
    }
}

- (CPArray)types
{
    return Array.prototype.slice.apply(_dataTransfer.types);
}

- (CPData)dataForType:(CPString)aType
{
    var dataString = _dataTransfer.getData(aType);

    if (aType === CPStringPboardType)
        return [CPData dataFromPropertyList:dataString format:kCFPropertyList280NorthFormat_v1_0];

    return [CPData dataWithRawString:dataString];
}

- (id)propertyListForType:(CPString)aType
{
    if (aType === CPStringPboardType)
        return _dataTransfer.getData(aType);

    return [CPPropertyListSerialization propertyListFromData:[self dataForType:aType] format:CPPropertyListUnknownFormat];
}

@end

#endif
