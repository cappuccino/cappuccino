@import <Foundation/Foundation.j>

@implementation IvarTestClass : CPObject
{
    id ivar1 @accessors;
    var ivar2 @accessors(readonly);
    CPNumber ivar3;
}

- (void)setIvar1UsingEval:(id)value
{
    eval(@"var ivar1 = " + value);
}

- (void)doNothingToIvar1UsingEval:(id)value
{
    (function()
    {
        eval(@"var ivar1 = " + value);
    })();
}

- (void)setIvar1DespiteAWithStatement:(id)value
{
    with({})
    {
        ivar1 = value;
    }
}

- (void)doNothingToIvar1BecauseOfWithStatement:(id)value
{
    with({'ivar1':null})
    {
        ivar1 = value;
    }
}

- (void)setIvar1UsingAShadowingLocalVariable:(id)ivar1
{
    self.ivar1 = ivar1;
}

@end

@implementation IvarTest : OJTestCase
{
    IvarTestClass testClass;
}

- (void)setUp
{
    testClass = [[IvarTestClass alloc] init];
}

- (void)testDirectAccess
{
    [self assert:nil equals:testClass.ivar1];
    testClass.ivar1 = 5;
    [self assert:5 equals:testClass.ivar1];
}

- (void)testWithStatementInMethod
{
    [self assert:nil equals:testClass.ivar1];
    [testClass setIvar1DespiteAWithStatement:5];
    [self assert:5 equals:testClass.ivar1];
    [testClass doNothingToIvar1BecauseOfWithStatement:10];
    [self assert:5 equals:testClass.ivar1];
}

- (void)testEvalInMethod
{
    [self assert:nil equals:testClass.ivar1];
    [testClass setIvar1UsingEval:5];
    [self assert:5 equals:testClass.ivar1];
    [testClass doNothingToIvar1UsingEval:10];
    [self assert:5 equals:testClass.ivar1];
}

- (void)testIvarShadowing
{
    [self assert:nil equals:testClass.ivar1];
    [testClass setIvar1UsingAShadowingLocalVariable:5];
    [self assert:5 equals:testClass.ivar1];
}

- (void)testAccessorGeneration
{
    [self assert:nil equals:[testClass ivar1]];
    [testClass setIvar1:10];
    [self assert:10 equals:[testClass ivar1]];
    [self assert:10 equals:testClass.ivar1];

    [self assert:nil equals:[testClass ivar2]];
    testClass.ivar2 = 5;
    [self assert:5 equals:[testClass ivar2]];
    [self assert:5 equals:testClass.ivar2];
    [self assertThrows:function()
    {
        [testClass setIvar2:6];
    }];
    [self assert:5 equals:[testClass ivar2]];

    [self assert:nil equals:testClass.ivar3];
    [self assertThrows:function()
    {
        [testClass ivar3];
    }];
    [self assertThrows:function()
    {
        [testClass setIvar3:20];
    }];
    [self assert:nil equals:testClass.ivar3];
}

@end
