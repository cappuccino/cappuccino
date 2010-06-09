
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

@end
