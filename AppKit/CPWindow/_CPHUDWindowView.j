/*
 * _CPHUDWindowView.j
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

@import "CPTextField.j"
@import "_CPTitleableWindowView.j"

var _CPHUDWindowViewBackgroundColor = nil,
    _CPHUDWindowViewThemeValues     = nil,

    CPHUDCloseButtonImage           = nil;

var HUD_TITLEBAR_HEIGHT             = 26.0;

@implementation _CPHUDWindowView : _CPTitleableWindowView
{
    CPView              _toolbarView;
    CPButton            _closeButton;
}

+ (void)initialize
{
    if (self !== [_CPHUDWindowView class])
        return;

    var bundle = [CPBundle bundleForClass:self];

    _CPHUDWindowViewBackgroundColor = [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:
        [
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground0.png"] size:CPSizeMake(7.0, 37.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground1.png"] size:CPSizeMake(1.0, 37.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground2.png"] size:CPSizeMake(7.0, 37.0)],

            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground3.png"] size:CPSizeMake(7.0, 1.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground4.png"] size:CPSizeMake(2.0, 2.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground5.png"] size:CPSizeMake(7.0, 1.0)],

            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground6.png"] size:CPSizeMake(7.0, 3.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground7.png"] size:CPSizeMake(1.0, 3.0)],
            [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/HUD/CPWindowHUDBackground8.png"] size:CPSizeMake(7.0, 3.0)]
        ]]];

    _CPHUDWindowViewCloseImage        = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"HUDTheme/WindowClose.png"] size:CPSizeMake(18.0, 18.0)];
    _CPHUDWindowViewCloseActiveImage  = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"HUDTheme/WindowCloseActive.png"] size:CPSizeMake(18.0, 18.0)];

    _CPHUDWindowViewThemeValues = [
        [@"title-font",                 [CPFont systemFontOfSize:[CPFont systemFontSize] - 1]],
        [@"title-text-color",           [CPColor colorWithWhite:255.0 / 255.0 alpha:0.75]],
        [@"title-text-color",           [CPColor colorWithWhite:255.0 / 255.0 alpha:1], CPThemeStateKeyWindow],
        [@"title-text-shadow-color",    [CPColor blackColor]],
        [@"title-text-shadow-offset",   CGSizeMake(0.0, 1.0)],
        [@"title-alignment",            CPCenterTextAlignment],
        // FIXME: Make this to CPLineBreakByTruncatingMiddle once it's implemented.
        [@"title-line-break-mode",      CPLineBreakByTruncatingTail],
        [@"title-vertical-alignment",   CPCenterVerticalTextAlignment]
    ];
}

+ (int)titleBarHeight
{
    return HUD_TITLEBAR_HEIGHT;
}

- (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    var contentRect = [[self class] contentRectForFrameRect:aFrameRect];

    if ([[[self window] toolbar] isVisible])
    {
        var toolbarHeight = CGRectGetHeight([[self toolbarView] frame]);

        contentRect.origin.y += toolbarHeight;
        contentRect.size.height -= toolbarHeight;
    }

    return contentRect;
}

- (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    var frameRect = [[self class] frameRectForContentRect:aContentRect];

    if ([[[self window] toolbar] isVisible])
    {
        var toolbarHeight = CGRectGetHeight([[self toolbarView] frame]);

        frameRect.origin.y -= toolbarHeight;
        frameRect.size.height += toolbarHeight;
    }

    return frameRect;
}

- (id)initWithFrame:(CPRect)aFrame styleMask:(unsigned)aStyleMask
{
    self = [super initWithFrame:aFrame styleMask:aStyleMask];

    if (self)
    {
        // Until windows become properly themable, just set these values here in the subclass.
        [self registerThemeValues:_CPHUDWindowViewThemeValues];

        var bounds = [self bounds];

        [self setBackgroundColor:_CPHUDWindowViewBackgroundColor];

        if (_styleMask & CPClosableWindowMask)
        {
            var closeSize = [_CPHUDWindowViewCloseImage size];

            _closeButton = [[CPButton alloc] initWithFrame:CGRectMake(8.0, 4.0, closeSize.width, closeSize.height)];

            [_closeButton setBordered:NO];

            [_closeButton setImage:_CPHUDWindowViewCloseImage];
            [_closeButton setAlternateImage:_CPHUDWindowViewCloseActiveImage];

            [self addSubview:_closeButton];
        }

        [self setResizeIndicatorOffset:CGSizeMake(5.0, 5.0)];

        [self tile];
    }

    return self;
}

- (void)viewDidMoveToWindow
{
    [_closeButton setTarget:[self window]];
    [_closeButton setAction:@selector(performClose:)];
}

- (_CPToolbarView)toolbarView
{
    return _toolbarView;
}

- (CPColor)toolbarLabelColor
{
    return [CPColor whiteColor];
}

- (CPColor)toolbarLabelShadowColor
{
    return [CPColor blackColor];
}

- (CGSize)toolbarOffset
{
    return _CGSizeMake(0.0, [[self class] titleBarHeight]);
}

- (void)tile
{
    [super tile];

    var theWindow = [self window],
        bounds = [self bounds],
        width = _CGRectGetWidth(bounds);

    [_titleField setFrame:_CGRectMake(20.0, 0, width - 40.0, [self toolbarOffset].height)];

    var maxY = [self toolbarMaxY];
    if ([_titleField isHidden])
        maxY -= ([self toolbarOffset]).height;

    var contentRect = _CGRectMake(0.0, maxY, width, _CGRectGetHeight(bounds) - maxY);

    [[theWindow contentView] setFrame:contentRect];
}

- (void)_enableSheet:(BOOL)enable
{
    [super _enableSheet:enable];

    [_closeButton setHidden:enable];
    [_titleField setHidden:enable];

    // resize the window
    var theWindow = [self window],
        frame = [theWindow frame],
        dy = ([self toolbarOffset]).height;

    if (enable)
        dy = -dy;

    var newHeight = _CGRectGetMaxY(frame) + dy,
        newWidth = _CGRectGetMaxX(frame);

    frame.size.height += dy;

    [self setFrameSize:_CGSizeMake(newWidth, newHeight)];
    [self tile];
    [theWindow setFrame:frame display:NO animate:NO];
    [theWindow setMovableByWindowBackground:!enable];
}

@end
