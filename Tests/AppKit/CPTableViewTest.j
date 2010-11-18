@import <AppKit/AppKit.j>

@implementation CPTableViewTest : OJTestCase
{
    CPTableView     tableView;
    CPTableColumn   tableColumn;

    BOOL            doubleActionReceived;
}

- (void)setUp
{
    // setup a reasonable table
    tableView = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    tableColumn = [[CPTableColumn alloc] initWithIdentifier:@"Foo"];
    [tableView addTableColumn:tableColumn];
}

- (void)testCPTableDoubleAction
{
    doubleActionReceived = NO;

    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(doubleAction:)];

    // CPEvent with 2 clickCount
    var dblClk = [CPEvent mouseEventWithType:CPLeftMouseUp location:CGPointMake(50, 50) modifierFlags:0
                          timestamp:0 windowNumber:0 context:nil eventNumber:0 clickCount:2 pressure:0];

    [[CPApplication sharedApplication] sendEvent:dblClk];
    [tableView trackMouse:dblClk];

    [self assertTrue:doubleActionReceived];
}

- (void)doubleAction:(id)sender
{
    doubleActionReceived = YES;
}

@end
