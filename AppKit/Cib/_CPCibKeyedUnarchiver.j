
@import <Foundation/CPKeyedUnarchiver.j>


@implementation _CPCibKeyedUnarchiver : CPKeyedUnarchiver
{
    CPBundle    _bundle;
}

- (id)initForReadingWithData:(CPData)data bundle:(CPBundle)aBundle
{
    self = [super initForReadingWithData:data];
    
    if (self)
    {
        _bundle = aBundle;
        
        [self setDelegate:self];
    }
    
    return self;
}

- (CPBundle)bundle
{
    return _bundle;
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