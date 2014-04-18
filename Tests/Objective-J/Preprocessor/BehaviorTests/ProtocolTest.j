@import <Foundation/Foundation.j>

@protocol MyProtocol

- (int)myFunction:(int)aValue;

@end

@protocol MyProtocol2

- (int)myFunction2:(int)aValue;

@end

@protocol MyProtocol3 <MyProtocol, MyProtocol2>

@required
@optional
@required
- (int)myFunction3:(int)aValue;
@optional
@required

@end

@protocol MyProtocol4 <MyProtocol, MyProtocol2>

@end

@implementation MyClass : CPObject <MyProtocol>

- (int)myOtherFunction:(int)aValue
{
    return aValue * 2;
}

- (int)myFunction:(int)aValue
{
    return aValue * 2;
}

@end

@implementation MyClass2 : CPObject <MyProtocol3>

- (int)myOtherFunction:(int)aValue
{
    return aValue * 2;
}

- (int)myFunction:(int)aValue
{
    return aValue * 2;
}

- (int)myFunction2:(int)aValue
{
    return aValue * 2;
}

- (int)myFunction3:(int)aValue
{
    return aValue * 2;
}

@end


@implementation ProtocolTest : OJTestCase

- (void)testConformsToProtocol
{
    [self assert:true equals:[[[MyClass alloc] init] conformsToProtocol:@protocol(MyProtocol)]];
    [self assert:false equals:[[[MyClass alloc] init] conformsToProtocol:@protocol(MyProtocol2)]];
    [self assert:false equals:[[[MyClass alloc] init] conformsToProtocol:@protocol(xxxxxx)]];
    [self assert:true equals:[[[MyClass2 alloc] init] conformsToProtocol:@protocol(MyProtocol)]];
    [self assert:true equals:[[[MyClass2 alloc] init] conformsToProtocol:@protocol(MyProtocol2)]];
    [self assert:true equals:[[[MyClass2 alloc] init] conformsToProtocol:@protocol(MyProtocol3)]];
}

@end
