/*
 * AppController.j
 * CPMenuRemoveAllTest
 *
 * Created by aparajita on May 11, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPMenu menu;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    menu = [[CPPopUpButton alloc] initWithFrame:CGRectMakeZero()];

    [self addStandardItems];
    [menu setPullsDown:YES];
    [menu sizeToFit];
    [menu setFrameSize:CGSizeMake(150, [menu frameSize].height)];
    [self setupAction];

    [menu setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [menu setCenter:[contentView center]];

    [contentView addSubview:menu];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}

- (void)addStandardItems
{
    [menu addItemsWithTitles:[@"One", @"Two", @"Alternate Items"]];
}

- (void)addAlternateItems
{
    [menu addItemsWithTitles:[@"Three", @"Four", @"Default Items"]];
}

- (void)setupAction
{
    var item = [menu itemAtIndex:2];

    [item setTarget:self];
    [item setAction:@selector(itemWasSelected:)];
}

- (void)itemWasSelected:(id)sender
{
    var title = [menu itemTitleAtIndex:0];

    [menu removeAllItems];

    if (title === @"One")
        [self addAlternateItems];
    else
        [self addStandardItems];

    [self setupAction];
}

@end
