/*
 * AppController.j
 * TableCibTest
 *
 * Created by Francisco Tolmasky on July 5, 2009.
 * Copyright 2009, 280 North, Inc. All rights reserved.
 */

@import <Foundation/CPObject.j>

CPLogRegister(CPLogConsole);

@implementation AppController : CPObject
{
    CPWindow        theWindow; //this "outlet" is connected automatically by the Cib
    CPScrollView    theScrollView;
    CPTableView     theTableView;
    CPPopupButton   theBorderTypePopup;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];

    [theWindow setBackgroundColor:[CPColor colorWithHexString:@"f3f4f5"]];

    [theBorderTypePopup selectItemWithTag:[theScrollView borderType]];
}

- (int)numberOfRowsInTableView:(CPTableView)tableView
{
    return 10;
}

- (id)tableView:(CPTableView)tableView objectValueForTableColumn:(CPTableColumn)tableColumn row:(CPInteger)row
{
    return String((row + 1) * [[tableColumn identifier] intValue]);
}

// Actions

- (void)setBorder:(id)sender
{
    var type = [[sender selectedItem] tag];
    console.log('type=%d', type);

    [theScrollView setBorderType:type];
}

@end