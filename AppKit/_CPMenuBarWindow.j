
#include "../CoreGraphics/CGGeometry.h"

@import "_CPMenuWindow.j"


var MENUBAR_HEIGHT          = 29.0,
    MENUBAR_MARGIN          = 10.0,
    MENUBAR_LEFT_MARGIN     = 10.0,
    MENUBAR_RIGHT_MARGIN    = 10.0;

var _CPMenuBarWindowBackgroundColor = nil,
    _CPMenuBarWindowFont            = nil;

@implementation _CPMenuBarWindow : CPPanel
{
    CPMenu      _menu;
    CPView      _highlightView;
    CPArray     _menuItemViews;
    
    CPMenuItem  _trackingMenuItem;
    
    CPImageView _iconImageView;
    CPTextField _titleField;
    
    CPColor     _textColor;
    CPColor     _titleColor;
    
    CPColor     _textShadowColor;
    CPColor     _titleShadowColor;
    
    CPColor     _highlightColor;
    CPColor     _highlightTextColor;
    CPColor     _highlightTextShadowColor;
}

+ (void)initialize
{
    if (self != [_CPMenuBarWindow class])
        return;
        
    var bundle = [CPBundle bundleForClass:self];
    
    _CPMenuBarWindowFont = [CPFont systemFontOfSize:11.0];
}

- (id)init
{
    // This only shows up in browser land, so don't bother calculating metrics in desktop.
    var contentRect = [[CPPlatformWindow primaryPlatformWindow] contentBounds];

    contentRect.size.height = MENUBAR_HEIGHT;

    self = [super initWithContentRect:contentRect styleMask:CPBorderlessWindowMask];

    if (self)
    {
        // FIXME: http://280north.lighthouseapp.com/projects/13294-cappuccino/tickets/39-dont-allow-windows-to-go-above-menubar
        [self setLevel:-1];//CPTornOffMenuWindowLevel];
        [self setAutoresizingMask:CPWindowWidthSizable];
     
        var contentView = [self contentView];
        
        [contentView setAutoresizesSubviews:NO];
        
        [self setBecomesKeyOnlyIfNeeded:YES];
        
        //
        _iconImageView = [[CPImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)];
        
        [contentView addSubview:_iconImageView];
        
        _titleField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
        
        [_titleField setFont:[CPFont boldSystemFontOfSize:12.0]];
        [_titleField setAlignment:CPCenterTextAlignment];
        [_titleField setTextShadowOffset:CGSizeMake(0, 1)];
        
        [contentView addSubview:_titleField];
    }
    
    return self;
}

- (void)setTitle:(CPString)aTitle
{
#if PLATFORM(DOM)
    var bundleName = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleName"];

    if (![bundleName length])
        document.title = aTitle;
    else if ([aTitle length])
        document.title = aTitle + @" - " + bundleName;
    else
        document.title = bundleName;
#endif

    [_titleField setStringValue:aTitle];
    [_titleField sizeToFit];
    
    [self tile];
}

- (void)setIconImage:(CPImage)anImage
{
    [_iconImageView setImage:anImage];
    [_iconImageView setHidden:anImage == nil];

    [self tile];
}

- (void)setIconImageAlphaValue:(float)anAlphaValue
{
    [_iconImageView setAlphaValue:anAlphaValue];
}

- (void)setColor:(CPColor)aColor
{
    if (!aColor)
    {
        if (!_CPMenuBarWindowBackgroundColor)
            _CPMenuBarWindowBackgroundColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[_CPMenuBarWindow class]] pathForResource:@"_CPMenuBarWindow/_CPMenuBarWindowBackground.png"] size:CGSizeMake(1.0, 18.0)]];
            
        [[self contentView] setBackgroundColor:_CPMenuBarWindowBackgroundColor];
    }
    else
        [[self contentView] setBackgroundColor:aColor];
}

