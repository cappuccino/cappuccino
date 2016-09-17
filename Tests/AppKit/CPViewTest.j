@import <AppKit/CPView.j>
@import <AppKit/CPApplication.j>

var methodCalled;
var updateTrackingAreasCalls,
    mouseEnteredCalls,
    mouseExitedCalls,
    mouseMovedCalls,
    cursorUpdateCalls,
    involvedViewForMouseEntered,
    involvedViewForMouseExited,
    involvedViewForCursorUpdate;

@implementation CPViewTest : OJTestCase
{
    CPView view;
    CPView view1;
    CPView view2;
    CPView view3;

    CPWindow window;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 1000.0, 1000.0) styleMask:CPWindowNotSizable];

    view = [[CPView alloc] initWithFrame:CGRectMakeZero()];
    view1 = [[CPResponderView alloc] initWithFrame:CGRectMakeZero()];
    view2 = [[CPResponderView alloc] initWithFrame:CGRectMakeZero()];
    view3 = [[CPResponderView alloc] initWithFrame:CGRectMakeZero()];

    [view1 setIdentifier:@"view1"];
    [view2 setIdentifier:@"view2"];
    [view3 setIdentifier:@"view3"];

    methodCalled = [];
    updateTrackingAreasCalls = 0;

    [super setUp];
}

- (void)testCanCreate
{
    [self assertTrue:!!view];
}

/*
    During the layout process for the view, _CPImageAndTextView.j throws
    a ReferenceError with the following:

        "hasDOMImageElement" is not defined

    The referenced variable is #if PLATFORM(DOM) excluded in all other
    instances. While not isolated to the behaviour of a CPView alone, the
    following test ensures that pending actions in the _CPDisplayServer can
    be flushed without touching unimplemented portions of the test platform
    (e.g. the DOM). There are times where we want to confirm that some setting
    requiring relayout (e.g. string truncation based on available space), the
    following test should help ensure those types of tests are safe to carry
    out with ojunit.

    Demonstrates issue #562.
*/
- (void)testCanFlushPendingLayoutWork
{
    [self assert:undefined same:[_CPDisplayServer run]];
}

- (void)testHasThemeState
{
    [self assertTrue:[view hasThemeState:CPThemeStateNormal] message:@"By default, CPView should be in CPThemeStateNormal"];

    view._themeState = CPThemeState(CPThemeStateDisabled, CPThemeStateBordered);
    [self assertTrue:[view hasThemeState:CPThemeStateDisabled] message:@"CPView should be in state CPThemeStateDisabled"];
    [self assertTrue:[view hasThemeState:CPThemeStateBordered] message:@"CPView should be in state CPThemeStateBordered"];
    [self assertTrue:[view hasThemeState:CPThemeState(CPThemeStateBordered, CPThemeStateDisabled)] message:@"CPView should be in the combined state of CPThemeStateDisabled and CPThemeStateBordered"];
    [self assertTrue:[view hasThemeStates:[CPThemeStateBordered, CPThemeStateDisabled]] message:@"hasThemeState works with an array argument"];
    [self assertFalse:[view hasThemeState:CPThemeState(CPThemeStateNormal)] message:@"CPView should not be in CPThemeStateNormal"];
}

- (void)testSetThemeState
{
    [self assert:String(CPThemeStateNormal) equals:String([view themeState]) message:@"CPView should initialy have CPThemeStateNormal"];

    [view setThemeState:CPThemeStateDisabled];
    [self assert:String(CPThemeStateDisabled) equals:String([view themeState]) message:@"The view should be CPThemeStateDisabled"];

    [view setThemeState:CPThemeStateHighlighted];
    [self assert:String(CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted)) equals:String([view themeState]) message:@"Theme state should be CPThemeStateHighlighted and CPThemeStateDisabled"];

    [view unsetThemeState:[view themeState]];
    [view setThemeState:CPThemeState(CPThemeStateNormal, CPThemeStateHighlighted)];
    [self assertFalse:[view hasThemeState:CPThemeStateNormal] message:@"CPThemeStateNormal cannot exist as part of a compound state"];
    [self assert:String([view themeState]) equals:String(CPThemeStateHighlighted) message:@"The view should be CPThemeStateHighlighted"];

    [view setThemeState:CPThemeState(CPThemeStateHighlighted, CPThemeStateDisabled)];
    [self assertTrue:[view hasThemeState:CPThemeStateHighlighted] message:@"The view should be CPThemeStateHighlighted"];
    [self assertTrue:[view hasThemeState:CPThemeStateDisabled] message:@"The view should be CPThemeStateDisabled"];
    [self assert:String(CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted)) equals:String([view themeState]) message:@"The view should be in the combined state of CPThemeStateDisabled and CPThemeStateHighlighted"];

    [view unsetThemeState:[view themeState]];
    [view setThemeStates:[CPThemeStateSelected, CPThemeStateDisabled]];
    [self assert:String(CPThemeState(CPThemeStateDisabled, CPThemeStateSelected)) equals:String([view themeState]) message:@"setThemeState works with array argument"];
}

- (void)testUnsetThemeState
{
    [self assert:String(CPThemeStateNormal) equals:String([view themeState]) message:@"CPView should initialy have CPThemeStateNormal"];
    [view unsetThemeState:CPThemeStateNormal];
    [self assert:String(CPThemeStateNormal) equals:String([view themeState]) message:@"CPView always be in CPThemeStateNormal even if you try to unset it"];

    [view setThemeState:CPThemeStateDisabled];
    [view unsetThemeState:CPThemeStateDisabled];
    [self assert:String(CPThemeStateNormal) equals:String([view themeState]) message:@"CPView should be in CPThemeStateNormal when all other theme states have been unset from it"];

    [view setThemeState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted)];
    [view unsetThemeState:CPThemeStateDisabled];
    [self assert:String(CPThemeStateHighlighted) equals:String([view themeState]) message:"@CPView should have the remaining state when one of its combined states is unset"];

    [view setThemeState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateBordered)];
    [view unsetThemeState:CPThemeState(CPThemeStateBordered, CPThemeStateHighlighted, CPThemeStateDisabled)];
    [self assert:String(CPThemeStateNormal) equals:String([view themeState]) message:@"CPView should be able to unset a combined theme state"];

    [view setThemeState:CPThemeState(CPThemeStateDisabled, CPThemeStateHighlighted, CPThemeStateBordered)];
    [view unsetThemeStates:[CPThemeStateBordered, CPThemeStateHighlighted]];
    [self assert:String(CPThemeStateDisabled) equals:String([view themeState]) message:@"unsetThemeState works with array argument"];

    [view setThemeState:CPThemeStateDisabled];
    [view unsetThemeStates:[CPThemeStateDisabled, CPThemeStateHighlighted]];
    [self assert:String(CPThemeStateNormal) equals:String([view themeState]) message:@"CPView should be able to unset a combined theme state that has more theme states than the view currently has"];

    [view setThemeState:CPThemeState(CPThemeStateDisabled, CPThemeStateBordered)];
    var returnValue = [view unsetThemeStates:[CPThemeStateDisabled, CPThemeStateHighlighted]];
    [self assert:String(CPThemeStateBordered) equals:String([view themeState]) message:@"CPView should be able to unset a combined theme state that has not entirely overlapping themestates"];
    [self assertTrue:returnValue message:@"When unsetThemeState successfully unsets anything, it return YES"];

    [view setThemeState:CPThemeState(CPThemeStateDisabled, CPThemeStateBordered)];
    var returnValue = [view unsetThemeStates:[CPThemeStateSelected, CPThemeStateHighlighted]];
    [self assert:String(CPThemeState(CPThemeStateDisabled, CPThemeStateBordered)) equals:String([view themeState]) message:@"CPView not unset any theme states it does not have"];
    [self assertFalse:returnValue message:@"When unsetThemeState doesn't unset anything, it returns NO"];

    [view setThemeState:CPThemeState(CPThemeStateDisabled, CPThemeStateBordered)];
    var returnValue = [view unsetThemeState:null];
    [self assert:String(CPThemeState(CPThemeStateDisabled, CPThemeStateBordered)) equals:String([view themeState]) message:@"Trying to unset a null themestate does not change the current themestate of the view"];
    [self assertFalse:returnValue message:@"Trying to unset a null themestate returns false"];
}

- (void)testThemeAttributes
{
    var attributes = [CPView themeAttributes];

    if (attributes)
    {
        var keys = [attributes allKeys],
            firstKey = [keys objectAtIndex:0];

        [self assertTrue:[view hasThemeAttribute:[firstKey]] message:[view className] + " should have the theme attribute \"" + firstKey + "\""];
    }

    [self assertFalse:[view hasThemeAttribute:@"foobar"] message:[view className] + " should not have theme attribute \"" + firstKey + "\""];
}

- (void)testIsVisible
{
    [self assertFalse:[view _isVisible] message:"view must belong to a window to be visible"];
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    [self assertFalse:[contentView _isVisible] message:"view must belong to a visible window to be visible"];
    [theWindow orderFront:self];
    // Fake this because we don't have the DOM in unit tests.
    [theWindow._isVisible = YES];
    [self assertTrue:[contentView _isVisible] message:"view is the content view of a visible window, hence visible"];

    [self assertFalse:[view _isVisible] message:"view must belong to a window to be visible"];
    [contentView addSubview:view];
    [self assertTrue:[view _isVisible] message:"view is a subview of a visible content view, hence visible"];

    [view setHidden:YES];
    [self assertFalse:[view _isVisible] message:"view is hidden"];

    [view setHidden:NO];
    [self assertTrue:[view _isVisible] message:"view is not hidden again"];

    [contentView setHidden:YES];
    [self assertFalse:[view _isVisible] message:"a superview is hidden"];

    [contentView setHidden:NO];
    [contentView removeFromSuperview];
    [self assertFalse:[view _isVisible] message:"a superview does not belong to a visible window"];
}

