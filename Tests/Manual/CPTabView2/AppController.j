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
{
    CPTabView tabView1;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    tabView1 = [[CPTabView alloc] initWithFrame:CGRectMake(50,50,400,400)];
    [tabView1 setTabViewType:CPNoTabsBezelBorder];
    [tabView1 setTabViewType:CPTopTabsBezelBorder];

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
        [tabView1 addTabViewItem:item];
    }

    [contentView addSubview:tabView1];

    [tabView1 setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    var toggleButton = [CPButton buttonWithTitle:@"Cycle Tab View Type"];
    [toggleButton setAction:@selector(switchTabType:)];
    [toggleButton setTarget:self];
    [toggleButton sizeToFit];
    [toggleButton setFrameOrigin:CGPointMake(CGRectGetWidth([contentView frame]) - CGRectGetWidth([toggleButton frame]) - 15, 15)];
    [toggleButton setAutoresizingMask:CPViewMinXMargin | CPViewMaxYMargin];
    [contentView addSubview:toggleButton];

    [theWindow orderFront:self];
}

- (@action)switchTabType:(id)sender
{
    [tabView1 setTabViewType:[tabView1 tabViewType] < CPNoTabsNoBorder ? [tabView1 tabViewType] + 1 : CPTopTabsBezelBorder];
}

@end
