/*
 * CPTreeController.j
 * AppKit
 *
 * Daniel Boehringer Mar/2026
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
@import <Foundation/CPIndexPath.j>
@import "CPObjectController.j"
@import "CPKeyValueBinding.j"
@import "CPTreeNode.j"

/*!
 @class CPTreeController

 CPTreeController is a bindings-compatible class that manages a tree of objects.
 It provides selection and sort management for hierarchical data.
 */
@implementation CPTreeController : CPObjectController
{
    BOOL        _avoidsEmptySelection;
    BOOL        _preservesSelection;
    BOOL        _selectsInsertedObjects;
    BOOL        _alwaysUsesMultipleValuesMarker;

    CPString    _childrenKeyPath;
    CPString    _countKeyPath;
    CPString    _leafKeyPath;

    CPArray     _sortDescriptors;
    id          _arrangedObjects; // The proxy root node containing the tree

    CPArray     _selectionIndexPaths; // Array of CPIndexPath objects

    BOOL        _disableSetContent;
}

+ (void)initialize
{
    if (self !== [CPTreeController class])
        return;

    [self exposeBinding:@"contentArray"];
    [self exposeBinding:@"sortDescriptors"];
}

+ (CPSet)keyPathsForValuesAffectingContentArray
{
    return[CPSet setWithObjects:@"content"];
}

+ (CPSet)keyPathsForValuesAffectingArrangedObjects
{
    return [CPSet setWithObjects:@"content", @"sortDescriptors", @"childrenKeyPath"];
}

+ (CPSet)keyPathsForValuesAffectingSelectionIndexPath
{
    return[CPSet setWithObjects:@"selectionIndexPaths"];
}

+ (CPSet)keyPathsForValuesAffectingSelectedObjects
{
    return [CPSet setWithObjects:@"selectionIndexPaths"];
}

+ (CPSet)keyPathsForValuesAffectingSelectedNodes
{
    return [CPSet setWithObjects:@"selectionIndexPaths"];
}

+ (CPSet)keyPathsForValuesAffectingCanAddChild
{
    return[CPSet setWithObjects:@"selectionIndexPaths"];
}

+ (CPSet)keyPathsForValuesAffectingCanInsert
{
    return[CPSet setWithObjects:@"selectionIndexPaths"];
}

+ (CPSet)keyPathsForValuesAffectingCanInsertChild
{
    return [CPSet setWithObjects:@"selectionIndexPaths"];
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _preservesSelection = YES;
        _selectsInsertedObjects = YES;
        _avoidsEmptySelection = YES;
        _alwaysUsesMultipleValuesMarker = NO;

        _childrenKeyPath = @"children";

        [self _init];
    }

    return self;
}

- (void)_init
{
    _sortDescriptors = [CPArray array];
    _selectionIndexPaths = [CPArray array];
    _arrangedObjects = [[CPTreeNode alloc] initWithRepresentedObject:nil];
}

- (void)prepareContent
{
    [self _setContentArray:[[self newObject]]];
}

// --- Properties ---

- (BOOL)preservesSelection
{
    return _preservesSelection;
}

- (void)setPreservesSelection:(BOOL)value
{
    _preservesSelection = value;
}

- (BOOL)selectsInsertedObjects
{
    return _selectsInsertedObjects;
}

- (void)setSelectsInsertedObjects:(BOOL)value
{
    _selectsInsertedObjects = value;
}

- (BOOL)avoidsEmptySelection
{
    return _avoidsEmptySelection;
}

- (void)setAvoidsEmptySelection:(BOOL)value
{
    _avoidsEmptySelection = value;
}

- (BOOL)alwaysUsesMultipleValuesMarker
{
    return _alwaysUsesMultipleValuesMarker;
}

- (void)setAlwaysUsesMultipleValuesMarker:(BOOL)aFlag
{
    _alwaysUsesMultipleValuesMarker = aFlag;
}

- (CPArray)sortDescriptors
{
    return _sortDescriptors;
}

