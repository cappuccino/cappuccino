
import <Foundation/CPObject.j>
import <AppKit/CPTableView.j>

CPLogRegister(CPLogConsole);

@implementation AppController : CPObject
{
    CPTableView _tableView;
    CPArray     _data;
    CPImage     _iconImage;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var view = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
    
    [view setBackgroundColor:[CPColor whiteColor]];
    [view enterFullScreenMode:nil withOptions:nil];
    
    _data = [1, 2];
    
    _tableView = [[CPTableView alloc] initWithFrame:[view bounds]];
    //[_tableView setBackgroundColor:[CPColor blueColor]];
    
    var iconView = [[CPImageView alloc] initWithFrame:CGRectMake(16,16,0,0)];
    [iconView setImageScaling:CPScaleNone];

    var iconColumn = [[CPTableColumn alloc] initWithIdentifier:"icons"];
    [iconColumn setWidth:32];
    [iconColumn setDataView:iconView];
    
    [_tableView addTableColumn:iconColumn];
    
    for (var i = 1; i <= 10; i++)
    {
        var column = [[CPTableColumn alloc] initWithIdentifier:String(i)];

        [[column headerView] setStringValue:"Number"];
        [[column headerView] sizeToFit];
        [column setWidth:[[column headerView] frame].size.width];

        [_tableView addTableColumn:column];
    }
    
    var scrollView = [[CPScrollView alloc] initWithFrame:[view bounds]];
    
    [scrollView setDocumentView:_tableView];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    
    [view addSubview:scrollView];
    
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
    
    _iconImage = [[CPImage alloc] initWithContentsOfFile:"http://cappuccino.org/images/favicon.png" size:CGSizeMake(16,16)];
}

- (int)numberOfRowsInTableView:(CPTableView)tableView
{
    return 7000000;
}

- (id)tableView:(CPTableView)tableView objectValueForTableColumn:(CPTableColumn)tableColumn row:(int)row
{
    if ([tableColumn identifier] == "icons")
        return _iconImage
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
	        return false
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
