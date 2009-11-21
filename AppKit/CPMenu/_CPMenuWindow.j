
#include "../CoreGraphics/CGGeometry.h"


var _CPMenuWindowPool                       = [],
    _CPMenuWindowPoolCapacity               = 5,
    
    _CPMenuWindowBackgroundColors           = [],
    
    _CPMenuWindowScrollingStateUp           = -1,
    _CPMenuWindowScrollingStateDown         = 1,
    _CPMenuWindowScrollingStateNone         = 0;
    
_CPMenuWindowMenuBarBackgroundStyle         = 0;
_CPMenuWindowPopUpBackgroundStyle           = 1;
_CPMenuWindowAttachedMenuBackgroundStyle    = 2;

var STICKY_TIME_INTERVAL        = 500,

    TOP_MARGIN                  = 5.0,
    LEFT_MARGIN                 = 1.0,
    RIGHT_MARGIN                = 1.0,
    BOTTOM_MARGIN               = 5.0,
    
    SCROLL_INDICATOR_HEIGHT     = 16.0;

/*
    @ignore
*/
@implementation _CPMenuWindow : CPWindow
{
    _CPMenuView         _menuView;
    CPClipView          _menuClipView;
    CPView              _lastMouseOverMenuView;
    
    CPImageView         _moreAboveView;
    CPImageView         _moreBelowView;
    
    id                  _sessionDelegate;
    SEL                 _didEndSelector;
    
    CPTimeInterval      _startTime;
    int                 _scrollingState;
    CGPoint             _lastGlobalLocation;
    CPMenu              _lastActiveMenu;
    
    BOOL                _isShowingTopScrollIndicator;
    BOOL                _isShowingBottomScrollIndicator;
    BOOL                _trackingCanceled;
    
    CGRect              _unconstrainedFrame;

    CPArray             _menuWindowStack;
}

+ (id)menuWindowWithMenu:(CPMenu)aMenu font:(CPFont)aFont
{
    var menuWindow = nil;

    if (_CPMenuWindowPool.length)
        menuWindow = _CPMenuWindowPool.pop();
    else
        menuWindow = [[_CPMenuWindow alloc] init];

    [menuWindow setFont:aFont];
    [menuWindow setMenu:aMenu];

    return menuWindow;
}

+ (void)poolMenuWindow:(_CPMenuWindow)aMenuWindow
{
    if (!aMenuWindow || _CPMenuWindowPool.length >= _CPMenuWindowPoolCapacity)
        return;

    _CPMenuWindowPool.push(aMenuWindow);
}

+ (void)initialize
{
    if (self != [_CPMenuWindow class])
        return;
    
    var bundle = [CPBundle bundleForClass:self];
    
    _CPMenuWindowMoreAboveImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowMoreAbove.png"] size:CGSizeMake(38.0, 18.0)];
    _CPMenuWindowMoreBelowImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowMoreBelow.png"] size:CGSizeMake(38.0, 18.0)];
}

- (id)init
{
    self = [super initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessWindowMask];
    
    if (self)
    {
        [self setLevel:CPPopUpMenuWindowLevel];
        [self setHasShadow:YES];
        [self setShadowStyle:CPMenuWindowShadowStyle];
        [self setAcceptsMouseMovedEvents:YES];
        
        _unconstrainedFrame = CGRectMakeZero();
        
        var contentView = [self contentView];
        
        _menuView = [[_CPMenuView alloc] initWithFrame:CGRectMakeZero()];
        
        _menuClipView = [[CPClipView alloc] initWithFrame:CGRectMake(LEFT_MARGIN, TOP_MARGIN, 0.0, 0.0)];
        [_menuClipView setDocumentView:_menuView];
        
        [contentView addSubview:_menuClipView];
        
        _moreAboveView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
        
        [_moreAboveView setImage:_CPMenuWindowMoreAboveImage];
        [_moreAboveView setFrameSize:[_CPMenuWindowMoreAboveImage size]];
        
        [contentView addSubview:_moreAboveView];
        
        _moreBelowView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
    
        [_moreBelowView setImage:_CPMenuWindowMoreBelowImage];
        [_moreBelowView setFrameSize:[_CPMenuWindowMoreBelowImage size]];
        
        [contentView addSubview:_moreBelowView];

        [self setShadowStyle:CPWindowShadowStyleMenu];
    }
    
    return self;
}

- (CGFloat)overlapOffsetWidth
{
    return LEFT_MARGIN;
}

- (void)setFont:(CPFont)aFont
{
    [_menuView setFont:aFont];
}

