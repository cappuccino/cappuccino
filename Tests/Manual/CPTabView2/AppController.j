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

	var view = [[CPView alloc] initWithFrame:CGRectMake(20, 20, 200, 200)];
	[view addSubview:[CPTextField labelWithTitle:@"First"]];
	var item = [[CPTabViewItem alloc] initWithIdentifier:@"a"];
	[item setView:view];
	[item setLabel:"Test"];
	[tabView addTabViewItem:item];

	view = [[CPView alloc] initWithFrame:CGRectMake(20, 20, 200, 200)];
	[view addSubview:[CPTextField labelWithTitle:@"Second"]];
	item = [[CPTabViewItem alloc] initWithIdentifier:@"a"];
	[item setView:view];
	[item setLabel:"Test2"];
	[tabView addTabViewItem:item];

	[contentView addSubview:tabView];

	[tabView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    [theWindow orderFront:self];
}

@end
