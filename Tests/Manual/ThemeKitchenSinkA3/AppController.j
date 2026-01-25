/*
 * AppController.j
 * KitchenSink in Code
 *
 * Created by Daniel Böhringer 2026.
 * Refactored: Fixed RuleEditor action handling.
 * Refactored: Added OutlineView and reordered tabs.
 * Refactored: Fixed control disabling logic for all tabs.
 * Added: CPAlert demonstrations wired to control buttons.
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
    
    // Outline Data
    CPArray             _outlineData;
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

        // --- Table Data Init ---
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

        // --- Outline Data Init ---
        _outlineData = [
            [CPDictionary dictionaryWithObjectsAndKeys:
                @"Filesystem Root", @"name",
                [
                    [CPDictionary dictionaryWithObjectsAndKeys:@"Applications", @"name", [], @"children"],
                    [CPDictionary dictionaryWithObjectsAndKeys:@"Library", @"name", 
                        [
                            [CPDictionary dictionaryWithObjectsAndKeys:@"Fonts", @"name", [], @"children"],
                            [CPDictionary dictionaryWithObjectsAndKeys:@"Frameworks", @"name", [], @"children"]
                        ], @"children"],
                    [CPDictionary dictionaryWithObjectsAndKeys:@"Users", @"name", 
                        [
                            [CPDictionary dictionaryWithObjectsAndKeys:@"Guest", @"name", [], @"children"],
                            [CPDictionary dictionaryWithObjectsAndKeys:@"Admin", @"name", 
                                [
                                    [CPDictionary dictionaryWithObjectsAndKeys:@"Documents", @"name", [], @"children"],
                                    [CPDictionary dictionaryWithObjectsAndKeys:@"Pictures", @"name", [], @"children"]
                                ], @"children"]
                        ], @"children"]
                ], @"children"
            ]
        ];

        [self _buildInterfaceIsHUD:isHUD];
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

    // Requested Order: "Controls", "Sizes", "Data & Rules", "Outline"

    // --- TAB 1: Controls ---
    var item1 = [[CPTabViewItem alloc] initWithIdentifier:@"Controls"];
    [item1 setLabel:@"Controls"];
    
    var controlsView = [[CPView alloc] initWithFrame:[tabView bounds]];
    [self _buildControlsTab:controlsView isHUD:isHUD];
    [item1 setView:controlsView];
    [tabView addTabViewItem:item1];

    // --- TAB 2: Sizes ---
    var item2 = [[CPTabViewItem alloc] initWithIdentifier:@"Sizes"];
    [item2 setLabel:@"Sizes"];

    var sizesView = [[CPView alloc] initWithFrame:[tabView bounds]];
    [self _buildSizesTab:sizesView isHUD:isHUD];
    [item2 setView:sizesView];
    [tabView addTabViewItem:item2];

    // --- TAB 3: Table & Text Split (Rules) ---
    var item3 = [[CPTabViewItem alloc] initWithIdentifier:@"Table"];
    [item3 setLabel:@"Data & Rules"];

    var tableViewWrapper = [[CPView alloc] initWithFrame:[tabView bounds]];
    [self _buildTableTab:tableViewWrapper isHUD:isHUD];
    [item3 setView:tableViewWrapper];
    [tabView addTabViewItem:item3];

    // --- TAB 4: Outline View ---
    var item4 = [[CPTabViewItem alloc] initWithIdentifier:@"Outline"];
    [item4 setLabel:@"Outline"];
    
    var outlineWrapper = [[CPView alloc] initWithFrame:[tabView bounds]];
    [self _buildOutlineTab:outlineWrapper isHUD:isHUD];
    [item4 setView:outlineWrapper];
    [tabView addTabViewItem:item4];

    [contentView addSubview:tabView];

    // If the window is supposed to be disabled, we must disable the controls 
    // in ALL tabs now, while we have references to their views.
    if (!_areControlsEnabled)
    {
        [self _disableControlsInView:controlsView];
        [self _disableControlsInView:sizesView];
        [self _disableControlsInView:tableViewWrapper];
        [self _disableControlsInView:outlineWrapper];
    }
}

- (void)_applyHUDStateToView:(CPView)aView
{
    if ([aView respondsToSelector:@selector(setThemeState:)])
        [aView setThemeState:CPThemeStateHUD];

    var subviews = [aView subviews],
        count = [subviews count];

    for (var i = 0; i < count; i++)
        [self _applyHUDStateToView:subviews[i]];
}

// --------------------------------------------------------------------------------
// Tab Builders
// --------------------------------------------------------------------------------

- (void)_buildControlsTab:(CPView)containerView isHUD:(BOOL)isHUD
{
    // Layout Constants
    var margin = 15.0,
        availableWidth = CGRectGetWidth([containerView bounds]),
        boxWidth = (availableWidth - (margin * 3)) / 2.0, 
        innerX = 15.0,     
        startY = 15.0,     
        gapY = 32.0,   
        controlWidth = boxWidth - (innerX * 2),
        fieldHeight = 25.0,
        boxTopY = 20.0;

    // --- LEFT BOX ---
    var leftBox = [[CPBox alloc] initWithFrame:CGRectMake(margin, boxTopY, boxWidth, 100)];
    [leftBox setTitle:@"Input & Controls"];
    [leftBox setAutoresizingMask:CPViewMaxXMargin | CPViewMinYMargin];
    [containerView addSubview:leftBox];
    
    var leftContent = [leftBox contentView];
    var currentY = startY;

    // Buttons
    var pushButton = [[CPButton alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, fieldHeight)];
    [pushButton setTitle:@"Push Button (Info Alert)"];
    [pushButton setBezelStyle:CPRoundedBezelStyle];
    
    // ACTION: Standard Informational Alert
    [pushButton setTarget:self];
    [pushButton setAction:@selector(showStandardAlert:)];
    
    [leftContent addSubview:pushButton];
    currentY += gapY;

    var gradientButton = [[CPButton alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, fieldHeight)];
    [gradientButton setTitle:@"Gradient (HUD Alert)"];
    [gradientButton setBezelStyle:CPSmallSquareBezelStyle];
    
    // ACTION: Critical / HUD Alert
    [gradientButton setTarget:self];
    [gradientButton setAction:@selector(showHUDAlert:)];
    
    [leftContent addSubview:gradientButton];
    currentY += gapY;

    var roundRectButton = [[CPButton alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, fieldHeight)];
    [roundRectButton setTitle:@"Round (Sheet Alert)"];
    [roundRectButton setBezelStyle:CPRoundRectBezelStyle];
    
    // ACTION: Warning Sheet
    [roundRectButton setTarget:self];
    [roundRectButton setAction:@selector(showSheetAlert:)];
    
    [leftContent addSubview:roundRectButton];
    currentY += gapY + 5.0; 

    // Text Inputs
    var placeholderField = [[CPTextField alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, fieldHeight)];
    [placeholderField setEditable:YES];
    [placeholderField setBezeled:YES];
    [placeholderField setPlaceholderString:@"Placeholder"];
    [leftContent addSubview:placeholderField];
    currentY += gapY;

    var textField = [[CPTextField alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, fieldHeight)];
    [textField setEditable:YES];
    [textField setBezeled:YES];
    [textField setStringValue:@"Text Field"];
    [leftContent addSubview:textField];
    currentY += gapY;

    var searchField = [[CPSearchField alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, fieldHeight)];
    [searchField setPlaceholderString:@"Search..."];
    [leftContent addSubview:searchField];
    currentY += gapY;

    var tokenField = [[CPTokenField alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, fieldHeight)];
    [tokenField setObjectValue:["Token", "Field"]];
    [leftContent addSubview:tokenField];
    currentY += gapY + 20.0;

    // Sliders 
    var tickSlider = [[CPSlider alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth - 40, 24)];
    [leftContent addSubview:tickSlider];

    var vSlider = [[CPSlider alloc] initWithFrame:CGRectMake(innerX + controlWidth - 30, currentY - 5, 24, 60)];
    [leftContent addSubview:vSlider];
    
    var knob = [[CPSlider alloc] initWithFrame:CGRectMake(innerX, currentY + 25, 32, 32)];
    [knob setSliderType:CPCircularSlider];
    [leftContent addSubview:knob];
    
    currentY += 60.0;

    [leftBox setFrameSize:CGSizeMake(boxWidth, currentY + 15.0)];


    // --- RIGHT BOX ---
    var rightBoxX = margin + boxWidth + margin;
    var rightBox = [[CPBox alloc] initWithFrame:CGRectMake(rightBoxX, boxTopY, boxWidth, 100)];
    [rightBox setTitle:@"Selection & Status"];
    [rightBox setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
    [containerView addSubview:rightBox];

    var rightContent = [rightBox contentView];
    currentY = startY; 

    // Date Picker
    var datePicker = [[CPDatePicker alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, fieldHeight)];
    [datePicker setDatePickerStyle:CPTextFieldAndStepperDatePickerStyle];
    [datePicker setDateValue:[CPDate date]];
    [rightContent addSubview:datePicker];
    currentY += gapY;

    // Menus
    var comboBox = [[CPComboBox alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, fieldHeight)];
    [comboBox setPlaceholderString:@"Combo Box"];
    [comboBox addItemsWithObjectValues:["Alpha", "Beta", "Gamma"]];
    [rightContent addSubview:comboBox];
    currentY += gapY;

    var pullDown = [[CPPopUpButton alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, fieldHeight) pullsDown:YES];
    [pullDown addItemWithTitle:@"Pull Down Menu"]; 
    [pullDown addItemWithTitle:@"Action A"]; [pullDown addItemWithTitle:@"Action B"];
    [rightContent addSubview:pullDown];
    currentY += gapY;

    var popUp = [[CPPopUpButton alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, fieldHeight) pullsDown:NO];
    [popUp addItemWithTitle:@"PopUp Item 1"];
    [popUp addItemWithTitle:@"PopUp Item 2"];
    [rightContent addSubview:popUp];
    currentY += gapY + 5.0;

    // Toggles
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

    var radio1 = [CPRadio radioWithTitle:@"Radio A"];
    [radio1 setFrameOrigin:CGPointMake(innerX, currentY)];
    [radio1 setState:CPOnState];
    [rightContent addSubview:radio1];

    var radio2 = [CPRadio radioWithTitle:@"Radio B"];
    [radio2 setFrameOrigin:CGPointMake(innerX + 80, currentY)];
    [rightContent addSubview:radio2];
    [radio1 setTarget:self]; [radio1 setAction:@selector(dummyAction:)];
    [radio2 setTarget:self]; [radio2 setAction:@selector(dummyAction:)];
    currentY += gapY + 15.0; 

    // Progress
    var stepperWidth = 19.0;
    var alignRightX = innerX + controlWidth - stepperWidth;
    var levelWidth = alignRightX - innerX - 5.0; 
    
    var levelInd = [[CPLevelIndicator alloc] initWithFrame:CGRectMake(innerX, currentY + 2, levelWidth, 18)];
    [levelInd setMaxValue:5];
    [levelInd setDoubleValue:3];
    [levelInd setLevelIndicatorStyle:CPDiscreteCapacityLevelIndicatorStyle];
    [rightContent addSubview:levelInd];

    var levelStepper = [[CPStepper alloc] initWithFrame:CGRectMake(alignRightX, currentY, stepperWidth, fieldHeight)];
    [levelStepper setMinValue:0]; [levelStepper setMaxValue:5]; [levelStepper setDoubleValue:3];
    [levelStepper setValueWraps:NO];
    [rightContent addSubview:levelStepper];
    [levelInd bind:CPValueBinding toObject:levelStepper withKeyPath:@"doubleValue" options:nil];
    currentY += gapY;

    var spinner = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(innerX, currentY, 24, 24)];
    [spinner setStyle:CPProgressIndicatorSpinningStyle];
    [spinner setIndeterminate:YES];
    [spinner setControlSize:CPRegularControlSize];
    [spinner startAnimation:self];
    [rightContent addSubview:spinner];

    var circProg = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(innerX + 40, currentY, 24, 24)];
    [circProg setStyle:CPProgressIndicatorSpinningStyle];
    [circProg setIndeterminate:NO];
    [circProg setControlSize:CPRegularControlSize];
    [circProg setDoubleValue:65.0];
    [circProg setMaxValue:100.0];
    [rightContent addSubview:circProg];

    var stepper = [[CPStepper alloc] initWithFrame:CGRectMake(alignRightX, currentY, stepperWidth, 27)];
    [stepper setValueWraps:NO]; [stepper setAutorepeat:YES];
    [stepper setMinValue:0]; [stepper setMaxValue:100]; [stepper setDoubleValue:65];
    [rightContent addSubview:stepper];
    
    [circProg bind:CPValueBinding toObject:stepper withKeyPath:@"doubleValue" options:nil];
    currentY += 35.0;

    var detProgress = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, 16)];
    [detProgress setStyle:CPProgressIndicatorBarStyle];
    [detProgress setIndeterminate:NO];
    [detProgress setMinValue:0];
    [detProgress setMaxValue:100];
    [detProgress bind:CPValueBinding toObject:stepper withKeyPath:@"doubleValue" options:nil];
    [rightContent addSubview:detProgress];
    currentY += 20.0;

    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(innerX, currentY, controlWidth, 16)];
    [progressBar setStyle:CPProgressIndicatorBarStyle];
    [progressBar setIndeterminate:YES];
    [progressBar startAnimation:self];
    [rightContent addSubview:progressBar];
    
    currentY += gapY;

    var maxHeight = MAX(CGRectGetHeight([leftBox frame]), currentY + 15.0);
    [leftBox setFrameSize:CGSizeMake(boxWidth, maxHeight)];
    [rightBox setFrameSize:CGSizeMake(boxWidth, maxHeight)];

    if (isHUD)
        [self _applyHUDStateToView:containerView];
}

// --------------------------------------------------------------------------------
// ALERT ACTIONS
// --------------------------------------------------------------------------------

- (void)showStandardAlert:(id)sender
{
    var alert = [[CPAlert alloc] init];
    [alert setTitle:@"Standard Alert"];
    [alert setMessageText:@"Informational Alert"];
    [alert setInformativeText:@"This is a standard CPAlert with the CPInformationalAlertStyle. It behaves like a standard modal dialog."];
    [alert setAlertStyle:CPInformationalAlertStyle];
    
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)showHUDAlert:(id)sender
{
    var alert = [[CPAlert alloc] init];
    [alert setTitle:@"HUD Alert"];
    [alert setMessageText:@"Critical HUD Alert"];
    [alert setInformativeText:@"This alert uses the CPCriticalAlertStyle and explicitly sets the HUD theme."];
    [alert setAlertStyle:CPCriticalAlertStyle];
    
    // Explicitly set the HUD theme like in the example
    [alert setTheme:[CPTheme defaultHudTheme]];
    
    [alert addButtonWithTitle:@"Destroy"];
    [alert addButtonWithTitle:@"Cancel"];
    
    // We can use a block for the return handler if desired, or standard modal
    [alert runModal];
}

- (void)showSheetAlert:(id)sender
{
    var alert = [[CPAlert alloc] init];
    [alert setMessageText:@"Document Warning"];
    [alert setInformativeText:@"This is a Sheet (CPDocModalWindowMask). It is attached to the parent window."];
    [alert setAlertStyle:CPWarningAlertStyle];
    
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    
    // If the parent window is HUD, make the sheet match
    if (_isHUD)
        [alert setTheme:[CPTheme defaultHudTheme]];

    // Using the delegate method pattern
    [alert beginSheetModalForWindow:[self window] 
                      modalDelegate:self 
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
                        contextInfo:@"SheetContext"];
}

- (void)alertDidEnd:(CPAlert)anAlert returnCode:(CPInteger)returnCode contextInfo:(id)context
{
    CPLog.info(@"Alert ended. Return Code: %d. Context: %@", returnCode, context);
}

// --------------------------------------------------------------------------------

- (void)_buildTableTab:(CPView)containerView isHUD:(BOOL)isHUD
{
    var bounds = [containerView bounds];
    var ruleEditorHeight = 140.0;
    
    // --- RULE EDITOR SECTION (Top) ---
    var ruleContainer = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), ruleEditorHeight)];
    [ruleContainer setAutohidesScrollers:YES];
    [ruleContainer setBorderType:CPBezelBorder];
    
    _ruleEditor = [[CPRuleEditor alloc] initWithFrame:CGRectMake(0,0, CGRectGetWidth(bounds), ruleEditorHeight)];
    [_ruleEditor setRowHeight:25.0];
    [_ruleEditor setCanRemoveAllRows:YES];

    [ruleContainer setAutoresizingMask:CPViewWidthSizable];

    _ruleDelegate = [[RuleDelegate alloc] init];
    [_ruleEditor setDelegate:_ruleDelegate];
    [_ruleEditor setAutoresizingMask:CPViewWidthSizable];

    [_ruleEditor setTarget:self];
    [_ruleEditor setAction:@selector(ruleEditorAction:)];
    
    // 1. Add the initial row structure
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
    var splitHeight = CGRectGetHeight(bounds) - splitY;
    
    var splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0, splitY, CGRectGetWidth(bounds), splitHeight)];
    [splitView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [splitView setVertical:NO]; 
    
    // --- TOP PANE: Table + ButtonBar ---
    var topPaneWrapper = [[CPView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), splitHeight / 2.0)];
    [topPaneWrapper setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    
    var buttonBarHeight = 32.0;
    
    // Table ScrollView
    var tableScroll = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), CGRectGetHeight([topPaneWrapper bounds]) - buttonBarHeight)];
    [tableScroll setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [tableScroll setAutohidesScrollers:YES];

    var tableView = [[CPTableView alloc] initWithFrame:[tableScroll bounds]];
    [tableView setUsesAlternatingRowBackgroundColors:YES];
    [tableView setCornerView:nil];
    
    [tableView bind:CPSelectionIndexesBinding toObject:_arrayController withKeyPath:@"selectionIndexes" options:nil];
    [tableView bind:@"sortDescriptors" toObject:_arrayController withKeyPath:@"sortDescriptors" options:nil];

    var colAnimal = [[CPTableColumn alloc] initWithIdentifier:@"animal"];
    [[colAnimal headerView] setStringValue:@"Animal"];
    [colAnimal setWidth:150];
    [colAnimal setEditable:YES];
    var animalCell = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    [animalCell setEditable:YES];
    [colAnimal setDataView:animalCell];
    [tableView addTableColumn:colAnimal];
    [colAnimal bind:CPValueBinding toObject:_arrayController withKeyPath:@"arrangedObjects.animal" options:nil];

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
    [topPaneWrapper addSubview:tableScroll];
    
    // Button Bar
    var buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight([topPaneWrapper bounds]) - buttonBarHeight, CGRectGetWidth(bounds), buttonBarHeight)];
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
    [topPaneWrapper addSubview:buttonBar];

    // --- BOTTOM PANE: Text View ---
    var textScroll = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), splitHeight / 2.0)];
    [textScroll setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [textScroll setAutohidesScrollers:YES];
    
    var textView = [[CPTextView alloc] initWithFrame:[textScroll bounds]];
    [textView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [textView setEditable:YES];
    [textView setRichText:YES]; 
    [textView setString:@"Enter an animal name such as 'Duck' in the Textfield above in order to filter the table dynamically.\nMove the columns around!\n\nBTW: this is a Rich Text enabled CPTextView"];
    [textView setFont:[CPFont fontWithName:@"Courier" size:13.0]];

    [textScroll setDocumentView:textView];
    
    [splitView addSubview:topPaneWrapper];
    [splitView addSubview:textScroll];

    [containerView addSubview:splitView];

    if (isHUD)
    {
        [self _applyHUDStateToView:containerView];
        [textView setBackgroundColor:[CPColor blackColor]];
        [textView setTextColor:[CPColor whiteColor]];
        [_predicateField setTextColor:[CPColor whiteColor]];
        [self _applyHUDStateToView:_ruleEditor];
    }
}

// This method catches the action sent by the RuleEditor when the text field (or other control) changes.
- (void)ruleEditorAction:(id)sender
{
    // Simply delegate to the update logic
    [self ruleEditorRowsDidChange:nil];
}

- (void)ruleEditorRowsDidChange:(CPNotification)note
{
    var predicate = [_ruleEditor predicate];

    if (predicate)
        [_predicateField setStringValue:[predicate predicateFormat]];
    else
        [_predicateField setStringValue:@"(Incomplete Predicate)"];
        
    // Apply the filter to the table's data source
    [_arrayController setFilterPredicate:predicate];
}

// --- SIZES TAB BUILDER ---
- (void)_buildSizesTab:(CPView)containerView isHUD:(BOOL)isHUD
{
    [self _addSizeColumnTo:containerView atX:20.0 controlSize:CPRegularControlSize title:@"Regular size"];
    [self _addSizeColumnTo:containerView atX:160.0 controlSize:CPSmallControlSize title:@"Small size"];
    [self _addSizeColumnTo:containerView atX:280.0 controlSize:CPMiniControlSize title:@"Mini size"];

    if (isHUD)
        [self _applyHUDStateToView:containerView];
}

- (void)_addSizeColumnTo:(CPView)parentView atX:(float)xPos controlSize:(CPControlSize)aSize title:(CPString)title
{
    var y = 20.0;
    var rowHeight = 40.0;
    var width = (aSize == CPRegularControlSize) ? 100.0 : ((aSize == CPSmallControlSize) ? 90.0 : 80.0);
    
    var label = [CPTextField labelWithTitle:title];
    [label setFrameOrigin:CGPointMake(xPos, y)];
    [label setFont:[CPFont systemFontOfSize:13.0]];
    [parentView addSubview:label];
    y += 35.0;

    var popUp = [[CPPopUpButton alloc] initWithFrame:CGRectMake(xPos, y, width, 24)];
    [popUp addItemWithTitle:@"Item 1"];
    [popUp addItemWithTitle:@"Item 2"];
    [popUp setControlSize:aSize];
    [parentView addSubview:popUp];
    y += rowHeight;

    var tf = [[CPTextField alloc] initWithFrame:CGRectMake(xPos, y, width, 24)];
    [tf setStringValue:@"Input"];
    [tf setBezeled:YES];
    [tf setEditable:YES];
    [tf setControlSize:aSize];
    [parentView addSubview:tf];
    y += rowHeight;

    var stepper = [[CPStepper alloc] initWithFrame:CGRectMake(xPos, y, 13, 23)];
    [stepper setControlSize:aSize];
    [parentView addSubview:stepper];
    y += rowHeight;

    var dpWidth = width + (aSize == CPRegularControlSize ? 20 : 15);
    var dp = [[CPDatePicker alloc] initWithFrame:CGRectMake(xPos, y, dpWidth, 28)];
    [dp setControlSize:aSize];
    [dp setDatePickerStyle:CPTextFieldAndStepperDatePickerStyle];
    [dp setDatePickerElements:CPYearMonthDayDatePickerElementFlag];
    [dp setDateValue:[CPDate date]];
    [parentView addSubview:dp];
    y += rowHeight;

    var cb = [CPCheckBox checkBoxWithTitle:@"Check"];
    [cb setFrameOrigin:CGPointMake(xPos, y)];
    [cb setControlSize:aSize];
    [cb sizeToFit];
    [parentView addSubview:cb];
    y += rowHeight;

    var btn = [[CPButton alloc] initWithFrame:CGRectMake(xPos, y, width, 24)];
    [btn setTitle:@"Button"];
    [btn setControlSize:aSize];
    [parentView addSubview:btn];
    y += rowHeight;

    var texBtn = [[CPButton alloc] initWithFrame:CGRectMake(xPos, y, width, 24)];
    [texBtn setTitle:@"Textured"];
    [texBtn setBezelStyle:CPTexturedSquareBezelStyle];
    [texBtn setControlSize:aSize];
    [parentView addSubview:texBtn];
    y += rowHeight;

    var roundTexBtn = [[CPButton alloc] initWithFrame:CGRectMake(xPos, y, width, 24)];
    [roundTexBtn setTitle:@"Round"];
    [roundTexBtn setBezelStyle:CPTexturedRoundedBezelStyle];
    [roundTexBtn setControlSize:aSize];
    [parentView addSubview:roundTexBtn];
    y += rowHeight;

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
    
    var popUp2 = [[CPPopUpButton alloc] initWithFrame:CGRectMake(xPos, y, width, 24)];
    [popUp2 setPullsDown:YES];
    [popUp2 setControlSize:aSize];
    [parentView addSubview:popUp2];
}

// --- OUTLINE TAB BUILDER ---
- (void)_buildOutlineTab:(CPView)containerView isHUD:(BOOL)isHUD
{
    var bounds = [containerView bounds];
    var scrollView = [[CPScrollView alloc] initWithFrame:bounds];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [scrollView setAutohidesScrollers:YES];

    var outlineView = [[CPOutlineView alloc] initWithFrame:[scrollView bounds]];
    [outlineView setUsesAlternatingRowBackgroundColors:YES];
    [outlineView setCornerView:nil];
    
    // Add a single column
    var col = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [[col headerView] setStringValue:@"File Structure"];
    [col setWidth:CGRectGetWidth(bounds) - 5];
    [col setEditable:NO];
    [outlineView addTableColumn:col];
    
    [outlineView setOutlineTableColumn:col];
    
    [outlineView setDataSource:self];
    [outlineView setDelegate:self];
    
    [scrollView setDocumentView:outlineView];
    [containerView addSubview:scrollView];

    // Important: Expand the root item initially to show data
    var rootItem = [_outlineData objectAtIndex:0];
    [outlineView expandItem:rootItem];

    if (isHUD)
    {
        [self _applyHUDStateToView:containerView];
    }
}

// --- OUTLINE VIEW DATASOURCE ---

- (int)outlineView:(CPOutlineView)outlineView numberOfChildrenOfItem:(id)item
{
    if (item === nil)
        return [_outlineData count];
        
    return [[item objectForKey:@"children"] count];
}

- (id)outlineView:(CPOutlineView)outlineView child:(int)index ofItem:(id)item
{
    if (item === nil)
        return [_outlineData objectAtIndex:index];
        
    return [[item objectForKey:@"children"] objectAtIndex:index];
}

- (BOOL)outlineView:(CPOutlineView)outlineView isItemExpandable:(id)item
{
    if (item === nil)
        return YES;
        
    return [[item objectForKey:@"children"] count] > 0;
}

- (id)outlineView:(CPOutlineView)outlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    // We only have one column identifier "name"
    return [item objectForKey:@"name"];
}

// --- GENERIC HELPERS ---

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

// 1. Determine how many items are in the popup for a specific row type
- (int)ruleEditor:(CPRuleEditor)editor numberOfChildrenForCriterion:(id)criterion withRowType:(CPRuleEditorRowType)rowType
{
    // --- COMPOUND ROW (The container: "Any/All of the following...") ---
    if (rowType === CPRuleEditorRowTypeCompound)
    {
        // Root: The dropdown options ("Any", "All")
        if (criterion == nil) return 2;
        
        // Children of Any/All: The static text ("of the following are true")
        if (criterion == CPOrPredicateType || criterion == CPAndPredicateType) return 1;
        
        return 0;
    }

    // --- SIMPLE ROW (The actual rules: "Animal", "Legs"...) ---
    if (rowType === CPRuleEditorRowTypeSimple)
    {
        if (criterion == nil) return 2; // animal, legs
        if (criterion == @"animal") return 2; // contains, is
        if (criterion == @"legs") return 3; // >, <, ==
        
        // Operator's child is the value placeholder
        if ([self isOperator:criterion]) return 1;
    }
    
    return 0; 
}

// 2. Return the actual item for the popup
- (id)ruleEditor:(CPRuleEditor)editor child:(int)index forCriterion:(id)criterion withRowType:(CPRuleEditorRowType)rowType
{
    // --- COMPOUND ROW ---
    if (rowType === CPRuleEditorRowTypeCompound)
    {
        // Root: Return the predicate constants
        if (criterion == nil) {
            return (index == 0) ? CPOrPredicateType : CPAndPredicateType;
        }
        
        // Return a marker for the static text
        return @"_static_text_";
    }

    // --- SIMPLE ROW ---
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
    if ([self isOperator:criterion]) {
        return @"_value_";
    }
    return nil;
}

// 3. What the user sees on screen
- (id)ruleEditor:(CPRuleEditor)editor displayValueForCriterion:(id)criterion inRow:(int)row
{
    // --- COMPOUND DISPLAY ---
    if (criterion === CPOrPredicateType) return @"Any";
    if (criterion === CPAndPredicateType) return @"All";
    // This creates the static text label next to the dropdown
    if (criterion === @"_static_text_") return @"of the following are true";

    // --- SIMPLE DISPLAY ---
    if (criterion == @"_value_") 
    {
        var field = [[CPTextField alloc] initWithFrame:CGRectMake(0, 0, 100, 24)];
        [field setEditable:YES];
        [field setBezeled:YES];
        [field setBackgroundColor:[CPColor whiteColor]];
        [field setPlaceholderString:@"Value"];
        [field setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        return field;
    }

    if (criterion == @"animal") return @"Animal Name";
    if (criterion == @"legs") return @"Leg Count";
    if (criterion == @"contains") return @"contains";
    if (criterion == @"is") return @"is";
    if (criterion == @">") return @"is greater than";
    if (criterion == @"<") return @"is less than";
    if (criterion == @"==") return @"is equal to";
    
    return criterion;
}

- (BOOL)isOperator:(id)criterion
{
    return (criterion == @"contains" || criterion == @"is" || 
            criterion == @">" || criterion == @"<" || criterion == @"==");
}

// 4. Convert UI to Predicate
- (CPDictionary)ruleEditor:(CPRuleEditor)editor predicatePartsForCriterion:(id)criterion withDisplayValue:(id)value inRow:(int)row
{
    var result = [CPMutableDictionary dictionary];

    // Handle Compound Type (Any vs All)
    if (criterion === CPOrPredicateType || criterion === CPAndPredicateType)
    {
        [result setObject:criterion forKey:CPRuleEditorPredicateCompoundType];
        return result;
    }
    
    // Ignore the static text part
    if (criterion === @"_static_text_") return nil;

    // --- SIMPLE ROW LOGIC ---
    [result setObject:CPDirectPredicateModifier forKey:CPRuleEditorPredicateComparisonModifier];
    [result setObject:CPCaseInsensitivePredicateOption forKey:CPRuleEditorPredicateOptions];

    if (criterion == @"animal" || criterion == @"legs")
    {
        [result setObject:[CPExpression expressionForKeyPath:criterion] 
                   forKey:CPRuleEditorPredicateLeftExpression];
    }
    else if ([self isOperator:criterion])
    {
        var operatorType = CPEqualToPredicateOperatorType;
        
        if (criterion == @"contains") operatorType = CPContainsPredicateOperatorType;
        else if (criterion == @"is")  operatorType = CPEqualToPredicateOperatorType;
        else if (criterion == @"==")  operatorType = CPEqualToPredicateOperatorType;
        else if (criterion == @">")   operatorType = CPGreaterThanPredicateOperatorType;
        else if (criterion == @"<")   operatorType = CPLessThanPredicateOperatorType;
        
        [result setObject:operatorType forKey:CPRuleEditorPredicateOperatorType];
    }
    else if (criterion == @"_value_")
    {
        if ([value respondsToSelector:@selector(validateEditing)])
            [value validateEditing];

        var stringValue = [value stringValue];
        var typedValue = stringValue;

        // Type Coercion for Legs
        var criteria = [editor criteriaForRow:row];
        if ([criteria count] > 0 && [criteria objectAtIndex:0] == @"legs")
        {
             typedValue = [value intValue];
        }

        [result setObject:[CPExpression expressionForConstantValue:typedValue] 
                   forKey:CPRuleEditorPredicateRightExpression];
    }

    return result;
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

    var winWidth = 480.0,
        winHeight = 450.0,
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
