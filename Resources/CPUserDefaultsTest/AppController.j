
@import <AppKit/CPTableView.j>


@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(50.0, 100.0, 400.0, 300.0) styleMask:CPTitledWindowMask],
        contentView = [theWindow contentView];

    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 300.0)],
        tableView = [[CPTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 300.0)];

    [scrollView setDocumentView:tableView];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    var tableColumn1 = [[CPTableColumn alloc] initWithIdentifier:@"column1"];
    [[tableColumn1 headerView] setStringValue:@"Column 1"];
    [tableView addTableColumn:tableColumn1];

    var tableColumn2 = [[CPTableColumn alloc] initWithIdentifier:@"column2"];
    [[tableColumn2 headerView] setStringValue:@"Column 2"];
    [tableView addTableColumn:tableColumn2];

    var tableColumn3 = [[CPTableColumn alloc] initWithIdentifier:@"column3"];
    [[tableColumn3 headerView] setStringValue:@"Column 3"];
    [tableView addTableColumn:tableColumn3];

    var tableColumn4 = [[CPTableColumn alloc] initWithIdentifier:@"column4"];
    [[tableColumn4 headerView] setStringValue:@"Column 4"];
    [tableView addTableColumn:tableColumn4];

    var tableColumn5 = [[CPTableColumn alloc] initWithIdentifier:@"column5"];
    [[tableColumn5 headerView] setStringValue:@"Column 5"];
    [tableView addTableColumn:tableColumn5];

    [scrollView setBackgroundColor:[CPColor blueColor]];
    [contentView addSubview:scrollView];

    [tableView setAutosaveTableColumns:YES];
    [tableView setAutosaveName:@"myAutosaveName"];

    [theWindow makeKeyAndOrderFront:self];
}

@end
