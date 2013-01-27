/*
 * AppController.j
 * CPTabViewNib
 *
 * Created by Alexander Ljungberg on November 5, 2010.
 * Copyright 2010, WireLoad, LLC All rights reserved.
 */

@import <Foundation/CPObject.j>

@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet     CPTabView nibTabView;
    @outlet     CPTabView nibTabViewEmpty;
}

- (IBAction)changeView:(id)sender
{
    var item = [nibTabView selectedTabViewItem],
        view = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [view setBackgroundColor:[CPColor redColor]];
    [item setView:view];
}

- (void)awakeFromCib
{
    var item = [[CPTabViewItem alloc] initWithIdentifier:@"item"],
        view = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [item setView:view];
    [item setLabel:@"item"];

    [nibTabViewEmpty addTabViewItem:item];

    [theWindow setFullPlatformWindow:YES];
}

- (void)tabView:(CPTabView)aTabView didSelectTabViewItem:(CPTabViewItem)tabViewItem
{
    CPLogConsole(_cmd + [tabViewItem label]);
}

- (void)tabView:(CPTabView)aTabView shouldSelectTabViewItem:(CPTabViewItem)tabViewItem
{
    return [tabViewItem identifier] != @"unselectable";
}

@end