- (CPFont)font
{
    return [_menuView font];
}

+ (CPColor)backgroundColorForBackgroundStyle:(_CPMenuWindowBackgroundStyle)aBackgroundStyle
{
    var color = _CPMenuWindowBackgroundColors[aBackgroundStyle];
    
    if (!color)
    {
        var bundle = [CPBundle bundleForClass:[self class]];

        if (aBackgroundStyle == _CPMenuWindowPopUpBackgroundStyle)
            color = [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:
                [
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowRounded0.png"] size:CGSizeMake(4.0, 4.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow1.png"] size:CGSizeMake(1.0, 4.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowRounded2.png"] size:CGSizeMake(4.0, 4.0)],
                    
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow3.png"] size:CGSizeMake(4.0, 1.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow4.png"] size:CGSizeMake(1.0, 1.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow5.png"] size:CGSizeMake(4.0, 1.0)],
                    
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowRounded6.png"] size:CGSizeMake(4.0, 4.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow7.png"] size:CGSizeMake(1.0, 4.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowRounded8.png"] size:CGSizeMake(4.0, 4.0)]
                ]]];
        
        else if (aBackgroundStyle == _CPMenuWindowMenuBarBackgroundStyle)
            color = [CPColor colorWithPatternImage:[[CPNinePartImage alloc] initWithImageSlices:
                [
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow3.png"] size:CGSizeMake(4.0, 0.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow4.png"] size:CGSizeMake(1.0, 0.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow5.png"] size:CGSizeMake(4.0, 0.0)],
                    
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow3.png"] size:CGSizeMake(4.0, 1.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow4.png"] size:CGSizeMake(1.0, 1.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow5.png"] size:CGSizeMake(4.0, 1.0)],
                    
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowRounded6.png"] size:CGSizeMake(4.0, 4.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindow7.png"] size:CGSizeMake(1.0, 4.0)],
                    [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"_CPMenuWindow/_CPMenuWindowRounded8.png"] size:CGSizeMake(4.0, 4.0)]
                ]]];
                
        _CPMenuWindowBackgroundColors[aBackgroundStyle] = color;
    }

    return color;
}

- (void)setBackgroundStyle:(_CPMenuWindowBackgroundStyle)aBackgroundStyle
{
    [self setBackgroundColor:[[self class] backgroundColorForBackgroundStyle:aBackgroundStyle]];
}

- (void)setMenu:(CPMenu)aMenu
{
    [aMenu _setMenuWindow:self];
    [_menuView setMenu:aMenu];
    
    var menuViewSize = [_menuView frame].size;
    
    [self setFrameSize:CGSizeMake(LEFT_MARGIN + menuViewSize.width + RIGHT_MARGIN, TOP_MARGIN + menuViewSize.height + BOTTOM_MARGIN)];
    
    [_menuView scrollPoint:CGPointMake(0.0, 0.0)];
    [_menuClipView setFrame:CGRectMake(LEFT_MARGIN, TOP_MARGIN, menuViewSize.width, menuViewSize.height)];
}

- (void)setMinWidth:(float)aWidth
{
    var size = [self frame].size;
    
    [self setFrameSize:CGSizeMake(MAX(size.width, aWidth), size.height)];
}

- (CGPoint)rectForItemAtIndex:(int)anIndex
{
    return [_menuView convertRect:[_menuView rectForItemAtIndex:anIndex] toView:nil];
}

- (int)itemIndexAtPoint:(CGPoint)aPoint
{
    return [_menuView itemIndexAtPoint:[_menuView convertPoint:aPoint fromView:nil]];
}

- (CPMenu)menu
{
    return [_menuView menu];
}

- (void)orderFront:(id)aSender
{
    [self constrainToScreen];
    
    [super orderFront:aSender];
}

