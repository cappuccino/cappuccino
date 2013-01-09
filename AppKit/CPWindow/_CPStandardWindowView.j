/*
 * _CPStandardWindowView.j
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


// var GRADIENT_HEIGHT = 41.0;

// var _CPTexturedWindowHeadGradientColor  = nil,
//     _CPTexturedWindowHeadSolidColor     = nil;

@implementation _CPTexturedWindowHeadView : CPView
{
    CPView  _gradientView;
    CPView  _solidView;
    CPView  _dividerView;
}

+ (CPString)defaultThemeClass
{
    return @"textured-window-head-view";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[31, [CPNull null], [CPColor blackColor]]
                                       forKeys:[@"gradient-height" ,@"bezel-color", @"solid-color"]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _gradientView = [[CPView alloc] initWithFrame:CGRectMakeZero()];

        [self addSubview:_gradientView];

        _solidView = [[CPView alloc] initWithFrame:CGRectMakeZero()];

        [self addSubview:_solidView];
    }

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    var gradientHeight = [self valueForThemeAttribute:@"gradient-height"],
        bounds = [self bounds];

    [_gradientView setFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), gradientHeight)];
    [_gradientView setBackgroundColor:[self valueForThemeAttribute:@"bezel-color"]];

    [_solidView setFrame:CGRectMake(0.0,gradientHeight ,CGRectGetWidth(bounds),  CGRectGetHeight(bounds) - gradientHeight)];
    [_solidView setBackgroundColor:[self valueForThemeAttribute:@"solid-color"]];
}

- (void)resizeSubviewsWithOldSize:(CGSize)aSize
{
    var bounds = [self bounds];

    [_gradientView setFrameSize:CGSizeMake(CGRectGetWidth(bounds), [self valueForThemeAttribute:@"gradient-height"])];
    [_solidView setFrameSize:CGSizeMake(CGRectGetWidth(bounds), CGRectGetHeight(bounds) - [self valueForThemeAttribute:@"gradient-height"])];
}

@end

var _CPStandardWindowViewBodyBackgroundColor                = nil,
    _CPStandardWindowViewDividerBackgroundColor             = nil,
    _CPStandardWindowViewCloseButtonImage                   = nil,
    _CPStandardWindowViewCloseButtonHighlightedImage        = nil,
    _CPStandardWindowViewCloseButtonUnsavedImage            = nil,
    _CPStandardWindowViewCloseButtonUnsavedHighlightedImage = nil,
    _CPStandardWindowViewMinimizeButtonImage                = nil,
    _CPStandardWindowViewMinimizeButtonHighlightedImage     = nil,
    _CPStandardWindowViewThemeValues                        = nil;

// var STANDARD_GRADIENT_HEIGHT                    = 41.0;

@implementation _CPStandardWindowView : _CPTitleableWindowView
{
    _CPTexturedWindowHeadView   _headView;
    CPView                      _dividerView;
    CPView                      _bodyView;
    CPView                      _toolbarView;

    CPButton                    _closeButton;
    CPButton                    _minimizeButton;

    BOOL                        _isDocumentEdited;
}

+ (CPString)defaultThemeClass
{
    return @"standard-window-view";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[[CPColor blackColor], [CPColor whiteColor], 32, [CPNull null], [CPNull null],[CPNull null], [CPNull null], [CPNull null], [CPNull null]]
                                       forKeys:[   @"divider-color", @"body-color", @"title-bar-height",@"minimize-image-highlighted-button",@"minimize-image-button",
                                                   @"close-image-button", @"close-image-highlighted-button", @"unsaved-image-button", @"unsaved-image-highlighted-button"]];
}

+ (CPColor)bodyBackgroundColor
{
    if (!_CPStandardWindowViewBodyBackgroundColor)
        _CPStandardWindowViewBodyBackgroundColor = [CPColor colorWithWhite:0.96 alpha:1.0];

    return _CPStandardWindowViewBodyBackgroundColor;
}

+ (CPColor)dividerBackgroundColor
{
    if (!_CPStandardWindowViewDividerBackgroundColor)
        _CPStandardWindowViewDividerBackgroundColor = [CPColor colorWithCalibratedRed:125.0 / 255.0 green:125.0 / 255.0 blue:125.0 / 255.0 alpha:1.0];

    return _CPStandardWindowViewDividerBackgroundColor;
}

- (id)initWithFrame:(CPRect)aFrame styleMask:(unsigned)aStyleMask
{
    self = [super initWithFrame:aFrame styleMask:aStyleMask];

    if (self)
    {
        var theClass = [self class],
            bounds = [self bounds];

        _headView = [[_CPTexturedWindowHeadView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), [self valueForThemeAttribute:@"title-bar-height"])];

        [_headView setAutoresizingMask:CPViewWidthSizable];;
        [_headView setHitTests:NO];

        [self addSubview:_headView positioned:CPWindowBelow relativeTo:_titleField];

        _dividerView = [[CPView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY([_headView frame]), CGRectGetWidth(bounds), 1.0)];

        [_dividerView setAutoresizingMask:CPViewWidthSizable];
        [_dividerView setHitTests:NO];

        [self addSubview:_dividerView];

        var y = CGRectGetMaxY([_dividerView frame]);

        _bodyView = [[CPView alloc] initWithFrame:CGRectMake(0.0, y, CGRectGetWidth(bounds), CGRectGetHeight(bounds) - y)];

        [_bodyView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [_bodyView setHitTests:NO];

        [self addSubview:_bodyView];

        [self setResizeIndicatorOffset:CGSizeMake(2.0, 2.0)];

        if (_styleMask & CPClosableWindowMask)
        {
            _closeButton = [[CPButton alloc] initWithFrame:CGRectMake(8.0, 8.0, 16.0, 16.0)];

            [_closeButton setButtonType:CPMomentaryChangeButton];
            [_closeButton setBordered:NO];
            [self _updateCloseButton];

            [self addSubview:_closeButton];
        }

        if (_styleMask & CPMiniaturizableWindowMask && ![CPPlatform isBrowser])
        {
            _minimizeButton = [[CPButton alloc] initWithFrame:CGRectMake(27.0, 7.0, 16.0, 16.0)];
            [_minimizeButton setBordered:NO];

            [self addSubview:_minimizeButton];
        }

        [self tile];
    }

    return self;
}

- (void)viewDidMoveToWindow
{
    [_closeButton setTarget:[self window]];
    [_closeButton setAction:@selector(performClose:)];

    [_minimizeButton setTarget:[self window]];
    [_minimizeButton setAction:@selector(performMiniaturize:)];
}

- (CGSize)toolbarOffset
{
    return CGSizeMake(0.0, [self valueForThemeAttribute:@"title-bar-height"]);
}

- (void)tile
{
    [super tile];

    var theWindow = [self window],
        bounds = [self bounds],
        width = _CGRectGetWidth(bounds);

    [_headView setFrameSize:_CGSizeMake(width, [self toolbarMaxY])];
    [_dividerView setFrame:_CGRectMake(0.0, _CGRectGetMaxY([_headView frame]), width, 1.0)];

    var dividerMaxY = 0,
        dividerMinY = 0;
    if (![_dividerView isHidden])
    {
        dividerMinY = _CGRectGetMinY([_dividerView frame]);
        dividerMaxY = _CGRectGetMaxY([_dividerView frame]);
    }

    [_bodyView setFrame:_CGRectMake(0.0, dividerMaxY, width, _CGRectGetHeight(bounds) - dividerMaxY)];

    var leftOffset = 8;

    if (_closeButton)
        leftOffset += 19.0;
    if (_minimizeButton)
        leftOffset += 19.0;

    [_titleField setFrame:_CGRectMake(leftOffset, 0, width - leftOffset * 2.0, [self valueForThemeAttribute:@"title-bar-height"])];

    var contentRect = _CGRectMake(0.0, dividerMaxY, width, _CGRectGetHeight([_bodyView frame]));

    [[theWindow contentView] setFrame:contentRect];
}

/*
- (void)setAnimatingToolbar:(BOOL)isAnimatingToolbar
{
    [super setAnimatingToolbar:isAnimatingToolbar];

    if ([self isAnimatingToolbar])
    {
        [[self toolbarView] setAutoresizingMask:CPViewHeightSizable];

        [_headView setAutoresizingMask:CPViewHeightSizable];
        [_dividerView setAutoresizingMask:CPViewMinYMargin];
        [_bodyView setAutoresizingMask:CPViewMinYMargin];

        [[[self window] contentView] setAutoresizingMask:CPViewNotSizable];
    }
    else
    {
        [[self toolbarView] setAutoresizingMask:CPViewWidthSizable];

        [_headView setAutoresizingMask:CPViewWidthSizable];
        [_dividerView setAutoresizingMask:CPViewWidthSizable];
        [_bodyView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

        [[[self window] contentView] setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    }
}
*/

