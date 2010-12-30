@import <AppKit/AppKit.j>

@implementation CPScrollViewTest : OJTestCase
{
}

- (void)testBothScrollersVisible
{
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];

    [scrollView setAutohidesScrollers:NO];
    [scrollView setHasHorizontalScroller:YES];
    [scrollView setHasVerticalScroller:YES];

    var documentView = [[CPView alloc] init];

    [scrollView setDocumentView:documentView];

    // Test document view size smaller than scroll view size.
    [documentView setFrameSize:CGSizeMake(50.0, 50.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:NO];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:NO];

    [self assert:[[scrollView verticalScroller] isHidden] equals:NO];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:NO];

    // Test document view size much larger than scroll view size.
    [documentView setFrameSize:CGSizeMake(1000.0, 1000.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:NO];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:YES];

    [self assert:[[scrollView verticalScroller] isHidden] equals:NO];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:YES];

    // Test document view size much taller than scroll view size.
    [documentView setFrameSize:CGSizeMake(50.0, 1000.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:NO];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:NO];

    [self assert:[[scrollView verticalScroller] isHidden] equals:NO];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:YES];

    // Test document view size much wider than scroll view size.
    [documentView setFrameSize:CGSizeMake(1000.0, 50.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:NO];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:YES];

    [self assert:[[scrollView verticalScroller] isHidden] equals:NO];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:NO];

    // Test document view size equal to scroll view size.
    [documentView setFrameSize:CGSizeMake(100.0, 100.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:NO];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:YES];

    [self assert:[[scrollView verticalScroller] isHidden] equals:NO];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:YES];

    // Test document view size taller than scroll view size only because of scrollers.
    [documentView setFrameSize:CGSizeMake(50.0, 100.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:NO];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:NO];

    [self assert:[[scrollView verticalScroller] isHidden] equals:NO];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:YES];

    // Test document view size wider than scroll view size only because of scrollers.
    [documentView setFrameSize:CGSizeMake(100.0, 50.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:NO];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:YES];

    [self assert:[[scrollView verticalScroller] isHidden] equals:NO];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:NO];

    // Test document view size exactly the right size relative to the scroll view size.
    [documentView setFrameSize:CGSizeMake(100.0 - 17.0, 100.0 - 17.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:NO];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:NO];

    [self assert:[[scrollView verticalScroller] isHidden] equals:NO];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:NO];
}

- (void)testAutoHidesScrollers
{
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];

    [scrollView setAutohidesScrollers:YES];
    [scrollView setHasHorizontalScroller:YES];
    [scrollView setHasVerticalScroller:YES];

    var documentView = [[CPView alloc] init];

    [scrollView setDocumentView:documentView];

    // Test document view size smaller than scroll view size.
    [documentView setFrameSize:CGSizeMake(50.0, 50.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:YES];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:NO];

    [self assert:[[scrollView verticalScroller] isHidden] equals:YES];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:NO];

    // Test document view size much larger than scroll view size.
    [documentView setFrameSize:CGSizeMake(1000.0, 1000.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:NO];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:YES];

    [self assert:[[scrollView verticalScroller] isHidden] equals:NO];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:YES];

    // Test document view size much taller than scroll view size.
    [documentView setFrameSize:CGSizeMake(50.0, 1000.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:YES];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:NO];

    [self assert:[[scrollView verticalScroller] isHidden] equals:NO];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:YES];

    // Test document view size much wider than scroll view size.
    [documentView setFrameSize:CGSizeMake(1000.0, 50.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:NO];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:YES];

    [self assert:[[scrollView verticalScroller] isHidden] equals:YES];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:NO];

    // Test document view size equal to scroll view size.
    [documentView setFrameSize:CGSizeMake(100.0, 100.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:YES];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:NO];

    [self assert:[[scrollView verticalScroller] isHidden] equals:YES];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:NO];

    // Test document view size taller than scroll view size only because of scrollers.
    [documentView setFrameSize:CGSizeMake(50.0, 100.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:YES];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:NO];

    [self assert:[[scrollView verticalScroller] isHidden] equals:YES];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:NO];

    // Test document view size wider than scroll view size only because of scrollers.
    [documentView setFrameSize:CGSizeMake(100.0, 50.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:YES];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:NO];

    [self assert:[[scrollView verticalScroller] isHidden] equals:YES];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:NO];

    // Test document view size exactly the right size relative to the scroll view size.
    [documentView setFrameSize:CGSizeMake(100.0 - 17.0, 100.0 - 17.0)];

    [self assert:[[scrollView horizontalScroller] isHidden] equals:YES];
    [self assert:[[scrollView horizontalScroller] isEnabled] equals:NO];

    [self assert:[[scrollView verticalScroller] isHidden] equals:YES];
    [self assert:[[scrollView verticalScroller] isEnabled] equals:NO];
}

- (void)testSetContentView
{
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
    var documentView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 400.0)];

    var replacementContentView = [[CPClipView alloc] initWithFrame:[scrollView _insetBounds]];
    var replacementDocumentView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 400.0)];

    [replacementContentView setDocumentView:replacementDocumentView];

    // Test the obvious condition that they aren't the same
    [self assert:replacementContentView notEqual:[scrollView contentView] message:@"contentView somehow equals the replacement"];

    // Test the obvious condition that the document view can be get/set
    [scrollView setDocumentView:documentView];
    [self assert:documentView equals:[scrollView documentView] message:@"documentView is not set as expected"];

    // Change the content view
    [scrollView setContentView:replacementContentView];

    // Test that the content view has been replaced
    [self assert:replacementContentView equals:[scrollView contentView] message:@"contentView was not replaced properly"];
    // and that the document view has been replaced
    [self assert:replacementDocumentView equals:[scrollView documentView] message:@"documentView was not replaced properly"];
}

@end