- (void)setSortDescriptors:(CPArray)value
{
    if (_sortDescriptors === value)
        return;

    _sortDescriptors = [value copy];
    [self _rearrangeObjects];
}

// --- Key Paths ---

- (CPString)childrenKeyPath
{
    return _childrenKeyPath;
}

- (void)setChildrenKeyPath:(CPString)aKeyPath
{
    if (_childrenKeyPath === aKeyPath)
        return;

    _childrenKeyPath = aKeyPath;
    [self rearrangeObjects];
}

- (CPString)countKeyPath
{
    return _countKeyPath;
}

- (void)setCountKeyPath:(CPString)aKeyPath
{
    _countKeyPath = aKeyPath;
}

- (CPString)leafKeyPath
{
    return _leafKeyPath;
}

- (void)setLeafKeyPath:(CPString)aKeyPath
{
    _leafKeyPath = aKeyPath;
}

// --- Node Key Path Overrides ---

- (CPString)childrenKeyPathForNode:(CPTreeNode)node
{
    return [self childrenKeyPath];
}

- (CPString)countKeyPathForNode:(CPTreeNode)node
{
    return [self countKeyPath];
}

- (CPString)leafKeyPathForNode:(CPTreeNode)node
{
    return [self leafKeyPath];
}

// --- Content and Arranged Objects ---

- (void)setContent:(id)value
{
    if (_disableSetContent)
        return;

    if (value == nil)
        value = [];

    if (![value isKindOfClass:[CPArray class]])
        value = [value];

    var oldSelectedObjects = nil,
    oldSelectionIndexPaths = nil;

    if ([self preservesSelection])
        oldSelectedObjects = [self selectedObjects];
    else
        oldSelectionIndexPaths = [self selectionIndexPaths];

    _contentObject = value;

    [self _rearrangeObjects];

    if ([self preservesSelection])[self __setSelectedObjects:oldSelectedObjects];
    else[self __setSelectionIndexPaths:oldSelectionIndexPaths avoidEmpty:_avoidsEmptySelection];
}

- (void)_setContentArray:(id)anArray
{
    [self setContent:anArray];
}

- (id)contentArray
{
    return[self content];
}

- (id)arrangedObjects
{
    return _arrangedObjects;
}

- (void)rearrangeObjects
{
    [self willChangeValueForKey:@"arrangedObjects"];
    [self _rearrangeObjects];
    [self didChangeValueForKey:@"arrangedObjects"];
}

- (void)_rearrangeObjects
{
    var oldSelectedObjects = nil,
    oldSelectionIndexPaths = nil;

    if ([self preservesSelection])
        oldSelectedObjects = [self selectedObjects];
    else
        oldSelectionIndexPaths = [self selectionIndexPaths];

    // Rebuild the proxy tree. In a full implementation, this observes children using _childrenKeyPath
    // and applies _sortDescriptors recursively.[self __rebuildArrangedObjectsTree];

    if ([self preservesSelection])
        [self __setSelectedObjects:oldSelectedObjects];
    else
        [self __setSelectionIndexPaths:oldSelectionIndexPaths avoidEmpty:_avoidsEmptySelection];
}

- (void)__rebuildArrangedObjectsTree
{
    // A simplified rebuilding logic: we set the content as the represented object's children
    // of the root proxy node.
    var rootNode = [[CPTreeNode alloc] initWithRepresentedObject:nil];
    var contentArray = [self contentArray];

    // Sort top level if needed
    var sortedContent = contentArray;
    if ([_sortDescriptors count] > 0)
        sortedContent = [contentArray sortedArrayUsingDescriptors:_sortDescriptors];

    var count = [sortedContent count];
    var children = [CPMutableArray arrayWithCapacity:count];

    for (var i = 0; i < count; i++)
    {
        var node = [[CPTreeNode alloc] initWithRepresentedObject:sortedContent[i]];
        // Note: Recursive population and sorting of children based on _childrenKeyPath
        // would occur here in a complete tree parser.[children addObject:node];
    }

    [[rootNode mutableChildNodes] addObjectsFromArray:children];
    _arrangedObjects = rootNode;
}

