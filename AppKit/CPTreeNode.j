/*
 * CPTreeNode.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301 USA
 */

@import <Foundation/CPObject.j>
@import <Foundation/CPIndexPath.j>
@import <Foundation/CPIndexSet.j>
@import <Foundation/CPArray.j>
@import <Foundation/CPKeyValueObserving.j>

/*
 * CPTreeNode implements the NSTreeNode contract.
 * The _childNodes array contains only CPTreeNode instances.
 * The representedObject property contains the application data.
 * The _parentNode and _childNodes properties maintain a strict bidirectional relationship.
 * The KVC mutation methods are the public mechanism to change the tree structure.
 */

/*
 * KVO contract.
 *
 * Automatic KVO is switched off for childNodes and parentNode (see
 * +automaticallyNotifiesObserversForKey:). Every structural mutation sends
 * its own notifications instead. Automatic swizzling is not usable here for
 * two reasons:
 *
 * 1. parentNode is readonly. There is no setParentNode: for the KVO
 *    machinery to instrument, so an automatic parentNode notification never
 *    fires.
 *
 * 2. _CPKVOProxy coalesces nested willChange/didChange brackets for the same
 *    key on the same object. The automatic wrapper around
 *    insertObject:inChildNodesAtIndex: opens an Insertion bracket before the
 *    method body runs. The Removal a same-parent move performs inside that
 *    body is then silently discarded.
 *
 * With manual notification, the observable changes are:
 *
 * - Insert (new node, or node from another parent):
 *     old parent childNodes: Removal at the old index
 *     self childNodes:       Insertion at anIndex
 *     node parentNode:       one Setting notification
 *
 * - Same-parent move via insert:
 *     self childNodes: Removal at the original index, then Insertion at anIndex
 *     node parentNode: no notification (the value does not change)
 *
 * - Remove:
 *     self childNodes: Removal at anIndex
 *     node parentNode: one Setting notification
 *
 * - Replace (replacement from another parent, or without a parent):
 *     old parent childNodes: Removal at the old index
 *     self childNodes:       Replacement at anIndex
 *     replaced node, replacement node parentNode: one Setting notification each
 *
 * - Same-parent replace:
 *     self childNodes: Removal at the replacement's original index, then
 *                      Replacement at the adjusted target index
 *     replaced node parentNode: one Setting notification
 *     replacement node parentNode: no notification (the value does not change)
 *
 * - Sort:
 *     childNodes of each node sorted: one Setting notification
 *
 * Each bracket is opened after all validation, so a raised exception never
 * leaves a willChange without its didChange.
 *
 * The parentNode bracket encloses the detach and the attach of a cross-parent
 * move. The Removal notification of the old parent therefore arrives while
 * parentNode of the node is nil, and the node is in no child array. An
 * observer that queries the tree at that time sees a consistent state.
 */

