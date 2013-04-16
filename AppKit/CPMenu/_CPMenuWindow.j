/*
 * _CPMenuWindow.j
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

@import "CPClipView.j"
@import "CPImageView.j"
@import "CPWindow.j"
@import "_CPMenuManager.j"

var _CPMenuWindowPool                       = [],
    _CPMenuWindowPoolCapacity               = 5,

    _CPMenuWindowBackgroundColors           = [];

_CPMenuWindowMenuBarBackgroundStyle         = 0;
_CPMenuWindowPopUpBackgroundStyle           = 1;
_CPMenuWindowAttachedMenuBackgroundStyle    = 2;

/*
    @ignore
*/
@implementation _CPMenuWindow : CPWindow
{
    _CPMenuView         _menuView;
    CPClipView          _menuClipView;

    CPImageView         _moreAboveView;
    CPImageView         _moreBelowView;

    CGRect              _unconstrainedFrame;
    CGRect              _constraintRect;
}

+ (id)menuWindowWithMenu:(CPMenu)aMenu font:(CPFont)aFont
{
    var menuWindow = nil;

    if (_CPMenuWindowPool.length)
    {
        menuWindow = _CPMenuWindowPool.pop();

        // Do this so that coordinates will be accurate.
        [menuWindow setFrameOrigin:CGPointMakeZero()];
    }
    else
        menuWindow = [[_CPMenuWindow alloc] init];

    [menuWindow setFont:aFont];
    [menuWindow setMenu:aMenu];
    [menuWindow setMinWidth:[aMenu minimumWidth]];

    return menuWindow;
}

+ (void)poolMenuWindow:(_CPMenuWindow)aMenuWindow
{
    if (!aMenuWindow || _CPMenuWindowPool.length >= _CPMenuWindowPoolCapacity)
        return;

    _CPMenuWindowPool.push(aMenuWindow);
}

- (id)initWithContentRect:(CGRect)aRect styleMask:(unsigned)aStyleMask
{
    _constraintRect = CGRectMakeZero();
    _unconstrainedFrame = CGRectMakeZero();

    self = [super initWithContentRect:aRect styleMask:CPBorderlessWindowMask];

    if (self)
    {
        _constrainsToUsableScreen = NO;

        [self setLevel:CPPopUpMenuWindowLevel];
        [self setHasShadow:YES];
        [self setShadowStyle:CPMenuWindowShadowStyle];
        [self setAcceptsMouseMovedEvents:YES];

        var contentView = [self contentView];

        _menuView = [[_CPMenuView alloc] initWithFrame:CGRectMakeZero()];

        _menuClipView = [[CPClipView alloc] initWithFrame:CGRectMake([_menuView valueForThemeAttribute:@"menu-window-margin-inset"].left, [_menuView valueForThemeAttribute:@"menu-window-margin-inset"].top, 0.0, 0.0)];
        [_menuClipView setDocumentView:_menuView];

        [contentView addSubview:_menuClipView];

        _moreAboveView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];

        [_moreAboveView setImage:[_menuView valueForThemeAttribute:@"menu-window-more-above-image"]];
        [_moreAboveView setFrameSize:[[_menuView valueForThemeAttribute:@"menu-window-more-above-image"] size]];

        [contentView addSubview:_moreAboveView];

        _moreBelowView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];

        [_moreBelowView setImage:[_menuView valueForThemeAttribute:@"menu-window-more-below-image"]];
        [_moreBelowView setFrameSize:[[_menuView valueForThemeAttribute:@"menu-window-more-below-image"] size]];

        [contentView addSubview:_moreBelowView];
    }

    return self;
}

