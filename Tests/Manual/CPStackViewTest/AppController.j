/*
 * AppController.j
 * CPStackViewTest
 *
 * Created by Daniel Boehringer.
 * Copyright 2025, Cappuccino Project.
 */

@import <Foundation/CPObject.j>
@import <AppKit/AppKit.j>

// We import the class to be tested. 
// Assuming CPStackView.j is in the same directory or properly included in the build.

@implementation AppController : CPObject
{
    CPWindow        theWindow;
    
    // We will construct these programmatically for the test 
    // to avoid needing a .cib file for a new class.
    CPStackView     stackViewHorizontal;
    CPStackView     stackViewVertical;
    
    // Control references
    CPCheckBox      detachHiddenCheckbox;
    CPView          toggleTargetView;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];
    var contentView = [theWindow contentView];
    [contentView setBackgroundColor:[CPColor colorWithWhite:0.95 alpha:1.0]];

    // 1. Create a Label
    var label = [CPTextField labelWithTitle:@"CPStackView Manual Test"];
    [label setFont:[CPFont boldSystemFontOfSize:18]];
    [label setFrameOrigin:CGPointMake(20, 20)];
    [contentView addSubview:label];

    // 2. Create Horizontal Stack View (The primary test subject)
    // We frame it in the top half
    stackViewHorizontal = [[CPStackView alloc] initWithFrame:CGRectMake(20, 60, 600, 150)];
    [stackViewHorizontal setBackgroundColor:[CPColor whiteColor]];
    [stackViewHorizontal setOrientation:CPUserInterfaceLayoutOrientationHorizontal];
    [stackViewHorizontal setEdgeInsets:CPEdgeInsetsMake(10, 10, 10, 10)];
    
    // Add Views to Horizontal Stack
    // Leading
    [stackViewHorizontal addView:[self _createBoxColor:[CPColor redColor] size:CGSizeMake(40, 40) label:@"L1"] inGravity:CPStackViewGravityLeading];
    [stackViewHorizontal addView:[self _createBoxColor:[CPColor redColor] size:CGSizeMake(60, 80) label:@"L2"] inGravity:CPStackViewGravityLeading]; // Taller to test alignment
    
    // Center
    toggleTargetView = [self _createBoxColor:[CPColor greenColor] size:CGSizeMake(50, 50) label:@"C1\n(Toggle)"];
    [stackViewHorizontal addView:toggleTargetView inGravity:CPStackViewGravityCenter];
    [stackViewHorizontal addView:[self _createBoxColor:[CPColor greenColor] size:CGSizeMake(50, 50) label:@"C2"] inGravity:CPStackViewGravityCenter];

    // Trailing
    [stackViewHorizontal addView:[self _createBoxColor:[CPColor blueColor] size:CGSizeMake(40, 40) label:@"T1"] inGravity:CPStackViewGravityTrailing];
    [stackViewHorizontal addView:[self _createBoxColor:[CPColor blueColor] size:CGSizeMake(40, 40) label:@"T2"] inGravity:CPStackViewGravityTrailing];

    // Set Autoresizing to stick to width
    [stackViewHorizontal setAutoresizingMask:CPViewWidthSizable];
    
    // Visual border for the stack view itself
    var borderView = [[CPView alloc] initWithFrame:CGRectInset([stackViewHorizontal frame], -1, -1)];
    [borderView setBackgroundColor:[CPColor grayColor]];
    [contentView addSubview:borderView];
    [contentView addSubview:stackViewHorizontal];


    // 3. Create Vertical Stack View (Secondary test)
    stackViewVertical = [[CPStackView alloc] initWithFrame:CGRectMake(20, 230, 200, 300)];
    [stackViewVertical setBackgroundColor:[CPColor whiteColor]];
    [stackViewVertical setOrientation:CPUserInterfaceLayoutOrientationVertical];
    [stackViewVertical setEdgeInsets:CPEdgeInsetsMake(5, 5, 5, 5)];
    [stackViewVertical setAlignment:CPLayoutAttributeCenterX]; // Center items horizontally

    [stackViewVertical addView:[self _createBoxColor:[CPColor orangeColor] size:CGSizeMake(40, 30) label:@"Top"] inGravity:CPStackViewGravityTop];
    [stackViewVertical addView:[self _createBoxColor:[CPColor purpleColor] size:CGSizeMake(80, 40) label:@"Mid"] inGravity:CPStackViewGravityCenter];
    [stackViewVertical addView:[self _createBoxColor:[CPColor brownColor] size:CGSizeMake(40, 30) label:@"Bot"] inGravity:CPStackViewGravityBottom];

    var borderViewVert = [[CPView alloc] initWithFrame:CGRectInset([stackViewVertical frame], -1, -1)];
    [borderViewVert setBackgroundColor:[CPColor grayColor]];
    [contentView addSubview:borderViewVert];
    [contentView addSubview:stackViewVertical];


    // 4. Controls Area
    var controlsY = 230;
    var controlsX = 250;

    var btnToggleHide = [CPButton buttonWithTitle:@"Toggle Center View Hidden"];
    [btnToggleHide setFrameOrigin:CGPointMake(controlsX, controlsY)];
    [btnToggleHide setTarget:self];
    [btnToggleHide setAction:@selector(toggleHidden:)];
    [contentView addSubview:btnToggleHide];

    controlsY += 40;
    detachHiddenCheckbox = [CPCheckBox checkBoxWithTitle:@"Detaches Hidden Views"];
    [detachHiddenCheckbox setFrameOrigin:CGPointMake(controlsX, controlsY)];
    [detachHiddenCheckbox setState:CPOnState];
    [detachHiddenCheckbox setTarget:self];
    [detachHiddenCheckbox setAction:@selector(toggleDetaches:)];
    [contentView addSubview:detachHiddenCheckbox];

    controlsY += 40;
    var btnAlignTop = [CPButton buttonWithTitle:@"Align Horizontal: Top"];
    [btnAlignTop setFrameOrigin:CGPointMake(controlsX, controlsY)];
    [btnAlignTop setTarget:self];
    [btnAlignTop setAction:@selector(setAlignmentTop:)];
    [contentView addSubview:btnAlignTop];

    controlsY += 30;
    var btnAlignCenter = [CPButton buttonWithTitle:@"Align Horizontal: CenterY"];
    [btnAlignCenter setFrameOrigin:CGPointMake(controlsX, controlsY)];
    [btnAlignCenter setTarget:self];
    [btnAlignCenter setAction:@selector(setAlignmentCenter:)];
    [contentView addSubview:btnAlignCenter];

    controlsY += 30;
    var btnAlignFill = [CPButton buttonWithTitle:@"Align Horizontal: Height (Fill)"];
    [btnAlignFill setFrameOrigin:CGPointMake(controlsX, controlsY)];
    [btnAlignFill setTarget:self];
    [btnAlignFill setAction:@selector(setAlignmentHeight:)];
    [contentView addSubview:btnAlignFill];
    
    controlsY += 40;
    var btnSpacing = [CPButton buttonWithTitle:@"Increase Spacing"];
    [btnSpacing setFrameOrigin:CGPointMake(controlsX, controlsY)];
    [btnSpacing setTarget:self];
    [btnSpacing setAction:@selector(changeSpacing:)];
    [contentView addSubview:btnSpacing];

    [theWindow setFullPlatformWindow:YES];
    [theWindow orderFront:self];
}

