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

import <Foundation/CPArray.j>
import <Foundation/CPObject.j>
import <Foundation/CPString.j>

import "CPCib.j"
import "_CPCibConnector.j"


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
}

- (CPArray)topLevelObjects
{
    var count = [_objectsValues count],
        topLevelObjects = [];
    var str = "";
    str2 = " ";
    while (count--)
    {str2 += _namesValues[count] +"\n";
        var eachObject = _objectsValues[count];
        
        if (eachObject == _fileOwner)
        {
            var anObject = _objectsKeys[count];
            
            if (anObject != _fileOwner)
            {str += _namesValues[count] + "\n";
                anObject.realname = _namesValues[count];str2+='X'+'\n';
                topLevelObjects.push(anObject);}
        }
    }
    alert(str2+'\n'+str);
    return topLevelObjects;
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
    
    //    CPSet           _visibleWindows;
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

//    CPSet           _visibleWindows;
}

- (void)establishConnectionsWithExternalNameTable:(CPDictionary)anExternalNameTable
{
    var index = 0,
        count = _connections.length,
        cibOwner = [anExternalNameTable objectForKey:CPCibOwner];

    for (; index < count; ++index)
    {
        var connection = _connections[index];
        
        [connection replaceObject:_fileOwner withObject:cibOwner];
        [connection establishConnection];
    }
}

@end
