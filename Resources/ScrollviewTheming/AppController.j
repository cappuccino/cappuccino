/*
 * AppController.j
 * ScrollviewTheming
 *
 * Created by You on September 9, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import "DocumentView.j"

@implementation AppController : CPObject
{
    @outlet CPWindow                                _window @accessors(property=window);
    @outlet CPScrollView                            _scrollView @accessors(property=scrollView);
}

- (void)awakeFromCib
{
    var headerView = [[CPView alloc] initWithFrame:CGRectMakeZero()];
    [headerView setBackgroundColor:[CPColor blueColor]];

    [[self window] setFullPlatformWindow:YES];
}

- (@action)changeBorderType:(id)aSender
{
    var borderType = CPNoBorder;

    switch ([aSender title])
    {
        default:
        case @"CPNoBorder":
            borderType = CPNoBorder;
            break;

        case @"CPLineBorder":
            borderType = CPLineBorder;
            break;

        case @"CPBezelBorder":
            borderType = CPBezelBorder;
            break;

        case @"CPGrooveBorder":
            borderType = CPGrooveBorder;
            break;
    }

    [[self scrollView] setBorderType:borderType];
}

- (@action)toggleHeaderView:(id)aSender
{
    [[[self scrollView] documentView] setShowHeaderView:[aSender objectValue]];
    [[self scrollView] _updateCornerAndHeaderView];
}

- (@action)changeBorderColor:(id)aSender
{
    [[self scrollView] setValue:[aSender color] forThemeAttribute:@"border-color"];
}

@end