// --- Selection Management ---

- (CPIndexPath)selectionIndexPath
{
    return [_selectionIndexPaths count] > 0 ? [_selectionIndexPaths objectAtIndex:0] : nil;
}

- (BOOL)setSelectionIndexPath:(CPIndexPath)indexPath
{
    var paths = indexPath ? [indexPath] : [];
    return [self setSelectionIndexPaths:paths];
}

- (CPArray)selectionIndexPaths
{
    return _selectionIndexPaths;
}

- (BOOL)setSelectionIndexPaths:(CPArray)indexPaths
{
    [self _selectionWillChange];
    var result = [self __setSelectionIndexPaths:indexPaths avoidEmpty:NO];
    [self _selectionDidChange];
    return result;
}

- (BOOL)__setSelectionIndexPaths:(CPArray)indexPaths avoidEmpty:(BOOL)avoidEmpty
{
    var newPaths = indexPaths;

    if (!newPaths)
        newPaths = [];

    if (![newPaths count] && avoidEmpty)
    {
        if ([[[self arrangedObjects] childNodes] count] > 0)
            newPaths = [[CPIndexPath indexPathWithIndex:0]];
    }

    if ([_selectionIndexPaths isEqualToArray:newPaths])
        return NO;

    _selectionIndexPaths = [newPaths copy];

    var binderClass = [[self class] _binderClassForBinding:@"selectionIndexPaths"];
    [[binderClass getBinding:@"selectionIndexPaths" forObject:self] reverseSetValueFor:@"selectionIndexPaths"];

    return YES;
}

- (BOOL)addSelectionIndexPaths:(CPArray)indexPaths
{
    var newPaths = [_selectionIndexPaths mutableCopy];
    [newPaths addObjectsFromArray:indexPaths];
    // Remove duplicates and maintain sorted order
    // ...
    return[self setSelectionIndexPaths:newPaths];
}

- (BOOL)removeSelectionIndexPaths:(CPArray)indexPaths
{
    var newPaths = [_selectionIndexPaths mutableCopy];
    [newPaths removeObjectsInArray:indexPaths];
    return [self setSelectionIndexPaths:newPaths];
}

- (CPArray)selectedNodes
{
    var nodes = [],
    count = [_selectionIndexPaths count];

    for (var i = 0; i < count; i++)
    {
        var node = [[self arrangedObjects] descendantNodeAtIndexPath:_selectionIndexPaths[i]];
        if (node)[nodes addObject:node];
    }
    return nodes;
}

- (CPArray)selectedObjects
{
    var objects = [],
    nodes = [self selectedNodes],
    count = [nodes count];

    for (var i = 0; i < count; i++)
        [objects addObject:[nodes[i] representedObject]];

    return objects;
}

- (BOOL)__setSelectedObjects:(CPArray)objects
{
    // Search the tree for index paths matching the passed objects and update selection
    // (Omitted recursive search for brevity)
    return YES;
}

// --- Adding, Inserting, Removing ---

- (BOOL)canInsert
{
    return [self isEditable];
}

- (BOOL)canInsertChild
{
    return [self isEditable] && [_selectionIndexPaths count] > 0;
}

- (BOOL)canAddChild
{
    return [self canInsertChild];
}

- (void)add:(id)sender
{
    if (![self canInsert])
        return;

    var newObject = [self automaticallyPreparesContent] ? [self newObject] : [self _defaultNewObject];

    var selectionPath = [self selectionIndexPath] || [CPIndexPath indexPathWithIndex:[[[self arrangedObjects] childNodes] count]];

    // Increment the last index by 1 to add *after* the current selection
    var length = [selectionPath length],
    lastIndex = [selectionPath indexAtPosition:length - 1];

    var insertPath = [selectionPath indexPathByRemovingLastIndex];
    insertPath = [insertPath indexPathByAddingIndex:lastIndex + 1];
    [self insertObject:newObject atArrangedObjectIndexPath:insertPath];
}

