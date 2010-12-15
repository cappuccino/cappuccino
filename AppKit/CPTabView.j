@import "CPBox.j"
@import "CPSegmentedControl.j"
@import "CPTabViewItem.j"
@import "CPView.j"

CPTopTabsBezelBorder     = 0;
//CPLeftTabsBezelBorder  = 1;
CPBottomTabsBezelBorder  = 2;
//CPRightTabsBezelBorder = 3;
CPNoTabsBezelBorder      = 4; //Displays no tabs and has a bezeled border.
CPNoTabsLineBorder       = 5; //Has no tabs and displays a line border.
CPNoTabsNoBorder         = 6; //Displays no tabs and no border.

var CPTabViewDidSelectTabViewItemSelector           = 1,
    CPTabViewShouldSelectTabViewItemSelector        = 2,
    CPTabViewWillSelectTabViewItemSelector          = 4,
    CPTabViewDidChangeNumberOfTabViewItemsSelector  = 8;

@implementation CPTabView : CPView
{
    CPArray             _items;

    CPSegmentedControl  _tabs;
    CPBox               _box;

    CPNumber            _selectedIndex;

    CPTabViewType       _type;

    id                  _delegate;
    unsigned            _delegateSelectors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _items = [CPArray array];
        _selectedIndex = CPNotFound;

        [self _init];
        [self setTabViewType:CPTopTabsBezelBorder];
    }

    return self;
}

- (void)_init
{
    _tabs = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [_tabs setHitTests:NO];
    
    var height = [_tabs valueForThemeAttribute:@"default-height"];
    [_tabs setFrameSize:CGSizeMake(0, height)];

    _box = [[CPBox alloc] initWithFrame:[self  bounds]];
    [self setBackgroundColor:[CPColor colorWithCalibratedWhite:0.95 alpha:1.0]];

    [_box setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_tabs setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin];

    [self addSubview:_box];
    [self addSubview:_tabs];
}

// Adding and Removing Tabs
/*!
    Adds a CPTabViewItem to the tab view.
    @param aTabViewItem the item to add
*/
- (void)addTabViewItem:(CPTabViewItem)aTabViewItem
{
    [self insertTabViewItem:aTabViewItem atIndex:[_items count]];
}

/*!
    Inserts a CPTabViewItem into the tab view
    at the specified index.
    @param aTabViewItem the item to insert
    @param anIndex the index for the item
*/
- (void)insertTabViewItem:(CPTabViewItem)aTabViewItem atIndex:(unsigned)anIndex
{
    [_items insertObject:aTabViewItem atIndex:anIndex];

    [self _updateItems];
    [self _repositionTabs];

    if (_delegateSelectors & CPTabViewDidChangeNumberOfTabViewItemsSelector)
        [_delegate tabViewDidChangeNumberOfTabViewItems:self];
}

/*!
    Removes the specified tab view item from the tab view.
    @param aTabViewItem the item to remove
*/
- (void)removeTabViewItem:(CPTabViewItem)aTabViewItem
{
    var count = [_items count];
    for (var i = 0; i < count; i++)
    {
        if ([items objectAtIndex:i] === aTabViewItem)
        {
            [items removeObjectAtIndex:i];
            break;
        }
    }

    [self _updateItems];
    [self _repositionTabs];

    if (_delegateSelectors & CPTabViewDidChangeNumberOfTabViewItemsSelector)
        [_delegate tabViewDidChangeNumberOfTabViewItems:self];
}

// Accessing Tabs
/*!
    Returns the index of the specified item
    @param aTabViewItem the item to find the index for
*/
- (int)indexOfTabViewItem:(CPTabViewItem)aTabViewItem
{
    return [_items indexOfObjectIdenticalTo:aTabViewItem];
}

/*!
    Returns the index of the CPTabViewItem with the specified identifier.
    @param anIdentifier the identifier of the item
*/
- (int)indexOfTabViewItemWithIdentifier:(CPString)anIdentifier
{
    for (var index = [_items count]; index >= 0; index--)
        if ([[_items[index] identifier] isEqual:anIdentifier])
            return index;

    return CPNotFound;
}

/*!
    Returns the number of items in the tab view.
*/
- (unsigned)numberOfTabViewItems
{
    return [_items count];
}

/*!
    Returns the CPTabViewItem at the specified index.
*/
- (CPTabViewItem)tabViewItemAtIndex:(unsigned)anIndex
{
    return [_items objectAtIndex:anIndex];
}

