/*
 * AppController.j
 * TableCibTest
 *
 * Created by Francisco Tolmasky on July 5, 2009.
 * Copyright 2009, 280 North, Inc. All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


CPLogRegister(CPLogConsole);

@implementation AppController : CPObject
{
    CPWindow        theWindow; //this "outlet" is connected automatically by the Cib
    CPScrollView    theScrollView;
    CPTableView     theTableView;
    CPPopupButton   theBorderTypePopup;
    CPTextField     horizontalIntercellSpacing;
    CPTextField     verticalIntercellSpacing;
    CPCheckBox      horizontalGridCB;
    CPCheckBox      verticalGridCB;
    CPColorWell     gridColorWell;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{    
    [theBorderTypePopup selectItemWithTag:[theScrollView borderType]];
    
    var spacing = [theTableView intercellSpacing];
    
    [horizontalIntercellSpacing setDoubleValue:spacing.width];
    [verticalIntercellSpacing setDoubleValue:spacing.height];
    
    var mask = [theTableView gridStyleMask];
    
    [horizontalGridCB setState:(mask & CPTableViewSolidHorizontalGridLineMask) ? CPOnState : CPOffState];
    [verticalGridCB setState:(mask & CPTableViewSolidVerticalGridLineMask) ? CPOnState : CPOffState];
    
    [gridColorWell setColor:[theTableView gridColor]];
}

- (void)awakeFromCib
{
    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
    [theWindow setBackgroundColor:[CPColor colorWithHexString:@"f3f4f5"]];
}

- (int)numberOfRowsInTableView:(CPTableView)tableView
{
    return 10;
}

- (id)tableView:(CPTableView)tableView objectValueForTableColumn:(CPTableColumn)tableColumn row:(int)row
{
    return String((row + 1) * [[tableColumn identifier] intValue]);
}

// Actions

- (void)setBorder:(id)sender
{
    var type = [[sender selectedItem] tag];
    
    [theScrollView setBorderType:type];
}

- (void)setIntercellSpacing:(id)sender
{
    var spacing = [theTableView intercellSpacing],
        horizontal = [horizontalIntercellSpacing doubleValue],
        vertical = [verticalIntercellSpacing doubleValue];
    
    [theTableView setIntercellSpacing:CGSizeMake(horizontal, vertical)];
    [theTableView setNeedsLayout];
    [[theTableView headerView] setNeedsLayout];
    [theTableView setNeedsDisplay:YES];
    [theTableView reloadData];
}

- (void)setGridStyle:(id)sender
{
    var mask = CPTableViewGridNone;
    
    if ([horizontalGridCB state] == CPOnState)
        mask |= CPTableViewSolidHorizontalGridLineMask;
        
    if ([verticalGridCB state] == CPOnState)
        mask |= CPTableViewSolidVerticalGridLineMask;
        
    [theTableView setGridStyleMask:mask];
    [theTableView setNeedsDisplay:YES];
}

- (void)setGridColor:(id)sender
{
    [theTableView setGridColor:[sender color]];
    [theTableView setNeedsDisplay:YES];
}

@end