- (void)setTextColor:(CPColor)aColor
{
    if (_textColor == aColor)
        return;
    
    _textColor = aColor;
    
    [_menuItemViews makeObjectsPerformSelector:@selector(setTextColor:) withObject:_textColor];
}

- (void)setTitleColor:(CPColor)aColor
{
    if (_titleColor == aColor)
        return;
    
    _titleColor = aColor;
    
    [_titleField setTextColor:aColor ? aColor : [CPColor blackColor]];
}

- (void)setTextShadowColor:(CPColor)aColor
{
    if (_textShadowColor == aColor)
        return;
    
    _textShadowColor = aColor;
    
    [_menuItemViews makeObjectsPerformSelector:@selector(setTextShadowColor:) withObject:_textShadowColor];
}

- (void)setTitleShadowColor:(CPColor)aColor
{
    if (_titleShadowColor == aColor)
        return;
    
    _titleShadowColor = aColor;
    
    [_titleField setTextShadowColor:aColor ? aColor : [CPColor whiteColor]];
}

- (void)setHighlightColor:(CPColor)aColor
{
    if (_highlightColor == aColor)
        return;
    
    _highlightColor = aColor;
}

- (void)setHighlightTextColor:(CPColor)aColor
{
    if (_highlightTextColor == aColor)
        return;
    
    _highlightTextColor = aColor;

//    [_menuItemViews makeObjectsPerformSelector:@selector(setActivateColor:) withObject:_highlightTextColor];
}

- (void)setHighlightTextShadowColor:(CPColor)aColor
{
    if (_highlightTextShadowColor == aColor)
        return;
    
    _highlightTextShadowColor = aColor;
    
//    [_menuItemViews makeObjectsPerformSelector:@selector(setActivateShadowColor:) withObject:_highlightTextShadowColor];
}

- (void)setMenu:(CPMenu)aMenu
{
    if (_menu == aMenu)
        return;
    
    var defaultCenter = [CPNotificationCenter defaultCenter];
    
    if (_menu)
    {
        [defaultCenter
            removeObserver:self
                      name:CPMenuDidAddItemNotification
                    object:_menu];

        [defaultCenter
            removeObserver:self
                      name:CPMenuDidChangeItemNotification
                    object:_menu];

        [defaultCenter
            removeObserver:self
                      name:CPMenuDidRemoveItemNotification
                    object:_menu];
                    
        var items = [_menu itemArray],
            count = items.length;
        
        while (count--)
            [[items[count] _menuItemView] removeFromSuperview];
    }

    _menu = aMenu;
    
    if (_menu)
    {
        [defaultCenter
            addObserver:self
              selector:@selector(menuDidAddItem:)
                  name:CPMenuDidAddItemNotification
                object:_menu];
    
        [defaultCenter
            addObserver:self
              selector:@selector(menuDidChangeItem:)
                  name:CPMenuDidChangeItemNotification
                object:_menu];
                
        [defaultCenter
            addObserver:self
              selector:@selector(menuDidRemoveItem:)
                  name:CPMenuDidRemoveItemNotification
                object:_menu];
    }
    
    _menuItemViews = [];
    
    var contentView = [self contentView],
        items = [_menu itemArray],
        count = items.length;
    
    for (index = 0; index < count; ++index)
    {
        var item = items[index],
            menuItemView = [item _menuItemView];
            
        _menuItemViews.push(menuItemView);
        
        [menuItemView setShowsStateColumn:NO];
        [menuItemView setBelongsToMenuBar:YES];
        [menuItemView setFont:_CPMenuBarWindowFont];
        [menuItemView setTextColor:_textColor];
        [menuItemView setHidden:[item isHidden]];
        
        [menuItemView synchronizeWithMenuItem];
        
        [contentView addSubview:menuItemView];
    }
        
    [self tile];
}

