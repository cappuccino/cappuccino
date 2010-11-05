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

@import "CPView.j"

// CPBoxType
CPBoxPrimary    = 0;
CPBoxSecondary  = 1;
CPBoxSeperator  = 2;
CPBoxOldStyle   = 3;
CPBoxCustom     = 4;

// CPBorderType
CPNoBorder      = 0;
CPLineBorder    = 1;
CPBezelBorder   = 2;
CPGrooveBorder  = 3;

@implementation CPBox : CPView
{
    CPBoxType       _boxType;
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
    var box = [[self alloc] initWithFrame:CGRectMakeZero()],
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
        _fillColor = [CPColor clearColor];
        _borderColor = [CPColor blackColor];

        _borderWidth = 1.0;
        _contentMargin = CGSizeMake(0.0, 0.0);

        _contentView = [[CPView alloc] initWithFrame:[self bounds]];
        [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

        [self setAutoresizesSubviews:YES];
        [self addSubview:_contentView];
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

- (void)setBorderType:(CPBorderType)aBorderType
{
    if (_borderType === aBorderType)
        return;

    _borderType = aBorderType;
    [self setNeedsDisplay:YES];
}

- (CPBoxType)boxType
{
    return _boxType;
}

- (void)setBoxType:(CPBoxType)aBoxType
{
    if (_boxType === aBoxType)
        return;

    _boxType = aBoxType;
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

    [aView setFrame:CGRectInset([self bounds], _contentMargin.width + _borderWidth, _contentMargin.height + _borderWidth)];
    [aView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
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

    _contentMargin = CGSizeMakeCopy(size);
    [self setNeedsDisplay:YES];
}

- (void)setFrameFromContentFrame:(CPRect)aRect
{
    [self setFrame:CGRectInset(aRect, -(_contentMargin.width + _borderWidth), -(_contentMargin.height + _borderWidth))];
    [self setNeedsDisplay:YES];
}

- (void)sizeToFit
{
    var contentFrame = [_contentView frame];

    [self setFrameSize:CGSizeMake(contentFrame.size.width + _contentMargin.width * 2,
                                  contentFrame.size.height + _contentMargin.height * 2)];

    [_contentView setFrameOrigin:CGPointMake(_contentMargin.width, _contentMargin.height)];
}

- (void)drawRect:(CPRect)rect
{
    if (_borderType === CPNoBorder)
        return;

    var bounds = [self bounds];

    switch (_boxType)
    {
        case CPBoxSeperator:
            // NSBox does not include a horitontal flag for the seperator type. We have to determine
            // the type of seperator to draw by the width and height of the frame.
            if (CGRectGetWidth(bounds) === 5.0)
                return [self _drawVerticalSeperatorInRect:bounds];
            else if (CGRectGetHeight(bounds) === 5.0)
                return [self _drawHorizontalSeperatorInRect:bounds];

            break;
    }

    switch (_borderType)
    {
        case CPBezelBorder:
            [self _drawBezelBorderInRect:bounds];
            break;

        default:
        case CPLineBorder:
            [self _drawLineBorderInRect:bounds];
            break;
    }
}

- (void)_drawHorizontalSeperatorInRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetStrokeColor(context, [self borderColor]);
    CGContextSetLineWidth(context, 1.0);

    CGContextMoveToPoint(context, CGRectGetMinX(aRect), CGRectGetMinY(aRect) + 0.5);
    CGContextAddLineToPoint(context, CGRectGetWidth(aRect), CGRectGetMinY(aRect) + 0.5);
    CGContextStrokePath(context);
}

- (void)_drawVerticalSeperatorInRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetStrokeColor(context, [self borderColor]);
    CGContextSetLineWidth(context, 1.0);

    CGContextMoveToPoint(context, CGRectGetMinX(aRect) + 0.5, CGRectGetMinY(aRect));
    CGContextAddLineToPoint(context, CGRectGetMinX(aRect) + 0.5, CGRectGetHeight(aRect));
    CGContextStrokePath(context);
}

- (void)_drawBezelBorderInRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        sides = [CPMinYEdge, CPMaxXEdge, CPMaxYEdge, CPMinXEdge],
        sideGray = 190.0 / 255.0,
        grays = [142.0 / 255.0, sideGray, sideGray, sideGray],
        borderWidth = _borderWidth;

    while (borderWidth--)
        aRect = CPDrawTiledRects(aRect, aRect, sides, grays);

    CGContextSetFillColor(context, [self fillColor]);
    CGContextFillRect(context, aRect);
}

- (void)_drawLineBorderInRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];

    aRect = CGRectInset(aRect, _borderWidth / 2.0, _borderWidth / 2.0);

    CGContextSetFillColor(context, [self fillColor]);
    CGContextSetStrokeColor(context, [self borderColor]);

    CGContextSetLineWidth(context, _borderWidth);
    CGContextFillRoundedRectangleInRect(context, aRect, _cornerRadius, YES, YES, YES, YES);
    CGContextStrokeRoundedRectangleInRect(context, aRect, _cornerRadius, YES, YES, YES, YES);
}

@end

var CPBoxTypeKey          = @"CPBoxTypeKey",
    CPBoxBorderTypeKey    = @"CPBoxBorderTypeKey",
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
        _boxType       = [aCoder decodeIntForKey:CPBoxTypeKey];
        _borderType    = [aCoder decodeIntForKey:CPBoxBorderTypeKey];

        _borderColor   = [aCoder decodeObjectForKey:CPBoxBorderColorKey];
        _fillColor     = [aCoder decodeObjectForKey:CPBoxFillColorKey];

        _cornerRadius  = [aCoder decodeFloatForKey:CPBoxCornerRadiusKey];
        _borderWidth   = [aCoder decodeFloatForKey:CPBoxBorderWidthKey];

        _contentMargin = [aCoder decodeSizeForKey:CPBoxContentMarginKey];

        _contentView   = [self subviews][0];

        [self setAutoresizesSubviews:YES];
        [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInt:_boxType forKey:CPBoxTypeKey];
    [aCoder encodeInt:_borderType forKey:CPBoxBorderTypeKey];

    [aCoder encodeObject:_borderColor forKey:CPBoxBorderColorKey];
    [aCoder encodeObject:_fillColor forKey:CPBoxFillColorKey];

    [aCoder encodeFloat:_cornerRadius forKey:CPBoxCornerRadiusKey];
    [aCoder encodeFloat:_borderWidth forKey:CPBoxBorderWidthKey];

    [aCoder encodeSize:_contentMargin forKey:CPBoxContentMarginKey];
}

@end
