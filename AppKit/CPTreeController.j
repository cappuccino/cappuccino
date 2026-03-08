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
    id          _arrangedObjects;

    CPArray     _selectionIndexPaths;
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
    return [CPSet setWithObjects:@"selectionIndexPaths"];
}

+ (CPSet)keyPathsForValuesAffectingCanInsertChild
{
    return [CPSet setWithObjects:@"selectionIndexPaths"];
}

- (id)init
{
    if (self = [super init])
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
{[self _setContentArray:[CPArray arrayWithObject:[self newObject]]];
}

- (BOOL)preservesSelection { return _preservesSelection; }
- (void)setPreservesSelection:(BOOL)value { _preservesSelection = value; }

- (BOOL)selectsInsertedObjects { return _selectsInsertedObjects; }
- (void)setSelectsInsertedObjects:(BOOL)value { _selectsInsertedObjects = value; }

- (BOOL)avoidsEmptySelection { return _avoidsEmptySelection; }
- (void)setAvoidsEmptySelection:(BOOL)value { _avoidsEmptySelection = value; }

- (BOOL)alwaysUsesMultipleValuesMarker { return _alwaysUsesMultipleValuesMarker; }
- (void)setAlwaysUsesMultipleValuesMarker:(BOOL)aFlag { _alwaysUsesMultipleValuesMarker = aFlag; }

- (CPArray)sortDescriptors { return _sortDescriptors; }
- (void)setSortDescriptors:(CPArray)value
{
    if (_sortDescriptors === value)
        return;

    _sortDescriptors = [value copy];
    [self _rearrangeObjects];
}

- (CPString)childrenKeyPath { return _childrenKeyPath; }
- (void)setChildrenKeyPath:(CPString)aKeyPath
{
    if (_childrenKeyPath === aKeyPath) return;
    _childrenKeyPath = aKeyPath;[self rearrangeObjects];
}

- (CPString)countKeyPath { return _countKeyPath; }
- (void)setCountKeyPath:(CPString)aKeyPath { _countKeyPath = aKeyPath; }

- (CPString)leafKeyPath { return _leafKeyPath; }
- (void)setLeafKeyPath:(CPString)aKeyPath { _leafKeyPath = aKeyPath; }

- (CPString)childrenKeyPathForNode:(CPTreeNode)node { return [self childrenKeyPath]; }
- (CPString)countKeyPathForNode:(CPTreeNode)node { return [self countKeyPath]; }
- (CPString)leafKeyPathForNode:(CPTreeNode)node { return [self leafKeyPath]; }

- (void)setContent:(id)value
{
    if (_disableSetContent) return;

    if (!value)
        value = [CPArray array];
    if (![value isKindOfClass:[CPArray class]])
        value = [CPArray arrayWithObject:value];

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

- (void)_setContentArray:(id)anArray {[self setContent:anArray]; }
- (id)contentArray { return _contentObject; }
- (id)arrangedObjects { return _arrangedObjects; }

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

    [self __rebuildArrangedObjectsTree];

    if ([self preservesSelection])[self __setSelectedObjects:oldSelectedObjects];
    else[self __setSelectionIndexPaths:oldSelectionIndexPaths avoidEmpty:_avoidsEmptySelection];
}

- (void)__rebuildArrangedObjectsTree
{
    var rootNode = [[CPTreeNode alloc] initWithRepresentedObject:nil],
    contentArray = [self contentArray];

    if (contentArray && [contentArray count] > 0)
    {
        var children = [self _buildTreeNodesForObjects:contentArray];
        [[rootNode mutableChildNodes] addObjectsFromArray:children];
    }

    _arrangedObjects = rootNode;
}

- (CPArray)_buildTreeNodesForObjects:(CPArray)objects
{
    var count = [objects count];

    if (count === 0)
        return [];

    var sortedObjects = objects;

    if (_sortDescriptors && [_sortDescriptors count] > 0)
        sortedObjects = [objects sortedArrayUsingDescriptors:_sortDescriptors];

    var nodes = [CPMutableArray arrayWithCapacity:count];

    for (var i = 0; i < count; i++)
    {
        var obj = [sortedObjects objectAtIndex:i],
        node = [[CPTreeNode alloc] initWithRepresentedObject:obj];

        if (_childrenKeyPath)
        {
            var childObjects = [obj valueForKeyPath:_childrenKeyPath];

            if (childObjects && [childObjects count] > 0)
            {
                var childNodes = [self _buildTreeNodesForObjects:childObjects];
                [[node mutableChildNodes] addObjectsFromArray:childNodes];
            }
        }

        [nodes addObject:node];
    }

    return nodes;
}

- (CPIndexPath)selectionIndexPath
{
    return [_selectionIndexPaths count] > 0 ? [_selectionIndexPaths objectAtIndex:0] : nil;
}

- (BOOL)setSelectionIndexPath:(CPIndexPath)indexPath
{
    var paths = indexPath ? [CPArray arrayWithObject:indexPath] : [CPArray array];
    return[self setSelectionIndexPaths:paths];
}

- (CPArray)selectionIndexPaths { return _selectionIndexPaths; }

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
        newPaths = [CPArray array];

    if (![newPaths count] && avoidEmpty)
    {
        if ([[[self arrangedObjects] childNodes] count] > 0)
            newPaths = [CPArray arrayWithObject:[CPIndexPath indexPathWithIndex:0]];
    }

    if ([_selectionIndexPaths isEqualToArray:newPaths])
        return NO;

    [self willChangeValueForKey:@"selectionIndexPaths"];

    _selectionIndexPaths = [newPaths copy];

    var binderClass = [[self class] _binderClassForBinding:@"selectionIndexPaths"];

    if (binderClass)
    {
        var binding = [binderClass getBinding:@"selectionIndexPaths" forObject:self];

        if (binding)
            [binding reverseSetValueFor:@"selectionIndexPaths"];
    }

    [self didChangeValueForKey:@"selectionIndexPaths"];

    return YES;
}

