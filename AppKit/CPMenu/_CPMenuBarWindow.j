/*
 * _CPMenuBarWindow.j
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

@import "CPPanel.j"
@import "_CPMenuManager.j"

@class _CPMenuView

@global CPMenuDidAddItemNotification
@global CPMenuDidChangeItemNotification
@global CPMenuDidRemoveItemNotification

@implementation _CPMenuBarWindow : CPPanel
{
    CPMenu      _menu;
    CPView      _highlightView;
    CPArray     _menuItemViews;

    CPMenuItem  _trackingMenuItem;

    CPImageView _iconImageView;
    CPTextField _titleField;

    CPColor     _textColor;
    CPColor     _titleColor;

    CPColor     _textShadowColor;
    CPColor     _titleShadowColor;

    CPColor     _highlightColor;
    CPColor     _highlightTextColor;
    CPColor     _highlightTextShadowColor;
}

+ (CPFont)font
{
    return [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-window-font" forClass:_CPMenuView];
}

- (id)init
{
    // This only shows up in browser land, so don't bother calculating metrics in desktop.
    var contentRect = [[CPPlatformWindow primaryPlatformWindow] contentBounds];

    contentRect.size.height = [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-window-height" forClass:_CPMenuView];

    self = [super initWithContentRect:contentRect styleMask:CPBorderlessWindowMask];

    if (self)
    {
        _constrainsToUsableScreen = NO;

        [self setLevel:CPMainMenuWindowLevel];
        [self setAutoresizingMask:CPWindowWidthSizable];

        var contentView = [self contentView];

        [contentView setAutoresizesSubviews:NO];

        [self setBecomesKeyOnlyIfNeeded:YES];

        //
        _iconImageView = [[CPImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)];

        [contentView addSubview:_iconImageView];

        _titleField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

        [_titleField setFont:[CPFont boldSystemFontOfSize:[CPFont systemFontSize] + 1]];
        [_titleField setAlignment:CPCenterTextAlignment];
        [_titleField setTextShadowOffset:CGSizeMake(0, 1)];

        [contentView addSubview:_titleField];
    }

    return self;
}

- (void)setTitle:(CPString)aTitle
{
#if PLATFORM(DOM)
    var bundleName = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleName"];

    if (![bundleName length])
        document.title = aTitle;
    else if ([aTitle length])
        document.title = aTitle + @" - " + bundleName;
    else
        document.title = bundleName;
#endif

    [_titleField setStringValue:aTitle];
    [_titleField sizeToFit];

    [self tile];
}

- (void)setIconImage:(CPImage)anImage
{
    [_iconImageView setImage:anImage];
    [_iconImageView setHidden:anImage == nil];

    [self tile];
}

- (void)setIconImageAlphaValue:(float)anAlphaValue
{
    [_iconImageView setAlphaValue:anAlphaValue];
}

- (void)setColor:(CPColor)aColor
{
    if (!aColor)
        [[self contentView] setBackgroundColor:[[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-window-background-color" forClass:_CPMenuView]];
    else
        [[self contentView] setBackgroundColor:aColor];
}

- (void)setTextColor:(CPColor)aColor
{
    if (_textColor == aColor)
        return;

    _textColor = aColor;

    [_menuItemViews makeObjectsPerformSelector:@selector(setTextColor:) withObject:_textColor];
    [_menuItemViews makeObjectsPerformSelector:@selector(setParentMenuTextColor:) withObject:_textColor];
}

- (void)setTitleColor:(CPColor)aColor
{
    if (_titleColor == aColor)
        return;

    _titleColor = aColor;

    [_titleField setTextColor:aColor ? aColor : [CPColor blackColor]];
}

- (void)setTextShadowColor:(CPColor)aColor
{
    if (_textShadowColor == aColor)
        return;

    _textShadowColor = aColor;

    [_menuItemViews makeObjectsPerformSelector:@selector(setTextShadowColor:) withObject:_textShadowColor];
    [_menuItemViews makeObjectsPerformSelector:@selector(setParentMenuTextShadowColor:) withObject:_textShadowColor];
}

- (void)setTitleShadowColor:(CPColor)aColor
{
    if (_titleShadowColor == aColor)
        return;

    _titleShadowColor = aColor;

    [_titleField setTextShadowColor:aColor ? aColor : [CPColor whiteColor]];
}

- (void)setHighlightColor:(CPColor)aColor
{
    if (_highlightColor == aColor)
        return;

    _highlightColor = aColor;

    [_menuItemViews makeObjectsPerformSelector:@selector(setParentMenuHighlightColor:) withObject:_highlightColor];
}

- (void)setHighlightTextColor:(CPColor)aColor
{
    if (_highlightTextColor == aColor)
        return;

    _highlightTextColor = aColor;

    [_menuItemViews makeObjectsPerformSelector:@selector(setParentMenuHighlightTextColor:) withObject:_highlightTextColor];
}

- (void)setHighlightTextShadowColor:(CPColor)aColor
{
    if (_highlightTextShadowColor == aColor)
        return;

    _highlightTextShadowColor = aColor;

    [_menuItemViews makeObjectsPerformSelector:@selector(setParentMenuHighlightTextShadowColor:) withObject:_highlightTextShadowColor];
}

- (void)setMenu:(CPMenu)aMenu
{
    if (_menu == aMenu)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter];

    if (_menu)
    {
        [defaultCenter
            removeObserver:self
                      name:CPMenuDidAddItemNotification
                    object:_menu];

        [defaultCenter
            removeObserver:self
                      name:CPMenuDidChangeItemNotification
                    object:_menu];

        [defaultCenter
            removeObserver:self
                      name:CPMenuDidRemoveItemNotification
                    object:_menu];

        var items = [_menu itemArray],
            count = items.length;

        while (count--)
            [[items[count] _menuItemView] removeFromSuperview];
    }

    _menu = aMenu;

    if (_menu)
    {
        [defaultCenter
            addObserver:self
              selector:@selector(menuDidAddItem:)
                  name:CPMenuDidAddItemNotification
                object:_menu];

        [defaultCenter
            addObserver:self
              selector:@selector(menuDidChangeItem:)
                  name:CPMenuDidChangeItemNotification
                object:_menu];

        [defaultCenter
            addObserver:self
              selector:@selector(menuDidRemoveItem:)
                  name:CPMenuDidRemoveItemNotification
                object:_menu];
    }

    _menuItemViews = [];

    var contentView = [self contentView],
        items = [_menu itemArray],
        count = items.length;

    for (var index = 0; index < count; ++index)
    {
        var item = items[index],
            menuItemView = [item _menuItemView];

        _menuItemViews.push(menuItemView);

        [menuItemView setTextColor:_textColor];
        [menuItemView setHidden:[item isHidden]];

        [menuItemView synchronizeWithMenuItem];

        [contentView addSubview:menuItemView];
    }

    [self tile];
}

- (void)menuDidChangeItem:(CPNotification)aNotification
{
    var menuItem = [_menu itemAtIndex:[[aNotification userInfo] objectForKey:@"CPMenuItemIndex"]],
        menuItemView = [menuItem _menuItemView];

    [menuItemView setHidden:[menuItem isHidden]];
    [menuItemView synchronizeWithMenuItem];

    [self tile];
}

- (void)menuDidAddItem:(CPNotification)aNotification
{
    var index = [[aNotification userInfo] objectForKey:@"CPMenuItemIndex"],
        menuItem = [_menu itemAtIndex:index],
        menuItemView = [menuItem _menuItemView];

    [_menuItemViews insertObject:menuItemView atIndex:index];

    [menuItemView setTextColor:_textColor];
    [menuItemView setHidden:[menuItem isHidden]];

    [menuItemView synchronizeWithMenuItem];

    [[self contentView] addSubview:menuItemView];

    [self tile];
}

- (void)menuDidRemoveItem:(CPNotification)aNotification
{
    var index = [[aNotification userInfo] objectForKey:@"CPMenuItemIndex"],
        menuItemView = [_menuItemViews objectAtIndex:index];

    [_menuItemViews removeObjectAtIndex:index];

    [menuItemView removeFromSuperview];

    [self tile];
}

- (BOOL)acceptsFirstMouse:(CPEvent)anEvent
{
    return YES;
}

- (void)mouseDown:(CPEvent)anEvent
{
    var constraintRect = CGRectInset([[self platformWindow] visibleFrame], 5.0, 0.0);

    constraintRect.size.height -= 5.0;

    [[_CPMenuManager sharedMenuManager]
        beginTracking:anEvent
        menuContainer:self
       constraintRect:constraintRect
             callback:function(aMenuContainer, aMenu)
             {
                [aMenu _performActionOfHighlightedItemChain];
                [aMenu _highlightItemAtIndex:CPNotFound];
             }];
}

- (CPFont)font
{
    [CPFont systemFontOfSize:[CPFont systemFontSize]];
}

- (void)tile
{
    var items = [_menu itemArray],
        index = 0,
        count = items.length,

        x = [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-window-left-margin" forClass:_CPMenuView],
        y = 0.0,
        isLeftAligned = YES;

    for (; index < count; ++index)
    {
        var item = items[index];

        if ([item isSeparatorItem])
        {
            x = CGRectGetWidth([self frame]) - [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-window-right-margin" forClass:_CPMenuView];
            isLeftAligned = NO;

            continue;
        }

         if ([item isHidden])
            continue;

        var menuItemView = [item _menuItemView],
            frame = [menuItemView frame];

        if (isLeftAligned)
        {
            [menuItemView setFrame:CGRectMake(x, 0.0, CGRectGetWidth(frame), [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-window-height" forClass:_CPMenuView])];

            x += CGRectGetWidth([menuItemView frame]);
        }
        else
        {
            [menuItemView setFrame:CGRectMake(x - CGRectGetWidth(frame), 0.0, CGRectGetWidth(frame), [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-bar-window-height" forClass:_CPMenuView])];

            x = CGRectGetMinX([menuItemView frame]);
        }
    }

    var bounds = [[self contentView] bounds],
        titleFrame = [_titleField frame];

    if ([_iconImageView isHidden])
        [_titleField setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - CGRectGetWidth(titleFrame)) / 2.0, (CGRectGetHeight(bounds) - CGRectGetHeight(titleFrame)) / 2.0)];
    else
    {
        var iconFrame = [_iconImageView frame],
            iconWidth = CGRectGetWidth(iconFrame),
            totalWidth = iconWidth + CGRectGetWidth(titleFrame);

        [_iconImageView setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - totalWidth) / 2.0, (CGRectGetHeight(bounds) - CGRectGetHeight(iconFrame)) / 2.0)];
        [_titleField setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - totalWidth) / 2.0 + iconWidth, (CGRectGetHeight(bounds) - CGRectGetHeight(titleFrame)) / 2.0)];
    }
}

- (void)setFrame:(CGRect)aRect display:(BOOL)shouldDisplay animate:(BOOL)shouldAnimate
{
    var size = [self frame].size;

    [super setFrame:aRect display:shouldDisplay animate:shouldAnimate];

    if (!CGSizeEqualToSize(size, aRect.size))
        [self tile];
}

@end

@implementation _CPMenuBarWindow (CPMenuContainer)

- (BOOL)isMenuBar
{
    return YES;
}

- (CGRect)globalFrame
{
    return [self frame];
}

- (_CPManagerScrollingState)scrollingStateForPoint:(CGPoint)aGlobalLocation
{
    return _CPMenuManagerScrollingStateNone;
}

- (CPInteger)itemIndexAtPoint:(CGPoint)aPoint
{
    var items = [_menu itemArray],
        index = items.length;

    while (index--)
    {
        var item = items[index];

        if ([item isHidden] || [item isSeparatorItem])
            continue;

        if (CGRectContainsPoint([self rectForItemAtIndex:index], aPoint))
            return index;
    }

    return CPNotFound;
}

- (CGRect)rectForItemAtIndex:(CPInteger)anIndex
{
    var menuItem = [_menu itemAtIndex:anIndex === CPNotFound ? 0 : anIndex];

    return [[menuItem _menuItemView] frame];
}

@end
