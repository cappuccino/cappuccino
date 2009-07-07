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

@end