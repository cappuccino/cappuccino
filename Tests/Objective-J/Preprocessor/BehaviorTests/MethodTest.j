@import <Foundation/Foundation.j>

@implementation MathClass : CPObject
{
}

- (CPNumber)five
{
    return 5;
}

- (CPNumber)sqrt:(CPNumber)operand
{
    return SQRT(operand);
}

- (CPNumber)multiply:(CPNumber)firstOperand with:(CPNumber)secondOperand
{
    return firstOperand * secondOperand;
}

- (CPNumber)multiply:(CPNumber)operand, ...
{
    var product;

    for (var i = 2, ii = arguments.length; i < ii; ++i)
        product = product ? product * arguments[i] : arguments[i];

    return product;
}

@end

@implementation MethodTest : OJTestCase
{
    MathClass testClass;
}

- (void)setUp
{
    testClass = [[MathClass alloc] init];
}

- (void)testNoParameters
{
    [self assert:5 equals:[testClass five]];
}

- (void)testOneParameter
{
    [self assert:2 equals:[testClass sqrt:4]];
}

- (void)testTwoParameters
{
    [self assert:6 equals:[testClass multiply:2 with:3]];
}

- (void)testVarArgs
{
    [self assert:30 equals:[testClass multiply:2,3,5]];
    [self assert:2310 equals:[testClass multiply:2,3,5,7,11]];
}

@end
