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
	[OJAssert assert:@"a" equals:[[[MyNum alloc] init] newMessage]];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingException
{
	[OJAssert assert:@"a" equals:[[[MyException alloc] init] newMessage]];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingArray
{
	[OJAssert assert:@"a" equals:[[[MyArray alloc] init] newMessage]];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingDate
{
	[OJAssert assert:@"a" equals:[[[MyDate alloc] init] newMessage]];
}

- (void)testThatSubclassTollFreeDoesAllowForSubclassingData
{
	[OJAssert assert:@"a" equals:[[[MyData alloc] init] newMessage]];
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
