@import "CPBox.j"
@import "CPSegmentedControl.j"
@import "CPTabViewItem.j"
@import "CPView.j"

/*
    Places tabs on top with a bezeled border.
    @global
    @group CPTabViewType
*/
CPTopTabsBezelBorder     = 0;
//CPLeftTabsBezelBorder    = 1;
CPBottomTabsBezelBorder  = 2;
//CPRightTabsBezelBorder   = 3;
/*
    Displays no tabs and has a bezeled border.
    @global
    @group CPTabViewType
*/
CPNoTabsBezelBorder      = 4;
/*
    Has no tabs and displays a line border.
    @global
    @group CPTabViewType
*/
CPNoTabsLineBorder       = 5;
/*
    Displays no tabs and no border.
    @global
    @group CPTabViewType
*/
CPNoTabsNoBorder         = 6;

var CPTabViewDidSelectTabViewItemSelector           = 1,
    CPTabViewShouldSelectTabViewItemSelector        = 2,
    CPTabViewWillSelectTabViewItemSelector          = 4,
    CPTabViewDidChangeNumberOfTabViewItemsSelector  = 8;

var HEIGHT_OF_SEGMENTED_CONTROL = 24;

@implementation CPTabView : CPView
{
    CPArray             items;

    CPSegmentedControl  tabs;
    CPBox               box;

    CPNumber            selectedIndex;

    CPTabViewType       type;

    id                  delegate;
    unsigned            delegateSelectors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    if (self)
    {
        items = [CPArray array];
        selectedIndex = CPNotFound;
        [self setTabViewType:CPTopTabsBezelBorder];

        [self _init];
    }
    return self;
}

- (void)_init
{
    tabs = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(0, 0, 0, HEIGHT_OF_SEGMENTED_CONTROL)];
    [tabs setHitTests:NO];

    var aFrame = [self frame];

    box = [[CPBox alloc] initWithFrame:CGRectMake(0, HEIGHT_OF_SEGMENTED_CONTROL / 2, CGRectGetWidth(aFrame),
                                                        CGRectGetHeight(aFrame) - HEIGHT_OF_SEGMENTED_CONTROL)];

    [self setBackgroundColor:[CPColor colorWithCalibratedWhite:0.95 alpha:1.0]];

    [self addSubview:box];
    [self addSubview:tabs];

    [box setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [tabs setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin];
}

// Adding and Removing Tabs
/*!
    Adds a CPTabViewItem to the tab view.
    @param aTabViewItem the item to add
*/
- (void)addTabViewItem:(CPTabViewItem)aTabViewItem
{
    [self insertTabViewItem:aTabViewItem atIndex:[items count]];
}

/*!
    Inserts a CPTabViewItem into the tab view
    at the specified index.
    @param aTabViewItem the item to insert
    @param anIndex the index for the item
*/
- (void)insertTabViewItem:(CPTabViewItem)aTabViewItem atIndex:(unsigned)anIndex
{
    [items insertObject:aTabViewItem atIndex:anIndex];

    [self _updateItems];
    [self _repositionTabs];

    if (delegateSelectors & CPTabViewDidChangeNumberOfTabViewItemsSelector)
        [delegate tabViewDidChangeNumberOfTabViewItems:self];
}

/*!
    Removes the specified tab view item from the tab view.
    @param aTabViewItem the item to remove
*/
- (void)removeTabViewItem:(CPTabViewItem)aTabViewItem
{
    for (var i = 0; i < [items count]; i++)
    {
        if ([items objectAtIndex:i] === aTabViewItem)
        {
            [items removeObjectAtIndex:i];
        }
    }

    [self _updateItems];
    [self _repositionTabs];

    if (delegateSelectors & CPTabViewDidChangeNumberOfTabViewItemsSelector)
        [delegate tabViewDidChangeNumberOfTabViewItems:self];
}

// Accessing Tabs
/*!
    Returns the index of the specified item
    @param aTabViewItem the item to find the index for
*/
- (int)indexOfTabViewItem:(CPTabViewItem)aTabViewItem
{
    return [items indexOfObjectIdenticalTo:aTabViewItem];
}

/*!
    Returns the index of the CPTabViewItem with the specified identifier.
    @param anIdentifier the identifier of the item
*/
- (int)indexOfTabViewItemWithIdentifier:(CPString)anIdentifier
{
    for (var index = [items count]; index >= 0; index--)
        if ([[items[index] identifier] isEqual:anIdentifier])
            return index;

    return CPNotFound;
}

/*!
    Returns the number of items in the tab view.
*/
- (unsigned)numberOfTabViewItems
{
    return [items count];
}

/*!
    Returns the CPTabViewItem at the specified index.
*/
- (CPTabViewItem)tabViewItemAtIndex:(unsigned)anIndex
{
    return [items objectAtIndex:anIndex];
}

/*!
    Returns the array of items that backs this tab view.
*/
- (CPArray)tabViewItems
{
    return [items copy]; // Copy?
}

// Selecting a Tab
/*!
    Sets the first tab view item in the array to be displayed to the user.
    @param aSender the object making this request
*/
- (void)selectFirstTabViewItem:(id)aSender
{
    if ([items count] === 0)
        return; // throw?

    [self selectTabViewItemAtIndex:0];
}

/*!
    Sets the last tab view item in the array to be displayed to the user.
    @param aSender the object making this request
*/
- (void)selectLastTabViewItem:(id)aSender
{
    if ([items count] === 0)
        return; // throw?

    [self selectTabViewItemAtIndex:[items count] - 1];
}

