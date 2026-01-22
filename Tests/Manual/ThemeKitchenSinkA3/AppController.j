/*
 * AppController.j
 * KitchenSink in Code
 *
 * Created by Daniel Böhringer 2026.
 * Modified for TabView, SplitView, Control Sizes, Grouped Boxes, Rules & Menus.
 * Update: Added Edit and Format Menus (Cut/Copy/Paste/Font Panel).
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

// --------------------------------------------------------------------------------
// KitchenSinkWindowController
// --------------------------------------------------------------------------------

@implementation KitchenSinkWindowController : CPWindowController
{
    BOOL                _isHUD;
    BOOL                _areControlsEnabled;
    CPArrayController   _arrayController;
    
    // Rule Editor References
    CPRuleEditor        _ruleEditor;
    RuleDelegate        _ruleDelegate;
    CPTextField         _predicateField;
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

        [self _buildInterfaceIsHUD:isHUD];

        if (!isEnabled)
            [self _disableControlsInView:[theWindow contentView]];
    }

    return self;
}

- (void)_buildInterfaceIsHUD:(BOOL)isHUD
{
    var window = [self window],
        contentView = [window contentView],
        bounds = [contentView bounds];

    var tabView = [[CPTabView alloc] initWithFrame:bounds];
    [tabView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    // --- TAB 1: Controls (Grouped in Boxes) ---
    var item1 = [[CPTabViewItem alloc] initWithIdentifier:@"Controls"];
    [item1 setLabel:@"Controls"];
    
    var controlsView = [[CPView alloc] initWithFrame:[tabView bounds]];
    [self _buildControlsTab:controlsView isHUD:isHUD];
    [item1 setView:controlsView];
    [tabView addTabViewItem:item1];

    // --- TAB 2: Table & Text Split (Rules & Editable Text) ---
    var item2 = [[CPTabViewItem alloc] initWithIdentifier:@"Table"];
    [item2 setLabel:@"Data & Rules"];

    var tableViewWrapper = [[CPView alloc] initWithFrame:[tabView bounds]];
    [self _buildTableTab:tableViewWrapper isHUD:isHUD];
    [item2 setView:tableViewWrapper];
    [tabView addTabViewItem:item2];

    // --- TAB 3: Control Sizes ---
    var item3 = [[CPTabViewItem alloc] initWithIdentifier:@"Sizes"];
    [item3 setLabel:@"Sizes"];

    var sizesView = [[CPView alloc] initWithFrame:[tabView bounds]];
    [self _buildSizesTab:sizesView isHUD:isHUD];
    [item3 setView:sizesView];
    [tabView addTabViewItem:item3];

    [contentView addSubview:tabView];
}

- (void)_buildControlsTab:(CPView)containerView isHUD:(BOOL)isHUD
{
    // Layout Constants
    var boxMargin = 15.0,
        boxWidth = 190.0,
        innerX = 15.0,     
        startY = 10.0,     
        gapY = 35.0,
        controlWidth = 150.0;

    // ------------------------------------------------------
    // LEFT BOX: Standard Controls
    // ------------------------------------------------------
    var leftBox = [[CPBox alloc] initWithFrame:CGRectMake(boxMargin, 15.0, boxWidth, 100)];
    [leftBox setTitle:@"Standard Controls"];
    [leftBox setAutoresizingMask:CPViewMaxXMargin | CPViewMinYMargin];
    [containerView addSubview:leftBox];
    
    var leftContent = [leftBox contentView];
    var currentY = startY;

    // 1. Push Button
    var pushButton = [[CPButton alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, 24)];
    [pushButton setTitle:@"Push Button"];
    [pushButton setBezelStyle:CPRoundedBezelStyle];
    [leftContent addSubview:pushButton];
    currentY += gapY;

    // 2. Gradient Button
    var gradientButton = [[CPButton alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, 24)];
    [gradientButton setTitle:@"Gradient Button"];
    [gradientButton setBezelStyle:CPSmallSquareBezelStyle];
    [leftContent addSubview:gradientButton];
    currentY += gapY;

    // 3. Round Rect Button
    var roundRectButton = [[CPButton alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, 24)];
    [roundRectButton setTitle:@"Round Rect Button"];
    [roundRectButton setBezelStyle:CPRoundRectBezelStyle];
    [leftContent addSubview:roundRectButton];
    currentY += gapY;

    // 4. Placeholder
    var placeholderField = [[CPTextField alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, 24)];
    [placeholderField setEditable:YES];
    [placeholderField setBezeled:YES];
    [placeholderField setPlaceholderString:@"Placeholder"];
    [leftContent addSubview:placeholderField];
    currentY += gapY;

    // 5. Text Field
    var textField = [[CPTextField alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, 25)];
    [textField setEditable:YES];
    [textField setBezeled:YES];
    [textField setStringValue:@"Text Field"];
    [leftContent addSubview:textField];
    currentY += gapY;

    // 6. Search Field
    var searchField = [[CPSearchField alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, 25)];
    [searchField setPlaceholderString:@"Search..."];
    [leftContent addSubview:searchField];
    currentY += gapY;

    // 7. Token Field
    var tokenField = [[CPTokenField alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, 25)];
    [tokenField setObjectValue:["Token", "Field"]];
    [leftContent addSubview:tokenField];
    currentY += gapY;

    // 8. Combo Box
    var comboBox = [[CPComboBox alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, 25)];
    [comboBox setPlaceholderString:@"Combo Box"];
    [comboBox addItemsWithObjectValues:["Alpha", "Beta", "Gamma"]];
    [leftContent addSubview:comboBox];
    currentY += gapY;

    // 9. Pull Down Menu
    var pullDown = [[CPPopUpButton alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, 25) pullsDown:YES];
    [pullDown addItemWithTitle:@"Pull Down Menu"]; 
    [pullDown addItemWithTitle:@"Action A"];
    [pullDown addItemWithTitle:@"Action B"];
    [pullDown addItemWithTitle:@"Action C"];
    [leftContent addSubview:pullDown];
    currentY += gapY;

    // 10. Standard PopUp Button
    var popUp = [[CPPopUpButton alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, 24) pullsDown:NO];
    [popUp addItemWithTitle:@"PopUp Item 1"];
    [popUp addItemWithTitle:@"PopUp Item 2"];
    [leftContent addSubview:popUp];
    currentY += gapY;

    // Resize Left Box to fit
    [leftBox setFrameSize:CGSizeMake(boxWidth, currentY + 15.0)];


    // ------------------------------------------------------
    // RIGHT BOX: Advanced Controls
    // ------------------------------------------------------
    var rightBoxX = boxMargin + boxWidth + 15.0;
    var rightBoxWidth = 205.0; 
    
    var rightBox = [[CPBox alloc] initWithFrame:CGRectMake(rightBoxX, 15.0, rightBoxWidth, 100)];
    [rightBox setTitle:@"Advanced Controls"];
    [rightBox setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
    [containerView addSubview:rightBox];

    var rightContent = [rightBox contentView];
    currentY = startY; // Reset Y

    // 1. Date Picker
    var datePicker = [[CPDatePicker alloc] initWithFrame:CGRectMake(innerX, currentY, 175, 28)];
    [datePicker setDatePickerStyle:CPTextFieldAndStepperDatePickerStyle];
    [datePicker setDateValue:[CPDate date]];
    [rightContent addSubview:datePicker];
    currentY += gapY;

    // 2. Checkboxes
    var cbOn = [CPCheckBox checkBoxWithTitle:@"On"];
    [cbOn setFrameOrigin:CGPointMake(innerX, currentY)];
    [cbOn setState:CPOnState];
    [rightContent addSubview:cbOn];

    var cbOff = [CPCheckBox checkBoxWithTitle:@"Off"];
    [cbOff setFrameOrigin:CGPointMake(innerX + 50, currentY)];
    [cbOff setState:CPOffState];
    [rightContent addSubview:cbOff];

    var cbBoth = [CPCheckBox checkBoxWithTitle:@"Mixed"];
    [cbBoth setFrameOrigin:CGPointMake(innerX + 100, currentY)];
    [cbBoth setState:CPMixedState];
    [rightContent addSubview:cbBoth];
    currentY += gapY;

    // 3. Spinners
    var spinner = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(innerX + 50, currentY - 4, 32, 32)];
    [spinner setStyle:CPProgressIndicatorSpinningStyle];
    [spinner setIndeterminate:YES];
    [spinner setControlSize:CPRegularControlSize];
    [spinner startAnimation:self];
    [rightContent addSubview:spinner];

    var circProg = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(innerX + 90, currentY - 4, 32, 32)];
    [circProg setStyle:CPProgressIndicatorSpinningStyle];
    [circProg setIndeterminate:NO];
    [circProg setControlSize:CPRegularControlSize];
    [circProg setDoubleValue:65.0];
    [circProg setMaxValue:100.0];
    [rightContent addSubview:circProg];

    currentY += gapY;

    // 4. Stepper & Progress Bar
    var stepper = [[CPStepper alloc] initWithFrame:CGRectMake(innerX, currentY + 3, 19, 27)];
    [stepper setValueWraps:NO];
    [stepper setAutorepeat:YES];
    [stepper setMinValue:0];
    [stepper setMaxValue:100];
    [stepper setDoubleValue:65];
    [rightContent addSubview:stepper];
    
    [circProg bind:CPValueBinding toObject:stepper withKeyPath:@"doubleValue" options:nil];

    var detProgress = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(innerX + 25, currentY + 5.5, 125, 16)];
    [detProgress setStyle:CPProgressIndicatorBarStyle];
    [detProgress setIndeterminate:NO];
    [detProgress setMinValue:0];
    [detProgress setMaxValue:100];
    [detProgress bind:CPValueBinding toObject:stepper withKeyPath:@"doubleValue" options:nil];
    [rightContent addSubview:detProgress];
    currentY += gapY;

    // 5. Radio Buttons
    var radio1 = [CPRadio radioWithTitle:@"Radio A"];
    [radio1 setFrameOrigin:CGPointMake(innerX, currentY)];
    [radio1 setState:CPOnState];
    [rightContent addSubview:radio1];

    var radio2 = [CPRadio radioWithTitle:@"Radio B"];
    [radio2 setFrameOrigin:CGPointMake(innerX, currentY + 22)];
    [rightContent addSubview:radio2];
    [radio1 setTarget:self]; [radio1 setAction:@selector(dummyAction:)];
    [radio2 setTarget:self]; [radio2 setAction:@selector(dummyAction:)];
    currentY += gapY * 1.5;

    // 6. Level Indicator
    var levelInd = [[CPLevelIndicator alloc] initWithFrame:CGRectMake(innerX, currentY, 130, 18)];
    [levelInd setMaxValue:5];
    [levelInd setDoubleValue:3];
    [levelInd setLevelIndicatorStyle:CPDiscreteCapacityLevelIndicatorStyle];
    [rightContent addSubview:levelInd];

    var levelStepper = [[CPStepper alloc] initWithFrame:CGRectMake(innerX + 135, currentY - 2, 19, 24)];
    [levelStepper setMinValue:0];
    [levelStepper setMaxValue:5];
    [levelStepper setDoubleValue:3];
    [levelStepper setValueWraps:NO];
    [rightContent addSubview:levelStepper];
    
    [levelInd bind:CPValueBinding toObject:levelStepper withKeyPath:@"doubleValue" options:nil];
    currentY += gapY;

    // 7. Sliders
    var tickSlider = [[CPSlider alloc] initWithFrame:CGRectMake(innerX, currentY, 110, 24)];
    [rightContent addSubview:tickSlider];

    var vSlider = [[CPSlider alloc] initWithFrame:CGRectMake(innerX + 130, currentY, 24, 70)];
    [rightContent addSubview:vSlider];
    currentY += gapY;

    // 8. Knob & Indeterminate Bar
    var knob = [[CPSlider alloc] initWithFrame:CGRectMake(innerX, currentY, 32, 32)];
    [knob setSliderType:CPCircularSlider];
    [rightContent addSubview:knob];

    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(innerX + 40, currentY + 8, 80, 16)];
    [progressBar setStyle:CPProgressIndicatorBarStyle];
    [progressBar setIndeterminate:YES];
    [progressBar startAnimation:self];
    [rightContent addSubview:progressBar];
    
    currentY += gapY;

    // Resize Right Box to fit
    [rightBox setFrameSize:CGSizeMake(rightBoxWidth, currentY + 15.0)];
}

- (void)_buildTableTab:(CPView)containerView isHUD:(BOOL)isHUD
{
    var bounds = [containerView bounds];
    var bottomBarHeight = 32.0;
    var ruleEditorHeight = 140.0;
    
    // --- RULE EDITOR SECTION (Top) ---
    var ruleContainer = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), ruleEditorHeight)];
    [ruleContainer setAutohidesScrollers:YES];
    [ruleContainer setBorderType:CPBezelBorder];
    
    _ruleEditor = [[CPRuleEditor alloc] initWithFrame:CGRectMake(0,0, CGRectGetWidth(bounds), ruleEditorHeight)];
    [_ruleEditor setRowHeight:25.0];
    [_ruleEditor setFormattingStringsFilename:@"Rules"]; 
    [_ruleEditor setCanRemoveAllRows:YES];
    
    _ruleDelegate = [[RuleDelegate alloc] init];
    [_ruleEditor setDelegate:_ruleDelegate];
    [_ruleEditor addRow:self];
    
    [ruleContainer setDocumentView:_ruleEditor];
    [containerView addSubview:ruleContainer];
    
    _predicateField = [[CPTextField alloc] initWithFrame:CGRectMake(10, ruleEditorHeight + 5, CGRectGetWidth(bounds) - 20, 20)];
    [_predicateField setEditable:NO];
    [_predicateField setFont:[CPFont systemFontOfSize:11.0]];
    [_predicateField setTextColor:[CPColor grayColor]];
    [_predicateField setStringValue:@"(Predicate will appear here)"];
    [containerView addSubview:_predicateField];
    
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(ruleEditorRowsDidChange:) name:CPRuleEditorRowsDidChangeNotification object:_ruleEditor];


    // --- SPLIT VIEW SECTION (Bottom) ---
    var splitY = ruleEditorHeight + 30.0;
    var splitHeight = CGRectGetHeight(bounds) - splitY - bottomBarHeight;
    
    var splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0, splitY, CGRectGetWidth(bounds), splitHeight)];
    [splitView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [splitView setVertical:NO]; 
    
    // Top Pane: Table
    var tableScroll = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), splitHeight / 2.0)];
    [tableScroll setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [tableScroll setAutohidesScrollers:YES];

    var tableView = [[CPTableView alloc] initWithFrame:[tableScroll bounds]];
    [tableView setUsesAlternatingRowBackgroundColors:YES];
    [tableView setCornerView:nil];
    
    [tableView bind:CPSelectionIndexesBinding toObject:_arrayController withKeyPath:@"selectionIndexes" options:nil];
    [tableView bind:@"sortDescriptors" toObject:_arrayController withKeyPath:@"sortDescriptors" options:nil];

    // Column 1: Animal
    var colAnimal = [[CPTableColumn alloc] initWithIdentifier:@"animal"];
    [[colAnimal headerView] setStringValue:@"Animal"];
    [colAnimal setWidth:150];
    [colAnimal setEditable:YES];
    
    var animalCell = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    [animalCell setEditable:YES];
    [colAnimal setDataView:animalCell];
    [tableView addTableColumn:colAnimal];
    [colAnimal bind:CPValueBinding toObject:_arrayController withKeyPath:@"arrangedObjects.animal" options:nil];

    // Column 2: Legs
    var colLegs = [[CPTableColumn alloc] initWithIdentifier:@"legs"];
    [[colLegs headerView] setStringValue:@"Legs"];
    [colLegs setWidth:100];
    [colLegs setEditable:YES];
    
    var legsCell = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    [legsCell setEditable:YES];
    [colLegs setDataView:legsCell];
    [tableView addTableColumn:colLegs];
    [colLegs bind:CPValueBinding toObject:_arrayController withKeyPath:@"arrangedObjects.legs" options:nil];

    [tableScroll setDocumentView:tableView];
    
    // Bottom Pane: Text (Updated for Menu support)
    var textScroll = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), splitHeight / 2.0)];
    [textScroll setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [textScroll setAutohidesScrollers:YES];
    
    var textView = [[CPTextView alloc] initWithFrame:[textScroll bounds]];
    [textView setEditable:YES];
    // --- ENABLE RICH TEXT TO SUPPORT FONTS/UNDERLINE ---
    [textView setRichText:YES]; 
    [textView setString:@"Select text here and use the 'Format' or 'Edit' menus.\n\n(This is a Rich Text enabled CPTextView)"];
    [textView setFont:[CPFont fontWithName:@"Courier" size:13.0]];

    if (isHUD)
    {
        [textView setBackgroundColor:[CPColor blackColor]];
        [textView setTextColor:[CPColor whiteColor]];
    }
    [textScroll setDocumentView:textView];
    
    [splitView addSubview:tableScroll];
    [splitView addSubview:textScroll];

    if (isHUD)
    {
        [splitView setThemeState:CPThemeStateHUD];
        [tableScroll setThemeState:CPThemeStateHUD];
        [textScroll setThemeState:CPThemeStateHUD];
        [tableView setThemeState:CPThemeStateHUD];
        [ruleContainer setThemeState:CPThemeStateHUD];
    }

    [containerView addSubview:splitView];

    // Button Bar
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

- (void)ruleEditorRowsDidChange:(CPNotification)note
{
    var predicate = [_ruleEditor predicate];
    if (predicate)
        [_predicateField setStringValue:[predicate predicateFormat]];
    else
        [_predicateField setStringValue:@"(Incomplete Predicate)"];
}

// --- SIZES TAB BUILDER ---
- (void)_buildSizesTab:(CPView)containerView isHUD:(BOOL)isHUD
{
    [self _addSizeColumnTo:containerView atX:20.0 controlSize:CPRegularControlSize title:@"Regular size"];
    [self _addSizeColumnTo:containerView atX:160.0 controlSize:CPSmallControlSize title:@"Small size"];
    [self _addSizeColumnTo:containerView atX:280.0 controlSize:CPMiniControlSize title:@"Mini size"];
}

- (void)_addSizeColumnTo:(CPView)parentView atX:(float)xPos controlSize:(CPControlSize)aSize title:(CPString)title
{
    var y = 20.0;
    var rowHeight = 40.0;
    var width = (aSize == CPRegularControlSize) ? 100.0 : ((aSize == CPSmallControlSize) ? 90.0 : 80.0);
    
    // 1. Title Label
    var label = [CPTextField labelWithTitle:title];
    [label setFrameOrigin:CGPointMake(xPos, y)];
    [label setFont:[CPFont systemFontOfSize:13.0]];
    [parentView addSubview:label];
    y += 35.0;

    // 2. PopUp Button
    var popUp = [[CPPopUpButton alloc] initWithFrame:CGRectMake(xPos, y, width, 24)];
    [popUp addItemWithTitle:@"Item 1"];
    [popUp addItemWithTitle:@"Item 2"];
    [popUp setControlSize:aSize];
    [parentView addSubview:popUp];
    y += rowHeight;

    // 3. Text Field
    var tf = [[CPTextField alloc] initWithFrame:CGRectMake(xPos, y, width, 24)];
    [tf setStringValue:@"Input"];
    [tf setBezeled:YES];
    [tf setEditable:YES];
    [tf setControlSize:aSize];
    [parentView addSubview:tf];
    y += rowHeight;

    // 4. Stepper
    var stepper = [[CPStepper alloc] initWithFrame:CGRectMake(xPos, y, 13, 23)];
    [stepper setControlSize:aSize];
    [parentView addSubview:stepper];
    y += rowHeight;

    // 5. Date Picker
    var dpWidth = width + (aSize == CPRegularControlSize ? 20 : 15);
    var dp = [[CPDatePicker alloc] initWithFrame:CGRectMake(xPos, y, dpWidth, 28)];
    [dp setControlSize:aSize];
    [dp setDatePickerStyle:CPTextFieldAndStepperDatePickerStyle];
    [dp setDatePickerElements:CPYearMonthDayDatePickerElementFlag];
    [dp setDateValue:[CPDate date]];
    [parentView addSubview:dp];
    y += rowHeight;

    // 6. Checkbox
    var cb = [CPCheckBox checkBoxWithTitle:@"Check"];
    [cb setFrameOrigin:CGPointMake(xPos, y)];
    [cb setControlSize:aSize];
    [cb sizeToFit];
    [parentView addSubview:cb];
    y += rowHeight;

    // 7. Standard Button
    var btn = [[CPButton alloc] initWithFrame:CGRectMake(xPos, y, width, 24)];
    [btn setTitle:@"Button"];
    [btn setControlSize:aSize];
    [parentView addSubview:btn];
    y += rowHeight;

    // 8. Textured Button
    var texBtn = [[CPButton alloc] initWithFrame:CGRectMake(xPos, y, width, 24)];
    [texBtn setTitle:@"Textured"];
    [texBtn setBezelStyle:CPTexturedSquareBezelStyle];
    [texBtn setControlSize:aSize];
    [parentView addSubview:texBtn];
    y += rowHeight;

    // 9. Round Textured Button
    var roundTexBtn = [[CPButton alloc] initWithFrame:CGRectMake(xPos, y, width, 24)];
    [roundTexBtn setTitle:@"Round"];
    [roundTexBtn setBezelStyle:CPTexturedRoundedBezelStyle];
    [roundTexBtn setControlSize:aSize];
    [parentView addSubview:roundTexBtn];
    y += rowHeight;

    // 10. Radio Buttons
    var rad1 = [CPRadio radioWithTitle:@"Radio"];
    [rad1 setFrameOrigin:CGPointMake(xPos, y)];
    [rad1 setControlSize:aSize];
    [rad1 setState:CPOnState];
    [rad1 sizeToFit];
    [parentView addSubview:rad1];
    y += 24.0;
    
    var rad2 = [CPRadio radioWithTitle:@"Radio"];
    [rad2 setFrameOrigin:CGPointMake(xPos, y)];
    [rad2 setControlSize:aSize];
    [rad2 sizeToFit];
    [parentView addSubview:rad2];
    y += rowHeight;
    
    // 11. Small Bottom PopUp
    var popUp2 = [[CPPopUpButton alloc] initWithFrame:CGRectMake(xPos, y, width, 24)];
    [popUp2 setPullsDown:YES];
    [popUp2 setControlSize:aSize];
    [parentView addSubview:popUp2];
}

- (void)_disableControlsInView:(id)aView
{
    var subviews = [aView subviews],
        count = [subviews count];

    for (var i = 0; i < count; i++)
    {
        var view = subviews[i];
        if ([view respondsToSelector:@selector(setEnabled:)])
            [view setEnabled:NO];
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
        [item setTarget:CPApp];
        [item setAction:@selector(orderFrontColorPanel:)];
    }
    return item;
}

@end


// --------------------------------------------------------------------------------
// RuleDelegate
// --------------------------------------------------------------------------------

@implementation RuleDelegate : CPObject
{
}

- (int)ruleEditor:(CPRuleEditor)editor numberOfChildrenForCriterion:(id)criterion withRowType:(CPRuleEditorRowType)rowType
{
    if (criterion == nil) return 2;
    if (criterion == @"animal") return 2;
    if (criterion == @"legs") return 3;
    return 0;
}

- (id)ruleEditor:(CPRuleEditor)editor child:(int)index forCriterion:(id)criterion withRowType:(CPRuleEditorRowType)rowType
{
    if (criterion == nil) {
        if (index == 0) return @"animal";
        return @"legs";
    }
    if (criterion == @"animal") {
        if (index == 0) return @"contains";
        return @"is";
    }
    if (criterion == @"legs") {
        if (index == 0) return @">";
        if (index == 1) return @"<";
        return @"==";
    }
    return nil;
}

- (id)ruleEditor:(CPRuleEditor)editor displayValueForCriterion:(id)criterion inRow:(int)row
{
    if (criterion == @"animal") return @"Animal Name";
    if (criterion == @"legs") return @"Leg Count";
    if (criterion == @"contains") return @"contains";
    if (criterion == @"is") return @"is";
    if (criterion == @">") return @"is greater than";
    if (criterion == @"<") return @"is less than";
    if (criterion == @"==") return @"is equal to";
    return criterion;
}

@end


// --------------------------------------------------------------------------------
// AppController
// --------------------------------------------------------------------------------

@implementation AppController : CPObject
{
    CPArray windows;
}

- (void)orderFrontFontPanel:(id)sender
{
   [[CPFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    windows = [];

    var winWidth = 430.0,
        winHeight = 550.0,
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

    // --- BUILD MENU FROM EXAMPLE ---
    var mainMenu = [CPApp mainMenu];

    while ([mainMenu numberOfItems] > 0)
       [mainMenu removeItemAtIndex:0];

    // Edit Menu
    var item = [mainMenu insertItemWithTitle:@"Edit" action:nil keyEquivalent:nil atIndex:0],
        editMenu = [[CPMenu alloc] initWithTitle:@"Edit Menu"];

    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Delete" action:@selector(delete:) keyEquivalent:@""];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    [editMenu addItemWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@"Z"];

    [mainMenu setSubmenu:editMenu forItem:item];

    // Format Menu
    item = [mainMenu insertItemWithTitle:@"Format" action:nil keyEquivalent:nil atIndex:0];
    var formatMenu = [[CPMenu alloc] initWithTitle:@"Format Menu"];
    [formatMenu addItemWithTitle:@"Font panel" action:@selector(orderFrontFontPanel:) keyEquivalent:@"f"];
    [formatMenu addItemWithTitle:@"Underline" action:@selector(underline:) keyEquivalent:@"u"];
    [mainMenu setSubmenu:formatMenu forItem:item];

    [CPMenu setMenuBarVisible:YES];
}

@end
