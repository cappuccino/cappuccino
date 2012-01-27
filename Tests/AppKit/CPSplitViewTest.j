
@import <AppKit/CPApplication.j>
@import <AppKit/CPSplitView.j>

[CPApplication sharedApplication]

@implementation CPSplitViewTest : OJTestCase
{
}

- (void)testSplitViewResize
{
    var splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)],
        viewA = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)],
        viewB = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];

    [splitView addSubview:viewA];
    [splitView addSubview:viewB];
    [splitView setVertical:NO];

    var dividerThickness = [splitView dividerThickness];

    [splitView setPosition:50 ofDividerAtIndex:0];

    [self assert:50 equals:[viewA frameSize].height];
    [self assert:(50 - dividerThickness) equals:[viewB frameSize].height];

    [splitView setPosition:40 ofDividerAtIndex:0];

    [self assert:40 equals:[viewA frameSize].height];
    [self assert:(60 - dividerThickness) equals:[viewB frameSize].height];

    [splitView setFrame:CGRectMake(0, 0, 200, 200)];
    // The extra size should be distributed proportionally to the original sizes of the subviews.
    [self assert:80 equals:[viewA frameSize].height];
    [self assert:(120 - dividerThickness) equals:[viewB frameSize].height];
}

@end
