/*
 * CPScrollView.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
 *
 * Modified to match Lion style by Antoine Mercadal 2011
 * <antoine.mercadal@archipelproject.org>
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

@import <Foundation/CPNotificationCenter.j>

@import "CPBox.j"
@import "CPClipView.j"
@import "CPScroller.j"
@import "CPView.j"


/*! @ignore */
var _isSystemUsingOverlayScrollers = function()
{
#if PLATFORM(DOM)
  var inner = document.createElement('p'),
      outer = document.createElement('div');

  inner.style.width = "100%";
  inner.style.height = "200px";

  outer.style.position = "absolute";
  outer.style.top = "0px";
  outer.style.left = "0px";
  outer.style.visibility = "hidden";
  outer.style.width = "200px";
  outer.style.height = "150px";
  outer.style.overflow = "hidden";
  outer.appendChild (inner);

  document.body.appendChild (outer);
  var w1 = inner.offsetWidth;
  outer.style.overflow = 'scroll';
  var w2 = inner.offsetWidth;
  if (w1 == w2)
    w2 = outer.clientWidth;

  document.body.removeChild (outer);

  return (w1 - w2 == 0);
#else
  return NO;
#endif
};

/*!
    @ingroup appkit
    @class CPScrollView

    Used to display views that are too large for the viewing area. the CPScrollView
    places scroll bars on the side of the view to allow the user to scroll and see the entire
    contents of the view.
*/

var TIMER_INTERVAL                              = 0.2,
    CPScrollViewDelegate_scrollViewWillScroll_  = 1 << 0,
    CPScrollViewDelegate_scrollViewDidScroll_   = 1 << 1,

    CPScrollViewFadeOutTime                     = 1.3;

var CPScrollerStyleGlobal                       = CPScrollerStyleOverlay,
    CPScrollerStyleGlobalChangeNotification     = @"CPScrollerStyleGlobalChangeNotification";


@implementation CPScrollView : CPView
{
    CPClipView      _contentView;
    CPClipView      _headerClipView;
    CPView          _cornerView;
    CPView          _bottomCornerView;

    id              _delegate;
    CPTimer         _scrollTimer;

    BOOL            _hasVerticalScroller;
    BOOL            _hasHorizontalScroller;
    BOOL            _autohidesScrollers;

    CPScroller      _verticalScroller;
    CPScroller      _horizontalScroller;

    CPInteger       _recursionCount;
    CPInteger       _implementedDelegateMethods;

    float           _verticalLineScroll;
    float           _verticalPageScroll;
    float           _horizontalLineScroll;
    float           _horizontalPageScroll;

    CPBorderType    _borderType;

    CPTimer         _timerScrollersHide;

    int             _scrollerStyle;
    int             _scrollerKnobStyle;
}


#pragma mark -
#pragma mark Class methods

+ (void)initialize
{
    var globalValue = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPScrollersGlobalStyle"];

    if (globalValue == nil || globalValue == -1)
        CPScrollerStyleGlobal = _isSystemUsingOverlayScrollers() ? CPScrollerStyleOverlay : CPScrollerStyleLegacy
    else
        CPScrollerStyleGlobal = globalValue;
}

+ (CPString)defaultThemeClass
{
    return @"scrollview"
}

+ (CPDictionary)themeAttributes
{
    return [CPDictionary dictionaryWithJSObject:{
        @"bottom-corner-color": [CPColor whiteColor],
        @"border-color": [CPColor blackColor]
    }];
}

+ (CGSize)contentSizeForFrameSize:(CGSize)frameSize hasHorizontalScroller:(BOOL)hFlag hasVerticalScroller:(BOOL)vFlag borderType:(CPBorderType)borderType
{
    var bounds = [self _insetBounds:_CGRectMake(0.0, 0.0, frameSize.width, frameSize.height) borderType:borderType],
        scrollerWidth = [CPScroller scrollerWidth];

    if (hFlag)
        bounds.size.height -= scrollerWidth;

    if (vFlag)
        bounds.size.width -= scrollerWidth;

    return bounds.size;
}

+ (CGSize)frameSizeForContentSize:(CGSize)contentSize hasHorizontalScroller:(BOOL)hFlag hasVerticalScroller:(BOOL)vFlag borderType:(CPBorderType)borderType
{
    var bounds = [self _insetBounds:_CGRectMake(0.0, 0.0, contentSize.width, contentSize.height) borderType:borderType],
        widthInset = contentSize.width - bounds.size.width,
        heightInset = contentSize.height - bounds.size.height,
        frameSize = _CGSizeMake(contentSize.width + widthInset, contentSize.height + heightInset),
        scrollerWidth = [CPScroller scrollerWidth];

    if (hFlag)
        frameSize.height -= scrollerWidth;

    if (vFlag)
        frameSize.width -= scrollerWidth;

    return frameSize;
}

+ (CGRect)_insetBounds:(CGRect)bounds borderType:(CPBorderType)borderType
{
    switch (borderType)
    {
        case CPLineBorder:
        case CPBezelBorder:
            return _CGRectInset(bounds, 1.0, 1.0);

        case CPGrooveBorder:
            bounds = _CGRectInset(bounds, 2.0, 2.0);
            ++bounds.origin.y;
            --bounds.size.height;
            return bounds;

        case CPNoBorder:
        default:
            return bounds;
    }
}

/*!
    Get the system wide scroller style.
*/
+ (int)globalScrollerStyle
{
    return CPScrollerStyleGlobal;
}

/*!
    Set the system wide scroller style.

    @param aStyle the scroller style to set all scroller views to use (CPScrollerStyleLegacy or CPScrollerStyleOverlay)
*/
+ (int)setGlobalScrollerStyle:(int)aStyle
{
    CPScrollerStyleGlobal = aStyle;
    [[CPNotificationCenter defaultCenter] postNotificationName:CPScrollerStyleGlobalChangeNotification object:nil];
}


