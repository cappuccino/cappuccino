@import <Foundation/CPError.j>
@import <OJUnit/OJTestCase.j>

@implementation CPErrorTest : OJTestCase
{
}

- (void)testInstanceInstantiation
{
    var err = [[CPError alloc] initWithDomain:CPCappuccinoErrorDomain
                                         code:-10
                                     userInfo:nil];
    [self assertNotNull:err];
}

- (void)testClassInstantiation
{
    var err = [CPError errorWithDomain:CPCappuccinoErrorDomain
                                  code:-10
                              userInfo:nil];
    [self assertNotNull:err];
}

@end