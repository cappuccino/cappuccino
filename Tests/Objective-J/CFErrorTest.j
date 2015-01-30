@import <OJUnit/OJTestCase.j>


@implementation CFErrorTest : OJTestCase

- (void)testCreate
{
    var err = new CFError();
    [self assertNotNull:err];
}

- (void)testCreateWithParams
{
    var err = new CFError(kCFErrorDomainCappuccino, -1000, nil);
    [self assertNotNull:err];
    [self assert:-1000 equals:err.code()];
}

- (void)testCreateGlobal
{
    var err = CFErrorCreate(kCFErrorDomainCappuccino, -1000, nil);
    [self assertNotNull:err];

    [self assert:kCFErrorDomainCappuccino equals:err.domain()];
    [self assert:-1000 equals:err.code()];
    [self assert:@"CPCappuccinoErrorDomain" equals:CFErrorGetDomain(err)];
}

- (void)testCreateWithUserInfoKeysAndValues
{
    var err = CFErrorCreateWithUserInfoKeysAndValues(kCFErrorDomainCappuccino, -1000, [kCFErrorLocalizedDescriptionKey, kCFErrorDescriptionKey], [@"A localized description", @"An error description"], 2);
    [self assertNotNull:err];

    var info = err.userInfo();
    [self assert:2 equals:info.count()];
}

- (void)testDescriptionCaseOne
{
    // Description case 1: Localized Key set
    var err = CFErrorCreateWithUserInfoKeysAndValues(kCFErrorDomainCappuccino, -1000, [kCFErrorLocalizedDescriptionKey], [@"A localized Description Key"], 1);
    [self assert:@"A localized Description Key" equals:err.description()];
    [self assert:@"A localized Description Key" equals:CFErrorCopyDescription(err)];
}

- (void)testDescriptionCaseTwo
{
    // Case 2: Reason set; description generated
    var err = CFErrorCreateWithUserInfoKeysAndValues(kCFErrorDomainCappuccino, -1000, [kCFErrorLocalizedFailureReasonKey], [@"A localized reason"], 1);
    [self assert:@"The operation couldn\u2019t be completed. A localized reason" equals:err.description()];
}

- (void)testDescriptionCaseThree
{
    // Case 3: Final fall-back.
    var err = CFErrorCreateWithUserInfoKeysAndValues(kCFErrorDomainCappuccino, -1000, [kCFErrorDescriptionKey], [@"A description key"], 1);
    [self assert:@"The operation couldn\u2019t be completed. (error -1000 - A description key)" equals:err.description()];
}

@end