/*
 * _CPCibObjectData.j
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

@import <Foundation/CPArray.j>
@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>

@import "CPCibBindingConnector.j"
@import "CPCibConnector.j"
@import "CPCibControlConnector.j"
@import "CPCibHelpConnector.j"
@import "CPCibOutletConnector.j"
@import "CPCibRuntimeAttributesConnector.j"
@import "CPClipView.j"

@class CPScrollView


@implementation _CPCibObjectData : CPObject
{
    CPArray             _namesKeys;
    CPArray             _namesValues;

    CPArray             _accessibilityConnectors;
    CPArray             _accessibilityOidsKeys;
    CPArray             _accessibilityOidsValues;

    CPArray             _classesKeys;
    CPArray             _classesValues;

    CPArray             _connections;

    id                  _fontManager;

    CPString            _framework;

    int                 _nextOid;

    CPArray             _objectsKeys;
    CPArray             _objectsValues;

    CPArray             _oidKeys;
    CPArray             _oidValues;

    _CPCibCustomObject  _fileOwner;

    CPSet               _visibleWindows;

    JSObject            _replacementObjects;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _namesKeys = [];
        _namesValues = [];

        //CPArray         _accessibilityConnectors;
        //CPArray         _accessibilityOidsKeys;
        //CPArray         _accessibilityOidsValues;

        _classesKeys = [];
        _classesValues = [];

        _connections = [];
        //id              _fontManager;

        _framework = @"";

        _nextOid = [];

        _objectsKeys = [];
        _objectsValues = [];

        _oidKeys = [];
        _oidValues = [];

        _fileOwner = nil;

        _visibleWindows = [CPSet set];
    }

    return self;
}

- (void)displayVisibleWindows
{
    var object = nil,
        objectEnumerator = [_visibleWindows objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        [_replacementObjects[[object UID]] makeKeyAndOrderFront:self];
}

@end

var _CPCibObjectDataNamesKeysKey                = @"_CPCibObjectDataNamesKeysKey",
    _CPCibObjectDataNamesValuesKey              = @"_CPCibObjectDataNamesValuesKey",

    _CPCibObjectDataAccessibilityConnectorsKey  = @"_CPCibObjectDataAccessibilityConnectors",
    _CPCibObjectDataAccessibilityOidsKeysKey    = @"_CPCibObjectDataAccessibilityOidsKeys",
    _CPCibObjectDataAccessibilityOidsValuesKey  = @"_CPCibObjectDataAccessibilityOidsValues",

    _CPCibObjectDataClassesKeysKey              = @"_CPCibObjectDataClassesKeysKey",
    _CPCibObjectDataClassesValuesKey            = @"_CPCibObjectDataClassesValuesKey",

    _CPCibObjectDataConnectionsKey              = @"_CPCibObjectDataConnectionsKey",

    _CPCibObjectDataFontManagerKey              = @"_CPCibObjectDataFontManagerKey",

    _CPCibObjectDataFrameworkKey                = @"_CPCibObjectDataFrameworkKey",

    _CPCibObjectDataNextOidKey                  = @"_CPCibObjectDataNextOidKey",

    _CPCibObjectDataObjectsKeysKey              = @"_CPCibObjectDataObjectsKeysKey",
    _CPCibObjectDataObjectsValuesKey            = @"_CPCibObjectDataObjectsValuesKey",

    _CPCibObjectDataOidKeysKey                  = @"_CPCibObjectDataOidKeysKey",
    _CPCibObjectDataOidValuesKey                = @"_CPCibObjectDataOidValuesKey",

    _CPCibObjectDataFileOwnerKey                = @"_CPCibObjectDataFileOwnerKey",
    _CPCibObjectDataVisibleWindowsKey           = @"_CPCibObjectDataVisibleWindowsKey";

@implementation _CPCibObjectData (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _replacementObjects = {};

        _namesKeys = [aCoder decodeObjectForKey:_CPCibObjectDataNamesKeysKey];
        _namesValues = [aCoder decodeObjectForKey:_CPCibObjectDataNamesValuesKey];

        //CPArray         _accessibilityConnectors;
        //CPArray         _accessibilityOidsKeys;
        //CPArray         _accessibilityOidsValues;

        _classesKeys = [aCoder decodeObjectForKey:_CPCibObjectDataClassesKeysKey];
        _classesValues = [aCoder decodeObjectForKey:_CPCibObjectDataClassesValuesKey];

        _connections = [aCoder decodeObjectForKey:_CPCibObjectDataConnectionsKey];
        //id              _fontManager;

        _framework = [aCoder decodeObjectForKey:_CPCibObjectDataFrameworkKey];

        _nextOid = [aCoder decodeIntForKey:_CPCibObjectDataNextOidKey];

        _objectsKeys = [aCoder decodeObjectForKey:_CPCibObjectDataObjectsKeysKey];
        _objectsValues = [aCoder decodeObjectForKey:_CPCibObjectDataObjectsValuesKey];

        _oidKeys = [aCoder decodeObjectForKey:_CPCibObjectDataOidKeysKey];
        _oidValues = [aCoder decodeObjectForKey:_CPCibObjectDataOidValuesKey];

        _fileOwner = [aCoder decodeObjectForKey:_CPCibObjectDataFileOwnerKey];

        _visibleWindows = [aCoder decodeObjectForKey:_CPCibObjectDataVisibleWindowsKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_namesKeys forKey:_CPCibObjectDataNamesKeysKey];
    [aCoder encodeObject:_namesValues forKey:_CPCibObjectDataNamesValuesKey];

    //CPArray         _accessibilityConnectors;
    //CPArray         _accessibilityOidsKeys;
    //CPArray         _accessibilityOidsValues;

    [aCoder encodeObject:_classesKeys forKey:_CPCibObjectDataClassesKeysKey];
    [aCoder encodeObject:_classesValues forKey:_CPCibObjectDataClassesValuesKey];

    [aCoder encodeObject:_connections forKey:_CPCibObjectDataConnectionsKey];

    //id              _fontManager;

    [aCoder encodeObject:_framework forKey:_CPCibObjectDataFrameworkKey];

    [aCoder encodeInt:_nextOid forKey:_CPCibObjectDataNextOidKey];

    [aCoder encodeObject:_objectsKeys forKey:_CPCibObjectDataObjectsKeysKey];
    [aCoder encodeObject:_objectsValues forKey:_CPCibObjectDataObjectsValuesKey];

    [aCoder encodeObject:_oidKeys forKey:_CPCibObjectDataOidKeysKey];
    [aCoder encodeObject:_oidValues forKey:_CPCibObjectDataOidValuesKey];

    [aCoder encodeObject:_fileOwner forKey:_CPCibObjectDataFileOwnerKey];
//    CPCustomObject  _fileOwner;

    [aCoder encodeObject:_visibleWindows forKey:_CPCibObjectDataVisibleWindowsKey];
}

- (void)instantiateWithOwner:(id)anOwner topLevelObjects:(CPMutableArray)topLevelObjects
{
    // _objectsValues -> parent
    // _objectsKeys -> child
    var count = [_objectsKeys count];

    while (count--)
    {
        var object = _objectsKeys[count],
            parent = _objectsValues[count],
            instantiatedObject = object;

        if ([object respondsToSelector:@selector(_cibInstantiate)])
        {
            var instantiatedObject = [object _cibInstantiate];

            if (instantiatedObject !== object)
            {
                _replacementObjects[[object UID]] = instantiatedObject;

                if ([instantiatedObject isKindOfClass:CPView])
                {
                    var clipView = [instantiatedObject superview];

                    if ([clipView isKindOfClass:CPClipView])
                    {
                        var scrollView = [clipView superview];

                        if ([scrollView isKindOfClass:CPScrollView])
                            [scrollView setDocumentView:instantiatedObject];
                    }
                }
            }
        }

        if (topLevelObjects && parent === _fileOwner && object !== _fileOwner)
            topLevelObjects.push(instantiatedObject);
    }
}

- (void)establishConnectionsWithOwner:(id)anOwner topLevelObjects:(CPMutableArray)topLevelObjects
{
    _replacementObjects[[_fileOwner UID]] = anOwner;

    for (var i = 0, count = _connections.length; i < count; ++i)
    {
        var connection = _connections[i];
        [connection replaceObjects:_replacementObjects];
        [connection establishConnection];
    }
}

- (void)awakeWithOwner:(id)anOwner topLevelObjects:(CPMutableArray)topLevelObjects
{
    var count = [_objectsKeys count];

    while (count--)
    {
        var object = _objectsKeys[count],
            instantiatedObject = _replacementObjects[[object UID]];

        if (instantiatedObject)
            object = instantiatedObject;

        // Don't use _fileOwner, by this point its been replaced with anOwner.
        if (object !== anOwner && [object respondsToSelector:@selector(awakeFromCib)])
            [object awakeFromCib];
    }

    if ([anOwner respondsToSelector:@selector(awakeFromCib)])
        [anOwner awakeFromCib];
}

@end