@implementation CPTreeNode : CPObject
{
    id              _representedObject  @accessors(readonly, property=representedObject);
    CPTreeNode      _parentNode         @accessors(readonly, property=parentNode);
    CPMutableArray  _childNodes;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(CPString)aKey
{
    if (aKey === @"childNodes" || aKey === @"parentNode")
        return NO;

    return [super automaticallyNotifiesObserversForKey:aKey];
}

+ (id)treeNodeWithRepresentedObject:(id)anObject
{
    return [[self alloc] initWithRepresentedObject:anObject];
}

- (id)initWithRepresentedObject:(id)anObject
{
    self = [super init];

    if (self)
    {
        _representedObject = anObject;
        _childNodes = [];
    }

    return self;
}

/*
 * Route plain init through the designated initializer.
 * Without this override, [[CPTreeNode alloc] init] leaves _childNodes unset.
 * The first mutation call then fails against an undefined array.
 */
- (id)init
{
    return [self initWithRepresentedObject:nil];
}

/*
 * Return YES if adding aTreeNode below self makes a cycle.
 * This method walks the parent chain.
 * The operation time is proportional to the tree depth.
 */
- (BOOL)_wouldCreateCycleWithNode:(CPTreeNode)aTreeNode
{
    for (var node = self; node; node = node._parentNode)
    {
        if (node === aTreeNode)
            return YES;
    }

    return NO;
}

/*
 * Enforce the NSTreeNode abstraction boundary.
 * All children must be CPTreeNode instances.
 */
- (void)_validateChildNode:(id)aTreeNode
{
    if (![aTreeNode isKindOfClass:[CPTreeNode class]])
    {
        [CPException raise:CPInvalidArgumentException
                    reason:"CPTreeNode children must be CPTreeNode instances."];
    }
}

/*
 * Remove a child node from this node, across a parent boundary.
 * This method sends the Removal notification on childNodes of self and
 * the parentNode notification of aNode (see removeObjectFromChildNodesAtIndex:).
 * A caller that encloses this call in its own parentNode bracket on aNode
 * gets one coalesced parentNode notification for the complete move.
 */
- (void)_removeChildNode:(CPTreeNode)aNode
{
    /*
     * A caller reaches this method only when aNode.parentNode already equals
     * self. _indexOfOwnChildNode: raises if self._childNodes does not contain
     * aNode, the same inconsistency indexPath raises for.
     */
    [self removeObjectFromChildNodesAtIndex:[self _indexOfOwnChildNode:aNode]];
}

/*
 * Return the index of aTreeNode, which must be a child of self.
 * Raise if the parent/child relationship is inconsistent.
 */
- (CPInteger)_indexOfOwnChildNode:(CPTreeNode)aTreeNode
{
    var index = [_childNodes indexOfObjectIdenticalTo:aTreeNode];

    if (index === CPNotFound)
    {
        [CPException raise:CPInternalInconsistencyException
                    reason:"CPTreeNode parent and child relationship is inconsistent."];
    }

    return index;
}

/*
 * First step of a same-parent move or replace: take aTreeNode out of
 * _childNodes and report it as a Removal on childNodes.
 *
 * parentNode of aTreeNode is nil while the Removal notification is
 * delivered. The node is then in no child array, and indexPath on it does
 * not raise. The caller attaches the node to self again before it returns.
 * parentNode ends with the same value it started with, so this method sends
 * no parentNode notification.
 */
- (void)_detachOwnChildNodeAtIndex:(CPInteger)anIndex
{
    var node = [_childNodes objectAtIndex:anIndex],
        indexes = [CPIndexSet indexSetWithIndex:anIndex];

    [self willChange:CPKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"childNodes"];

    node._parentNode = nil;
    [_childNodes removeObjectAtIndex:anIndex];

    [self didChange:CPKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"childNodes"];
}

/*
 * Insert aTreeNode, which has no parent, at anIndex and report an Insertion.
 * The caller validated anIndex and sends any parentNode notification.
 */
- (void)_attachChildNode:(CPTreeNode)aTreeNode atIndex:(CPInteger)anIndex
{
    var indexes = [CPIndexSet indexSetWithIndex:anIndex];

    [self willChange:CPKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"childNodes"];

    aTreeNode._parentNode = self;
    [_childNodes insertObject:aTreeNode atIndex:anIndex];

    [self didChange:CPKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"childNodes"];
}

/*
 * Put aTreeNode, which has no parent, into the existing slot anIndex and
 * report a Replacement. The node that held the slot loses its parent and
 * gets its own parentNode notification. The caller validated anIndex and
 * sends any parentNode notification for aTreeNode.
 */
- (void)_replaceChildNodeAtIndex:(CPInteger)anIndex withDetachedNode:(CPTreeNode)aTreeNode
{
    var oldTreeNode = [_childNodes objectAtIndex:anIndex],
        indexes = [CPIndexSet indexSetWithIndex:anIndex];

    [oldTreeNode willChangeValueForKey:@"parentNode"];
    [self willChange:CPKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"childNodes"];

    oldTreeNode._parentNode = nil;
    aTreeNode._parentNode = self;
    [_childNodes replaceObjectAtIndex:anIndex withObject:aTreeNode];

    [self didChange:CPKeyValueChangeReplacement valuesAtIndexes:indexes forKey:@"childNodes"];
    [oldTreeNode didChangeValueForKey:@"parentNode"];
}

- (CPIndexPath)indexPath
{
    if (!_parentNode)
        return [CPIndexPath indexPathWithIndexes:[]];

    var indexes = [],
    node = self;

    while (node._parentNode)
    {
        var parent = node._parentNode,
        index = [parent._childNodes indexOfObjectIdenticalTo:node];

        if (index === CPNotFound)
        {
            [CPException raise:CPInternalInconsistencyException
                        reason:"CPTreeNode parent and child relationship is inconsistent."];
        }

        [indexes addObject:index];
        node = parent;
    }

    /*
     * indexes was collected leaf-to-root. Build a second array in
     * root-to-leaf order by walking indexes backward. CPArray has no
     * -reverse selector; count/objectAtIndex:/addObject: are the verified,
     * already-used-elsewhere primitives.
     */
    var orderedIndexes = [],
    count = [indexes count];

    while (count--)
        [orderedIndexes addObject:[indexes objectAtIndex:count]];

    return [CPIndexPath indexPathWithIndexes:orderedIndexes];
}

- (BOOL)isLeaf
{
    return [_childNodes count] == 0;
}

- (CPArray)childNodes
{
    /*
     * Return a copy.
     * This prevents external changes that bypass the KVC methods.
     */
    return [_childNodes copy];
}

- (CPMutableArray)mutableChildNodes
{
    return [self mutableArrayValueForKey:@"childNodes"];
}

/*
 * KVC compliance methods.
 * The mutableArrayValueForKey: method uses these names.
 */


- (void)insertObject:(CPTreeNode)aTreeNode inChildNodesAtIndex:(CPInteger)anIndex
{
    [self _validateChildNode:aTreeNode];

    var oldParent = aTreeNode._parentNode,
        isSameParentMove = (oldParent === self),
        count = [_childNodes count],

        /*
         * anIndex is the target position in the final array, per the KVC
         * to-many contract. A same-parent move does not change the count,
         * so the last valid position is count - 1, not count.
         */
        maxIndex = isSameParentMove ? count - 1 : count;

    if (anIndex < 0 || anIndex > maxIndex)
    {
        [CPException raise:CPRangeException
                    reason:"index (" + anIndex + ") beyond bounds (0 .. " + maxIndex + ") for insertObject:inChildNodesAtIndex:"];
    }

    if ([self _wouldCreateCycleWithNode:aTreeNode])
    {
        [CPException raise:CPInvalidArgumentException
                    reason:"Inserting a CPTreeNode beneath itself or one of its descendants makes a cycle."];
    }

    if (isSameParentMove)
    {
        var originalIndex = [self _indexOfOwnChildNode:aTreeNode];

        /*
         * Two separate, unnested brackets: a Removal at the original index,
         * then an Insertion at the target index. The array is one element
         * short after the removal, so inserting at anIndex against it lands
         * the node at its final position without an index adjustment.
         */
        [self _detachOwnChildNodeAtIndex:originalIndex];
        [self _attachChildNode:aTreeNode atIndex:anIndex];

        return;
    }

    /*
     * Enclose detach and attach in one parentNode bracket. The nested
     * bracket that removeObjectFromChildNodesAtIndex: opens on the old
     * parent side is coalesced into this one, so an observer of parentNode
     * gets one notification for the move, not one for nil and one for self.
     */
    [aTreeNode willChangeValueForKey:@"parentNode"];

    if (oldParent)
        [oldParent _removeChildNode:aTreeNode];

    [self _attachChildNode:aTreeNode atIndex:anIndex];

    [aTreeNode didChangeValueForKey:@"parentNode"];
}

- (void)removeObjectFromChildNodesAtIndex:(CPInteger)anIndex
{
    var node = [_childNodes objectAtIndex:anIndex],
        indexes = [CPIndexSet indexSetWithIndex:anIndex];

    [node willChangeValueForKey:@"parentNode"];
    [self willChange:CPKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"childNodes"];

    node._parentNode = nil;
    [_childNodes removeObjectAtIndex:anIndex];

    [self didChange:CPKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"childNodes"];
    [node didChangeValueForKey:@"parentNode"];
}

- (void)replaceObjectInChildNodesAtIndex:(CPInteger)anIndex withObject:(CPTreeNode)aTreeNode
{
    var oldTreeNode = [_childNodes objectAtIndex:anIndex];

    [self _validateChildNode:aTreeNode];

    if (oldTreeNode === aTreeNode)
        return;

    if ([self _wouldCreateCycleWithNode:aTreeNode])
    {
        [CPException raise:CPInvalidArgumentException
                    reason:"Replacing a child with itself or one of its ancestors makes a cycle."];
    }

    var oldParent = aTreeNode._parentNode;

    if (oldParent === self)
    {
        var replacementIndex = [self _indexOfOwnChildNode:aTreeNode],
            targetIndex = anIndex;

        /*
         * Unlike insertObject:inChildNodesAtIndex:, anIndex here cannot be
         * treated as a plain final-array position: replace requires an
         * existing slot, it cannot append past the end. The removal below
         * takes a slot out of the array ahead of the target whenever the
         * replacement's original position was before it. Shift the target
         * down by one in that case, to keep it pointing at the same
         * physical slot the caller named. This matches the Cocoa KVC
         * mutation semantics.
         */
        if (replacementIndex < anIndex)
            --targetIndex;

        /*
         * Two separate, unnested brackets: a Removal at the replacement's
         * original index, then a Replacement at the target slot.
         */
        [self _detachOwnChildNodeAtIndex:replacementIndex];
        [self _replaceChildNodeAtIndex:targetIndex withDetachedNode:aTreeNode];

        return;
    }

    /*
     * Same single parentNode bracket as the cross-parent insert.
     */
    [aTreeNode willChangeValueForKey:@"parentNode"];

    if (oldParent)
        [oldParent _removeChildNode:aTreeNode];

    [self _replaceChildNodeAtIndex:anIndex withDetachedNode:aTreeNode];

    [aTreeNode didChangeValueForKey:@"parentNode"];
}

- (id)objectInChildNodesAtIndex:(CPInteger)anIndex
{
    return [_childNodes objectAtIndex:anIndex];
}

- (CPInteger)countOfChildNodes
{
    return [_childNodes count];
}


/*
 * Sort the child array of one node and report it as a Setting change of
 * childNodes. Sorting reorders the whole array, so no index-based change
 * kind describes it more precisely.
 */
- (void)_sortChildNodesUsingDescriptors:(CPArray)sortDescriptors
{
    [self willChangeValueForKey:@"childNodes"];
    [_childNodes sortUsingDescriptors:sortDescriptors];
    [self didChangeValueForKey:@"childNodes"];
}

- (void)sortWithSortDescriptors:(CPArray)sortDescriptors recursively:(BOOL)shouldSortRecursively
{
    if (!shouldSortRecursively)
    {
        [self _sortChildNodesUsingDescriptors:sortDescriptors];
        return;
    }

    /*
     * Use an explicit stack, not recursion.
     * The recursive form is not a tail call.
     * The sibling loop continues after each child call returns.
     * Only JavaScriptCore performs tail call optimization.
     * The explicit stack prevents stack overflow on deep trees.
     */
    var stack = [];

    [stack addObject:self];

    while ([stack count])
    {
        var node = [stack lastObject];

        [stack removeLastObject];

        [node _sortChildNodesUsingDescriptors:sortDescriptors];

        var count = [node._childNodes count];

        while (count--)
        {
            [stack addObject:[node._childNodes objectAtIndex:count]];
        }
    }
}

- (CPTreeNode)descendantNodeAtIndexPath:(CPIndexPath)indexPath
{
    if (!indexPath || [indexPath length] == 0)
        return self;

    var node = self,
    length = [indexPath length];

    for (var i = 0; i < length; i++)
    {
        var index = [indexPath indexAtPosition:i],
        count = [node countOfChildNodes];

        if (index < 0 || index >= count)
            return nil;

        node = [node objectInChildNodesAtIndex:index];
    }

    return node;
}

@end

var CPTreeNodeRepresentedObjectKey  = @"CPTreeNodeRepresentedObjectKey",
    CPTreeNodeParentNodeKey         = @"CPTreeNodeParentNodeKey",
    CPTreeNodeChildNodesKey         = @"CPTreeNodeChildNodesKey";

@implementation CPTreeNode (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _representedObject = [aCoder decodeObjectForKey:CPTreeNodeRepresentedObjectKey];
        _parentNode = [aCoder decodeObjectForKey:CPTreeNodeParentNodeKey];
        _childNodes = [aCoder decodeObjectForKey:CPTreeNodeChildNodesKey];

        if (!_childNodes)
            _childNodes = [];

        if (![_childNodes isKindOfClass:[CPMutableArray class]])
            _childNodes = [_childNodes mutableCopy];

        /*
         * The child array is the authoritative structure.
         * Re-establish the parent links.
         * This makes the decoded tree match the tree built by the mutation methods.
         */
        var count = [_childNodes count];

        while (count--)
        {
            var child = [_childNodes objectAtIndex:count];

            [self _validateChildNode:child];
            child._parentNode = self;
        }
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_representedObject forKey:CPTreeNodeRepresentedObjectKey];
    [aCoder encodeConditionalObject:_parentNode forKey:CPTreeNodeParentNodeKey];
    [aCoder encodeObject:_childNodes forKey:CPTreeNodeChildNodesKey];
}

@end