- (void)constrainToScreen
{
    // FIXME: There are integral window issues with platform windows.
    // FIXME: This gets called far too often.
    _unconstrainedFrame = CGRectMakeCopy([self frame]);

    var isBrowser = [CPPlatform isBrowser],
        visibleFrame =  CGRectInset(isBrowser ? [[self platformWindow] contentBounds] : [[self screen] visibleFrame], 5.0, 5.0),
        constrainedFrame = CGRectIntersection(_unconstrainedFrame, visibleFrame);

    // We don't want to simply intersect the visible frame and the unconstrained frame.
    // We should be allowing as much of the width to fit as possible (pushing back and forward).
    constrainedFrame.origin.x = CGRectGetMinX(_unconstrainedFrame);
    constrainedFrame.size.width = CGRectGetWidth(_unconstrainedFrame);

    if (CGRectGetWidth(constrainedFrame) > CGRectGetWidth(visibleFrame))
        constrainedFrame.size.width = CGRectGetWidth(visibleFrame);

    if (CGRectGetMaxX(constrainedFrame) > CGRectGetMaxX(visibleFrame))
        constrainedFrame.origin.x -= CGRectGetMaxX(constrainedFrame) - CGRectGetMaxX(visibleFrame);

    if (CGRectGetMinX(constrainedFrame) < CGRectGetMinX(visibleFrame))
        constrainedFrame.origin.x = CGRectGetMinX(visibleFrame);

    // This needs to happen before changing the frame.
    var menuViewOrigin = [self convertBaseToGlobal:CGPointMake(LEFT_MARGIN, TOP_MARGIN)];

    [super setFrame:constrainedFrame];

    var moreAbove = menuViewOrigin.y < CGRectGetMinY(constrainedFrame) + TOP_MARGIN,
        moreBelow = menuViewOrigin.y + CGRectGetHeight([_menuView frame]) > CGRectGetMaxY(constrainedFrame) - BOTTOM_MARGIN,

        topMargin = TOP_MARGIN,
        bottomMargin = BOTTOM_MARGIN,
        
        contentView = [self contentView],
        bounds = [contentView bounds];

    if (moreAbove)
    {
        topMargin += SCROLL_INDICATOR_HEIGHT;
    
        var frame = [_moreAboveView frame];
        
        [_moreAboveView setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - CGRectGetWidth(frame)) / 2.0, (TOP_MARGIN + SCROLL_INDICATOR_HEIGHT - CGRectGetHeight(frame)) / 2.0)];
    }

    [_moreAboveView setHidden:!moreAbove];

    if (moreBelow)
    {
        bottomMargin += SCROLL_INDICATOR_HEIGHT;
    
        [_moreBelowView setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - CGRectGetWidth([_moreBelowView frame])) / 2.0, CGRectGetHeight(bounds) - SCROLL_INDICATOR_HEIGHT - BOTTOM_MARGIN)];
    }
    
    [_moreBelowView setHidden:!moreBelow];

    var clipFrame = CGRectMake(LEFT_MARGIN, topMargin, CGRectGetWidth(constrainedFrame) - LEFT_MARGIN - RIGHT_MARGIN, CGRectGetHeight(constrainedFrame) - topMargin - bottomMargin)

    [_menuClipView setFrame:clipFrame];
    [_menuView setFrameSize:CGSizeMake(CGRectGetWidth(clipFrame), CGRectGetHeight([_menuView frame]))];

    [_menuView scrollPoint:CGPointMake(0.0, [self convertBaseToGlobal:clipFrame.origin].y - menuViewOrigin.y)];
}

- (void)beginTrackingWithEvent:(CPEvent)anEvent sessionDelegate:(id)aSessionDelegate didEndSelector:(SEL)aDidEndSelector
{
    CPApp._activeMenu = [_menuView menu];

    _startTime = [anEvent timestamp];//new Date();
    _scrollingState = _CPMenuWindowScrollingStateNone;
    _trackingCanceled = NO;
    _menuWindowStack = [self];
    
    _sessionDelegate = aSessionDelegate;
    _didEndSelector = aDidEndSelector;
    
    [self trackEvent:anEvent];
}

- (_CPMenuWindow)menuWindowAtPoint:(CGPoint)aGlobalLocation
{
    var count = _menuWindowStack.length;

    while (count--)
    {
        var menuWindow = _menuWindowStack[count];

        if (CGRectContainsPoint([menuWindow frame], aGlobalLocation))
            return menuWindow;
    }

    return nil;
}

- (void)showMenu:(CPMenu)newMenu fromMenu:(CPMenu)baseMenu atPoint:(CGPoint)aGlobalLocation
{
    var count = _menuWindowStack.length,
        index = count;

    // Hide all menus up to the base menu...
    while (index--)
    {
        var menuWindow = _menuWindowStack[index];

        if ([menuWindow menu] === baseMenu)
            break;

        [[menuWindow menu] _highlightItemAtIndex:CPNotFound];

        [menuWindow orderOut:self];
        [menuWindow setMenu:nil];

        [_CPMenuWindow poolMenuWindow:menuWindow];
        [_menuWindowStack removeObjectAtIndex:index];
    }

    if (!newMenu)
        return;

    var menuWindow = [_CPMenuWindow menuWindowWithMenu:newMenu font:[self font]];

    _menuWindowStack.push(menuWindow);

    [menuWindow setBackgroundStyle:_CPMenuWindowPopUpBackgroundStyle];
    [menuWindow setFrameOrigin:aGlobalLocation];
    [menuWindow orderFront:self];
}

