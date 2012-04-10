@import <Foundation/CPObject.j>


_CPMenuManagerScrollingStateUp      = -1;
_CPMenuManagerScrollingStateDown    = 1;
_CPMenuManagerScrollingStateNone    = 0;

var STICKY_TIME_INTERVAL            = 500,
    SharedMenuManager               = nil;

@implementation _CPMenuManager: CPObject
{
    CPTimeInterval      _startTime;
    BOOL                _mouseWasDragged;
    int                 _scrollingState;
    CGPoint             _lastGlobalLocation;

    CPView              _lastMouseOverMenuView;

    CGRect              _constraintRect;
    CPMutableArray      _menuContainerStack;

    Function            _trackingCallback;

    CPString            _keyBuffer;

    CPMenuItem          _previousActiveItem;
    int                 _showTimerID;
}

+ (_CPMenuManager)sharedMenuManager
{
    if (!SharedMenuManager)
        SharedMenuManager = [[_CPMenuManager alloc] init];

    return SharedMenuManager;
}

- (id)init
{
    if (SharedMenuManager)
        return SharedMenuManager;

    return [super init];
}

- (id)trackingMenuContainer
{
    return _menuContainerStack[0];
}

- (CPMenu)trackingMenu
{
    return [[self trackingMenuContainer] menu];
}

- (void)beginTracking:(CPEvent)anEvent
        menuContainer:(id)aMenuContainer
       constraintRect:(CGRect)aRect
             callback:(Function)aCallback
{
    var menu = [aMenuContainer menu];

    if ([menu numberOfItems] <= 0)
        return;

    CPApp._activeMenu = menu;

    _startTime = [anEvent timestamp];
    _scrollingState = _CPMenuManagerScrollingStateNone;

    _constraintRect = aRect;
    _menuContainerStack = [aMenuContainer];
    _trackingCallback = aCallback;

    if (menu === [CPApp mainMenu])
    {
        var globalLocation = [anEvent globalLocation],

            // Find which menu window the mouse is currently on top of
            menuLocation = [aMenuContainer convertGlobalToBase:globalLocation],

            // Find out the item the mouse is currently on top of
            activeItemIndex = [aMenuContainer itemIndexAtPoint:menuLocation],
            activeItem = activeItemIndex !== CPNotFound ? [menu itemAtIndex:activeItemIndex] : nil;

        _menuBarButtonItemIndex = activeItemIndex;
        _menuBarButtonMenuContainer = aMenuContainer;

        if ([activeItem _isMenuBarButton])
            return [self trackMenuBarButtonEvent:anEvent];
    }

    _mouseWasDragged = NO;

    [self trackEvent:anEvent];
}

