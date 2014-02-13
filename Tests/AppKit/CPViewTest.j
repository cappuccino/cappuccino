
@import <AppKit/CPView.j>
@import <AppKit/CPApplication.j>

[CPApplication sharedApplication]

@implementation CPViewTest : OJTestCase
{
    CPView view;
}

- (void)setUp
{
    view = [[CPView alloc] initWithFrame:CGRectMakeZero()];
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

- (void)testThemeState
{
    [self assertTrue:[view hasThemeState:CPThemeStateNormal] message:@"CPView should initialy have CPThemeStateNormal"];
    [self assertFalse:[view hasThemeState:CPThemeStateDisabled] message:@"view should be disabled"];

    [view setThemeState:CPThemeStateDisabled];
    [self assertTrue:[view hasThemeState:CPThemeStateDisabled] message:@"The view should be CPThemeStateDisabled"];

    [view setThemeState:CPThemeStateHighlighted];
    [self assertTrue:[view hasThemeState:CPThemeStateHighlighted] message:@"Theme state should be CPThemeStateHighlighted"];

    [view setThemeState:CPThemeState(CPThemeStateNormal, CPThemeStateHighlighted)];
    [self assertFalse:[view hasThemeState:CPThemeStateNormal] message:@"CPThemeStateNormal cannot exist as part of a compound state"];
    [self assertTrue:[view hasThemeState:CPThemeStateHighlighted] message:@"The view should be CPThemeStateHighlighted"];
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

@end