- (void)trackEvent:(CPEvent)anEvent
{
    var type = [anEvent type],
        menu = [_menuView menu];

    // Close Menu Event.
    if (type === CPAppKitDefined)
    {
        // Stop all periodic events at this point.
        [CPEvent stopPeriodicEvents];

        var highlightedItem = [[_menuView menu] highlightedItem];

        // Hide all submenus.
        [self showMenu:nil fromMenu:menu atPoint:nil];

        [self orderOut:self];
        [self setMenu:nil];

        var delegate = [menu delegate];

        if ([delegate respondsToSelector:@selector(menuDidClose:)])
            [delegate menuDidClose:menu];

        if (_sessionDelegate && _didEndSelector)
            objj_msgSend(_sessionDelegate, _didEndSelector, self, highlightedItem);

        [[CPNotificationCenter defaultCenter]
            postNotificationName:CPMenuDidEndTrackingNotification
                          object:menu];

        CPApp._activeMenu = nil;

        return;
    }

    [CPApp setTarget:self selector:@selector(trackEvent:) forNextEventMatchingMask:CPPeriodicMask | CPMouseMovedMask | CPLeftMouseDraggedMask | CPLeftMouseUpMask | CPAppKitDefinedMask untilDate:nil inMode:nil dequeue:YES];

    var theWindow = [anEvent window],
        globalLocation = [anEvent locationInWindow];

    if (theWindow)
        globalLocation = [theWindow convertBaseToGlobal:globalLocation];

    if (type === CPPeriodic)
    {
        var constrainedBounds =  CGRectInset([CPPlatform isBrowser] ? [[self platformWindow] contentBounds] : [[self screen] visibleFrame], 5.0, 5.0);
        
        if (_scrollingState == _CPMenuWindowScrollingStateUp)
        {
            if (CGRectGetMinY(_unconstrainedFrame) < CGRectGetMinY(constrainedBounds))
                _unconstrainedFrame.origin.y += 10;
        }
        else if (_scrollingState == _CPMenuWindowScrollingStateDown)
            if (CGRectGetMaxY(_unconstrainedFrame) > CGRectGetHeight(constrainedBounds))
                _unconstrainedFrame.origin.y -= 10;
                
        [self setFrame:_unconstrainedFrame];
        [self constrainToScreen];
        
        globalLocation = _lastGlobalLocation;
    }

    _lastGlobalLocation = globalLocation;

    // Find which menu window the mouse is currently on top of
    var activeMenuWindow = [self menuWindowAtPoint:globalLocation];

    if (activeMenuWindow)
    {
        var menuLocation = [activeMenuWindow convertGlobalToBase:globalLocation],
            activeItemIndex = [activeMenuWindow itemIndexAtPoint:menuLocation],
            activeMenu = [activeMenuWindow menu],
            activeItem = [activeMenu itemAtIndex:activeItemIndex],
            mouseOverMenuView = [activeItem view];
    }
    else
    {
        var activeMenuItemIndex = CPNotFound,
            activeMenu = nil,
            activeItem = nil,
            mouseOverMenuView = nil;
    }
    
    _lastActiveMenu = activeMenu || _lastActiveMenu;

    // If we're over a custom menu view...
    if (mouseOverMenuView)
    {
        if (!_lastMouseOverMenuView)
            [menu _highlightItemAtIndex:CPNotFound];
        
        if (_lastMouseOverMenuView != mouseOverMenuView)
        {
            [mouseOverMenuView mouseExited:anEvent];
            // FIXME: Possibly multiple of these?
            [_lastMouseOverMenuView mouseEntered:anEvent];
            
            _lastMouseOverMenuView = mouseOverMenuView;
        }
        
        [self sendEvent:[CPEvent mouseEventWithType:type location:menuLocation modifierFlags:[anEvent modifierFlags] 
            timestamp:[anEvent timestamp] windowNumber:[self windowNumber] context:nil 
            eventNumber:0 clickCount:[anEvent clickCount] pressure:[anEvent pressure]]];
    }
    else
    {
        if (_lastMouseOverMenuView)
        {
            [_lastMouseOverMenuView mouseExited:anEvent];
            _lastMouseOverMenuView = nil;
        }
        
        [_lastActiveMenu _highlightItemAtIndex:activeItemIndex];
        
        if (type === CPMouseMoved || type === CPLeftMouseDragged || type === CPLeftMouseDown)
        {
            var frame = [self frame],
                oldScrollingState = _scrollingState;
            
            _scrollingState = _CPMenuWindowScrollingStateNone;
            
            // If we're at or above of the top scroll indicator...
            if (globalLocation.y < CGRectGetMinY(frame) + TOP_MARGIN + SCROLL_INDICATOR_HEIGHT)
                _scrollingState = _CPMenuWindowScrollingStateUp;
        
            // If we're at or below the bottom scroll indicator...
            else if (globalLocation.y > CGRectGetMaxY(frame) - BOTTOM_MARGIN - SCROLL_INDICATOR_HEIGHT)
                _scrollingState = _CPMenuWindowScrollingStateDown;
            
            if (_scrollingState != oldScrollingState)
            
                if (_scrollingState == _CPMenuWindowScrollingStateNone)
                    [CPEvent stopPeriodicEvents];
            
                else if (oldScrollingState == _CPMenuWindowScrollingStateNone)
                    [CPEvent startPeriodicEventsAfterDelay:0.0 withPeriod:0.04];
        }
        else if (type === CPLeftMouseUp && ([anEvent timestamp] - _startTime > STICKY_TIME_INTERVAL))
            [menu cancelTracking];
    }

    if (activeItem)
        if ([activeItem hasSubmenu])// && [activeItem action] === @selector(submenuAction:))
        {
            var activeItemRect = [activeMenuWindow rectForItemAtIndex:activeItemIndex],
                newMenuOrigin = CGPointMake(CGRectGetMaxX(activeItemRect), CGRectGetMinY(activeItemRect));
    
            newMenuOrigin = [activeMenuWindow convertBaseToGlobal:newMenuOrigin];
    
            [self showMenu:[activeItem submenu] fromMenu:[activeItem menu] atPoint:newMenuOrigin];
        }
        else
            [self showMenu:nil fromMenu:[activeItem menu] atPoint:CGPointMakeZero()];
}

