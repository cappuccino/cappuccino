@import <AppKit/CPPasteboard.j>

@import <OJUnit/OJTestCase.j>

@implementation CPPasteboardTest : OJTestCase
{
}

- (void)testSetString_forType_
{
    var pboard = [CPPasteboard generalPasteboard];
    [pboard declareTypes:@[CPStringPboardType] owner:nil];
    [pboard setString:@"hello" forType:CPStringPboardType];
    [self assert:@"hello" equals:[pboard stringForType:CPStringPboardType]];
}

- (void)testSetStringTypeCheck
{
    var pboard = [CPPasteboard generalPasteboard];
    [pboard declareTypes:@[CPStringPboardType] owner:nil];

    // These are okay.
    [pboard setString:"a" forType:CPStringPboardType];
    [pboard setString:[CPString stringWithString:@"a"] forType:CPStringPboardType];

    // This one should crash.
    [self assertThrows:function()
    {
        [pboard setString:[1, 2, 3] forType:CPStringPboardType];
    }];
}

@end
