/*
 * _CPMenuItemView.j
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

@import "_CPMenuItemSeparatorView.j"
@import "_CPMenuItemStandardView.j"
@import "_CPMenuItemMenuBarView.j"

@global CPApp

/*
    @ignore
*/
@implementation _CPMenuItemView : CPView
{
    CPMenuItem              _menuItem;
    CPView                  _view       @accessors(property=view, readonly);

    CPFont                  _font;
    CPColor                 _textColor;
    CPColor                 _textShadowColor;

    CGSize                  _minSize;
    BOOL                    _isDirty;
    BOOL                    _showsStateColumn;

    _CPImageAndTextView     _imageAndTextView;
    CPView                  _submenuView;
}

+ (CPString)defaultThemeClass
{
    return "menu-item-view";
}

+ (id)themeAttributes
{
    return @{};
}

// Not used in the Appkit
// + (float)leftMargin
// {
//     return LEFT_MARGIN + STATE_COLUMN_WIDTH;
// }

- (id)initWithFrame:(CGRect)aFrame forMenuItem:(CPMenuItem)aMenuItem
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _menuItem = aMenuItem;
        _showsStateColumn = YES;
        _isDirty = YES;

        [self setAutoresizingMask:CPViewWidthSizable];

        [self synchronizeWithMenuItem];
    }

    return self;
}

- (CGSize)minSize
{
    return _minSize;
}

- (void)setDirty
{
    _isDirty = YES;
}

- (void)synchronizeWithMenuItem
{
    var menuItemView = [_menuItem view];

    if ([_menuItem isSeparatorItem])
    {
        if (![_view isKindOfClass:[_CPMenuItemSeparatorView class]])
        {
            [_view removeFromSuperview];
            _view = [_CPMenuItemSeparatorView view];
        }
    }
    else if (menuItemView)
    {
        if (_view !== menuItemView)
        {
            [_view removeFromSuperview];
            _view = menuItemView;
        }
    }

    else if ([_menuItem menu] == [CPApp mainMenu])
    {
        if (![_view isKindOfClass:[_CPMenuItemMenuBarView class]])
        {
            [_view removeFromSuperview];
            _view = [_CPMenuItemMenuBarView view];
        }

        [_view setMenuItem:_menuItem];
    }
    else
    {
        if (![_view isKindOfClass:[_CPMenuItemStandardView class]])
        {
            [_view removeFromSuperview];
            _view = [_CPMenuItemStandardView view];
        }

        [_view setMenuItem:_menuItem];
    }

    if ([_view superview] !== self)
        [self addSubview:_view];

    if ([_view respondsToSelector:@selector(update)])
        [_view update];

    _minSize = [_view frame].size;
    [self setAutoresizesSubviews:NO];
    [self setFrameSize:_minSize];
    [self setAutoresizesSubviews:YES];
}

- (void)setShowsStateColumn:(BOOL)shouldShowStateColumn
{
    _showsStateColumn = shouldShowStateColumn;
}

- (void)highlight:(BOOL)shouldHighlight
{
    if ([_view respondsToSelector:@selector(highlight:)])
        [_view highlight:shouldHighlight];
}

- (BOOL)eventOnSubmenu:(CPEvent)anEvent
{
    if (![_menuItem hasSubmenu])
        return NO;

    return CGRectContainsPoint([_submenuView frame], [self convertPoint:[anEvent locationInWindow] fromView:nil]);
}

- (BOOL)isHidden
{
    return [_menuItem isHidden];
}

- (CPMenuItem)menuItem
{
    return _menuItem;
}

- (void)setFont:(CPFont)aFont
{
    if ([_font isEqual:aFont])
        return;

    _font = aFont;

    if ([_view respondsToSelector:@selector(setFont:)])
        [_view setFont:aFont];

    [self setDirty];
}

- (void)setTextColor:(CPColor)aColor
{
    if (_textColor == aColor)
        return;

    _textColor = aColor;

    [_imageAndTextView setTextColor:[self textColor]];
    [_submenuView setColor:[self textColor]];
}

- (CPColor)textColor
{
    return nil;
}

- (void)setTextShadowColor:(CPColor)aColor
{
    if (_textShadowColor == aColor)
        return;

    _textShadowColor = aColor;

    [_imageAndTextView setTextShadowColor:[self textShadowColor]];
    //[_submenuView setColor:[self textColor]];
}

- (CPColor)textShadowColor
{
    return [_menuItem isEnabled] ? (_textShadowColor ? _textShadowColor : [CPColor colorWithWhite:1.0 alpha:0.8]) : [CPColor colorWithWhite:0.8 alpha:0.8];
}

- (void)setParentMenuHighlightColor:(CPColor)aColor
{
    if ([_view respondsToSelector:@selector(setHighlightColor:)])
        [_view setHighlightColor:aColor];
}

- (void)setParentMenuHighlightTextColor:(CPColor)aColor
{
    if ([_view respondsToSelector:@selector(setHighlightTextColor:)])
        [_view setHighlightTextColor:aColor];
}

- (void)setParentMenuHighlightTextShadowColor:(CPColor)aColor
{
    if ([_view respondsToSelector:@selector(setHighlightTextShadowColor:)])
        [_view setHighlightTextShadowColor:aColor];
}

- (void)setParentMenuTextColor:(CPColor)aColor
{
    if ([_view respondsToSelector:@selector(setTextColor:)])
        [_view setTextColor:aColor];
}

- (void)setParentMenuTextShadowColor:(CPColor)aColor
{
    if ([_view respondsToSelector:@selector(setTextShadowColor:)])
        [_view setTextShadowColor:aColor];
}

@end

@implementation _CPMenuItemArrowView : CPView
{
    CPColor _color;
}

- (void)setColor:(CPColor)aColor
{
    if (_color == aColor)
        return;

    _color = aColor;

    [self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextBeginPath(context);

    CGContextMoveToPoint(context, 1.0, 4.0);
    CGContextAddLineToPoint(context, 9.0, 4.0);
    CGContextAddLineToPoint(context, 5.0, 8.0);
    CGContextClosePath(context);

    CGContextSetFillColor(context, _color);
    CGContextFillPath(context);
}

@end
