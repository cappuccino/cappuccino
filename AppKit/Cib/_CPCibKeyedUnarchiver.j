
@import <Foundation/CPKeyedUnarchiver.j>


@implementation _CPCibKeyedUnarchiver : CPKeyedUnarchiver
{
    CPBundle    _bundle;
    BOOL        _awakenCustomResources;
}

- (id)initForReadingWithData:(CPData)data bundle:(CPBundle)aBundle awakenCustomResources:(BOOL)shouldAwakenCustomResources
{
    self = [super initForReadingWithData:data];
    
    if (self)
    {
        _bundle = aBundle;
        _awakenCustomResources = shouldAwakenCustomResources;
        
        [self setDelegate:self];
    }
    
    return self;
}

- (CPBundle)bundle
{
    return _bundle;
}

- (BOOL)awakenCustomResources
{
    return _awakenCustomResources;
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