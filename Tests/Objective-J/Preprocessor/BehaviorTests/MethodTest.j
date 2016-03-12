@import <Foundation/Foundation.j>

@import <OJUnit/OJTestCase.j>

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

- (id)in:(int)aNumber void:(int)anotherNumber
{
    return aNumber - anotherNumber;
}

- (id)void:(int)aNumber in:(int)anotherNumber
{
    return anotherNumber - aNumber;
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
    [self assert:30 equals:[testClass multiply:2, 3, 5]];
    [self assert:2310 equals:[testClass multiply:2, 3, 5, 7, 11]];
}

- (void)testKeywordsInSelector
{
    [self assert:6 equals:[testClass in:10 void:4]];
    [self assert:-6 equals:[testClass void:10 in:4]];
}

- (void)testMethodName
{
    var method = class_getInstanceMethod(MathClass, @selector(sqrt:));

    [self assert:method_getName(method) equals:@"sqrt:"];
}

- (void)testMethodNoOfArguments
{
    var method = class_getInstanceMethod(MathClass, @selector(five));

    [self assert:method_getNumberOfArguments(method) equals:2];

    method = class_getInstanceMethod(MathClass, @selector(multiply:));
    [self assert:method_getNumberOfArguments(method) equals:3];

    method = class_getInstanceMethod(MathClass, @selector(multiply:with:));
    [self assert:method_getNumberOfArguments(method) equals:4];
}

- (void)testMethodTypes
{
    var theClass = objj_allocateClassPair(CPObject, RAND() + "");

    objj_registerClassPair(theClass);
    class_addMethod(theClass, @"myMethod:", function() { }, ["void", "CPNumber"]);
    class_addMethod(theClass, @"myMethod2:", function() { }, ["int", "float"]);
    class_addMethod(theClass, @"myMethod3:", function() { });
    [theClass new];

    var method = class_getInstanceMethod(theClass, @selector(myMethod:));

    [self assert:method_copyReturnType(method) equals:@"void" message:@"Return type of method 'myMethod:'"];
    [self assert:method_copyArgumentType(method, 0) equals:@"id"];
    [self assert:method_copyArgumentType(method, 1) equals:@"SEL"];
    [self assert:method_copyArgumentType(method, 2) equals:@"CPNumber"];
    [self assertTrue:method_copyArgumentType(method, 3) === nil];
    [self assert:method_getNumberOfArguments(method) equals:3];

    method = class_getInstanceMethod(theClass, @selector(myMethod2:));
    [self assert:method_copyReturnType(method) equals:@"int" message:@"Return type of method 'myMethod2:'"];
    [self assert:method_copyArgumentType(method, 0) equals:@"id"];
    [self assert:method_copyArgumentType(method, 1) equals:@"SEL"];
    [self assert:method_copyArgumentType(method, 2) equals:@"float"];
    [self assertTrue:method_copyArgumentType(method, 3) === nil];
    [self assert:method_getNumberOfArguments(method) equals:3];

    method = class_getInstanceMethod(theClass, @selector(myMethod3:));
    [self assertTrue:method_copyReturnType(method) == nil];
    [self assert:method_copyArgumentType(method, 0) equals:@"id"];
    [self assert:method_copyArgumentType(method, 1) equals:@"SEL"];
    [self assertTrue:method_copyArgumentType(method, 2) === nil];
    [self assert:method_getNumberOfArguments(method) equals:3];
}

@end