- (void)awakeFromCib
{
    // If we were using a Cib, initialization would happen here.
}

#pragma mark -
#pragma mark Actions

- (@action)toggleHidden:(id)sender
{
    var isHidden = [toggleTargetView isHidden];
    [toggleTargetView setHidden:!isHidden];
    
    // In standard Cocoa, hiding a view triggers layout if stackView is observing,
    // but in this manual implementation, we might need to nudge it or ensure 
    // setHidden triggers needsLayout on superview. 
    // The CPStackView provided relies on 'layoutSubviews' being called.
    
    [stackViewHorizontal setNeedsLayout:YES];
}

- (@action)toggleDetaches:(id)sender
{
    [stackViewHorizontal setDetachesHiddenViews:([sender state] === CPOnState)];
}

- (@action)setAlignmentTop:(id)sender
{
    [stackViewHorizontal setAlignment:CPLayoutAttributeTop];
}

- (@action)setAlignmentCenter:(id)sender
{
    [stackViewHorizontal setAlignment:CPLayoutAttributeCenterY];
}

- (@action)setAlignmentHeight:(id)sender
{
    [stackViewHorizontal setAlignment:CPLayoutAttributeHeight];
}

- (@action)changeSpacing:(id)sender
{
    var current = [stackViewHorizontal spacing];
    [stackViewHorizontal setSpacing:(current >= 20.0 ? 8.0 : current + 4.0)];
}

#pragma mark -
#pragma mark Helpers

- (CPView)_createBoxColor:(CPColor)aColor size:(CGSize)aSize label:(CPString)text
{
    var view = [[CPView alloc] initWithFrame:CGRectMake(0, 0, aSize.width, aSize.height)];
    [view setBackgroundColor:aColor];
    
    var label = [[CPTextField alloc] initWithFrame:CGRectInset([view bounds], 2, 2)];
    [label setStringValue:text];
    [label setTextColor:[CPColor whiteColor]];
    [label setAlignment:CPCenterTextAlignment];
    [label setVerticalAlignment:CPCenterVerticalTextAlignment];
    [label setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [label setLineBreakMode:CPLineBreakByWordWrapping];
    
    [view addSubview:label];
    
    return view;
}

@end
