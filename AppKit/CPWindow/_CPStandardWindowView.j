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
        _CPTexturedWindowHeadSolidColor = [CPColor colorWithCalibratedRed:182.0 / 255.0 green:182.0 / 255.0 blue:182.0 / 255.0 alpha:1.0];
    
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

var _CPStandardWindowViewBodyBackgroundColor            = nil,
    _CPStandardWindowViewDividerBackgroundColor         = nil,
    _CPStandardWindowViewTitleBackgroundColor           = nil,
    _CPStandardWindowViewCloseButtonImage               = nil,
    _CPStandardWindowViewCloseButtonHighlightedImage    = nil;

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
}

+ (CPColor)bodyBackgroundColor
{
    if (!_CPStandardWindowViewBodyBackgroundColor)
        _CPStandardWindowViewBodyBackgroundColor = [CPColor whiteColor];//
        
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
        titleBarHeight = STANDARD_TITLEBAR_HEIGHT + 1.0;
        
    contentRect.origin.y += titleBarHeight;
    contentRect.size.height -= titleBarHeight;

    return contentRect;
}

+ (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    var frameRect = CGRectMakeCopy(aContentRect),
        titleBarHeight = STANDARD_TITLEBAR_HEIGHT + 1.0;
    
    frameRect.origin.y -= titleBarHeight;
    frameRect.size.height += titleBarHeight;
    
    return frameRect;
}

- (CGRect)contentRectForFrameRect:(CGRect)aFrameRect
{
    var contentRect = [[self class] contentRectForFrameRect:aFrameRect];
    
    if ([[[self owningWindow] toolbar] isVisible])
    {
        toolbarHeight = CGRectGetHeight([[self toolbarView] frame]);
        
        contentRect.origin.y += toolbarHeight;
        contentRect.size.height -= toolbarHeight;
    }
    
    return contentRect;
}

- (CGRect)frameRectForContentRect:(CGRect)aContentRect
{
    var frameRect = [[self class] frameRectForContentRect:aContentRect];
    
    if ([[[self owningWindow] toolbar] isVisible])
    {
        toolbarHeight = CGRectGetHeight([[self toolbarView] frame]);
        
        frameRect.origin.y -= toolbarHeight;
        frameRect.size.height += toolbarHeight;
    }
    
    return frameRect;
}

- (id)initWithFrame:(CPRect)aFrame styleMask:(unsigned)aStyleMask owningWindow:(CPWindow)aWindow
{
    self = [super initWithFrame:aFrame styleMask:aStyleMask owningWindow:aWindow];
    
    if (self)
    {
        var theClass = [self class],
            bounds = [self bounds];
        
        _headView = [[_CPTexturedWindowHeadView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(bounds), STANDARD_TITLEBAR_HEIGHT)];
          
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
        [self setShowsResizeIndicator:NO];
        [self setShowsResizeIndicator:YES];
        
        _titleField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        
        [_titleField setFont:[CPFont boldSystemFontOfSize:12.0]];
        [_titleField setAutoresizingMask:CPViewWidthSizable];
        
        // FIXME: Make this to CPLineBreakByTruncatingMiddle once it's implemented.
        [_titleField setLineBreakMode:CPLineBreakByTruncatingTail];
        [_titleField setAlignment:CPCenterTextAlignment];
        
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
            }
            
            _closeButton = [[CPButton alloc] initWithFrame:CGRectMake(8.0, 7.0, 16.0, 16.0)];
            
            [_closeButton setBordered:NO];
            
            [_closeButton setImage:_CPStandardWindowViewCloseButtonImage];
            [_closeButton setAlternateImage:_CPStandardWindowViewCloseButtonHighlightedImage];
            
            [_closeButton setTarget:aWindow];
            [_closeButton setAction:@selector(performClose:)];
            
            [self addSubview:_closeButton];
        }

        
        [self tile];
    }
    
    return self;
}

- (CGSize)toolbarOffset
{
    return CGSizeMake(0.0, STANDARD_TITLEBAR_HEIGHT);
}

- (void)tile
{
    [super tile];

    var owningWindow = [self owningWindow],
        width = CGRectGetWidth([self bounds]);
    
    [_headView setFrameSize:CGSizeMake(width, [self toolbarMaxY])];
    [_dividerView setFrameOrigin:CGPointMake(0.0, CGRectGetMaxY([_headView frame]))];
    [_bodyView setFrameOrigin:CGPointMake(0.0, CGRectGetMaxY([_dividerView frame]))];

    [_titleField setFrame:CGRectMake(10.0, 3.0, width - 20.0, CGRectGetHeight([_titleField frame]))];
    
    [[owningWindow contentView] setFrameOrigin:CGPointMake(0.0, CGRectGetMaxY([_dividerView frame]))];
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