- (void)testNextValidKeyView
{
    var viewA = [CPView new],
        viewB = [CPView new],
        viewC = [CPCollectionView new],
        viewD = [CPView new],
        viewE = [CPView new];

    [viewA setNextKeyView:viewB];
    [viewB setNextKeyView:viewC];

    [self assert:viewC equals:[viewA nextValidKeyView]];

    // Make a loop which is harder to detect.
    [viewA setNextKeyView:viewB];
    [viewB setNextKeyView:viewD];
    [viewD setNextKeyView:viewE];
    [viewE setNextKeyView:viewD];

    [self assert:nil equals:[viewA nextValidKeyView]];
}

- (void)testConvertPoint_fromView_shouldChangeNothingForSameView
{
    var tView0 = [CPView new],
        aWindow = [CPWindow new];

    [aWindow setContentView:tView0];

    [tView0 setFrame:CGRectMake(3, 5, 13, 17)];

    [self assertTrue:CGPointEqualToPoint(CGPointMake(7, 11), [tView0 convertPoint:CGPointMake(7, 11) fromView:tView0])]
}

- (void)testConvertPoint_fromView_shouldAddSubviewCoordinatesWhenMovingUp
{
    var tView0 = [CPView new],
        subView0 = [CPView new],
        aWindow = [CPWindow new];

    [aWindow setContentView:tView0];

    [tView0 addSubview:subView0];
    [tView0 setFrame:CGRectMake(30, 50, 130, 170)];
    [subView0 setFrame:CGRectMake(3, 5, 13, 17)];

    [self assertTrue:CGPointEqualToPoint(CGPointMake(10, 16), [tView0 convertPoint:CGPointMake(7, 11) fromView:subView0])]
}

- (void)testConvertPoint_fromView_shouldWorkBetweenSiblingViews
{
    var tView0 = [CPView new],
        subView0 = [CPView new],
        aWindow = [CPWindow new];

    [[aWindow contentView] addSubview:tView0];
    [[aWindow contentView] addSubview:subView0];

    [tView0 setFrame:CGRectMake(30, 50, 130, 170)];
    [subView0 setFrame:CGRectMake(3, 5, 13, 17)];

    [self assertTrue:CGPointEqualToPoint(CGPointMake(34, 56), [subView0 convertPoint:CGPointMake(7, 11) fromView:tView0])]
}

- (void)testConvertPoint_fromView_shouldSubtractSubviewCoordinatesWhenMovingDown
{
    var tView0 = [CPView new],
        subView0 = [CPView new],
        aWindow = [CPWindow new];

    [aWindow setContentView:tView0];

    [tView0 addSubview:subView0];
    [tView0 setFrame:CGRectMake(30, 50, 130, 170)];
    [subView0 setFrame:CGRectMake(3, 5, 13, 17)];

    [self assertTrue:CGPointEqualToPoint(CGPointMake(4, 6), [subView0 convertPoint:CGPointMake(7, 11) fromView:tView0])]
}

+ (CPArray)createResponderView:(/*@ref */CPView)viewOut siblingView:(/*@ref */CPView)siblingViewOut inWindow:(/*@ref */CPWindow)windowOut
{
    var aView = [CPResponderView new],
        siblingView = [CPResponderView new],
        aWindow = [CPWindow new];

    [[aWindow contentView] addSubview:aView];
    [[aWindow contentView] addSubview:siblingView];

    if (viewOut)
        @deref(viewOut) = aView;
    if (siblingViewOut)
        @deref(siblingViewOut) = siblingView;
    if (windowOut)
        @deref(windowOut) = aWindow;

    return aView;
}

- (void)testWhenFirstResponderShouldHaveThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    [self assertFalse:[aView hasThemeState:CPThemeStateFirstResponder]];
    [self assertFalse:[siblingView hasThemeState:CPThemeStateFirstResponder]];

    [aWindow makeFirstResponder:aView];
    [self assertTrue:[aView hasThemeState:CPThemeStateFirstResponder]];

    [aWindow makeFirstResponder:siblingView];
    [self assertTrue:[siblingView hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenChildOfFirstResponderShouldHaveThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];
    var subview = [CPView new];
    [aView addSubview:subview];

    [aWindow makeFirstResponder:aView];
    [self assertTrue:[aView hasThemeState:CPThemeStateFirstResponder]];
    [self assertTrue:[subview hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenNotFirstResponderShouldLoseThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    [aWindow makeFirstResponder:aView];
    [self assertFalse:[siblingView hasThemeState:CPThemeStateFirstResponder]];

    [aWindow makeFirstResponder:siblingView];
    [self assertFalse:[aView hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenNotChildOfFirstResponderShouldLoseThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];
    var subview = [CPView new];
    [aView addSubview:subview];

    [aWindow makeFirstResponder:aView];
    [self assertTrue:[aView hasThemeState:CPThemeStateFirstResponder]];
    [self assertTrue:[subview hasThemeState:CPThemeStateFirstResponder]];

    [aWindow makeFirstResponder:siblingView];
    [self assertFalse:[aView hasThemeState:CPThemeStateFirstResponder]];
    [self assertFalse:[subview hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenFirstResponderButNotKeyWindowShouldStillHaveThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    var aView2, siblingView2, aWindow2;
    [CPViewTest createResponderView:@ref(aView2) siblingView:@ref(siblingView2) inWindow:@ref(aWindow2)];

    [aWindow makeKeyWindow];
    [aWindow makeFirstResponder:aView];
    [self assertTrue:[aView hasThemeState:CPThemeStateFirstResponder]];

    [aWindow2 makeFirstResponder:siblingView];
    [aWindow2 makeKeyWindow];

    [self assertTrue:[aView hasThemeState:CPThemeStateFirstResponder]];
    [self assertTrue:[siblingView hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenChildOfFirstResponderButNotKeyWindowShouldStillHaveThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    var subview = [CPView new];
    [aView addSubview:subview];

    var aView2, siblingView2, aWindow2;
    [CPViewTest createResponderView:@ref(aView2) siblingView:@ref(siblingView2) inWindow:@ref(aWindow2)];

    [aWindow makeKeyWindow];
    [aWindow makeFirstResponder:aView];
    [aWindow2 makeFirstResponder:siblingView];
    [aWindow2 makeKeyWindow];
    [self assertTrue:[subview hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenNotFirstResponderButNotKeyWindowShouldStillLoseThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    var aView2, siblingView2, aWindow2;
    [CPViewTest createResponderView:@ref(aView2) siblingView:@ref(siblingView2) inWindow:@ref(aWindow2)];

    [aWindow makeKeyWindow];
    [aWindow makeFirstResponder:aView];
    [aWindow2 makeFirstResponder:siblingView];
    [aWindow2 makeKeyWindow];
    [aWindow makeFirstResponder:siblingView];

    [self assertFalse:[aView hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenNotChildOfFirstResponderButNotKeyWindowShouldShouldStillLoseThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    var subview = [CPView new];
    [aView addSubview:subview];

    var aView2, siblingView2, aWindow2;
    [CPViewTest createResponderView:@ref(aView2) siblingView:@ref(siblingView2) inWindow:@ref(aWindow2)];

    [aWindow makeKeyWindow];
    [aWindow makeFirstResponder:aView];
    [aWindow2 makeFirstResponder:siblingView];
    [aWindow2 makeKeyWindow];
    [aWindow makeFirstResponder:siblingView];

    [self assertFalse:[subview hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenAndOnlyWhenWindowIsKeyEveryViewShouldHaveThemeStateKeyWindow
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    var subview = [CPView new];
    [aView addSubview:subview];

    var aView2, siblingView2, aWindow2;
    [CPViewTest createResponderView:@ref(aView2) siblingView:@ref(siblingView2) inWindow:@ref(aWindow2)];

    [aWindow makeKeyWindow];
    [self assertTrue:[aView hasThemeState:CPThemeStateKeyWindow]];
    [self assertTrue:[siblingView hasThemeState:CPThemeStateKeyWindow]];
    [self assertTrue:[subview hasThemeState:CPThemeStateKeyWindow]];
    [self assertFalse:[aView2 hasThemeState:CPThemeStateKeyWindow]];
    [self assertFalse:[siblingView2 hasThemeState:CPThemeStateKeyWindow]];

    [aWindow2 makeKeyWindow];
    [self assertFalse:[aView hasThemeState:CPThemeStateKeyWindow]];
    [self assertFalse:[siblingView hasThemeState:CPThemeStateKeyWindow]];
    [self assertFalse:[subview hasThemeState:CPThemeStateKeyWindow]];
    [self assertTrue:[aView2 hasThemeState:CPThemeStateKeyWindow]];
    [self assertTrue:[siblingView2 hasThemeState:CPThemeStateKeyWindow]];
}

- (void)testWhenFirstResponderBeforeBeingAddedSubviewShouldHaveThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    [self assertFalse:[aView hasThemeState:CPThemeStateFirstResponder]];
    [self assertFalse:[siblingView hasThemeState:CPThemeStateFirstResponder]];

    [aWindow makeFirstResponder:aView];

    var subview = [CPView new];
    [aView addSubview:subview];
    [self assertTrue:[subview hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenRemovedSubviewShouldLoseThemeStateFirstResponder
{
    var aView, siblingView, aWindow;
    [CPViewTest createResponderView:@ref(aView) siblingView:@ref(siblingView) inWindow:@ref(aWindow)];

    [aWindow makeFirstResponder:aView];
    var subview = [CPView new];
    [aView addSubview:subview];
    [subview removeFromSuperview];
    [self assertFalse:[subview hasThemeState:CPThemeStateFirstResponder]];
}

- (void)testWhenAddedSubviewMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1"];

    [[window contentView] addSubview:view1];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedSubviewWithoutWindowMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view2", @"viewDidMoveToSuperview_view2"];

    [view1 addSubview:view2];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedSubviewTwiceMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1", @"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1"];

    [[window contentView] addSubview:view1];
    [[window contentView] addSubview:view1];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenRemovedSubviewMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1"];

    [view1 removeFromSuperview];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedSubviewThenRemovedSubviewMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1"];

    [[window contentView] addSubview:view1];

    methodCalled = [];
    [view1 removeFromSuperview];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedSubviewThenRemovedSubviewWithoutWindowMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1"];

    [view1 addSubview:view2];

    methodCalled = [];
    [view1 removeFromSuperview];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedTwoSubviewsMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view2", @"viewDidMoveToSuperview_view2",@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewWillMoveToWindow_view2", "viewDidMoveToWindow_view2",  "viewDidMoveToWindow_view1"];

    [view1 addSubview:view2];
    [[window contentView] addSubview:view1];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedTwoSubviewsThenRemovedMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewWillMoveToWindow_view2", "viewDidMoveToWindow_view2",  "viewDidMoveToWindow_view1"];

    [view1 addSubview:view2];
    [[window contentView] addSubview:view1];

    methodCalled = [];
    [view1 removeFromSuperview];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedTwoSubviewsThenAddedTheViewToAnotherViewWithoutWindowMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", @"viewWillMoveToWindow_view1", @"viewDidMoveToWindow_view1", @"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", @"viewWillMoveToWindow_view1", @"viewDidMoveToWindow_view1"];

    [[window contentView] addSubview:view1];
    [view2 addSubview:view1];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedOneSubviewsWithSetSubviewsMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1"];

    [[window contentView] setSubviews:[view1]];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedTwoSubviewsWithSetSubviewsMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1", @"viewWillMoveToSuperview_view2", @"viewDidMoveToSuperview_view2", "viewWillMoveToWindow_view2", "viewDidMoveToWindow_view2"];

    [[window contentView] setSubviews:[view1, view2]];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedTwoSubviewsThenSetSubviewsWithOneViewMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view2", @"viewDidMoveToSuperview_view2", "viewWillMoveToWindow_view2", "viewDidMoveToWindow_view2"];

    [[window contentView] setSubviews:[view1, view2]];

    methodCalled = [];

    [[window contentView] setSubviews:[view1]];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenAddedTwoSubviewsThenSetSubviewsWithTwoViewsMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view2", @"viewDidMoveToSuperview_view2", "viewWillMoveToWindow_view2", "viewDidMoveToWindow_view2", @"viewWillMoveToSuperview_view3", @"viewDidMoveToSuperview_view3", "viewWillMoveToWindow_view3", "viewDidMoveToWindow_view3"];

    [[window contentView] setSubviews:[view1, view2]];

    methodCalled = [];

    [[window contentView] setSubviews:[view1, view3]];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenReplacedViewWithSameViewMethodCalled
{
    var expectedRestult = [];

    [[window contentView] addSubview:view1];

    methodCalled = [];

    [[window contentView] replaceSubview:view1 with:view1];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenReplacedViewWithOtherViewMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view2", @"viewDidMoveToSuperview_view2", "viewWillMoveToWindow_view2", "viewDidMoveToWindow_view2", @"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1"];

    [[window contentView] addSubview:view1];

    methodCalled = [];

    [[window contentView] replaceSubview:view1 with:view2];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testWhenReplacedViewWithOtherAddedViewMethodCalled
{
    var expectedRestult = [@"viewWillMoveToSuperview_view2", @"viewDidMoveToSuperview_view2", "viewWillMoveToWindow_view2", "viewDidMoveToWindow_view2", @"viewWillMoveToSuperview_view1", @"viewDidMoveToSuperview_view1", "viewWillMoveToWindow_view1", "viewDidMoveToWindow_view1"];

    [[window contentView] addSubview:view1];
    [[window contentView] addSubview:view2];

    methodCalled = [];

    [[window contentView] replaceSubview:view1 with:view2];

    [self assert:expectedRestult equals:methodCalled];
}

- (void)testLayoutSubviews
{
    var layoutView = [[CPLayoutView alloc] initWithFrame:CGRectMakeZero()];

    [layoutView setIdentifier:@"layoutView"];

    [[window contentView] addSubview:layoutView];
    [layoutView setNeedsLayout]

    methodCalled = [];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    var expectedRestult = ["layoutSubivews_layoutView"];
    [self assert:expectedRestult equals:methodCalled];


    [layoutView setNeedsLayout]
    [layoutView setNeedsLayout]

    methodCalled = [];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    expectedRestult = ["layoutSubivews_layoutView"];
    [self assert:expectedRestult equals:methodCalled];


    [layoutView setNeedsLayout:YES]

    methodCalled = [];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    expectedRestult = ["layoutSubivews_layoutView"];
    [self assert:expectedRestult equals:methodCalled];


    [layoutView setNeedsLayout:YES];
    [layoutView setNeedsLayout:NO];

    methodCalled = [];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    expectedRestult = [];
    [self assert:expectedRestult equals:methodCalled];


    [layoutView setNeedsLayout:YES];
    [layoutView setNeedsLayout:NO];
    [layoutView setNeedsLayout:YES];

    methodCalled = [];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    expectedRestult = ["layoutSubivews_layoutView"];
    [self assert:expectedRestult equals:methodCalled];
}

- (void)testToolTipInitialEmpty
{
    [self assert:nil equals:view._toolTip];
    [self assert:nil equals:view._toolTipInstalled];
    [self assert:nil equals:view._toolTipFunctionIn];
    [self assert:nil equals:view._toolTipFunctionOut];
}

- (void)testToolTipWithToolTipAndNoWindow
{
    [view setToolTip:@"tooltip"];

    [self assert:@"tooltip" equals:view._toolTip];
    [self assert:nil equals:view._toolTipInstalled];
    [self assert:nil equals:view._toolTipFunctionIn];
    [self assert:nil equals:view._toolTipFunctionOut];
}

- (void)testToolTipWithToolTipAndWindow
{
    [view setToolTip:@"tooltip"];

    [[window contentView] addSubview:view]

    [self assert:@"tooltip" equals:view._toolTip];
    [self assertTrue:view._toolTipInstalled];
    [self assertTrue:!!view._toolTipFunctionIn];
    [self assertTrue:!!view._toolTipFunctionOut];
}

- (void)testToolTipWithToolTipAndWindowThenNoWindow
{
    [view setToolTip:@"tooltip"];

    [[window contentView] addSubview:view]
    [view removeFromSuperview];

    [self assert:@"tooltip" equals:view._toolTip];
    [self assert:NO equals:view._toolTipInstalled];
    [self assert:nil equals:view._toolTipFunctionIn];
    [self assert:nil equals:view._toolTipFunctionOut];
}

- (void)testToolTipWithNoToolTipAndWindowThenNoWindowThenToolTip
{
    [self assert:nil equals:view._toolTip];
    [self assert:nil equals:view._toolTipInstalled];
    [self assert:nil equals:view._toolTipFunctionIn];
    [self assert:nil equals:view._toolTipFunctionOut];

    [[window contentView] addSubview:view];

    [self assert:nil equals:view._toolTip];
    [self assert:nil equals:view._toolTipInstalled];
    [self assert:nil equals:view._toolTipFunctionIn];
    [self assert:nil equals:view._toolTipFunctionOut];

    [view setToolTip:@"tooltip"];

    [self assert:@"tooltip" equals:view._toolTip];
    [self assertTrue:view._toolTipInstalled];
    [self assertTrue:!!view._toolTipFunctionIn];
    [self assertTrue:!!view._toolTipFunctionOut];

    [view removeFromSuperview];

    [self assert:@"tooltip" equals:view._toolTip];
    [self assert:NO equals:view._toolTipInstalled];
    [self assert:nil equals:view._toolTipFunctionIn];
    [self assert:nil equals:view._toolTipFunctionOut];
}

- (void)testAppearanceDefaultvalue
{
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self assert:nil equals:[view appearance]];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantDark]];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantLight]];
    [self assert:nil equals:[view effectiveAppearance]];
}

- (void)testAppearanceWithVibrantDark
{
    [view setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark]];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark] equals:[view appearance]];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark] equals:[view effectiveAppearance]];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assertTrue:[view hasThemeState:CPThemeStateAppearanceVibrantDark]];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantLight]];
}

- (void)testAppearanceWithVibrantLight
{
    [view setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight]];

    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight] equals:[view appearance]];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight] equals:[view effectiveAppearance]];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assertTrue:[view hasThemeState:CPThemeStateAppearanceVibrantLight]];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantDark]];
}

