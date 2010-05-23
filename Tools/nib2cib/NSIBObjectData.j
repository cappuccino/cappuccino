/*
 * NSIBObjectData.j
 * nib2cib
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

@import <AppKit/_CPCibObjectData.j>

@import "NSCell.j"


@implementation _CPCibObjectData (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [self init];
    
    if (self)
    {
/*         id                    owner;
    
        if((owner=[nameTable objectForKey:NSNibOwner])!=nil)
         [nameTable setObject:owner forKey:@"File's Owner"];
        
        [nameTable setObject:[NSFontManager sharedFontManager] forKey:@"Font Manager"];
*/
        _namesKeys = [aCoder decodeObjectForKey:@"NSNamesKeys"];
        _namesValues = [aCoder decodeObjectForKey:@"NSNamesValues"];

        //_accessibilityConnectors = [aCoder decodeObjectForKey:@"NSAccessibilityConnectors"];
        //_accessibilityOidsKeys = [aCoder decodeObjectForKey:@"NSAccessibilityOidsKeys"];
        //_accessibilityOidsValues = [aCoder decodeObjectForKey:@"NSAccessibilityOidsValues"];

        _classesKeys = [aCoder decodeObjectForKey:@"NSClassesKeys"];
        _classesValues = [aCoder decodeObjectForKey:@"NSClassesValues"];

        _connections = [aCoder decodeObjectForKey:@"NSConnections"];
        
        //_fontManager = [aCoder decodeObjectForKey:@"NSFontManager"] retain];
        _framework = [aCoder decodeObjectForKey:@"NSFramework"];

        //_nextOid = [aCoder decodeIntForKey:@"NSNextOid"];

        _objectsKeys = [aCoder decodeObjectForKey:@"NSObjectsKeys"];
        _objectsValues = [aCoder decodeObjectForKey:@"NSObjectsValues"];

        [self removeCellsFromObjectGraph];

        //_oidKeys = [aCoder decodeObjectForKey:@"NSOidsKeys"];
        //_oidValues = [aCoder decodeObjectForKey:@"NSOidsValues"];

        _fileOwner = [aCoder decodeObjectForKey:@"NSRoot"];
        _visibleWindows = [aCoder decodeObjectForKey:@"NSVisibleWindows"];
    }

    return self;
}

- (void)removeCellsFromObjectGraph
{
    // FIXME: Remove from top level objects and connections?

    // Most cell references should be naturally removed by the fact that we don't manually 
    // encode them anywhere, however, they remain in our object graph. For each cell found, 
    // take its children and promote them to our parent object's children.
    var count = _objectsKeys.length,
        parentForCellUIDs = { },
        promotedChildrenForCellUIDs = { };

    while (count--)
    {
        var child = _objectsKeys[count];

        if (!child)
            continue;

        var parent = _objectsValues[count];

        // If this object is a cell, remember it's parent.
        if ([child isKindOfClass:[NSCell class]])
        {
            parentForCellUIDs[[child UID]] = parent;
            continue;
        }

        // If parent also isn't a cell, we don't care about it.
        if (![parent isKindOfClass:[NSCell class]])
            continue;

        // Remember this child for later promotion.
        var parentUID = [parent UID],
            children = promotedChildrenForCellUIDs[parentUID];

        if (!children)
        {
            children = [];
            promotedChildrenForCellUIDs[parentUID] = children;
        }

        children.push(child);

        _objectsKeys.splice(count, 1);
        _objectsValues.splice(count, 1);
    }

    for (var cellUID in promotedChildrenForCellUIDs)
        if (promotedChildrenForCellUIDs.hasOwnProperty(cellUID))
        {
            var children = promotedChildrenForCellUIDs[cellUID],
                parent = parentForCellUIDs[cellUID];

            children.forEach(function(aChild)
            {
                CPLog.info("Promoted " + aChild + " to child of " + parent);
                _objectsKeys.push(aChild);
                _objectsValues.push(parent);
            });
        }

    var count = _objectsKeys.length;

    while (count--)
    {
        var object = _objectsKeys[count];

        if ([object respondsToSelector:@selector(swapCellsForParents:)])
            [object swapCellsForParents:parentForCellUIDs];
    }
}

@end

@implementation NSIBObjectData : _CPCibObjectData
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPCibObjectData class];
}

@end
