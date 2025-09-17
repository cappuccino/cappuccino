/*
 * AppController.j
 * CPMenuTest
 *
 * Created by Blair Duncan on April 23, 2012.
 * Copyright 2012, SGL Studio, BBDO Toronto All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        popupButton = [[CPPopUpButton alloc] initWithFrame:CGRectMakeZero()];

    [popupButton addItemsWithTitles:[[CPFontManager sharedFontManager] availableFonts]];
    [popupButton sizeToFit];

    [popupButton setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [popupButton setCenter:[contentView center]];

    [contentView addSubview:popupButton];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}


@end