- (void)testAppearanceReset
{
    [view setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight]];
    [view setAppearance:nil];

    [self assert:nil equals:[view appearance]];
    [self assert:nil equals:[view effectiveAppearance]];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantLight]];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantDark]];
}

- (void)testEffectiveAppearance
{
    var secondView = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [view addSubview:secondView];

    [self assert:nil equals:[secondView appearance]];

    [view setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight]];

    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight] equals:[secondView effectiveAppearance]];
}

- (void)testEffectiveAppearanceWithMovingViews
{
    var viewA = [[CPView alloc] initWithFrame:CGRectMakeZero()],
        viewB = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [viewA setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight]];
    [viewB setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark]];

    [viewA addSubview:view];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight] equals:[view effectiveAppearance]];
    [self assertTrue:[view hasThemeState:CPThemeStateAppearanceVibrantLight]];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantDark]];

    [viewB addSubview:view];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark] equals:[view effectiveAppearance]];
    [self assertFalse:[view hasThemeState:CPThemeStateAppearanceVibrantLight]];
    [self assertTrue:[view hasThemeState:CPThemeStateAppearanceVibrantDark]];
}

- (void)testEffectiveAppearanceWithMovingViewHierarchy
{
    var viewC = [[CPView alloc] initWithFrame:CGRectMakeZero()],
        viewA = [[CPView alloc] initWithFrame:CGRectMakeZero()],
        viewB = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [view setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight]];
    [viewC setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark]];

    [viewA addSubview:viewB];
    [view addSubview:viewA];

    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight] equals:[viewB effectiveAppearance]];

    [viewC addSubview:viewA];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark] equals:[viewB effectiveAppearance]];
}

- (void)testEffectiveAppearanceReset
{
    var viewA = [[CPView alloc] initWithFrame:CGRectMakeZero()],
        viewB = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [viewA setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight]];
    [viewB setAppearance:[CPAppearance appearanceNamed:CPAppearanceNameVibrantDark]];

    [viewA addSubview:view];
    [self assert:[CPAppearance appearanceNamed:CPAppearanceNameVibrantLight] equals:[view effectiveAppearance]];

    [view removeFromSuperview];
    [self assert:nil equals:[view effectiveAppearance]];
}

- (void)testViewDidHideDidUnhide
{
    var expectedResult = [@"viewDidHide_view1", @"viewDidUnhide_view1"];

    [view1 setHidden:YES];
    [view1 setHidden:NO];

    [self assert:expectedResult equals:methodCalled];
}

- (void)testAddViewRemoveView
{
    var expectedResult = [@"viewWillMoveToSuperview_view2",
    @"viewDidMoveToSuperview_view2",
    @"viewWillMoveToSuperview_view2",
    @"viewDidMoveToSuperview_view2",
    @"viewWillMoveToWindow_view2",
    @"viewDidMoveToWindow_view2"];

    [view1 addSubview:view2];
    [view2 removeFromSuperview];

    [self assert:expectedResult equals:methodCalled];
}

- (void)testViewGainedHiddenAncestor
{
    var expectedResult = [@"viewDidHide_view1",
    @"viewWillMoveToSuperview_view3",
    @"viewDidMoveToSuperview_view3",
    @"viewWillMoveToSuperview_view2",
    @"viewDidHide_view2",
    @"viewDidHide_view3",
    @"viewDidMoveToSuperview_view2"];

    [view1 setHidden:YES];
    [view2 addSubview:view3];
    CPLog.warn("will add view2");
    [view1 addSubview:view2];

    [self assertTrue: [view2 isHiddenOrHasHiddenAncestor] message:@"Expected " + [view2 identifier] + "isHiddenOrHasHiddenAncestor = YES"];
    [self assertTrue: [view3 isHiddenOrHasHiddenAncestor] message:@"Expected isHiddenOrHasHiddenAncestor = YES"];

    [self assertFalse:[view2 isHidden]];
    [self assertFalse:[view3 isHidden]];

    [self assert:expectedResult equals:methodCalled];
}

- (void)testRemoveViewsHiddenByAncestor
{
    var expectedResult = @[
    @"viewWillMoveToSuperview_view2",
    @"viewDidUnhide_view2",
    @"viewDidUnhide_view3",
    @"viewDidMoveToSuperview_view2",
    @"viewWillMoveToWindow_view2",
    @"viewWillMoveToWindow_view3",
    @"viewDidMoveToWindow_view3",
    @"viewDidMoveToWindow_view2"
];

    [view1 setHidden:YES];
    [view1 addSubview:view2];
    [view2 addSubview:view3];

    [self assertTrue: [view2 isHiddenOrHasHiddenAncestor] message:@"Expected isHiddenOrHasHiddenAncestor = YES" ];
    [self assertFalse:[view2 isHidden]];

    [self assertTrue: [view3 isHiddenOrHasHiddenAncestor] message:@"Expected isHiddenOrHasHiddenAncestor = YES" ];
    [self assertFalse:[view3 isHidden]];

    methodCalled = [];

    [view2 removeFromSuperview];

    [self assertFalse: [view2 isHiddenOrHasHiddenAncestor] message:@"Expected isHiddenOrHasHiddenAncestor = NO" ];
    [self assertFalse: [view3 isHiddenOrHasHiddenAncestor] message:@"Expected isHiddenOrHasHiddenAncestor = NO" ];

    [self assert:expectedResult equals:methodCalled];
}

- (void)testRemoveHiddenView
{
    var expectedResult = [@"viewWillMoveToSuperview_view2",    @"viewDidMoveToSuperview_view2",    @"viewWillMoveToWindow_view2",    @"viewDidMoveToWindow_view2"];

    [view1 addSubview:view2];
    [view2 setHidden:YES];

    methodCalled = [];

    [view2 removeFromSuperview];
    [self assertTrue: [view2 isHiddenOrHasHiddenAncestor] message:@"Expected isHiddenOrHasHiddenAncestor = YES" ];
    [self assert:expectedResult equals:methodCalled];
}

- (void)testLostHiddenAncestorAfterMovingToNewSuperview
{
    var expectedResult = @[
    @"viewWillMoveToSuperview_view2",
    @"viewDidMoveToSuperview_view2",
    @"viewDidHide_view1",
    @"viewDidHide_view2",
    @"viewWillMoveToSuperview_view2",
    @"viewDidUnhide_view2",
    @"viewDidMoveToSuperview_view2"
];

    [view1 addSubview:view2];
    [view1 setHidden:YES];
    [view3 addSubview:view2];

    [self assert:expectedResult equals:methodCalled];
}
// TrackingAreaAdditions