#pragma mark -
#pragma mark Initialization

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _verticalLineScroll = 10.0;
        _verticalPageScroll = 10.0;

        _horizontalLineScroll = 10.0;
        _horizontalPageScroll = 10.0;

        _borderType = CPNoBorder;

        _contentView = [[CPClipView alloc] initWithFrame:[self _insetBounds]];
        [self addSubview:_contentView];

        _headerClipView = [[CPClipView alloc] init];
        [self addSubview:_headerClipView];

        _bottomCornerView = [[CPView alloc] init];
        [self addSubview:_bottomCornerView];

        [self setHasVerticalScroller:YES];
        [self setHasHorizontalScroller:YES];
        _scrollerKnobStyle = CPScrollerKnobStyleDefault;
        [self setScrollerStyle:CPScrollerStyleGlobal];

        _delegate = nil;
        _scrollTimer = nil;
        _implementedDelegateMethods = 0;

        [[CPNotificationCenter defaultCenter] addObserver:self
                                 selector:@selector(_didReceiveDefaultStyleChange:)
                                     name:CPScrollerStyleGlobalChangeNotification
                                   object:nil];
    }

    return self;
}


#pragma mark -
#pragma mark Getters / Setters

/*!
    The delegate of the scroll view
*/
- (id)delegate
{
    return _delegate;
}

/*!
    Set the delegate of the scroll view
*/
- (void)setDelegate:(id)aDelegate
{
    if (aDelegate === _delegate)
        return;

    _delegate = aDelegate;
    _implementedDelegateMethods = 0;

    if (_delegate === nil)
        return;

    if ([_delegate respondsToSelector:@selector(scrollViewWillScroll:)])
        _implementedDelegateMethods |= CPScrollViewDelegate_scrollViewWillScroll_;

    if ([_delegate respondsToSelector:@selector(scrollViewDidScroll:)])
        _implementedDelegateMethods |= CPScrollViewDelegate_scrollViewDidScroll_;
}

- (int)scrollerStyle
{
    return _scrollerStyle;
}

/*!
    Set the scroller style.

    - CPScrollerStyleLegacy: Standard scrollers like Windows or Mac OS X prior to 10.7
    - CPScrollerStyleOverlay: scrollers like those in Mac OS X 10.7+
*/
- (void)setScrollerStyle:(int)aStyle
{
    if (_scrollerStyle === aStyle)
        return;

    _scrollerStyle = aStyle;

    [self _updateScrollerStyle];
}

/*!
    Returns the style of the scroller knob, the bit which moves when scrolling, of the receiver.

    Valid values are:
    <pre>
        CPScrollerKnobStyleLight
        CPScrollerKnobStyleDark
        CPScrollerKnobStyleDefault
    </pre>
*/
- (int)scrollerKnobStyle
{
    return _scrollerKnobStyle;
}

/*!
    Sets the style of the scroller knob, the bit which moves when scrolling.

    Valid values are:
    <pre>
        CPScrollerKnobStyleLight
        CPScrollerKnobStyleDark
        CPScrollerKnobStyleDefault
    </pre>
*/
- (void)setScrollerKnobStyle:(int)newScrollerKnobStyle
{
     if (_scrollerKnobStyle === newScrollerKnobStyle)
        return;

    _scrollerKnobStyle = newScrollerKnobStyle;

   [self _updateScrollerStyle];
}

/*!
    Returns the content view that clips the document.
*/
- (CPClipView)contentView
{
    return _contentView;
}

/*!
    Sets the content view that clips the document.

    @param aContentView the content view
*/
- (void)setContentView:(CPClipView)aContentView
{
    if (_contentView === aContentView || !aContentView)
        return;

    var documentView = [aContentView documentView];

    if (documentView)
        [documentView removeFromSuperview];

    [_contentView removeFromSuperview];

    _contentView = aContentView;

    [_contentView setDocumentView:documentView];

    [self addSubview:_contentView];

    // This will size the content view appropriately, so no need to size it in this method.
    [self reflectScrolledClipView:_contentView];
}

/*!
    Returns the size of the scroll view's content view.
*/
- (CGSize)contentSize
{
    return [_contentView frame].size;
}

/*!
    Returns the view that is scrolled for the user.
*/
- (id)documentView
{
    return [_contentView documentView];
}

/*!
    Sets the view that is scrolled for the user.

    @param aView the view that will be scrolled
*/
- (void)setDocumentView:(CPView)aView
{
    [_contentView setDocumentView:aView];

    // FIXME: This should be observed.
    [self _updateCornerAndHeaderView];
    [self reflectScrolledClipView:_contentView];
}

/*!
    Returns the border type drawn around the view.
*/
- (CPBorderType)borderType
{
    return _borderType;
}

/*!
    Sets the type of border to be drawn around the view.

    Valid types are:
    <pre>
    CPNoBorder
    CPLineBorder
    CPBezelBorder
    CPGrooveBorder</pre>
*/
- (void)setBorderType:(CPBorderType)borderType
{
    if (_borderType == borderType)
        return;

    _borderType = borderType;

    [self reflectScrolledClipView:_contentView];
    [self setNeedsDisplay:YES];
}


/*!
    Returns the scroll view's horizontal scroller.
*/
- (CPScroller)horizontalScroller
{
    return _horizontalScroller;
}

/*!
    Sets the scroll view's horizontal scroller.

    @param aScroller the horizontal scroller for the scroll view
*/
- (void)setHorizontalScroller:(CPScroller)aScroller
{
    if (_horizontalScroller === aScroller)
        return;

    [_horizontalScroller removeFromSuperview];
    [_horizontalScroller setTarget:nil];
    [_horizontalScroller setAction:nil];

    _horizontalScroller = aScroller;

    [_horizontalScroller setTarget:self];
    [_horizontalScroller setAction:@selector(_horizontalScrollerDidScroll:)];

    [self addSubview:_horizontalScroller];

    [self _updateScrollerStyle];
}

/*!
    Returns \c YES if the scroll view can have a horizontal scroller.
*/
- (BOOL)hasHorizontalScroller
{
    return _hasHorizontalScroller;
}

/*!
    Specifies whether the scroll view can have a horizontal scroller.

    @param hasHorizontalScroller \c YES lets the scroll view
    allocate a horizontal scroller if necessary.
*/
- (void)setHasHorizontalScroller:(BOOL)shouldHaveHorizontalScroller
{
    if (_hasHorizontalScroller === shouldHaveHorizontalScroller)
        return;

    _hasHorizontalScroller = shouldHaveHorizontalScroller;

    if (_hasHorizontalScroller && !_horizontalScroller)
    {
        var bounds = [self _insetBounds];

        [self setHorizontalScroller:[[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, MAX(_CGRectGetWidth(bounds), [CPScroller scrollerWidthInStyle:_scrollerStyle] + 1), [CPScroller scrollerWidthInStyle:_scrollerStyle])]];
        [[self horizontalScroller] setFrameSize:CGSizeMake(_CGRectGetWidth(bounds), [CPScroller scrollerWidthInStyle:_scrollerStyle])];
    }

    [self reflectScrolledClipView:_contentView];
}

