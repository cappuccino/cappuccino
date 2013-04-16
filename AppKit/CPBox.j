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

@import "CPTextField.j"
@import "CPView.j"

// CPBoxType
CPBoxPrimary    = 0;
CPBoxSecondary  = 1;
CPBoxSeparator  = 2;
CPBoxOldStyle   = 3;
CPBoxCustom     = 4;

// CPBorderType
CPNoBorder      = 0;
CPLineBorder    = 1;
CPBezelBorder   = 2;
CPGrooveBorder  = 3;

// CPTitlePosition
CPNoTitle     = 0;
CPAboveTop    = 1;
CPAtTop       = 2;
CPBelowTop    = 3;
CPAboveBottom = 4;
CPAtBottom    = 5;
CPBelowBottom = 6;


/*!
    @ingroup appkit
    @class CPBox

    A CPBox is a simple view which can display a border.
*/
@implementation CPBox : CPView
{
    CPBoxType       _boxType;
    CPBorderType    _borderType;
    CPView          _contentView;

    CPString        _title @accessors(getter=title);
    int             _titlePosition @accessors(getter=titlePosition);
    CPTextField     _titleView;
}

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if ([aBinding hasPrefix:CPDisplayPatternTitleBinding])
        return [CPTitleWithPatternBinding class];

    return [super _binderClassForBinding:aBinding];
}

+ (CPString)defaultThemeClass
{
    return @"box";
}

+ (id)themeAttributes
{
    return @{
            @"background-color": [CPNull null],
            @"border-color": [CPNull null],
            @"border-width": 1.0,
            @"corner-radius": 3.0,
            @"inner-shadow-offset": CGSizeMakeZero(),
            @"inner-shadow-size": 6.0,
            @"inner-shadow-color": [CPNull null],
            @"content-margin": CGSizeMakeZero(),
        };
}

+ (id)boxEnclosingView:(CPView)aView
{
    var box = [[self alloc] initWithFrame:CGRectMakeZero()],
        enclosingView = [aView superview];

    [box setAutoresizingMask:[aView autoresizingMask]];
    [box setFrameFromContentFrame:[aView frame]];

    [enclosingView replaceSubview:aView with:box];

    [box setContentView:aView];

    return box;
}

