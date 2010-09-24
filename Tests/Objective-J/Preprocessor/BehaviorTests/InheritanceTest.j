@import <Foundation/Foundation.j>

@implementation ParentClass : CPObject
{
    id ivar;
}

- (CPString)classNameString
{
    return @"ParentClass";
}

@end

@implementation ChildClass : ParentClass
{
}

- (id)ivar
{
    return ivar;
}

- (void)setIvar:(id)newValue
{
    ivar = newValue;
}

- (CPString)classNameString
{
    return @"ChildClass";
}

- (CPString)parentClassNameString
{
    return [super classNameString];
}

@end

@implementation GrandChildClass : ChildClass
{
}

- (CPString)classNameString
{
    return @"GrandChildClass";
}

- (CPString)parentClassNameString
{
    return [super classNameString];
}

- (CPString)grandParentClassNameString
{
    return [super parentClassNameString];
}

@end

@implementation InheritanceTest : OJTestCase
{
    ParentClass parentClass;
    ChildClass childClass;
    GrandChildClass grandChildClass;
}

- (void)setUp
{
    parentClass = [[ParentClass alloc] init];
    childClass = [[ChildClass alloc] init];
    grandChildClass = [[GrandChildClass alloc] init];
}

- (void)testIvarInheritance
{
    [self assert:nil equals:parentClass.ivar];
    [self assert:nil equals:childClass.ivar];
    [self assert:nil equals:grandChildClass.ivar];

    parentClass.ivar = 1;
    childClass.ivar = 2;
    grandChildClass.ivar = 3;

    [self assert:1 equals:parentClass.ivar];
    [self assert:2 equals:childClass.ivar];
    [self assert:3 equals:grandChildClass.ivar];
}

- (void)testIvarIndependence
{
    parentClass.ivar = 1;
    [self assert:1 equals:parentClass.ivar];
    [self assert:nil equals:childClass.ivar];
    [self assert:nil equals:grandChildClass.ivar];

    childClass.ivar = 2;
    [self assert:1 equals:parentClass.ivar];
    [self assert:2 equals:childClass.ivar];
    [self assert:nil equals:grandChildClass.ivar];

    grandChildClass.ivar = 3;
    [self assert:1 equals:parentClass.ivar];
    [self assert:2 equals:childClass.ivar];
    [self assert:3 equals:grandChildClass.ivar];
}

- (void)testMethodInheritance
{
    [self assertThrows:function()
    {
        [parentClass setIvar:5];
    }];
    [childClass setIvar:5];
    [grandChildClass setIvar:10];
    [self assert:nil equals:parentClass.ivar];
    [self assert:5 equals:childClass.ivar];
    [self assert:10 equals:grandChildClass.ivar];
}

- (void)testSuper
{
    [self assert:@"ParentClass" equals:[parentClass classNameString]];
    [self assert:@"ParentClass" equals:[childClass parentClassNameString]];
    [self assert:@"ParentClass" equals:[grandChildClass grandParentClassNameString]];
}

@end