- (void)trackEvent:(CPEvent)anEvent
{
    var type = [anEvent type],
        trackingMenu = [self trackingMenu];

    // Close Menu Event.
    if (type === CPAppKitDefined)
        return [self completeTracking];

    [CPApp setTarget:self selector:@selector(trackEvent:) forNextEventMatchingMask:CPKeyDownMask | CPPeriodicMask | CPMouseMovedMask | CPLeftMouseDraggedMask | CPLeftMouseUpMask | CPRightMouseUpMask | CPAppKitDefinedMask | CPScrollWheelMask untilDate:nil inMode:nil dequeue:YES];

    if (type === CPKeyDown)
    {
        var menu = trackingMenu,
            submenu = [[menu  highlightedItem] submenu];

        // get the current active menu
        while (submenu && [submenu._menuWindow isVisible])
        {
            menu = submenu;
            submenu = [[menu  highlightedItem] submenu];
        }

        if ([menu numberOfItems])
            [self interpretKeyEvent:anEvent forMenu:menu];

        return;
    }

    if (_keyBuffer)
    {
        if (([CPDate date] - _startTime) > (STICKY_TIME_INTERVAL + [activeMenu numberOfItems] / 2))
            [self selectNextItemBeginningWith:_keyBuffer inMenu:menu clearBuffer:YES];

        if (type === CPPeriodic)
            return;
    }

    // Periodic events don't have a valid location.
    var globalLocation = type === CPPeriodic ? _lastGlobalLocation : [anEvent globalLocation];

    // Remember this for the next periodic event.
    _lastGlobalLocation = globalLocation;

    if (!_lastGlobalLocation)
        return;

    // Find which menu window the mouse is currently on top of
    var activeMenuContainer = [self menuContainerForPoint:globalLocation],
        activeMenu = [activeMenuContainer menu],
        menuLocation = [activeMenuContainer convertGlobalToBase:globalLocation],

        // Find out the item the mouse is currently on top of
        activeItemIndex = activeMenuContainer ? [activeMenuContainer itemIndexAtPoint:menuLocation] : CPNotFound,
        activeItem = activeItemIndex !== CPNotFound ? [activeMenu itemAtIndex:activeItemIndex] : nil;

    // If the item isn't enabled its as if we clicked on nothing.
    if (![activeItem isEnabled] || [activeItem _isMenuBarButton])
    {
        activeItemIndex = CPNotFound;
        activeItem = nil;
    }

    var mouseOverMenuView = [activeItem view];

    if (type === CPScrollWheel)
        [activeMenuContainer scrollByDelta:[anEvent deltaY]];

    if (type === CPPeriodic)
    {
        if (_scrollingState === _CPMenuManagerScrollingStateUp)
            [activeMenuContainer scrollUp];
        else if (_scrollingState === _CPMenuManagerScrollingStateDown)
            [activeMenuContainer scrollDown];
    }

    // If we're over a custom menu view...
    if (mouseOverMenuView)
    {
        if (!_lastMouseOverMenuView)
            [activeMenu _highlightItemAtIndex:CPNotFound];

        if (_lastMouseOverMenuView != mouseOverMenuView)
        {
            [mouseOverMenuView mouseExited:anEvent];
            // FIXME: Possibly multiple of these?
            [_lastMouseOverMenuView mouseEntered:anEvent];

            _lastMouseOverMenuView = mouseOverMenuView;
        }

        var menuContainerWindow = activeMenuContainer;

        if (![menuContainerWindow isKindOfClass:CPWindow])
            menuContainerWindow = [menuContainerWindow window];

        [menuContainerWindow
            sendEvent:[CPEvent mouseEventWithType:type
                                         location:menuLocation
                                    modifierFlags:[anEvent modifierFlags]
                                        timestamp:[anEvent timestamp]
                                     windowNumber:menuContainerWindow
                                          context:nil
                                      eventNumber:0
                                       clickCount:[anEvent clickCount]
                                         pressure:[anEvent pressure]]];
    }
    else
    {
        if (_lastMouseOverMenuView)
        {
            [_lastMouseOverMenuView mouseExited:anEvent];
            _lastMouseOverMenuView = nil;
        }

        [activeMenu _highlightItemAtIndex:activeItemIndex];

        if (type === CPMouseMoved || type === CPLeftMouseDragged || type === CPLeftMouseDown || type === CPPeriodic)
        {
            if (type === CPLeftMouseDragged)
                _mouseWasDragged = YES;

            var oldScrollingState = _scrollingState;

            _scrollingState = [activeMenuContainer scrollingStateForPoint:globalLocation];

            if (_scrollingState !== oldScrollingState)
            {
                if (_scrollingState === _CPMenuManagerScrollingStateNone)
                    [CPEvent stopPeriodicEvents];
                else if (oldScrollingState === _CPMenuManagerScrollingStateNone)
                    [CPEvent startPeriodicEventsAfterDelay:0.0 withPeriod:0.04];
            }
        }
        else if (type === CPLeftMouseUp || type === CPRightMouseUp)
        {
            /*
                There are a few possibilites:

                1. The user clicks and releases without dragging within the sticky time.
                   This is considered a regular mouse click and not a drag. In this case
                   we allow the user to track the menu by moving the mouse. The next
                   mouse up will end tracking.

                2. The user clicks and releases without dragging after the sticky time.
                   This is considered a drag and release and tracking ends.

                3. The user clicks, drags and then releases. Tracking ends.
            */
            if (_mouseWasDragged || [anEvent timestamp] - _startTime > STICKY_TIME_INTERVAL)
            {
                /*
                    Close the menu if:

                    1. The mouse was dragged.
                    2. The mouse is released in the menubar.
                    3. The current item has a submenu with a custom action.
                */
                if (_mouseWasDragged ||
                    [activeMenuContainer isMenuBar] ||
                    [activeItem action] !== @selector(submenuAction:))
                {
                    [trackingMenu cancelTracking];
                }
            }
        }
    }

    // Prevent previous selected menu items from opening by stopping the timer if a
    // new item is selected before the timer runs out
    if (_previousActiveItem !== activeItem)
    {
        clearTimeout(_showTimerID);
        _showTimerID = undefined;
    }

    // If the item has a submenu, show it.
    if ([activeItem hasSubmenu]) // && [activeItem action] === @selector(submenuAction:))
    {
        var activeItemRect = [activeMenuContainer rectForItemAtIndex:activeItemIndex],
            newMenuOrigin;

        if ([activeMenuContainer isMenuBar])
            newMenuOrigin = CGPointMake(CGRectGetMinX(activeItemRect), CGRectGetMaxY(activeItemRect));
        else
            newMenuOrigin = CGPointMake(CGRectGetMaxX(activeItemRect), CGRectGetMinY(activeItemRect));

        newMenuOrigin = [activeMenuContainer convertBaseToGlobal:newMenuOrigin];

        // Only start a new timer if the previous was cancelled
        if (_showTimerID === undefined)
        {
            // Close the current menu item because we are going to select a new one after a short delay
            [self showMenu:nil fromMenu:activeMenu atPoint:CGPointMakeZero()];

            if (![activeMenuContainer isMenuBar])
            {
                _showTimerID = setTimeout(function()
                {
                    [self showMenu:[activeItem submenu] fromMenu:[activeItem menu] atPoint:newMenuOrigin];
                }, 250);
            }
            else
                [self showMenu:[activeItem submenu] fromMenu:[activeItem menu] atPoint:newMenuOrigin];
        }
    }

    // This handles both the case where we've moved away from the menu, and where
    // we've moved to an item without a submenu.
    else
        [self showMenu:nil fromMenu:activeMenu atPoint:CGPointMakeZero()];

    _previousActiveItem = activeItem;
}

