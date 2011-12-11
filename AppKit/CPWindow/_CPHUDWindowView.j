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

var _CPHUDWindowViewBackgroundColor = nil,

    CPHUDCloseButtonImage           = nil;

var HUD_TITLEBAR_HEIGHT             = 26.0;

@implementation _CPHUDWindowView : _CPWindowView
{
    CPView              _toolbarView;

    CPTextField         _titleField;
    CPButton            _closeButton;
}

+ (void)initialize
{
    if (self != [_CPHUDWindowView class])
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
}

+ (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    var contentRect = CGRectMakeCopy(aFrameRect),
        titleBarHeight = HUD_TITLEBAR_HEIGHT;

    contentRect.origin.y += titleBarHeight;
    contentRect.size.height -= titleBarHeight;

    return contentRect;
}

+ (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    var frameRect = CGRectMakeCopy(aContentRect),
        titleBarHeight = HUD_TITLEBAR_HEIGHT;

    frameRect.origin.y -= titleBarHeight;
    frameRect.size.height += titleBarHeight;

    return frameRect;
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
        var bounds = [self bounds];

        [self setBackgroundColor:_CPHUDWindowViewBackgroundColor];

        _titleField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

        [_titleField setHitTests:NO];
        [_titleField setFont:[CPFont systemFontOfSize:11.0]];
        [_titleField setTextColor:[CPColor whiteColor]];
        [_titleField setTextShadowColor:[CPColor blackColor]];
        [_titleField setTextShadowOffset:CGSizeMake(0.0, 1.0)];
        [_titleField setAutoresizingMask:CPViewWidthSizable];

        // FIXME: Make this to CPLineBreakByTruncatingMiddle once it's implemented.
        [_titleField setLineBreakMode:CPLineBreakByTruncatingTail];
        [_titleField setAlignment:CPCenterTextAlignment];

        [_titleField setStringValue:@"Untitled"];
        [_titleField sizeToFit];
        [_titleField setAutoresizingMask:CPViewWidthSizable];
        [_titleField setStringValue:@""];

        [_titleField setFrame:CGRectMake(20.0, 3.0, CGRectGetWidth([self bounds]) - 40.0, CGRectGetHeight([_titleField frame]))];

        [self addSubview:_titleField];

        if (_styleMask & CPClosableWindowMask)
        {
            var closeSize = [_CPHUDWindowViewCloseImage size];

            _closeButton = [[CPButton alloc] initWithFrame:CGRectMake(8.0, 5.0, closeSize.width, closeSize.height)];

            [_closeButton setBordered:NO];

            [_closeButton setImage:_CPHUDWindowViewCloseImage];
            [_closeButton setAlternateImage:_CPHUDWindowViewCloseActiveImage];

            [self addSubview:_closeButton];
        }

        [self setResizeIndicatorOffset:CGSizeMake(5.0, 5.0)];
    }

    return self;
}

- (void)viewDidMoveToWindow
{
    [_closeButton setTarget:[self window]];
    [_closeButton setAction:@selector(performClose:)];
}

- (void)setTitle:(CPString)aTitle
{
    [_titleField setStringValue:aTitle];
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
    return CGSizeMake(0.0, HUD_TITLEBAR_HEIGHT);
}

- (void)tile
{
    [super tile];

    var theWindow = [self window],
        bounds = [self bounds],
        width = CGRectGetWidth(bounds);

    [_titleField setFrame:CGRectMake(20.0, 3.0, width - 40.0, CGRectGetHeight([_titleField frame]))];

    var maxY = [self toolbarMaxY];

    [[theWindow contentView] setFrameOrigin:CGPointMake(0.0, maxY, width, CGRectGetHeight(bounds) - maxY)];
}

@end

