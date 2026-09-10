/*
 * AppController.j
 * CPSplitViewDivider
 *
 * Created by You on January 12, 2016.
 * Copyright 2016, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    @outlet CPSplitView     splitView;
    @outlet CPView          viewLeft;
    @outlet CPView          viewRight;
    @outlet CPWindow        theWindow;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
}

- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];
    [viewLeft setBackgroundColor:[CPColor grayColor]];
    [viewRight setBackgroundColor:[CPColor greenColor]];
}

- (@action)clickChangeButton:(id)aSender
{
    if (![viewRight superview])
    {
        console.log(@"Add viewRight in splitView");
        [splitView addSubview:viewRight];
    }
    else
    {
        console.error(@"Remove viewRight from splitView");
        [viewRight removeFromSuperview];
    }
}


@end
