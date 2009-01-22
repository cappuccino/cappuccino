
@import "CPSet.j"

@implementation CPCountedSet : CPMutableSet
{
    Object  _counts;
}

- (void)addObject:(id)anObject
{
    if (!_counts)
        _counts = {};
    
    [super addObject:anObject];
    
    var hash = [anObject hash];
    
    if (_counts[hash] === undefined)
        _counts[hash] = 1;
    else
        ++_counts[hash];
}

- (void)removeObject:(id)anObject
{
    if (!_counts)
        return;
        
    var hash = [anObject hash];
    
    if (_counts[hash] === undefined)
        return;
    
    else
    {
        --_counts[hash];
        
        if (_counts[hash] === 0)
        {
            delete _counts[hash];
            [super removeObject:anObject];
        }
    }
}

- (void)removeAllObjects
{
    [super removeAllObjects];
    _counts = {};
}

/*
    Returns the number of times anObject appears in the receiver.
    @param anObject The object to check the count for.
*/
- (unsigned)countForObject:(id)anObject
{
    if (!_counts)
        _counts = {};
    
    var hash = [anObject hash];
    
    if (_counts[hash] === undefined)
        return 0;
    
    return _counts[hash];
}


/* 

Eventually we should see what these are supposed to do, and then do that.

- (void)intersectSet:(CPSet)set

- (void)minusSet:(CPSet)set

- (void)unionSet:(CPSet)set

*/

@end
