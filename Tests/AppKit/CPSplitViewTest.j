
@import <AppKit/CPApplication.j>
@import <AppKit/CPSplitView.j>

[CPApplication sharedApplication];

@implementation CPSplitViewTest : OJTestCase
{
    CPSplitView splitView;
    CPView viewA;
    CPView viewB;
}

- (void)setUp
{
    splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    viewA = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
    viewB = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];

    [splitView addSubview:viewA];
    [splitView addSubview:viewB];
    [splitView setVertical:NO];

    [splitView setPosition:50 ofDividerAtIndex:0];
}

- (void)testSplitViewResize
{
    var dividerThickness = [splitView dividerThickness];

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

- (void)testSplitView_shouldAdjustSizeOfSubview_
{
    var dividerThickness = [splitView dividerThickness],
        delegate = [CPSplitViewDontResizeTopView new];

    [splitView setDelegate:delegate];
    [splitView setFrame:CGRectMake(0, 0, 200, 200)];

    // All the extra height should have gone to the bottom view.
    [self assert:50 equals:[viewA frameSize].height];
    [self assert:(150 - dividerThickness) equals:[viewB frameSize].height];

    var viewC = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
    [splitView addSubview:viewC];
    [splitView setPosition:66 ofDividerAtIndex:0];
    [splitView setPosition:(132 + dividerThickness) ofDividerAtIndex:1];

    [self assert:66 equals:[viewA frameSize].height];
    [self assert:66 equals:[viewB frameSize].height];
    [self assert:66 equals:[viewC frameSize].height];
}

- (void)testAutosave
{
    // Verify that the split view does not attempt to auto save without an auto save name.

    [[CPUserDefaults standardUserDefaults] setPersistentStoreClass:CPUserDefaultsFailingStore forDomain:CPApplicationDomain reloadData:NO];

    [splitView setPosition:50 ofDividerAtIndex:0];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

@end

@implementation CPSplitViewDontResizeTopView : CPObject
{
}

- (BOOL)splitView:(CPSplitView)splitView shouldAdjustSizeOfSubview:(CPView)subview
{
    var subviews = [splitView subviews];
    return (subview !== [subviews firstObject]);
}

@end
/*!
    This store always fails.
*/
@implementation CPUserDefaultsFailingStore : CPUserDefaultsStore
{
}

- (CPData)data
{
    return nil;
}

- (void)setData:(CPData)aData
{
    [CPException raise:@"CPUnsupportedMethodException" reason:@"Data should not be stored in CPUserDefaultsFailingStore."];
}

@end
