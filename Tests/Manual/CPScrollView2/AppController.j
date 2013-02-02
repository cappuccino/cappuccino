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

    @outlet CPScrollView    scrollView2;
    @outlet CPView          contentView2;

    CPColor lightBackground;
}

- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];

    lightBackground = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"photo.jpg"]]];
    [contentView setBackgroundColor:lightBackground];
    [contentView setAutoresizingMask:CPViewWidthSizable];

    [scrollView setDocumentView:contentView];
    [contentView2 setAutoresizingMask:CPViewWidthSizable];
    [scrollView2 setDocumentView:contentView2];
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

    switch (style)
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

    switch (style)
    {
        case "Light":
            [[scrollView documentView] setBackgroundColor:lightBackground];
            break;

        case "Dark":
            [[scrollView documentView] setBackgroundColor:[CPColor colorWithHexString:@"333"]];
            break;
    }
}

- (IBAction)makeBigDocView:(id)aSender
{
    [contentView setFrameSize:CGSizeMake(1000, 1000)];
}

- (IBAction)makeSmallDocView:(id)aSender
{
    [contentView setFrameSize:CGSizeMake(200, 200)];
}

- (IBAction)makeNarrowDocView:(id)aSender
{
    [contentView setFrameSize:CGSizeMake(200, 1000)];
}

- (IBAction)makeShortDocView:(id)aSender
{
    [contentView setFrameSize:CGSizeMake(1000, 200)];
}

- (IBAction)flash:(id)aSender
{
    [scrollView flashScrollers];
}


/*! documentation
    @param aSender the sender of the action
*/
- (IBAction)changeSystemWideScrollerStyle:(id)aSender
{
    if ([CPScrollView globalScrollerStyle] == CPScrollerStyleOverlay)
        [CPScrollView setGlobalScrollerStyle:CPScrollerStyleLegacy];
    else
        [CPScrollView setGlobalScrollerStyle:CPScrollerStyleOverlay];
}

@end
