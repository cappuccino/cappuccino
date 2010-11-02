@import <Foundation/CPDictionary.j>

@implementation MyDict : CPDictionary
{
	int a;
}

+ (id)alloc
{
	return class_createInstance(self);
}

- (id)init
{
	self = [super init];
	if(self)
	{
		_a = "Bob";
	}
	return self;
}

- (CPString)secondaryName
{
	return "Saget";
}

- (CPString)name
{
	return _a;
}

@end


@implementation TestSubclassableDictionary : OJTestCase

- (void)testThatMyDictContainsReplacedNameSelector
{
	var target = [[MyDict alloc] init];
	[OJAssert assert:@"Bob" equals:[target name]];
}

- (void)testThatMyDictDoesHaveNewSelector
{
	var target = [[MyDict alloc] init];
	[OJAssert assert:@"Saget" equals:[target secondaryName]];
}

- (void)testThatDictionaryDoesNotHaveReplacedName
{
	var target = [[CPDictionary alloc] init];
	[OJAssert assert:@"Bob" notEqual:[target name]];
}

- (void)testThatTollFreeDoesNotHaveNewSelector
{
	var target = {};
	[OJAssert assertThrows:function() { [target secondaryName]; }];
}

@end