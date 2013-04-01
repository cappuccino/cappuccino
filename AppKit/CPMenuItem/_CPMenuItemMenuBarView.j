/*
 * _CPMenuItemMenuBarView.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
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

@import "CPControl.j"
@import "_CPImageAndTextView.j"

@class _CPMenuBarWindow
@class _CPMenuView

@implementation _CPMenuItemMenuBarView : CPView
{
    CPColor                 _highlightColor @accessors(property=highlightColor);
    CPColor                 _textColor @accessors(property=textColor);
    CPColor                 _textShadowColor @accessors(property=textShadowColor);
    CPColor                 _highlightTextColor @accessors(property=highlightTextColor);
    CPColor                 _highlightTextShadowColor @accessors(property=highlightTextShadowColor);

    CPMenuItem              _menuItem @accessors(property=menuItem);

    CPFont                  _font;

    BOOL                    _isDirty;
    BOOL                    _shouldHighlight;

    _CPImageAndTextView     _imageAndTextView;
}

+ (CPString)defaultThemeClass
{
    return "menu-item-bar-view";
}

+ (id)themeAttributes
{
    return @{
            @"horizontal-margin": 9.0,
            @"submenu-indicator-margin": 3.0,
            @"vertical-margin": 4.0,
        };
}

+ (id)view
{
    return [[self alloc] init];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _imageAndTextView = [[_CPImageAndTextView alloc] initWithFrame:CGRectMake([self valueForThemeAttribute:@"horizontal-margin"], 0.0, 0.0, 0.0)];

        [_imageAndTextView setImagePosition:CPImageLeft];
        [_imageAndTextView setImageOffset:3.0];
        [_imageAndTextView setTextShadowOffset:CGSizeMake(0.0, 1.0)];
        [_imageAndTextView setAutoresizingMask:CPViewMinYMargin | CPViewMaxYMargin];

        [self addSubview:_imageAndTextView];

        [self setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    }

    return self;
}

- (CPColor)setTextColor:(CPColor)aColor
{
    _textColor = aColor;
    [self setNeedsLayout];
}

- (CPColor)setTextShadowColor:(CPColor)aColor
{
    _textShadowColor = aColor;
    [self setNeedsLayout];
}

- (CPColor)setHighlightTextColor:(CPColor)aColor
{
    _highlightTextColor = aColor;
    [self setNeedsLayout];
}

- (CPColor)setHighlightTextShadowColor:(CPColor)aColor
{
    _highlightTextShadowColor = aColor;
    [self setNeedsLayout];
}

- (CPColor)textColor
{
    if (![_menuItem isEnabled])
        return [CPColor lightGrayColor];

    return _textColor || [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-text-color" forClass:_CPMenuView];
}

- (CPColor)textShadowColor
{
    if (![_menuItem isEnabled])
        return [CPColor clearColor];

    return _textShadowColor || [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-text-shadow-color" forClass:_CPMenuView];
}

- (CPColor)highlightTextColor
{
    if (![_menuItem isEnabled])
        return [CPColor lightGrayColor];

    return _highlightTextColor || [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-highlight-text-color" forClass:_CPMenuView];
}

- (CPColor)highlightTextShadowColor
{
    if (![_menuItem isEnabled])
        return [CPColor clearColor];

    return _highlightTextShadowColor || [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-highlight-text-shadow-color" forClass:_CPMenuView];
}

- (CPColor)highlightColor
{
    return _highlightColor || [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-window-background-selected-color" forClass:_CPMenuView];
}

- (void)update
{
    var x = [self valueForThemeAttribute:@"horizontal-margin"],
        height = 0.0;

    [_imageAndTextView setText:[_menuItem title]];
    [_imageAndTextView setFont:[_menuItem font] || [_CPMenuBarWindow font]];
    [_imageAndTextView setVerticalAlignment:CPCenterVerticalTextAlignment];
    [_imageAndTextView setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [_imageAndTextView setImage:[_menuItem image]];
    [_imageAndTextView sizeToFit];

    var imageAndTextViewFrame = [_imageAndTextView frame];

    imageAndTextViewFrame.origin.x = x;
    x += CGRectGetWidth(imageAndTextViewFrame);
    height = MAX(height, CGRectGetHeight(imageAndTextViewFrame)) + 2.0 * [self valueForThemeAttribute:@"vertical-margin"];

    imageAndTextViewFrame.origin.y = FLOOR((height - CGRectGetHeight(imageAndTextViewFrame)) / 2.0);
    [_imageAndTextView setFrame:imageAndTextViewFrame];

    [self setAutoresizesSubviews:NO];
    [self setFrameSize:CGSizeMake(x + [self valueForThemeAttribute:@"horizontal-margin"], height)];
    [self setAutoresizesSubviews:YES];
    [self setNeedsLayout];
}

- (void)highlight:(BOOL)shouldHighlight
{
    // FIXME: This should probably be even throw.
    if (![_menuItem isEnabled])
        shouldHighlight = NO;

    _shouldHighlight = shouldHighlight;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    if (_shouldHighlight)
    {
        if (![_menuItem _isMenuBarButton])
            [self setBackgroundColor:[self highlightColor]];

        [_imageAndTextView setImage:[_menuItem alternateImage] || [_menuItem image]];
        [_imageAndTextView setTextColor:[self highlightTextColor]];
        [_imageAndTextView setTextShadowColor:[self highlightTextShadowColor]];
    }
    else
    {
        [self setBackgroundColor:nil];

        [_imageAndTextView setImage:[_menuItem image]];
        [_imageAndTextView setTextColor:[self textColor]];
        [_imageAndTextView setTextShadowColor:[self textShadowColor]];
    }
}

@end
