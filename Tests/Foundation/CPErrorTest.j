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

- (void)testUserInfoDict
{
    var userInfo = @{
        CPLocalizedDescriptionKey: @"A localized error description",
        CPUnderlyingErrorKey: @"An underlying error",
        CPLocalizedFailureReasonErrorKey: @"A localized error reason",
        CPLocalizedRecoverySuggestionErrorKey: @"The world is about to explode. You can choose to ignore this.",
        CPLocalizedRecoveryOptionsErrorKey: ["Cry", "Ignore"]
    },
        err = [CPError errorWithDomain:CPCappuccinoErrorDomain
                                  code:-10
                              userInfo:userInfo];

    [self assertNotNull:[err userInfo]];
    [self assert:[err localizedDescription] equals:@"A localized error description"];
    [self assert:[err localizedRecoveryOptions] equals:["Cry", "Ignore"]];
    [self assertNull:[err recoveryAttempter]];
}

@end