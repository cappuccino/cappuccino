/*
 * AppController.j
 * ScrollviewTheming
 *
 * Created by You on September 9, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    @outlet CPWindow                                _window @accessors(property=window);
    @outlet CPScrollView                            _scrollView @accessors(property=scrollView);
}

- (void)awakeFromCib
{
    [[self window] setFullBridge:YES];
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

- (@action)changeBorderWidth:(id)aSender
{
    [[self scrollView] setValue:[aSender integerValue] forThemeAttribute:@"line-border-width"];
}

@end
