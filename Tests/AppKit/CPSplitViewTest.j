
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
    [splitView addSubview:viewC];
    // Force an immediate adjustment of subview sizes.
    [splitView viewWillDraw];
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
    [splitView addSubview:viewC];
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
    [self assert:30 equals:[viewB frameSize].height];
    [self assert:30 equals:[viewC frameSize].height];
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

    // FIXME At the moment restore from autosave only happens if the split view is loaded from a
    // coder. It seems like it should happen when initialising in code too, but some research of
    // Cocoa's behaviour will need to be done first. For now, trigger it by hand.
    [splitView _restoreFromAutosave];

    [self assert:25 equals:[viewA frameSize].height message:@"divider position restored"];
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