+ (float)_standardLeftMargin
{
    return [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-window-margin-inset" forClass:_CPMenuView].left;
}

- (void)setFont:(CPFont)aFont
{
    [_menuView setFont:aFont];
}

- (CPFont)font
{
    return [_menuView font];
}

+ (CPColor)backgroundColorForBackgroundStyle:(_CPMenuWindowBackgroundStyle)aBackgroundStyle
{
    var color = _CPMenuWindowBackgroundColors[aBackgroundStyle];

    if (!color)
    {
        var bundle = [CPBundle bundleForClass:[self class]];

        if (aBackgroundStyle == _CPMenuWindowPopUpBackgroundStyle)
            color = [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-window-pop-up-background-style-color" forClass:_CPMenuView];

        else if (aBackgroundStyle == _CPMenuWindowMenuBarBackgroundStyle)
            color = [[CPTheme defaultTheme] valueForAttributeWithName:@"menu-window-menu-bar-background-style-color" forClass:_CPMenuView];

        _CPMenuWindowBackgroundColors[aBackgroundStyle] = color;
    }

    return color;
}

- (void)setBackgroundStyle:(_CPMenuWindowBackgroundStyle)aBackgroundStyle
{
    [self setBackgroundColor:[[self class] backgroundColorForBackgroundStyle:aBackgroundStyle]];
}

- (void)setMenu:(CPMenu)aMenu
{
    [aMenu _setMenuWindow:self];
    [_menuView setMenu:aMenu];

    var menuViewSize = [_menuView frame].size,
        marginInset = [_menuView valueForThemeAttribute:@"menu-window-margin-inset"];

    [self setFrameSize:CGSizeMake(marginInset.left + menuViewSize.width + marginInset.right, marginInset.top + menuViewSize.height + marginInset.bottom)];

    [_menuView scrollPoint:CGPointMake(0.0, 0.0)];
    [_menuClipView setFrame:CGRectMake(marginInset.left, marginInset.top, menuViewSize.width, menuViewSize.height)];
}

- (void)setMinWidth:(float)aWidth
{
    var size = [self unconstrainedFrame].size;

    [self setFrameSize:CGSizeMake(MAX(size.width, aWidth), size.height)];
}

- (CPMenu)menu
{
    return [_menuView menu];
}

- (_CPMenuView)_menuView
{
    return _menuView;
}

- (void)orderFront:(id)aSender
{
    [[self menu] update];
    [self setFrame:_unconstrainedFrame];

    [super orderFront:aSender];
}

- (void)setConstraintRect:(CGRect)aRect
{
    _constraintRect = aRect;

    [self setFrame:_unconstrainedFrame];
}

- (CGRect)unconstrainedFrame
{
    return CGRectMakeCopy(_unconstrainedFrame);
}

// We need this because if not this will call setFrame: with -frame instead of -unconstrainedFrame, turning
// the constrained frame into the unconstrained frame.
- (void)setFrameOrigin:(CGPoint)aPoint
{
    [super setFrame:CGRectMake(aPoint.x, aPoint.y, CGRectGetWidth(_unconstrainedFrame), CGRectGetHeight(_unconstrainedFrame))];
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrame:CGRectMake(CGRectGetMinX(_unconstrainedFrame), CGRectGetMinY(_unconstrainedFrame), aSize.width, aSize.height)];
}

- (void)setFrame:(CGRect)aFrame display:(BOOL)shouldDisplay animate:(BOOL)shouldAnimate
{
    // FIXME: There are integral window issues with platform windows.
    // FIXME: This gets called far too often.
    _unconstrainedFrame = CGRectMakeCopy(aFrame);

    var constrainedFrame = CGRectIntersection(_unconstrainedFrame, _constraintRect),
        marginInset = [_menuView valueForThemeAttribute:@"menu-window-margin-inset"],
        scrollIndicatorHeight = [_menuView valueForThemeAttribute:@"menu-window-scroll-indicator-height"];

    // We don't want to simply intersect the visible frame and the unconstrained frame.
    // We should be allowing as much of the width to fit as possible (pushing back and forward).
    constrainedFrame.origin.x = CGRectGetMinX(_unconstrainedFrame);
    constrainedFrame.size.width = CGRectGetWidth(_unconstrainedFrame);

    if (CGRectGetWidth(constrainedFrame) > CGRectGetWidth(_constraintRect))
        constrainedFrame.size.width = CGRectGetWidth(_constraintRect);

    if (CGRectGetMaxX(constrainedFrame) > CGRectGetMaxX(_constraintRect))
        constrainedFrame.origin.x -= CGRectGetMaxX(constrainedFrame) - CGRectGetMaxX(_constraintRect);

    if (CGRectGetMinX(constrainedFrame) < CGRectGetMinX(_constraintRect))
        constrainedFrame.origin.x = CGRectGetMinX(_constraintRect);

    [super setFrame:constrainedFrame display:shouldDisplay animate:shouldAnimate];

    // This needs to happen before changing the frame.
    var menuViewOrigin = CGPointMake(CGRectGetMinX(aFrame) + marginInset.left, CGRectGetMinY(aFrame) + marginInset.top),
        moreAbove = menuViewOrigin.y < CGRectGetMinY(constrainedFrame) + marginInset.top,
        moreBelow = menuViewOrigin.y + CGRectGetHeight([_menuView frame]) > CGRectGetMaxY(constrainedFrame) - marginInset.bottom,

        topMargin = marginInset.top,
        bottomMargin = marginInset.bottom,

        contentView = [self contentView],
        bounds = [contentView bounds];

    if (moreAbove)
    {
        topMargin += scrollIndicatorHeight;

        var frame = [_moreAboveView frame];

        [_moreAboveView setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - CGRectGetWidth(frame)) / 2.0, (marginInset.top + scrollIndicatorHeight - CGRectGetHeight(frame)) / 2.0)];
    }

    [_moreAboveView setHidden:!moreAbove];

    if (moreBelow)
    {
        bottomMargin += scrollIndicatorHeight;

        [_moreBelowView setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - CGRectGetWidth([_moreBelowView frame])) / 2.0, CGRectGetHeight(bounds) - scrollIndicatorHeight - marginInset.bottom)];
    }

    [_moreBelowView setHidden:!moreBelow];

    var clipFrame = CGRectMakeZero();

    clipFrame.origin.x = marginInset.left;
    clipFrame.origin.y = topMargin;
    clipFrame.size.width = CGRectGetWidth(constrainedFrame) - marginInset.left - marginInset.right;
    clipFrame.size.height = CGRectGetHeight(constrainedFrame) - topMargin - bottomMargin;

    [_menuClipView setFrame:clipFrame];
    [_menuView setFrameSize:CGSizeMake(CGRectGetWidth(clipFrame), CGRectGetHeight([_menuView frame]))];

    [_menuView scrollPoint:CGPointMake(0.0, [self convertBaseToGlobal:clipFrame.origin].y - menuViewOrigin.y)];
}

