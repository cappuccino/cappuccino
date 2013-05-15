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

@end