- (BOOL)addSelectionIndexPaths:(CPArray)indexPaths
{
    var newPaths = [_selectionIndexPaths mutableCopy];

    [newPaths addObjectsFromArray:indexPaths];

    return [self setSelectionIndexPaths:newPaths];
}

- (BOOL)removeSelectionIndexPaths:(CPArray)indexPaths
{
    var newPaths = [_selectionIndexPaths mutableCopy];
    [newPaths removeObjectsInArray:indexPaths];
    return[self setSelectionIndexPaths:newPaths];
}

- (CPArray)selectedNodes
{
    var nodes = [CPMutableArray array],
    count = [_selectionIndexPaths count];

    for (var i = 0; i < count; i++)
    {
        var node = [[self arrangedObjects] descendantNodeAtIndexPath:[_selectionIndexPaths objectAtIndex:i]];
        if (node)
            [nodes addObject:node];
    }
    return nodes;
}

- (CPArray)selectedObjects
{
    var objects = [CPMutableArray array],
    nodes = [self selectedNodes],
    count = [nodes count];

    for (var i = 0; i < count; i++)
        [objects addObject:[[nodes objectAtIndex:i] representedObject]];

    return objects;
}

- (BOOL)__setSelectedObjects:(CPArray)objects
{
    if (!objects || [objects count] === 0)
        return[self __setSelectionIndexPaths:[CPArray array] avoidEmpty:_avoidsEmptySelection];

    var newPaths = [CPMutableArray array];
    for (var i = 0, count = [objects count]; i < count; i++)
    {
        var path = [self _indexPathForObject:[objects objectAtIndex:i] inNode:[self arrangedObjects]];
        if (path)
            [newPaths addObject:path];
    }

    return[self __setSelectionIndexPaths:newPaths avoidEmpty:_avoidsEmptySelection];
}

- (CPIndexPath)_indexPathForObject:(id)anObject inNode:(CPTreeNode)node
{
    if ([node representedObject] === anObject && [node parentNode] != nil)
        return [node indexPath];

    var children = [node childNodes];
    if (children)
    {
        for (var i = 0, count = [children count]; i < count; i++)
        {
            var found = [self _indexPathForObject:anObject inNode:[children objectAtIndex:i]];
            if (found)
                return found;
        }
    }
    return nil;
}

- (BOOL)canInsert { return[self isEditable]; }
- (BOOL)canInsertChild { return [self isEditable] &&[_selectionIndexPaths count] > 0; }
- (BOOL)canAddChild { return [self canInsertChild]; }

- (void)add:(id)sender
{
    if (![self canInsert]) return;

    var newObject = [self automaticallyPreparesContent] ? [self newObject] :[self _defaultNewObject],
    selectionPath = [self selectionIndexPath];

    if (!selectionPath)
        selectionPath = [CPIndexPath indexPathWithIndex:[[[self arrangedObjects] childNodes] count]];

    var length = [selectionPath length],
    lastIndex = [selectionPath indexAtPosition:length - 1],
    insertPath = [selectionPath indexPathByRemovingLastIndex];

    insertPath = [insertPath indexPathByAddingIndex:lastIndex + 1];

    [self insertObject:newObject atArrangedObjectIndexPath:insertPath];
}

- (void)addChild:(id)sender
{
    if (![self canAddChild])
        return;

    var newObject = [self automaticallyPreparesContent] ?[self newObject] : [self _defaultNewObject],
    parentNode = [[self arrangedObjects] descendantNodeAtIndexPath:[self selectionIndexPath]],
    childCount = [[parentNode childNodes] count],
    insertPath = [[self selectionIndexPath] indexPathByAddingIndex:childCount];

    [self insertObject:newObject atArrangedObjectIndexPath:insertPath];
}

