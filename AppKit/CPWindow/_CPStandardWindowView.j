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
@import "CPApplication_Constants.j"

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

+ (CPDictionary)themeAttributes
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

    CPButton                    _closeButton;
    CPButton                    _minimizeButton;
    CPButton                    _zoomButton;

    BOOL                        _isDocumentEdited;
    BOOL                        _isSheet;
    
    CPTrackingArea              _closeButtonTrackingArea;
    CPTrackingArea              _minimizeButtonTrackingArea;
    CPTrackingArea              _zoomButtonTrackingArea;

    int                         _buttonsWidth;
}

+ (CPString)defaultThemeClass
{
    return @"standard-window-view";
}

+ (CPDictionary)themeAttributes
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
            @"zoom-image-button": [CPNull null],
            @"zoom-image-highlighted-button": [CPNull null]
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

        _headView = [[_CPTexturedWindowHeadView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), _titleBarHeight) windowView:self];

        [_headView setAutoresizingMask:CPViewWidthSizable];
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
            _closeButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];

            [_closeButton setButtonType:CPMomentaryChangeButton];
            [_closeButton setBordered:NO];

            [self addSubview:_closeButton];
        }

        if (_styleMask & CPMiniaturizableWindowMask)
        {
            _minimizeButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];

            [_minimizeButton setButtonType:CPMomentaryChangeButton];
            [_minimizeButton setBordered:NO];

            [self addSubview:_minimizeButton];
        }

        if (_styleMask & CPResizableWindowMask)
        {
            _zoomButton = [[CPButton alloc] initWithFrame:CGRectMakeZero()];

            [_zoomButton setButtonType:CPMomentaryChangeButton];
            [_zoomButton setBordered:NO];

            [self addSubview:_zoomButton];
        }

        [self _updateWindowButtons:YES];
        [self tile];

        // Observe CPApplicationOSBehaviorDidChangeNotification
        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_osBehaviorDidChange:) name:CPApplicationOSBehaviorDidChangeNotification object:CPApp];
    }

    return self;
}

// This will be called by CPWindow -close so the observer can be removed
- (void)_close
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:CPApplicationOSBehaviorDidChangeNotification object:CPApp];
}

- (void)viewDidMoveToWindow
{
    [_closeButton setTarget:[self window]];
    [_closeButton setAction:@selector(performClose:)];

    [_minimizeButton setTarget:[self window]];
    [_minimizeButton setAction:@selector(performMiniaturize:)];

    [_zoomButton setTarget:[self window]];
    [_zoomButton setAction:@selector(performZoom:)];
}

