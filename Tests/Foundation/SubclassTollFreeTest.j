@implementation SubclassTollFreeTest : OJTestCase

- (void)testThatSubclassTollFreeDoesAllowForSubclassingDictionary
{
    var target = [[MyDict2 alloc] init];
    [OJAssert assert:@"a" equals:[target newMessage]];
    [OJAssert assert:0 equals:[target count]];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingString
{
    var target = [[MyString2 alloc] initWithString:@"adsf"];
    [OJAssert assert:@"a" equals:[target newMessage]];
    [OJAssert assert:4 equals:[target length]];

    var target2 = "agdsa";
    [OJAssert assertThrows:function(){ [target2 newMessage]; }];
    [OJAssert assert:5 equals:[target2 length]];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingNumber
{
    var target = [[MyNum2 alloc] init];
    [OJAssert assert:@"a" equals:[target newMessage]];
    [OJAssert assertFalse:[target isEqualToNumber:5]];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingException
{
    var target = [[MyException2 alloc] init];
    [OJAssert assert:@"a" equals:[target newMessage]];
    // there are no internal properties to test here.. so no need to jimmyrig it.
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingArray
{
    var target = [[MyArray2 alloc] initWithObjects:@"a"];
    [OJAssert assert:@"a" equals:[target newMessage]];
    [OJAssert assert:1 equals:[target count]];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingDate
{
    var target = [[MyDate2 alloc] init];
    [OJAssert assert:@"a" equals:[target newMessage]];
    [OJAssert assertTrue:[target timeIntervalSince1970] > 0];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingData
{
    var target = [[MyData2 alloc] initWithRawString:@"b"];
    [OJAssert assert:@"a" equals:[target newMessage]];
    [OJAssert assert:@"b" equals:[target rawString]];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingURL
{
    var target = [[MyURL2 alloc] initWithString:@"http://www.google.com"];
    [OJAssert assert:@"a" equals:[target newMessage]];
    [OJAssert assert:@"http://www.google.com" equals:[target absoluteString]];
}


@end

@import <Foundation/CPDictionary.j>

@implementation MyDict2 : CPDictionary

- (id)newMessage
{
    return "a";
}

@end

@implementation MyNum2 : CPNumber

- (id)newMessage
{
    return "a";
}

@end

@implementation MyString2 : CPString

- (id)newMessage
{
    return "a";
}

@end

@implementation MyException2 : CPException

- (id)newMessage
{
    return "a";
}

@end

@implementation MyArray2 : CPArray
{
    CPArray _storage;
}

- (id)initWithObjects:(id)anObject, ...
{
    self = [super init];

    if (self)
        _storage = [[CPArray alloc] initWithObjects:Array.prototype.slice.call(arguments, 2)];

    return self
}

- (id)objectAtIndex:(CPUInteger)anIndex
{
    return [_storage objectAtIndex:anIndex];
}

- (CPUInteger)count
{
    return [_storage count];
}

- (id)newMessage
{
    return "a";
}

@end

@implementation MyDate2 : CPDate

- (id)newMessage
{
    return "a";
}

@end

@implementation MyData2 : CPData

- (id)newMessage
{
    return "a";
}

@end

@implementation MyURL2 : CPURL

- (id)newMessage
{
    return "a";
}

@end
