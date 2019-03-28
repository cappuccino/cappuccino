/*
 * _CPBorderlessWindowView.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "_CPWindowView.j"

@implementation _CPBorderlessBridgeWindowView : _CPWindowView
{
    CPView  _toolbarBackgroundView;
}

+ (CPString)defaultThemeClass
{
    return @"borderless-bridge-window-view";
}

+ (CPDictionary)themeAttributes
{
    return @{
            @"toolbar-background-color": [CPColor grayColor],
        };
}

- (void)setShowsResizeIndicator:(BOOL)shouldShowResizeIndicator
{
    // We don't ever want to show the resize indicator.
}

- (void)tile
{
    [super tile];

    var theWindow = [self window],
        bounds = [self bounds];

    [[theWindow contentView] setFrame:CGRectMake(0.0, [self toolbarMaxY], CGRectGetWidth(bounds), CGRectGetHeight(bounds) - [self toolbarMaxY])];

    if (![[theWindow toolbar] isVisible])
    {
        [_toolbarBackgroundView removeFromSuperview];

        _toolbarBackgroundView = nil;

        return;
    }

    if (!_toolbarBackgroundView)
    {
        _toolbarBackgroundView = [[CPView alloc] initWithFrame:CGRectMakeZero()];

        [_toolbarBackgroundView setBackgroundColor:[self valueForThemeAttribute:@"toolbar-background-color"]];
        [_toolbarBackgroundView setAutoresizingMask:CPViewWidthSizable];

        [self addSubview:_toolbarBackgroundView positioned:CPWindowBelow relativeTo:nil];
    }

    var frame = CGRectMakeZero(),
        toolbarOffset = [self toolbarOffset];

    frame.origin = CGPointMake(toolbarOffset.width, toolbarOffset.height);
    frame.size = [_toolbarView frame].size;

    [_toolbarBackgroundView setFrame:frame];
}

- (void)setFrameSize:(CGSize)aFrameSize
{
    [super setFrameSize:aFrameSize];

    var theWindow = [self window];

    if (_frame.size.width < theWindow._minSize.width || _frame.size.height < theWindow._minSize.height)
        [theWindow._contentView setFrameSize:CGSizeMake(MAX(_frame.size.width, theWindow._minSize.width), MAX(_frame.size.height, theWindow._minSize.height))];

#if PLATFORM(DOM)
    _DOMElement.style.overflowX = (_frame.size.width < theWindow._minSize.width)? "scroll":"hidden";
    _DOMElement.style.overflowY = (_frame.size.height < theWindow._minSize.height)? "scroll":"hidden";
#endif
}

@end
