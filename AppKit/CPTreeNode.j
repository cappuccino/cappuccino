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
@import <Foundation/CPArray.j>

/*
 * CPTreeNode implements the NSTreeNode contract.
 * The _childNodes array contains only CPTreeNode instances.
 * The representedObject property contains the application data.
 * The _parentNode and _childNodes properties maintain a strict bidirectional relationship.
 * The KVC mutation methods are the public mechanism to change the tree structure.
 */
@implementation CPTreeNode : CPObject
{
    /*
     * KVO notifications on childNodes and parentNode are not reliable during
     * internal structural moves. insertObject:inChildNodesAtIndex: and
     * replaceObjectInChildNodesAtIndex:withObject: detach a node from its
     * prior position by mutating _childNodes directly, or through
     * _removeChildNode:, bypassing the KVC proxy for that step. An observer
     * of the old parent's childNodes, or of a moved node's parentNode, can
     * miss the change entirely or see it reported as the wrong kind of
     * change. This is a deliberate trade against the cost of routing every
     * internal detach through the proxy. Do not rely on these two
     * properties for observation during a move; rely only on the state
     * after the call returns.
     */
    id              _representedObject  @accessors(readonly, property=representedObject);
    CPTreeNode      _parentNode         @accessors(readonly, property=parentNode);
    CPMutableArray  _childNodes;
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
 * Remove a child node directly.
 * This method bypasses the KVC proxy methods.
 * Use this method for internal structural changes to prevent KVO overhead.
 */
- (void)_removeChildNode:(CPTreeNode)aNode
{
    var index = [_childNodes indexOfObjectIdenticalTo:aNode];

    /*
     * A caller reaches this method only when aNode.parentNode already equals
     * self (see the two call sites below). If self._childNodes does not
     * actually contain aNode at that point, the parent/child relationship
     * is already broken. indexPath raises for this identical class of
     * inconsistency; silently returning here would hide the same problem
     * instead of surfacing it.
     */
    if (index === CPNotFound)
    {
        [CPException raise:CPInternalInconsistencyException
                    reason:"CPTreeNode parent and child relationship is inconsistent."];
    }

    aNode._parentNode = nil;
    [_childNodes removeObjectAtIndex:index];
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
    var count = [_childNodes count];

    if (anIndex < 0 || anIndex > count)
    {
        [CPException raise:CPRangeException
                    reason:"index (" + anIndex + ") beyond bounds (0 .. " + count + ") for insertObject:inChildNodesAtIndex:"];
    }

    [self _validateChildNode:aTreeNode];

    if ([self _wouldCreateCycleWithNode:aTreeNode])
    {
        [CPException raise:CPInvalidArgumentException
                    reason:"Inserting a CPTreeNode beneath itself or one of its descendants makes a cycle."];
    }

    /*
     * Detach the node from its old parent first.
     * The code validated the index before this change.
     */
    if (aTreeNode._parentNode)
    {
        if (aTreeNode._parentNode === self)
        {
            var originalIndex = [_childNodes indexOfObjectIdenticalTo:aTreeNode];

            /*
             * Bypass KVO for this internal structural adjustment.
             */
            aTreeNode._parentNode = nil;
            [_childNodes removeObjectAtIndex:originalIndex];

            /*
             * The removal shifts the array elements.
             * Adjust the target index to maintain the position relative to the original array.
             * This matches the Cocoa move semantics.
             */
            if (originalIndex < anIndex)
                --anIndex;
        }
        else
        {
            /*
             * Detach the node from its old parent.
             * Use the internal method to bypass KVO overhead.
             */
            [aTreeNode._parentNode _removeChildNode:aTreeNode];
        }
    }

    aTreeNode._parentNode = self;
    [_childNodes insertObject:aTreeNode atIndex:anIndex];
}

- (void)removeObjectFromChildNodesAtIndex:(CPInteger)anIndex
{
    var node = [_childNodes objectAtIndex:anIndex];

    node._parentNode = nil;
    [_childNodes removeObjectAtIndex:anIndex];
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

    /*
     * If the replacement node is already a child of this parent, remove it first.
     * The removal shifts the array elements.
     * Adjust the target index before the replace operation.
     * This matches the Cocoa KVC mutation semantics.
     */
    var oldParent = aTreeNode._parentNode;

    if (oldParent === self)
    {
        var replacementIndex = [_childNodes indexOfObjectIdenticalTo:aTreeNode];

        /*
         * aTreeNode.parentNode already equals self at this point. If
         * self._childNodes does not actually contain aTreeNode, the
         * parent/child relationship is already broken. indexPath raises
         * for this identical class of inconsistency; proceeding here would
         * silently tolerate the same problem instead of surfacing it.
         */
        if (replacementIndex === CPNotFound)
        {
            [CPException raise:CPInternalInconsistencyException
                        reason:"CPTreeNode parent and child relationship is inconsistent."];
        }

        /*
         * Bypass KVO for this internal structural adjustment.
         */
        aTreeNode._parentNode = nil;
        [_childNodes removeObjectAtIndex:replacementIndex];

        if (replacementIndex < anIndex)
            --anIndex;
    }
    else if (oldParent)
    {
        /*
         * Detach the node from its old parent.
         * Use the internal method to bypass KVO overhead.
         */
        [oldParent _removeChildNode:aTreeNode];
    }

    oldTreeNode._parentNode = nil;
    aTreeNode._parentNode = self;

    [_childNodes replaceObjectAtIndex:anIndex withObject:aTreeNode];
}

- (id)objectInChildNodesAtIndex:(CPInteger)anIndex
{
    return [_childNodes objectAtIndex:anIndex];
}

- (CPInteger)countOfChildNodes
{
    return [_childNodes count];
}

- (void)sortWithSortDescriptors:(CPArray)sortDescriptors recursively:(BOOL)shouldSortRecursively
{
    if (!shouldSortRecursively)
    {
        [_childNodes sortUsingDescriptors:sortDescriptors];
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

        [node._childNodes sortUsingDescriptors:sortDescriptors];

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