/*!
    Sets the next tab item in the array to be displayed.
    @param aSender the object making this request
*/
- (void)selectNextTabViewItem:(id)aSender
{
    if (selectedIndex === CPNotFound)
        return;

    var nextIndex = selectedIndex + 1;

    if (nextIndex === [items count])
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
    if (selectedIndex === CPNotFound)
        return;

    var previousIndex = selectedIndex - 1;

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
    var aTabViewItem = [items objectAtIndex:anIndex];

    if (anIndex === selectedIndex)
        return;

    var aTabViewItem = [self tabViewItemAtIndex:anIndex];

    if ((delegateSelectors & CPTabViewShouldSelectTabViewItemSelector) && ![delegate tabView:self shouldSelectTabViewItem:aTabViewItem])
        return;

    if (delegateSelectors & CPTabViewWillSelectTabViewItemSelector)
        [delegate tabView:self willSelectTabViewItem:aTabViewItem];

    [tabs selectSegmentWithTag:anIndex];
    [self _setSelectedIndex:anIndex];

    if (delegateSelectors & CPTabViewDidSelectTabViewItemSelector)
        [delegate tabView:self didSelectTabViewItem:aTabViewItem];
}

/*!
    Returns the current item being displayed.
*/
- (CPTabViewItem)selectedTabViewItem
{
    return [items objectAtIndex:selectedIndex];
}

//
/*!
    Sets the tab view type.
    @param aTabViewType the view type
*/
- (void)setTabViewType:(CPTabViewType)aTabViewType
{
    if (type === aTabViewType)
        return;

    if ((type === CPTopTabsBezelBorder || type === CPBottomTabsBezelBorder)
            && (aTabViewType !== CPTopTabsBezelBorder && aTabViewType !== CPBottomTabsBezelBorder))
        [tabs removeFromSuperview];

    if ((type === CPNoTabsBezelBorder || type === CPNoTabsLineBorder || type === CPNoTabsNoBorder)
            && (aTabViewType !== CPNoTabsBezelBorder && aTabViewType !== CPNoTabsBezelBorder && aTabViewType !== CPNoTabsNoBorder))
        [self addSubview:tabs];

    type = aTabViewType;

    switch (type)
    {
        case CPTopTabsBezelBorder:
        case CPBottomTabsBezelBorder:
        case CPNoTabsBezelBorder:
            [box setBorderType:CPBezelBorder];
            break;
        case CPNoTabsLineBorder:
            [box setBorderType:CPLineBorder];
            break;
        case CPNoTabsNoBorder:
            [box setBorderType:CPNoBorder];
            break;
    }
}

/*!
    Returns the tab view type.
*/
- (CPTabViewType)tabViewType
{
    return type;
}

/*!
    Returns the receiver's delegate.
*/
- (id)delegate
{
    return delegate;
}

/*!
    Sets the delegate for this tab view.
    @param aDelegate the tab view's delegate
*/
- (void)setDelegate:(id)aDelegate
{
    if (delegate == aDelegate)
        return;

    delegate = aDelegate;

    delegateSelectors = 0;

    if ([delegate respondsToSelector:@selector(tabView:shouldSelectTabViewItem:)])
        delegateSelectors |= CPTabViewShouldSelectTabViewItemSelector;

    if ([delegate respondsToSelector:@selector(tabView:willSelectTabViewItem:)])
        delegateSelectors |= CPTabViewWillSelectTabViewItemSelector;

    if ([delegate respondsToSelector:@selector(tabView:didSelectTabViewItem:)])
        delegateSelectors |= CPTabViewDidSelectTabViewItemSelector;

    if ([delegate respondsToSelector:@selector(tabViewDidChangeNumberOfTabViewItems:)])
        delegateSelectors |= CPTabViewDidChangeNumberOfTabViewItemsSelector;
}

- (void)setBackgroundColor:(CPColor)aColor
{
    [box setBackgroundColor:aColor];
}

- (void)mouseDown:(CPEvent)anEvent
{
    var segmentIndex = [tabs testSegment:[tabs convertPoint:[anEvent locationInWindow] fromView:nil]];

    if (segmentIndex != CPNotFound)
    {
        [self selectTabViewItemAtIndex:segmentIndex];
        [tabs trackSegment:anEvent];
    }
}

- (void)_repositionTabs
{
    var horizontalCenterOfSelf = CGRectGetWidth([self bounds]) / 2,
        verticalCenterOfTabs = CGRectGetHeight([tabs bounds]) / 2;

    if (type === CPBottomTabsBezelBorder)
        [tabs setCenter:CGPointMake(horizontalCenterOfSelf, CGRectGetHeight([self bounds]) - verticalCenterOfTabs)];
    else
        [tabs setCenter:CGPointMake(horizontalCenterOfSelf, verticalCenterOfTabs)];
}

- (void)_setSelectedIndex:(CPNumber)index
{
    selectedIndex = index;

    [box setContentView:[[items objectAtIndex:selectedIndex] view]];
}

- (void)_updateItems
{
    [tabs setSegmentCount:[items count]];

    for (var i = 0; i < [items count]; i++)
    {
        [tabs setLabel:[[items objectAtIndex:i] label] forSegment:i];
        [tabs setTag:i forSegment:i];
    }

    if (selectedIndex === CPNotFound)
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
        items   = [];

        [self _init];

        var encodedItems = [aCoder decodeObjectForKey:CPTabViewItemsKey];
        for (var i = 0; encodedItems && i < encodedItems.length; i++)
            [self insertTabViewItem:encodedItems[i] atIndex:i];

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

    [aCoder encodeObject:items forKey:CPTabViewItemsKey];;
    [aCoder encodeObject:[self selectedTabViewItem] forKey:CPTabViewSelectedItemKey];

    [aCoder encodeInt:type forKey:CPTabViewTypeKey];

    [aCoder encodeConditionalObject:delegate forKey:CPTabViewDelegateKey];
}

@end
