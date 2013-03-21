/*
 * _CPDocModalWindowView.j
 * AppKit
 *
 * Created by Ross Boucher.
 * Copyright 2009, 280 North, Inc.
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


@implementation _CPDocModalWindowView : _CPWindowView
{
    CPView _bodyView;
}

+ (CPString)defaultThemeClass
{
    return @"doc-modal-window-view";
}

+ (id)themeAttributes
{
    return @{
            @"body-color": [CPColor whiteColor],
            @"shadow-height": 8,
        };
}

+ (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    /*
        This window view class draws a frame.
        So we have to inset the content rect to be inside the frame.
    */
    var contentRect = [super contentRectForFrameRect:aFrameRect];

    return CGRectInset(contentRect, 1.0, 1.0);
}

- (id)initWithFrame:(CGRect)aFrame styleMask:(unsigned)aStyleMask
{
    self = [super initWithFrame:aFrame styleMask:aStyleMask];

    if (self)
    {
        var bounds = [self bounds];

        _bodyView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), CGRectGetHeight(bounds))];

        [_bodyView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [_bodyView setHitTests:NO];

        [self addSubview:_bodyView];
    }

    return self;
}

- (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    return [[self class] contentRectForFrameRect:aFrameRect];
}

- (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    return [[self class] frameRectForContentRect:aContentRect];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    var bounds = [self bounds];

    [_bodyView setBackgroundColor:[self valueForThemeAttribute:@"body-color"]];
}

- (int)bodyOffset
{
    return [_bodyView frame].origin.y;
}

@end

