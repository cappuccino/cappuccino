/*
 * AppController.j
 * BindingContentArrayTest
 *
 * Created by aparajita on August 17, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@implementation Companies : CPObject
{
    CPMutableArray items @accessors;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        items = [CPMutableArray array];
        [items addObject:[CPDictionary dictionaryWithObjectsAndKeys:@"Spacely Sprockets", @"name", [CPArray arrayWithObjects:@"Tom", @"Dick", @"Harry"], @"employees"]];
        [items addObject:[CPDictionary dictionaryWithObjectsAndKeys:@"Cogswell Cogs", @"name", [CPArray arrayWithObjects:@"Jane", @"Mary", @"Vic"], @"employees"]];
    }

    return self;
}

@end

@implementation AppController : CPObject
{
    CPString            employee @accessors;
    Companies           companies @accessors;
    CPArrayController   companiesController;
    CPArrayController   employeesController;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        companiesScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(30, 30, 200, 100)],
        companiesTable = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)],
        employeesScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(250, 30, 200, 100)],
        employeesTable = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)],
        text = [[CPTextField alloc] initWithFrame:CGRectMake(250, 140, 200, 29)];

    companies = [Companies new];

    var column = [[CPTableColumn alloc] initWithIdentifier:@"name"];

    [column setResizingMask:CPTableColumnAutoresizingMask];
    [companiesTable addTableColumn:column];
    [companiesTable setAllowsMultipleSelection:YES];
    [companiesTable setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [companiesScrollView setHasHorizontalScroller:NO];
    [companiesScrollView setHasVerticalScroller:NO];
    [companiesScrollView setDocumentView:companiesTable];
    [companiesScrollView setBorderType:CPBezelBorder];
    [companiesTable setHeaderView:nil];
    [companiesTable setAllowsEmptySelection:NO];

    [contentView addSubview:companiesScrollView];

    column = [[CPTableColumn alloc] initWithIdentifier:@"name"];

    [column setResizingMask:CPTableColumnAutoresizingMask];
    [employeesTable addTableColumn:column];
    [employeesTable setAllowsMultipleSelection:YES];
    [employeesTable setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [employeesScrollView setHasHorizontalScroller:NO];
    [employeesScrollView setHasVerticalScroller:NO];
    [employeesScrollView setDocumentView:employeesTable];
    [employeesScrollView setBorderType:CPBezelBorder];
    [employeesTable setHeaderView:nil];
    [employeesTable setAllowsEmptySelection:YES];

    [contentView addSubview:employeesScrollView];
    [contentView addSubview:text];

    companiesController = [CPArrayController new];
    [companiesController bind:@"contentArray" toObject:companies withKeyPath:@"items" options:nil];

    employeesController = [CPArrayController new];
    [employeesController bind:@"contentArray" toObject:companiesController withKeyPath:@"selection.employees" options:nil];

    //var employeeController = [CPObjectController new];

    //[employeeController bind:@"contentObject" toObject:self withKeyPath:@"employee" options:nil];

    [[companiesTable tableColumnWithIdentifier:@"name"] bind:@"value" toObject:companiesController withKeyPath:@"arrangedObjects.name" options:nil];
    [[employeesTable tableColumnWithIdentifier:@"name"] bind:@"value" toObject:employeesController withKeyPath:@"arrangedObjects" options:nil];
    [text bind:@"value" toObject:employeesController withKeyPath:@"selection.self" options:nil];

    [companiesController addObserver:self forKeyPath:@"selection" options:0 context:@"companies.selection"];
    [companiesController addObserver:self forKeyPath:@"selectionIndexes" options:0 context:@"companies.selectionIndexes"];
    [companiesController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:@"companies.arrangedObjects"];
    [employeesController addObserver:self forKeyPath:@"selectionIndexes" options:0 context:@"employees.selectionIndexes"];
    [employeesController addObserver:self forKeyPath:@"selection" options:0 context:@"employees.selection"];
    [employeesController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:@"employees.arrangedObjects"];

    [theWindow setInitialFirstResponder:companiesTable];
    [theWindow orderFront:self];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    console.log("\nkeyPath: %s\ncontext: %s\nnew: %s\nold: %s", keyPath, context, [[change valueForKey:CPKeyValueChangeNewKey] description], [[change valueForKey:CPKeyValueChangeOldKey] description]);
}

@end
