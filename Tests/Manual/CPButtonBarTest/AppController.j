/*
 * AppController.j
 * CPButtonBar Right Buttons Manual Test
 */

@import <Foundation/CPObject.j>
@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPKeyedUnarchiver.j>
@import <AppKit/AppKit.j>

@implementation AppController : CPObject
{
    CPButtonBar buttonBar;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    var bounds = [contentView bounds];

    // 1. Create the ButtonBar
    buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(bounds) - 28, CGRectGetWidth(bounds), 28)];
    [buttonBar setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
    
    // Add resize control to ensure bounds calculations are correct
    [buttonBar setHasResizeControl:YES];

    // 2. Setup standard Left Buttons
    var plusButton = [CPButtonBar plusButton],
        minusButton = [CPButtonBar minusButton];
    
    [buttonBar setButtons:[plusButton, minusButton]];

    // 3. Setup the new Right Buttons (PR #745)
    var actionButton = [CPButtonBar actionPopupButton],
        customRightBtn = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, 70, 24)];
        
    [customRightBtn setTitle:@"Settings"];
    [buttonBar setRightButtons:[customRightBtn, actionButton]];

    [contentView addSubview:buttonBar];

    // --- Testing Controls ---

    // Button to test resizing alignment layout
    var toggleAlignmentBtn = [CPButton buttonWithTitle:@"Toggle Resize Control Alignment"];
    [toggleAlignmentBtn setFrameOrigin:CGPointMake(20, 20)];
    [toggleAlignmentBtn sizeToFit];
    [toggleAlignmentBtn setTarget:self];
    [toggleAlignmentBtn setAction:@selector(toggleResizeAlignment:)];
    [contentView addSubview:toggleAlignmentBtn];

    // Button to test the KVO "hidden" observer on rightButtons
    var toggleVisibilityBtn = [CPButton buttonWithTitle:@"Toggle Right Button Visibility"];
    [toggleVisibilityBtn setFrameOrigin:CGPointMake(20, 60)];
    [toggleVisibilityBtn sizeToFit];
    [toggleVisibilityBtn setTarget:self];
    [toggleVisibilityBtn setAction:@selector(toggleRightVisibility:)];
    [contentView addSubview:toggleVisibilityBtn];

    // Button to test CPCoding archiving/unarchiving of rightButtons
    var testArchivingBtn = [CPButton buttonWithTitle:@"Test Archiving (CPCoding)"];
    [testArchivingBtn setFrameOrigin:CGPointMake(20, 100)];
    [testArchivingBtn sizeToFit];
    [testArchivingBtn setTarget:self];
    [testArchivingBtn setAction:@selector(testArchiving:)];
    [contentView addSubview:testArchivingBtn];

    [theWindow orderFront:self];
}

- (void)toggleResizeAlignment:(id)sender
{
    // Flipping the resize control to the left shouldn't break the right-aligned buttons
    [buttonBar setResizeControlIsLeftAligned:![buttonBar resizeControlIsLeftAligned]];
}

- (void)toggleRightVisibility:(id)sender
{
    var rightBtns = [buttonBar rightButtons];
    if ([rightBtns count] > 0)
    {
        var btn = rightBtns[0];
        [btn setHidden:![btn isHidden]];
    }
}

- (void)testArchiving:(id)sender
{
    // Test the new CPButtonBarRightButtonsKey in CPCoding
    var data = [CPKeyedArchiver archivedDataWithRootObject:buttonBar];
    var unarchivedBar = [CPKeyedUnarchiver unarchiveObjectWithData:data];

    var bounds = [[buttonBar superview] bounds];
    
    // Place the cloned bar directly above the original one
    [unarchivedBar setFrame:CGRectMake(0, CGRectGetHeight(bounds) - 56, CGRectGetWidth(bounds), 28)];
    
    [[buttonBar superview] addSubview:unarchivedBar];
}

@end