/*!
    Returns the scroll view's vertical scroller.
*/
- (CPScroller)verticalScroller
{
    return _verticalScroller;
}

/*!
    Sets the scroll view's vertical scroller.

    @param aScroller the vertical scroller
*/
- (void)setVerticalScroller:(CPScroller)aScroller
{
    if (_verticalScroller === aScroller)
        return;

    [_verticalScroller removeFromSuperview];
    [_verticalScroller setTarget:nil];
    [_verticalScroller setAction:nil];

    _verticalScroller = aScroller;

    [_verticalScroller setTarget:self];
    [_verticalScroller setAction:@selector(_verticalScrollerDidScroll:)];

    [self addSubview:_verticalScroller];

    [self _updateScrollerStyle];
}

/*!
    Returns \c YES if the scroll view can have a vertical scroller.
*/
- (BOOL)hasVerticalScroller
{
    return _hasVerticalScroller;
}

/*!
    Specifies whether the scroll view can have a vertical scroller.
    It allocates it if necessary.

    @param hasVerticalScroller \c YES allows the scroll view to
    display a vertical scroller
*/
- (void)setHasVerticalScroller:(BOOL)shouldHaveVerticalScroller
{
    if (_hasVerticalScroller === shouldHaveVerticalScroller)
        return;

    _hasVerticalScroller = shouldHaveVerticalScroller;

    if (_hasVerticalScroller && !_verticalScroller)
    {
        var bounds = [self _insetBounds];

        [self setVerticalScroller:[[CPScroller alloc] initWithFrame:_CGRectMake(0.0, 0.0, [CPScroller scrollerWidthInStyle:_scrollerStyle], MAX(_CGRectGetHeight(bounds), [CPScroller scrollerWidthInStyle:_scrollerStyle] + 1))]];
        [[self verticalScroller] setFrameSize:CGSizeMake([CPScroller scrollerWidthInStyle:_scrollerStyle], _CGRectGetHeight(bounds))];
    }

    [self reflectScrolledClipView:_contentView];
}

/*!
    Returns \c YES if the scroll view hides its scroll bars when not necessary.
*/
- (BOOL)autohidesScrollers
{
    return _autohidesScrollers;
}

/*!
    Sets whether the scroll view hides its scroll bars when not needed.

    @param autohidesScrollers \c YES causes the scroll bars
    to be hidden when not needed.
*/
- (void)setAutohidesScrollers:(BOOL)autohidesScrollers
{
    if (_autohidesScrollers == autohidesScrollers)
        return;

    _autohidesScrollers = autohidesScrollers;

    [self reflectScrolledClipView:_contentView];
}

- (CPView)bottomCornerView
{
    return _bottomCornerView;
}

- (void)setBottomCornerView:(CPView)aBottomCornerView
{
    if (_bottomCornerView === aBottomCornerView)
        return;

    [_bottomCornerView removeFromSuperview];

    [aBottomCornerView setFrame:[self _bottomCornerViewFrame]];
    [self addSubview:aBottomCornerView];

    _bottomCornerView = aBottomCornerView;

    [self _updateCornerAndHeaderView];
}

/*!
    Returns how much the document moves when scrolled.
*/
- (float)lineScroll
{
    return [self horizontalLineScroll];
}

/*!
    Sets how much the document moves when scrolled. Sets the vertical and horizontal scroll.

    @param aLineScroll the amount to move the document when scrolled
*/
- (void)setLineScroll:(float)aLineScroll
{
    [self setHorizontalLineScroll:aLineScroll];
    [self setVerticalLineScroll:aLineScroll];
}

/*!
    Returns how much the document moves horizontally when scrolled.
*/
- (float)horizontalLineScroll
{
    return _horizontalLineScroll;
}

/*!
    Sets how much the document moves when scrolled horizontally.

    @param aLineScroll the amount to move horizontally when scrolled.
*/
- (void)setHorizontalLineScroll:(float)aLineScroll
{
    _horizontalLineScroll = aLineScroll;
}

/*!
    Returns how much the document moves vertically when scrolled.
*/
- (float)verticalLineScroll
{
    return _verticalLineScroll;
}

/*!
    Sets how much the document moves when scrolled vertically.

    @param aLineScroll the new amount to move vertically when scrolled.
*/
- (void)setVerticalLineScroll:(float)aLineScroll
{
    _verticalLineScroll = aLineScroll;
}

/*!
    Returns the vertical and horizontal page scroll amount.
*/
- (float)pageScroll
{
    return [self horizontalPageScroll];
}

/*!
    Sets the horizontal and vertical page scroll amount.

    @param aPageScroll the new horizontal and vertical page scroll amount
*/
- (void)setPageScroll:(float)aPageScroll
{
    [self setHorizontalPageScroll:aPageScroll];
    [self setVerticalPageScroll:aPageScroll];
}

/*!
    Returns the horizontal page scroll amount.
*/
- (float)horizontalPageScroll
{
    return _horizontalPageScroll;
}

/*!
    Sets the horizontal page scroll amount.

    @param aPageScroll the new horizontal page scroll amount
*/
- (void)setHorizontalPageScroll:(float)aPageScroll
{
    _horizontalPageScroll = aPageScroll;
}

/*!
    Returns the vertical page scroll amount.
*/
- (float)verticalPageScroll
{
    return _verticalPageScroll;
}

/*!
    Sets the vertical page scroll amount.

    @param aPageScroll the new vertical page scroll amount
*/
- (void)setVerticalPageScroll:(float)aPageScroll
{
    _verticalPageScroll = aPageScroll;
}


#pragma mark -
#pragma mark Privates

