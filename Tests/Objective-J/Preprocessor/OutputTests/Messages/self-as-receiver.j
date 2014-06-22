@implementation MyClass

- (id)mySelector
{
    [self init];
    self = nil;
    [self init];
}

- (id)mySelector2
{
    [self init];
    eval("self = null;");
    [self init];
}

@end
