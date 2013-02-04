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

@import "CPButton.j"
@import "_CPTitleableWindowView.j"

@class _CPDocModalWindowView

@implementation _CPTexturedWindowHeadView : CPView
{
    _CPWindowView   _parentView;
    CPView          _gradientView;
    CPView          _solidView;
    CPView          _dividerView;
}

+ (CPString)defaultThemeClass
{
    return @"textured-window-head-view";
}

+ (id)themeAttributes
{
    return [CPDictionary dictionaryWithObjects:[]
                                       forKeys:[]];
}

- (id)initWithFrame:(CGRect)aFrame windowView:(_CPWindowView)parentView
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _parentView = parentView;
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

    var gradientHeight = [[CPTheme defaultTheme] valueForAttributeWithName:@"gradient-height" forClass:_CPStandardWindowView],
        bounds = [self bounds];

    [_gradientView setFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), gradientHeight)];
    [_gradientView setBackgroundColor:[[CPTheme defaultTheme] valueForAttributeWithName:@"bezel-head-color" inState:[_parentView themeState] forClass:_CPStandardWindowView]];

    [_solidView setFrame:CGRectMake(0.0, gradientHeight, CGRectGetWidth(bounds), CGRectGetHeight(bounds) - gradientHeight)];
    [_solidView setBackgroundColor:[[CPTheme defaultTheme] valueForAttributeWithName:@"solid-color" forClass:_CPStandardWindowView]];
}

- (void)resizeSubviewsWithOldSize:(CGSize)aSize
{
    var bounds = [self bounds];

    [_gradientView setFrameSize:CGSizeMake(CGRectGetWidth(bounds), [[CPTheme defaultTheme] valueForAttributeWithName:@"gradient-height" forClass:_CPStandardWindowView])];
    [_solidView setFrameSize:CGSizeMake(CGRectGetWidth(bounds), CGRectGetHeight(bounds) - [[CPTheme defaultTheme] valueForAttributeWithName:@"gradient-height" forClass:_CPStandardWindowView])];
}

@end


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
    return [CPDictionary dictionaryWithObjects:[[CPNull null], [CPNull null], [CPNull null], [CPColor blackColor], [CPColor whiteColor], 32, [CPNull null], [CPNull null],[CPNull null], [CPNull null], [CPNull null], [CPNull null]]
                                       forKeys:[   @"gradient-height",
                                                   @"solid-color",
                                                   @"bezel-head-color",
                                                   @"divider-color",
                                                   @"body-color",
                                                   @"title-bar-height",
                                                   @"minimize-image-highlighted-button",
                                                   @"minimize-image-button",
                                                   @"close-image-button",
                                                   @"close-image-highlighted-button",
                                                   @"unsaved-image-button",
                                                   @"unsaved-image-highlighted-button"]];
}

- (id)initWithFrame:(CGRect)aFrame styleMask:(unsigned)aStyleMask
{
    self = [super initWithFrame:aFrame styleMask:aStyleMask];

    if (self)
    {
        var theClass = [self class],
            bounds = [self bounds];

        _headView = [[_CPTexturedWindowHeadView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), [self valueForThemeAttribute:@"title-bar-height"]) windowView:self];

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
            [_minimizeButton setButtonType:CPMomentaryChangeButton];
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
        width = _CGRectGetWidth(bounds),
        headHeight = [self toolbarMaxY];

    [_headView setFrameSize:_CGSizeMake(width, headHeight)];
    [_dividerView setFrame:_CGRectMake(0.0, headHeight, width, 1.0)];

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
    [_closeButton setFrameSize:[self valueForThemeAttribute:@"close-image-size"]];
    [_closeButton setFrameOrigin:[self valueForThemeAttribute:@"close-image-origin"]];

    if (_isDocumentEdited)
    {
        [_closeButton setImage:[self currentValueForThemeAttribute:@"unsaved-image-button"]];
        [_closeButton setAlternateImage:[self valueForThemeAttribute:@"unsaved-image-highlighted-button"]];
    }
    else
    {
        [_closeButton setImage:[self currentValueForThemeAttribute:@"close-image-button"]];
        [_closeButton setAlternateImage:[self currentValueForThemeAttribute:@"close-image-highlighted-button"]];
    }
}

- (void)setDocumentEdited:(BOOL)isEdited
{
    _isDocumentEdited = isEdited;
    [self _updateCloseButton];
}

- (BOOL)couldBeMoveEvent:(CPEvent)anEvent
{
    if (![_headView isHidden])
        if (CGRectContainsPoint([_headView frame], [self convertPoint:[anEvent locationInWindow] fromView:nil]))
            return YES;

    return [super couldBeMoveEvent:anEvent];
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
        [_bodyView setBackgroundColor:[[CPTheme defaultTheme] valueForAttributeWithName:@"body-color" forClass:_CPDocModalWindowView]];
    else
        [_bodyView setBackgroundColor:[self valueForThemeAttribute:@"body-color"]];

    // resize the window
    var theWindow = [self window],
        frame = [theWindow frame],
        dy;

    if (enable)
        dy = -(_CGRectGetHeight([_headView frame]) + _CGRectGetHeight([_dividerView frame]));
    else
        dy = [self toolbarMaxY] + 1.0;

    var newHeight = _CGRectGetMaxY(frame) + dy,
        newWidth = _CGRectGetMaxX(frame);

    frame.size.height += dy;

    [self setFrameSize:_CGSizeMake(newWidth, newHeight)];

    [self tile];
    [theWindow setFrame:frame display:NO animate:NO];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    var bounds = [self bounds];

    [super layoutSubviews];
    [self _updateCloseButton];

    [_minimizeButton setImage:[self valueForThemeAttribute:@"minimize-image-button"]];
    [_minimizeButton setAlternateImage:[self valueForThemeAttribute:@"minimize-image-highlighted-button"]];

    if (![_headView isHidden])
        [_headView setFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), [self toolbarMaxY])];
    else
        [_headView setFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), 0)];

    if (![_dividerView isHidden])
        [_dividerView setFrame:CGRectMake(0.0, CGRectGetMaxY([_headView frame]), CGRectGetWidth(bounds), 1.0)];
    else
        [_dividerView setFrame:CGRectMake(0.0, CGRectGetMaxY([_headView frame]), CGRectGetWidth(bounds), 0.0)];

    [_dividerView setBackgroundColor:[self valueForThemeAttribute:@"divider-color"]];

    var y = CGRectGetMaxY([_dividerView frame]);

    [_bodyView setFrame:CGRectMake(0.0, y, CGRectGetWidth(bounds), CGRectGetHeight(bounds) - y)];
    [_bodyView setBackgroundColor:[self valueForThemeAttribute:@"body-color"]];

    [_headView setNeedsLayout];
}

@end