/* @ignore */
- (void)_updateScrollerStyle
{
    if (_hasHorizontalScroller)
    {
        [_horizontalScroller setStyle:_scrollerStyle];
        [_horizontalScroller unsetThemeState:CPThemeStateSelected];
        switch (_scrollerKnobStyle)
        {
            case CPScrollerKnobStyleLight:
                [_horizontalScroller unsetThemeState:CPThemeStateScrollerKnobDark];
                [_horizontalScroller setThemeState:CPThemeStateScrollerKnobLight];
                break;
            case CPScrollerKnobStyleDark:
                [_horizontalScroller unsetThemeState:CPThemeStateScrollerKnobLight];
                [_horizontalScroller setThemeState:CPThemeStateScrollerKnobDark];
                break;
            default:
                [_horizontalScroller unsetThemeState:CPThemeStateScrollerKnobLight];
                [_horizontalScroller unsetThemeState:CPThemeStateScrollerKnobDark];
        }
    }
    if (_hasVerticalScroller)
    {
        [_verticalScroller setStyle:_scrollerStyle];
        [_verticalScroller unsetThemeState:CPThemeStateSelected];
        switch (_scrollerKnobStyle)
        {
            case CPScrollerKnobStyleLight:
                [_verticalScroller unsetThemeState:CPThemeStateScrollerKnobDark];
                [_verticalScroller setThemeState:CPThemeStateScrollerKnobLight];
                break;
            case CPScrollerKnobStyleDark:
                [_verticalScroller unsetThemeState:CPThemeStateScrollerKnobLight];
                [_verticalScroller setThemeState:CPThemeStateScrollerKnobDark];
                break;
            default:
                [_verticalScroller unsetThemeState:CPThemeStateScrollerKnobLight];
                [_verticalScroller unsetThemeState:CPThemeStateScrollerKnobDark];
        }
    }

    if (_scrollerStyle == CPScrollerStyleOverlay)
    {
        if (_timerScrollersHide)
            [_timerScrollersHide invalidate];
        _timerScrollersHide = [CPTimer scheduledTimerWithTimeInterval:CPScrollViewFadeOutTime target:self selector:@selector(_hideScrollers:) userInfo:nil repeats:NO];
        [[self bottomCornerView] setHidden:YES];
    }
    else
        [[self bottomCornerView] setHidden:NO];

    [self reflectScrolledClipView:_contentView];
}

/* @ignore */
- (CGRect)_insetBounds
{
    return [[self class] _insetBounds:[self bounds] borderType:_borderType];
}

/* @ignore */
- (void)_updateCornerAndHeaderView
{
    var documentView = [self documentView],
        currentHeaderView = [self _headerView],
        documentHeaderView = [documentView respondsToSelector:@selector(headerView)] ? [documentView headerView] : nil;

    if (currentHeaderView !== documentHeaderView)
    {
        [currentHeaderView removeFromSuperview];
        [_headerClipView setDocumentView:documentHeaderView];
    }

    var documentCornerView = [documentView respondsToSelector:@selector(cornerView)] ? [documentView cornerView] : nil;

    if (_cornerView !== documentCornerView)
    {
        [_cornerView removeFromSuperview];

        _cornerView = documentCornerView;

        if (_cornerView)
            [self addSubview:_cornerView];
    }

    [self reflectScrolledClipView:_contentView];
    [documentHeaderView setNeedsLayout];
    [documentHeaderView setNeedsDisplay:YES];
}

/* @ignore */
- (CPView)_headerView
{
    return [_headerClipView documentView];
}

/* @ignore */
- (CGRect)_cornerViewFrame
{
    if (!_cornerView)
        return _CGRectMakeZero();

    var bounds = [self _insetBounds],
        frame = [_cornerView frame];

    frame.origin.x = _CGRectGetMaxX(bounds) - _CGRectGetWidth(frame);
    frame.origin.y = _CGRectGetMinY(bounds);

    return frame;
}

/* @ignore */
- (CGRect)_headerClipViewFrame
{
    var headerView = [self _headerView];

    if (!headerView)
        return _CGRectMakeZero();

    var frame = [self _insetBounds];

    frame.size.height = _CGRectGetHeight([headerView frame]);
    frame.size.width -= _CGRectGetWidth([self _cornerViewFrame]);

    return frame;
}

/* @ignore */
- (CGRect)_bottomCornerViewFrame
{
    if ([[self horizontalScroller] isHidden] || [[self verticalScroller] isHidden])
        return CGRectMakeZero();

    var verticalFrame = [[self verticalScroller] frame],
        bottomCornerFrame = CGRectMakeZero();

    bottomCornerFrame.origin.x = CGRectGetMinX(verticalFrame);
    bottomCornerFrame.origin.y = CGRectGetMaxY(verticalFrame);
    bottomCornerFrame.size.width = [CPScroller scrollerWidthInStyle:_scrollerStyle];
    bottomCornerFrame.size.height = [CPScroller scrollerWidthInStyle:_scrollerStyle];

    return bottomCornerFrame;
}

/* @ignore */
- (void)_verticalScrollerDidScroll:(CPScroller)aScroller
{
    var value = [aScroller floatValue],
        documentFrame = [[_contentView documentView] frame],
        contentBounds = [_contentView bounds];


    switch ([_verticalScroller hitPart])
    {
        case CPScrollerDecrementLine:
            contentBounds.origin.y -= _verticalLineScroll;
            break;

        case CPScrollerIncrementLine:
            contentBounds.origin.y += _verticalLineScroll;
            break;

        case CPScrollerDecrementPage:
            contentBounds.origin.y -= _CGRectGetHeight(contentBounds) - _verticalPageScroll;
            break;

        case CPScrollerIncrementPage:
            contentBounds.origin.y += _CGRectGetHeight(contentBounds) - _verticalPageScroll;
            break;

        // We want integral bounds!
        case CPScrollerKnobSlot:
        case CPScrollerKnob:
        default:
            contentBounds.origin.y = ROUND(value * (_CGRectGetHeight(documentFrame) - _CGRectGetHeight(contentBounds)));
    }

    [self _sendDelegateMessages];

    [_contentView scrollToPoint:contentBounds.origin];
}

