@import <AppKit/CPImage.j>

@implementation CPImageTest : OJTestCase
{
}

- (void)testInitWithContentsOfFile_nil
{
    var image = [[CPImage alloc] initWithContentsOfFile:nil];

    [self assert:nil equals:image message:@"- CPImage initWithContentsOfFile:nil should return nil"];
}

@end
