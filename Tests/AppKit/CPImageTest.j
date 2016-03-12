@import <AppKit/CPImage.j>

@implementation CPImageTest : OJTestCase
{
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];
}

- (void)testInitWithContentsOfFile_nil
{
    var image = [[CPImage alloc] initWithContentsOfFile:nil];

    [self assert:nil equals:image message:@"- CPImage initWithContentsOfFile:nil should return nil"];
}

@end
