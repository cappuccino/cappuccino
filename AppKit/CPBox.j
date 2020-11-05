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
@import <Foundation/CPGeometry.j>

// CPBoxType
@typedef CPBoxType
CPBoxPrimary    = 0;
CPBoxSecondary  = 1; // Deprecated
CPBoxSeparator  = 2;
CPBoxOldStyle   = 3; // Deprecated
CPBoxCustom     = 4;

// CPBorderType
@typedef CPBorderType
CPNoBorder      = 0;
CPLineBorder    = 1;
CPBezelBorder   = 2;
CPGrooveBorder  = 3;

// CPTitlePosition
@typedef CPTitlePosition
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
    CPBorderType    _borderType;    // deprecated
    CPView          _contentView;
    CPView          _boxView;       // needed for CSS theming, will be transparent for non CSS themes
    BOOL            _transparent    @accessors(getter=isTransparent);

    CPString        _title          @accessors(getter=title);
    int             _titlePosition  @accessors(getter=titlePosition);
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

+ (CPDictionary)themeAttributes
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
            @"title-font": [CPNull null],
            @"title-left-offset": 5.0,
            @"title-top-offset": 0.0,
            @"title-color": [CPNull null],
            @"nib2cib-adjustment-primary-frame": CGRectMake(4, -4, -8, -6),
            @"content-adjustment": CGRectMakeZero(),
            @"min-y-correction-no-title": 0,
            @"min-y-correction-title": 0
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
        _borderType = CPGrooveBorder; // Was CPBezelBorder but Cocoa default is CPGrooveBorder
        _boxType    = CPBoxPrimary;

        _titlePosition = CPNoTitle;
        _titleView = [CPTextField labelWithTitle:@""];
        [_titleView setFont:[self titleFont]];
        [_titleView setTextColor:[self titleColor]];

        _boxView = [[CPView alloc] initWithFrame:[self bounds]];
        [_boxView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

        _contentView = [[CPView alloc] initWithFrame:[self bounds]];
        [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

        [self setAutoresizesSubviews:YES];
        [self addSubview:_boxView];
        [_boxView setAutoresizesSubviews:YES];
        [_boxView addSubview:_contentView];

        [self sizeToFit];
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
    CPLog.warn("CPBox borderType is deprecated.");

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

    [self refreshDisplay];
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
    if ((aBoxType == CPBoxSecondary) || (aBoxType == CPBoxOldStyle))
        CPLog.warn("CPBox setBoxType: CPBoxSecondary and CPBoxOldStyle are deprecated.");

    if (_boxType === aBoxType)
        return;

    _boxType = aBoxType;

    [self refreshDisplay];
}

- (void)setTransparent:(BOOL)shouldBeTransparent
{
    if (_transparent == shouldBeTransparent)
        return;

    _transparent = shouldBeTransparent;

    [self _manageTitlePositioning];
}

/*!
    The receiver’s border color. It must be a custom box (that is, it has a type of CPBoxCustom) and it must have a border style of CPLineBorder.
 */
- (CPColor)borderColor
{
    return [self valueForThemeAttribute:@"border-color"];
}

- (void)setBorderColor:(CPColor)color
{
    if ((_boxType !== CPBoxCustom) || (_borderType !== CPLineBorder))
    {
        CPLog.warn("CPBox setBorderColor: the box must be of type CPBoxCustom AND border of type CPLineBorder in order to use setBorderColor. Ignored.");
        return;
    }

    if ([color isEqual:[self borderColor]])
        return;

    [self setValue:color forThemeAttribute:@"border-color"];
}

/*!
    The receiver’s border width. It must be a custom box (that is, it has a type of CPBoxCustom) and it must have a border style of CPLineBorder.
 */
- (float)borderWidth
{
    return [self valueForThemeAttribute:@"border-width"];
}

- (void)setBorderWidth:(float)width
{
    if ((_boxType !== CPBoxCustom) || (_borderType !== CPLineBorder))
    {
        CPLog.warn("CPBox setBorderWidth: the box must be of type CPBoxCustom AND border of type CPLineBorder in order to use setBorderWidth. Ignored.");
        return;
    }

    if (width === [self borderWidth])
        return;

    [self setValue:width forThemeAttribute:@"border-width"];
}

/*!
    The receiver’s corner radius. It must be a custom box (that is, it has a type of CPBoxCustom) and it must have a border style of CPLineBorder.
 */
- (float)cornerRadius
{
    return [self valueForThemeAttribute:@"corner-radius"];
}

- (void)setCornerRadius:(float)radius
{
    if ((_boxType !== CPBoxCustom) || (_borderType !== CPLineBorder))
    {
        CPLog.warn("CPBox setCornerRadius: the box must be of type CPBoxCustom AND border of type CPLineBorder in order to use setCornerRadius. Ignored.");
        return;
    }

    if (radius === [self cornerRadius])
        return;

    [self setValue:radius forThemeAttribute:@"corner-radius"];
}

/*!
    The receiver’s background color. It must be a custom box (that is, it has a type of CPBoxCustom) and it must have a border style of CPLineBorder.
 */
- (CPColor)fillColor
{
    return [self valueForThemeAttribute:@"background-color"];
}

- (void)setFillColor:(CPColor)color
{
    if ((_boxType !== CPBoxCustom) || (_borderType !== CPLineBorder))
    {
        CPLog.warn("CPBox setFillColor: the box must be of type CPBoxCustom AND border of type CPLineBorder in order to use setFillColor. Ignored.");
        return;
    }

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

    [aView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    //  A nil contentView is allowed (tested in Cocoa 2013-02-22).
    if (!aView)
        [_contentView removeFromSuperview];
    else if (_contentView)
        [_boxView replaceSubview:_contentView with:aView];
    else
        [_boxView addSubview:aView];

    _contentView = aView;

    [self sizeToFit];
    [self refreshDisplay];
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
        contentMargin = [self valueForThemeAttribute:@"content-margin"],
        contentAdjustment = [self valueForThemeAttribute:@"content-adjustment"],
        minYCorrection = [self valueForThemeAttribute:(_titlePosition === CPNoTitle ? @"min-y-correction-no-title" : @"min-y-correction-title")];

    [self setFrame:CGRectMake(aRect.origin.x - contentAdjustment.origin.x - contentMargin.width  + borderWidth,
                              aRect.origin.y - contentAdjustment.origin.y - contentMargin.height + borderWidth - minYCorrection,
                              aRect.size.width  + 2 * contentMargin.width  - contentAdjustment.size.width,
                              aRect.size.height + 2 * contentMargin.height - contentAdjustment.size.height)];
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
    if ([self hasThemeAttribute:@"title-font"])
        return [self valueForThemeAttribute:@"title-font"];
    else
        return [_titleView font];
}

- (void)setTitleFont:(CPFont)aFont
{
    if ([aFont isEqual:[self titleFont]])
        return;

    if ([self hasThemeAttribute:@"title-font"])
        [self setValue:aFont forThemeAttribute:@"title-font"];

    [_titleView setFont:aFont];
}

- (CPColor)titleColor
{
    if ([self hasThemeAttribute:@"title-color"])
        return [self valueForThemeAttribute:@"title-color"];
    else
        return [_titleView textColor];
}

- (void)setTitleColor:(CPColor)aColor
{
    if ([aColor isEqual:[self titleColor]])
        return;

    if ([self hasThemeAttribute:@"title-color"])
        [self setValue:aColor forThemeAttribute:@"title-color"];

    [_titleView setTextColor:aColor];
}

/*!
    Return the text field used to display the receiver's title.

    This is the Cappuccino equivalent to the `titleCell` method.
*/
- (CPTextField)titleView
{
    return _titleView;
}

/*!
    Return the rectangle in which the receiver’s title is drawn.
 */
- (CGRect)titleRect
{
    return [_titleView frame];
}

- (void)_manageTitlePositioning
{
    if ((_titlePosition == CPNoTitle) || _transparent)
    {
        [_titleView removeFromSuperview];

        if (_boxType !== CPBoxSeparator)
            [self sizeToFit];

        [self refreshDisplay];
        return;
    }

    [_titleView setStringValue:_title];
    [_titleView sizeToFit];

    var titleLeftOffset = [self valueForThemeAttribute:@"title-left-offset"],
        titleTopOffset  = [self valueForThemeAttribute:@"title-top-offset"];

    switch (_titlePosition)
    {
        case CPAtTop:
        case CPAboveTop:
        case CPBelowTop:
            [_titleView setFrameOrigin:CGPointMake(titleLeftOffset, titleTopOffset)]; // FIXME: was 0.0
            [_titleView setAutoresizingMask:CPViewNotSizable];
            break;

        case CPAboveBottom:
        case CPAtBottom:
        case CPBelowBottom:
            var h = [_titleView frameSize].height;
            [_titleView setFrameOrigin:CGPointMake(titleLeftOffset, [self frameSize].height - h - titleTopOffset)];
            [_titleView setAutoresizingMask:CPViewMinYMargin];
            break;
    }

    if (!_transparent)
        [self addSubview:_titleView];

    [self sizeToFit];
    [self refreshDisplay];
}

- (void)sizeToFit
{
    var offset = [self _titleHeightOffset],
        size = [self frameSize];

    [_boxView setFrame:CGRectMake(0, offset[1], size.width, size.height - offset[0])];

    if (!_contentView)
        return;

    var boxSize = [_boxView frameSize],
        contentMargin = [self valueForThemeAttribute:@"content-margin"],
        contentAdjustment = [self valueForThemeAttribute:@"content-adjustment"],
        borderWidth = [self valueForThemeAttribute:@"border-width"],
        minYCorrection = [self valueForThemeAttribute:(_titlePosition === CPNoTitle ? @"min-y-correction-no-title" : @"min-y-correction-title")];

    [_contentView setFrame:CGRectMake(contentAdjustment.origin.x + contentMargin.width  - borderWidth,
                                      contentAdjustment.origin.y + contentMargin.height - borderWidth + minYCorrection,
                                      boxSize.width  - 2 * contentMargin.width  + contentAdjustment.size.width,
                                      boxSize.height - 2 * contentMargin.height + contentAdjustment.size.height)];
}

- (CPArray)_titleHeightOffset
{
    var titleTopOffset = [self valueForThemeAttribute:@"title-top-offset"];

    switch (_titlePosition)
    {
        case CPAtTop:
            return [[_titleView frameSize].height + titleTopOffset, [_titleView frameSize].height + titleTopOffset];

        case CPAtBottom:
            return [[_titleView frameSize].height + titleTopOffset, 0.0];

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
    if ([self isCSSBased] && (_boxType !== CPBoxCustom))
        return;

    var bounds = [self bounds];

    if (_boxType === CPBoxSeparator)
    {
        // NSBox does not include a horizontal flag for the separator type. We have to determine
        // the type of separator to draw by the width and height of the frame.
        if (CGRectGetWidth(bounds) === 5.0)
            return [self _drawVerticalSeparatorInRect:bounds];
        else if (CGRectGetHeight(bounds) === 5.0)
            return [self _drawHorizontalSeparatorInRect:bounds];
    }

    if (_transparent)
        return;

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

#pragma mark -

@implementation CPBox (CSSTheming)

- (void)layoutSubviews
{
    if (![self isCSSBased] || (_boxType === CPBoxCustom))
        return;

    var bounds = [self bounds];

    if (_boxType === CPBoxSeparator)
    {
        if (bounds.size.width === 5.0)
        {
            // Vertical separator
            [_boxView setFrame:CGRectMake(2,0,1,bounds.size.height)];
        }
        else
        {
            // Horizontal separator
            [_boxView setFrame:CGRectMake(0,2,bounds.size.width,1)];
        }

        [_boxView setBackgroundColor:[self valueForThemeAttribute:@"border-color"]];

        return;
    }

    // All types of boxes (beside custom which is not covered here) always draw the same way, unless they are CPNoBorder.
    if ((_borderType !== CPNoBorder) && !_transparent)
    {
        [_boxView setBackgroundColor:[self valueForThemeAttribute:@"background-color"]];
        return;
    }

    // No border or transparent
    [_boxView setBackgroundColor:nil];
}

- (BOOL)isCSSBased
{
    return [[self theme] isCSSBased];
}

- (void)refreshDisplay
{
    if ([self isCSSBased] && (_boxType !== CPBoxCustom))
        [self setNeedsLayout:YES];
    else
        [self setNeedsDisplay:YES];
}

@end

#pragma mark -

var CPBoxTypeKey          = @"CPBoxTypeKey",
    CPBoxBorderTypeKey    = @"CPBoxBorderTypeKey",
    CPBoxTitleKey         = @"CPBoxTitleKey",
    CPBoxTitlePositionKey = @"CPBoxTitlePositionKey",
    CPBoxTitleViewKey     = @"CPBoxTitleViewKey",
    CPBoxContentViewKey   = @"CPBoxContentViewKey",
    CPBoxBoxViewKey       = @"CPBoxBoxViewKey";

@implementation CPBox (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _boxType       = [aCoder decodeIntForKey:CPBoxTypeKey];
        _borderType    = [aCoder decodeIntForKey:CPBoxBorderTypeKey];

        _title         = [aCoder decodeObjectForKey:CPBoxTitleKey];
        _titlePosition = [aCoder decodeIntForKey:CPBoxTitlePositionKey];

        // Important : see comment on encodeWithCoder below

        _boxView = [aCoder decodeObjectForKey:CPBoxBoxViewKey];

        if (!_boxView)
        {
            // We're coming from nib2cib.

            _boxView     = [[CPView alloc] initWithFrame:[self bounds]];
            _titleView   = [CPTextField labelWithTitle:_title];
        }
        else
        {
            // We're coming from elsewhere

            _titleView   = [aCoder decodeObjectForKey:CPBoxTitleViewKey];
        }

        _contentView = [aCoder decodeObjectForKey:CPBoxContentViewKey];

        // FIXME: super-mega-hyper-trick : _contentView has a superview which is not normal !
        // FIXME: (see encodeWithCoder to understand why this is not possible)
        // FIXME: we fix this by hand. This is horrible so please find a structural solution !

        if (_contentView)
            _contentView._superview = nil;

        [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [_boxView     setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [_boxView     setAutoresizesSubviews:YES];
        [self         setAutoresizesSubviews:YES];

        if (_contentView)
            [_boxView setSubviews:@[_contentView]];

        [self addSubview:_boxView];
        [self addSubview:_titleView];

        if (_boxType === CPBoxSeparator)
            _titlePosition = CPNoTitle;

        [_titleView setFont:[self titleFont]];
        [_titleView setTextColor:[self titleColor]];

        [self _manageTitlePositioning];

        [self refreshDisplay];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    // We have to distinguish between 2 cases :
    // - we come from nib2cib
    // - we come from elsewhere
    //
    // When coming from nib2cib, we have no _boxView, _contentView, _titleView.
    // We fix _contentView to be the first (and only) subview.
    // They will have to be added on decoding.
    //
    // When coming from elsewhere, we remove _boxView (and thus _contentView) and _titleView
    // from the view hierarchy as we'll already encode them via variables.
    // They will be putted back during decoding. This way, we reduce the space and speed needed for coding.

    var subviews = [self subviews];

    if (!_boxView)
    {
        // We're coming from nib2cib.

        _contentView = subviews[0];

        [_contentView removeFromSuperview];
    }
    else
    {
        // We're coming from elsewhere.

        [_boxView   removeFromSuperview];
        [_titleView removeFromSuperview];
    }

    [super encodeWithCoder:aCoder];

    [self setSubviews:subviews];

    [aCoder encodeInt:_boxType forKey:CPBoxTypeKey];
    [aCoder encodeInt:_borderType forKey:CPBoxBorderTypeKey];
    [aCoder encodeObject:_title forKey:CPBoxTitleKey];
    [aCoder encodeInt:_titlePosition forKey:CPBoxTitlePositionKey];
    [aCoder encodeConditionalObject:_contentView forKey:CPBoxContentViewKey];
    [aCoder encodeConditionalObject:_titleView forKey:CPBoxTitleViewKey];
    [aCoder encodeConditionalObject:_boxView forKey:CPBoxBoxViewKey];
}

@end
