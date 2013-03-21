/*
 * _CPShadowWindowView.j
 * AppKit
 *
 * Created by Alexandre Wilhelm.
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


@implementation _CPShadowWindowView : CPView
{
    _CPWindowView _windowView @accessors(setter=setWindowView:);
}

- (id)init
{
    if (self = [super init])
    {
    }
    return self;
}

+ (CPString)defaultThemeClass
{
    return @"shadow-window-view";
}

+ (id)themeAttributes
{
    return @{};
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    var bounds = [_windowView bounds],
        shadowDistance = [_windowView valueForThemeAttribute:@"shadow-distance"],
        shadowInset = [_windowView valueForThemeAttribute:@"shadow-inset"],
        size = [_windowView frameSize],
        shadowSize = CGSizeMake(size.width, size.height);

    // if the shadow would be taller/wider than the window height,
    // make it the same as the window height. this allows views to
    // become 0, 0 with no shadow on them and makes the sheet
    // animation look nicer
    if (size.width >= (shadowInset.left + shadowInset.right))
        shadowSize.width += shadowInset.left + shadowInset.right;
    else
        shadowSize.width = shadowInset.left + CGRectGetWidth(bounds) + shadowInset.right;

    if (size.height >= (shadowInset.bottom + shadowInset.top + shadowDistance))
        shadowSize.height += shadowInset.bottom + shadowInset.top + shadowDistance;
    else
        shadowSize.height = shadowInset.top + CGRectGetHeight(bounds) + shadowInset.bottom;

    [self setFrame:CGRectMake(-shadowInset.left, -shadowInset.top + shadowDistance, shadowSize.width, shadowSize.height)];
    [self setBackgroundColor:[_windowView valueForThemeAttribute:@"window-shadow-color"]];
}

@end
