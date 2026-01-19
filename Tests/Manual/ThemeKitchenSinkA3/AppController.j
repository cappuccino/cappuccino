/*
 * AppController.j
 * KitchenSink in Code
 *
 * Created by Daniel Böhringer 2026.
 * Modified for TabView and SplitView (Table + Text) support.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

// --------------------------------------------------------------------------------
// KitchenSinkWindowController
// Manages a single window instance with Tabs: Controls & Table/Text Split
// --------------------------------------------------------------------------------

@implementation KitchenSinkWindowController : CPWindowController
{
    BOOL                _isHUD;
    BOOL                _areControlsEnabled;
    CPArrayController   _arrayController;
}

- (id)initWithContentRect:(CGRect)aRect isHUD:(BOOL)isHUD enabled:(BOOL)isEnabled
{
    var styleMask = CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask;
    
    if (isHUD)
        styleMask |= CPHUDBackgroundWindowMask;

    var theWindow = [[CPWindow alloc] initWithContentRect:aRect styleMask:styleMask];
    
    self = [super initWithWindow:theWindow];
    
    if (self)
    {
        _isHUD = isHUD;
        _areControlsEnabled = isEnabled;

        var title = (isHUD ? @"HUD Theme" : @"Aristo3 Theme") + (isEnabled ? @" (Enabled)" : @" (Disabled)");
        [theWindow setTitle:title];

        var toolbar = [[CPToolbar alloc] initWithIdentifier:@"KitchenSinkToolbar" + (isHUD ? @"HUD" : @"Aqua")];
        [toolbar setDelegate:self];
        [toolbar setVisible:YES];
        [theWindow setToolbar:toolbar];

        _arrayController = [[CPArrayController alloc] init];
        
        var contentData = [
            [CPDictionary dictionaryWithObjectsAndKeys:@"Cat", @"animal", 4, @"legs"],
            [CPDictionary dictionaryWithObjectsAndKeys:@"Duck", @"animal", 2, @"legs"],
            [CPDictionary dictionaryWithObjectsAndKeys:@"Centipede", @"animal", 100, @"legs"],
            [CPDictionary dictionaryWithObjectsAndKeys:@"Spider", @"animal", 8, @"legs"],
            [CPDictionary dictionaryWithObjectsAndKeys:@"Snake", @"animal", 0, @"legs"]
        ];
        
        [_arrayController setContent:contentData];
        [_arrayController setEditable:YES];

        [self _buildInterface];

        if (!isEnabled)
            [self _disableControlsInView:[theWindow contentView]];
    }

    return self;
}

- (void)_buildInterface
{
    var window = [self window],
        contentView = [window contentView],
        bounds = [contentView bounds];

    var tabView = [[CPTabView alloc] initWithFrame:bounds];
    [tabView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    // --- TAB 1: Controls ---
    var item1 = [[CPTabViewItem alloc] initWithIdentifier:@"Controls"];
    [item1 setLabel:@"Controls"];
    
    var controlsView = [[CPView alloc] initWithFrame:[tabView bounds]];
    [self _buildControlsTab:controlsView];
    [item1 setView:controlsView];
    [tabView addTabViewItem:item1];

    // --- TAB 2: Table & Text Split ---
    var item2 = [[CPTabViewItem alloc] initWithIdentifier:@"Table"];
    [item2 setLabel:@"Data Split"]; // Renamed slightly to reflect content

    var tableViewWrapper = [[CPView alloc] initWithFrame:[tabView bounds]];
    [self _buildTableTab:tableViewWrapper];
    [item2 setView:tableViewWrapper];
    [tabView addTabViewItem:item2];

    [contentView addSubview:tabView];
}

- (void)_buildControlsTab:(CPView)containerView
{
    var col1X = 20.0,
        col2X = 200.0,
        startY = 20.0,
        gapY = 35.0,
        width = 150.0;

    // --- COLUMN 1 ---
    var pushButton = [[CPButton alloc] initWithFrame:CGRectMake(col1X, startY, width, 24)];
    [pushButton setTitle:@"Push Button"];
    [containerView addSubview:pushButton];

    var gradientButton = [[CPButton alloc] initWithFrame:CGRectMake(col1X, startY + gapY, width, 24)];
    [gradientButton setTitle:@"Gradient Button"];
    [containerView addSubview:gradientButton];

    var roundRectButton = [[CPButton alloc] initWithFrame:CGRectMake(col1X, startY + (gapY * 2), width, 24)];
    [roundRectButton setTitle:@"Round Rect Button"];
    [roundRectButton setBezelStyle:CPRoundedBezelStyle];
    [containerView addSubview:roundRectButton];

    var placeholderField = [[CPTextField alloc] initWithFrame:CGRectMake(col1X, startY + (gapY * 3), width, 24)];
    [placeholderField setEditable:YES];
    [placeholderField setBezeled:YES];
    [placeholderField setPlaceholderString:@"Placeholder"];
    [containerView addSubview:placeholderField];

    var textField = [[CPTextField alloc] initWithFrame:CGRectMake(col1X, startY + (gapY * 4), width, 25)];
    [textField setEditable:YES];
    [textField setBezeled:YES];
    [textField setStringValue:@"Text Field"];
    [containerView addSubview:textField];

    var searchField = [[CPSearchField alloc] initWithFrame:CGRectMake(col1X, startY + (gapY * 5), width, 25)];
    [searchField setPlaceholderString:@"Search..."];
    [containerView addSubview:searchField];

    var tokenField = [[CPTokenField alloc] initWithFrame:CGRectMake(col1X, startY + (gapY * 6), width, 25)];
    [tokenField setObjectValue:["Token", "Field"]];
    [containerView addSubview:tokenField];

    var comboBox = [[CPComboBox alloc] initWithFrame:CGRectMake(col1X, startY + (gapY * 7), width, 25)];
    [comboBox setPlaceholderString:@"Combo Box"];
    [comboBox addItemsWithObjectValues:["Alpha", "Beta", "Gamma"]];
    [containerView addSubview:comboBox];

    var bottomSlider = [[CPSlider alloc] initWithFrame:CGRectMake(col1X, startY + (gapY * 8.5), width, 25)];
    [containerView addSubview:bottomSlider];

    // --- COLUMN 2 ---
    var datePicker = [[CPDatePicker alloc] initWithFrame:CGRectMake(col2X, startY, 175, 28)];
    [datePicker setDatePickerStyle:CPTextFieldAndStepperDatePickerStyle];
    [datePicker setDateValue:[CPDate date]];
    [containerView addSubview:datePicker];

    var cbY = startY + gapY;
    var cbOn = [CPCheckBox checkBoxWithTitle:@"On"];
    [cbOn setFrameOrigin:CGPointMake(col2X, cbY)];
    [cbOn setState:CPOnState];
    [containerView addSubview:cbOn];

    var cbOff = [CPCheckBox checkBoxWithTitle:@"Off"];
    [cbOff setFrameOrigin:CGPointMake(col2X + 50, cbY)];
    [cbOff setState:CPOffState];
    [containerView addSubview:cbOff];

    var cbBoth = [CPCheckBox checkBoxWithTitle:@"Mixed"];
    [cbBoth setFrameOrigin:CGPointMake(col2X + 100, cbY)];
    [cbBoth setState:CPMixedState];
    [containerView addSubview:cbBoth];

    var popUp = [[CPPopUpButton alloc] initWithFrame:CGRectMake(col2X, startY + (gapY * 2), 150, 24) pullsDown:NO];
    [popUp addItemWithTitle:@"Item 1"];
    [popUp addItemWithTitle:@"Item 2"];
    [containerView addSubview:popUp];

    // Stepper & Progress Bar
    var swapY = startY + (gapY * 3);
    var stepper = [[CPStepper alloc] initWithFrame:CGRectMake(col2X, swapY + 3, 19, 27)];
    [stepper setValueWraps:NO];
    [stepper setAutorepeat:YES];
    [stepper setMinValue:0];
    [stepper setMaxValue:100];
    [stepper setDoubleValue:33];
    [containerView addSubview:stepper];
    
    var detProgress = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(col2X + 25, swapY + 5.5, 125, 16)];
    [detProgress setStyle:CPProgressIndicatorBarStyle];
    [detProgress setIndeterminate:NO];
    [detProgress setMinValue:0];
    [detProgress setMaxValue:100];
    [detProgress bind:CPValueBinding toObject:stepper withKeyPath:@"doubleValue" options:nil];
    [containerView addSubview:detProgress];

    var radioY = startY + (gapY * 4);
    var radio1 = [CPRadio radioWithTitle:@"Radio A"];
    [radio1 setFrameOrigin:CGPointMake(col2X, radioY)];
    [radio1 setState:CPOnState];
    [containerView addSubview:radio1];

    var radio2 = [CPRadio radioWithTitle:@"Radio B"];
    [radio2 setFrameOrigin:CGPointMake(col2X, radioY + 22)];
    [containerView addSubview:radio2];
    [radio1 setTarget:self]; [radio1 setAction:@selector(dummyAction:)];
    [radio2 setTarget:self]; [radio2 setAction:@selector(dummyAction:)];

    var levelInd = [[CPLevelIndicator alloc] initWithFrame:CGRectMake(col2X, startY + (gapY * 5.5), 150, 18)];
    [levelInd setMaxValue:5];
    [levelInd setDoubleValue:3];
    [levelInd setLevelIndicatorStyle:CPDiscreteCapacityLevelIndicatorStyle];
    [containerView addSubview:levelInd];

    var tickSlider = [[CPSlider alloc] initWithFrame:CGRectMake(col2X, startY + (gapY * 6.5), 110, 24)];
    [containerView addSubview:tickSlider];

    var vSlider = [[CPSlider alloc] initWithFrame:CGRectMake(col2X + 130, startY + (gapY * 6.5), 24, 70)];
    [containerView addSubview:vSlider];
    
    var knob = [[CPSlider alloc] initWithFrame:CGRectMake(col2X, startY + (gapY * 7.5), 32, 32)];
    [knob setSliderType:CPCircularSlider];
    [containerView addSubview:knob];

    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(col2X + 40, startY + (gapY * 7.5) + 8, 80, 16)];
    [progressBar setStyle:CPProgressIndicatorBarStyle];
    [progressBar setIndeterminate:YES];
    [progressBar startAnimation:self];
    [containerView addSubview:progressBar];
}

- (void)_buildTableTab:(CPView)containerView
{
    var bounds = [containerView bounds];
    var bottomBarHeight = 32.0;

    // 1. Calculate Frame for Split View (Everything above the button bar)
    var splitFrame = CGRectMake(0, 0, CGRectGetWidth(bounds), CGRectGetHeight(bounds) - bottomBarHeight);
    
    // 2. Create the Split View
    var splitView = [[CPSplitView alloc] initWithFrame:splitFrame];
    [splitView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [splitView setVertical:NO]; // NO = Horizontal Dividers = Vertical Stacking
    
    // --- TOP PANE: Table View ---
    
    var tableScroll = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), CGRectGetHeight(splitFrame) / 2.0)];
    [tableScroll setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [tableScroll setAutohidesScrollers:YES];

    var tableView = [[CPTableView alloc] initWithFrame:[tableScroll bounds]];
    [tableView setUsesAlternatingRowBackgroundColors:YES];
    [tableView setCornerView:nil];
    
    // Bindings
    [tableView bind:CPSelectionIndexesBinding toObject:_arrayController withKeyPath:@"selectionIndexes" options:nil];
    [tableView bind:@"sortDescriptors" toObject:_arrayController withKeyPath:@"sortDescriptors" options:nil];

    // Col 1: Animal
    var colAnimal = [[CPTableColumn alloc] initWithIdentifier:@"animal"];
    [[colAnimal headerView] setStringValue:@"Animal"];
    [colAnimal setWidth:150];
    var animalCell = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    [animalCell setFont:[CPFont systemFontOfSize:12.0]];
    [colAnimal setDataView:animalCell];
    [tableView addTableColumn:colAnimal];
    [colAnimal bind:CPValueBinding toObject:_arrayController withKeyPath:@"arrangedObjects.animal" options:nil];

    // Col 2: Legs
    var colLegs = [[CPTableColumn alloc] initWithIdentifier:@"legs"];
    [[colLegs headerView] setStringValue:@"Legs"];
    [colLegs setWidth:100];
    var legsCell = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    [legsCell setFont:[CPFont systemFontOfSize:12.0]];
    [colLegs setDataView:legsCell];
    [tableView addTableColumn:colLegs];
    [colLegs bind:CPValueBinding toObject:_arrayController withKeyPath:@"arrangedObjects.legs" options:nil];

    [tableScroll setDocumentView:tableView];
    
    // --- BOTTOM PANE: Text View ---
    
    var textScroll = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), CGRectGetHeight(splitFrame) / 2.0)];
    [textScroll setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [textScroll setAutohidesScrollers:YES];
    
    var textView = [[CPTextView alloc] initWithFrame:[textScroll bounds]];
    [textView setEditable:YES];
    [textView setString:@"Select an item in the table above...\n\n(This is a CPTextView inside a CPScrollView inside a CPSplitView)"];
    [textView setFont:[CPFont fontWithName:@"Courier" size:13.0]];
    
    [textScroll setDocumentView:textView];
    
    // --- ASSEMBLE SPLIT VIEW ---
    // Note: The order of addSubview determines top vs bottom
    [splitView addSubview:tableScroll];
    [splitView addSubview:textScroll];
    
    [containerView addSubview:splitView];

    // 3. Button Bar (Remains at bottom, outside split view)
    var buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(bounds) - bottomBarHeight, CGRectGetWidth(bounds), bottomBarHeight)];
    [buttonBar setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
    
    if ([buttonBar respondsToSelector:@selector(setHasResizeControl:)])
        [buttonBar setHasResizeControl:NO];
    else if ([buttonBar respondsToSelector:@selector(setAutomaticResizeControl:)])
        [buttonBar setAutomaticResizeControl:NO];

    var plusBtn = [CPButtonBar plusButton];
    [plusBtn setTarget:_arrayController];
    [plusBtn setAction:@selector(add:)];
    [plusBtn setEnabled:YES];

    var minusBtn = [CPButtonBar minusButton];
    [minusBtn setTarget:_arrayController];
    [minusBtn setAction:@selector(remove:)];
    [minusBtn bind:CPEnabledBinding toObject:_arrayController withKeyPath:@"canRemove" options:nil];

    [buttonBar setButtons:[plusBtn, minusBtn]];
    [containerView addSubview:buttonBar];
}

- (void)_disableControlsInView:(id)aView
{
    var subviews = [aView subviews],
        count = [subviews count];

    for (var i = 0; i < count; i++)
    {
        var view = subviews[i];
        
        // Skip text views to keep them readable even if window is 'disabled' (optional preference)
        // or disable them too. Here we stick to the requested behavior of disabling controls.
        if ([view respondsToSelector:@selector(setEnabled:)])
            [view setEnabled:NO];
        
        // Specifically for CPTextView which might rely on setEditable for "enabling"
        if ([view isKindOfClass:[CPTextView class]])
            [view setEditable:NO];

        if ([[view subviews] count] > 0)
            [self _disableControlsInView:view];
    }
}

- (void)dummyAction:(id)sender
{
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
        [item setImage:[CPImage imageNamed:CPImageNameColorPanel]];
        [item setAlternateImage:[CPImage imageNamed:CPImageNameColorPanelHighlighted]];
        [item setTarget:self];
        [item setAction:@selector(orderFrontColorPanel:)];
    }
    
    return item;
}

@end


@implementation AppController : CPObject
{
    CPArray windows;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    windows = [];

    var winWidth = 430.0,
        winHeight = 500.0, // Increased height slightly to accommodate the split view better
        padding = 20.0;

    var wc1 = [[KitchenSinkWindowController alloc] initWithContentRect:CGRectMake(50, 50, winWidth, winHeight) isHUD:NO enabled:YES];
    [wc1 showWindow:self];
    [windows addObject:wc1];

    var wc2 = [[KitchenSinkWindowController alloc] initWithContentRect:CGRectMake(50 + winWidth + padding, 50, winWidth, winHeight) isHUD:NO enabled:NO];
    [wc2 showWindow:self];
    [windows addObject:wc2];

    var wc3 = [[KitchenSinkWindowController alloc] initWithContentRect:CGRectMake(50, 50 + winHeight + padding + 30, winWidth, winHeight) isHUD:YES enabled:YES];
    [wc3 showWindow:self];
    [windows addObject:wc3];

    var wc4 = [[KitchenSinkWindowController alloc] initWithContentRect:CGRectMake(50 + winWidth + padding, 50 + winHeight + padding + 30, winWidth, winHeight) isHUD:YES enabled:NO];
    [wc4 showWindow:self];
    [windows addObject:wc4];

    [CPMenu setMenuBarVisible:YES];
}

@end
