@import <Foundation/CPDictionary.j>

@implementation MyDict : CPDictionary
{
    CPString _firstName;
}

- (id)init
{
    self = [super init];

    if (self)
        _firstName = "Bob";

    return self;
}

- (CPString)secondaryName
{
    return "Saget";
}

- (CPString)name
{
    return _firstName;
}

@end


@implementation CPSubclassableDictionaryTest : OJTestCase

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

    [OJAssert assert:NO same:[target respondsToSelector:@selector(name)]];
}

- (void)testThatTollFreeDoesNotHaveNewSelector
{
    var target = {};

    [OJAssert assertThrows:function() { [target secondaryName]; }];
}

@end