- (CGSize)toolbarOffset
{
    return CGSizeMake(0.0, _titleBarHeight);
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

    [_titleField setFrame:CGRectMake(_buttonsWidth, 0, width - _buttonsWidth * 2.0, _titleBarHeight)];

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

- (void)_updateWindowButtons:(BOOL)shouldRefreshLayout
{
    if (shouldRefreshLayout)
    {
        if (CPApplicationShouldMimicWindows)
            [self setThemeState:CPThemeStateWindowsPlatform];
        else
            [self unsetThemeState:CPThemeStateWindowsPlatform];

        // Remember that on Cappuccino, buttons are (left to right) : close - minimize - zoom
        // and that on Windows, (also left to right) : minimize - zoom - close

        var offset,
            mask,
            closeThemeOrigin    = CGPointMakeCopy([self currentValueForThemeAttribute:@"close-image-origin"]    || CGPointMakeZero()),
            minimizeThemeOrigin = CGPointMakeCopy([self currentValueForThemeAttribute:@"minimize-image-origin"] || CGPointMakeZero()),
            zoomThemeOrigin     = CGPointMakeCopy([self currentValueForThemeAttribute:@"zoom-image-origin"]     || CGPointMakeZero()),
            closeThemeSize      = CGSizeMakeZero(),
            minimizeThemeSize   = CGSizeMakeZero(),
            zoomThemeSize       = CGSizeMakeZero(),
            delta1,
            delta2;

        if (CPApplicationShouldMimicWindows)
        {
            offset = [self bounds].size.width;
            mask   = CPViewMinXMargin;
            delta1 = zoomThemeOrigin.x - closeThemeOrigin.x;
            delta2 = minimizeThemeOrigin.x - zoomThemeOrigin.x;
        }
        else
        {
            offset = 0;
            mask   = CPViewMaxXMargin;
            delta1 = minimizeThemeOrigin.x - closeThemeOrigin.x;
            delta2 = zoomThemeOrigin.x - minimizeThemeOrigin.x;
        }

        _buttonsWidth = 0;

        if (_styleMask & CPClosableWindowMask)
        {
            closeThemeSize = [self currentValueForThemeAttribute:@"close-image-size"];

            // For retro-compatibility:
            if (!closeThemeSize)
            {
                closeThemeSize   = CGSizeMake(16.0, 16.0);
                closeThemeOrigin = CGPointMake(8.0, 8.0);
            }

            [_closeButton setFrame:CGRectMake(closeThemeOrigin.x + offset, closeThemeOrigin.y, closeThemeSize.width, closeThemeSize.height)];
            [_closeButton setAutoresizingMask:mask];

            _buttonsWidth = ABS(closeThemeOrigin.x) + (CPApplicationShouldMimicWindows ? 0 : closeThemeSize.width);
        }
        else
        {
            minimizeThemeOrigin.x -= delta1;
            zoomThemeOrigin.x     -= delta1;
        }

        if (CPApplicationShouldMimicWindows)
        {
            if (_styleMask & CPResizableWindowMask)
            {
                zoomThemeSize = [self currentValueForThemeAttribute:@"zoom-image-size"];

                // For retro-compatibility:
                if (!zoomThemeSize)
                {
                    zoomThemeSize   = CGSizeMake(16.0, 16.0);
                    zoomThemeOrigin = CGPointMake(46.0, 8.0);
                }

                [_zoomButton setFrame:CGRectMake(zoomThemeOrigin.x + offset, zoomThemeOrigin.y, zoomThemeSize.width, zoomThemeSize.height)];
                [_zoomButton setAutoresizingMask:mask];

                _buttonsWidth = ABS(zoomThemeOrigin.x);
            }
            else
                minimizeThemeOrigin.x -= delta2;

            if (_styleMask & CPMiniaturizableWindowMask)
            {
                minimizeThemeSize = [self currentValueForThemeAttribute:@"minimize-image-size"];

                // For retro-compatibility:
                if (!minimizeThemeSize)
                {
                    minimizeThemeSize   = CGSizeMake(16.0, 16.0);
                    minimizeThemeOrigin = CGPointMake(27.0, 8.0);
                }

                [_minimizeButton setFrame:CGRectMake(minimizeThemeOrigin.x + offset, minimizeThemeOrigin.y, minimizeThemeSize.width, minimizeThemeSize.height)];
                [_minimizeButton setAutoresizingMask:mask];

                _buttonsWidth = ABS(minimizeThemeOrigin.x);
            }

            if (_buttonsWidth > 0)
                _buttonsWidth += ABS(closeThemeOrigin.x) - closeThemeSize.width;
        }
        else // not win
        {
            if (_styleMask & CPMiniaturizableWindowMask)
            {
                minimizeThemeSize = [self currentValueForThemeAttribute:@"minimize-image-size"];

                // For retro-compatibility:
                if (!minimizeThemeSize)
                {
                    minimizeThemeSize   = CGSizeMake(16.0, 16.0);
                    minimizeThemeOrigin = CGPointMake(27.0, 8.0);
                }

                [_minimizeButton setFrame:CGRectMake(minimizeThemeOrigin.x + offset, minimizeThemeOrigin.y, minimizeThemeSize.width, minimizeThemeSize.height)];
                [_minimizeButton setAutoresizingMask:mask];

                _buttonsWidth = minimizeThemeOrigin.x + minimizeThemeSize.width;
            }
            else
                zoomThemeOrigin.x -= delta2;

            if (_styleMask & CPResizableWindowMask)
            {
                zoomThemeSize = [self currentValueForThemeAttribute:@"zoom-image-size"];

                // For retro-compatibility:
                if (!zoomThemeSize)
                {
                    zoomThemeSize   = CGSizeMake(16.0, 16.0);
                    zoomThemeOrigin = CGPointMake(46.0, 8.0);
                }

                [_zoomButton setFrame:CGRectMake(zoomThemeOrigin.x + offset, zoomThemeOrigin.y, zoomThemeSize.width, zoomThemeSize.height)];
                [_zoomButton setAutoresizingMask:mask];

                _buttonsWidth = zoomThemeOrigin.x + zoomThemeSize.width;
            }

            if (_buttonsWidth > 0)
                _buttonsWidth += closeThemeOrigin.x;
        }

        [self updateTrackingAreas];
    }

    [self _updateCloseButton];

    [_minimizeButton setImage:[self currentValueForThemeAttribute:@"minimize-image-button"]];
    [_minimizeButton setAlternateImage:[self currentValueForThemeAttribute:@"minimize-image-highlighted-button"]];
    [_zoomButton setImage:[self currentValueForThemeAttribute:@"zoom-image-button"]];
    [_zoomButton setAlternateImage:[self currentValueForThemeAttribute:@"zoom-image-highlighted-button"]];
}

- (void)_updateCloseButton
{
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

- (void)_osBehaviorDidChange:(id)application
{
    [self _updateWindowButtons:YES];
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

    [_closeButton    setHidden:enable];
    [_minimizeButton setHidden:enable];
    [_zoomButton     setHidden:enable];
    [_titleField     setHidden:enable];

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
    var width = [self bounds].size.width;

    [super layoutSubviews];

    if (_closeButton || _minimizeButton || _zoomButton)
        [self _updateWindowButtons:NO];

    [_dividerView setBackgroundColor:[self valueForThemeAttribute:@"divider-color"]];
    [_bodyView setBackgroundColor:[self valueForThemeAttribute:@"body-color"]];

    [_headView setNeedsLayout];

    if (width - 2 * _buttonsWidth < _minimumTitleFieldSize)
    {
        if (width - _buttonsWidth - _titleMargin < _minimumTitleFieldSize)
            [_titleField setFrame:CGRectMake((CPApplicationShouldMimicWindows ? _titleMargin : _buttonsWidth), 0, width - _buttonsWidth - _titleMargin, _titleBarHeight)];
        else
            [_titleField setFrame:CGRectMake((CPApplicationShouldMimicWindows ? width - _buttonsWidth - _minimumTitleFieldSize : _buttonsWidth), 0, _minimumTitleFieldSize, _titleBarHeight)];
    }
}

- (CGSize)_minimumResizeSize
{
    // The minimum width is such that the close/minimize/zoom button(s) would always be visible.
    // We give the same margin to the right of the button(s) as there is to the left.
    var size = CGSizeMakeCopy([super _minimumResizeSize]);

    size.width = _buttonsWidth;
    size.height += _CPStandardWindowViewDividerViewHeight;

    return size;
}

- (int)bodyOffset
{
    return [_bodyView frame].origin.y;
}

#pragma mark -
#pragma mark Hover management for buttons

- (void)updateTrackingAreas
{
    if (_closeButtonTrackingArea)
        [_closeButton removeTrackingArea:_closeButtonTrackingArea];

    if (_minimizeButtonTrackingArea)
        [_minimizeButton removeTrackingArea:_minimizeButtonTrackingArea];

    if (_zoomButtonTrackingArea)
        [_zoomButton removeTrackingArea:_zoomButtonTrackingArea];

    if (_closeButton)
    {
        _closeButtonTrackingArea = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                                                options:CPTrackingMouseEnteredAndExited | CPTrackingActiveAlways | CPTrackingInVisibleRect
                                                                  owner:self
                                                               userInfo:_closeButton];
        [_closeButton addTrackingArea:_closeButtonTrackingArea];
    }

    if (_minimizeButton)
    {
        _minimizeButtonTrackingArea = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                                                   options:CPTrackingMouseEnteredAndExited | CPTrackingActiveAlways | CPTrackingInVisibleRect
                                                                     owner:self
                                                                  userInfo:_minimizeButton];
        [_minimizeButton addTrackingArea:_minimizeButtonTrackingArea];
    }

    if (_zoomButton)
    {
        _zoomButtonTrackingArea = [[CPTrackingArea alloc] initWithRect:CGRectMakeZero()
                                                               options:CPTrackingMouseEnteredAndExited | CPTrackingActiveAlways | CPTrackingInVisibleRect
                                                                 owner:self
                                                              userInfo:_zoomButton];
        [_zoomButton addTrackingArea:_zoomButtonTrackingArea];
    }
    
    [super updateTrackingAreas];
}

