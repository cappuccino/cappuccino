/*
 * AppController.j
 * CPTabView2
 *
 * Created by You on August 27, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPTabView.j>


@implementation AppController : CPObject

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    var tabView = [[CPTabView alloc] initWithFrame:CGRectMake(50,50,400,400)];
    [tabView setTabViewType:CPNoTabsBezelBorder];
    [tabView setTabViewType:CPTopTabsBezelBorder];

    var tabs = [
        "First Tab", "a label",
        "Second Tab", "another label",
        "Third Tab", "a third label",
        "Fourth Tab", "label 4",
        /*"5th Tab", "label 5",
        "6th Tab", "label 6",
        "7th Tab", "label 7",*/
        ];

    for (var i = 0; i < tabs.length; i += 2)
    {
        var view = [[CPView alloc] initWithFrame:CGRectMake(20, 20, 200, 200)];
        [view addSubview:[CPTextField labelWithTitle:tabs[i + 1]]];

        var item = [[CPTabViewItem alloc] initWithIdentifier:tabs[i]];
        [item setView:view];
        [item setLabel:tabs[i]];
        [tabView addTabViewItem:item];
    }

    [contentView addSubview:tabView];

    [tabView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    [theWindow orderFront:self];
}

@end
