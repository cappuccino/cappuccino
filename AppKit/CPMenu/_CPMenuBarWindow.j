@import "CPPanel.j"
@import "_CPMenuWindow.j"


var MENUBAR_HEIGHT          = 28.0,
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
    
    _CPMenuBarWindowFont = [CPFont boldSystemFontOfSize:12.0];
}

+ (CPFont)font
{
    return _CPMenuBarWindowFont;
}

- (id)init
{
    // This only shows up in browser land, so don't bother calculating metrics in desktop.
    var contentRect = [[CPPlatformWindow primaryPlatformWindow] contentBounds];

    contentRect.size.height = MENUBAR_HEIGHT;

    self = [super initWithContentRect:contentRect styleMask:CPBorderlessWindowMask];

    if (self)
    {
        [self setLevel:CPMainMenuWindowLevel];
        [self setAutoresizingMask:CPWindowWidthSizable];
     
        var contentView = [self contentView];
        
        [contentView setAutoresizesSubviews:NO];
        
        [self setBecomesKeyOnlyIfNeeded:YES];
        
        //
        _iconImageView = [[CPImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)];
        
        [contentView addSubview:_iconImageView];
        
        _titleField = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

        [_titleField setFont:[CPFont boldSystemFontOfSize:13.0]];
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
            _CPMenuBarWindowBackgroundColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[_CPMenuBarWindow class]] pathForResource:@"_CPMenuBarWindow/_CPMenuBarWindowBackground.png"] size:CGSizeMake(1.0, 28.0)]];
            
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

- (void)mouseDown:(CPEvent)anEvent
{
    var constraintRect = CGRectInset([[self platformWindow] visibleFrame], 5.0, 0.0);

    constraintRect.size.height -= 5.0;

    [[_CPMenuManager sharedMenuManager]
        beginTracking:anEvent
        menuContainer:self
       constraintRect:constraintRect
             callback:function(aMenuContainer, aMenu)
             {
                [aMenu _performActionOfHighlightedItemChain];
                [aMenu _highlightItemAtIndex:CPNotFound];
             }];
}

- (CPFont)font
{
    [CPFont systemFontOfSize:12.0];
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
            [menuItemView setFrame:CGRectMake(x, 0.0, CGRectGetWidth(frame), MENUBAR_HEIGHT)];

            x += CGRectGetWidth([menuItemView frame]);
        }
        else
        {
            [menuItemView setFrame:CGRectMake(x - CGRectGetWidth(frame), 0.0, CGRectGetWidth(frame), MENUBAR_HEIGHT)];
     
            x = CGRectGetMinX([menuItemView frame]);
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

@implementation _CPMenuBarWindow (CPMenuContainer)

- (BOOL)isMenuBar
{
    return YES;
}

- (CGRect)globalFrame
{
    return [self frame];
}

- (_CPManagerScrollingState)scrollingStateForPoint:(CGPoint)aGlobalLocation
{
    return _CPMenuManagerScrollingStateNone;
}

- (CPInteger)itemIndexAtPoint:(CGPoint)aPoint
{
    var items = [_menu itemArray],
        index = items.length;

    while (index--)
    {
        var item = items[index];

        if ([item isHidden] || [item isSeparatorItem])
            continue;

        if (CGRectContainsPoint([self rectForItemAtIndex:index], aPoint))
            return index;
    }

    return CPNotFound;
}

- (CGRect)rectForItemAtIndex:(CPInteger)anIndex
{
    var menuItem = [_menu itemAtIndex:anIndex === CPNotFound ? 0 : anIndex];

    return [[menuItem _menuItemView] frame];
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
