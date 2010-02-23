
@import <AppKit/CPButton.j>
@import <AppKit/CPApplication.j>

[CPApplication sharedApplication]

@implementation CPButtonTest : OJTestCase
{
    CPButton button;
    BOOL wasClicked;
}

- (void)setUp
{
    button = [CPButton buttonWithTitle:"hello world"];
    wasClicked = NO;
}

- (void)testCanCreate
{
    [self assertTrue:!!button];
}

- (void)testPerformClick
{
    [button setTarget:self];
    [button setAction:@selector(clickMe:)];
    [button performClick:nil];
    [self assertTrue:wasClicked];
}

- (void)clickMe:(id)sender
{
    wasClicked = YES;
}

@end