/*!
    Returns the array of items that backs this tab view.
*/
- (CPArray)tabViewItems
{
    return [_items copy]; // Copy?
}

// Selecting a Tab
/*!
    Sets the first tab view item in the array to be displayed to the user.
    @param aSender the object making this request
*/
- (void)selectFirstTabViewItem:(id)aSender
{
    if ([_items count] === 0)
        return; // throw?

    [self selectTabViewItemAtIndex:0];
}

/*!
    Sets the last tab view item in the array to be displayed to the user.
    @param aSender the object making this request
*/
- (void)selectLastTabViewItem:(id)aSender
{
    if ([_items count] === 0)
        return; // throw?

    [self selectTabViewItemAtIndex:[_items count] - 1];
}

/*!
    Sets the next tab item in the array to be displayed.
    @param aSender the object making this request
*/
- (void)selectNextTabViewItem:(id)aSender
{
    if (_selectedIndex === CPNotFound)
        return;

    var nextIndex = _selectedIndex + 1;

    if (nextIndex === [_items count])
        // does nothing. According to spec at (http://developer.apple.com/mac/library/DOCUMENTATION/Cocoa/Reference/ApplicationKit/Classes/NSTabView_Class/Reference/Reference.html#//apple_ref/occ/instm/NSTabView/selectNextTabViewItem:)
        return;

    [self selectTabViewItemAtIndex:nextIndex];
}

/*!
    Selects the previous item in the array for display.
    @param aSender the object making this request
*/
- (void)selectPreviousTabViewItem:(id)aSender
{
    if (_selectedIndex === CPNotFound)
        return;

    var previousIndex = _selectedIndex - 1;

    if (previousIndex < 0)
        return; // does nothing. See above.

    [self selectTabViewItemAtIndex:previousIndex];
}

/*!
    Displays the specified item in the tab view.
    @param aTabViewItem the item to display
*/
- (void)selectTabViewItem:(CPTabViewItem)aTabViewItem
{
    [self selectTabViewItemAtIndex:[self indexOfTabViewItem:aTabViewItem]];
}

/*!
    Selects the item at the specified index.
    @param anIndex the index of the item to display.
*/
- (void)selectTabViewItemAtIndex:(unsigned)anIndex
{
    var aTabViewItem = [_items objectAtIndex:anIndex];

    if (anIndex === _selectedIndex)
        return;

    var aTabViewItem = [self tabViewItemAtIndex:anIndex];

    if ((_delegateSelectors & CPTabViewShouldSelectTabViewItemSelector) && ![delegate tabView:self shouldSelectTabViewItem:aTabViewItem])
        return;

    if (_delegateSelectors & CPTabViewWillSelectTabViewItemSelector)
        [_delegate tabView:self willSelectTabViewItem:aTabViewItem];

    [_tabs selectSegmentWithTag:anIndex];
    [self _setSelectedIndex:anIndex];

    if (_delegateSelectors & CPTabViewDidSelectTabViewItemSelector)
        [_delegate tabView:self didSelectTabViewItem:aTabViewItem];
}

/*!
    Returns the current item being displayed.
*/
- (CPTabViewItem)selectedTabViewItem
{
    return [_items objectAtIndex:_selectedIndex];
}

//
/*!
    Sets the tab view type.
    @param aTabViewType the view type
*/
- (void)setTabViewType:(CPTabViewType)aTabViewType
{
    if (_type === aTabViewType)
        return;

    _type = aTabViewType;

    if (_type !== CPTopTabsBezelBorder && _type !== CPBottomTabsBezelBorder)
    {
        [_box setFrame:[self bounds]];
        [_tabs removeFromSuperview];
    }
    else
    {
        var aFrame = [self frame],
            segmentedHeight = CGRectGetHeight([_tabs frame]),
            origin = _type === CPTopTabsBezelBorder ? segmentedHeight / 2 : 0;

        [_box setFrame:CGRectMake(0, origin, CGRectGetWidth(aFrame),
                                  CGRectGetHeight(aFrame) - segmentedHeight / 2)];

        [self addSubview:_tabs];
    }

    switch (_type)
    {
        case CPTopTabsBezelBorder:
        case CPBottomTabsBezelBorder:
        case CPNoTabsBezelBorder:
            [_box setBorderType:CPBezelBorder];
            break;
        case CPNoTabsLineBorder:
            [_box setBorderType:CPLineBorder];
            break;
        case CPNoTabsNoBorder:
            [_box setBorderType:CPNoBorder];
            break;
    }
}