/* @ignore */
- (void)_horizontalScrollerDidScroll:(CPScroller)aScroller
{
   var value = [aScroller floatValue],
       documentFrame = [[self documentView] frame],
       contentBounds = [_contentView bounds];

    switch ([_horizontalScroller hitPart])
    {
        case CPScrollerDecrementLine:
            contentBounds.origin.x -= _horizontalLineScroll;
            break;

        case CPScrollerIncrementLine:
            contentBounds.origin.x += _horizontalLineScroll;
            break;

        case CPScrollerDecrementPage:
            contentBounds.origin.x -= _CGRectGetWidth(contentBounds) - _horizontalPageScroll;
            break;

        case CPScrollerIncrementPage:
            contentBounds.origin.x += _CGRectGetWidth(contentBounds) - _horizontalPageScroll;
            break;

        // We want integral bounds!
        case CPScrollerKnobSlot:
        case CPScrollerKnob:
        default:
            contentBounds.origin.x = ROUND(value * (_CGRectGetWidth(documentFrame) - _CGRectGetWidth(contentBounds)));
    }

    [self _sendDelegateMessages];

    [_contentView scrollToPoint:contentBounds.origin];
    [_headerClipView scrollToPoint:CGPointMake(contentBounds.origin.x, 0.0)];
}

/* @ignore */
- (void)_sendDelegateMessages
{
    if (_implementedDelegateMethods == 0)
        return;

    if (!_scrollTimer)
    {
        [self _scrollViewWillScroll];
        _scrollTimer = [CPTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(_scrollViewDidScroll) userInfo:nil repeats:YES];
    }
    else
        [_scrollTimer setFireDate:[CPDate dateWithTimeIntervalSinceNow:TIMER_INTERVAL]];
}

/* @ignore */
- (void)_hideScrollers:(CPTimer)theTimer
{
    if ([_verticalScroller allowFadingOut])
        [_verticalScroller fadeOut];
    if ([_horizontalScroller allowFadingOut])
        [_horizontalScroller fadeOut];
    _timerScrollersHide = nil;
}

/* @ignore */
- (void)_respondToScrollWheelEventWithDeltaX:(float)deltaX deltaY:(float)deltaY
{
    var documentFrame = [[self documentView] frame],
        contentBounds = [_contentView bounds],
        contentFrame = [_contentView frame],
        enclosingScrollView = [self enclosingScrollView];

    // We want integral bounds!
    contentBounds.origin.x = ROUND(contentBounds.origin.x + deltaX);
    contentBounds.origin.y = ROUND(contentBounds.origin.y + deltaY);

    var constrainedOrigin = [_contentView constrainScrollPoint:CGPointCreateCopy(contentBounds.origin)],
        extraX = contentBounds.origin.x - constrainedOrigin.x,
        extraY = contentBounds.origin.y - constrainedOrigin.y;

    [self _sendDelegateMessages];

    [_contentView scrollToPoint:constrainedOrigin];
    [_headerClipView scrollToPoint:CGPointMake(constrainedOrigin.x, 0.0)];

    if (extraX || extraY)
        [enclosingScrollView _respondToScrollWheelEventWithDeltaX:extraX deltaY:extraY];
}

/* @ignore */
- (void)_scrollViewWillScroll
{
    if (_implementedDelegateMethods & CPScrollViewDelegate_scrollViewWillScroll_)
        [_delegate scrollViewWillScroll:self];
}

/* @ignore */
- (void)_scrollViewDidScroll
{
    [_scrollTimer invalidate];
    _scrollTimer = nil;

    if (_implementedDelegateMethods & CPScrollViewDelegate_scrollViewDidScroll_)
        [_delegate scrollViewDidScroll:self];
}

/*! @ignore*/
- (void)_didReceiveDefaultStyleChange:(CPNotification)aNotification
{
    [self setScrollerStyle:CPScrollerStyleGlobal];
}



#pragma mark -
#pragma mark Utilities

/*!
    Lays out the scroll view's components.
*/
- (void)tile
{
    // yuck.
    // RESIZE: tile->setHidden AND refl
    // Outside Change: refl->tile->setHidden AND refl
    // scroll: refl.
}

