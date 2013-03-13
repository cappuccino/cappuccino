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

@import "CPButton.j"
@import "CPTextField.j"
@import "_CPTitleableWindowView.j"


@implementation _CPHUDWindowView : _CPTitleableWindowView
{
    CPView              _toolbarView;
    CPButton            _closeButton;
}

+ (CPString)defaultThemeClass
{
    return @"hud-window-view";
}

+ (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    /*
        This window view class draws a frame.
        So we have to inset the content rect to be inside the frame.
        The top coordinate has already been adjusted by _CPTitleableWindowView.
    */
    var contentRect = [super contentRectForFrameRect:aFrameRect];

    contentRect.origin.x += 1;
    contentRect.size.width -= 2;
    contentRect.size.height -= 1;

    return contentRect;
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

- (id)initWithFrame:(CGRect)aFrame styleMask:(unsigned)aStyleMask
{
    self = [super initWithFrame:aFrame styleMask:aStyleMask];

    if (self)
    {
        if (_styleMask & CPClosableWindowMask)
        {
            _closeButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
            [_closeButton setBordered:NO];
            [_closeButton setButtonType:CPMomentaryChangeButton];
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
    return CGSizeMake(0.0, [[self class] titleBarHeight]);
}

- (void)tile
{
    [super tile];

    var theWindow = [self window],
        bounds = [self bounds],
        width = CGRectGetWidth(bounds);

    [_titleField setFrame:CGRectMake(20.0, 0, width - 40.0, [self toolbarOffset].height)];

    var maxY = [self toolbarMaxY];
    if ([_titleField isHidden])
        maxY -= ([self toolbarOffset]).height;

    var contentRect = CGRectMake(0.0, maxY, width, CGRectGetHeight(bounds) - maxY);

    [[theWindow contentView] setFrame:contentRect];
}

- (void)_enableSheet:(BOOL)enable inWindow:(CPWindow)parentWindow
{
    // No need to call super, it just deals with the shadow view, which we don't want

    [_closeButton setHidden:enable];
    [_titleField setHidden:enable];

    // resize the window
    var theWindow = [self window],
        frame = [theWindow frame],
        dy = ([self toolbarOffset]).height;

    if (enable)
        dy = -dy;

    var newHeight = CGRectGetMaxY(frame) + dy,
        newWidth = CGRectGetMaxX(frame);

    frame.size.height += dy;

    [self setFrameSize:CGSizeMake(newWidth, newHeight)];
    [self tile];
    [theWindow setFrame:frame display:NO animate:NO];
    [theWindow setMovableByWindowBackground:!enable];

    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (_styleMask & CPClosableWindowMask)
    {
        [_closeButton setFrameOrigin:[self valueForThemeAttribute:@"close-image-origin"]];
        [_closeButton setFrameSize:[self valueForThemeAttribute:@"close-image-size"]]
        [_closeButton setImage:[self valueForThemeAttribute:@"close-image"]];
        [_closeButton setAlternateImage:[self valueForThemeAttribute:@"close-active-image"]];
    }
}

@end
