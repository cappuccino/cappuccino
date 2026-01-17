/*
 * AppController.j
 * KitchenSink in Code
 *
 * Created by Daniel Böhringer 2026.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

// --------------------------------------------------------------------------------
// KitchenSinkWindowController
// Manages a single window instance, its specific style (HUD/Standard), and content state.
// --------------------------------------------------------------------------------

@implementation KitchenSinkWindowController : CPWindowController
{
    BOOL    _isHUD;
    BOOL    _areControlsEnabled;
}

- (id)initWithContentRect:(CGRect)aRect isHUD:(BOOL)isHUD enabled:(BOOL)isEnabled
{
    // 1. Determine Style Mask
    var styleMask = CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask;
    
    if (isHUD)
        styleMask |= CPHUDBackgroundWindowMask;

    // 2. Create Window
    var theWindow = [[CPWindow alloc] initWithContentRect:aRect styleMask:styleMask];
    
    self = [super initWithWindow:theWindow];
    
    if (self)
    {
        _isHUD = isHUD;
        _areControlsEnabled = isEnabled;

        var title = (isHUD ? @"HUD Theme" : @"Aqua Theme") + (isEnabled ? @" (Enabled)" : @" (Disabled)");
        [theWindow setTitle:title];

        // 3. Setup Toolbar
        var toolbar = [[CPToolbar alloc] initWithIdentifier:@"KitchenSinkToolbar" + (isHUD ? @"HUD" : @"Aqua")];
        [toolbar setDelegate:self];
        [toolbar setVisible:YES];
        [theWindow setToolbar:toolbar];

        // 4. Build UI
        [self _buildInterface];

        // 5. Apply Enabled State
        if (!isEnabled)
            [self _disableAllControls];
    }

    return self;
}

- (void)_buildInterface
{
    var window = [self window],
        contentView = [window contentView],
        col1X = 20.0,
        col2X = 200.0,
        startY = 20.0,
        gapY = 35.0,
        width = 150.0;

    // --- COLUMN 1 ---

    // Push Button
    var pushButton = [[CPButton alloc] initWithFrame:CGRectMake(col1X, startY, width, 24)];
    [pushButton setTitle:@"Push Button"];
    [contentView addSubview:pushButton];

    // Gradient Button
    var gradientButton = [[CPButton alloc] initWithFrame:CGRectMake(col1X, startY + gapY, width, 24)];
    [gradientButton setTitle:@"Gradient Button"];
    [contentView addSubview:gradientButton];

    // Round Rect Button
    var roundRectButton = [[CPButton alloc] initWithFrame:CGRectMake(col1X, startY + (gapY * 2), width, 24)];
    [roundRectButton setTitle:@"Round Rect Button"];
    [roundRectButton setBezelStyle:CPRoundedBezelStyle];
    [contentView addSubview:roundRectButton];

    // Placeholder TextField
    var placeholderField = [[CPTextField alloc] initWithFrame:CGRectMake(col1X, startY + (gapY * 3), width, 29)];
    [placeholderField setEditable:YES];
    [placeholderField setBezeled:YES];
    [placeholderField setPlaceholderString:@"Placeholder"];
    [contentView addSubview:placeholderField];

    // Normal TextField
    var textField = [[CPTextField alloc] initWithFrame:CGRectMake(col1X, startY + (gapY * 4), width, 29)];
    [textField setEditable:YES];
    [textField setBezeled:YES];
    [textField setStringValue:@"Text Field"];
    [contentView addSubview:textField];

    // Search Field
    var searchField = [[CPSearchField alloc] initWithFrame:CGRectMake(col1X, startY + (gapY * 5), width, 30)];
    [searchField setPlaceholderString:@"Search..."];
    [contentView addSubview:searchField];

    // Token Field
    var tokenField = [[CPTokenField alloc] initWithFrame:CGRectMake(col1X, startY + (gapY * 6), width, 30)];
    [tokenField setObjectValue:["Token", "Field"]];
    [contentView addSubview:tokenField];

    // Combo Box
    var comboBox = [[CPComboBox alloc] initWithFrame:CGRectMake(col1X, startY + (gapY * 7), width, 29)];
    [comboBox setPlaceholderString:@"Combo Box"];
    [comboBox addItemsWithObjectValues:["Alpha", "Beta", "Gamma"]];
    [contentView addSubview:comboBox];

    // Slider
    var bottomSlider = [[CPSlider alloc] initWithFrame:CGRectMake(col1X, startY + (gapY * 8.5), width, 24)];
    [contentView addSubview:bottomSlider];


    // --- COLUMN 2 ---

    // Date Picker
    var datePicker = [[CPDatePicker alloc] initWithFrame:CGRectMake(col2X, startY, 140, 28)];
    [datePicker setDatePickerStyle:CPTextFieldAndStepperDatePickerStyle];
    [datePicker setDateValue:[CPDate date]];
    [contentView addSubview:datePicker];

    // Checkboxes (Grouped visually)
    var cbY = startY + gapY;
    var cbOn = [CPCheckBox checkBoxWithTitle:@"On"];
    [cbOn setFrameOrigin:CGPointMake(col2X, cbY)];
    [cbOn setState:CPOnState];
    [contentView addSubview:cbOn];

    var cbOff = [CPCheckBox checkBoxWithTitle:@"Off"];
    [cbOff setFrameOrigin:CGPointMake(col2X + 50, cbY)];
    [cbOff setState:CPOffState];
    [contentView addSubview:cbOff];

    var cbBoth = [CPCheckBox checkBoxWithTitle:@"Mixed"];
    [cbBoth setFrameOrigin:CGPointMake(col2X + 100, cbY)];
    [cbBoth setState:CPMixedState];
    [contentView addSubview:cbBoth];

    // Pop Up Button
    var popUp = [[CPPopUpButton alloc] initWithFrame:CGRectMake(col2X, startY + (gapY * 2), 150, 24) pullsDown:NO];
    [popUp addItemWithTitle:@"Item 1"];
    [popUp addItemWithTitle:@"Item 2"];
    [contentView addSubview:popUp];

    // Segmented Control
    var seg = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(col2X, startY + (gapY * 3), 160, 24)];
    [seg setSegmentCount:3];
    [seg setLabel:@"One" forSegment:0];
    [seg setLabel:@"Two" forSegment:1];
    [seg setLabel:@"Three" forSegment:2];
    [seg setWidth:50 forSegment:0];
    [seg setSelectedSegment:0];
    [contentView addSubview:seg];

    // Radio Buttons
    var radioY = startY + (gapY * 4);
    var radio1 = [CPRadio radioWithTitle:@"Radio A"];
    [radio1 setFrameOrigin:CGPointMake(col2X, radioY)];
    [radio1 setState:CPOnState];
    [contentView addSubview:radio1];

    var radio2 = [CPRadio radioWithTitle:@"Radio B"];
    [radio2 setFrameOrigin:CGPointMake(col2X, radioY + 22)];
    [contentView addSubview:radio2];
    
    // Link radios target
    [radio1 setTarget:self]; [radio1 setAction:@selector(dummyAction:)];
    [radio2 setTarget:self]; [radio2 setAction:@selector(dummyAction:)];

    // Level Indicator
    var levelInd = [[CPLevelIndicator alloc] initWithFrame:CGRectMake(col2X, startY + (gapY * 5.5), 150, 18)];
    [levelInd setMaxValue:5];
    [levelInd setDoubleValue:3];
    [levelInd setLevelIndicatorStyle:CPDiscreteCapacityLevelIndicatorStyle];
    [contentView addSubview:levelInd];

    // Tick Slider
    var tickSlider = [[CPSlider alloc] initWithFrame:CGRectMake(col2X, startY + (gapY * 6.5), 110, 24)];
    //[tickSlider setNumberOfTickMarks:5];
    [contentView addSubview:tickSlider];

    // Vertical Slider
    var vSlider = [[CPSlider alloc] initWithFrame:CGRectMake(col2X + 130, startY + (gapY * 6.5), 24, 70)];
    [contentView addSubview:vSlider];
    
    // Circular Slider
    var knob = [[CPSlider alloc] initWithFrame:CGRectMake(col2X, startY + (gapY * 7.5), 32, 32)];
    [knob setSliderType:CPCircularSlider];
    [contentView addSubview:knob];
}

- (void)_disableAllControls
{
    var contentView = [[self window] contentView],
        subviews = [contentView subviews],
        count = [subviews count];

    for (var i = 0; i < count; i++)
    {
        var view = subviews[i];
        if ([view respondsToSelector:@selector(setEnabled:)])
        {
            [view setEnabled:NO];
        }
        
        // Handle specific case for labels usually associated with controls 
        // (Not strictly necessary as CPTextField disables nicely, but good for completeness)
        if ([view isKindOfClass:[CPTextField class]] && ![view isEditable])
        {
             //[view setTextColor:[CPColor disabledControlTextColor]];
        }
    }
}

- (void)dummyAction:(id)sender
{
    // Placeholder action for controls
}

// --- TOOLBAR DELEGATE ---

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)aToolbar
{
    return [@"ColorsItem", CPToolbarFlexibleSpaceItemIdentifier];
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar
{
    return [CPToolbarFlexibleSpaceItemIdentifier, @"ColorsItem"];
}

- (CPToolbarItem)toolbar:(CPToolbar)aToolbar itemForItemIdentifier:(CPString)anItemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    var item = [[CPToolbarItem alloc] initWithItemIdentifier:anItemIdentifier];
    
    if (anItemIdentifier == @"ColorsItem")
    {
        [item setLabel:@"Colors"];
        [item setPaletteLabel:@"Colors"];
        
        // Simulating the Color Wheel icon via a drawing block or placeholder resource
        // Since we don't have the PNG, we assume standard bundle presence or generic text
        [item setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/ColorWheel.png" size:CGSizeMake(32, 32)]];
        
        [item setTarget:self];
        [item setAction:@selector(orderFrontColorPanel:)];
    }
    
    return item;
}

@end


// --------------------------------------------------------------------------------
// AppController
// Orchestrates the creation of the 4 windows.
// --------------------------------------------------------------------------------

@implementation AppController : CPObject
{
    CPArray windows;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    windows = [];

    var winWidth = 400.0,
        winHeight = 420.0,
        padding = 20.0;

    // 1. Top Left: Normal, Enabled
    var wc1 = [[KitchenSinkWindowController alloc] initWithContentRect:CGRectMake(50, 50, winWidth, winHeight)
                                                                 isHUD:NO 
                                                               enabled:YES];
    [wc1 showWindow:self];
    [windows addObject:wc1];

    // 2. Top Right: Normal, Disabled
    var wc2 = [[KitchenSinkWindowController alloc] initWithContentRect:CGRectMake(50 + winWidth + padding, 50, winWidth, winHeight)
                                                                 isHUD:NO 
                                                               enabled:NO];
    [wc2 showWindow:self];
    [windows addObject:wc2];

    // 3. Bottom Left: HUD, Enabled
    var wc3 = [[KitchenSinkWindowController alloc] initWithContentRect:CGRectMake(50, 50 + winHeight + padding + 30, winWidth, winHeight)
                                                                 isHUD:YES 
                                                               enabled:YES];
    [wc3 showWindow:self];
    [windows addObject:wc3];

    // 4. Bottom Right: HUD, Disabled
    var wc4 = [[KitchenSinkWindowController alloc] initWithContentRect:CGRectMake(50 + winWidth + padding, 50 + winHeight + padding + 30, winWidth, winHeight)
                                                                 isHUD:YES 
                                                               enabled:NO];
    [wc4 showWindow:self];
    [windows addObject:wc4];

}

@end