- (void)mouseEntered:(CPEvent)anEvent
{
    var triggeredButton = [[anEvent trackingArea] userInfo],
        state           = CPThemeStateHovered;

    if (CPApplicationShouldMimicWindows)
        state = state.and(CPThemeStateWindowsPlatform);

    if (triggeredButton === _closeButton)
    {
        if (_isDocumentEdited)
            [_closeButton setImage:[self valueForThemeAttribute:@"unsaved-image-button" inState:state]];
        else
            [_closeButton setImage:[self valueForThemeAttribute:@"close-image-button" inState:state]];
    }
    else if (triggeredButton === _minimizeButton)
    {
        [_minimizeButton setImage:[self valueForThemeAttribute:@"minimize-image-button" inState:state]];
    }
    else if (triggeredButton === _zoomButton)
    {
        [_zoomButton setImage:[self valueForThemeAttribute:@"zoom-image-button" inState:state]];
    }
}

- (void)mouseExited:(CPEvent)anEvent
{
    var triggeredButton = [[anEvent trackingArea] userInfo];

    if (triggeredButton === _closeButton)
    {
        if (_isDocumentEdited)
            [_closeButton setImage:[self currentValueForThemeAttribute:@"unsaved-image-button"]];
        else
            [_closeButton setImage:[self currentValueForThemeAttribute:@"close-image-button"]];
    }
    else if (triggeredButton === _minimizeButton)
    {
        [_minimizeButton setImage:[self currentValueForThemeAttribute:@"minimize-image-button"]];
    }
    else if (triggeredButton === _zoomButton)
    {
        [_zoomButton setImage:[self currentValueForThemeAttribute:@"zoom-image-button"]];
    }
}

@end