@end

/*
    @ignore
*/

@implementation _CPMenuView : CPView
{
    CPArray _menuItemViews;
    CPArray _visibleMenuItemInfos;
    
    CPFont  _font @accessors(property=font);
}

- (CGRect)rectForItemAtIndex:(int)anIndex
{
    return [_menuItemViews[anIndex === CPNotFound ? 0 : anIndex] frame];
}

- (int)itemIndexAtPoint:(CGPoint)aPoint
{
    var x = aPoint.x,
        bounds = [self bounds];

    if (x < CGRectGetMinX(bounds) || x > CGRectGetMaxX(bounds))
        return CPNotFound;

    var y = aPoint.y,
        low = 0,
        high = _visibleMenuItemInfos.length - 1;

    while (low <= high)
    {
        var middle = FLOOR(low + (high - low) / 2),
            info = _visibleMenuItemInfos[middle]
            frame = [info.view frame];

        if (y < CGRectGetMinY(frame))
            high = middle - 1;

        else if (y > CGRectGetMaxY(frame))
            low = middle + 1;

        else
            return info.index;
   }

   return CPNotFound;
}

- (void)tile
{
    [_menuItemViews makeObjectsPerformSelector:@selector(removeFromSuperview)];   

    _menuItemViews = [];
    _visibleMenuItemInfos = [];

    var menu = [self menu];

    if (!menu)
        return;

    var items = [menu itemArray],
        index = 0,
        count = [items count],
        maxWidth = 0,
        y = 0,
        showsStateColumn = [menu showsStateColumn];

    for (; index < count; ++index)
    {
        var item = items[index],
            view = [item _menuItemView];        
        
        _menuItemViews.push(view);
        
        if ([item isHidden])
            continue;

        _visibleMenuItemInfos.push({ view:view, index:index });
        
        [view setFont:_font];
        [view setShowsStateColumn:showsStateColumn];
        [view synchronizeWithMenuItem];

        [view setFrameOrigin:CGPointMake(0.0, y)];

        [self addSubview:view];

        var size = [view minSize],
            width = size.width;

        if (maxWidth < width)
            maxWidth = width;

        y += size.height;
    }

    for (index = 0; index < count; ++index)
    {
        var view = _menuItemViews[index];

        [view setFrameSize:CGSizeMake(maxWidth, CGRectGetHeight([view frame]))];
    }

    [self setAutoresizesSubviews:NO];
    [self setFrameSize:CGSizeMake(maxWidth, y)];
    [self setAutoresizesSubviews:YES];
}

- (void)setMenu:(CPMenu)aMenu
{
    [super setMenu:aMenu];
    [self tile];
}

@end