- (void)trackMenuBarButtonEvent:(CPEvent)anEvent
{
    var type = [anEvent type];

    if (type === CPAppKitDefined)
        return [self completeTracking];

    var globalLocation = [anEvent globalLocation],

        // Find which menu window the mouse is currently on top of
        menu = [self trackingMenu],
        trackingMenuContainer = [self trackingMenuContainer],
        menuLocation = [trackingMenuContainer convertGlobalToBase:globalLocation];

    if ([trackingMenuContainer itemIndexAtPoint:menuLocation] === _menuBarButtonItemIndex)
        [menu _highlightItemAtIndex:_menuBarButtonItemIndex];
    else
        [menu _highlightItemAtIndex:CPNotFound];

    [CPApp setTarget:self selector:@selector(trackMenuBarButtonEvent:) forNextEventMatchingMask:CPPeriodicMask | CPMouseMovedMask | CPLeftMouseDraggedMask | CPLeftMouseUpMask | CPAppKitDefinedMask untilDate:nil inMode:nil dequeue:YES];

    if (type === CPLeftMouseUp)
        [menu cancelTracking];
}

- (void)completeTracking
{
    var trackingMenu = [self trackingMenu];

    // Stop all periodic events at this point.
    [CPEvent stopPeriodicEvents];

    // Hide all submenus.
    [self showMenu:nil fromMenu:trackingMenu atPoint:nil];
    [trackingMenu _menuDidClose];

    if (_trackingCallback)
        _trackingCallback([self trackingMenuContainer], trackingMenu);

    [[CPNotificationCenter defaultCenter] postNotificationName:CPMenuDidEndTrackingNotification
                                                        object:trackingMenu];

    CPApp._activeMenu = nil;
}

- (id)menuContainerForPoint:(float)aGlobalLocation
{
    var count = [_menuContainerStack count],
        firstMenuContainer = _menuContainerStack[0];

    // Trivial case.
    if (count === 1)
        return firstMenuContainer;

    var firstMenuWindowIndex = 0,
        lastMenuWindowIndex = count - 1;

    // If the first menu container is a bar, then it has to fall strictly within its bounds.
    if ([firstMenuContainer isMenuBar])
    {
        if (CGRectContainsPoint([firstMenuContainer globalFrame], aGlobalLocation))
            return firstMenuContainer;

        firstMenuWindowIndex = 1;
    }

    var index = count,
        x = aGlobalLocation.x,
        closerDeltaX = Infinity,
        closerMenuContainer = nil;

    while (index-- > firstMenuWindowIndex)
    {
        var menuContainer = _menuContainerStack[index],
            menuContainerFrame = [menuContainer globalFrame],
            menuContainerMinX = _CGRectGetMinX(menuContainerFrame),
            menuContainerMaxX = _CGRectGetMaxX(menuContainerFrame);

        // If within the x bounds of this menu container, return it.
        if (x < menuContainerMaxX && x >= menuContainerMinX)
            return menuContainer;

        // If this is either the first or last menu *window*, check to see how close we are to it.
        if (index === firstMenuWindowIndex || index === lastMenuWindowIndex)
        {
            var deltaX = ABS(x < menuContainerMinX ? menuContainerMinX - x : menuContainerMaxX - x);

            if (deltaX < closerDeltaX)
            {
                closerMenuContainer = menuContainer;
                closerDeltaX = deltaX;
            }
        }
    }

    return closerMenuContainer;
}