- (void)insert:(id)sender
{
    if (![self canInsert]) return;

    var newObject = [self automaticallyPreparesContent] ? [self newObject] :[self _defaultNewObject],
    indexPath = [self selectionIndexPath] || [CPIndexPath indexPathWithIndex:0];

    [self insertObject:newObject atArrangedObjectIndexPath:indexPath];
}

- (void)insertChild:(id)sender
{
    if (![self canInsertChild]) return;

    var newObject = [self automaticallyPreparesContent] ? [self newObject] : [self _defaultNewObject],
    insertPath = [[self selectionIndexPath] indexPathByAddingIndex:0];

    [self insertObject:newObject atArrangedObjectIndexPath:insertPath];
}

- (void)insertObject:(id)anObject atArrangedObjectIndexPath:(CPIndexPath)indexPath
{
    [self insertObjects:[CPArray arrayWithObject:anObject] atArrangedObjectIndexPaths:[CPArray arrayWithObject:indexPath]];
}

- (void)insertObjects:(CPArray)objects atArrangedObjectIndexPaths:(CPArray)indexPaths
{
    [self willChangeValueForKey:@"content"];
    _disableSetContent = YES;

    var count = [objects count];
    for (var i = 0; i < count; i++)
    {
        var object = [objects objectAtIndex:i],
        path = [indexPaths objectAtIndex:i],
        length = [path length];

        if (length === 1)
        {[_contentObject insertObject:object atIndex:[path indexAtPosition:0]];
        }
        else
        {
            var parentPath = [path indexPathByRemovingLastIndex],
            parentNode = [[self arrangedObjects] descendantNodeAtIndexPath:parentPath];

            if (parentNode)
            {
                var parentObj = [parentNode representedObject],
                childIndex = [path indexAtPosition:length - 1];

                var children = [parentObj valueForKeyPath:_childrenKeyPath];
                if (!children)
                {
                    children = [CPMutableArray array];
                    [parentObj setValue:children forKeyPath:_childrenKeyPath];
                }

                var mutableChildren = [parentObj mutableArrayValueForKeyPath:_childrenKeyPath];

                [mutableChildren insertObject:object atIndex:childIndex];
            }
        }
    }

    var binding = [[self class] _binderClassForBinding:@"contentArray"];
    if (binding)
        [[binding getBinding:@"contentArray" forObject:self] _contentArrayDidChange];

    _disableSetContent = NO;
    [self _rearrangeObjects];

    if ([self selectsInsertedObjects])[self setSelectionIndexPaths:indexPaths];

    [self didChangeValueForKey:@"content"];
}

- (void)remove:(id)sender
{
    [self removeObjectsAtArrangedObjectIndexPaths:_selectionIndexPaths];
}

- (void)removeObjectAtArrangedObjectIndexPath:(CPIndexPath)indexPath
{
    [self removeObjectsAtArrangedObjectIndexPaths:[CPArray arrayWithObject:indexPath]];
}

- (void)removeObjectsAtArrangedObjectIndexPaths:(CPArray)indexPaths
{
    [self willChangeValueForKey:@"content"];
    _disableSetContent = YES;

    var sortedPaths = [indexPaths sortedArrayUsingSelector:@selector(compare:)],
    count = [sortedPaths count];

    for (var i = count - 1; i >= 0; i--)
    {
        var path = [sortedPaths objectAtIndex:i],
        length = [path length];

        if (length === 1)
        {
            [_contentObject removeObjectAtIndex:[path indexAtPosition:0]];
        }
        else
        {
            var parentPath = [path indexPathByRemovingLastIndex],
            parentNode = [[self arrangedObjects] descendantNodeAtIndexPath:parentPath];

            if (parentNode)
            {
                var parentObj = [parentNode representedObject],
                childIndex = [path indexAtPosition:length - 1],
                mutableChildren = [parentObj mutableArrayValueForKeyPath:_childrenKeyPath];

                if (mutableChildren && childIndex <[mutableChildren count])
                    [mutableChildren removeObjectAtIndex:childIndex];
            }
        }
    }

    var binding = [[self class] _binderClassForBinding:@"contentArray"];
    if (binding)
        [[binding getBinding:@"contentArray" forObject:self] _contentArrayDidChange];

    _disableSetContent = NO;
    [self _rearrangeObjects];
    [self didChangeValueForKey:@"content"];
}

- (void)moveNode:(CPTreeNode)node toIndexPath:(CPIndexPath)indexPath
{
    [self moveNodes:[CPArray arrayWithObject:node] toIndexPath:indexPath];
}

- (void)moveNodes:(CPArray)nodes toIndexPath:(CPIndexPath)startingIndexPath
{[CPException raise:CPUnsupportedMethodException reason:@"moveNodes:toIndexPath: is not yet implemented in CPTreeController."];
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
            [self _setContentArray:[CPArray array]];
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
