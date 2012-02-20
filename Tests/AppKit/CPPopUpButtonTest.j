
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPApplication.j>

@implementation CPPopUpButtonTest : OJTestCase
{
    CPPopUpButton button;
}

- (void)setUp
{
    button = [CPPopUpButton new];
}

- (void)testItemTitles
{
    [self assert:[] equals:[button itemTitles]];
    [button addItem:[[CPMenuItem alloc] initWithTitle:"Option A" action:nil keyEquivalent:nil]];
    [button addItem:[[CPMenuItem alloc] initWithTitle:"Option B" action:nil keyEquivalent:nil]];
    [self assert:["Option A", "Option B"] equals:[button itemTitles]];
}

@end
