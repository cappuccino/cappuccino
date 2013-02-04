/*
 * AppController.j
 * CPBoxTest
 *
 * Created by You on January 13, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPBox.j>


@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet     CPBox   box1;
    @outlet     CPView  documentView;
    @outlet     CPScrollView mainScrollView;
}

- (void)awakeFromCib
{
    [self makeRedViews];

    [[theWindow contentView] setBackgroundColor:[[CPColor greenColor] colorWithAlphaComponent:0.25]];

    [documentView setBackgroundColor:[CPColor whiteColor]];
    [mainScrollView setDocumentView:documentView];
    [theWindow setFullPlatformWindow:YES];
}

- (void)makeRedViews
{
    var subviews = [documentView subviews];

    for (var i = 0; i < [subviews count]; i++)
    {
        var subview = [subviews objectAtIndex:i];
        if ([subview tag] == "red")
            [subview setBackgroundColor:[CPColor redColor]];
    }
}

- (void)makeTransparentViews
{
    var subviews = [documentView subviews];

    for (var i = 0; i < [subviews count]; i++)
    {
        var subview = [subviews objectAtIndex:i];
        if ([subview tag] == "red")
            [subview setBackgroundColor:nil];
    }
}

- (IBAction)click:(id)sender
{
    [box1 setFrameFromContentFrame:CGRectMake(18, 81, 326, 133)];
}

- (IBAction)click2:(id)sender
{
    [box1 setFrameFromContentFrame:CGRectMake(18, 81, 300, 250)];
}

- (IBAction)change:(id)aSender
{
    var pos;

    switch ([aSender title])
    {
        case @"CPAtTop":
            pos = CPAtTop;
            break;
        case @"CPAtBottom":
            pos = CPAtBottom;
            break;
        case @"CPAboveBottom":
            pos = CPAboveBottom;
            break;
        case @"CPBelowBottom":
            pos = CPBelowBottom;
            break;
        case @"CPAboveTop":
            pos = CPAboveTop;
            break;
        case @"CPBelowTop":
            pos = CPBelowTop;
            break;
        case @"CPNoTitle":
            pos = CPNoTitle;
            break;
    }
    [box1 setTitlePosition:pos];
}

- (IBAction)switchBoxes:(id)aSender
{
    if ([aSender state])
        [self makeRedViews];
    else
        [self makeTransparentViews]
}
@end
