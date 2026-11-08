@import <AppKit/CPWindow.j>
@import <AppKit/CPMenuItem.j>
@import <AppKit/_CPBorderlessWindowView.j>
@import <Foundation/CPURL.j>

@implementation CPWindowTest : OJTestCase
{
    CPWindow                _window @accessors(property=window);
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    _window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 1024.0, 768.0)
                                          styleMask:CPWindowNotSizable];
}

- (void)testCanAllocWindow
{
    [self assertTrue:!![self window]];
}

- (void)testThatNilIsInitialFirstResponder
{
    [self assert:nil
          equals:[[self window] initialFirstResponder]
         message:@"The initial first responder must be null"];
}

- (void)testKeyViewLoop
{
    var contentView = [[self window] contentView],
        textField = [CPTextField textFieldWithStringValue:@"" placeholder:@"" width:100.0];

    [textField setFrame:CGRectMake(100.0, 100.0, 100.0, 26.0)];
    [contentView addSubview:textField];

    var nextTextField = [CPTextField textFieldWithStringValue:@"" placeholder:@"" width:100];
    [nextTextField setFrame:CGRectMake(100.0, 200.0, 100.0, 26.0)];
    [contentView addSubview:nextTextField];

    [[self window] recalculateKeyViewLoop];

    // Test nextKeyView
    [self assert:textField
          equals:[contentView nextKeyView]
         message:@"textField should be the next key view of contentView"];

    [self assert:nextTextField
          equals:[textField nextKeyView]
         message:@"nextTextField should be the next key view of textField"];

    [self assert:contentView
          equals:[nextTextField nextKeyView]
         message:@"contentView should be the next key view of nextTextField"];

    // Test previousKeyView
    [self assert:contentView
          equals:[textField previousKeyView]
         message:@"contentView should be the previous key view of textField"];

    [self assert:textField
          equals:[nextTextField previousKeyView]
         message:@"textField should be the previous key view of nextTextField"];

    [self assert:nextTextField
          equals:[contentView previousKeyView]
         message:@"nextTextField should be the previous key view of contentView"];
}

- (void)testValiKeyViewLoop
{
    var contentView = [[self window] contentView],
        textField = [CPTextField textFieldWithStringValue:@"" placeholder:@"" width:100.0];

    [textField setFrame:CGRectMake(100.0, 100.0, 100.0, 26.0)];
    [contentView addSubview:textField];
    [[self window] recalculateKeyViewLoop];

    var nextTextField = [CPTextField textFieldWithStringValue:@"" placeholder:@"" width:100];
    [nextTextField setFrame:CGRectMake(100.0, 200.0, 100.0, 26.0)];
    [contentView addSubview:nextTextField];
    [[self window] recalculateKeyViewLoop];

    // Test nextValidKeyView
    [self assert:textField
          equals:[contentView nextValidKeyView]
         message:@"textField should be the next valid key view of contentView"];

    [self assert:nextTextField
          equals:[textField nextValidKeyView]
         message:@"nextTextField should be the next valid key view of textField"];

    [self assert:textField
          equals:[nextTextField nextValidKeyView]
         message:@"textField should be the next key valid view of nextTextField"];

    // Test previousValidKeyView
    [self assert:nextTextField
          equals:[textField previousValidKeyView]
         message:@"nextTextField should be the previous valid key view of textField"];

    [self assert:textField
          equals:[nextTextField previousValidKeyView]
         message:@"textField should be the previous key valid view of nextTextField"];

    [self assert:nextTextField
          equals:[contentView previousValidKeyView]
         message:@"nextTextField should be the previous valid key view of contentView"];
}

- (void)testRepresentedFilename
{
    /*
        representedURL and representedFilename
        are drawn from the _representedURL variable.
    */
    var aURL = @"http://www.cappuccino-project.org";

    [[self window] setRepresentedURL:[CPURL URLWithString:aURL]];
    [self assertTrue:[[[self window] representedURL] class] === [CPURL class]];
    /*
        Test for Issue 1633
        Make sure that changing it via setRepresentedFilename doesn't change the type
    */
    [[self window] setRepresentedFilename:aURL];
    [self assertTrue:[[[self window] representedURL] class] === [CPURL class]];
}

- (void)testOrderingMethod
{
    [_window orderFront:self];
    [_window orderBack:self];
    [_window orderFront:self];
    [_window orderOut:self];
}

