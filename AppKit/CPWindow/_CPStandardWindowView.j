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


var GRADIENT_HEIGHT = 41.0;

var _CPTexturedWindowHeadGradientColor  = nil,
    _CPTexturedWindowHeadSolidColor     = nil;

@implementation _CPTexturedWindowHeadView : CPView
{
    CPView  _gradientView;
    CPView  _solidView;
    CPView  _dividerView;
}

+ (CPColor)gradientColor
{
    if (!_CPTexturedWindowHeadGradientColor)
    {
        var bundle = [CPBundle bundleForClass:[_CPWindowView class]];

        _CPTexturedWindowHeadGradientColor = [CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
            [
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/Standard/CPWindowStandardTop0.png"] size:CGSizeMake(6.0, 41.0)],
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/Standard/CPWindowStandardTop1.png"] size:CGSizeMake(1.0, 41.0)],
                [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/Standard/CPWindowStandardTop2.png"] size:CGSizeMake(6.0, 41.0)]
            ]
            isVertical:NO
        ]];
    }

    return _CPTexturedWindowHeadGradientColor;
}

+ (CPColor)solidColor
{
    if (!_CPTexturedWindowHeadSolidColor)
        _CPTexturedWindowHeadSolidColor = [CPColor colorWithCalibratedRed:195.0 / 255.0 green:195.0 / 255.0 blue:195.0 / 255.0 alpha:1.0];

    return _CPTexturedWindowHeadSolidColor;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        var theClass = [self class],
            bounds = [self bounds];

        _gradientView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), GRADIENT_HEIGHT)];
        [_gradientView setBackgroundColor:[theClass gradientColor]];

        [self addSubview:_gradientView];

        _solidView = [[CPView alloc] initWithFrame:CGRectMake(0.0, GRADIENT_HEIGHT, CGRectGetWidth(bounds), CGRectGetHeight(bounds) - GRADIENT_HEIGHT)];
        [_solidView setBackgroundColor:[theClass solidColor]];

        [self addSubview:_solidView];
    }

    return self;
}

