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
    var newVersion = ROUND(RAND() * 100);

    // make sure it's not zero
    while (newVersion == 0)
        newVersion = ROUND(RAND() * 100);

    [CPObject setVersion:newVersion];

    // test to make sure the assignment worked
    [self assert:[CPObject version] equals:newVersion];
}

- (void)testMultipleArgumentPerformSelector
{
    var receiver = [[Receiver alloc] init],

        value1 = "a",
        value2 = "b",
        value3 = "c",
        value4 = "d",
        selector = @selector(implements:multiple:argument:selector:),

        returnValue = [receiver performSelector:selector withObjects:value1, value2, value3, value4],

        expectedReturnValue = value1 + value2 + value3 + value4;

    [self assertTrue:expectedReturnValue === returnValue];
}

- (void)testCPDescriptionOfObject
{
    var jSON = {"name": "Martin", "access":null},
        d = CPDescriptionOfObject(jSON);

    [self assertTrue:d.indexOf("name:") !== -1 message:"Can't find 'name:' in description of json " + d];
    [self assertTrue:d.indexOf("access:") !== -1 message:"Can't find 'access:' in description of json " + d];
}

- (void)testCPObjectNotEqualToNil
{
    var anObject = [[CPObject alloc] init];

    [self assert:anObject notEqual:nil];
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

- (id)implements:(id)a multiple:(id)b argument:(id)c selector:(id)d
{
    return a + b + c + d;
}
@end