/*
    The zoom tests supply the standard frame through the delegate. Outside a browser,
    each window has its own platform window, whose usable area follows the window.
*/
- (CPWindow)resizableWindow
{
    return [[CPWindow alloc] initWithContentRect:CGRectMake(100.0, 100.0, 400.0, 300.0)
                                       styleMask:CPTitledWindowMask | CPResizableWindowMask];
}

- (void)assertWindow:(CPWindow)aWindow hasFrame:(CGRect)aFrame
{
    [self assertTrue:CGRectEqualToRect([aWindow frame], aFrame)
             message:@"expected " + CPStringFromRect(aFrame) + " but was " + CPStringFromRect([aWindow frame])];
}

- (void)testZoomTogglesBetweenTheStandardFrameAndTheUserFrame
{
    var window = [self resizableWindow],
        standardFrame = CGRectMake(20.0, 30.0, 640.0, 480.0),
        delegate = [[CPWindowTestZoomDelegate alloc] initWithStandardFrame:standardFrame],
        userFrame = [window frame];

    [window setDelegate:delegate];

    [window zoom:self];
    [self assertWindow:window hasFrame:standardFrame];
    [self assertTrue:[window isZoomed]];

    [window zoom:self];
    [self assertWindow:window hasFrame:userFrame];
    [self assertFalse:[window isZoomed]];
}

- (void)testZoomPassesTheUsableAreaAsTheDefaultFrame
{
    var window = [self resizableWindow],
        delegate = [[CPWindowTestZoomDelegate alloc] initWithStandardFrame:CGRectMake(20.0, 30.0, 640.0, 480.0)],
        usableFrame = [[window platformWindow] usableContentFrame];

    [window setDelegate:delegate];
    [window zoom:self];

    [self assertTrue:CGRectEqualToRect([delegate defaultFrame], usableFrame)
             message:@"expected " + CPStringFromRect(usableFrame) + " but was " + CPStringFromRect([delegate defaultFrame])];
}

- (void)testWindowShouldZoomCanRefuseTheStandardFrame
{
    var window = [self resizableWindow],
        standardFrame = CGRectMake(20.0, 30.0, 640.0, 480.0),
        delegate = [[CPWindowTestZoomDelegate alloc] initWithStandardFrame:standardFrame],
        userFrame = [window frame];

    [delegate setShouldZoom:NO];
    [window setDelegate:delegate];
    [window zoom:self];

    [self assertWindow:window hasFrame:userFrame];
    [self assertTrue:CGRectEqualToRect([delegate proposedFrame], standardFrame)];
}

- (void)testZoomKeepsTheStandardFrameWithinTheMaximumSize
{
    var window = [self resizableWindow];

    [window setMaxSize:CGSizeMake(500.0, 400.0)];
    [window setDelegate:[[CPWindowTestZoomDelegate alloc] initWithStandardFrame:CGRectMake(20.0, 30.0, 640.0, 480.0)]];
    [window zoom:self];

    [self assertWindow:window hasFrame:CGRectMake(20.0, 30.0, 500.0, 400.0)];
}

- (void)testZoomWithoutAUserFrameLeavesTheStandardFrame
{
    var window = [self resizableWindow],
        standardFrame = [window frame];

    [window setDelegate:[[CPWindowTestZoomDelegate alloc] initWithStandardFrame:standardFrame]];
    [window zoom:self];

    [self assertWindow:window hasFrame:standardFrame];
    [self assertTrue:[window isZoomed]];
}

- (void)testAWindowSubclassCanSupplyTheStandardFrame
{
    var window = [[CPWindowTestZoomingWindow alloc] initWithContentRect:CGRectMake(100.0, 100.0, 400.0, 300.0)
                                                              styleMask:CPTitledWindowMask | CPResizableWindowMask];

    [window zoom:self];

    [self assertWindow:window hasFrame:CPWindowTestZoomingWindowStandardFrame];
}

