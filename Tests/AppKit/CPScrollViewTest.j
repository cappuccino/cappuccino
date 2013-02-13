@import <AppKit/AppKit.j>

@implementation CPScrollViewTest : OJTestCase
{
}

/*!
    Test that scroll views don't generate bad layouts when very small.
*/
- (void)testZeroSize
{
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMakeZero()],
        documentView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [scrollView setAutohidesScrollers:NO];
    [scrollView setDocumentView:documentView];
    [scrollView setScrollerStyle:CPScrollerStyleLegacy];
    // If the layout operation leads to setKnobProportion:0/0 this will crash.
    [[scrollView horizontalScroller] layoutSubviews];
    [[scrollView verticalScroller] layoutSubviews];
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
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)],
        documentView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 400.0)],
        replacementContentView = [[CPClipView alloc] initWithFrame:[scrollView _insetBounds]],
        replacementDocumentView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 400.0)];

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

- (void)testScrollRectToVisible
{
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)],
        documentView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 1000, 1000)],
        textField1 = [CPTextField textFieldWithStringValue:@"Martin" placeholder:@"" width:10],
        textField2 = [CPTextField textFieldWithStringValue:@"Malte" placeholder:@"" width:10],
        textField1Size = CGSizeMakeCopy([textField1 bounds].size),
        textField2Size = CGSizeMakeCopy([textField2 bounds].size);

    [scrollView setDocumentView:documentView];

    [textField1 setFrameOrigin:CGPointMake(0, 0)];
    [textField2 setFrameOrigin:CGPointMake(500, 500)];

    [documentView addSubview:textField1];
    [documentView addSubview:textField2];

    var visibleRect = [documentView visibleRect],
        originalVisibleSize = CGSizeMakeCopy(visibleRect.size);

    // Make sure we are at the top left corner
    [self assertPoint:CGPointMake(0, 0) equals:visibleRect.origin message:@"VisibleRect origin not at top left corner"];

    // Make the second text field visible
    [textField2 scrollRectToVisible:[textField2 bounds]];

    var visibleRectOriginShouldBeAt = CGPointMake(500 - originalVisibleSize.width + textField2Size.width, 500 -originalVisibleSize.height + textField2Size.height);

    visibleRect = [documentView visibleRect];

    // We should now have the text field in the lower right corner
    [self assertPoint:visibleRectOriginShouldBeAt equals:visibleRect.origin message:@"Second text field not at lower right corner in visible rect"];

    // Make the first text field visible again
    [textField1 scrollRectToVisible:[textField2 bounds]];

    visibleRect = [documentView visibleRect];

    // We should now be back at top left corner
    [self assertPoint:CGPointMake(0, 0) equals:visibleRect.origin message:@"VisibleRect origin not at top left corner again"];
}

- (void)assertPoint:(CGPoint)expected equals:(CGPoint)actual message:(CPString)message
{
    [self assert:expected.x equals:actual.x message:@"X: " + message];
    [self assert:expected.y equals:actual.y message:@"Y: " + message];
}

@end