- (void)showMenu:(CPMenu)newMenu fromMenu:(CPMenu)baseMenu atPoint:(CGPoint)aGlobalLocation
{
    var count = _menuContainerStack.length,
        index = count;

    [newMenu _menuWillOpen];

    // Hide all menus up to the base menu...
    while (index--)
    {
        var menuContainer = _menuContainerStack[index],
            menu = [menuContainer menu];

        // If we reach the base menu, or this menu is already being shown, break.
        if (menu === baseMenu)
            break;

        // If this menu is already being shown, unhighlight and return.
        if (menu === newMenu) //&& [menu supermenu] === baseMenu)
            return [newMenu _highlightItemAtIndex:CPNotFound];

        [menuContainer orderOut:self];
        [menuContainer setMenu:nil];

        [_CPMenuWindow poolMenuWindow:menuContainer];
        [_menuContainerStack removeObjectAtIndex:index];

        [menu _menuDidClose];
    }

    if (!newMenu)
        return;

    // Unhighlight any previously highlighted item.
    [newMenu _highlightItemAtIndex:CPNotFound];

    var menuWindow = [_CPMenuWindow menuWindowWithMenu:newMenu font:[_menuContainerStack[0] font]];

    [_menuContainerStack addObject:menuWindow];

    [menuWindow setConstraintRect:_constraintRect];

    // If our parent menu is a menu bar...
    if (baseMenu === [self trackingMenu] && [[self trackingMenuContainer] isMenuBar])
        [menuWindow setBackgroundStyle:_CPMenuWindowMenuBarBackgroundStyle];
    else
        [menuWindow setBackgroundStyle:_CPMenuWindowPopUpBackgroundStyle];

    [menuWindow setFrameOrigin:aGlobalLocation];
    [menuWindow orderFront:self];
}