- (void)_updateCloseButton
{
    if (_isDocumentEdited)
    {
        [_closeButton setImage:[self valueForThemeAttribute:@"unsaved-image-button"]];
        [_closeButton setAlternateImage:[self valueForThemeAttribute:@"unsaved-image-highlighted-button"]];
    }
    else
    {
        [_closeButton setImage:[self valueForThemeAttribute:@"close-image-button"]];
        [_closeButton setAlternateImage:[self valueForThemeAttribute:@"close-image-highlighted-button"]];
    }
}

- (void)setDocumentEdited:(BOOL)isEdited
{
    _isDocumentEdited = isEdited;
    [self _updateCloseButton];
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (![_headView isHidden])
        if (CGRectContainsPoint([_headView frame], [self convertPoint:[anEvent locationInWindow] fromView:nil]))
            return [self trackMoveWithEvent:anEvent];

    [super mouseDown:anEvent];
}

- (void)_enableSheet:(BOOL)enable
{
    [super _enableSheet:enable];

    [_headView setHidden:enable];
    [_dividerView setHidden:enable];
    [_closeButton setHidden:enable];
    [_minimizeButton setHidden:enable];
    [_titleField setHidden:enable];

    if (enable)
        [_bodyView setBackgroundColor:[_CPDocModalWindowView bodyBackgroundColor]];
    else
        [_bodyView setBackgroundColor:[self valueForThemeAttribute:@"body-color"]];

    // resize the window
    var theWindow = [self window],
        frame = [theWindow frame];

    var dy = _CGRectGetHeight([_headView frame]) + _CGRectGetHeight([_dividerView frame]);
    if (enable)
        dy = -dy;

    var newHeight = _CGRectGetMaxY(frame) + dy,
        newWidth = _CGRectGetMaxX(frame);

    frame.size.height += dy;

    [self setFrameSize:_CGSizeMake(newWidth, newHeight)];
    [self tile];
    [theWindow setFrame:frame display:NO animate:NO];
}

- (void)layoutSubviews
{
    var bounds = [self bounds];

    [super layoutSubviews];
    [self _updateCloseButton];

    [_minimizeButton setImage:[self valueForThemeAttribute:@"minimize-image-button"]];
    [_minimizeButton setAlternateImage:[self valueForThemeAttribute:@"minimize-image-highlighted-button"]];

    [_headView setFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), [self valueForThemeAttribute:@"title-bar-height"])];

    [_dividerView setFrame:CGRectMake(0.0, CGRectGetMaxY([_headView frame]), CGRectGetWidth(bounds), 1.0)];
    [_dividerView setBackgroundColor:[self valueForThemeAttribute:@"divider-color"]];

    var y = CGRectGetMaxY([_dividerView frame]);

    [_bodyView setFrame:CGRectMake(0.0, y, CGRectGetWidth(bounds), CGRectGetHeight(bounds) - y)];
    [_bodyView setBackgroundColor:[self valueForThemeAttribute:@"body-color"]];

    [_headView setNeedsLayout];
}

@end
