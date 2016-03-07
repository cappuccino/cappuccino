@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@implementation CPTabView (TEST)

- (CPSegmentedControl)tabs
{
    return _tabs;
}

- (CPBox)box
{
    return _box;
}

@end


@implementation CPTabViewTest : OJTestCase
{
    CPTabView       _tabView;
    CPTabViewItem   _tabItem1;
    CPTabViewItem   _tabItem2;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    _tabView = [[CPTabView alloc] initWithFrame:CGRectMake(0, 0, 800, 600)];

    _tabItem1 = [[CPTabViewItem alloc] initWithIdentifier:@"id1"];
    [_tabItem1 setLabel:@"Item A"];
    [_tabItem1 setView:[[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)]]

    _tabItem2 = [[CPTabViewItem alloc] initWithIdentifier:@"id2"];
    [_tabItem2 setLabel:@"Item B"];
    [_tabItem2 setView:[[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)]]

    [_tabView addTabViewItem:_tabItem1];
    [_tabView addTabViewItem:_tabItem2];

    [[CPRunLoop currentRunLoop] performSelectors];
}

- (void)testCreate
{
    [self assertNotNull:_tabView];

}

- (void)testMiddle
{
    var tabs = [_tabView tabs];
    [self assert:([_tabView frameSize].width / 2)  equals:CGRectGetMidX([tabs frame])];
}

- (void)testMiddleAfterMoveFrame
{
    var tabs = [_tabView tabs];
    [_tabView setFrame:CGRectMake(10, 100, 1000, 200)];
    // Perform this manually for the sake of the unit test.
    [_tabView layoutIfNeeded];
    [self assert:([_tabView frameSize].width / 2)  equals:CGRectGetMidX([tabs frame])];
}

- (void)testMiddleAfterMoveBound
{
    var tabs = [_tabView tabs];
    [_tabView setBounds:CGRectMake(100, 100, 20, 300)];
    // Perform this manually for the sake of the unit test.
    [_tabView layoutIfNeeded];
    [self assert:([tabs boundsSize].width / 2)  equals:CGRectGetMidX([tabs bounds])];
}

- (void)testBoxHeight
{
    var box = [_tabView box],
        tabs = [_tabView tabs];

    [_tabView setFrame:CGRectMake(0, 0, 800, 800)];
    // Perform this manually for the sake of the unit test.
    [_tabView layoutIfNeeded];
    [self assert:[box frameSize].height  equals:800 - [tabs frameSize].height / 2];
}

- (void)testTabViewGetsSetOnViewItem
{
    [self assert:[_tabItem1 tabView] equals:_tabView];
}

- (void)testTabViewGetsRemoveOnViewItem
{
    [_tabView removeTabViewItem:_tabItem1];
    [self assertNull:[_tabItem1 tabView]];
}

- (void)testInsertTabViewItem
{
    [_tabView selectTabViewItem:_tabItem2];

    [self assert:[_tabView numberOfTabViewItems] equals:2];
    [self assert:[_tabView selectedTabViewItem] equals:_tabItem2];

    var tabItem3 = [[CPTabViewItem alloc] initWithIdentifier:@"insert"];
    [tabItem3 setLabel:@"insert"];
    [_tabView insertTabViewItem:tabItem3 atIndex:0];

    [self assert:[_tabView numberOfTabViewItems] equals:3];
    [self assert:[_tabView selectedTabViewItem] equals:_tabItem2];
    [self assert:[_tabView indexOfTabViewItem:tabItem3] equals:0];
}

- (void)testRemoveSelectedTabViewItem
{
    [_tabView selectTabViewItem:_tabItem2];

    [self assert:[_tabView numberOfTabViewItems] equals:2];
    [self assert:[_tabView selectedTabViewItem] equals:_tabItem2];

    [_tabView removeTabViewItem:_tabItem2];

    [self assert:[_tabView numberOfTabViewItems] equals:1];
    [self assert:[_tabView selectedTabViewItem] equals:_tabItem1];
}

- (void)testRemoveSelectedFirstTabViewItem
{
    [_tabView selectTabViewItem:_tabItem1];

    [self assert:[_tabView numberOfTabViewItems] equals:2];
    [self assert:[_tabView selectedTabViewItem] equals:_tabItem1];

    [_tabView removeTabViewItem:_tabItem1];

    [self assert:[_tabView numberOfTabViewItems] equals:1];
    [self assert:[_tabView selectedTabViewItem] equals:_tabItem2];
}

@end