- (void)menuDidChangeItem:(CPNotification)aNotification
{
    var menuItem = [_menu itemAtIndex:[[aNotification userInfo] objectForKey:@"CPMenuItemIndex"]],
        menuItemView = [menuItem _menuItemView];

    [menuItemView setHidden:[menuItem isHidden]];
    [menuItemView synchronizeWithMenuItem];
    
    [self tile];
}

- (void)menuDidAddItem:(CPNotification)aNotification
{
    var index = [[aNotification userInfo] objectForKey:@"CPMenuItemIndex"],
        menuItem = [_menu itemAtIndex:index],
        menuItemView = [menuItem _menuItemView];

    [_menuItemViews insertObject:menuItemView atIndex:index];

    [menuItemView setShowsStateColumn:NO];
    [menuItemView setBelongsToMenuBar:YES];
    [menuItemView setFont:_CPMenuBarWindowFont];
    [menuItemView setTextColor:_textColor];
    [menuItemView setHidden:[menuItem isHidden]];

    [menuItemView synchronizeWithMenuItem];
    
    [[self contentView] addSubview:menuItemView];
    
    [self tile];
}

- (void)menuDidRemoveItem:(CPNotification)aNotification
{
    var index = [[aNotification userInfo] objectForKey:@"CPMenuItemIndex"],
        menuItemView = [_menuItemViews objectAtIndex:index];

    [_menuItemViews removeObjectAtIndex:index];

    [menuItemView removeFromSuperview];
        
    [self tile];
}

- (CGRect)frameForMenuItem:(CPMenuItem)aMenuItem
{
    var frame = [[aMenuItem _menuItemView] frame];
    
    frame.origin.x -= 5.0;
    frame.origin.y = 0;
    frame.size.width += 10.0;
    frame.size.height = MENUBAR_HEIGHT;
    
    return frame;
}

- (CPMenuItem)menuItemAtPoint:(CGPoint)aPoint
{
    var items = [_menu itemArray],
        count = items.length;
    
    while (count--)
    {
        var item = items[count];
        
        if ([item isHidden] || [item isSeparatorItem])
            continue;
        
        if (CGRectContainsPoint([self frameForMenuItem:item], aPoint))
            return item;
    }
    
    return nil;
}

- (void)mouseDown:(CPEvent)anEvent
{
    _trackingMenuItem = [self menuItemAtPoint:[anEvent locationInWindow]];
    
    if (![_trackingMenuItem isEnabled])
        return;
    
    if ([[_trackingMenuItem _menuItemView] eventOnSubmenu:anEvent])
        return [self showMenu:anEvent];
    
    if ([_trackingMenuItem isEnabled])
        [self trackEvent:anEvent];
}

- (void)trackEvent:(CPEvent)anEvent
{
    var type = [anEvent type];
    
    if (type === CPPeriodic)
        return [self showMenu:anEvent];
    
    var frame = [self frameForMenuItem:_trackingMenuItem],
        menuItemView = [_trackingMenuItem _menuItemView],
        onMenuItemView = CGRectContainsPoint(frame, [anEvent locationInWindow]);
        
    if (type == CPLeftMouseDown)
    {
        if ([_trackingMenuItem submenu] != nil)
        {
            var action = [_trackingMenuItem action];

            // If the item has a submenu, but not direct action, a.k.a. a "pure" menu, simply show the menu.
            // FIXME: (?) should we use submenuAction: or not?
            if (!action || action === @selector(submenuAction:))
                return [self showMenu:anEvent];
            
            // If this is a hybrid button/menu, show it in a bit...
            [CPEvent startPeriodicEventsAfterDelay:0.0 withPeriod:0.5];
        }
        
        [menuItemView highlight:onMenuItemView];
    }
    
    else if (type == CPLeftMouseDragged)
    {
        if (!onMenuItemView && [_trackingMenuItem submenu])
            return [self showMenu:anEvent];
    
        [menuItemView highlight:onMenuItemView];
    }
    
    else /*if (type == CPLeftMouseUp)*/
    {
        [CPEvent stopPeriodicEvents];
    
        [menuItemView highlight:NO];
        
        if (onMenuItemView)
            [CPApp sendAction:[_trackingMenuItem action] to:[_trackingMenuItem target] from:_trackingMenuItem];
        
        return;
    }
    
    [CPApp setTarget:self selector:@selector(trackEvent:) forNextEventMatchingMask:CPPeriodicMask | CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];    
}