- (void)testTrackingAreas
{
    var trackingArea = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:CPTrackingMouseEnteredAndExited | CPTrackingActiveInKeyWindow | CPTrackingInVisibleRect owner:self userInfo:nil];

    [self assert:0 equals:[[view trackingAreas] count] message:@"Initially, a view has no tracking area"];

    //

    [view addTrackingArea:trackingArea];
    [self assert:1 equals:[[view trackingAreas] count] message:@"After adding a tracking area"];
    [self assert:view equals:[trackingArea view] message:@"Tracking area should be linked to view"];

    //

    [view removeTrackingArea:trackingArea];
    [self assert:0 equals:[[view trackingAreas] count] message:@"After removing the only tracking area"];
    [self assert:nil equals:[trackingArea view] message:@"Tracking area should be unlinked"];

    //

    [view addTrackingArea:trackingArea];
    [view addTrackingArea:trackingArea];
    [view addTrackingArea:trackingArea];
    [self assert:1 equals:[[view trackingAreas] count] message:@"Adding the same tracking area multiple times should add it once"];
    [self assert:view equals:[trackingArea view] message:@"Tracking area should be linked to view"];

    var trackingArea2 = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:CPTrackingMouseEnteredAndExited | CPTrackingActiveInKeyWindow owner:self userInfo:nil];

    //

    [view addTrackingArea:trackingArea2];
    [self assert:2 equals:[[view trackingAreas] count] message:@"After adding a second tracking area"];
    [self assert:view equals:[trackingArea2 view] message:@"Tracking area should be linked to view"];

    //

    [view removeAllTrackingAreas];
    [self assert:0 equals:[[view trackingAreas] count] message:@"After removing all tracking areas"];
    [self assert:nil equals:[trackingArea view] message:@"Tracking area should be unlinked"];
    [self assert:nil equals:[trackingArea2 view] message:@"Tracking area should be unlinked"];

    //

    [view addTrackingArea:trackingArea];

    var contentView = [window contentView];

    [contentView addSubview:view];
    [self assert:0 equals:updateTrackingAreasCalls message:@"Putting a view with a CPTrackingAreaInVisibleRect in a window should not call updateTrackingAreas"];

    [view removeFromSuperview];

    //

    [view addTrackingArea:trackingArea2];
    [contentView addSubview:view];
    [self assert:1 equals:updateTrackingAreasCalls message:@"Putting a view with a non CPTrackingAreaInVisibleRect in a window should call updateTrackingAreas"];

    [view removeAllTrackingAreas];

    //

    var viewTA = [[CPTrackingAreaView alloc] initWithFrame:CGRectMakeZero()];
    updateTrackingAreasCalls = 0;

    [contentView addSubview:viewTA];
    [self assert:1 equals:updateTrackingAreasCalls message:@"Putting a view with no tracking areas in a window should call updateTrackingAreas"];

    //

    updateTrackingAreasCalls = 0;

    [viewTA addTrackingArea:trackingArea];
    [viewTA setFrame:CGRectMake(10, 10, 10, 10)];
    [self assert:0 equals:updateTrackingAreasCalls message:@"Changing geometry of a view with a CPTrackingAreaInVisibleRect should not call updateTrackingAreas"];

    //

    updateTrackingAreasCalls = 0;

    [viewTA addTrackingArea:trackingArea2];
    [viewTA setFrame:CGRectMake(20, 20, 20, 20)];
    [self assert:1 equals:updateTrackingAreasCalls message:@"Changing geometry of a view with a non CPTrackingAreaInVisibleRect should call updateTrackingAreas"];

    //

    var trackingAreaAll = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:CPTrackingMouseEnteredAndExited | CPTrackingMouseMoved | CPTrackingCursorUpdate | CPTrackingActiveInActiveApp | CPTrackingInVisibleRect owner:viewTA userInfo:nil];

    [viewTA removeAllTrackingAreas];
    [viewTA addTrackingArea:trackingAreaAll];

    // Mouse enters the tracking area

    [self moveMouseAtPoint:CGPointMake(21, 21) dragging:NO];

    [self assert:1 equals:mouseEnteredCalls message:@"Mouse entering a tracking area should call mouseEntered"];
    [self assert:0 equals:mouseExitedCalls  message:@"Mouse entering a tracking area should not call mouseExited"];
    [self assert:0 equals:mouseMovedCalls   message:@"Mouse entering a tracking area should not call mouseMoved"];
    [self assert:1 equals:cursorUpdateCalls message:@"Mouse entering a tracking area should call cursorUpdate"];

    // Mouse moves in the tracking area

    [self moveMouseAtPoint:CGPointMake(22, 22) dragging:NO];

    [self assert:0 equals:mouseEnteredCalls message:@"Mouse moving in a tracking area should not call mouseEntered"];
    [self assert:0 equals:mouseExitedCalls  message:@"Mouse moving in a tracking area should not call mouseExited"];
    [self assert:1 equals:mouseMovedCalls   message:@"Mouse moving in a tracking area should call mouseMoved"];
    [self assert:0 equals:cursorUpdateCalls message:@"Mouse moving in a tracking area should not call cursorUpdate"];

    // Mouse exits from the tracking area

    [self moveMouseAtPoint:CGPointMake(0, 0) dragging:NO];

    [self assert:0 equals:mouseEnteredCalls message:@"Mouse exiting from a tracking area should not call mouseEntered"];
    [self assert:1 equals:mouseExitedCalls  message:@"Mouse exiting from a tracking area should call mouseExited"];
    [self assert:0 equals:mouseMovedCalls   message:@"Mouse exiting from a tracking area should not call mouseMoved"];
    [self assert:0 equals:cursorUpdateCalls message:@"Mouse exiting from a tracking area should not call cursorUpdate"];

    // Mouse enters the tracking area while dragging

    [self moveMouseAtPoint:CGPointMake(21, 21) dragging:YES];

    [self assert:0 equals:mouseEnteredCalls message:@"While dragging, mouse entering a tracking area without CPTrackingEnabledDuringMouseDrag should not call mouseEntered"];
    [self assert:0 equals:mouseExitedCalls  message:@"While dragging, mouse entering a tracking area without CPTrackingEnabledDuringMouseDrag should not call mouseExited"];
    [self assert:0 equals:mouseMovedCalls   message:@"While dragging, mouse entering a tracking area without CPTrackingEnabledDuringMouseDrag should not call mouseMoved"];
    [self assert:0 equals:cursorUpdateCalls message:@"While dragging, mouse entering a tracking area without CPTrackingEnabledDuringMouseDrag should not call cursorUpdate"];

    // Mouse moves in the tracking area while dragging

    [self moveMouseAtPoint:CGPointMake(22, 22) dragging:YES];

    [self assert:0 equals:mouseEnteredCalls message:@"While dragging, mouse moving in a tracking area without CPTrackingEnabledDuringMouseDrag should not call mouseEntered"];
    [self assert:0 equals:mouseExitedCalls  message:@"While dragging, mouse moving in a tracking area without CPTrackingEnabledDuringMouseDrag should not call mouseExited"];
    [self assert:0 equals:mouseMovedCalls   message:@"While dragging, mouse moving in a tracking area without CPTrackingEnabledDuringMouseDrag should not call mouseMoved"];
    [self assert:0 equals:cursorUpdateCalls message:@"While dragging, mouse moving in a tracking area without CPTrackingEnabledDuringMouseDrag should not call cursorUpdate"];

    // Mouse exits from the tracking area while dragging

    [self moveMouseAtPoint:CGPointMake(0, 0) dragging:YES];

    [self assert:0 equals:mouseEnteredCalls message:@"While dragging, mouse exiting from a tracking area without CPTrackingEnabledDuringMouseDrag should not call mouseEntered"];
    [self assert:0 equals:mouseExitedCalls  message:@"While dragging, mouse exiting from a tracking area without CPTrackingEnabledDuringMouseDrag should not call mouseExited"];
    [self assert:0 equals:mouseMovedCalls   message:@"While dragging, mouse exiting from a tracking area without CPTrackingEnabledDuringMouseDrag should not call mouseMoved"];
    [self assert:0 equals:cursorUpdateCalls message:@"While dragging, mouse exiting from a tracking area without CPTrackingEnabledDuringMouseDrag should not call cursorUpdate"];

    //

    var trackingAreaAllWithDrag = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:CPTrackingMouseEnteredAndExited | CPTrackingMouseMoved | CPTrackingCursorUpdate | CPTrackingActiveInActiveApp | CPTrackingInVisibleRect | CPTrackingEnabledDuringMouseDrag owner:viewTA userInfo:nil];

    [viewTA removeAllTrackingAreas];
    [viewTA addTrackingArea:trackingAreaAllWithDrag];

    // Mouse enters the tracking area while dragging (option set)

    [self moveMouseAtPoint:CGPointMake(21, 21) dragging:YES];

    [self assert:1 equals:mouseEnteredCalls message:@"While dragging, mouse entering a tracking area with CPTrackingEnabledDuringMouseDrag should call mouseEntered"];
    [self assert:0 equals:mouseExitedCalls  message:@"While dragging, mouse entering a tracking area with CPTrackingEnabledDuringMouseDrag should not call mouseExited"];
    [self assert:0 equals:mouseMovedCalls   message:@"While dragging, mouse entering a tracking area with CPTrackingEnabledDuringMouseDrag should not call mouseMoved"];
    [self assert:0 equals:cursorUpdateCalls message:@"While dragging, mouse entering a tracking area with CPTrackingEnabledDuringMouseDrag should not call cursorUpdate"];

    // Mouse moves in the tracking area while dragging (option set)

    [self moveMouseAtPoint:CGPointMake(22, 22) dragging:YES];

    [self assert:0 equals:mouseEnteredCalls message:@"While dragging, mouse moving in a tracking area with CPTrackingEnabledDuringMouseDrag should not call mouseEntered"];
    [self assert:0 equals:mouseExitedCalls  message:@"While dragging, mouse moving in a tracking area with CPTrackingEnabledDuringMouseDrag should not call mouseExited"];
    [self assert:0 equals:mouseMovedCalls   message:@"While dragging, mouse moving in a tracking area with CPTrackingEnabledDuringMouseDrag should not call mouseMoved"];
    [self assert:0 equals:cursorUpdateCalls message:@"While dragging, mouse moving in a tracking area with CPTrackingEnabledDuringMouseDrag should not call cursorUpdate"];

    // Mouse exits from the tracking area while dragging (option set)

    [self moveMouseAtPoint:CGPointMake(0, 0) dragging:YES];

    [self assert:0 equals:mouseEnteredCalls message:@"While dragging, mouse exiting from a tracking area with CPTrackingEnabledDuringMouseDrag should not call mouseEntered"];
    [self assert:1 equals:mouseExitedCalls  message:@"While dragging, mouse exiting from a tracking area with CPTrackingEnabledDuringMouseDrag should call mouseExited"];
    [self assert:0 equals:mouseMovedCalls   message:@"While dragging, mouse exiting from a tracking area with CPTrackingEnabledDuringMouseDrag should not call mouseMoved"];
    [self assert:0 equals:cursorUpdateCalls message:@"While dragging, mouse exiting from a tracking area with CPTrackingEnabledDuringMouseDrag should not call cursorUpdate"];

    // Nested views

    var innerViewTA = [[CPTrackingAreaView alloc] initWithFrame:CGRectMake(5, 5, 10, 10)];

    [viewTA addSubview:innerViewTA];

    var innerTrackingArea = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:CPTrackingMouseEnteredAndExited | CPTrackingMouseMoved | CPTrackingCursorUpdate | CPTrackingActiveInActiveApp | CPTrackingInVisibleRect owner:innerViewTA userInfo:nil];

    [innerViewTA addTrackingArea:innerTrackingArea];

    // Mouse enters outer view

    [self moveMouseAtPoint:CGPointMake(21, 21) dragging:NO];

    [self assert:1 equals:mouseEnteredCalls message:@"Mouse entering outer tracking area should call mouseEntered"];
    [self assert:0 equals:mouseExitedCalls  message:@"Mouse entering outer tracking area should not call mouseExited"];
    [self assert:0 equals:mouseMovedCalls   message:@"Mouse entering outer tracking area should not call mouseMoved"];
    [self assert:1 equals:cursorUpdateCalls message:@"Mouse entering outer tracking area should call cursorUpdate"];

    // Mouse enters inner view

    [self moveMouseAtPoint:CGPointMake(26, 26) dragging:NO];

    [self assert:1 equals:mouseEnteredCalls message:@"Mouse entering inner tracking area should call mouseEntered"];
    [self assert:0 equals:mouseExitedCalls  message:@"Mouse entering inner tracking area should not call mouseExited"];
    [self assert:1 equals:mouseMovedCalls   message:@"Mouse entering inner tracking area should call mouseMoved"];
    [self assert:1 equals:cursorUpdateCalls message:@"Mouse entering inner tracking area should call cursorUpdate"];

    // Mouse moves in inner view

    [self moveMouseAtPoint:CGPointMake(27, 27) dragging:NO];

    [self assert:0 equals:mouseEnteredCalls message:@"Mouse moving in inner tracking area should not call mouseEntered"];
    [self assert:0 equals:mouseExitedCalls  message:@"Mouse moving in inner tracking area should not call mouseExited"];
    [self assert:2 equals:mouseMovedCalls   message:@"Mouse moving in inner tracking area should call mouseMoved for both views"];
    [self assert:0 equals:cursorUpdateCalls message:@"Mouse moving in inner tracking area should not call cursorUpdate"];

    // Mouse leaves inner view but remains in outer view

    [self moveMouseAtPoint:CGPointMake(36, 36) dragging:NO];

    [self assert:0 equals:mouseEnteredCalls message:@"Mouse moving from inner to outer tracking area should not call mouseEntered"];
    [self assert:1 equals:mouseExitedCalls  message:@"Mouse moving from inner to outer tracking area should call mouseExited (for inner)"];
    [self assert:1 equals:mouseMovedCalls   message:@"Mouse moving from inner to outer tracking area should call mouseMoved (for outer)"];
    [self assert:1 equals:cursorUpdateCalls message:@"Mouse moving from inner to outer tracking area should call cursorUpdate (for outer)"];

    [self assert:innerViewTA equals:involvedViewForMouseExited  message:@"Inner view should receive mouseExited"];
    [self assert:viewTA      equals:involvedViewForCursorUpdate message:@"Outer view should receive cursorUpdate"];

    // Complex test for cursor update frontmost tracking area detection

    var viewA = [[CPTrackingAreaView alloc] initWithFrame:CGRectMake(0, 30, 40, 40)],
        viewB = [[CPTrackingAreaView alloc] initWithFrame:CGRectMake(30, 20, 40, 40)],
        viewC = [[CPTrackingAreaView alloc] initWithFrame:CGRectMake(10, 0, 40, 40)];

    [contentView setSubviews:[CPArray array]];
    [contentView addSubview:viewA];
    [contentView addSubview:viewB];
    [contentView addSubview:viewC];

    var subviewA = [[CPTrackingAreaView alloc] initWithFrame:CGRectMake(20, 0, 20, 20)],
        subviewB = [[CPTrackingAreaView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)],
        subviewC = [[CPTrackingAreaView alloc] initWithFrame:CGRectMake(0, 20, 40, 20)];

    [viewA addSubview:subviewA];
    [viewB addSubview:subviewB];
    [viewC addSubview:subviewC];

    var options              = CPTrackingCursorUpdate | CPTrackingActiveInActiveApp | CPTrackingInVisibleRect,
        options2             = CPTrackingMouseEnteredAndExited | CPTrackingActiveInActiveApp | CPTrackingInVisibleRect,
        options3             = CPTrackingCursorUpdate | CPTrackingActiveInActiveApp,
        viewATrackingArea    = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:options  owner:viewA userInfo:nil],
        viewBTrackingArea    = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:options  owner:viewB userInfo:nil],
        viewCTrackingArea    = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:options2 owner:viewC userInfo:nil],
        subviewATrackingArea = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()          options:options  owner:subviewA userInfo:nil],
        subviewBTrackingArea = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()          options:options  owner:subviewB userInfo:nil],
        subviewCtrackingArea = [[CPTrackingArea alloc] initWithRect:CGRectMake(20, 0, 20, 20) options:options3 owner:subviewC userInfo:nil];

    [viewA addTrackingArea:viewATrackingArea];
    [viewB addTrackingArea:viewBTrackingArea];
    [viewC addTrackingArea:viewCTrackingArea];

    [subviewA addTrackingArea:subviewATrackingArea];
    [subviewB addTrackingArea:subviewBTrackingArea];
    [subviewC addTrackingArea:subviewCtrackingArea];

    // Step 1

    [self moveMouseAtPoint:CGPointMake(5, 25) dragging:NO];

    [self assert:0   equals:cursorUpdateCalls           message:@"Step 1 : no cursorUpdate should be called"];
    [self assert:nil equals:involvedViewForCursorUpdate message:@"Step 1 : no view should be called for cursorUpdate"];

    // Step 2

    [self moveMouseAtPoint:CGPointMake(5, 35) dragging:NO];

    [self assert:1     equals:cursorUpdateCalls           message:@"Step 2 : 1 cursorUpdate should be called"];
    [self assert:viewA equals:involvedViewForCursorUpdate message:@"Step 2 : viewA should be called for cursorUpdate"];

    // Step 3

    [self moveMouseAtPoint:CGPointMake(15, 35) dragging:NO];

    [self assert:0   equals:cursorUpdateCalls           message:@"Step 3 : no cursorUpdate should be called"];
    [self assert:nil equals:involvedViewForCursorUpdate message:@"Step 3 : no view should be called for cursorUpdate"];

    // Step 4

    [self moveMouseAtPoint:CGPointMake(25, 35) dragging:NO];

    [self assert:1        equals:cursorUpdateCalls           message:@"Step 4 : 1 cursorUpdate should be called"];
    [self assert:subviewA equals:involvedViewForCursorUpdate message:@"Step 4 : subviewA should be called for cursorUpdate"];

    // Step 5

    [self moveMouseAtPoint:CGPointMake(35, 35) dragging:NO];

    [self assert:1        equals:cursorUpdateCalls           message:@"Step 5 : 1 cursorUpdate should be called"];
    [self assert:subviewC equals:involvedViewForCursorUpdate message:@"Step 5 : subviewC should be called for cursorUpdate"];

    // Step 6

    [self moveMouseAtPoint:CGPointMake(45, 35) dragging:NO];

    [self assert:0   equals:cursorUpdateCalls           message:@"Step 6 : no cursorUpdate should be called"];
    [self assert:nil equals:involvedViewForCursorUpdate message:@"Step 6 : no view should be called for cursorUpdate"];

    // Step 7

    [self moveMouseAtPoint:CGPointMake(55, 35) dragging:NO];

    [self assert:1     equals:cursorUpdateCalls           message:@"Step 7 : 1 cursorUpdate should be called"];
    [self assert:viewB equals:involvedViewForCursorUpdate message:@"Step 7 : viewB should be called for cursorUpdate"];

    // Step 8

    [self moveMouseAtPoint:CGPointMake(75, 35) dragging:NO];

    [self assert:0   equals:cursorUpdateCalls           message:@"Step 8 : no cursorUpdate should be called"];
    [self assert:nil equals:involvedViewForCursorUpdate message:@"Step 8 : no view should be called for cursorUpdate"];

    // Cursor tests

    var viewA = [[CPTrackingAreaViewWithCursorUpdate alloc] initWithFrame:CGRectMake(20, 20, 40, 40)],
        viewB = [[CPTrackingAreaView alloc] initWithFrame:CGRectMake(10, 10, 80, 80)],
        viewC = [[CPTrackingAreaViewWithoutCursorUpdate alloc] initWithFrame:CGRectMake(10, 10, 80, 80)];

    [contentView setSubviews:[CPArray array]];
    [contentView addSubview:viewA];

    var options  = CPTrackingCursorUpdate | CPTrackingActiveInActiveApp | CPTrackingInVisibleRect;

    var viewATrackingArea = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:options owner:viewA userInfo:nil],
        viewBTrackingArea = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:options owner:viewB userInfo:nil],
        viewCTrackingArea = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:options owner:viewC userInfo:nil];

    [viewA addTrackingArea:viewATrackingArea];
    [viewB addTrackingArea:viewBTrackingArea];
    [viewC addTrackingArea:viewCTrackingArea];

    // Step 1.1 : outside the view

    [self moveMouseAtPoint:CGPointMake(10, 10) dragging:NO];

    [self assert:[CPCursor arrowCursor] equals:[CPCursor currentCursor] message:@"Step 1.1 : cursor should be an arrow"];

    // Step 1.2 : inside the view

    [self moveMouseAtPoint:CGPointMake(30, 30) dragging:NO];

    [self assert:[CPCursor crosshairCursor] equals:[CPCursor currentCursor] message:@"Step 1.2 : cursor should be a crosshair"];

    // Step 1.3 : outside the view

    [self moveMouseAtPoint:CGPointMake(70, 70) dragging:NO];

    [self assert:[CPCursor arrowCursor] equals:[CPCursor currentCursor] message:@"Step 1.3 : cursor should be an arrow"];

    // Step 1.4 : inside the view with dragging

    [self moveMouseAtPoint:CGPointMake(30, 30) dragging:YES];

    [self assert:[CPCursor arrowCursor] equals:[CPCursor currentCursor] message:@"Step 1.4 : cursor should be an arrow"];

    // Step 1.5 : mouse up (ends dragging)

    [self mouseUpAtPoint:CGPointMake(30, 30)];

    [self assert:[CPCursor crosshairCursor] equals:[CPCursor currentCursor] message:@"Step 1.5 : cursor should be a crosshair"];

    // Step 1.6 : outside the view with dragging

    [self moveMouseAtPoint:CGPointMake(10, 10) dragging:YES];

    [self assert:[CPCursor crosshairCursor] equals:[CPCursor currentCursor] message:@"Step 1.6 : cursor should be a crosshair"];

    // Step 1.7 : mouse up (ends dragging)

    [self mouseUpAtPoint:CGPointMake(10, 10)];

    [self assert:[CPCursor arrowCursor] equals:[CPCursor currentCursor] message:@"Step 1.7 : cursor should be an arrow"];

    //

    [self moveMouseAtPoint:CGPointMake(1, 1) dragging:NO];

    [viewA removeFromSuperview];
    [contentView addSubview:viewB];
    [viewB addSubview:viewA];

    // Step 2.1 : outside the superview

    [self moveMouseAtPoint:CGPointMake(5, 5) dragging:NO];

    [self assert:[CPCursor arrowCursor] equals:[CPCursor currentCursor] message:@"Step 2.1 : cursor should be an arrow"];

    // Step 2.2 : inside the superview / outside the subview

    [self moveMouseAtPoint:CGPointMake(15, 15) dragging:NO];

    [self assert:[CPCursor arrowCursor] equals:[CPCursor currentCursor] message:@"Step 2.2 : cursor should be an arrow"];

    // Step 2.3 : inside the subview

    [self moveMouseAtPoint:CGPointMake(35, 35) dragging:NO];

    [self assert:[CPCursor crosshairCursor] equals:[CPCursor currentCursor] message:@"Step 2.3 : cursor should be a crosshair"];

    // Step 2.4 : outside the subview / inside the superview

    [self moveMouseAtPoint:CGPointMake(15, 15) dragging:NO];

    [self assert:[CPCursor crosshairCursor] equals:[CPCursor currentCursor] message:@"Step 2.4 : cursor should be a crosshair"];

    // Step 2.5 : outside the superview

    [self moveMouseAtPoint:CGPointMake(5, 5) dragging:NO];

    [self assert:[CPCursor arrowCursor] equals:[CPCursor currentCursor] message:@"Step 2.5 : cursor should be an arrow"];

    //

    [self moveMouseAtPoint:CGPointMake(1, 1) dragging:NO];

    [viewA removeFromSuperview];
    [viewB removeFromSuperview];
    [contentView addSubview:viewC];
    [viewC addSubview:viewA];

    // Step 3.1 : outside the superview

    [self moveMouseAtPoint:CGPointMake(5, 5) dragging:NO];

    [self assert:[CPCursor arrowCursor] equals:[CPCursor currentCursor] message:@"Step 3.1 : cursor should be an arrow"];

    // Step 3.2 : inside the superview / outside the subview

    [self moveMouseAtPoint:CGPointMake(15, 15) dragging:NO];

    [self assert:[CPCursor arrowCursor] equals:[CPCursor currentCursor] message:@"Step 3.2 : cursor should be an arrow"];

    // Step 3.3 : inside the subview

    [self moveMouseAtPoint:CGPointMake(35, 35) dragging:NO];

    [self assert:[CPCursor crosshairCursor] equals:[CPCursor currentCursor] message:@"Step 3.3 : cursor should be a crosshair"];

    // Step 3.4 : outside the subview / inside the superview

    [self moveMouseAtPoint:CGPointMake(15, 15) dragging:NO];

    [self assert:[CPCursor arrowCursor] equals:[CPCursor currentCursor] message:@"Step 3.4 : cursor should be an arrow"];

    // Step 3.5 : outside the superview

    [self moveMouseAtPoint:CGPointMake(5, 5) dragging:NO];

    [self assert:[CPCursor arrowCursor] equals:[CPCursor currentCursor] message:@"Step 3.5 : cursor should be an arrow"];

}

