/*
 * AppController.j
 * HeaderView-CornerView
 *
 * Created by aparajita on May 18, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/CPObject.j>

var brokenTable = nil,
    fixedTable = nil;

@implementation AppController : CPObject
{
    CPWindow theWindow;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{    
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];
            
    brokenTable = [self makeTableWithCaption:@"No header, has corner: wrong" at:CPPointMake(50, 50)];
    fixedTable = [self makeTableWithCaption:@"No header, no corner: correct" at:CPPointMake(250, 50)];

    [brokenTable setHeaderView:nil];
    [fixedTable setHeaderView:nil];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (void)makeTableWithCaption:(CPString)caption at:(CGPoint)location
{
    var label = [CPTextField labelWithTitle:caption],
        table = [[CPTableView alloc] initWithFrame:CGRectMakeZero()],
        frame = CGRectMake(location.x, location.y + 25, 150, ([table rowHeight] * 5) + 2),
        scroll = [[CPScrollView alloc] initWithFrame:frame];

    [label setFrameOrigin:CGPointMake(location.x, location.y)];
    
    [table setDataSource:self];
    [table setDelegate:self];
    [table setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [table setUsesAlternatingRowBackgroundColors:YES];
    [table setAllowsMultipleSelection:NO];
    [table setIntercellSpacing:CGSizeMake(0, 0)];

    var column = [[CPTableColumn alloc] initWithIdentifier:"1"];

    [column setWidth:CGRectGetWidth(frame) - [CPScroller scrollerWidth]];
    [column setResizingMask:CPTableColumnNoResizing];
    [table addTableColumn:column];
    [table selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];

    [scroll setBorderType:CPLineBorder];
    [scroll setHasHorizontalScroller:NO];
    [scroll setDocumentView:table];
    
    var contentView = [theWindow contentView];
    
    [contentView addSubview:label];
    [contentView addSubview:scroll];
    
    return table;
}

/*!
    Returns the number of rows in the table data.
    The default implementation returns the size of the table data array.
*/
- (int)numberOfRowsInTableView:(id)tableView
{
    return 10;
}

- (id)tableView:(id)tableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    return @"Row " + aRow;
}

@end

@implementation CPTableView (test)

- (void)setHeaderView:(CPView)aHeaderView
{
    if (_headerView === aHeaderView)
        return;

    [_headerView setTableView:nil];

    _headerView = aHeaderView;

    if (_headerView)
    {
        [_headerView setTableView:self];
        [_headerView setFrameSize:CGSizeMake(CGRectGetWidth([self frame]), CGRectGetHeight([_headerView frame]))];
    }
    else if (self === fixedTable)
    {
        // If there is no header view, there should be no corner view
        [_cornerView removeFromSuperview];
        _cornerView = nil;
    }

    var scrollView = [self enclosingScrollView];

    if ([scrollView isKindOfClass:[CPScrollView class]] && [scrollView documentView] === self)
        [scrollView _updateCornerAndHeaderView];
}

@end