- (void)resizeSubviewsWithOldSize:(CGSize)aSize
{
    var bounds = [self bounds];

    [_gradientView setFrameSize:CGSizeMake(CGRectGetWidth(bounds), GRADIENT_HEIGHT)];
    [_solidView setFrameSize:CGSizeMake(CGRectGetWidth(bounds), CGRectGetHeight(bounds) - GRADIENT_HEIGHT)];
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

var STANDARD_GRADIENT_HEIGHT                    = 41.0;

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

+ (void)initialize
{
    _CPStandardWindowViewThemeValues = [
        [@"title-font",                 [CPFont boldSystemFontOfSize:CPFontCurrentSystemSize]],
        [@"title-text-color",           [CPColor colorWithWhite:22.0 / 255.0 alpha:0.75]],
        [@"title-text-color",           [CPColor colorWithWhite:22.0 / 255.0 alpha:1], CPThemeStateKeyWindow],
        [@"title-text-shadow-color",    [CPColor whiteColor]],
        [@"title-text-shadow-offset",   CGSizeMake(0.0, 1.0)],
        [@"title-alignment",            CPCenterTextAlignment],
        // FIXME: Make this to CPLineBreakByTruncatingMiddle once it's implemented.
        [@"title-line-break-mode",      CPLineBreakByTruncatingTail],
        [@"title-vertical-alignment",   CPCenterVerticalTextAlignment]
    ];
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
        // Until windows become properly themable, just set these values here in the subclass.
        [self registerThemeValues:_CPStandardWindowViewThemeValues];

        var theClass = [self class],
            bounds = [self bounds];

        _headView = [[_CPTexturedWindowHeadView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), [[self class] titleBarHeight])];

        [_headView setAutoresizingMask:CPViewWidthSizable];;
        [_headView setHitTests:NO];

        [self addSubview:_headView positioned:CPWindowBelow relativeTo:_titleField];

        _dividerView = [[CPView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY([_headView frame]), CGRectGetWidth(bounds), 1.0)];

        [_dividerView setAutoresizingMask:CPViewWidthSizable];
        [_dividerView setBackgroundColor:[theClass dividerBackgroundColor]];
        [_dividerView setHitTests:NO];

        [self addSubview:_dividerView];

        var y = CGRectGetMaxY([_dividerView frame]);

        _bodyView = [[CPView alloc] initWithFrame:CGRectMake(0.0, y, CGRectGetWidth(bounds), CGRectGetHeight(bounds) - y)];

        [_bodyView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [_bodyView setBackgroundColor:[theClass bodyBackgroundColor]];
        [_bodyView setHitTests:NO];

        [self addSubview:_bodyView];

        [self setResizeIndicatorOffset:CGSizeMake(2.0, 2.0)];

        if (_styleMask & CPClosableWindowMask)
        {
            if (!_CPStandardWindowViewCloseButtonImage)
            {
                var bundle = [CPBundle bundleForClass:[CPWindow class]];

                _CPStandardWindowViewCloseButtonImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/Standard/CPWindowStandardCloseButton.png"] size:CGSizeMake(16.0, 16.0)];
                _CPStandardWindowViewCloseButtonHighlightedImage  = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/Standard/CPWindowStandardCloseButtonHighlighted.png"] size:CGSizeMake(16.0, 16.0)];
                _CPStandardWindowViewCloseButtonUnsavedImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/Standard/CPWindowStandardCloseButtonUnsaved.png"] size:CGSizeMake(16.0, 16.0)];
                _CPStandardWindowViewCloseButtonUnsavedHighlightedImage  = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/Standard/CPWindowStandardCloseButtonUnsavedHighlighted.png"] size:CGSizeMake(16.0, 16.0)];
            }

            _closeButton = [[CPButton alloc] initWithFrame:CGRectMake(8.0, 6.0, 16.0, 16.0)];

            [_closeButton setBordered:NO];
            [self _updateCloseButton];

            [self addSubview:_closeButton];
        }

        if (_styleMask & CPMiniaturizableWindowMask && ![CPPlatform isBrowser])
        {
            if (!_CPStandardWindowViewMinimizeButtonImage)
            {
                var bundle = [CPBundle bundleForClass:[CPWindow class]];

                _CPStandardWindowViewMinimizeButtonImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/Standard/CPWindowStandardMinimizeButton.png"] size:CGSizeMake(16.0, 16.0)];
                _CPStandardWindowViewMinimizeButtonHighlightedImage  = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPWindow/Standard/CPWindowStandardMinimizeButtonHighlighted.png"] size:CGSizeMake(16.0, 16.0)];
            }

            _minimizeButton = [[CPButton alloc] initWithFrame:CGRectMake(27.0, 7.0, 16.0, 16.0)];

            [_minimizeButton setBordered:NO];

            [_minimizeButton setImage:_CPStandardWindowViewMinimizeButtonImage];
            [_minimizeButton setAlternateImage:_CPStandardWindowViewMinimizeButtonHighlightedImage];

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
    return CGSizeMake(0.0, [[self class] titleBarHeight]);
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

    [_titleField setFrame:_CGRectMake(leftOffset, 0, width - leftOffset * 2.0, [[self class] titleBarHeight])];

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
        [_closeButton setImage:_CPStandardWindowViewCloseButtonUnsavedImage];
        [_closeButton setAlternateImage:_CPStandardWindowViewCloseButtonUnsavedHighlightedImage];
    }
    else
    {
        [_closeButton setImage:_CPStandardWindowViewCloseButtonImage];
        [_closeButton setAlternateImage:_CPStandardWindowViewCloseButtonHighlightedImage];
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
        [_bodyView setBackgroundColor:[[self class] bodyBackgroundColor]];

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

@end
