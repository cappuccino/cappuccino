
@import <Foundation/CPObject.j>

@import <Foundation/CPIndexSet.j>
@import <AppKit/NEWCPTableColumn.j>
@import <AppKit/NEWCPTableView.j>


CPLogRegister(CPLogConsole);

@implementation AppController : CPObject
{
    CPTableView tableView;
    CPImage     iconImage;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var view = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
    
    [view setBackgroundColor:[CPColor whiteColor]];
    [view enterFullScreenMode:nil withOptions:nil];
    
    tableView = [[NEWCPTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 500.0, 500.0)];//[view bounds]];

    [tableView setBackgroundColor:[CPColor blueColor]];

    var iconView = [[CPImageView alloc] initWithFrame:CGRectMake(16,16,0,0)];

    [iconView setImageScaling:CPScaleNone];

    var iconColumn = [[NEWCPTableColumn alloc] initWithIdentifier:"icons"];

    [iconColumn setWidth:32.0];
    [iconColumn setDataView:iconView];

    [tableView addTableColumn:iconColumn];
    
    for (var i = 1; i <= 10; i++)
    {
        var column = [[NEWCPTableColumn alloc] initWithIdentifier:String(i)];

//        [[column headerView] setStringValue:"Number"];
//        [[column headerView] sizeToFit];
//        [column setWidth:[[column headerView] frame].size.width];
        
        [column setWidth:200.0];

        [tableView addTableColumn:column];
    }

    var scrollView = [[CPScrollView alloc] initWithFrame:[view bounds]];

    [scrollView setDocumentView:tableView];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    [view addSubview:scrollView];

    [tableView setDelegate:self];
    [tableView setDataSource:self];
    
    iconImage = [[CPImage alloc] initWithContentsOfFile:"http://cappuccino.org/images/favicon.png" size:CGSizeMake(16,16)];
}

- (int)numberOfRowsInTableView:(CPTableView)tableView
{
    return 700000;
}

- (id)tableView:(CPTableView)tableView objectValueForTableColumn:(CPTableColumn)tableColumn row:(int)row
{
    if ([tableColumn identifier] === "icons")
        return iconImage
    else
        return String((row + 1) * [[tableColumn identifier] intValue]);
}
/*
- (id)tableView:(CPTableView)tableView heightOfRow:(int)row
{
    //CPLog.info("heightOfRow:"+row);
    return 20.0 + ROUND(row * 0.5);
}
*/
//- (void)tableViewSelectionIsChanging:(CPNotification)aNotification
//{
//	CPLog.debug(@"changing! %@", [aNotification description]);
//}
//
//- (void)tableViewSelectionDidChange:(CPNotification)aNotification
//{
//	CPLog.debug(@"did change! %@", [aNotification description]);
//}

- (BOOL)tableView:(CPTableView)aTableView shouldSelectRow:(int)rowIndex
{
	//CPLog.debug(@"shouldSelectRow %d", rowIndex);
	for (var i = 2, sqrt = SQRT(rowIndex+1); i <= sqrt; i++)
	    if ((rowIndex+1) % i === 0)
	        return false;

	return true;
}

- (BOOL)selectionShouldChangeInTableView:(CPTableView)aTableView
{
	//CPLog.debug(@"selectionShouldChangeInTableView");
	return YES;
}

//- (CPIndexSet)tableView:(CPTableView)tableView selectionIndexesForProposedSelection:(CPIndexSet)proposedSelectionIndexes
//{
//	CPLog.debug(@"selectionIndexesForProposedSelection %@", [proposedSelectionIndexes description]);
//	return proposedSelectionIndexes;
//}

@end