/*!
    Resizes the scroll view to contain the specified clip view.

    @param aClipView the clip view to resize to
*/
- (void)reflectScrolledClipView:(CPClipView)aClipView
{
    if (_contentView !== aClipView)
        return;

    if (_recursionCount > 5)
        return;

    ++_recursionCount;

    var documentView = [self documentView];

    if (!documentView)
    {
        if (_autohidesScrollers)
        {
            [_verticalScroller setHidden:YES];
            [_horizontalScroller setHidden:YES];
        }

        [_contentView setFrame:[self _insetBounds]];
        [_headerClipView setFrame:_CGRectMakeZero()];

        --_recursionCount;

        return;
    }

    var documentFrame = [documentView frame], // the size of the whole document
        contentFrame = [self _insetBounds], // assume it takes up the entire size of the scrollview (no scrollers)
        headerClipViewFrame = [self _headerClipViewFrame],
        headerClipViewHeight = _CGRectGetHeight(headerClipViewFrame);

    contentFrame.origin.y += headerClipViewHeight;
    contentFrame.size.height -= headerClipViewHeight;

    var difference = _CGSizeMake(_CGRectGetWidth(documentFrame) - _CGRectGetWidth(contentFrame), _CGRectGetHeight(documentFrame) - _CGRectGetHeight(contentFrame)),
        verticalScrollerWidth = _CGRectGetWidth([_verticalScroller frame]),
        horizontalScrollerHeight = _CGRectGetHeight([_horizontalScroller frame]),
        hasVerticalScroll = difference.height > 0.0,
        hasHorizontalScroll = difference.width > 0.0,
        shouldShowVerticalScroller = _hasVerticalScroller && (!_autohidesScrollers || hasVerticalScroll),
        shouldShowHorizontalScroller = _hasHorizontalScroller && (!_autohidesScrollers || hasHorizontalScroll);

    // Now we have to account for the shown scrollers affecting the deltas.
    if (shouldShowVerticalScroller)
    {
        if (_scrollerStyle === CPScrollerStyleLegacy)
            difference.width += verticalScrollerWidth;
        hasHorizontalScroll = difference.width > 0.0;
        shouldShowHorizontalScroller = _hasHorizontalScroller && (!_autohidesScrollers || hasHorizontalScroll);
    }

    if (shouldShowHorizontalScroller)
    {
        if (_scrollerStyle === CPScrollerStyleLegacy)
            difference.height += horizontalScrollerHeight;
        hasVerticalScroll = difference.height > 0.0;
        shouldShowVerticalScroller = _hasVerticalScroller && (!_autohidesScrollers || hasVerticalScroll);
    }

    // We now definitively know which scrollers are shown or not, as well as whether they are showing scroll values.
    [_verticalScroller setHidden:!shouldShowVerticalScroller];
    [_verticalScroller setEnabled:hasVerticalScroll];

    [_horizontalScroller setHidden:!shouldShowHorizontalScroller];
    [_horizontalScroller setEnabled:hasHorizontalScroll];

    var overlay = [CPScroller scrollerOverlay];
    if (_scrollerStyle === CPScrollerStyleLegacy)
    {
        // We can thus appropriately account for them changing the content size.
        if (shouldShowVerticalScroller)
            contentFrame.size.width -= verticalScrollerWidth;

        if (shouldShowHorizontalScroller)
            contentFrame.size.height -= horizontalScrollerHeight;
        overlay = 0;
    }

    var scrollPoint = [_contentView bounds].origin,
        wasShowingVerticalScroller = ![_verticalScroller isHidden],
        wasShowingHorizontalScroller = ![_horizontalScroller isHidden];

    if (shouldShowVerticalScroller)
    {
        var verticalScrollerY =
            MAX(_CGRectGetMinY(contentFrame), MAX(_CGRectGetMaxY([self _cornerViewFrame]), _CGRectGetMaxY(headerClipViewFrame)));

        var verticalScrollerHeight = _CGRectGetMaxY(contentFrame) - verticalScrollerY;

        // Make a gap at the bottom of the vertical scroller so that the horizontal and vertical can't overlap.
        if (_scrollerStyle === CPScrollerStyleOverlay && hasHorizontalScroll)
            verticalScrollerHeight -= horizontalScrollerHeight;

        var documentHeight = _CGRectGetHeight(documentFrame);
        [_verticalScroller setFloatValue:(difference.height <= 0.0) ? 0.0 : scrollPoint.y / difference.height];
        [_verticalScroller setKnobProportion:documentHeight > 0 ? _CGRectGetHeight(contentFrame) / documentHeight : 1.0];
        [_verticalScroller setFrame:_CGRectMake(_CGRectGetMaxX(contentFrame) - overlay, verticalScrollerY, verticalScrollerWidth, verticalScrollerHeight)];
    }
    else if (wasShowingVerticalScroller)
    {
        [_verticalScroller setFloatValue:0.0];
        [_verticalScroller setKnobProportion:1.0];
    }

    if (shouldShowHorizontalScroller)
    {
        var horizontalScrollerWidth = _CGRectGetWidth(contentFrame);
        // Make a gap at the bottom of the vertical scroller so that the horizontal and vertical can't overlap.
        if (_scrollerStyle === CPScrollerStyleOverlay && hasVerticalScroll)
            horizontalScrollerWidth -= verticalScrollerWidth;

        var documentWidth = _CGRectGetWidth(documentFrame);

        [_horizontalScroller setFloatValue:(difference.width <= 0.0) ? 0.0 : scrollPoint.x / difference.width];
        [_horizontalScroller setKnobProportion:documentWidth > 0 ? _CGRectGetWidth(contentFrame) / documentWidth : 1.0];
        [_horizontalScroller setFrame:_CGRectMake(_CGRectGetMinX(contentFrame), _CGRectGetMaxY(contentFrame) - overlay, horizontalScrollerWidth, horizontalScrollerHeight)];
    }
    else if (wasShowingHorizontalScroller)
    {
        [_horizontalScroller setFloatValue:0.0];
        [_horizontalScroller setKnobProportion:1.0];
    }

    [_contentView setFrame:contentFrame];
    [_headerClipView setFrame:headerClipViewFrame];
    [[_headerClipView documentView] setNeedsDisplay:YES];
    [_cornerView setFrame:[self _cornerViewFrame]];

    if (_scrollerStyle === CPScrollerStyleLegacy)
    {
        [[self bottomCornerView] setFrame:[self _bottomCornerViewFrame]];
        [[self bottomCornerView] setBackgroundColor:[self currentValueForThemeAttribute:@"bottom-corner-color"]];
    }

    --_recursionCount;
}

/*!
    Momentarily display the scrollers if the scroller style is CPScrollerStyleOverlay.
*/
- (void)flashScrollers
{
    if (_scrollerStyle === CPScrollerStyleLegacy)
        return;

    if (_hasHorizontalScroller)
    {
        [_horizontalScroller setHidden:NO];
        [_horizontalScroller fadeIn];
    }

    if (_hasVerticalScroller)
    {
        [_verticalScroller setHidden:NO];
        [_verticalScroller fadeIn];
    }

    if (_timerScrollersHide)
        [_timerScrollersHide invalidate]
    _timerScrollersHide = [CPTimer scheduledTimerWithTimeInterval:CPScrollViewFadeOutTime target:self selector:@selector(_hideScrollers:) userInfo:nil repeats:NO];
}

/* @ignore */
- (void)resizeSubviewsWithOldSize:(CGSize)aSize
{
    [self reflectScrolledClipView:_contentView];
}


#pragma mark -
#pragma mark Overrides

- (void)drawRect:(CPRect)aRect
{
    [super drawRect:aRect];

    if (_borderType == CPNoBorder)
        return;

    var strokeRect = [self bounds],
        context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetLineWidth(context, 1);

    switch (_borderType)
    {
        case CPLineBorder:
            CGContextSetStrokeColor(context, [self currentValueForThemeAttribute:@"border-color"]);
            CGContextStrokeRect(context, _CGRectInset(strokeRect, 0.5, 0.5));
            break;

        case CPBezelBorder:
            [self _drawGrayBezelInContext:context bounds:strokeRect];
            break;

        case CPGrooveBorder:
            [self _drawGrooveInContext:context bounds:strokeRect];
            break;

        default:
            break;
    }
}

