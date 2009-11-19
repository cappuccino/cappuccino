
@import <Foundation/CPObject.j>


@implementation CPTreeNode : CPObject
{
    id              _representedObject @accessors(readonly, property=representedObject);
    
    CPTreeNode      _parentNode @accessors(readonly, property=parentNode);
    CPMutableArray  _childNodes @accessors(readonly, property=childNodes);
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

- (CPMutableArray)mutableChildNodes
{
    return [self mutableArrayValueForKey:@"childNodes"];
}

- (void)insertObject:(id)anObject inChildNodesAtIndex:(CPInteger)anIndex
{
    anObject._parentNode = self;

    [_childNodes addObject:anObject];
}

- (void)removeObjectFromChildNodesAtIndex:(CPInteger)anIndex
{
    [_childNodes objectAtIndex:anIndex]._parentNode = nil;

    [_childNodes removeObjectAtIndex:anIndex];
}

- (void)replaceObjectFromChildNodesAtIndex:(CPInteger)anIndex withObject:(id)anObject
{
    var oldObject = [_childNodes objectAtIndex:anIndex];

    oldObject._parentNode = nil;

    [_childNodes replaceObjectAtIndex:anIndex withObject:anObject];
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
