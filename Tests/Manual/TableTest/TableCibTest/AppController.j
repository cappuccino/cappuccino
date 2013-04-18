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
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    CPImage     iconImage;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
    iconImage = [[CPImage alloc] initWithContentsOfFile:"http://cappuccino-project.org/img/favicon.ico" size:CGSizeMake(16,16)];
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

- (int)numberOfRowsInTableView:(CPTableView)tableView
{
    return 100000;
}

- (id)tableView:(CPTableView)tableView objectValueForTableColumn:(CPTableColumn)tableColumn row:(int)row
{
    if ([tableColumn identifier] === "icons")
        return iconImage;
    else
        return String((row + 1) * [[tableColumn identifier] intValue]);
}

- (BOOL)tableView:(CPTableView)tableView shouldReorderColumn:(int)columnIndex toColumn:(int)newColumnIndex
{
    if (columnIndex === 0 || newColumnIndex === 4)
        return NO;
    else
        return YES;
}

@end