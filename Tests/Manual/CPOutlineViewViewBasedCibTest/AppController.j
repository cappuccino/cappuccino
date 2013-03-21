/*
 * AppController.j
 * CPOutlineViewViewBasedCibTest
 *
 * Created by You on April 11, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

CPLogRegister(CPLogConsole);

@implementation AppController : CPObject
{
    @outlet CPWindow      theWindow;
    @outlet CPOutlineView outlineView;
}

- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];
}

- (int)outlineView:(id)oview numberOfChildrenOfItem:(id)item
{
    return 3;
}

- (id)outlineView:(id)oview child:(int)childnum ofItem:(id)item
{
    return [CPObject new];
}

- (BOOL)outlineView:(id)oview isItemExpandable:(id)item
{
    return YES;
}

-(id)outlineView:(id)oview dataViewForTableColumn:(id)tableColumn item:(id)item
{
    var identifier = [tableColumn identifier];
    if (identifier == @"first" && [oview parentForItem:item] == nil)
        identifier = @"firstRoot";

    var view = [oview makeViewWithIdentifier:identifier owner:self];
    [[view textField] setStringValue:@"Item <" + [item UID] + ">"];

    if (identifier = @"firstRoot")
    {
        var expandButton = [view viewWithTag:1000];
        [expandButton setState:[outlineView isItemExpanded:item]];
    }

    return view;
}

- (IBAction)expand:(id)sender
{
    var row = [outlineView rowForView:sender],
        item = [outlineView itemAtRow:row];

    if ([outlineView isItemExpanded:item])
        [outlineView collapseItem:item];
    else
        [outlineView expandItem:item];
}

@end
