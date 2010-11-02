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
@import "CPImageView.j"
@import "CPView.j"


CPLightShadow   = 0;
CPHeavyShadow   = 1;

var CPShadowViewLightBackgroundColor    = nil,
    CPShadowViewHeavyBackgroundColor    = nil;

var LIGHT_LEFT_INSET    = 3.0,
    LIGHT_RIGHT_INSET   = 3.0,
    LIGHT_TOP_INSET     = 3.0,
    LIGHT_BOTTOM_INSET  = 5.0,

    HEAVY_LEFT_INSET    = 7.0,
    HEAVY_RIGHT_INSET   = 7.0,
    HEAVY_TOP_INSET     = 5.0,
    HEAVY_BOTTOM_INSET  = 5.0;

/*!
    @ingroup appkit
*/

@implementation CPShadowView : CPView
{
    CPShadowWeight  _weight;
}

+ (void)initialize
{
    if (self != [CPShadowView class])
        return;

    var bundle = [CPBundle bundleForClass:[self class]];

    CPShadowViewLightBackgroundColor = [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:
        [
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewLightTopLeft.png"] size:CGSizeMake(9.0, 9.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewLightTop.png"] size:CGSizeMake(1.0, 9.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewLightTopRight.png"] size:CGSizeMake(9.0, 9.0)],

            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewLightLeft.png"] size:CGSizeMake(9.0, 1.0)],
            nil,
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewLightRight.png"] size:CGSizeMake(9.0, 1.0)],

            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewLightBottomLeft.png"] size:CGSizeMake(9.0, 9.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewLightBottom.png"] size:CGSizeMake(1.0, 9.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewLightBottomRight.png"] size:CGSizeMake(9.0, 9.0)]
        ]]];

    CPShadowViewHeavyBackgroundColor = [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:
        [
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewHeavyTopLeft.png"] size:CGSizeMake(17.0, 17.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewHeavyTop.png"] size:CGSizeMake(1.0, 17.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewHeavyTopRight.png"] size:CGSizeMake(17.0, 17.0)],

            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewHeavyLeft.png"] size:CGSizeMake(17.0, 1.0)],
            nil,
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewHeavyRight.png"] size:CGSizeMake(17.0, 1.0)],

            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewHeavyBottomLeft.png"] size:CGSizeMake(17.0, 17.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewHeavyBottom.png"] size:CGSizeMake(1.0, 17.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPShadowView/CPShadowViewHeavyBottomRight.png"] size:CGSizeMake(17.0, 17.0)]
        ]]];
}

+ (id)shadowViewEnclosingView:(CPView)aView
{
    return [self shadowViewEnclosingView:aView withWeight:CPLightShadow];
}

+ (id)shadowViewEnclosingView:(CPView)aView withWeight:(CPShadowWeight)aWeight
{
    var shadowView = [[CPShadowView alloc] initWithFrame:[aView frame]];
    [shadowView setWeight:aWeight];

    var size = [shadowView frame].size,
        width = size.width - [shadowView leftInset] - [shadowView rightInset],
        height = size.height - [shadowView topInset] - [shadowView bottomInset],
        enclosingView = [aView superview];

    [shadowView setHitTests:[aView hitTests]];
    [shadowView setAutoresizingMask:[aView autoresizingMask]];
    [aView removeFromSuperview];
    [shadowView addSubview:aView];
    [aView setFrame:CGRectMake([shadowView leftInset], [shadowView topInset], width, height)]
    [enclosingView addSubview:shadowView];

    return shadowView;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _weight = CPLightShadow;

        [self setBackgroundColor:CPShadowViewLightBackgroundColor];

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
        [self setBackgroundColor:CPShadowViewLightBackgroundColor];

    else
        [self setBackgroundColor:CPShadowViewHeavyBackgroundColor];
}

- (float)leftInset
{
    return _weight == CPLightShadow ? LIGHT_LEFT_INSET : HEAVY_LEFT_INSET;
}

- (float)rightInset
{
    return _weight == CPLightShadow ? LIGHT_RIGHT_INSET : HEAVY_RIGHT_INSET;
}

- (float)topInset
{
    return _weight == CPLightShadow ? LIGHT_TOP_INSET : HEAVY_TOP_INSET;
}

- (float)bottomInset
{
    return _weight == CPLightShadow ? LIGHT_BOTTOM_INSET : HEAVY_BOTTOM_INSET;
}

- (float)horizontalInset
{
    if (_weight == CPLightShadow)
        return LIGHT_LEFT_INSET + LIGHT_RIGHT_INSET;

    return HEAVY_LEFT_INSET + HEAVY_RIGHT_INSET;
}

- (float)verticalInset
{
    if (_weight == CPLightShadow)
        return LIGHT_TOP_INSET + LIGHT_BOTTOM_INSET;

    return HEAVY_TOP_INSET + HEAVY_BOTTOM_INSET;
}

+ (CGRect)frameForContentFrame:(CGRect)aFrame withWeight:(CPShadowWeight)aWeight
{
    if (aWeight == CPLightShadow)
        return CGRectMake(_CGRectGetMinX(aFrame) - LIGHT_LEFT_INSET, _CGRectGetMinY(aFrame) - LIGHT_TOP_INSET, _CGRectGetWidth(aFrame) + LIGHT_LEFT_INSET + LIGHT_RIGHT_INSET, _CGRectGetHeight(aFrame) + LIGHT_TOP_INSET + LIGHT_BOTTOM_INSET);
    else
        return CGRectMake(_CGRectGetMinX(aFrame) - HEAVY_LEFT_INSET, _CGRectGetMinY(aFrame) - HEAVY_TOP_INSET, _CGRectGetWidth(aFrame) + HEAVY_LEFT_INSET + HEAVY_RIGHT_INSET, _CGRectGetHeight(aFrame) + HEAVY_TOP_INSET + HEAVY_BOTTOM_INSET);
}

- (CGRect)frameForContentFrame:(CGRect)aFrame
{
    return [[self class] frameForContentFrame:aFrame withWeight:_weight];
}

- (void)setFrameForContentFrame:(CGRect)aFrame
{
    [self setFrame:[self frameForContentFrame:aFrame]];
}

@end
