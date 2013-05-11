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

var _CPStandardWindowViewDividerViewHeight = 1.0;

@implementation _CPTexturedWindowHeadView : CPView
{
    BOOL            _isSheet    @accessors(setter=setSheet:);

    _CPWindowView   _parentView;
    CPView          _gradientView;
    CPView          _solidView;
}

+ (CPString)defaultThemeClass
{
    return @"textured-window-head-view";
}

+ (id)themeAttributes
{
    return @{};
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
        bounds = [self bounds],
        bezelHeadColor = [[CPTheme defaultTheme] valueForAttributeWithName:_isSheet ? @"bezel-head-sheet-color" : @"bezel-head-color" inState:[_parentView themeState] forClass:_CPStandardWindowView];

    [_gradientView setFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), gradientHeight)];
    [_gradientView setBackgroundColor:bezelHeadColor];

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
    BOOL                        _isSheet;
}

+ (CPString)defaultThemeClass
{
    return @"standard-window-view";
}

+ (id)themeAttributes
{
    return @{
            @"gradient-height": [CPNull null],
            @"solid-color": [CPNull null],
            @"bezel-head-color": [CPNull null],
            @"bezel-head-sheet-color": [CPNull null],
            @"divider-color": [CPColor blackColor],
            @"body-color": [CPColor whiteColor],
            @"title-bar-height": 32,
            @"minimize-image-highlighted-button": [CPNull null],
            @"minimize-image-button": [CPNull null],
            @"close-image-button": [CPNull null],
            @"close-image-highlighted-button": [CPNull null],
            @"unsaved-image-button": [CPNull null],
            @"unsaved-image-highlighted-button": [CPNull null],
        };
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

    // Adjust for the divider
    contentRect.origin.y += _CPStandardWindowViewDividerViewHeight;
    contentRect.size.height -= _CPStandardWindowViewDividerViewHeight;

    return contentRect;
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

        _dividerView = [[CPView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY([_headView frame]), CGRectGetWidth(bounds), _CPStandardWindowViewDividerViewHeight)];

        [_dividerView setAutoresizingMask:CPViewWidthSizable];
        [_dividerView setHitTests:NO];

        [self addSubview:_dividerView];

        var y = CGRectGetMinY([_dividerView frame]);

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
        width = CGRectGetWidth(bounds),
        headHeight = [self toolbarMaxY];

    if (_isSheet && _toolbarView && [self showsToolbar])
    {
        headHeight = [_toolbarView frameSize].height;
        [_toolbarView setFrameOrigin:CGPointMake(0.0, 0.0)];
    }

    [_headView setFrameSize:CGSizeMake(width, headHeight)];

    [_dividerView setFrame:CGRectMake(0.0, headHeight, width, _CPStandardWindowViewDividerViewHeight)];

    var dividerMinY = 0,
        dividerFrame = [_dividerView frame];

    if (![_dividerView isHidden])
        dividerMinY = CGRectGetMinY(dividerFrame);

    [_bodyView setFrame:CGRectMake(0.0, dividerMinY, width, CGRectGetHeight(bounds) - dividerMinY)];

    var leftOffset = 8;

    if (_closeButton)
        leftOffset += 19.0;
    if (_minimizeButton)
        leftOffset += 19.0;

    [_titleField setFrame:CGRectMake(leftOffset, 0, width - leftOffset * 2.0, [self valueForThemeAttribute:@"title-bar-height"])];

    var contentFrame = [_bodyView frame];
    [[theWindow contentView] setFrame:CGRectInset(contentFrame, 1.0, 1.0)];
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

- (void)_enableSheet:(BOOL)enable inWindow:(CPWindow)parentWindow
{
    [super _enableSheet:enable inWindow:parentWindow];

    _isSheet = enable;
    [_headView setSheet:enable];

    if (_toolbarView && [self showsToolbar])
    {
        [_headView setHidden:NO];
        [_dividerView setHidden:NO];
    }
    else
    {
        [_headView setHidden:enable];
        [_dividerView setHidden:enable];
    }

    [_closeButton setHidden:enable];
    [_minimizeButton setHidden:enable];
    [_titleField setHidden:enable];

    [[self window] setMovable:!enable];

    if (enable)
    {
        [_bodyView setBackgroundColor:[[CPTheme defaultTheme] valueForAttributeWithName:@"body-color" forClass:_CPDocModalWindowView]];

        // Move the shadow view down so it is inside the content border
        var shadowFrame = [_sheetShadowView frame];
        [_sheetShadowView setFrameOrigin:CGPointMake(shadowFrame.origin.x, shadowFrame.origin.y + 1)];
    }
    else
        [_bodyView setBackgroundColor:[self valueForThemeAttribute:@"body-color"]];

    // resize the window
    var theWindow = [self window],
        frame = [theWindow frame],
        dividerHeight = [_dividerView frame].size.height,
        dy = [self toolbarMaxY] + dividerHeight;

    if (_toolbarView && [self showsToolbar])
        dy = [[CPTheme defaultTheme] valueForAttributeWithName:@"gradient-height" forClass:_CPStandardWindowView];

    if (enable)
        dy = -dy;

    var newHeight = CGRectGetHeight(frame) + dy,
        newWidth = CGRectGetWidth(frame);

    frame.size.height += dy;

    [self setFrameSize:CGSizeMake(newWidth, newHeight)];

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
    [_dividerView setBackgroundColor:[self valueForThemeAttribute:@"divider-color"]];
    [_bodyView setBackgroundColor:[self valueForThemeAttribute:@"body-color"]];

    [_headView setNeedsLayout];
}

- (CGSize)_minimumResizeSize
{
    // The minimum width is such that the close button would always be visible.
    // We give the same margin to the right of the button as there is to the left.
    var size = [super _minimumResizeSize],
        closeSize = [self valueForThemeAttribute:@"close-image-size"],
        closeOrigin = [self valueForThemeAttribute:@"close-image-origin"];

    size.width = closeSize.width + (closeOrigin.x * 2);
    size.height += _CPStandardWindowViewDividerViewHeight;

    return size;
}

- (int)bodyOffset
{
    return [_bodyView frame].origin.y;
}

@end
