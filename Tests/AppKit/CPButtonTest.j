
@import <AppKit/CPButton.j>
@import <AppKit/CPStringDrawing.j>

@implementation CPButtonTest : OJTestCase
{
}

- (void)testCanCreate
{
    var button = [CPButton buttonWithTitle:"hello world"];
    [self assertTrue:!!button];
}

@end
