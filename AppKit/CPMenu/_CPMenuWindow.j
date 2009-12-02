
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

    CPTimeInterval      _startTime;
    int                 _scrollingState;
    CGPoint             _lastGlobalLocation;

    Function            _trackingCallback;
    
    CGRect              _unconstrainedFrame;
    CGRect              _constraintRect;

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
    [menuWindow setMinWidth:[aMenu minimumWidth]];

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

- (id)initWithContentRect:(CGRect)aRect styleMask:(unsigned)aStyleMask
{
    _constraintRect = _CGRectMakeZero();
    _unconstrainedFrame = _CGRectMakeZero();

    self = [super initWithContentRect:aRect styleMask:CPBorderlessWindowMask];

    if (self)
    {
        [self setLevel:CPPopUpMenuWindowLevel];
        [self setHasShadow:YES];
        [self setShadowStyle:CPMenuWindowShadowStyle];
        [self setAcceptsMouseMovedEvents:YES];

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
    var size = [self unconstrainedFrame].size;

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
    [self setFrame:_unconstrainedFrame];
    
    [super orderFront:aSender];
}

- (void)setConstraintRect:(CGRect)aRect
{
    _constraintRect = aRect;

    [self setFrame:_unconstrainedFrame];
}

- (void)scrollUp
{
    if (CGRectGetMinY(_unconstrainedFrame) >= CGRectGetMinY(_constraintRect))
        return;

    _unconstrainedFrame.origin.y += 10;

    [self setFrame:_unconstrainedFrame];
}

- (void)scrollDown
{
    if (CGRectGetMaxY(_unconstrainedFrame) <= CGRectGetHeight(_constraintRect))
        return;

    _unconstrainedFrame.origin.y -= 10;

    [self setFrame:_unconstrainedFrame];
}

- (CGRect)unconstrainedFrame
{
    return _unconstrainedFrame;
}

// We need this because if not this will call setFrame: with -frame instead of -unconstrainedFrame, turning
// the constrained frame into the unconstrained frame.
- (void)setFrameOrigin:(CGPoint)aPoint
{
    [super setFrame:_CGRectMake(aPoint.x, aPoint.y, _CGRectGetWidth(_unconstrainedFrame), _CGRectGetHeight(_unconstrainedFrame))];
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrame:_CGRectMake(_CGRectGetMinX(_unconstrainedFrame), _CGRectGetMinY(_unconstrainedFrame), aSize.width, aSize.height)];
}

