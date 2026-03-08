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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <Foundation/CPObject.j>
@import <Foundation/CPIndexPath.j>
@import <Foundation/CPArray.j>

@implementation CPTreeNode : CPObject
{
    id              _representedObject  @accessors(property=representedObject);
    CPTreeNode      _parentNode         @accessors(property=parentNode);
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

- (CPIndexPath)indexPath
{
    // If we have a parent, calculate path based on parent's path + our index
    if (_parentNode)
    {
        var index = [_childNodes indexOfObjectIdenticalTo:self];
        
        // If the parent is the root (and technically has no path itself in some implementations),
        // we might get nil. Handle that gracefully.
        var parentPath = [_parentNode indexPath];
        
        if (parentPath)
            return [parentPath indexPathByAddingIndex:index];
            
        return [CPIndexPath indexPathWithIndex:index];
    }
    
    // If we are the root, we don't have an index path in the context of a tree controller usually,
    // or we are [] (empty path). Returning nil is acceptable for the absolute root.
    return nil; 
}

- (BOOL)isLeaf
{
    return [_childNodes count] == 0;
}

- (CPArray)childNodes
{
    // Return a copy to prevent external modification without KVC
    return [_childNodes copy];
}

- (CPMutableArray)mutableChildNodes
{
    return [self mutableArrayValueForKey:@"childNodes"];
}

// MARK: - KVC Compliance Methods

- (void)insertObject:(CPTreeNode)aTreeNode inChildNodesAtIndex:(CPInteger)anIndex
{
    // Optional: Auto-detach from old parent if strictly moving nodes
    if ([aTreeNode isKindOfClass:[CPTreeNode class]] && aTreeNode._parentNode)
    {
        [[aTreeNode._parentNode mutableChildNodes] removeObjectIdenticalTo:aTreeNode];
    }

    // Direct ivar access is allowed here since we are inside the class implementation
    if ([aTreeNode isKindOfClass:[CPTreeNode class]])
        aTreeNode._parentNode = self;

    [_childNodes insertObject:aTreeNode atIndex:anIndex];
}

- (void)removeObjectFromChildNodesAtIndex:(CPInteger)anIndex
{
    var node = [_childNodes objectAtIndex:anIndex];
    
    if ([node isKindOfClass:[CPTreeNode class]])
        node._parentNode = nil;

    [_childNodes removeObjectAtIndex:anIndex];
}

- (void)replaceObjectFromChildNodesAtIndex:(CPInteger)anIndex withObject:(id)aTreeNode
{
    var oldTreeNode = [_childNodes objectAtIndex:anIndex];

    if ([oldTreeNode isKindOfClass:[CPTreeNode class]])
        oldTreeNode._parentNode = nil;
    
    if ([aTreeNode isKindOfClass:[CPTreeNode class]])
        aTreeNode._parentNode = self;

    [_childNodes replaceObjectAtIndex:anIndex withObject:aTreeNode];
}

// MARK: - Convenience Accessors

- (id)objectInChildNodesAtIndex:(CPInteger)anIndex
{
    return [_childNodes objectAtIndex:anIndex];
}

- (CPInteger)count
{
    return [_childNodes count];
}

- (id)objectAtIndex:(CPInteger)anIndex
{
    return [_childNodes objectAtIndex:anIndex];
}

// MARK: - Utility

- (void)sortWithSortDescriptors:(CPArray)sortDescriptors recursively:(BOOL)shouldSortRecursively
{
    [_childNodes sortUsingDescriptors:sortDescriptors];

    if (!shouldSortRecursively)
        return;

    var count = [_childNodes count];
    while (count--)
    {
        var child = [_childNodes objectAtIndex:count];
        if ([child respondsToSelector:@selector(sortWithSortDescriptors:recursively:)])
            [child sortWithSortDescriptors:sortDescriptors recursively:YES];
    }
}

- (CPTreeNode)descendantNodeAtIndexPath:(CPIndexPath)indexPath
{
    if (!indexPath || [indexPath length] == 0)
        return self;

    var index = [indexPath indexAtPosition:0],
        count = [_childNodes count];
        
    if (index >= count)
        return nil;
        
    var child = [_childNodes objectAtIndex:index];
    
    if ([indexPath length] == 1)
        return child;
        
    return [child descendantNodeAtIndexPath:[indexPath indexPathByRemovingFirstIndex]];
}

@end

// Coding implementation remains correct
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
        
        // Safety check to ensure decoding gave us a CPArray
        if (!_childNodes)
            _childNodes = [[CPMutableArray alloc] init];
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
