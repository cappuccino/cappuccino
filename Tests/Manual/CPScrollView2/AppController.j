/*
 * AppController.j
 * scrollview
 *
 * Created by You on October 3, 2011.
 * Copyright 2011, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow                theWindow; //this "outlet" is connected automatically by the Cib
    @outlet CPScrollView    scrollView;
    @outlet CPView          contentView;
}

- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];

    [contentView setBackgroundColor:[CPColor colorWithHexString:@"f3f3f3"]];
    [contentView setAutoresizingMask:CPViewWidthSizable];
    // [scrollView setAutohidesScrollers:YES];
    [scrollView setDocumentView:contentView];
}

- (IBAction)change:(id)aSender
{
    if ([scrollView scrollerStyle] == CPScrollerStyleLegacy)
        [scrollView setScrollerStyle:CPScrollerStyleOverlay];
    else
        [scrollView setScrollerStyle:CPScrollerStyleLegacy];
}

- (IBAction)changeKnob:(id)aSender
{
    var style = [aSender title];

    switch(style)
    {
        case "Default":
            [scrollView setScrollerKnobStyle:CPScrollerKnobStyleDefault];
            break;
        case "Dark":
            [scrollView setScrollerKnobStyle:CPScrollerKnobStyleDark];
            break;
        case "Light":
            [scrollView setScrollerKnobStyle:CPScrollerKnobStyleLight];
            break;
    }
}

- (IBAction)changeBackground:(id)aSender
{
    var style = [aSender title];

    switch(style)
    {
        case "Light":
            [[scrollView documentView] setBackgroundColor:[CPColor colorWithHexString:@"f3f3f3"]];
            break;
        case "Dark":
            [[scrollView documentView] setBackgroundColor:[CPColor colorWithHexString:@"333"]];
            break;
    }
}

- (IBAction)makeBigDocView:(id)aSender
{
    [contentView setFrameSize:CPSizeMake(1000, 1000)];
}

- (IBAction)makeSmallDocView:(id)aSender
{
    [contentView setFrameSize:CPSizeMake(30, 30)];
}

- (IBAction)flash:(id)aSender
{
    [scrollView flashScrollers];
}

@end
