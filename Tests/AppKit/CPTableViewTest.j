@import <AppKit/AppKit.j>

@implementation CPTableViewTest : OJTestCase
{
}

- (void)setUp
{
    // setup a reasonable table
    _tableView = [[CPTableView alloc] initWithFrame:CGRectMakeZero()];
    _tableColumn = [[CPTableColumn alloc] initWithIdentifier:@"Foo"];
    [_tableView addTableColumn:_tableColumn];
}

// Failing test for issue 112, See:http://github.com/280north/cappuccino/issues/#issue/112
- (void)testCPTableDoubleAction
{
    // CPEvent with 2 clickCount
    var dblClk = [CPEvent mouseEventWithType:CPLeftMouseUp location:CGPointMakeZero() modifierFlags:0 
                          timestamp:0 windowNumber:0 context:nil eventNumber:0 clickCount:2 pressure:0];
    
    [_tableView trackSelection:dblClk];
}