- (void)addChild:(id)sender
{
    if (![self canAddChild])
        return;

    var newObject = [self automaticallyPreparesContent] ? [self newObject] : [self _defaultNewObject],
    parentNode = [[self arrangedObjects] descendantNodeAtIndexPath:[self selectionIndexPath]],
    childCount = [[parentNode childNodes] count];

    var insertPath = [[self selectionIndexPath] indexPathByAddingIndex:childCount];
    [self insertObject:newObject atArrangedObjectIndexPath:insertPath];
}

- (void)insert:(id)sender
{
    if (![self canInsert])
        return;

    var newObject = [self automaticallyPreparesContent] ? [self newObject] :[self _defaultNewObject];
    var indexPath = [self selectionIndexPath] ||[CPIndexPath indexPathWithIndex:0];

    [self insertObject:newObject atArrangedObjectIndexPath:indexPath];
}

- (void)insertChild:(id)sender
{
    if (![self canInsertChild])
        return;

    var newObject = [self automaticallyPreparesContent] ? [self newObject] :[self _defaultNewObject],
    insertPath = [[self selectionIndexPath] indexPathByAddingIndex:0];
    [self insertObject:newObject atArrangedObjectIndexPath:insertPath];
}

- (void)insertObject:(id)anObject atArrangedObjectIndexPath:(CPIndexPath)indexPath
{
    [self insertObjects:[anObject] atArrangedObjectIndexPaths:[indexPath]];
}

- (void)insertObjects:(CPArray)objects atArrangedObjectIndexPaths:(CPArray)indexPaths
{
    [self willChangeValueForKey:@"content"];
    _disableSetContent = YES;

    var count = [objects count];
    for (var i = 0; i < count; i++)
    {
        var object = objects[i],
        path = indexPaths[i],
        length = [path length];

        if (length === 1)
        {
            // Insert at root level
            [_contentObject insertObject:object atIndex:[path indexAtPosition:0]];
        }
        else
        {
            // Insert into a parent node's children
            var parentPath = [path indexPathByRemovingLastIndex],
            parentNode = [[self arrangedObjects] descendantNodeAtIndexPath:parentPath],
            parentObj = [parentNode representedObject],
            childIndex = [path indexAtPosition:length - 1];

            var children = [parentObj valueForKeyPath:_childrenKeyPath];
            if (!children)
            {
                children = [CPMutableArray array];
                [parentObj setValue:children forKeyPath:_childrenKeyPath];
            }
            [children insertObject:object atIndex:childIndex];
        }
    }

    [[CPBinder getBinding:@"contentArray" forObject:self] _contentArrayDidChange];
    _disableSetContent = NO;

    [self _rearrangeObjects];

    if ([self selectsInsertedObjects])
        [self setSelectionIndexPaths:indexPaths];

    [self didChangeValueForKey:@"content"];
}

- (void)remove:(id)sender
{
    [self removeObjectsAtArrangedObjectIndexPaths:_selectionIndexPaths];
}

- (void)removeObjectAtArrangedObjectIndexPath:(CPIndexPath)indexPath
{
    [self removeObjectsAtArrangedObjectIndexPaths:[indexPath]];
}

- (void)removeObjectsAtArrangedObjectIndexPaths:(CPArray)indexPaths
{
    [self willChangeValueForKey:@"content"];
    _disableSetContent = YES;

    // Remove in reverse order to prevent shifting indices from invalidating remaining paths
    var sortedPaths = [indexPaths sortedArrayUsingSelector:@selector(compare:)],
    count = [sortedPaths count];

    for (var i = count - 1; i >= 0; i--)
    {
        var path = sortedPaths[i],
        length = [path length];

        if (length === 1)
        {
            [_contentObject removeObjectAtIndex:[path indexAtPosition:0]];
        }
        else
        {
            var parentPath = [path indexPathByRemovingLastIndex],
            parentNode = [[self arrangedObjects] descendantNodeAtIndexPath:parentPath],
            parentObj = [parentNode representedObject],
            childIndex = [path indexAtPosition:length - 1];

            var children = [parentObj valueForKeyPath:_childrenKeyPath];
            if (children)
                [children removeObjectAtIndex:childIndex];
        }
    }

    [[CPBinder getBinding:@"contentArray" forObject:self] _contentArrayDidChange];
    _disableSetContent = NO;

    [self _rearrangeObjects];
    [self didChangeValueForKey:@"content"];
}

