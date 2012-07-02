@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPKeyedUnarchiver.j>

@implementation CPKeyedArchiverTest : OJTestCase
{

}

- (void)testJavaScriptObject
{
    var original = [Archivable new];

    [original setAJsObject:{ 'top': 5 }];

    var decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:original]];

    [self assert:5 equals:[decoded aJsObject].top message:"JS object encoded and decoded right"];
}

@end

@implementation Archivable : CPObject
{
    JSObject    aJsObject @accessors;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        // Note we decode this twice to expose a bug where the cached decoded
        // values did not properly unwrap JS objects.
        aJsObject = [aCoder decodeObjectForKey:@"aJsObject"];
        aJsObject = [aCoder decodeObjectForKey:@"aJsObject"];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:aJsObject forKey:@"aJsObject"];
}

@end
