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
        _fillColor = [CPColor clearColor];
        _borderColor = [CPColor blackColor];

        _borderWidth = 1.0;
        _contentMargin = CGSizeMake(0.0, 0.0);

        _contentView = [[CPView alloc] initWithFrame:[self bounds]];

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

    [aView setFrame:CGRectInset([self bounds], _contentMargin.width + _borderWidth, _contentMargin.height + _borderWidth)];
    [self replaceSubview:_contentView with:aView];
    [aView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
    
    _contentView = aView;    
}

- (CPSize)contentViewMargins
{
    return _contentMargin;
}

- (void)setContentViewMargins:(CPSize)size
{
     if(size.width < 0 || size.height < 0)
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
    var bounds = [self bounds],
        aContext = [[CPGraphicsContext currentContext] graphicsPort],
        border2 = _borderWidth/2,

        strokeRect = CGRectMake(bounds.origin.x + border2, 
                                bounds.origin.y + border2, 
                                bounds.size.width - _borderWidth, 
                                bounds.size.height - _borderWidth),
                                
        fillRect = CGRectMake(bounds.origin.x + border2, 
                              bounds.origin.y + border2, 
                              bounds.size.width - _borderWidth, 
                              bounds.size.height - _borderWidth);

    CGContextSetFillColor(aContext, [self fillColor]);
    CGContextSetStrokeColor(aContext, [self borderColor]);
    CGContextSetLineWidth(aContext, _borderWidth);

    switch(_borderType)
    {
        case CPLineBorder:  CGContextFillRoundedRectangleInRect(aContext, fillRect, _cornerRadius, YES, YES, YES, YES);
                            CGContextStrokeRoundedRectangleInRect(aContext, strokeRect, _cornerRadius, YES, YES, YES, YES);
                            break;

        case CPBezelBorder: CGContextFillRoundedRectangleInRect(aContext, fillRect, _cornerRadius, YES, YES, YES, YES);
                            CGContextSetStrokeColor(aContext, [CPColor colorWithWhite:190.0/255.0 alpha:1.0]);
                            CGContextBeginPath(aContext);
                            CGContextMoveToPoint(aContext, strokeRect.origin.x, strokeRect.origin.y);
                            CGContextAddLineToPoint(aContext, CGRectGetMinX(strokeRect), CGRectGetMaxY(strokeRect)),
                            CGContextAddLineToPoint(aContext, CGRectGetMaxX(strokeRect), CGRectGetMaxY(strokeRect)),
                            CGContextAddLineToPoint(aContext, CGRectGetMaxX(strokeRect), CGRectGetMinY(strokeRect)),
                            CGContextStrokePath(aContext);
                            CGContextSetStrokeColor(aContext, [CPColor colorWithWhite:142.0/255.0 alpha:1.0]);
                            CGContextBeginPath(aContext);
                            CGContextMoveToPoint(aContext, bounds.origin.x, strokeRect.origin.y);
                            CGContextAddLineToPoint(aContext, CGRectGetMaxX(bounds), CGRectGetMinY(strokeRect));
                            CGContextStrokePath(aContext);
                            break;

        default:            break;
    }
}

@end