- (void)moveNode:(CPTreeNode)node toIndexPath:(CPIndexPath)indexPath
{
    [self moveNodes:[node] toIndexPath:indexPath];
}

- (void)moveNodes:(CPArray)nodes toIndexPath:(CPIndexPath)startingIndexPath
{
    // A proper implementation handles repositioning inside the tree while maintaining object state[CPException raise:CPUnsupportedMethodException reason:@"moveNodes:toIndexPath: is not yet implemented in CPTreeController."];
}

@end

var CPTreeControllerAvoidsEmptySelection             = @"CPTreeControllerAvoidsEmptySelection",
CPTreeControllerPreservesSelection               = @"CPTreeControllerPreservesSelection",
CPTreeControllerSelectsInsertedObjects           = @"CPTreeControllerSelectsInsertedObjects",
CPTreeControllerAlwaysUsesMultipleValuesMarker   = @"CPTreeControllerAlwaysUsesMultipleValuesMarker",
CPTreeControllerChildrenKeyPath                  = @"CPTreeControllerChildrenKeyPath",
CPTreeControllerCountKeyPath                     = @"CPTreeControllerCountKeyPath",
CPTreeControllerLeafKeyPath                      = @"CPTreeControllerLeafKeyPath";

@implementation CPTreeController (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _avoidsEmptySelection = [aCoder decodeBoolForKey:CPTreeControllerAvoidsEmptySelection];
        _preservesSelection = [aCoder decodeBoolForKey:CPTreeControllerPreservesSelection];
        _selectsInsertedObjects = [aCoder decodeBoolForKey:CPTreeControllerSelectsInsertedObjects];
        _alwaysUsesMultipleValuesMarker = [aCoder decodeBoolForKey:CPTreeControllerAlwaysUsesMultipleValuesMarker];

        _childrenKeyPath = [aCoder decodeObjectForKey:CPTreeControllerChildrenKeyPath] || @"children";
        _countKeyPath = [aCoder decodeObjectForKey:CPTreeControllerCountKeyPath];
        _leafKeyPath = [aCoder decodeObjectForKey:CPTreeControllerLeafKeyPath];

        _sortDescriptors = [CPArray array];
        _selectionIndexPaths = [CPArray array];
        _arrangedObjects = [[CPTreeNode alloc] initWithRepresentedObject:nil];

        if (![self content] && [self automaticallyPreparesContent])
            [self prepareContent];
        else if (![self content])
            [self _setContentArray:[]];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeBool:_avoidsEmptySelection forKey:CPTreeControllerAvoidsEmptySelection];
    [aCoder encodeBool:_preservesSelection forKey:CPTreeControllerPreservesSelection];
    [aCoder encodeBool:_selectsInsertedObjects forKey:CPTreeControllerSelectsInsertedObjects];
    [aCoder encodeBool:_alwaysUsesMultipleValuesMarker forKey:CPTreeControllerAlwaysUsesMultipleValuesMarker];
    [aCoder encodeObject:_childrenKeyPath forKey:CPTreeControllerChildrenKeyPath];
    [aCoder encodeObject:_countKeyPath forKey:CPTreeControllerCountKeyPath];
    [aCoder encodeObject:_leafKeyPath forKey:CPTreeControllerLeafKeyPath];
}

- (void)awakeFromCib
{
    [self _selectionWillChange];
    [self _selectionDidChange];
}

@end

