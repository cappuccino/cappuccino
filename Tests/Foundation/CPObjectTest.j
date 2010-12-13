@import <Foundation/CPObject.j>

@implementation CPObjectTest : OJTestCase
{
}

- (void)testImplementsSelector
{
    var receiver = [[Receiver alloc] init];

    [self assertTrue:[receiver implementsSelector:@selector(implementedInReceiverAndSuper)]];
    [self assertTrue:[receiver implementsSelector:@selector(implementedInReceiverOnly)]];

    [self assertFalse:[receiver implementsSelector:@selector(implementedInSuperOnly)]];
    [self assertFalse:[receiver implementsSelector:@selector(notImplementedInSuperNorReceiver)]];
}

- (void)testVersion
{
    // zero by default
    [self assert:[CPObject version] equals:0];

    // create a random new version and round it to an integer
    var newVersion = ROUND(RAND()*100);

    // make sure it's not zero
    while (newVersion == 0)
        newVersion = ROUND(RAND()*100);

    [CPObject setVersion:newVersion];

    // test to make sure the assignment worked
    [self assert:[CPObject version] equals:newVersion];
}

@end

@implementation SuperReceiver : CPObject
{
}

- (void)implementedInReceiverAndSuper
{
}

- (void)implementedInSuperOnly
{
}
@end

@implementation Receiver : SuperReceiver
{
}

- (void)implementedInReceiverAndSuper
{
}

- (void)implementedInReceiverOnly
{
}
@end