- (void)showMenu:(CPEvent)anEvent
{
    [CPEvent stopPeriodicEvents];
    
    var frame = [self frameForMenuItem:_trackingMenuItem],
        menuItemView = [_trackingMenuItem _menuItemView];
    
    if (!_highlightView)
    {
        _highlightView = [[CPView alloc] initWithFrame:frame];
    
        [_highlightView setBackgroundColor:_highlightColor ? _highlightColor : [CPColor colorWithRed:95.0/255.0 green:131.0/255.0 blue:185.0/255.0 alpha:1.0]];
    }
    else
        [_highlightView setFrame:frame];
        
    [[self contentView] addSubview:_highlightView positioned:CPWindowBelow relativeTo:menuItemView];
    
    [menuItemView activate:YES];
    
    var submenu = [_trackingMenuItem submenu];

    [[CPNotificationCenter defaultCenter]
        addObserver:self
          selector:@selector(menuDidEndTracking:)
              name:CPMenuDidEndTrackingNotification
            object:submenu];
    
    [CPMenu _popUpContextMenu:submenu
                    withEvent:[CPEvent mouseEventWithType:CPLeftMouseDown location:CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame))
                                modifierFlags:[anEvent modifierFlags] timestamp:[anEvent timestamp] windowNumber:[self windowNumber] 
                                context:nil eventNumber:0 clickCount:[anEvent clickCount] pressure:[anEvent pressure]] 
                      forView:[self contentView]
                     withFont:nil
                   forMenuBar:YES];
}

- (void)menuDidEndTracking:(CPNotification)aNotification
{
    [_highlightView removeFromSuperview];
    
    [[_trackingMenuItem _menuItemView] activate:NO];
    
    [[CPNotificationCenter defaultCenter]
        removeObserver:self
                  name:CPMenuDidEndTrackingNotification
                object:[aNotification object]];
}

- (void)tile
{
    var items = [_menu itemArray],
        index = 0,
        count = items.length,
        
        x = MENUBAR_LEFT_MARGIN,
        y = 0.0,
        isLeftAligned = YES;
    
    for (; index < count; ++index)
    {
        var item = items[index];
        
        if ([item isSeparatorItem])
        {
            x = CGRectGetWidth([self frame]) - MENUBAR_RIGHT_MARGIN;
            isLeftAligned = NO;
            
            continue;
        }
        
         if ([item isHidden])
            continue;

        var menuItemView = [item _menuItemView],
            frame = [menuItemView frame];
        
        if (isLeftAligned)
        {
            [menuItemView setFrameOrigin:CGPointMake(x, (MENUBAR_HEIGHT - 1.0 - CGRectGetHeight(frame)) / 2.0)];
     
            x += CGRectGetWidth([menuItemView frame]) + MENUBAR_MARGIN;
        }
        else
        {
            [menuItemView setFrameOrigin:CGPointMake(x - CGRectGetWidth(frame), (MENUBAR_HEIGHT - 1.0 - CGRectGetHeight(frame)) / 2.0)];
     
            x = CGRectGetMinX([menuItemView frame]) - MENUBAR_MARGIN;
        }
    }
    
    var bounds = [[self contentView] bounds],
        titleFrame = [_titleField frame];
    
    if ([_iconImageView isHidden])
        [_titleField setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - CGRectGetWidth(titleFrame)) / 2.0, (CGRectGetHeight(bounds) - CGRectGetHeight(titleFrame)) / 2.0)];
    else
    {
        var iconFrame = [_iconImageView frame],
            iconWidth = CGRectGetWidth(iconFrame),
            totalWidth = iconWidth + CGRectGetWidth(titleFrame);
        
        [_iconImageView setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - totalWidth) / 2.0, (CGRectGetHeight(bounds) - CGRectGetHeight(iconFrame)) / 2.0)];
        [_titleField setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - totalWidth) / 2.0 + iconWidth, (CGRectGetHeight(bounds) - CGRectGetHeight(titleFrame)) / 2.0)];
    }
}

