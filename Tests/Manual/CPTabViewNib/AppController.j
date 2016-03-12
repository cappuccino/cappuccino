/*
 * AppController.j
 * CPTabViewNib
 *
 * Created by Alexander Ljungberg on November 5, 2010.
 * Copyright 2010, WireLoad, LLC All rights reserved.
 */
@import <AppKit/AppKit.j>
@import <Foundation/CPObject.j>

CPLogRegister(CPLogConsole);

@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet     CPTabView nibTabView;
    @outlet     CPTabView nibTabViewEmpty;
    @outlet     CPViewController viewController;
    @outlet     CPStepper insertStepper;
    @outlet     CPStepper removeStepper;
    @outlet     CPButton fromViewController;
}

- (IBAction)insertTabViewItem:(id)sender
{
    var idx = [insertStepper intValue],
        item;

    if ([fromViewController state])
        item = [CPTabViewItem tabViewItemWithViewController:viewController];
    else
    {
        item = [[CPTabViewItem alloc] initWithIdentifier:@"Insert" + idx];
        var view = [[CPView alloc] initWithFrame:CGRectMakeZero()];
        [view setBackgroundColor:[CPColor randomColor]];
        [item setView:view];
        [item setLabel:@"Insert" + idx];
    }

    [nibTabView insertTabViewItem:item atIndex:idx];
}

- (IBAction)removeTabViewItem:(id)sender
{
    var idx = [removeStepper intValue],
        item = [nibTabView tabViewItemAtIndex:idx];

    [nibTabView removeTabViewItem:item];
}

- (IBAction)changeView:(id)sender
{
    var item = [nibTabView selectedTabViewItem];
    var view = [[CPView alloc] initWithFrame:CGRectMakeZero()];
    [view setBackgroundColor:[CPColor randomColor]];
    [item setView:view];
}

- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];
/*
    var item = [[CPTabViewItem alloc] initWithIdentifier:@"item"];
    [item setLabel:@"item"];
    [nibTabViewEmpty addTabViewItem:item];
*/
}

- (BOOL)tabView:(CPTabView)aTabView shouldSelectTabViewItem:(CPTabViewItem)tabViewItem
{
    var result = ([tabViewItem identifier] != @"unselectable");
    CPLog.debug(_cmd + [tabViewItem label] + " =" + result);

    return result;
}

- (void)tabView:(CPTabView)tabView willSelectTabViewItem:(CPTabViewItem)tabViewItem
{
    CPLog.debug(_cmd + [tabViewItem label]);
}

- (void)tabView:(CPTabView)aTabView didSelectTabViewItem:(CPTabViewItem)tabViewItem
{
    CPLog.debug(_cmd + [tabViewItem label]);
}

- (void)tabViewDidChangeNumberOfTabViewItems:(CPTabView)tabView
{
    CPLog.debug(_cmd + [tabView numberOfTabViewItems]);
}

@end
