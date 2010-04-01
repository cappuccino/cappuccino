
@import "CPObject.j"

var MAIN_POOL = nil;

@implementation CPAutoreleasePool : CPObject
{
    CPArray _objects;
}

+ (void)initialize
{
    MAIN_POOL = [CPAutoreleasePool new];
}

+ (id)_mainAutoreleasePool
{
    return MAIN_POOL;
}

+ (void)addObject:(id)anObject
{
    [[self _mainAutoreleasePool] addObject:anObject];
}

- (id)init
{
    if (self = [super init])
    {
        _objects = [];
        [[CPRunLoop currentRunLoop] performSelector:@selector(drain) target:self argument:nil order:0 modes:[CPDefaultRunLoopMode]];
    }

    return self;
}

- (void)addObject:(id)anObject
{
    _objects.push(anObject);
}

- (void)drain
{
    for (var i = 0, count = [_objects count]; i < count; i++)
        [_objects.pop() release];

    [[CPRunLoop currentRunLoop] performSelector:@selector(drain) target:self argument:nil order:0 modes:[CPDefaultRunLoopMode]];
}

- (void)dealloc
{
    [self drain];
    [super dealloc];
}

@end
