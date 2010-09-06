@implementation SubclassTollFreeTest : OJTestCase

- (void)testThatSubclassTollFreeDoesAllowForSubclassing
{
	[OJAssert assert:@"a" equals:[[[MyDict alloc] init] newMessage]];
	[OJAssert assert:@"a" equals:[[[MyString alloc] init] newMessage]];
	[OJAssert assert:@"a" equals:[[[MyNum alloc] init] newMessage]];
	[OJAssert assert:@"a" equals:[[[MyException alloc] init] newMessage]];
	[OJAssert assert:@"a" equals:[[[MyArray alloc] init] newMessage]];
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
