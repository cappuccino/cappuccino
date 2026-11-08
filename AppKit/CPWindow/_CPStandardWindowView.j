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

+ (CPDictionary)themeAttributes
{
    return @{
                @"close-active-image-button": [CPNull null],
                @"minimize-active-image-button": [CPNull null],
                @"zoom-active-image-button": [CPNull null],
            };
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

/*
    The head view draws with the theme values of its window view, in the window view's
    current state, so it follows the window's theme. It read them from the default
    theme, so under any other theme it drew the default theme's height and colours.
*/
- (void)layoutSubviews
{
    [super layoutSubviews];

    var gradientHeight = [_parentView valueForThemeAttribute:@"gradient-height"],
        bounds = [self bounds],
        bezelHeadColor = [_parentView currentValueForThemeAttribute:_isSheet ? @"bezel-head-sheet-color" : @"bezel-head-color"];

    // Apply the border/background color to self (the container) so borders are drawn on the outside
    [self setBackgroundColor:bezelHeadColor];

    // Set x=0.0 to avoid 1px gap. Width is reduced by 2.0 to fit inside the 1px borders on each side.
    [_gradientView setFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds) - 2.0, gradientHeight)];
    
    // Set x=0.0 to avoid 1px gap. Width is reduced by 2.0.
    [_solidView setFrame:CGRectMake(0.0, gradientHeight, CGRectGetWidth(bounds) - 2.0, CGRectGetHeight(bounds) - gradientHeight)];
    [_solidView setBackgroundColor:[_parentView currentValueForThemeAttribute:@"solid-color"]];
}

- (void)resizeSubviewsWithOldSize:(CGSize)aSize
{
    var bounds = [self bounds],
        width = CGRectGetWidth(bounds) - 2.0, // Account for border inset
        gradientHeight = [_parentView valueForThemeAttribute:@"gradient-height"];

    if (width < 0) width = 0;

    [_gradientView setFrameSize:CGSizeMake(width, gradientHeight)];
    [_solidView setFrameSize:CGSizeMake(width, CGRectGetHeight(bounds) - gradientHeight)];
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
    BOOL                        _isPointerOverButtons;
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

        /*
            A standard titled window shows close, minimize and zoom, and enables each only
            when it is available, as Apple's guidelines ask. Only the available buttons
            were shown, so an unavailable control was hidden instead of disabled. As in
            macOS, minimize is available when the window is miniaturizable, and zoom when
            it is resizable.
        */
        _closeButton = [self _windowButton];
        _minimizeButton = [self _windowButton];
        _zoomButton = [self _windowButton];

        [_closeButton setEnabled:!!(_styleMask & CPClosableWindowMask)];
        [_minimizeButton setEnabled:!!(_styleMask & CPMiniaturizableWindowMask)];
        [_zoomButton setEnabled:!!(_styleMask & CPResizableWindowMask)];

        [self _updateWindowButtons];
        [self updateTrackingAreas];
        [self tile];
    }

    return self;
}

/*
    Makes one of the window buttons: an image without a bezel, which shows its alternate
    image while it is pressed.
*/
- (CPButton)_windowButton
{
    var button = [[CPButton alloc] initWithFrame:CGRectMakeZero()];

    [button setButtonType:CPMomentaryChangeButton];
    [button setBordered:NO];
    [self addSubview:button];

    return button;
}

- (void)viewDidMoveToWindow
{
    [_closeButton setTarget:[self window]];
    [_closeButton setAction:@selector(performClose:)];

    [_minimizeButton setTarget:[self window]];
    [_minimizeButton setAction:@selector(miniaturize:)];

    [_zoomButton setTarget:[self window]];
    [_zoomButton setAction:@selector(zoom:)];
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

    // Set divider to full width to prevent gaps/holes at the sides.
    [_dividerView setFrame:CGRectMake(0.0, headHeight, width, _CPStandardWindowViewDividerViewHeight)];

    var dividerMinY = 0,
        dividerFrame = [_dividerView frame];

    if (![_dividerView isHidden])
        dividerMinY = CGRectGetMinY(dividerFrame);

    [_bodyView setFrame:CGRectMake(0.0, dividerMinY, width, CGRectGetHeight(bounds) - dividerMinY)];

    [self _layoutTitleField];

    var contentFrame = [_bodyView frame];
    [[theWindow contentView] setFrame:CGRectInset(contentFrame, 1.0, 1.0)];
}

