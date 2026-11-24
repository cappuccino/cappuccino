@import <AppKit/CPApplication.j>
@import <AppKit/CPSplitView.j>

@implementation CPSplitViewTest : OJTestCase
{
    CPSplitView splitView;
    CPView viewA;
    CPView viewB;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    viewA = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
    viewB = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];

    [splitView setArrangesAllSubviews:YES];
    [splitView setDividerStyle:CPSplitViewDividerStyleThin];
    [splitView setVertical:NO];
    [splitView addArrangedSubview:viewA];
    [splitView addArrangedSubview:viewB];
    [splitView adjustSubviews];

    [splitView setPosition:50 ofDividerAtIndex:0];
}

- (void)testSplitViewResize
{
    [self assert:50 equals:[viewA frameSize].height];
    [self assert:49 equals:[viewB frameSize].height];

    [splitView setPosition:40 ofDividerAtIndex:0];

    [self assert:40 equals:[viewA frameSize].height];
    [self assert:59 equals:[viewB frameSize].height];

    [splitView setFrame:CGRectMake(0, 0, 200, 200)];
    // The extra size should be distributed proportionally to the original sizes of the subviews.
    [self assert:80 equals:[viewA frameSize].height];
    [self assert:119 equals:[viewB frameSize].height];

    // It should work for shrinking as well.
    [splitView setFrame:CGRectMake(0, 0, 200, 100)];
    [self assert:40 equals:[viewA frameSize].height];
    [self assert:59 equals:[viewB frameSize].height];

    // And for multiple areas.
    var viewC = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
    [splitView addArrangedSubview:viewC];
    [splitView adjustSubviews];
    [self assert:26 equals:[viewA frameSize].height message:"adding viewC shrinks viewA"];
    [self assert:39 equals:[viewB frameSize].height message:"adding viewC shrinks viewB"];
    [self assert:33 equals:[viewC frameSize].height message:"new viewC is fit into remaining space"];

    // Grow with 3 areas.
    [splitView setFrame:CGRectMake(0, 0, 200, 200)];
    [self assert:53 equals:[viewA frameSize].height];
    [self assert:79 equals:[viewB frameSize].height];
    [self assert:66 equals:[viewC frameSize].height];

    // Shrink with 3 areas.
    [splitView setFrame:CGRectMake(0, 0, 200, 100)];
    [self assert:26 equals:[viewA frameSize].height];
    [self assert:39 equals:[viewB frameSize].height];
    [self assert:33 equals:[viewC frameSize].height];
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

    // Should work just as well with three views.
    var viewC = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
    [splitView addArrangedSubview:viewC];
    [splitView adjustSubviews];
    [splitView setPosition:50 ofDividerAtIndex:0];
    [splitView setPosition:100 ofDividerAtIndex:1];

    [self assert:50 equals:[viewA frameSize].height];
    [self assert:49 equals:[viewB frameSize].height];
    [self assert:99 equals:[viewC frameSize].height];

    // Shrink
    [splitView setFrame:CGRectMake(0, 0, 200, 100)];
    [self assert:50 equals:[viewA frameSize].height];
    [self assert:16 equals:[viewB frameSize].height];
    [self assert:32 equals:[viewC frameSize].height];

    // Crush fixed
    [splitView setFrame:CGRectMake(0, 0, 200, 40)];
    [self assert:38 equals:[viewA frameSize].height message:"fixed size area should be forced to fit"];
    [self assert:0 equals:[viewB frameSize].height];
    [self assert:0 equals:[viewC frameSize].height];

    // Regrow
    [splitView setFrame:CGRectMake(0, 0, 200, 100)];
    [self assert:38 equals:[viewA frameSize].height];
    [self assert:20 equals:[viewB frameSize].height]; // was 30
    [self assert:40 equals:[viewC frameSize].height]; // was 30
}

- (void)testAutosave
{
    // Verify that the split view does not attempt to auto save without an auto save name.

    // This storage class will cause a crash if a save is attempted.
    [[CPUserDefaults standardUserDefaults] setPersistentStoreClass:CPUserDefaultsFailingStore forDomain:CPApplicationDomain reloadData:NO];
    [splitView setPosition:50 ofDividerAtIndex:0];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    // Now test that it does work normally.
    [[CPUserDefaults standardUserDefaults] setPersistentStoreClass:CPUserDefaultsTestStore forDomain:CPApplicationDomain reloadData:NO];
    [splitView setAutosaveName:@"Charles"];
    [splitView setPosition:25 ofDividerAtIndex:0];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    // Recreate the split view.
    [self setUp];
    [splitView setAutosaveName:@"Charles"];

    /*
        Setting the name restores the layout; the restore a cib load makes gives the same
        result.
    */
    [splitView _restoreFromAutosave];

    [self assert:25 equals:[viewA frameSize].height message:@"divider position restored"];
}

/*
    A delegate that lays out the subviews sets only their frames. The split view places the
    divider after the first subview.
*/
- (void)testTheDividerFollowsTheSubviewsThatTheDelegateLaysOut
{
    var thickness = [splitView dividerThickness];

    [splitView setDelegate:[CPSplitViewLayoutDelegate new]];
    [splitView setFrame:CGRectMake(0, 0, 200, 200)];

    [self assertTrue:CGRectEqualToRect(CGRectMake(0, 0, 200, 70), [viewA frame]) message:@"the delegate places the first subview, at " + CPStringFromRect([viewA frame])];
    [self assertTrue:CGRectEqualToRect(CGRectMake(0, 70, 200, thickness), [splitView rectOfDividerAtIndex:0]) message:@"the divider follows the first subview, at " + CPStringFromRect([splitView rectOfDividerAtIndex:0])];
}

@end

/*
    Lays out the subviews itself: the first subview is 70 points high, and the second one fills
    the rest below the divider.
*/
@implementation CPSplitViewLayoutDelegate : CPObject
{
}

- (void)splitView:(CPSplitView)aSplitView resizeSubviewsWithOldSize:(CGSize)oldSize
{
    var size = [aSplitView frameSize],
        thickness = [aSplitView dividerThickness],
        subviews = [aSplitView arrangedSubviews];

    [subviews[0] setFrame:CGRectMake(0, 0, size.width, 70)];
    [subviews[1] setFrame:CGRectMake(0, 70 + thickness, size.width, size.height - 70 - thickness)];
}

@end

@implementation CPSplitViewDontResizeTopView : CPObject
{
}

- (BOOL)splitView:(CPSplitView)splitView shouldAdjustSizeOfSubview:(CPView)subview
{
    var subviews = [splitView arrangedSubviews];
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

/*!
    This is a temporary store.
*/
@implementation CPUserDefaultsTestStore : CPUserDefaultsStore
{
    CPData _data;
}

- (CPData)data
{
    return _data;
}

- (void)setData:(CPData)aData
{
    _data = aData;
}

@end