- (void)testTrackingAreasLiveViewHierarchyModification
{
    // 1. viewB inside viewA with mouseEntered removing itself

    var viewA = [[CPTrackingAreaViewWithCursorUpdate alloc] initWithFrame:CGRectMake(20, 20, 40, 40)],
        viewB = [[CPTrackingAreaViewLiveRemoval      alloc] initWithFrame:CGRectMake(10, 10, 20, 20)];

    [[window contentView] setSubviews:[CPArray arrayWithObject:viewA]];
    [viewA addSubview:viewB];

    var options           = CPTrackingMouseEnteredAndExited | CPTrackingCursorUpdate | CPTrackingActiveInActiveApp | CPTrackingInVisibleRect,
        viewATrackingArea = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:options owner:viewA userInfo:nil],
        viewBTrackingArea = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:options owner:viewB userInfo:nil];

    [viewA addTrackingArea:viewATrackingArea];
    [viewB addTrackingArea:viewBTrackingArea];

    // Step 1.1 : enter viewA

    [self moveMouseAtPoint:CGPointMake(25, 25) dragging:NO];

    [self assert:1 equals:mouseEnteredCalls message:@"1.1 There should be one and only one mouseEntered call"];
    [self assert:0 equals:mouseExitedCalls  message:@"1.1 There should be no mouseExited call"];
    [self assert:0 equals:mouseMovedCalls   message:@"1.1 There should be no mouseMoved call"];
    [self assert:1 equals:cursorUpdateCalls message:@"1.1 There should be one and only one cursorUpdate call"];

    [self assert:viewA equals:involvedViewForMouseEntered message:@"1.1 viewA should receive mouseEntered"];
    [self assert:viewA equals:involvedViewForCursorUpdate message:@"1.1 viewA should receive cursorUpdate"];

    // Step 1.2 : enter viewB

    [self moveMouseAtPoint:CGPointMake(40, 40) dragging:NO];

    [self assert:1 equals:mouseEnteredCalls message:@"1.2 There should be one and only one mouseEntered call"];
    [self assert:0 equals:mouseExitedCalls  message:@"1.2 There should be no mouseExited call"];
    [self assert:0 equals:mouseMovedCalls   message:@"1.2 There should be no mouseMoved call"];
    [self assert:0 equals:cursorUpdateCalls message:@"1.2 There should be no cursorUpdate call"];

    [self assert:viewB equals:involvedViewForMouseEntered message:@"1.2 viewB should receive mouseEntered"];

    // Step 1.3 : move back to viewA (there should be no more viewB)

    [self moveMouseAtPoint:CGPointMake(25, 25) dragging:NO];

    [self assert:0 equals:mouseEnteredCalls message:@"1.3 There should be no mouseEntered call"];
    [self assert:0 equals:mouseExitedCalls  message:@"1.3 There should be no mouseExited call"];
    [self assert:0 equals:mouseMovedCalls   message:@"1.3 There should be no mouseMoved call"];
    [self assert:1 equals:cursorUpdateCalls message:@"1.3 There should be one and only one cursorUpdate call"];

    [self assert:viewA equals:involvedViewForCursorUpdate message:@"1.3 viewA should receive cursorUpdate"];

    // Step 1.4 : exit viewA

    [self moveMouseAtPoint:CGPointMake(5, 5) dragging:NO];

    [self assert:0 equals:mouseEnteredCalls message:@"1.4 There should be one and only one mouseEntered call"];
    [self assert:1 equals:mouseExitedCalls  message:@"1.4 There should be one and only on mouseExited call"];
    [self assert:0 equals:mouseMovedCalls   message:@"1.4 There should be no mouseMoved call"];
    [self assert:0 equals:cursorUpdateCalls message:@"1.4 There should be no cursorUpdate call"];

    [self assert:viewA equals:involvedViewForMouseExited message:@"1.4 viewA should receive mouseExited"];

    // 2. viewA with mouseEntered adding viewB inside it. Testing if viewB receive mouseEntered & cursorUpdate

    var viewA = [[CPTrackingAreaViewLiveAddition alloc] initWithFrame:CGRectMake(20, 20, 40, 40)];

    [[window contentView] setSubviews:[CPArray arrayWithObject:viewA]];

    var options           = CPTrackingMouseEnteredAndExited | CPTrackingCursorUpdate | CPTrackingActiveInActiveApp | CPTrackingInVisibleRect,
        viewATrackingArea = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:options owner:viewA userInfo:nil];

    [viewA addTrackingArea:viewATrackingArea];

    // Step 2.1 : enter viewA (then add viewB thus enter also viewB)

    [self moveMouseAtPoint:CGPointMake(25, 25) dragging:NO];

    [self assert:2 equals:mouseEnteredCalls message:@"2.1 There should be two mouseEntered calls"];
    [self assert:0 equals:mouseExitedCalls  message:@"2.1 There should be no mouseExited call"];
    [self assert:0 equals:mouseMovedCalls   message:@"2.1 There should be no mouseMoved call"];
    [self assert:2 equals:cursorUpdateCalls message:@"2.1 There should be two cursorUpdate calls"];

    [self assert:[[viewA subviews] firstObject] equals:involvedViewForMouseEntered message:@"2.1 viewB should receive mouseEntered"];
    [self assert:[[viewA subviews] firstObject] equals:involvedViewForCursorUpdate message:@"2.1 viewB should receive cursorUpdate"];
    [self assert:[CPCursor crosshairCursor]     equals:[CPCursor currentCursor]    message:@"2.1 Final cursor should be crosshair cursor, determined by viewB"];

    // Step 2.2 : exit viewA (thus also viewB)

    [self moveMouseAtPoint:CGPointMake(5, 5) dragging:NO];

    [self assert:0 equals:mouseEnteredCalls message:@"2.2 There should be no mouseEntered calls"];
    [self assert:2 equals:mouseExitedCalls  message:@"2.2 There should be two mouseExited call"];
    [self assert:0 equals:mouseMovedCalls   message:@"2.2 There should be no mouseMoved call"];
    [self assert:0 equals:cursorUpdateCalls message:@"2.2 There should be no cursorUpdate calls"];

    [self assert:[[viewA subviews] firstObject] equals:involvedViewForMouseExited message:@"2.2 viewB should receive mouseExited"];
    [self assert:[CPCursor arrowCursor]         equals:[CPCursor currentCursor]   message:@"2.2 Cursor should be an arrow"];

    // 3. viewA with mouseEntered adding viewB inside it BUT with CPTrackingAssumeInside. Testing if viewB receive only cursorUpdate

    var viewA = [[CPTrackingAreaViewLiveAddition2 alloc] initWithFrame:CGRectMake(20, 20, 40, 40)];

    [[window contentView] setSubviews:[CPArray arrayWithObject:viewA]];

    var options           = CPTrackingMouseEnteredAndExited | CPTrackingCursorUpdate | CPTrackingActiveInActiveApp | CPTrackingInVisibleRect,
        viewATrackingArea = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:options owner:viewA userInfo:nil];

    [viewA addTrackingArea:viewATrackingArea];

    // Step 3.1 : enter viewA (then add viewB thus enter also viewB)

    [self moveMouseAtPoint:CGPointMake(25, 25) dragging:NO];

    [self assert:1 equals:mouseEnteredCalls message:@"3.1 There should be two mouseEntered calls"];
    [self assert:0 equals:mouseExitedCalls  message:@"3.1 There should be no mouseExited call"];
    [self assert:0 equals:mouseMovedCalls   message:@"3.1 There should be no mouseMoved call"];
    [self assert:2 equals:cursorUpdateCalls message:@"3.1 There should be two cursorUpdate calls"];

    [self assert:viewA                          equals:involvedViewForMouseEntered message:@"3.1 viewB should receive mouseEntered"];
    [self assert:[[viewA subviews] firstObject] equals:involvedViewForCursorUpdate message:@"3.1 viewB should receive cursorUpdate"];
    [self assert:[CPCursor crosshairCursor]     equals:[CPCursor currentCursor]    message:@"3.1 Final cursor should be crosshair cursor, determined by viewB"];

    // Step 3.2 : exit viewA (thus also viewB)

    [self moveMouseAtPoint:CGPointMake(5, 5) dragging:NO];

    [self assert:0 equals:mouseEnteredCalls message:@"3.2 There should be no mouseEntered calls"];
    [self assert:2 equals:mouseExitedCalls  message:@"3.2 There should be two mouseExited call"];
    [self assert:0 equals:mouseMovedCalls   message:@"3.2 There should be no mouseMoved call"];
    [self assert:0 equals:cursorUpdateCalls message:@"3.2 There should be no cursorUpdate calls"];

    [self assert:[[viewA subviews] firstObject] equals:involvedViewForMouseExited message:@"3.2 viewB should receive mouseExited"];
    [self assert:[CPCursor arrowCursor]         equals:[CPCursor currentCursor]   message:@"3.2 Cursor should be an arrow"];
}

