
import <Foundation/CPKeyedUnarchiver.j>


@implementation _CPCibKeyedUnarchiver : CPKeyedUnarchiver
{
}

- (id)initForReadingWithData:(CPData)data
{
    self = [super initForReadingWithData:data];
    
    if (self)
        [self setDelegate:self];
    
    return self;
}

- (id)unarchiver:(CPKeyedUnarchiver)aKeyedUnarchiver didDecodeObject:(id)anObject
{
    if ([anObject respondsToSelector:@selector(_cibInstantiate)])
        return [anObject _cibInstantiate];

    return anObject;
}

- (void)replaceObjectAtUID:(int)aUID withObject:(id)anObject
{
    _objects[aUID] = anObject;
}

- (id)objectAtUID:(int)aUID
{
    return _objects[aUID];
}

@end