- (BOOL)hasMinimumNumberOfVisibleItems
{
    var visibleRect = [_menuView visibleRect];

    // Clearly if the entire view isn't visible the minimum won't be visible.
    if (CGRectIsEmpty(visibleRect))
        return NO;

    var numberOfUnhiddenItems = [_menuView numberOfUnhiddenItems],
        minimumNumberOfVisibleItems = MIN(numberOfUnhiddenItems, 3),
        count = 0,
        index = [_menuView itemIndexAtPoint:[_menuView convertPoint:[_menuClipView frame].origin fromView:nil]];

    for (; index < numberOfUnhiddenItems && count < minimumNumberOfVisibleItems; ++index)
    {
        var itemRect = [_menuView rectForUnhiddenItemAtIndex:index],
            visibleItemRect = CGRectIntersection(visibleRect, itemRect);

        // As soon as we get to the first unhidden item that is no longer visible, stop.
        if (CGRectIsEmpty(visibleItemRect))
            break;

        // If the item is *completely* visible, count it.
        if (CGRectEqualToRect(visibleItemRect, itemRect))
            ++count;
    }

    return count >= minimumNumberOfVisibleItems;
}

- (BOOL)canScrollUp
{
    return ![_moreAboveView isHidden];
}

- (BOOL)canScrollDown
{
    return ![_moreBelowView isHidden];
}

- (BOOL)canScroll
{
    return [self canScrollUp] || [self canScrollDown];
}

- (void)scrollByDelta:(float)theDelta
{
    if (theDelta === 0.0)
        return;

    if (theDelta > 0.0 && ![self canScrollDown])
        return;

    if (theDelta < 0.0 && ![self canScrollUp])
        return;

    _unconstrainedFrame.origin.y -= theDelta;
    [self setFrame:_unconstrainedFrame];
}

- (void)scrollUp
{
    [self scrollByDelta:-10.0];
}

- (void)scrollDown
{
    [self scrollByDelta:10.0];
}

@end

@implementation _CPMenuWindow (CPMenuContainer)

- (CGRect)globalFrame
{
    return [self frame];
}

- (BOOL)isMenuBar
{
    return NO;
}

- (_CPManagerScrollingState)scrollingStateForPoint:(CGPoint)aGlobalLocation
{
    var frame = [self frame];
    if (!CGRectContainsPoint(frame,aGlobalLocation) || ![self canScroll])
        return _CPMenuManagerScrollingStateNone;

    // If we're at or above of the top scroll indicator...
    if (aGlobalLocation.y < CGRectGetMinY(frame) + [_menuView valueForThemeAttribute:@"menu-window-margin-inset"].top + [_menuView valueForThemeAttribute:@"menu-window-scroll-indicator-height"] &&  ![_moreAboveView isHidden])
        return _CPMenuManagerScrollingStateUp;

    // If we're at or below the bottom scroll indicator...
    if (aGlobalLocation.y > CGRectGetMaxY(frame) - [_menuView valueForThemeAttribute:@"menu-window-margin-inset"].bottom - [_menuView valueForThemeAttribute:@"menu-window-scroll-indicator-height"] &&  ![_moreBelowView isHidden])
        return _CPMenuManagerScrollingStateDown;

    return _CPMenuManagerScrollingStateNone;
}

- (float)deltaYForItemAtIndex:(int)anIndex
{
    return [_menuView valueForThemeAttribute:@"menu-window-margin-inset"].top + CGRectGetMinY([_menuView rectForItemAtIndex:anIndex]);
}

- (CGPoint)rectForItemAtIndex:(int)anIndex
{
    return [_menuView convertRect:[_menuView rectForItemAtIndex:anIndex] toView:nil];
}

