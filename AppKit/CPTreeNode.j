
@import <Foundation/CPObject.j>


@implementation CPTreeNode : CPObject
{
    id              _representedObject @accessors(readonly, property=representedObject);
    
    CPTreeNode      _parentNode @accessors(readonly, property=parentNode);
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

- (BOOL)isLeaf
{
    return [_childNodes count] <= 0;
}

- (CPArray)childNodes
{
    return [_childNodes copy];
}

- (CPMutableArray)mutableChildNodes
{
    return [self mutableArrayValueForKey:@"childNodes"];
}

- (void)insertObject:(id)aTreeNode inChildNodesAtIndex:(CPInteger)anIndex
{
    [[aTreeNode._parentNode mutableChildNodes] removeObjectIdenticalTo:aTreeNode];

    aTreeNode._parentNode = self;

    [_childNodes insertObject:aTreeNode atIndex:anIndex];
}

- (void)removeObjectFromChildNodesAtIndex:(CPInteger)anIndex
{
    [_childNodes objectAtIndex:anIndex]._parentNode = nil;

    [_childNodes removeObjectAtIndex:anIndex];
}

- (void)replaceObjectFromChildNodesAtIndex:(CPInteger)anIndex withObject:(id)aTreeNode
{
    var oldTreeNode = [_childNodes objectAtIndex:anIndex];

    oldTreeNode._parentNode = nil;
    aTreeNode._parentNode = self;

    [_childNodes replaceObjectAtIndex:anIndex withObject:aTreeNode];
}

- (id)objectInChildNodesAtIndex:(CPInteger)anIndex
{
    return _childNodes[anIndex];
}

- (void)sortWithSortDescriptors:(CPArray)sortDescriptors recursively:(BOOL)shouldSortRecursively
{
    [_childNodes sortUsingDescriptors:sortDescriptors];

    if (!shouldSortRecursively)
        return;

    var count = [_childNodes count];

    while (count--)
        [_childNodes[count] sortWithSortDescriptors:sortDescriptors recursively:YES];
}

- (CPEnumerator)preOrder
{
    return [_CPTreeNodeEnumerator enumeratorWithTreeNode:self order:_CPTreeNodeEnumeratorPreOrder];
}

- (CPEnumerator)inOrder
{
    return [_CPTreeNodeEnumerator enumeratorWithTreeNode:self order:_CPTreeNodeEnumeratorInOrder];
}

- (CPEnumerator)postOrder
{
    return [_CPTreeNodeEnumerator enumeratorWithTreeNode:self order:_CPTreeNodeEnumeratorPostOrder];
}

- (CPEnumerator)levelOrder
{
    return [_CPTreeNodeEnumerator enumeratorWithTreeNode:self order:_CPTreeNodeEnumeratorLevelOrder];
}

- (int)countByEnumeratingWithState:(id)aState objects:(id)objects count:(id)aCount
{
    if (aState.state !== 0)
        return 0;

    // FIXME: Change this to inorder when implemented?
    var count = [[self preOrder] countByEnumeratingWithState:aState objects:objects count:aCount];

    // Dangerous?
    aState.state = YES;

    return count;
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

var _CPTreeNodeEnumeratorPreOrder   = 0,
    _CPTreeNodeEnumeratorInOrder    = 1,
    _CPTreeNodeEnumeratorPostOrder  = 2,
    _CPTreeNodeEnumeratorLevelOrder = 3;

@implementation _CPTreeNodeEnumerator : CPEnumerator
{
    int         _order;
    Object      _state;
    CPTreeNode  _treeNode;
}

+ (_CPTreeNodeEnumerator)enumeratorWithTreeNode:(CPTreeNode)aTreeNode order:(int)anOrder
{
    return [[self alloc] initWithTreeNode:aTreeNode order:anOrder];
}

- (id)initWithTreeNode:(CPTreeNode)aTreeNode order:(int)anOrder
{
    self = [super init];

    if (self)
    {
        _order = anOrder
        _state = [self _newState];
        _treeNode = aTreeNode;
    }

    return self;
}

- (id)_newState
{
    return { stack:[_treeNode], visited:[CPSet set] };
}

- (id)_preOrderFromState:(Object)state allObjects:(BOOL)shouldReturnAllObjects
{
    var stack = state.stack;

    if (stack.length <= 0)
        return nil;

    if (shouldReturnAllObjects)
        var allObjects = [];

    while (stack.length)
    {
        var currentNode = stack.pop(),
            childNodes = currentNode._childNodes,
            count = childNodes.length;

        while (count--)
            stack.push(childNodes[count]);

        if (shouldReturnAllObjects)
            allObjects.push(currentNode);
        else
            return currentNode;
    }

    return allObjects;
}

- (id)_inOrderFromState:(Object)state allObjects:(BOOL)shouldReturnAllObjects
{
    // Implement.
}

- (id)_postOrderFromState:(Object)state allObjects:(BOOL)shouldReturnAllObjects
{
    var stack = state.stack;

    if (stack.length <= 0)
        return nil;

    var visited = state.visited;

    if (shouldReturnAllObjects)
        var allObjects = [];

    while (stack.length)
    {
        var currentNode = [stack lastObject],
            childNodes = currentNode._childNodes,
            originalCount = stack.length,
            count = childNodes.length;

        while (count--)
        {
            var treeNode = childNodes[count];

            if ([visited containsObject:treeNode])
                continue;
            else
                stack.push(treeNode);
        }

        if (originalCount === stack.length)
        {
            [visited addObject:currentNode];

            if (shouldReturnAllObjects)
                allObjects.push(stack.pop());
            else
                return stack.pop();
        }
    }

    return allObjects;
}

- (id)_levelOrderFromState:(Object)state allObjects:(BOOL)shouldReturnAllObjects
{
    // Implement.
}

- (id)nextObject
{
    if (_order === _CPTreeNodeEnumeratorPreOrder)
        return [self _preOrderFromState:[self _newState] allObjects:NO];

    else if (_order === _CPTreeNodeEnumeratorInOrder)
        return [self _inOrderFromState:[self _newState] allObjects:NO];

    else if (_order === _CPTreeNodeEnumeratorPostOrder)
        return [self _postOrderFromState:[self _newState] allObjects:NO];

    //else if (_order === _CPTreeNodeEnumeratorLevelOrder)
        return [self _levelOrderFromState:[self _newState] allObjects:NO];

}

- (CPArray)allObjects
{
    if (_order === _CPTreeNodeEnumeratorPreOrder)
        return [self _preOrderFromState:[self _newState] allObjects:YES];

    else if (_order === _CPTreeNodeEnumeratorInOrder)
        return [self _inOrderFromState:[self _newState] allObjects:YES];

    else if (_order === _CPTreeNodeEnumeratorPostOrder)
        return [self _postOrderFromState:[self _newState] allObjects:YES];

    //else if (_order === _CPTreeNodeEnumeratorLevelOrder)
        return [self _levelOrderFromState:[self _newState] allObjects:NO];
}

- (int)countByEnumeratingWithState:(id)aState objects:(id)objects count:(id)aCount
{
    if (aState.state !== 0)
        return 0;

    var count = [[self allObjects] countByEnumeratingWithState:aState objects:objects count:aCount];

    // Dangerous?
    aState.state = YES;

    return count;
}

@end