- (void)updateTrackingAreas
{
    updateTrackingAreasCalls++;
}

- (void)resetCounters
{
    mouseEnteredCalls = 0;
    mouseExitedCalls  = 0;
    mouseMovedCalls   = 0;
    cursorUpdateCalls = 0;

    involvedViewForMouseEntered = nil;
    involvedViewForMouseExited  = nil;
    involvedViewForCursorUpdate = nil;
}

- (void)moveMouseAtPoint:(CGPoint)aPoint dragging:(BOOL)dragging
{
    var anEvent = [CPEvent mouseEventWithType:(dragging ? CPLeftMouseDragged : CPMouseMoved)
                                     location:aPoint
                                modifierFlags:0
                                    timestamp:0
                                 windowNumber:[window windowNumber]
                                      context:nil
                                  eventNumber:-1
                                   clickCount:0
                                     pressure:0];

    [self resetCounters];

    [[CPApplication sharedApplication] sendEvent:anEvent];
}

- (void)mouseUpAtPoint:(CGPoint)aPoint
{
    var anEvent = [CPEvent mouseEventWithType:CPLeftMouseUp
                                     location:aPoint
                                modifierFlags:0
                                    timestamp:0
                                 windowNumber:[window windowNumber]
                                      context:nil
                                  eventNumber:-1
                                   clickCount:0
                                     pressure:0];

    [self resetCounters];

    [[CPApplication sharedApplication] sendEvent:anEvent];
}

