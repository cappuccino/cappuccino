@import <OJUnit/OJTestCase.j>

var addRef = function(aRef)
    {
        @deref(aRef) += 1;
    },
    subtractRef = function(aRef)
    {
        @deref(aRef) -= 1;
    },
    multiplyRef = function(aRef)
    {
        @deref(aRef) *= 2;
    },
    divideRef = function(aRef)
    {
        @deref(aRef) /= 2;
    },
    setRef = function(aRef)
    {
        @deref(aRef) = 5;
    },
    getRef = function(aRef)
    {
        return @deref(aRef)
    },
    incrementRefPrefix = function(aRef)
    {
        return ++@deref(aRef);
    },
    incrementRefPostfix = function(aRef)
    {
        return @deref(aRef)++;
    },
    decrementRefPrefix = function(aRef)
    {
        return --@deref(aRef);
    },
    decrementRefPostfix = function(aRef)
    {
        return @deref(aRef)--;
    };

@implementation PassByReferenceTest : OJTestCase

- (void)testGetByReference
{
    var x = -1;

    [self assert:-1 equals:@deref(@ref(x))];
    [self assert:-1 equals:getRef(@ref(x))];
}

- (void)testSetByReference
{
    var x = -1;

    setRef(@ref(x));

    [self assert:5 equals:x];
}

- (void)testAddByReference
{
    var x = -1;

    addRef(@ref(x));

    [self assert:0 equals:x];
}

- (void)testSubtractByReference
{
    var x = -1;

    subtractRef(@ref(x));

    [self assert:-2 equals:x];
}

- (void)testIncrementPrefixByReference
{
    var x = -1,
        r = incrementRefPrefix(@ref(x));

    [self assert:0 equals:r];
    [self assert:0 equals:x];
}

- (void)testIncrementPostfixByReference
{
    var x = -1,
        r = incrementRefPostfix(@ref(x));

    [self assert:-1 equals:r];
    [self assert:0 equals:x];
}

- (void)testDecrementPrefixByReference
{
    var x = -1,
        r = decrementRefPrefix(@ref(x));

    [self assert:-2 equals:r];
    [self assert:-2 equals:x];
}

- (void)testDecrementPostfixByReference
{
    var x = -1,
        r = decrementRefPostfix(@ref(x));

    [self assert:-1 equals:r];
    [self assert:-2 equals:x];
}

- (void)testMultiplyByReference
{
    var x = -1;

    multiplyRef(@ref(x));

    [self assert:-2 equals:x];
}

- (void)testDivideByReference
{
    var x = -1;

    divideRef(@ref(x));

    [self assert:-0.5 equals:x];
}

- (void)testComplexDereference
{
    var x = 1,
        xRef = @ref(x),
        xRefRef = @ref(xRef),
        y = 10,
        yRef = @ref(y),
        yRefRef = @ref(yRef);

    var r = @deref(@deref(xRefRef))++;

    [self assert:1 equals:r];
    [self assert:2 equals:x];

    var r = @deref(@deref(x == 1 ? xRefRef : yRefRef))++;

    [self assert:10 equals:r];
    [self assert:2 equals:x];
    [self assert:11 equals:y];
}

@end