- (int)itemIndexAtPoint:(CGPoint)aPoint
{
    // Don't return indexes of items that aren't visible.
    if (!CGRectContainsPoint([_menuClipView bounds], [_menuClipView convertPoint:aPoint fromView:nil]))
        return NO;

    return [_menuView itemIndexAtPoint:[_menuView convertPoint:aPoint fromView:nil]];
}

@end

/*
    @ignore
*/

@implementation _CPMenuView : CPView
{
    CPArray _menuItemViews;
    CPArray _visibleMenuItemInfos;

    CPFont  _font @accessors(property=font);
}


+ (CPString)defaultThemeClass
{
    return "menu-view";
}

+ (id)themeAttributes
{
    return @{
            @"menu-window-more-above-image": [CPNull null],
            @"menu-window-more-below-image": [CPNull null],
            @"menu-window-pop-up-background-style-color": [CPNull null],
            @"menu-window-menu-bar-background-style-color": [CPNull null],
            @"menu-window-margin-inset": CGInsetMake(5.0, 1.0, 1.0, 5.0),
            @"menu-window-scroll-indicator-height": 16.0,
            @"menu-bar-window-background-color": [CPNull null],
            @"menu-bar-window-background-selected-color": [CPNull null],
            @"menu-bar-window-font": [CPNull null],
            @"menu-bar-window-height": 30.0,
            @"menu-bar-window-margin": 10.0,
            @"menu-bar-window-left-margin": 10.0,
            @"menu-bar-window-right-margin": 10.0,
            @"menu-bar-text-color": [CPNull null],
            @"menu-bar-title-color": [CPNull null],
            @"menu-bar-text-shadow-color": [CPNull null],
            @"menu-bar-title-shadow-color": [CPNull null],
            @"menu-bar-highlight-color": [CPNull null],
            @"menu-bar-highlight-text-color": [CPNull null],
            @"menu-bar-highlight-text-shadow-color": [CPNull null],
            @"menu-bar-height": 28.0,
            @"menu-bar-icon-image": [CPNull null],
            @"menu-bar-icon-image-alpha-value": 1.0,
            @"menu-general-icon-new": [CPNull null],
            @"menu-general-icon-save": [CPNull null],
            @"menu-general-icon-open": [CPNull null],
        };
}

- (unsigned)numberOfUnhiddenItems
{
    return _visibleMenuItemInfos.length;
}

- (CGRect)rectForUnhiddenItemAtIndex:(int)anIndex
{
    return [self rectForItemAtIndex:_visibleMenuItemInfos[anIndex].index];
}

- (CGRect)rectForItemAtIndex:(int)anIndex
{
    return [_menuItemViews[anIndex === CPNotFound ? 0 : anIndex] frame];
}

- (int)itemIndexAtPoint:(CGPoint)aPoint
{
    var x = aPoint.x,
        bounds = [self bounds];

    if (x < CGRectGetMinX(bounds) || x > CGRectGetMaxX(bounds))
        return CPNotFound;

    var y = aPoint.y,
        low = 0,
        high = _visibleMenuItemInfos.length - 1;

    while (low <= high)
    {
        var middle = FLOOR(low + (high - low) / 2),
            info = _visibleMenuItemInfos[middle],
            frame = [info.view frame];

        if (y < CGRectGetMinY(frame))
            high = middle - 1;

        else if (y > CGRectGetMaxY(frame))
            low = middle + 1;

        else
            return info.index;
   }

   return CPNotFound;
}

- (void)tile
{
    [_menuItemViews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    _menuItemViews = [];
    _visibleMenuItemInfos = [];

    var menu = [self menu];

    if (!menu)
        return;

    var items = [menu itemArray],
        index = 0,
        count = [items count],
        maxWidth = 0,
        y = 0,
        showsStateColumn = [menu showsStateColumn];

    for (; index < count; ++index)
    {
        var item = items[index],
            view = [item _menuItemView];

        _menuItemViews.push(view);

        if ([item isHidden])
            continue;

        _visibleMenuItemInfos.push({ view:view, index:index });

        [view setFont:_font];
        [view setShowsStateColumn:showsStateColumn];
        [view synchronizeWithMenuItem];

        [view setFrameOrigin:CGPointMake(0.0, y)];

        [self addSubview:view];

        var size = [view minSize],
            width = size.width;

        if (maxWidth < width)
            maxWidth = width;

        y += size.height;
    }

    for (index = 0; index < count; ++index)
    {
        var view = _menuItemViews[index];

        [view setFrameSize:CGSizeMake(maxWidth, CGRectGetHeight([view frame]))];
    }

    [self setAutoresizesSubviews:NO];
    [self setFrameSize:CGSizeMake(maxWidth, y)];
    [self setAutoresizesSubviews:YES];
}

- (void)setMenu:(CPMenu)aMenu
{
    [super setMenu:aMenu];
    [self tile];
}

@end
