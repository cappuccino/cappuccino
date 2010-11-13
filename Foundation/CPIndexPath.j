
@import <Foundation/CPRange.j>
@import <Foundation/CPObject.j>
@import <Foundation/CPArray.j>
@import <Foundation/CPSortDescriptor.j>
@import <Foundation/CPException.j>


@implementation CPIndexPath : CPObject
{
    CPArray _indexes @accessors(property=indexes);
}

+ (id)indexPathWithIndex:(int)index
{
    return [[self alloc] initWithIndexes:[index] length:1];
}

+ (id)indexPathWithIndexes:(CPArray)indexes length:(int)length
{
    return [[self alloc] initWithIndexes:indexes length:length];
}

+ (id)indexPathWithIndexes:(CPArray)indexes
{
    return [[self alloc] initWithIndexes:indexes];
}

- (id)initWithIndexes:(CPArray)indexes length:(int)length
{
    self = [super init];
    
    if(self)
    {
        _indexes = [indexes subarrayWithRange:CPMakeRange(0,length)];
    }
    
    return self;
}

- (id)initWithIndexes:(CPArray)indexes
{
    self = [super init];
    
    if(self)
    {
        _indexes = [indexes copy];
    }
    
    return self;
}

- (CPString)description
{
    return [super description] + " " + _indexes;
}

#pragma mark -
#pragma mark Accessing

- (id)length
{
    return [_indexes count];
}

- (int)indexAtPosition:(int)position
{
    return [_indexes objectAtIndex:position];
}

#pragma mark -
#pragma mark Modification

- (CPIndexPath)indexPathByAddingIndex:(int)index
{
    return [CPIndexPath indexPathWithIndexes:[_indexes arrayByAddingObject:index]];
}

- (CPIndexPath)indexPathByRemovingLastIndex
{
    return [CPIndexPath indexPathWithIndexes:_indexes length:[self length]];
}

#pragma mark -
#pragma mark Comparison

- (BOOL)isEqual:(id)object
{
    if(![object class] === CPIndexPath)
        return NO;
    
    return [_indexes isEqualToArray:[object indexes]];
}

- (CPComparisonResult)compare:(CPIndexPath)indexPath
{
    if(!indexPath)
        [CPException raise:CPInvalidArgumentException reason:"indexPath to " + self + " was nil"];
    
    var lhsIndexes = [self indexes],
        rhsIndexes = [indexPath indexes];
    
    var count = MIN([lhsIndexes count], [rhsIndexes count]);
    
    for(var i = 0; i < count; i++) {
        var lhs = lhsIndexes[i],
            rhs = rhsIndexes[i];
        
        if(lhs < rhs)
            return CPOrderedAscending;
        else if(lhs > rhs)
            return CPOrderedDescending;
    }
    
    if([lhsIndexes count] == [rhsIndexes count])
        return CPOrderedSame;
    
    return ([lhsIndexes count] == count) ? CPOrderedAscending : CPOrderedDescending;
}

@end