- (void)testPerformZoomZoomsOnlyAResizableWindow
{
    var standardFrame = CGRectMake(20.0, 30.0, 640.0, 480.0),
        resizableWindow = [self resizableWindow],
        fixedWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(100.0, 100.0, 400.0, 300.0) styleMask:CPTitledWindowMask],
        fixedFrame = [fixedWindow frame];

    [resizableWindow setDelegate:[[CPWindowTestZoomDelegate alloc] initWithStandardFrame:standardFrame]];
    [fixedWindow setDelegate:[[CPWindowTestZoomDelegate alloc] initWithStandardFrame:standardFrame]];

    [resizableWindow performZoom:self];
    [fixedWindow performZoom:self];

    [self assertWindow:resizableWindow hasFrame:standardFrame];
    [self assertWindow:fixedWindow hasFrame:fixedFrame];
}

- (void)testZoomItemsAreEnabledOnlyForAResizableWindow
{
    var resizableWindow = [self resizableWindow],
        fixedWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(100.0, 100.0, 400.0, 300.0) styleMask:CPTitledWindowMask];

    [@selector(performZoom:), @selector(zoom:)].forEach(function(anAction)
    {
        var item = [[CPMenuItem alloc] initWithTitle:@"Zoom" action:anAction keyEquivalent:@""];

        [self assertTrue:[resizableWindow validateUserInterfaceItem:item] message:CPStringFromSelector(anAction) + " in a resizable window"];
        [self assertFalse:[fixedWindow validateUserInterfaceItem:item] message:CPStringFromSelector(anAction) + " in a window that cannot resize"];
    });
}

/*
    The title bar height comes from the default theme. This theme fixes it, so that the
    test does not depend on the theme that another test leaves as the default.
*/
- (CPTheme)themeWithTitleBarHeight:(float)aHeight
{
    var theme = [[CPTheme alloc] initWithName:@"CPWindowTestTitleBar"],
        template = [[_CPStandardWindowView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 300.0) styleMask:CPTitledWindowMask];

    [template setValue:aHeight forThemeAttribute:@"title-bar-height"];
    [theme takeThemeFromObject:template];

    return theme;
}

- (void)testDoubleClickInTheTitleBarZoomsTheWindow
{
    var defaultTheme = [CPTheme defaultTheme];

    [CPTheme setDefaultTheme:[self themeWithTitleBarHeight:32.0]];

    try
    {
        var window = [self resizableWindow],
            standardFrame = CGRectMake(20.0, 30.0, 640.0, 480.0),
            event = [CPEvent mouseEventWithType:CPLeftMouseDown
                                       location:CGPointMake(200.0, 16.0)
                                  modifierFlags:0
                                      timestamp:0
                                   windowNumber:[window windowNumber]
                                        context:nil
                                    eventNumber:0
                                     clickCount:2
                                       pressure:0];

        [window setDelegate:[[CPWindowTestZoomDelegate alloc] initWithStandardFrame:standardFrame]];
        [[window _windowView] mouseDown:event];

        [self assertWindow:window hasFrame:standardFrame];
    }
    finally
    {
        [CPTheme setDefaultTheme:defaultTheme];
    }
}

/*
    There is no DOM in the test runner, so ordering a window in or out does not change its
    visibility. The minimize tests start from a window marked visible.
*/
- (CPWindow)visibleWindowWithStyleMask:(unsigned)aStyleMask
{
    var window = [[CPWindow alloc] initWithContentRect:CGRectMake(100.0, 100.0, 400.0, 300.0) styleMask:aStyleMask];

    window._isVisible = YES;

    return window;
}

- (void)testDeminiaturizeRestoresAMinimizedWindow
{
    var window = [self visibleWindowWithStyleMask:CPTitledWindowMask | CPMiniaturizableWindowMask];

    [window miniaturize:self];
    [self assertTrue:[window isMiniaturized]];

    [window deminiaturize:self];
    [self assertFalse:[window isMiniaturized]];
}

- (void)testMinimizingAndRestoringPostNotificationsInOrder
{
    var window = [self visibleWindowWithStyleMask:CPTitledWindowMask | CPMiniaturizableWindowMask],
        center = [CPNotificationCenter defaultCenter],
        names = [],
        record = function(aNotification) { names.push([aNotification name]); },
        observers = [CPWindowWillMiniaturizeNotification, CPWindowDidMiniaturizeNotification, CPWindowDidDeminiaturizeNotification].map(function(aName)
        {
            return [center addObserverForName:aName object:window queue:nil usingBlock:record];
        });

    [window miniaturize:self];
    [window miniaturize:self];
    [window deminiaturize:self];

    observers.forEach(function(anObserver) { [center removeObserver:anObserver]; });

    [self assert:[CPWindowWillMiniaturizeNotification, CPWindowDidMiniaturizeNotification, CPWindowDidDeminiaturizeNotification] equals:names];
}

