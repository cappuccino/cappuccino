@implementation SubclassTollFreeTest : OJTestCase

- (void)testThatSubclassTollFreeDoesAllowForSubclassingDictionary
{
	var target = [[MyDict alloc] init];
	[OJAssert assert:@"a" equals:[target newMessage]];
	[OJAssert assert:0 equals:[target count]];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingString
{
	var target = [[MyString alloc] initWithString:@"adsf"];
	[OJAssert assert:@"a" equals:[target newMessage]];
	[OJAssert assert:4 equals:[target length]];
	
	var target2 = "agdsa";
	[OJAssert assertThrows:function(){ [target2 newMessage]; }];
	[OJAssert assert:5 equals:[target2 length]];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingNumber
{
	var target = [[MyNum alloc] init];
	[OJAssert assert:@"a" equals:[target newMessage]];
	[OJAssert assertFalse:[target isEqualToNumber:5]];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingException
{
	var target = [[MyException alloc] init];
	[OJAssert assert:@"a" equals:[target newMessage]];
	// there are no internal properties to test here.. so no need to jimmyrig it.
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingArray
{
	var target = [[MyArray alloc] initWithObjects:@"a"];
	[OJAssert assert:@"a" equals:[target newMessage]];
	[OJAssert assert:1 equals:[target count]];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingDate
{
	var target = [[MyDate alloc] init];
	[OJAssert assert:@"a" equals:[target newMessage]];
	[OJAssert assertTrue:[target timeIntervalSince1970] > 0];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingData
{
	var target = [[MyData alloc] initWithRawString:@"b"];
	[OJAssert assert:@"a" equals:[target newMessage]];
	[OJAssert assert:@"b" equals:[target rawString]];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingURL
{
	var target = [[MyURL alloc] initWithString:@"http://www.google.com"];
	[OJAssert assert:@"a" equals:[target newMessage]];
	[OJAssert assert:@"http://www.google.com" equals:[target absoluteString]];
}


@end

@import <Foundation/CPDictionary.j>

@implementation MyDict : CPDictionary

- (id)newMessage
{
	return "a";
}

@end

@implementation MyNum : CPNumber

- (id)newMessage
{
	return "a";
}

@end

@implementation MyString : CPString

- (id)newMessage
{
	return "a";
}

@end

@implementation MyException : CPException

- (id)newMessage
{
	return "a";
}

@end

@implementation MyArray : CPArray

- (id)newMessage
{
	return "a";
}

@end

@implementation MyDate : CPDate

- (id)newMessage
{
	return "a";
}

@end

@implementation MyData : CPData

- (id)newMessage
{
	return "a";
}

@end

@implementation MyURL : CPURL

- (id)newMessage
{
	return "a";
}

@end