- (void)_drawGrayBezelInContext:(CGContext)context bounds:(CGRect)aRect
{
    CGContextBeginPath(context);
    CGContextSetStrokeColor(context, [CPColor colorWithWhite:142.0 / 255.0 alpha:1.0]);

    var y = _CGRectGetMinY(aRect) + 0.5;

    CGContextMoveToPoint(context, _CGRectGetMinX(aRect), y);
    CGContextAddLineToPoint(context, _CGRectGetMinX(aRect) + 1.0, y);
    CGContextStrokePath(context);

    CGContextBeginPath(context);
    CGContextSetStrokeColor(context, [CPColor colorWithWhite:192.0 / 255.0 alpha:1.0]);
    CGContextMoveToPoint(context, _CGRectGetMinX(aRect) + 1.0, y);
    CGContextAddLineToPoint(context, _CGRectGetMaxX(aRect) - 1.0, y);
    CGContextStrokePath(context);

    CGContextBeginPath(context);
    CGContextSetStrokeColor(context, [CPColor colorWithWhite:142.0 / 255.0 alpha:1.0]);
    CGContextMoveToPoint(context, _CGRectGetMaxX(aRect) - 1.0, y);
    CGContextAddLineToPoint(context, _CGRectGetMaxX(aRect), y);
    CGContextStrokePath(context);

    CGContextBeginPath(context);
    CGContextSetStrokeColor(context, [CPColor colorWithWhite:190.0 / 255.0 alpha:1.0]);

    var x = _CGRectGetMaxX(aRect) - 0.5;

    CGContextMoveToPoint(context, x, _CGRectGetMinY(aRect) + 1.0);
    CGContextAddLineToPoint(context, x, _CGRectGetMaxY(aRect));

    CGContextMoveToPoint(context, x - 0.5, _CGRectGetMaxY(aRect) - 0.5);
    CGContextAddLineToPoint(context, _CGRectGetMinX(aRect), _CGRectGetMaxY(aRect) - 0.5);

    x = _CGRectGetMinX(aRect) + 0.5;

    CGContextMoveToPoint(context, x, _CGRectGetMaxY(aRect));
    CGContextAddLineToPoint(context, x, _CGRectGetMinY(aRect) + 1.0);

    CGContextStrokePath(context);
}

- (void)_drawGrooveInContext:(CGContext)context bounds:(CGRect)aRect
{
    CGContextBeginPath(context);
    CGContextSetStrokeColor(context, [CPColor colorWithWhite:159.0 / 255.0 alpha:1.0]);

    var y = _CGRectGetMinY(aRect) + 0.5;

    CGContextMoveToPoint(context, _CGRectGetMinX(aRect), y);
    CGContextAddLineToPoint(context, _CGRectGetMaxX(aRect), y);

    var x = _CGRectGetMaxX(aRect) - 1.5;

    CGContextMoveToPoint(context, x, _CGRectGetMinY(aRect) + 2.0);
    CGContextAddLineToPoint(context, x, _CGRectGetMaxY(aRect) - 1.0);

    y = _CGRectGetMaxY(aRect) - 1.5;

    CGContextMoveToPoint(context, _CGRectGetMaxX(aRect) - 1.0, y);
    CGContextAddLineToPoint(context, _CGRectGetMinX(aRect) + 2.0, y);

    x = _CGRectGetMinX(aRect) + 0.5;

    CGContextMoveToPoint(context, x, _CGRectGetMaxY(aRect));
    CGContextAddLineToPoint(context, x, _CGRectGetMinY(aRect));

    CGContextStrokePath(context);

    CGContextBeginPath(context);
    CGContextSetStrokeColor(context, [CPColor whiteColor]);

    var rect = _CGRectOffset(aRect, 1.0, 1.0);

    rect.size.width -= 1.0;
    rect.size.height -= 1.0;
    CGContextStrokeRect(context, _CGRectInset(rect, 0.5, 0.5));

    CGContextBeginPath(context);
    CGContextSetStrokeColor(context, [CPColor colorWithWhite:192.0 / 255.0 alpha:1.0]);

    y = _CGRectGetMinY(aRect) + 2.5;

    CGContextMoveToPoint(context, _CGRectGetMinX(aRect) + 2.0, y);
    CGContextAddLineToPoint(context, _CGRectGetMaxX(aRect) - 2.0, y);
    CGContextStrokePath(context);
}

/*!
    Handles a scroll wheel event from the user.

    @param anEvent the scroll wheel event
*/
- (void)scrollWheel:(CPEvent)anEvent
{
    if (_timerScrollersHide)
        [_timerScrollersHide invalidate];
    if (![_verticalScroller isHidden])
        [_verticalScroller fadeIn];
    if (![_horizontalScroller isHidden])
        [_horizontalScroller fadeIn];
    if (![_horizontalScroller isHidden] || ![_verticalScroller isHidden])
        _timerScrollersHide = [CPTimer scheduledTimerWithTimeInterval:CPScrollViewFadeOutTime target:self selector:@selector(_hideScrollers:) userInfo:nil repeats:NO];

    [self _respondToScrollWheelEventWithDeltaX:[anEvent deltaX] deltaY:[anEvent deltaY]];
}

- (void)scrollPageUp:(id)sender
{
    var contentBounds = [_contentView bounds];
    [self moveByOffset:CGSizeMake(0.0, -(_CGRectGetHeight(contentBounds) - _verticalPageScroll))];
}

- (void)scrollPageDown:(id)sender
{
    var contentBounds = [_contentView bounds];
    [self moveByOffset:CGSizeMake(0.0, _CGRectGetHeight(contentBounds) - _verticalPageScroll)];
}

- (void)scrollToBeginningOfDocument:(id)sender
{
    [_contentView scrollToPoint:_CGPointMakeZero()];
    [_headerClipView scrollToPoint:_CGPointMakeZero()];
}

- (void)scrollToEndOfDocument:(id)sender
{
    var contentBounds = [_contentView bounds],
        documentFrame = [[self documentView] frame],
        scrollPoint = _CGPointMake(0.0, _CGRectGetHeight(documentFrame) - _CGRectGetHeight(contentBounds));

    [_contentView scrollToPoint:scrollPoint];
    [_headerClipView scrollToPoint:_CGPointMakeZero()];
}

- (void)moveLeft:(id)sender
{
    [self moveByOffset:CGSizeMake(-_horizontalLineScroll, 0.0)];
}

- (void)moveRight:(id)sender
{
    [self moveByOffset:CGSizeMake(_horizontalLineScroll, 0.0)];
}

- (void)moveUp:(id)sender
{
    [self moveByOffset:CGSizeMake(0.0, -_verticalLineScroll)];
}

