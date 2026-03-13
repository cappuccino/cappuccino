@import <AppKit/CPViewController.j>

@class UIBuilderController;

@implementation InspectorController : CPViewController
{
    UIBuilderController _builderController @accessors(property=builderController);
    CPPanel             _panel @accessors(property=panel);
    CPTableView         _connectionsTableView;
}

- (void)awakeFromMarkup
{
    [_builderController addObserver:self forKeyPath:@"elementsController.selectionIndexes" options:CPKeyValueObservingOptionNew context:nil];

    // Create Tab View
    var tabView = [[CPTabView alloc] initWithFrame:[[_panel contentView] bounds]];
    [tabView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [tabView setDelegate:self];

    // Properties Tab
    var propertiesView = [[CPView alloc] initWithFrame:CGRectMakeZero()];
    var propertiesTabItem = [[CPTabViewItem alloc] initWithIdentifier:@"properties"];
    [propertiesTabItem setLabel:@"Properties"];
    [propertiesTabItem setView:propertiesView];
    [tabView addTabViewItem:propertiesTabItem];

    // Connections Tab
    var connectionsView = [[CPView alloc] initWithFrame:CGRectMakeZero()];
    var connectionsTabItem = [[CPTabViewItem alloc] initWithIdentifier:@"connections"];
    [connectionsTabItem setLabel:@"Connections"];
    [connectionsTabItem setView:connectionsView];
    [tabView addTabViewItem:connectionsTabItem];

    // Connections TableView
    _connectionsTableView = [[CPTableView alloc] initWithFrame:[connectionsView bounds]];
    [_connectionsTableView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    var columns = [
        {identifier: "outlet", title: "Outlet", width: 80},
        {identifier: "action", title: "Action", width: 120}
    ];

    // Keep a reference to the array controller
    var connectionsController = [_builderController connectionsController];

    for (var i = 0; i < [columns count]; i++) {
        var colInfo = columns[i];
        var column = [[CPTableColumn alloc] initWithIdentifier:colInfo.identifier];
        [[column headerView] setStringValue:colInfo.title];
        [column setWidth:colInfo.width];
        [_connectionsTableView addTableColumn:column];
        // Bind the value of each column to the corresponding key path on the arranged objects
        [column bind:CPValueBinding toObject:connectionsController withKeyPath:("arrangedObjects." + colInfo.identifier) options:nil];
    }

    // Bind the table's selection to the array controller's selection
    [_connectionsTableView bind:@"selectionIndexes" toObject:connectionsController withKeyPath:@"selectionIndexes" options:nil];

    var connectionsViewBounds = [connectionsView bounds];
    var buttonBarHeight = 28;
    var tableHeight = connectionsViewBounds.size.height - buttonBarHeight;

    var scrollViewFrame = CGRectMake(3, 3, connectionsViewBounds.size.width - 6, tableHeight - 6);
    var buttonBarFrame = CGRectMake(0, tableHeight, connectionsViewBounds.size.width, buttonBarHeight);

    var scrollView = [[CPScrollView alloc] initWithFrame:scrollViewFrame];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [scrollView setDocumentView:_connectionsTableView];
    [connectionsView addSubview:scrollView];

    var buttonBar = [[CPView alloc] initWithFrame:buttonBarFrame];
    [buttonBar setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin]; // Stick to bottom
    [connectionsView addSubview:buttonBar];

    var deleteButton = [CPButtonBar minusButton];
    [deleteButton setAction:@selector(deleteSelectedConnection:)];
    [deleteButton setTarget:self];
    [buttonBar addSubview:deleteButton];

    // Replace panel's content view with the tab view
    [_panel setContentView:tabView];

    [self updateInspector];
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
{
    var connection = [[[_builderController connectionsController] arrangedObjects] objectAtIndex:aRow];
    var identifier = [aTableColumn identifier];
    
    return [connection valueForKey:identifier];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    // We only observe selection changes now.
    if (keyPath === @"elementsController.selectionIndexes")
    {
        [self updateInspector];
        [self _updateConnectionVisibility];
    }
}

- (void)_updateConnectionVisibility
{
    var tabView = [[self panel] contentView];
    if (![tabView isKindOfClass:[CPTabView class]])
        return;

    var selectedTabViewItem = [tabView selectedTabViewItem];
    var connectionsController = [_builderController connectionsController];
    var selectedObjects = [[_builderController elementsController] selectedObjects];

    // 1. Filter the connections based on the selected UI element.
    if ([selectedObjects count] === 1)
    {
        var selectedID = [[selectedObjects objectAtIndex:0] valueForKey:@"id"];
        var predicate = [CPPredicate predicateWithFormat:@"sourceID == %@ OR targetID == %@", selectedID, selectedID];
        [connectionsController setFilterPredicate:predicate];
    }
    else
    {
        [connectionsController setFilterPredicate:[CPPredicate predicateWithFormat:@"FALSEPREDICATE"]];
    }
}

- (void)tabView:(CPTabView)aTabView didSelectTabViewItem:(CPTabViewItem)aTabViewItem
{
    [self _updateConnectionVisibility];
}

- (void)deleteSelectedConnection:(id)sender
{
    var selectedObjects = [[_builderController connectionsController] selectedObjects];
    if ([selectedObjects count] > 0)
        [[_builderController connectionsController] removeObjects:selectedObjects];
}

- (void)updateInspector
{
    var selectedObjects = [[_builderController elementsController] selectedObjects];
    var propertiesView = [[[_panel contentView] tabViewItemAtIndex:0] view];

    // Clear existing views from properties tab
    var subviews = [propertiesView subviews];
    for (var i = [subviews count] - 1; i >= 0; i--) {
        [subviews[i] removeFromSuperview];
    }

    if ([selectedObjects count] === 1)
    {
        var selectedObject = selectedObjects[0];
        var elementType = [selectedObject valueForKey:@"type"];
        var viewClass = [UIBuilderController classForElementType:elementType];
        var properties = [viewClass persistentProperties];

        var yPos = 10;

        // Set panel title
        [_panel setTitle:elementType];

        for (var i = 0; i < [properties count]; i++)
        {
            var propertyName = properties[i];
            var value = [selectedObject valueForKey:propertyName];
            var propertyType = [[viewClass propertyTypes] valueForKey:propertyName];

            // Create Label
            var label = [[CPTextField alloc] initWithFrame:CGRectMake(10, yPos + 3, 100, 20)];
            [label setStringValue:propertyName];
            [label setBezeled:NO];
            [label setDrawsBackground:NO];
            [label setEditable:NO];
            [propertiesView addSubview:label];
            [label setTextColor:[CPColor grayColor]];

            // Create Control based on property type
            if (propertyType === UIBBoolean) {
                var checkbox = [[CPCheckBox alloc] initWithFrame:CGRectMake(120, yPos, 100, 20)];
                [checkbox setTitle:@""];
                [checkbox bind:@"value" toObject:selectedObject withKeyPath:propertyName options:nil];
                [propertiesView addSubview:checkbox];
            } else if (propertyType === UIBString || propertyType === UIBNumber) {
                var textField = [[CPTextField alloc] initWithFrame:CGRectMake(120, yPos, 150, 27)];
                [textField bind:@"value" toObject:selectedObject withKeyPath:propertyName options:nil];
                [textField setBezeled:YES];
                [textField setEditable:YES];
                [propertiesView addSubview:textField];
            } else { // Fallback for unknown types
                var textField = [[CPTextField alloc] initWithFrame:CGRectMake(120, yPos, 150, 25)];
                [textField bind:@"value" toObject:selectedObject withKeyPath:propertyName options:nil];
                [textField setBezeled:YES];
                [textField setEditable:YES];
                [propertiesView addSubview:textField];
            }

            yPos += 30;
        }

        [[self panel] orderFront:self];
    }
    else
    {
        [[self panel] orderOut:self];
    }
}

- (void)dealloc
{
    [_builderController removeObserver:self forKeyPath:@"elementsController.selectionIndexes"];
    [super dealloc];
}

@end
