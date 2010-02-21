
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
