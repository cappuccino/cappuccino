/*
 * AppController.j
 * CursorTest
 *
 * Created by You on November 6, 2009.
 * Copyright 2009, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>

var selectors = ["pointingHandCursor", "resizeDownCursor", "resizeLeftCursor", "resizeRightCursor", "resizeUpCursor", "resizeLeftRightCursor", "resizeUpDownCursor", "operationNotAllowedCursor", "dragCopyCursor", "dragLinkCursor", "contextualMenuCursor", "openHandCursor", "closedHandCursor", "disappearingItemCursor"];

@implementation AppController : CPObject
{
    CPPopUpButton popup;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    popup = [[CPPopUpButton alloc] initWithFrame:CGRectMake(100,100,150,24)];
    var menu = [popup menu];
    for (var i = 0 , count = [selectors count];i < count;i++)
    {   
        var selector = selectors[i];
        var item = [[CPMenuItem alloc] initWithTitle:selector action:nil keyEquivalent:@""];
        [item setTarget:self];
        [menu addItem:item];
    }
    [contentView addSubview:popup];
    
    var button = [[CPButton alloc] initWithFrame:CGRectMake(270,100,100,24)];
    [button setAction:@selector(setCursor:)];
    [button setTarget:self];
    [button setTitle:@"set Cursor"];
    [contentView addSubview:button];
    
    var button = [[CPButton alloc] initWithFrame:CGRectMake(270,150,150,24)];
    [button setAction:@selector(setUrlCursor:)];
    [button setTarget:self];
    [button setTitle:@"set Cursor from url"];
    [contentView addSubview:button];
    
    [theWindow orderFront:self];
    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

-(void)setCursor:(id)sender
{
    var selector = CPSelectorFromString([popup titleOfSelectedItem]);
    var cursor = [CPCursor performSelector:selector];
    [cursor set];
}

-(void)setUrlCursor:(id)sender
{   // note  gifs don't animate when they are used as a cursor.
    var aImage = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"spinner.gif"]];
    var cursor = [[CPCursor alloc] initWithImage:aImage hotSpot:CGPointMakeZero()];
    [cursor set];
}

@end
