@import <Foundation/CPException.j>

@implementation CPExceptionTest : OJTestCase
{
    CPException exception;
}

- (void)setUp
{
    exception = [CPException exceptionWithName:@"CPGenericException"
                                        reason:@"Margins must be positive"
                                      userInfo:nil];
}

- (void)testInitWithNameReasonUserInfo
{
    exception = [[CPException alloc] initWithName:@"CPUnsupportedMethodException"
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

- (void)testRaise_format_
{
    var success = NO;
    try
    {
        [CPException raise:CPGenericException format:@"Expected %.2f for %s", 0.789, "hello"];
    }
    catch (anException)
    {
        success = YES;
        [self assert:CPGenericException equals:[anException name]];
        [self assert:@"Expected 0.79 for hello" equals:[anException reason]];
    }
    [self assertTrue:success];
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
    [self assertThrows:function() { [exception raise]; }];
}

@end