/*!
    Returns the tab view type.
*/
- (CPTabViewType)tabViewType
{
    return _type;
}

/*!
    Returns the receiver's delegate.
*/
- (id)delegate
{
    return _delegate;
}

/*!
    Sets the delegate for this tab view.
    @param aDelegate the tab view's delegate
*/
- (void)setDelegate:(id)aDelegate
{
    if (_delegate == aDelegate)
        return;

    _delegate = aDelegate;

    _delegateSelectors = 0;

    if ([_delegate respondsToSelector:@selector(tabView:shouldSelectTabViewItem:)])
        _delegateSelectors |= CPTabViewShouldSelectTabViewItemSelector;

    if ([_delegate respondsToSelector:@selector(tabView:willSelectTabViewItem:)])
        _delegateSelectors |= CPTabViewWillSelectTabViewItemSelector;

    if ([_delegate respondsToSelector:@selector(tabView:didSelectTabViewItem:)])
        _delegateSelectors |= CPTabViewDidSelectTabViewItemSelector;

    if ([_delegate respondsToSelector:@selector(tabViewDidChangeNumberOfTabViewItems:)])
        _delegateSelectors |= CPTabViewDidChangeNumberOfTabViewItemsSelector;
}

- (void)setBackgroundColor:(CPColor)aColor
{
    [_box setBackgroundColor:aColor];
}

- (CPColor)backgroundColor
{
    return [_box backgroundColor];
}

- (void)mouseDown:(CPEvent)anEvent
{
    var segmentIndex = [_tabs testSegment:[_tabs convertPoint:[anEvent locationInWindow] fromView:nil]];

    if (segmentIndex != CPNotFound)
    {
        [self selectTabViewItemAtIndex:segmentIndex];
        [_tabs trackSegment:anEvent];
    }
}

- (void)_repositionTabs
{
    var horizontalCenterOfSelf = CGRectGetWidth([self bounds]) / 2,
        verticalCenterOfTabs = CGRectGetHeight([_tabs bounds]) / 2;

    if (_type === CPBottomTabsBezelBorder)
        [_tabs setCenter:CGPointMake(horizontalCenterOfSelf, CGRectGetHeight([self bounds]) - verticalCenterOfTabs)];
    else
        [_tabs setCenter:CGPointMake(horizontalCenterOfSelf, verticalCenterOfTabs)];
}

- (void)_setSelectedIndex:(CPNumber)index
{
    _selectedIndex = index;

    [_box setContentView:[[_items objectAtIndex:_selectedIndex] view]];
}

- (void)_updateItems
{
    var count = [_items count];
    [_tabs setSegmentCount:count];

    for (var i = 0; i < count; i++)
    {
        [_tabs setLabel:[[_items objectAtIndex:i] label] forSegment:i];
        [_tabs setTag:i forSegment:i];
    }

    if (_selectedIndex === CPNotFound)
    {
        [self selectFirstTabViewItem:self];
    }
}

@end

var CPTabViewItemsKey               = "CPTabViewItemsKey",
    CPTabViewSelectedItemKey        = "CPTabViewSelectedItemKey",
    CPTabViewTypeKey                = "CPTabViewTypeKey",
    CPTabViewDelegateKey            = "CPTabViewDelegateKey";

@implementation CPTabView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        [self _init];

        _items = [aCoder decodeObjectForKey:CPTabViewItemsKey];

        [self _updateItems];
        [self _repositionTabs];

        var selected = [aCoder decodeObjectForKey:CPTabViewSelectedItemKey];
        if (selected)
            [self selectTabViewItem:selected];

        [self setDelegate:[aCoder decodeObjectForKey:CPTabViewDelegateKey]];

        [self setTabViewType:[aCoder decodeIntForKey:CPTabViewTypeKey]];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_items forKey:CPTabViewItemsKey];
    [aCoder encodeObject:[self selectedTabViewItem] forKey:CPTabViewSelectedItemKey];

    [aCoder encodeInt:_type forKey:CPTabViewTypeKey];

    [aCoder encodeConditionalObject:_delegate forKey:CPTabViewDelegateKey];
}

@end
