/*
 * CPBox.j
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

@import "CPGraphics.j"
@import "CPView.j"

#include "CoreGraphics/CGGeometry.h"

// CPBorderType
CPNoBorder      = 0;
CPLineBorder    = 1;
CPBezelBorder   = 2;
CPGrooveBorder  = 3;

@implementation CPBox : CPView
{
    CPBorderType    _borderType;

    CPColor         _borderColor;
    CPColor         _fillColor;

    float           _cornerRadius;
    float           _borderWidth;

    CPSize          _contentMargin;
    CPView          _contentView;
}

+ (id)boxEnclosingView:(CPView)aView
{
    var box = [[self alloc] initWithFrame:_CGRectMakeZero()],
        enclosingView = [aView superview];

    [box setFrameFromContentFrame:[aView frame]];

    [enclosingView replaceSubview:aView with:box];

    [box setContentView:aView];

    return box;
}

- (id)initWithFrame:(CPRect)frameRect
{
    self = [super initWithFrame:frameRect];

    if (self)
    {
        _borderType = CPBezelBorder;
        _fillColor = [CPColor colorWithWhite:0.75 alpha:0.1];
        _borderColor = [CPColor blackColor];

        _borderWidth = 1.0;
        _contentMargin = _CGSizeMake(0.0, 0.0);

        _contentView = [[CPView alloc] initWithFrame:[self bounds]];
        [_contentView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
        [self addSubview:_contentView];

        [_contentView setAutoresizesSubviews:YES];
        [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    }

    return self;
}

// Configuring Boxes

- (CPRect)borderRect
{
    return [self bounds];
}

- (CPBorderType)borderType
{
    return _borderType;
}

- (void)setBorderType:(CPBorderType)value
{
    _borderType = value;
    [self setNeedsDisplay:YES];
}

- (CPColor)borderColor
{
    return _borderColor;
}

- (void)setBorderColor:(CPColor)color
{
    if ([color isEqual:_borderColor])
        return;

    _borderColor = color;
    [self setNeedsDisplay:YES];
}

- (float)borderWidth
{
    return _borderWidth;
}

- (void)setBorderWidth:(float)width
{
    if (width === _borderWidth)
        return;

    _borderWidth = width;
    [self setNeedsDisplay:YES];
}

- (float)cornerRadius
{
    return _cornerRadius;
}

- (void)setCornerRadius:(float)radius
{
    if (radius === _cornerRadius)
        return;

    _cornerRadius = radius;
    [self setNeedsDisplay:YES];
}

- (CPColor)fillColor
{
    return _fillColor;
}

- (void)setFillColor:(CPColor)color
{
    if ([color isEqual:_fillColor])
        return;

    _fillColor = color;
    [self setNeedsDisplay:YES];
}

- (CPView)contentView
{
    return _contentView;
}

- (void)setContentView:(CPView)aView
{
    if (aView === _contentView)
        return;

    [aView setFrame:_CGRectInset([self bounds], _contentMargin.width + _borderWidth, _contentMargin.height + _borderWidth)];
    [aView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
    [aView setAutoresizesSubviews:YES];
    [self replaceSubview:_contentView with:aView];

    _contentView = aView;
}

- (CPSize)contentViewMargins
{
    return _contentMargin;
}

- (void)setContentViewMargins:(CPSize)size
{
     if (size.width < 0 || size.height < 0)
         [CPException raise:CPGenericException reason:@"Margins must be positive"];

    _contentMargin = _CGSizeMakeCopy(size);
    [self setNeedsDisplay:YES];
}

- (void)setFrameFromContentFrame:(CPRect)aRect
{
    [self setFrame:_CGRectInset(aRect, -(_contentMargin.width + _borderWidth), -(_contentMargin.height + _borderWidth))];
    [self setNeedsDisplay:YES];
}

- (void)sizeToFit
{
    var contentFrameSize = [_contentView frameSize];

    [self setFrameSize:_CGSizeMake(contentFrameSize.width + (_contentMargin.width * 2),
                                   contentFrameSize.height + (_contentMargin.height * 2))];

    [_contentView setFrameOrigin:_CGPointMake(_contentMargin.width, _contentMargin.height)];
}

- (void)drawRect:(CPRect)rect
{
    var bounds = [self bounds],
        context = [[CPGraphicsContext currentContext] graphicsPort],
        strokeRect = _CGRectInset(bounds, _borderWidth / 2.0, _borderWidth / 2.0),
        fillRect = _CGRectInset(bounds, _borderWidth, _borderWidth);

    CGContextSetFillColor(context, [self fillColor]);
    CGContextSetStrokeColor(context, [self borderColor]);
    CGContextSetLineWidth(context, _borderWidth);

    switch(_borderType)
    {
        case CPNoBorder:
        case CPLineBorder:
            CGContextFillRoundedRectangleInRect(context, fillRect, _cornerRadius, YES, YES, YES, YES);

            if (_borderType === CPLineBorder)
                CGContextStrokeRoundedRectangleInRect(context, strokeRect, _cornerRadius, YES, YES, YES, YES);
            break;

        case CPBezelBorder:
            CGContextFillRoundedRectangleInRect(context, fillRect, _cornerRadius, YES, YES, YES, YES);
            CPDrawGrayBezel(bounds);
            break;

        default:
            break;
    }
}

@end

var CPBoxBorderTypeKey    = @"CPBoxBorderTypeKey",
    CPBoxBorderColorKey   = @"CPBoxBorderColorKey",
    CPBoxFillColorKey     = @"CPBoxFillColorKey",
    CPBoxCornerRadiusKey  = @"CPBoxCornerRadiusKey",
    CPBoxBorderWidthKey   = @"CPBoxBorderWidthKey",
    CPBoxContentMarginKey = @"CPBoxContentMarginKey";

@implementation CPBox (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _borderType    = [aCoder decodeIntForKey:CPBoxBorderTypeKey];

        _borderColor   = [aCoder decodeObjectForKey:CPBoxBorderColorKey];
        _fillColor     = [aCoder decodeObjectForKey:CPBoxFillColorKey];

        _cornerRadius  = [aCoder decodeFloatForKey:CPBoxCornerRadiusKey];
        _borderWidth   = [aCoder decodeFloatForKey:CPBoxBorderWidthKey];

        _contentMargin = [aCoder decodeSizeForKey:CPBoxContentMarginKey];

        _contentView   = [self subviews][0];

        [self setAutoresizesSubviews:YES];
        [_contentView setAutoresizesSubviews:YES];
        [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInt:_borderType forKey:CPBoxBorderTypeKey];

    [aCoder encodeObject:_borderColor forKey:CPBoxBorderColorKey];
    [aCoder encodeObject:_fillColor forKey:CPBoxFillColorKey];

    [aCoder encodeFloat:_cornerRadius forKey:CPBoxCornerRadiusKey];
    [aCoder encodeFloat:_borderWidth forKey:CPBoxBorderWidthKey];

    [aCoder encodeSize:_contentMargin forKey:CPBoxContentMarginKey];
}

@end
