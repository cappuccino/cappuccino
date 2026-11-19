/*
 * _CPBorderlessWindowView.j
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

@import "_CPWindowView.j"
@import "CPCompatibility.j"

/*
    The view of a window that fills its platform window. It draws a background by default: the
    theme's bezel colour in the view's current state, else +[CPColor windowBackgroundColor],
    as an NSWindow draws its window background. A colour that the application sets stays.

    The view drew no background, so the page behind a full-page window showed through every
    view without a background of its own. The page is outside the appearance system, so those
    areas followed neither the system appearance nor the application's, and each application
    that followed the appearance had to set the window background itself.
*/
@implementation _CPBorderlessBridgeWindowView : _CPWindowView
{
    CPView  _toolbarBackgroundView;
    BOOL    _usesDefaultBackgroundColor;
}

+ (CPString)defaultThemeClass
{
    return @"borderless-bridge-window-view";
}

+ (CPDictionary)themeAttributes
{
    return @{
            @"toolbar-background-color": [CPColor grayColor],
        };
}

- (id)initWithFrame:(CGRect)aFrame styleMask:(unsigned)aStyleMask
{
    self = [super initWithFrame:aFrame styleMask:aStyleMask];

    if (self)
    {
        /*
            The black of the HUD style counts as a colour of the window's own until the HUD
            style takes its background from the theme.
        */
        [self setBackgroundColor:(aStyleMask & CPHUDBackgroundWindowMask) ? [CPColor blackColor] : nil];
    }

    return self;
}

/*
    Sets the background colour. A nil colour gives the default background (see
    -_defaultBackgroundColor), which follows the theme state and the appearance. For a window
    that shows the page behind it, set +[CPColor clearColor].
*/
- (void)setBackgroundColor:(CPColor)aColor
{
    if (aColor === [CPNull null])
        aColor = nil;

    _usesDefaultBackgroundColor = !aColor;

    [super setBackgroundColor:aColor || [self _defaultBackgroundColor]];
}

/*
    Returns the default background: the theme's bezel colour in the receiver's current state,
    else the window background colour, AppKit's default.
*/
- (CPColor)_defaultBackgroundColor
{
    return [self currentValueForThemeAttribute:@"bezel-color"] || [CPColor windowBackgroundColor];
}

/*
    A change of theme state, theme or appearance lays the view out, so the default background
    follows it. A colour of the application's own stays.
*/
- (void)layoutSubviews
{
    [super layoutSubviews];

    if (_usesDefaultBackgroundColor)
        [super setBackgroundColor:[self _defaultBackgroundColor]];
}

- (void)setShowsResizeIndicator:(BOOL)shouldShowResizeIndicator
{
    // We don't ever want to show the resize indicator.
}

- (void)tile
{
    [super tile];

    var theWindow = [self window],
        bounds = [self bounds];

    [[theWindow contentView] setFrame:CGRectMake(0.0, [self toolbarMaxY], CGRectGetWidth(bounds), CGRectGetHeight(bounds) - [self toolbarMaxY])];

    if (![[theWindow toolbar] isVisible])
    {
        [_toolbarBackgroundView removeFromSuperview];

        _toolbarBackgroundView = nil;

        return;
    }

    if (!_toolbarBackgroundView)
    {
        _toolbarBackgroundView = [[CPView alloc] initWithFrame:CGRectMakeZero()];

        [_toolbarBackgroundView setBackgroundColor:[self valueForThemeAttribute:@"toolbar-background-color"]];
        [_toolbarBackgroundView setAutoresizingMask:CPViewWidthSizable];

        [self addSubview:_toolbarBackgroundView positioned:CPWindowBelow relativeTo:nil];
    }

    var frame = CGRectMakeZero(),
        toolbarOffset = [self toolbarOffset];

    frame.origin = CGPointMake(toolbarOffset.width, toolbarOffset.height);
    frame.size = [_toolbarView frame].size;

    [_toolbarBackgroundView setFrame:frame];
}

- (void)setFrameSize:(CGSize)aFrameSize
{
    [super setFrameSize:aFrameSize];

    var theWindow = [self window];

    if (_frame.size.width < theWindow._minSize.width || _frame.size.height < theWindow._minSize.height)
        [theWindow._contentView setFrameSize:CGSizeMake(MAX(_frame.size.width, theWindow._minSize.width), MAX(_frame.size.height, theWindow._minSize.height))];

    if (CPDOMAvailable)
    {
        _DOMElement.style.overflowX = (_frame.size.width < theWindow._minSize.width)? "scroll":"hidden";
        _DOMElement.style.overflowY = (_frame.size.height < theWindow._minSize.height)? "scroll":"hidden";
    }
}

@end