- (id)initWithFrame:(CGRect)frameRect
{
    self = [super initWithFrame:frameRect];

    if (self)
    {
        _borderType = CPBezelBorder;

        _titlePosition = CPNoTitle;
        _titleView = [CPTextField labelWithTitle:@""];

        _contentView = [[CPView alloc] initWithFrame:[self bounds]];
        [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

        [self setAutoresizesSubviews:YES];
        [self addSubview:_contentView];
    }

    return self;
}

// Configuring Boxes

/*!
    Returns the receiver's border rectangle.

    @return the border rectangle of the box
*/
- (CGRect)borderRect
{
    return [self bounds];
}

/*!
    Returns the receiver's border type. Possible values are:

    <pre>
    CPNoBorder
    CPLineBorder
    CPBezelBorder
    CPGrooveBorder
    </pre>

    @return the border type of the box
*/
- (CPBorderType)borderType
{
    return _borderType;
}


/*!
    Sets the receiver's border type. Valid values are:

    <pre>
    CPNoBorder
    CPLineBorder
    CPBezelBorder
    CPGrooveBorder
    </pre>

    @param borderType the border type to use
*/
- (void)setBorderType:(CPBorderType)aBorderType
{
    if (_borderType === aBorderType)
        return;

    _borderType = aBorderType;
    [self setNeedsDisplay:YES];
}

/*!
    Returns the receiver's box type. Possible values are:

    <pre>
    CPBoxPrimary
    CPBoxSecondary
    CPBoxSeparator
    CPBoxOldStyle
    CPBoxCustom
    </pre>

    (In the current implementation, all values act the same except CPBoxSeparator.)

    @return the box type of the box.
*/
- (CPBoxType)boxType
{
    return _boxType;
}

/*!
    Sets the receiver's box type. Valid values are:

    <pre>
    CPBoxPrimary
    CPBoxSecondary
    CPBoxSeparator
    CPBoxOldStyle
    CPBoxCustom
    </pre>

    (In the current implementation, all values act the same except CPBoxSeparator.)

    @param aBoxType the box type of the box.
*/
- (void)setBoxType:(CPBoxType)aBoxType
{
    if (_boxType === aBoxType)
        return;

    _boxType = aBoxType;
    [self setNeedsDisplay:YES];
}

- (CPColor)borderColor
{
    return [self valueForThemeAttribute:@"border-color"];
}

- (void)setBorderColor:(CPColor)color
{
    if ([color isEqual:[self borderColor]])
        return;

    [self setValue:color forThemeAttribute:@"border-color"];
}

- (float)borderWidth
{
    return [self valueForThemeAttribute:@"border-width"];
}

- (void)setBorderWidth:(float)width
{
    if (width === [self borderWidth])
        return;

    [self setValue:width forThemeAttribute:@"border-width"];
}

- (float)cornerRadius
{
    return [self valueForThemeAttribute:@"corner-radius"];
}

- (void)setCornerRadius:(float)radius
{
    if (radius === [self cornerRadius])
        return;

    [self setValue:radius forThemeAttribute:@"corner-radius"];
}

- (CPColor)fillColor
{
    return [self valueForThemeAttribute:@"background-color"];
}

- (void)setFillColor:(CPColor)color
{
    if ([color isEqual:[self fillColor]])
        return;

    [self setValue:color forThemeAttribute:@"background-color"];
}

- (CPView)contentView
{
    return _contentView;
}

- (void)setContentView:(CPView)aView
{
    if (aView === _contentView)
        return;

    var borderWidth = [self borderWidth],
        contentMargin = [self valueForThemeAttribute:@"content-margin"];

    [aView setFrame:CGRectInset([self bounds], contentMargin.width + borderWidth, contentMargin.height + borderWidth)];
    [aView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    //  A nil contentView is allowed (tested in Cocoa 2013-02-22).
    if (!aView)
        [_contentView removeFromSuperview];
    else if (_contentView)
        [self replaceSubview:_contentView with:aView];
    else
        [self addSubview:aView];

    _contentView = aView;
}

- (CGSize)contentViewMargins
{
    return [self valueForThemeAttribute:@"content-margin"];
}

- (void)setContentViewMargins:(CGSize)size
{
     if (size.width < 0 || size.height < 0)
         [CPException raise:CPGenericException reason:@"Margins must be positive"];

    [self setValue:CGSizeMakeCopy(size) forThemeAttribute:@"content-margin"];
}

- (void)setFrameFromContentFrame:(CGRect)aRect
{
    var offset = [self _titleHeightOffset],
        borderWidth = [self borderWidth],
        contentMargin = [self valueForThemeAttribute:@"content-margin"];

    [self setFrame:CGRectInset(aRect, -(contentMargin.width + borderWidth), -(contentMargin.height + offset[0] + borderWidth))];
}

- (void)setTitle:(CPString)aTitle
{
    if (aTitle == _title)
        return;

    _title = aTitle;

    [self _manageTitlePositioning];
}

- (void)setTitlePosition:(int)aTitlePotisition
{
    if (aTitlePotisition == _titlePosition)
        return;

    _titlePosition = aTitlePotisition;

    [self _manageTitlePositioning];
}

- (CPFont)titleFont
{
    return [_titleView font];
}

- (void)setTitleFont:(CPFont)aFont
{
    [_titleView setFont:aFont];
}

/*!
    Return the text field used to display the receiver's title.

    This is the Cappuccino equivalent to the `titleCell` method.
*/
- (CPTextField)titleView
{
    return _titleView;
}

- (void)_manageTitlePositioning
{
    if (_titlePosition == CPNoTitle)
    {
        [_titleView removeFromSuperview];
        [self setNeedsDisplay:YES];
        return;
    }

    [_titleView setStringValue:_title];
    [_titleView sizeToFit];
    [self addSubview:_titleView];

    switch (_titlePosition)
    {
        case CPAtTop:
        case CPAboveTop:
        case CPBelowTop:
            [_titleView setFrameOrigin:CGPointMake(5.0, 0.0)];
            [_titleView setAutoresizingMask:CPViewNotSizable];
            break;

        case CPAboveBottom:
        case CPAtBottom:
        case CPBelowBottom:
            var h = [_titleView frameSize].height;
            [_titleView setFrameOrigin:CGPointMake(5.0, [self frameSize].height - h)];
            [_titleView setAutoresizingMask:CPViewMinYMargin];
            break;
    }

    [self sizeToFit];
    [self setNeedsDisplay:YES];
}

- (void)sizeToFit
{
    var contentFrame = [_contentView frame],
        offset = [self _titleHeightOffset],
        contentMargin = [self valueForThemeAttribute:@"content-margin"];

    if (!contentFrame)
        return;

    [_contentView setFrameOrigin:CGPointMake(contentMargin.width, contentMargin.height + offset[1])];
}

- (float)_titleHeightOffset
{
    if (_titlePosition == CPNoTitle)
        return [0.0, 0.0];

    switch (_titlePosition)
    {
        case CPAtTop:
            return [[_titleView frameSize].height, [_titleView frameSize].height];

        case CPAtBottom:
            return [[_titleView frameSize].height, 0.0];

        default:
            return [0.0, 0.0];
    }
}

- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    if (aKey === CPDisplayPatternTitleBinding)
        [self setTitle:aValue || @""];
    else
        [super setValue:aValue forKey:aKey];
}

- (void)drawRect:(CGRect)rect
{
    var bounds = [self bounds];

    switch (_boxType)
    {
        case CPBoxSeparator:
            // NSBox does not include a horizontal flag for the separator type. We have to determine
            // the type of separator to draw by the width and height of the frame.
            if (CGRectGetWidth(bounds) === 5.0)
                return [self _drawVerticalSeparatorInRect:bounds];
            else if (CGRectGetHeight(bounds) === 5.0)
                return [self _drawHorizontalSeparatorInRect:bounds];

            break;
    }

    if (_titlePosition == CPAtTop)
    {
        bounds.origin.y += [_titleView frameSize].height;
        bounds.size.height -= [_titleView frameSize].height;
    }
    if (_titlePosition == CPAtBottom)
    {
        bounds.size.height -= [_titleView frameSize].height;
    }

    // Primary or secondary type boxes always draw the same way, unless they are CPNoBorder.
    if ((_boxType === CPBoxPrimary || _boxType === CPBoxSecondary) && _borderType !== CPNoBorder)
    {
        [self _drawPrimaryBorderInRect:bounds];
        return;
    }

    switch (_borderType)
    {
        case CPBezelBorder:
            [self _drawBezelBorderInRect:bounds];
            break;

        case CPGrooveBorder:
        case CPLineBorder:
            [self _drawLineBorderInRect:bounds];
            break;

        case CPNoBorder:
            [self _drawNoBorderInRect:bounds];
            break;
    }
}

- (void)_drawHorizontalSeparatorInRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetStrokeColor(context, [self borderColor]);
    CGContextSetLineWidth(context, 1.0);

    CGContextMoveToPoint(context, CGRectGetMinX(aRect), CGRectGetMidY(aRect));
    CGContextAddLineToPoint(context, CGRectGetWidth(aRect), CGRectGetMidY(aRect));
    CGContextStrokePath(context);
}

- (void)_drawVerticalSeparatorInRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetStrokeColor(context, [self borderColor]);
    CGContextSetLineWidth(context, 1.0);

    CGContextMoveToPoint(context, CGRectGetMidX(aRect), CGRectGetMinY(aRect));
    CGContextAddLineToPoint(context, CGRectGetMidX(aRect), CGRectGetHeight(aRect));
    CGContextStrokePath(context);
}

- (void)_drawLineBorderInRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        cornerRadius = [self cornerRadius],
        borderWidth = [self borderWidth];

    aRect = CGRectInset(aRect, borderWidth / 2.0, borderWidth / 2.0);

    CGContextSetFillColor(context, [self fillColor]);
    CGContextSetStrokeColor(context, [self borderColor]);

    CGContextSetLineWidth(context, borderWidth);
    CGContextFillRoundedRectangleInRect(context, aRect, cornerRadius, YES, YES, YES, YES);
    CGContextStrokeRoundedRectangleInRect(context, aRect, cornerRadius, YES, YES, YES, YES);
}

- (void)_drawBezelBorderInRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        cornerRadius = [self cornerRadius],
        borderWidth = [self borderWidth],
        shadowOffset = [self valueForThemeAttribute:@"inner-shadow-offset"],
        shadowSize = [self valueForThemeAttribute:@"inner-shadow-size"],
        shadowColor = [self valueForThemeAttribute:@"inner-shadow-color"];

    var baseRect = aRect;
    aRect = CGRectInset(aRect, borderWidth / 2.0, borderWidth / 2.0);

    CGContextSaveGState(context);

    CGContextSetStrokeColor(context, [self borderColor]);
    CGContextSetLineWidth(context, borderWidth);
    CGContextSetFillColor(context, [self fillColor]);
    CGContextFillRoundedRectangleInRect(context, aRect, cornerRadius, YES, YES, YES, YES);
    CGContextStrokeRoundedRectangleInRect(context, aRect, cornerRadius, YES, YES, YES, YES);

    CGContextRestoreGState(context);
}