- (void)moveDown:(id)sender
{
    [self moveByOffset:CGSizeMake(0.0, _verticalLineScroll)];
}

- (void)moveByOffset:(CGSize)aSize
{
    var documentFrame = [[self documentView] frame],
        contentBounds = [_contentView bounds];

    contentBounds.origin.x += aSize.width;
    contentBounds.origin.y += aSize.height;

    [_contentView scrollToPoint:contentBounds.origin];
    [_headerClipView scrollToPoint:CGPointMake(contentBounds.origin.x, 0)];
}

@end


var CPScrollViewContentViewKey          = @"CPScrollViewContentView",
    CPScrollViewHeaderClipViewKey       = @"CPScrollViewHeaderClipViewKey",
    CPScrollViewVLineScrollKey          = @"CPScrollViewVLineScroll",
    CPScrollViewHLineScrollKey          = @"CPScrollViewHLineScroll",
    CPScrollViewVPageScrollKey          = @"CPScrollViewVPageScroll",
    CPScrollViewHPageScrollKey          = @"CPScrollViewHPageScroll",
    CPScrollViewHasVScrollerKey         = @"CPScrollViewHasVScroller",
    CPScrollViewHasHScrollerKey         = @"CPScrollViewHasHScroller",
    CPScrollViewVScrollerKey            = @"CPScrollViewVScroller",
    CPScrollViewHScrollerKey            = @"CPScrollViewHScroller",
    CPScrollViewAutohidesScrollerKey    = @"CPScrollViewAutohidesScroller",
    CPScrollViewCornerViewKey           = @"CPScrollViewCornerViewKey",
    CPScrollViewBottomCornerViewKey     = @"CPScrollViewBottomCornerViewKey",
    CPScrollViewBorderTypeKey           = @"CPScrollViewBorderTypeKey",
    CPScrollViewScrollerStyleKey        = @"CPScrollViewScrollerStyleKey",
    CPScrollViewScrollerKnobStyleKey    = @"CPScrollViewScrollerKnobStyleKey";

@implementation CPScrollView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _verticalLineScroll     = [aCoder decodeFloatForKey:CPScrollViewVLineScrollKey];
        _verticalPageScroll     = [aCoder decodeFloatForKey:CPScrollViewVPageScrollKey];

        _horizontalLineScroll   = [aCoder decodeFloatForKey:CPScrollViewHLineScrollKey];
        _horizontalPageScroll   = [aCoder decodeFloatForKey:CPScrollViewHPageScrollKey];

        _contentView            = [aCoder decodeObjectForKey:CPScrollViewContentViewKey];
        _headerClipView         = [aCoder decodeObjectForKey:CPScrollViewHeaderClipViewKey];

        if (!_headerClipView)
        {
            _headerClipView = [[CPClipView alloc] init];
            [self addSubview:_headerClipView];
        }

        _verticalScroller       = [aCoder decodeObjectForKey:CPScrollViewVScrollerKey];
        _horizontalScroller     = [aCoder decodeObjectForKey:CPScrollViewHScrollerKey];

        _hasVerticalScroller    = [aCoder decodeBoolForKey:CPScrollViewHasVScrollerKey];
        _hasHorizontalScroller  = [aCoder decodeBoolForKey:CPScrollViewHasHScrollerKey];
        _autohidesScrollers     = [aCoder decodeBoolForKey:CPScrollViewAutohidesScrollerKey];

        _borderType             = [aCoder decodeIntForKey:CPScrollViewBorderTypeKey];

        _cornerView             = [aCoder decodeObjectForKey:CPScrollViewCornerViewKey];
        _bottomCornerView       = [aCoder decodeObjectForKey:CPScrollViewBottomCornerViewKey];

        _delegate = nil;
        _scrollTimer = nil;
        _implementedDelegateMethods = 0;

        // Due to the anything goes nature of decoding, our subviews may not exist yet, so layout at the end of the run loop when we're sure everything is in a correct state.
        [[CPRunLoop currentRunLoop] performSelector:@selector(_updateCornerAndHeaderView) target:self argument:_contentView order:0 modes:[CPDefaultRunLoopMode]];

        [self setScrollerStyle:[aCoder decodeIntForKey:CPScrollViewScrollerStyleKey] || CPScrollerStyleGlobal];
        [self setScrollerKnobStyle:[aCoder decodeIntForKey:CPScrollViewScrollerKnobStyleKey] || CPScrollerKnobStyleDefault];

        [[CPNotificationCenter defaultCenter] addObserver:self
                                 selector:@selector(_didReceiveDefaultStyleChange:)
                                     name:CPScrollerStyleGlobalChangeNotification
                                   object:nil];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_contentView           forKey:CPScrollViewContentViewKey];
    [aCoder encodeObject:_headerClipView        forKey:CPScrollViewHeaderClipViewKey];

    [aCoder encodeObject:_verticalScroller      forKey:CPScrollViewVScrollerKey];
    [aCoder encodeObject:_horizontalScroller    forKey:CPScrollViewHScrollerKey];

    [aCoder encodeFloat:_verticalLineScroll     forKey:CPScrollViewVLineScrollKey];
    [aCoder encodeFloat:_verticalPageScroll     forKey:CPScrollViewVPageScrollKey];
    [aCoder encodeFloat:_horizontalLineScroll   forKey:CPScrollViewHLineScrollKey];
    [aCoder encodeFloat:_horizontalPageScroll   forKey:CPScrollViewHPageScrollKey];

    [aCoder encodeBool:_hasVerticalScroller     forKey:CPScrollViewHasVScrollerKey];
    [aCoder encodeBool:_hasHorizontalScroller   forKey:CPScrollViewHasHScrollerKey];
    [aCoder encodeBool:_autohidesScrollers      forKey:CPScrollViewAutohidesScrollerKey];

    [aCoder encodeObject:_cornerView            forKey:CPScrollViewCornerViewKey];
    [aCoder encodeObject:_bottomCornerView      forKey:CPScrollViewBottomCornerViewKey];

    [aCoder encodeInt:_borderType               forKey:CPScrollViewBorderTypeKey];

    [aCoder encodeInt:_scrollerStyle            forKey:CPScrollViewScrollerStyleKey];
    [aCoder encodeInt:_scrollerKnobStyle        forKey:CPScrollViewScrollerKnobStyleKey];
}

@end
