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

@import "_CPWindowView.j"


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
    _CPStandardWindowViewTitleBackgroundColor               = nil,
    _CPStandardWindowViewCloseButtonImage                   = nil,
    _CPStandardWindowViewCloseButtonHighlightedImage        = nil,
    _CPStandardWindowViewCloseButtonUnsavedImage            = nil,
    _CPStandardWindowViewCloseButtonUnsavedHighlightedImage = nil,
    _CPStandardWindowViewMinimizeButtonImage                = nil,
    _CPStandardWindowViewMinimizeButtonHighlightedImage     = nil;

var STANDARD_GRADIENT_HEIGHT                    = 41.0;
    STANDARD_TITLEBAR_HEIGHT                    = 25.0;

@implementation _CPStandardWindowView : _CPWindowView
{
    _CPTexturedWindowHeadView   _headView;
    CPView                      _dividerView;
    CPView                      _bodyView;
    CPView                      _toolbarView;
    
    CPTextField                 _titleField;
    CPButton                    _closeButton;
    CPButton                    _minimizeButton;

    BOOL                        _isDocumentEdited;
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

+ (CPColor)titleColor
{
    if (!_CPStandardWindowViewTitleBackgroundColor)
        _CPStandardWindowViewTitleBackgroundColor = [CPColor colorWithCalibratedRed:44.0 / 255.0 green:44.0 / 255.0 blue:44.0 / 255.0 alpha:1.0];
    
    return _CPStandardWindowViewTitleBackgroundColor;
}

+ (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    var contentRect = CGRectMakeCopy(aFrameRect),
        titleBarHeight = [self titleBarHeight] + 1.0;
        
    contentRect.origin.y += titleBarHeight;
    contentRect.size.height -= titleBarHeight;

    return contentRect;
}

+ (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    var frameRect = CGRectMakeCopy(aContentRect),
        titleBarHeight = [self titleBarHeight] + 1.0;
    
    frameRect.origin.y -= titleBarHeight;
    frameRect.size.height += titleBarHeight;
    
    return frameRect;
}

+ (float)titleBarHeight
{
    return STANDARD_TITLEBAR_HEIGHT;
}

- (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    var contentRect = [[self class] contentRectForFrameRect:aFrameRect],
        theToolbar = [[self window] toolbar];
    
    if ([theToolbar isVisible])
    {
        toolbarHeight = CGRectGetHeight([[theToolbar _toolbarView] frame]);
        
        contentRect.origin.y += toolbarHeight;
        contentRect.size.height -= toolbarHeight;
    }
    
    return contentRect;
}

- (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    var frameRect = [[self class] frameRectForContentRect:aContentRect],
        theToolbar = [[self window] toolbar];
    
    if ([theToolbar isVisible])
    {
        toolbarHeight = CGRectGetHeight([[theToolbar _toolbarView] frame]);
        
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
        var theClass = [self class],
            bounds = [self bounds];
        
        _headView = [[_CPTexturedWindowHeadView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), [[self class] titleBarHeight])];
          
        [_headView setAutoresizingMask:CPViewWidthSizable];;
        [_headView setHitTests:NO];
        
        [self addSubview:_headView];
        
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
        
        _titleField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        
        [_titleField setFont:[CPFont boldSystemFontOfSize:12.0]];
        [_titleField setAutoresizingMask:CPViewWidthSizable];
        
        // FIXME: Make this to CPLineBreakByTruncatingMiddle once it's implemented.
        [_titleField setLineBreakMode:CPLineBreakByTruncatingTail];
        [_titleField setAlignment:CPCenterTextAlignment];
        [_titleField setTextShadowColor:[CPColor whiteColor]];
        [_titleField setTextShadowOffset:CGSizeMake(0.0, 1.0)];
        
        [_titleField setStringValue:@"Untitled"];
        [_titleField sizeToFit];
        [_titleField setAutoresizingMask:CPViewWidthSizable];
        [_titleField setStringValue:@""];
        
        [self addSubview:_titleField];
        
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

            _closeButton = [[CPButton alloc] initWithFrame:CGRectMake(8.0, 7.0, 16.0, 16.0)];

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
        width = CGRectGetWidth(bounds);

    [_headView setFrameSize:CGSizeMake(width, [self toolbarMaxY])];
    [_dividerView setFrame:CGRectMake(0.0, CGRectGetMaxY([_headView frame]), width, 1.0)];

    var dividerMaxY = CGRectGetMaxY([_dividerView frame]);

    [_bodyView setFrame:CGRectMake(0.0, dividerMaxY, width, CGRectGetHeight(bounds) - dividerMaxY)];

    var leftOffset = 8;

    if (_closeButton)
        leftOffset += 19.0;
    if (_minimizeButton)
        leftOffset += 19.0;

    [_titleField setFrame:CGRectMake(leftOffset, 5.0, width - leftOffset*2.0, CGRectGetHeight([_titleField frame]))];

    [[theWindow contentView] setFrameOrigin:CGPointMake(0.0, CGRectGetMaxY([_dividerView frame]))];
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

- (void)setTitle:(CPString)aTitle
{
    [_titleField setStringValue:aTitle];
}

- (void)mouseDown:(CPEvent)anEvent
{
    if (CGRectContainsPoint([_headView frame], [self convertPoint:[anEvent locationInWindow] fromView:nil]))
        return [self trackMoveWithEvent:anEvent];

    [super mouseDown:anEvent];
}

@end