- (void)setFrame:(CGRect)aFrame display:(BOOL)shouldDisplay animate:(BOOL)shouldAnimate
{
    // FIXME: There are integral window issues with platform windows.
    // FIXME: This gets called far too often.
    _unconstrainedFrame = _CGRectMakeCopy(aFrame);

    var constrainedFrame = CGRectIntersection(_unconstrainedFrame, _constraintRect);

    // We don't want to simply intersect the visible frame and the unconstrained frame.
    // We should be allowing as much of the width to fit as possible (pushing back and forward).
    constrainedFrame.origin.x = CGRectGetMinX(_unconstrainedFrame);
    constrainedFrame.size.width = CGRectGetWidth(_unconstrainedFrame);

    if (CGRectGetWidth(constrainedFrame) > CGRectGetWidth(_constraintRect))
        constrainedFrame.size.width = CGRectGetWidth(_constraintRect);

    if (CGRectGetMaxX(constrainedFrame) > CGRectGetMaxX(_constraintRect))
        constrainedFrame.origin.x -= CGRectGetMaxX(constrainedFrame) - CGRectGetMaxX(_constraintRect);

    if (CGRectGetMinX(constrainedFrame) < CGRectGetMinX(_constraintRect))
        constrainedFrame.origin.x = CGRectGetMinX(_constraintRect);

    [super setFrame:constrainedFrame display:shouldDisplay animate:shouldAnimate];

    // This needs to happen before changing the frame.
    var menuViewOrigin = CGPointMake(CGRectGetMinX(aFrame) + LEFT_MARGIN, CGRectGetMinY(aFrame) + TOP_MARGIN),
        moreAbove = menuViewOrigin.y < CGRectGetMinY(constrainedFrame) + TOP_MARGIN,
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

- (void)beginTrackingWithEvent:(CPEvent)anEvent callback:(Function)aCallback
{
    CPApp._activeMenu = [self menu];

    _startTime = [anEvent timestamp];//new Date();
    _scrollingState = _CPMenuWindowScrollingStateNone;
    _menuWindowStack = [self];

    _trackingCallback = aCallback;
    
    // bleh
    [self setConstraintRect:CGRectInset([CPPlatform isBrowser] ? [[self platformWindow] contentBounds] : [[self screen] visibleFrame], 5.0, 5.0)];

    [self trackEvent:anEvent];
}

- (_CPMenuWindow)menuWindowForPoint:(float)aGlobalLocation
{
    var count = [_menuWindowStack count];

    // Trivial case.
    if (count === 1)
        return _menuWindowStack[0];

    var index = count,
        x = aGlobalLocation.x,
        closerDeltaX = Infinity,
        closerMenuWindow = nil;

    while (index--)
    {
        var menuWindow = _menuWindowStack[index],
            menuWindowFrame = [menuWindow frame],
            menuWindowMinX = _CGRectGetMinX(menuWindowFrame),
            menuWindowMaxX = _CGRectGetMaxX(menuWindowFrame);

        // If within the x bounds of this menu window, return it.
        if (x < menuWindowMaxX && x >= menuWindowMinX)
            return menuWindow;

        // If this is either the first or last menu, check to see how close we are to it.
        if (index === 0 || index === count - 1)
        {
            var deltaX = ABS(x < menuWindowMinX ? menuWindowMinX - x : menuWindowMaxX - x);

            if (deltaX < closerDeltaX)
            {
                closerMenuWindow = menuWindow;
                closerDeltaX = deltaX;
            }
        }
    }

    return closerMenuWindow;
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

    // Unhighlight any previously highlighted item.
    [newMenu _highlightItemAtIndex:CPNotFound];

    var menuWindow = [_CPMenuWindow menuWindowWithMenu:newMenu font:[self font]];

    _menuWindowStack.push(menuWindow);

    [menuWindow setConstraintRect:_constraintRect];
    [menuWindow setBackgroundStyle:_CPMenuWindowPopUpBackgroundStyle];
    [menuWindow setFrameOrigin:aGlobalLocation];
    [menuWindow orderFront:self];
}

- (void)trackEvent:(CPEvent)anEvent
{
    var type = [anEvent type],
        menu = [self menu];

    // Close Menu Event.
    if (type === CPAppKitDefined)
    {
        // Stop all periodic events at this point.
        [CPEvent stopPeriodicEvents];

        var highlightedItem = [menu highlightedItem];

        // Hide all submenus.
        [self showMenu:nil fromMenu:menu atPoint:nil];

        [self orderOut:self];
        [self setMenu:nil];

        var delegate = [menu delegate];

        if ([delegate respondsToSelector:@selector(menuDidClose:)])
            [delegate menuDidClose:menu];

        if (_trackingCallback)
            _trackingCallback(self, menu);

        [[CPNotificationCenter defaultCenter]
            postNotificationName:CPMenuDidEndTrackingNotification
                          object:menu];

        CPApp._activeMenu = nil;

        return;
    }

    [CPApp setTarget:self selector:@selector(trackEvent:) forNextEventMatchingMask:CPPeriodicMask | CPMouseMovedMask | CPLeftMouseDraggedMask | CPLeftMouseUpMask | CPAppKitDefinedMask untilDate:nil inMode:nil dequeue:YES];

    // Periodic events don't have a valid location.
    var globalLocation = type === CPPeriodic ? _lastGlobalLocation : [anEvent globalLocation];

    // Remember this for the next periodic event.
    _lastGlobalLocation = globalLocation;

    // Find which menu window the mouse is currently on top of
    var activeMenuWindow = [self menuWindowForPoint:globalLocation],
        menuLocation = [activeMenuWindow convertGlobalToBase:globalLocation],
        activeItemIndex = activeMenuWindow ? [activeMenuWindow itemIndexAtPoint:menuLocation] : CPNotFound,
        activeMenu = activeMenuWindow ? [activeMenuWindow menu] : nil,
        activeItem = activeMenuWindow ? [activeMenu itemAtIndex:activeItemIndex] : nil,
        mouseOverMenuView = activeMenuWindow ? [activeItem view] : nil;

    if (type === CPPeriodic)
    {
        if (_scrollingState === _CPMenuWindowScrollingStateUp)
            [activeMenuWindow scrollUp];

        else if (_scrollingState === _CPMenuWindowScrollingStateDown)
            [activeMenuWindow scrollDown];
    }

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
        
        [activeMenu _highlightItemAtIndex:activeItemIndex];
        
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

    // If the item has a submenu, show it.
    if ([activeItem hasSubmenu])// && [activeItem action] === @selector(submenuAction:))
    {
        var activeItemRect = [activeMenuWindow rectForItemAtIndex:activeItemIndex],
            newMenuOrigin = CGPointMake(CGRectGetMaxX(activeItemRect), CGRectGetMinY(activeItemRect));

        newMenuOrigin = [activeMenuWindow convertBaseToGlobal:newMenuOrigin];

        [self showMenu:[activeItem submenu] fromMenu:[activeItem menu] atPoint:newMenuOrigin];
    }

    // This handles both the case where we've moved away from the menu, and where 
    // we've moved to an item without a submenu.
    else
        [self showMenu:nil fromMenu:activeMenu atPoint:CGPointMakeZero()];
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