- (void)testRestoringAMinimizedWindowRestoresItsFirstResponder
{
    var window = [self visibleWindowWithStyleMask:CPTitledWindowMask | CPMiniaturizableWindowMask],
        responder = [[CPWindowTestResponderView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];

    /*
        The window is key before it is minimized, so that restoring it does not make it key
        for the first time, which would choose a first responder of its own.
    */
    [[window contentView] addSubview:responder];
    [window makeFirstResponder:responder];
    [window makeKeyWindow];

    [window miniaturize:self];
    [window deminiaturize:self];

    [self assert:responder equals:[window firstResponder]];
}

- (void)testPerformMiniaturizeMinimizesOnlyAMiniaturizableWindow
{
    var miniaturizableWindow = [self visibleWindowWithStyleMask:CPTitledWindowMask | CPMiniaturizableWindowMask],
        fixedWindow = [self visibleWindowWithStyleMask:CPTitledWindowMask];

    [miniaturizableWindow performMiniaturize:self];
    [fixedWindow performMiniaturize:self];

    [self assertTrue:[miniaturizableWindow isMiniaturized]];
    [self assertFalse:[fixedWindow isMiniaturized]];
}

- (void)testMinimizeButtonMinimizesTheWindow
{
    var window = [self visibleWindowWithStyleMask:CPTitledWindowMask | CPMiniaturizableWindowMask],
        button = [window _windowView]._minimizeButton;

    [button sendAction:[button action] to:[button target]];

    [self assertTrue:[window isMiniaturized]];
}

- (void)testMinimizeItemsAreEnabledOnlyForAMiniaturizableWindow
{
    var miniaturizableWindow = [self visibleWindowWithStyleMask:CPTitledWindowMask | CPMiniaturizableWindowMask],
        fixedWindow = [self visibleWindowWithStyleMask:CPTitledWindowMask];

    [@selector(performMiniaturize:), @selector(miniaturize:)].forEach(function(anAction)
    {
        var item = [[CPMenuItem alloc] initWithTitle:@"Minimize" action:anAction keyEquivalent:@""];

        [self assertTrue:[miniaturizableWindow validateUserInterfaceItem:item] message:CPStringFromSelector(anAction) + " in a miniaturizable window"];
        [self assertFalse:[fixedWindow validateUserInterfaceItem:item] message:CPStringFromSelector(anAction) + " in a window that cannot minimize"];
    });
}

@end

/*
    A view that accepts first responder status.
*/
@implementation CPWindowTestResponderView : CPView

- (BOOL)acceptsFirstResponder
{
    return YES;
}

@end

/*
    Supplies a fixed standard frame and records the frames the window passes to it.
*/
@implementation CPWindowTestZoomDelegate : CPObject
{
    CGRect  _standardFrame;
    CGRect  _defaultFrame   @accessors(readonly, property=defaultFrame);
    CGRect  _proposedFrame  @accessors(readonly, property=proposedFrame);
    BOOL    _shouldZoom     @accessors(property=shouldZoom);
}

- (id)initWithStandardFrame:(CGRect)aFrame
{
    self = [super init];

    if (self)
    {
        _standardFrame = CGRectMakeCopy(aFrame);
        _shouldZoom = YES;
    }

    return self;
}

- (CGRect)windowWillUseStandardFrame:(CPWindow)aWindow defaultFrame:(CGRect)aFrame
{
    _defaultFrame = CGRectMakeCopy(aFrame);

    return CGRectMakeCopy(_standardFrame);
}

- (BOOL)windowShouldZoom:(CPWindow)aWindow toFrame:(CGRect)aFrame
{
    _proposedFrame = CGRectMakeCopy(aFrame);

    return _shouldZoom;
}

@end

var CPWindowTestZoomingWindowStandardFrame = CGRectMake(40.0, 50.0, 600.0, 450.0);

/*
    Supplies its own standard frame, as a window subclass may in Cocoa.
*/
@implementation CPWindowTestZoomingWindow : CPWindow

- (CGRect)windowWillUseStandardFrame:(CPWindow)aWindow defaultFrame:(CGRect)aFrame
{
    return CGRectMakeCopy(CPWindowTestZoomingWindowStandardFrame);
}

@end