- (void)setFrame:(CGRect)aRect display:(BOOL)shouldDisplay animate:(BOOL)shouldAnimate
{
    var size = [self frame].size;

    [super setFrame:aRect display:shouldDisplay animate:shouldAnimate];

    if (!_CGSizeEqualToSize(size, aRect.size))
        [self tile];
}

@end

@implementation __CPMenuBarWindow : _CPMenuWindow
{
}

@end

@implementation _CPMenuBarView : _CPMenuView
{
}

- (CGRect)rectForItemAtIndex:(int)anIndex
{
    return [_menuItemViews[anIndex === CPNotFound ? 0 : anIndex] frame];
}

- (int)itemIndexAtPoint:(CGPoint)aPoint
{
    var bounds = [self bounds];

    if (!CGRectContainsPoint(bounds, aPoint))
        return CPNotFound;

    var x = aPoint.x,
        low = 0,
        high = _visibleMenuItemInfos.length - 1;

    while (low <= high)
    {
        var middle = FLOOR(low + (high - low) / 2),
            info = _visibleMenuItemInfos[middle],
            frame = [info.view frame];

        if (x < CGRectGetMinX(frame))
            high = middle - 1;

        else if (x > CGRectGetMaxX(frame))
            low = middle + 1;

        else
            return info.index;
   }

   return CPNotFound;
}

- (void)tile
{
    var items = [_menu itemArray],
        index = 0,
        count = items.length,

        x = MENUBAR_LEFT_MARGIN,
        y = 0.0,
        isLeftAligned = YES;

    for (; index < count; ++index)
    {
        var item = items[index];
        
        if ([item isSeparatorItem])
        {
            x = CGRectGetWidth([self frame]) - MENUBAR_RIGHT_MARGIN;
            isLeftAligned = NO;
            
            continue;
        }
        
         if ([item isHidden])
            continue;

        var menuItemView = [item _menuItemView],
            frame = [menuItemView frame];
        
        if (isLeftAligned)
        {
            [menuItemView setFrameOrigin:CGPointMake(x, (MENUBAR_HEIGHT - 1.0 - CGRectGetHeight(frame)) / 2.0)];
     
            x += CGRectGetWidth([menuItemView frame]) + MENUBAR_MARGIN;
        }
        else
        {
            [menuItemView setFrameOrigin:CGPointMake(x - CGRectGetWidth(frame), (MENUBAR_HEIGHT - 1.0 - CGRectGetHeight(frame)) / 2.0)];
     
            x = CGRectGetMinX([menuItemView frame]) - MENUBAR_MARGIN;
        }
    }
    
    var bounds = [[self contentView] bounds],
        titleFrame = [_titleField frame];
    
    if ([_iconImageView isHidden])
        [_titleField setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - CGRectGetWidth(titleFrame)) / 2.0, (CGRectGetHeight(bounds) - CGRectGetHeight(titleFrame)) / 2.0)];
    else
    {
        var iconFrame = [_iconImageView frame],
            iconWidth = CGRectGetWidth(iconFrame),
            totalWidth = iconWidth + CGRectGetWidth(titleFrame);
        
        [_iconImageView setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - totalWidth) / 2.0, (CGRectGetHeight(bounds) - CGRectGetHeight(iconFrame)) / 2.0)];
        [_titleField setFrameOrigin:CGPointMake((CGRectGetWidth(bounds) - totalWidth) / 2.0 + iconWidth, (CGRectGetHeight(bounds) - CGRectGetHeight(titleFrame)) / 2.0)];
    }
}

@end
