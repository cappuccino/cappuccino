
import <Foundation/CPKeyedUnarchiver.j>


@implementation _CPCibKeyedUnarchiver : CPKeyedUnarchiver
{
}

- (id)decodeObjectForKey:(CPString)aKey
{
    var object = [super decodeObjectForKey:aKey];
    
    if ([object respondsToSelector:@selector(_cibInstantiate)])
    {
        var index = [[_plistObject objectForKey:aKey] objectForKey:_CPKeyedArchiverUIDKey],
            processedObject = [object _cibInstantiate];
            
        if (processedObject != object)
        {
            object = processedObject;
        
            [self replaceObjectAtUID:index withObject:processedObject];
        }
    }
    
    return object;
}

- (void)replaceObjectAtUID:(int)aUID withObject:(id)anObject
{
    _objects[aUID] = anObject;
}

@end