@end

@implementation CPTrackingAreaView : CPView

- (void)mouseEntered:(CPEvent)anEvent
{
    mouseEnteredCalls++;
    involvedViewForMouseEntered = [[anEvent trackingArea] view];
}

- (void)mouseExited:(CPEvent)anEvent
{
    mouseExitedCalls++;
    involvedViewForMouseExited = [[anEvent trackingArea] view];
}

- (void)mouseMoved:(CPEvent)anEvent
{
    mouseMovedCalls++;
}

- (void)cursorUpdate:(CPEvent)anEvent
{
    cursorUpdateCalls++;
    involvedViewForCursorUpdate = [[anEvent trackingArea] view];
}

- (void)updateTrackingAreas
{
    updateTrackingAreasCalls++;
}

@end

@implementation CPTrackingAreaViewWithCursorUpdate : CPTrackingAreaView

- (void)cursorUpdate:(CPEvent)anEvent
{
    [[CPCursor crosshairCursor] set];
    [super cursorUpdate:anEvent];
}

@end

@implementation CPTrackingAreaViewWithoutCursorUpdate : CPView

@end

@implementation CPTrackingAreaViewLiveRemoval : CPTrackingAreaView

- (void)cursorUpdate:(CPEvent)anEvent
{
    [[CPCursor pointingHandCursor] set];
    [super cursorUpdate:anEvent];
}

- (void)mouseEntered:(CPEvent)anEvent
{
    [self removeFromSuperview];
    [super mouseEntered:anEvent];
}

@end

@implementation CPTrackingAreaViewLiveAddition : CPTrackingAreaView

- (void)cursorUpdate:(CPEvent)anEvent
{
    [[CPCursor pointingHandCursor] set];
    [super cursorUpdate:anEvent];
}

- (void)mouseEntered:(CPEvent)anEvent
{
    var viewB = [[CPTrackingAreaViewWithCursorUpdate alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];

    [self addSubview:viewB];

    [viewB addTrackingArea:[[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:CPTrackingMouseEnteredAndExited | CPTrackingCursorUpdate | CPTrackingActiveInActiveApp | CPTrackingInVisibleRect owner:viewB userInfo:nil]];

    [super mouseEntered:anEvent];
}

@end

@implementation CPTrackingAreaViewLiveAddition2 : CPTrackingAreaView

- (void)cursorUpdate:(CPEvent)anEvent
{
    [[CPCursor pointingHandCursor] set];
    [super cursorUpdate:anEvent];
}

- (void)mouseEntered:(CPEvent)anEvent
{
    var viewB = [[CPTrackingAreaViewWithCursorUpdate alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];

    [self addSubview:viewB];

    [viewB addTrackingArea:[[CPTrackingArea alloc] initWithRect:CGRectMakeZero() options:CPTrackingMouseEnteredAndExited | CPTrackingCursorUpdate | CPTrackingActiveInActiveApp | CPTrackingInVisibleRect | CPTrackingAssumeInside owner:viewB userInfo:nil]];

    [super mouseEntered:anEvent];
}

@end

@implementation CPLayoutView : CPView
{

}

- (void)layoutSubviews
{
    [super layoutSubviews];

    var string = @"layoutSubivews_" + [self identifier];
    [methodCalled addObject:string];
}

@end

@implementation CPResponderView : CPView

- (void)viewDidMoveToSuperview
{
    var string = @"viewDidMoveToSuperview_" + [self identifier];
    [methodCalled addObject:string];
}

- (void)viewDidMoveToWindow
{
    var string = @"viewDidMoveToWindow_" + [self identifier];
    [methodCalled addObject:string];
}

- (void)viewWillMoveToSuperview:(CPView)newSuperview
{
    var string = @"viewWillMoveToSuperview_" + [self identifier];
    [methodCalled addObject:string];
}

- (void)viewWillMoveToWindow:(CPWindow)newWindow
{
    var string = @"viewWillMoveToWindow_" + [self identifier];
    [methodCalled addObject:string];
}

- (void)viewDidUnhide
{
    var string = _cmd + @"_" + [self identifier];
    [methodCalled addObject:string];
}

- (void)viewDidHide
{
    var string = _cmd + @"_" + [self identifier];
    [methodCalled addObject:string];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

@end
