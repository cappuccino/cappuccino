@import <Foundation/CPException.j>

@implementation CPExceptionTest : OJTestCase
{
}

- (void)setUp
{
    exception = [CPException exceptionWithName:@"CPGenericException"
                                        reason:@"Margins must be positive"
                                      userInfo:nil];
}

- (void)testInitWithNameReasonUserInfo
{
    var exception = [[CPException alloc] initWithName:@"CPUnsupportedMethodException"
                                               reason:@"setHeaderCell: is not supported. -setHeaderCell:aView instead."
                                             userInfo:nil];
    [self assert:[exception name] equals:"CPUnsupportedMethodException"];
    [self assert:[exception reason] equals:"setHeaderCell: is not supported. -setHeaderCell:aView instead."];
    [self assertThrows:function(){[exception raise]}];
}

- (void)testRaiseReason
{
    [self assertThrows:function(){[CPException raise:@"CPGenericException" reason:@"Margins must be positive"];}];
}

- (void)testName
{
    [self assert:[exception name] equals:@"CPGenericException"];
}

- (void)testReason
{
    [self assert:[exception reason] equals:@"Margins must be positive"];
}

- (void)testUserInfo
{
    [self assert:[exception userInfo] equals:null];
}

- (void)testRaise
{
    [self assertThrows:function(){[exception raise];}];
}

@end