/// handle keyboard navigation
- (void)interpretKeyEvent:(CPEvent)anEvent forMenu:(CPMenu)menu
{
    var modifierFlags = [anEvent modifierFlags],
        character = [anEvent charactersIgnoringModifiers],
        selectorNames = [CPKeyBinding selectorsForKey:character modifierFlags:modifierFlags];

    if (selectorNames)
    {
        var iter = [selectorNames objectEnumerator],
            obj;

        while ((obj = [iter nextObject]) !== nil)
        {
            var aSelector = CPSelectorFromString(obj);

            if ([self respondsToSelector:aSelector])
                [self performSelector:aSelector withObject:menu];
        }
    }
    else if (!(modifierFlags & (CPCommandKeyMask | CPControlKeyMask)))
    {
        if (!_keyBuffer)
        {
            _startTime = [CPDate date];
            _keyBuffer = character;

            [CPEvent stopPeriodicEvents];
            [CPEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
        }
        else
            _keyBuffer += character;

        [self selectNextItemBeginningWith:_keyBuffer inMenu:menu clearBuffer:NO];
        _lastGlobalLocation = Nil;
    }
}

- (void)selectNextItemBeginningWith:(CPString)characters inMenu:(CPMenu)menu clearBuffer:(BOOL)shouldClear
{
    var iter = [[menu itemArray] objectEnumerator],
        obj;

    while ((obj = [iter nextObject]) !== nil)
    {
        if ([obj isHidden] || ![obj isEnabled])
            continue;

        if ([[[obj title] commonPrefixWithString:characters options:CPCaseInsensitiveSearch] length] == [characters length])
        {
            [menu _highlightItemAtIndex:iter._index];
            break;
        }
    }

    if (shouldClear)
    {
        [CPEvent stopPeriodicEvents];
        _keyBuffer = Nil;
    }
    else
        _startTime = [CPDate date];
}

- (void)scrollToBeginningOfDocument:(CPMenu)menu
{
    [menu _highlightItemAtIndex:0];
}

- (void)scrollToEndOfDocument:(CPMenu)menu
{
    [menu _highlightItemAtIndex:[menu numberOfItems] - 1];
}

- (void)scrollPageDown:(CPMenu)menu
{
    var menuWindow = menu._menuWindow,
        menuClipView = menuWindow._menuClipView,
        bottom = [menuClipView bounds].size.height,
        first = [menuWindow itemIndexAtPoint:CGPointMake(1, 10)],
        last = [menuWindow itemIndexAtPoint:CGPointMake(1, bottom)],
        current = [menu indexOfItem:[menu highlightedItem]];

    if (current == CPNotFound)
    {
        [menu _highlightItemAtIndex:0];
        return;
    }

    next = current + (last - first);

    if (next < [menu numberOfItems])
        [menu _highlightItemAtIndex:next];
    else
        [menu _highlightItemAtIndex:[menu numberOfItems] - 1];

    var item = [menu highlightedItem];

    if ([item isSeparatorItem] || [item isHidden] || ![item isEnabled])
        [self moveDown:menu];
}

- (void)scrollPageUp:(CPMenu)menu
{
    var menuWindow = menu._menuWindow,
        menuClipView = menuWindow._menuClipView,
        bottom = [menuClipView bounds].size.height,
        first = [menuWindow itemIndexAtPoint:CGPointMake(1, 10)],
        last = [menuWindow itemIndexAtPoint:CGPointMake(1, bottom)],
        current = [menu indexOfItem:[menu highlightedItem]];

    if (current == CPNotFound)
    {
        [menu _highlightItemAtIndex:0];
        return;
    }

    next = current - (last - first);

    if (next < 0)
        [menu _highlightItemAtIndex:0];
    else
        [menu _highlightItemAtIndex:next];

    var item = [menu highlightedItem];

    if ([item isSeparatorItem] || [item isHidden] || ![item isEnabled])
        [self moveUp:menu];
}

- (void)moveLeft:(CPMenu)menu
{
    if ([menu supermenu])
    {
        if ([menu supermenu] == [CPApp mainMenu])
        {
            [self showMenu:nil fromMenu:[menu supermenu] atPoint:CGPointMakeZero()];
            [self moveUp:[CPApp mainMenu]];

            var activeItem = [[CPApp mainMenu] highlightedItem],
                menuLocation = CGPointMake([[activeItem _menuItemView] frameOrigin].x , [[activeItem _menuItemView] frameSize].height);

            [self showMenu:[activeItem submenu] fromMenu:[activeItem menu] atPoint:menuLocation];
        }
        else
            [self showMenu:nil fromMenu:[menu supermenu] atPoint:CGPointMakeZero()];
    }
}

- (void)moveRight:(CPMenu)menu
{
    var activeItem = [menu highlightedItem];

    if ([activeItem hasSubmenu])
    {
        if ([[activeItem submenu] numberOfItems])
        {
            var activeItemIndex = [menu indexOfItem:activeItem],
                activeMenuContainer = menu._menuWindow,
                activeItemRect = [activeMenuContainer rectForItemAtIndex:activeItemIndex],
                newMenuOrigin;

            if ([activeMenuContainer isMenuBar])
                newMenuOrigin = CGPointMake(CGRectGetMinX(activeItemRect), CGRectGetMaxY(activeItemRect));
            else
                newMenuOrigin = CGPointMake(CGRectGetMaxX(activeItemRect), CGRectGetMinY(activeItemRect));

            newMenuOrigin = [activeMenuContainer convertBaseToGlobal:newMenuOrigin];

            [self showMenu:[activeItem submenu] fromMenu:[activeItem menu] atPoint:newMenuOrigin];
            [self moveDown:[activeItem submenu]];
        }
    }
    else if ([self trackingMenu] == [CPApp mainMenu])
    {
        [self showMenu:nil fromMenu:menu atPoint:CGPointMakeZero()];
        [self moveDown:[CPApp mainMenu]];

        var activeItem = [[CPApp mainMenu] highlightedItem],
            menuLocation = CGPointMake([[activeItem _menuItemView] frameOrigin].x , [[activeItem _menuItemView] frameSize].height);

        [self showMenu:[activeItem submenu] fromMenu:[activeItem menu] atPoint:menuLocation];
    }
}

- (void)moveDown:(CPMenu)menu
{
    var index = menu._highlightedIndex + 1;

    if (index < [menu numberOfItems])
    {
        [menu _highlightItemAtIndex:index];

        var item = [menu highlightedItem];

        if ([item isSeparatorItem] || [item isHidden] || ![item isEnabled])
            [self moveDown:menu];
    }
}

- (void)moveUp:(CPMenu)menu
{
    var index = menu._highlightedIndex - 1;

    if (index < 0)
        return;

    [menu _highlightItemAtIndex:index];

    var item = [menu highlightedItem];

    if ([item isSeparatorItem] || [item isHidden] || ![item isEnabled])
        [self moveUp:menu];
}

- (void)insertNewline:(CPMenu)menu
{
    if ([[menu highlightedItem] hasSubmenu])
        [self moveRight:menu];
    else
        [menu cancelTracking]
}

- (void)cancelOperation:(CPMenu)menu
{
    [menu _highlightItemAtIndex:CPNotFound];
    [CPEvent stopPeriodicEvents];
    [[self trackingMenu] cancelTracking];
}

@end
