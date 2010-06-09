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
