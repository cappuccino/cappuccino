/*
 * CPShadowView.j
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

@import <Foundation/CPBundle.j>

@import "CGGeometry.j"
@import "CPImage.j"
@import "CPView.j"


CPLightShadow   = 0;
CPHeavyShadow   = 1;

CPThemeStateShadowViewLight = CPThemeState("shadowview-style-light");
CPThemeStateShadowViewHeavy = CPThemeState("shadowview-style-heavy");


/*!
    @ingroup appkit
*/
@implementation CPShadowView : CPView
{
    CPShadowWeight  _weight;
}

+ (CPString)defaultThemeClass
{
    return "shadow-view";
}

+ (id)themeAttributes
{
    return @{
            @"bezel-color": [CPNull null],
            @"content-inset": CGInsetMakeZero()
        };
}

+ (CGRect)frameForContentFrame:(CGRect)aFrame withWeight:(CPShadowWeight)aWeight
{
    var shadowView = [CPShadowView new],
        inset = [shadowView valueForThemeAttribute:@"content-inset" inState:(aWeight == CPLightShadow) ? CPThemeStateShadowViewLight : CPThemeStateShadowViewHeavy];

    return CGRectMake(CGRectGetMinX(aFrame) - inset.left, CGRectGetMinY(aFrame) - inset.top, CGRectGetWidth(aFrame) + inset.left + inset.right, CGRectGetHeight(aFrame) + inset.top + inset.bottom);
}

+ (id)shadowViewEnclosingView:(CPView)aView
{
    return [self shadowViewEnclosingView:aView withWeight:CPLightShadow];
}

+ (id)shadowViewEnclosingView:(CPView)aView withWeight:(CPShadowWeight)aWeight
{
    var shadowView = [[self alloc] initWithFrame:[aView frame]];

    if (shadowView)
    {
        [shadowView setWeight:aWeight];

        var size = [shadowView frame].size,
            inset = [shadowView currentValueForThemeAttribute:@"content-inset"],
            width = size.width - inset.left - inset.right,
            height = size.height - inset.top - inset.bottom,
            enclosingView = [aView superview];

        [shadowView setHitTests:[aView hitTests]];
        [shadowView setAutoresizingMask:[aView autoresizingMask]];
        [aView removeFromSuperview];
        [shadowView addSubview:aView];
        [aView setFrame:CGRectMake(inset.left, inset.top, width, height)];
        [enclosingView addSubview:shadowView];
    }

    return shadowView;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        [self setWeight:CPLightShadow];

        [self setHitTests:NO];
    }

    return self;
}

- (void)setWeight:(CPShadowWeight)aWeight
{
    if (_weight == aWeight)
        return;

    _weight = aWeight;

    if (_weight == CPLightShadow)
        [self setThemeState:CPThemeStateShadowViewLight];
    else
        [self setThemeState:CPThemeStateShadowViewHeavy];

    [self setNeedsLayout];
}

- (float)leftInset
{
    return [self currentValueForThemeAttribute:@"content-inset"].left;
}

- (float)rightInset
{
    return [self currentValueForThemeAttribute:@"content-inset"].right;
}

- (float)topInset
{
    return [self currentValueForThemeAttribute:@"content-inset"].top;
}

- (float)bottomInset
{
    return [self currentValueForThemeAttribute:@"content-inset"].bottom;
}

- (float)horizontalInset
{
    var currentContentInset = [self currentValueForThemeAttribute:@"content-inset"];

    return currentContentInset.left + currentContentInset.right;
}

- (float)verticalInset
{
    var currentContentInset = [self currentValueForThemeAttribute:@"content-inset"];

    return currentContentInset.top + currentContentInset.bottom;
}

- (CGRect)frameForContentFrame:(CGRect)aFrame
{
    return [[self class] frameForContentFrame:aFrame withWeight:_weight];
}

- (void)setFrameForContentFrame:(CGRect)aFrame
{
    [self setFrame:[self frameForContentFrame:aFrame]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self setBackgroundColor:[self currentValueForThemeAttribute:@"bezel-color"]];
}

@end