- (void)_drawPrimaryBorderInRect:(CGRect)aRect
{
    // Draw the "primary" style CPBox.

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        cornerRadius = [self cornerRadius],
        borderWidth = [self borderWidth],
        shadowOffset = [self valueForThemeAttribute:@"inner-shadow-offset"],
        shadowSize = [self valueForThemeAttribute:@"inner-shadow-size"],
        shadowColor = [self valueForThemeAttribute:@"inner-shadow-color"],
        baseRect = aRect;

    aRect = CGRectInset(aRect, borderWidth / 2.0, borderWidth / 2.0);

    CGContextSaveGState(context);

    CGContextSetStrokeColor(context, [self borderColor]);
    CGContextSetLineWidth(context, borderWidth);
    CGContextSetFillColor(context, [self fillColor]);
    CGContextFillRoundedRectangleInRect(context, aRect, cornerRadius, YES, YES, YES, YES);

    CGContextBeginPath(context);
    // Note we can't use the 0.5 inset rectangle when setting up clipping. The clipping has to be
    // on integer coordinates for this to look right in Chrome.
    CGContextAddPath(context, CGPathWithRoundedRectangleInRect(baseRect, cornerRadius, cornerRadius, YES, YES, YES, YES));
    CGContextClip(context);
    CGContextSetShadowWithColor(context, shadowOffset, shadowSize, shadowColor);
    CGContextStrokeRoundedRectangleInRect(context, aRect, cornerRadius, YES, YES, YES, YES);

    CGContextRestoreGState(context);
}

- (void)_drawNoBorderInRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetFillColor(context, [self fillColor]);
    CGContextFillRect(context, aRect);
}

@end

var CPBoxTypeKey          = @"CPBoxTypeKey",
    CPBoxBorderTypeKey    = @"CPBoxBorderTypeKey",
    CPBoxTitle            = @"CPBoxTitle",
    CPBoxTitlePosition    = @"CPBoxTitlePosition",
    CPBoxTitleView        = @"CPBoxTitleView";

@implementation CPBox (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _boxType       = [aCoder decodeIntForKey:CPBoxTypeKey];
        _borderType    = [aCoder decodeIntForKey:CPBoxBorderTypeKey];

        _title         = [aCoder decodeObjectForKey:CPBoxTitle];
        _titlePosition = [aCoder decodeIntForKey:CPBoxTitlePosition];
        _titleView     = [aCoder decodeObjectForKey:CPBoxTitleView] || [CPTextField labelWithTitle:_title];

        _contentView   = [self subviews][0];

        [self setAutoresizesSubviews:YES];
        [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

        [self _manageTitlePositioning];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInt:_boxType forKey:CPBoxTypeKey];
    [aCoder encodeInt:_borderType forKey:CPBoxBorderTypeKey];
    [aCoder encodeObject:_title forKey:CPBoxTitle];
    [aCoder encodeInt:_titlePosition forKey:CPBoxTitlePosition];
    [aCoder encodeObject:_titleView forKey:CPBoxTitleView];
}

@end