/*
    The buttons are placed from the theme values on every layout, so a change of theme
    moves them. They were placed only when the view was made, so the window kept the
    old theme's positions. The positions come from the theme alone, with no branch for
    the host platform. A theme without positions gets fixed defaults.
*/
- (void)_updateWindowButtons
{
    var closeOrigin    = [self currentValueForThemeAttribute:@"close-image-origin"]    || CGPointMake(8.0, 8.0),
        minimizeOrigin = [self currentValueForThemeAttribute:@"minimize-image-origin"] || CGPointMake(27.0, 8.0),
        zoomOrigin     = [self currentValueForThemeAttribute:@"zoom-image-origin"]     || CGPointMake(46.0, 8.0),
        closeSize      = [self currentValueForThemeAttribute:@"close-image-size"]      || CGSizeMake(16.0, 16.0),
        minimizeSize   = [self currentValueForThemeAttribute:@"minimize-image-size"]   || CGSizeMake(16.0, 16.0),
        zoomSize       = [self currentValueForThemeAttribute:@"zoom-image-size"]       || CGSizeMake(16.0, 16.0);

    [_closeButton setFrame:CGRectMake(closeOrigin.x, closeOrigin.y, closeSize.width, closeSize.height)];
    [_minimizeButton setFrame:CGRectMake(minimizeOrigin.x, minimizeOrigin.y, minimizeSize.width, minimizeSize.height)];
    [_zoomButton setFrame:CGRectMake(zoomOrigin.x, zoomOrigin.y, zoomSize.width, zoomSize.height)];

    _buttonsWidth = zoomOrigin.x + zoomSize.width + closeOrigin.x;

    [self _updateWindowButtonImages];
}

/*
    Sets each button's image for the window's state. A disabled button takes the theme's
    disabled value. While the pointer is over the buttons, the enabled ones take their
    hovered value, so that an inactive window shows their colours.
*/
- (void)_updateWindowButtonImages
{
    var closeName = _isDocumentEdited ? @"unsaved-image" : @"close-image";

    [_closeButton setImage:[self _imageForWindowButton:_closeButton attribute:closeName + @"-button"]];
    [_closeButton setAlternateImage:[self currentValueForThemeAttribute:closeName + @"-highlighted-button"]];
    [_minimizeButton setImage:[self _imageForWindowButton:_minimizeButton attribute:@"minimize-image-button"]];
    [_minimizeButton setAlternateImage:[self currentValueForThemeAttribute:@"minimize-image-highlighted-button"]];
    [_zoomButton setImage:[self _imageForWindowButton:_zoomButton attribute:@"zoom-image-button"]];
    [_zoomButton setAlternateImage:[self currentValueForThemeAttribute:@"zoom-image-highlighted-button"]];
}

- (CPImage)_imageForWindowButton:(CPButton)aButton attribute:(CPString)anAttributeName
{
    var state = [self themeState];

    if (![aButton isEnabled])
        state = state.and(CPThemeStateDisabled);
    else if (_isPointerOverButtons)
        state = state.and(CPThemeStateHovered);

    return [self valueForThemeAttribute:anAttributeName inState:state];
}

/*
    The title fills the space between the buttons and the same width on the other side.
    When that is too narrow for the title, the title gives up the space on the other
    side first. The title margin is read from the theme here, so a change of theme
    moves the title.
*/
- (void)_layoutTitleField
{
    var width       = CGRectGetWidth([self bounds]),
        titleMargin = [self currentValueForThemeAttribute:@"title-margin"],
        titleWidth  = width - 2.0 * _buttonsWidth;

    if (titleWidth < _minimumTitleFieldSize)
    {
        if (width - _buttonsWidth - titleMargin < _minimumTitleFieldSize)
            titleWidth = width - _buttonsWidth - titleMargin;
        else
            titleWidth = _minimumTitleFieldSize;
    }

    [_titleField setFrame:CGRectMake(_buttonsWidth, 0, titleWidth, _titleBarHeight)];
}

- (void)setDocumentEdited:(BOOL)isEdited
{
    _isDocumentEdited = isEdited;

    [self _updateWindowButtonImages];
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
        [_bodyView setBackgroundColor:[[self actualTheme] valueForAttributeWithName:@"body-color" forClass:_CPDocModalWindowView]];

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
        dy = [self valueForThemeAttribute:@"gradient-height"];

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
    [super layoutSubviews];

    [self _updateWindowButtons];
    [self _layoutTitleField];

    [_dividerView setBackgroundColor:[self valueForThemeAttribute:@"divider-color"]];
    [_bodyView setBackgroundColor:[self valueForThemeAttribute:@"body-color"]];

    [_headView setNeedsLayout];
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

// pragma mark -
// pragma mark Hover management for buttons

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

/*
    The pointer entering any of the buttons shows the hovered images of the whole group,
    and leaving it restores them. Each button showed only its own hovered image, without
    the window's state.
*/
- (void)mouseEntered:(CPEvent)anEvent
{
    if (![self _isWindowButton:[[anEvent trackingArea] userInfo]])
    {
        [super mouseEntered:anEvent];
        return;
    }

    _isPointerOverButtons = YES;
    [self _updateWindowButtonImages];
}

- (void)mouseExited:(CPEvent)anEvent
{
    if (![self _isWindowButton:[[anEvent trackingArea] userInfo]])
    {
        [super mouseExited:anEvent];
        return;
    }

    _isPointerOverButtons = NO;
    [self _updateWindowButtonImages];
}

- (BOOL)_isWindowButton:(id)anObject
{
    return anObject === _closeButton || anObject === _minimizeButton || anObject === _zoomButton;
}

@end
