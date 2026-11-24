/*
 * CPSplitViewController.j
 * AppKit
 *
 * Created by Daniel Boehringer on September 2, 2025.
 * Copyright (c) 2025 Daniel Boehringer. All rights reserved.
 * Reimplemented by David Richardson on 2026-11-23.
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

@import "CPViewController.j"
@import "CPSplitView.j"
@import "CPSplitViewItem.j"
@import "CPAnimationContext.j"

@class CPMenuItem

/*!
    The value of -minimumThicknessForInlineSidebars that takes the minimum from the items.
*/
CPSplitViewControllerAutomaticDimension = -1;

var CPSplitViewControllerToggleDuration = 0.25;

/*!
    @ingroup appkit
    @class CPSplitViewController

    A split view controller shows its child view controllers side by side in a split view,
    as AppKit's NSSplitViewController does. Each child has a CPSplitViewItem that describes it:
    whether it is collapsed, whether the user can collapse it, its holding priority and the
    limits of its thickness.

    The split view is the controller's view, and the controller is its delegate. Set the
    orientation, the divider style and the autosave name on the split view; manage the
    subviews, the delegate and the holding priorities through the controller and its items.
    The default split view is vertical with thin dividers.

    The child view controller methods of CPViewController work as conveniences: a child added
    with them gets an item with the default values, and a removed child loses its item.

    A subclass that overrides -viewDidLoad or one of the split view delegate methods that the
    controller implements must call super.
*/
@implementation CPSplitViewController : CPViewController
{
    CPSplitView         _splitView;
    CPMutableArray      _splitViewItems;
    float               _minimumThicknessForInlineSidebars;

    BOOL                _itemViewsAreAttached;
    BOOL                _isChangingChildren;
    BOOL                _isUpdatingInlineSidebars;
    float               _lastSplitViewThickness;
    CPMutableArray      _autoCollapsedItems;
}

- (id)initWithCibName:(CPString)aCibNameOrNil bundle:(CPBundle)aCibBundleOrNil externalNameTable:(CPDictionary)anExternalNameTable
{
    if (self = [super initWithCibName:aCibNameOrNil bundle:aCibBundleOrNil externalNameTable:anExternalNameTable])
        [self _initSplitViewController];

    return self;
}

- (void)_initSplitViewController
{
    _splitViewItems = @[];
    _minimumThicknessForInlineSidebars = CPSplitViewControllerAutomaticDimension;
    _itemViewsAreAttached = NO;
    _isChangingChildren = NO;
    _isUpdatingInlineSidebars = NO;
    _lastSplitViewThickness = -1;
    _autoCollapsedItems = @[];
}

// MARK: - The split view

/*!
    Returns the split view that the controller manages.
*/
- (CPSplitView)splitView
{
    return _splitView;
}

/*!
    Sets the split view that the controller manages. It raises
    CPInternalInconsistencyException once the controller's view is loaded.
*/
- (void)setSplitView:(CPSplitView)aSplitView
{
    if (_splitView === aSplitView)
        return;

    if (_itemViewsAreAttached)
        [CPException raise:CPInternalInconsistencyException reason:@"The split view of a split view controller cannot change after its view is loaded"];

    _splitView = aSplitView;
    [_splitView setDelegate:self];
}

/*
    Without a cib, the view is the split view, a vertical one with thin dividers unless one
    was set. With a cib, the cib's view is the split view.
*/
- (void)loadView
{
    if (_cibName)
    {
        [super loadView];

        if (!_splitView && [_view isKindOfClass:[CPSplitView class]])
            [self setSplitView:_view];

        return;
    }

    if (!_splitView)
    {
        var splitView = [[CPSplitView alloc] initWithFrame:CGRectMakeZero()];

        [splitView setVertical:YES];
        [splitView setDividerStyle:CPSplitViewDividerStyleThin];
        [splitView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [self setSplitView:splitView];
    }

    [self setView:_splitView];
}

/*!
    Adds the views of the items that are not collapsed to the split view. A subclass that
    overrides this method must call super.
*/
- (void)viewDidLoad
{
    [super viewDidLoad];

    if (!_splitView && [_view isKindOfClass:[CPSplitView class]])
        [self setSplitView:_view];

    [self _attachItemViews];
}

/*
    Adds the view of each item that is not collapsed, in the order of the items. A split view
    with no size yet takes the sum of the thicknesses of the views, so that the views keep
    their sizes until the split view is placed and resized. An item view that a cib already
    placed in the split view stays where it is.
*/
- (void)_attachItemViews
{
    if (_itemViewsAreAttached || !_splitView)
        return;

    _itemViewsAreAttached = YES;

    var sizeComponent = [_splitView isVertical] ? "width" : "height",
        otherComponent = [_splitView isVertical] ? "height" : "width",
        needed = 0,
        other = 0,
        visibleCount = 0;

    for (var i = 0, count = _splitViewItems.length; i < count; i++)
    {
        var item = _splitViewItems[i];

        if ([item isCollapsed])
            continue;

        var size = [[[item viewController] view] frameSize];

        needed += [self _initialThicknessOfItem:item available:0];
        other = MAX(other, size[otherComponent]);
        visibleCount++;
    }

    needed += MAX(0, visibleCount - 1) * [_splitView dividerThickness];

    var splitSize = CGSizeMakeCopy([_splitView frameSize]);

    if (splitSize[sizeComponent] <= 0 && ![_splitView superview])
    {
        splitSize[sizeComponent] = needed;
        splitSize[otherComponent] = MAX(splitSize[otherComponent], other);
        [_splitView setFrameSize:splitSize];
    }

    for (var i = 0, count = _splitViewItems.length; i < count; i++)
        if (![_splitViewItems[i] isCollapsed])
            [self _attachViewOfItem:_splitViewItems[i] hidden:NO];

    [_splitView adjustSubviews];
    _lastSplitViewThickness = [_splitView frameSize][sizeComponent];
}

/*
    Returns the thickness that the view of an item takes when it is added to the split view:
    its own thickness, or else the preferred part of the space available, or else the
    minimum thickness, within the minimum and the maximum.
*/
- (float)_initialThicknessOfItem:(CPSplitViewItem)anItem available:(float)anAvailableThickness
{
    var thickness = [[[anItem viewController] view] frameSize][[_splitView isVertical] ? "width" : "height"],
        minimum = [anItem minimumThickness],
        maximum = [anItem maximumThickness],
        fraction = [anItem preferredThicknessFraction];

    if (thickness <= 0 && fraction > 0 && anAvailableThickness > 0)
        thickness = ROUND(fraction * anAvailableThickness);

    if (thickness <= 0 && minimum > 0)
        thickness = minimum;

    if (minimum >= 0)
        thickness = MAX(thickness, minimum);

    if (maximum >= 0)
        thickness = MIN(thickness, maximum);

    return MAX(0, thickness);
}

/*
    Inserts the view of an item into the split view, after the views of the items before it,
    with the item's holding priority. A view that is already arranged keeps its place.
*/
- (void)_attachViewOfItem:(CPSplitViewItem)anItem hidden:(BOOL)shouldHide
{
    var view = [[anItem viewController] view];

    if (![[_splitView arrangedSubviews] containsObjectIdenticalTo:view])
    {
        var index = 0,
            itemIndex = [_splitViewItems indexOfObjectIdenticalTo:anItem],
            available = MAX(0, [_splitView frameSize][[_splitView isVertical] ? "width" : "height"] - [_splitView dividerThickness]),
            size = CGSizeMakeCopy([view frameSize]);

        for (var i = 0; i < itemIndex; i++)
            if ([self _viewOfItemIsAttached:_splitViewItems[i]])
                index++;

        size[[_splitView isVertical] ? "width" : "height"] = [self _initialThicknessOfItem:anItem available:available];
        [view setFrameSize:size];
        [view setHidden:shouldHide];
        [_splitView insertArrangedSubview:view atIndex:index];
    }

    [_splitView setHoldingPriority:[anItem holdingPriority] forSubviewAtIndex:[self _arrangedIndexOfItem:anItem]];
}

- (BOOL)_viewOfItemIsAttached:(CPSplitViewItem)anItem
{
    return [self _arrangedIndexOfItem:anItem] !== CPNotFound;
}

/*
    Returns the index of an item's view among the arranged subviews of the split view, or
    CPNotFound when the view is not loaded or not arranged.
*/
- (CPInteger)_arrangedIndexOfItem:(CPSplitViewItem)anItem
{
    var viewController = [anItem viewController];

    if (!_splitView || ![viewController isViewLoaded])
        return CPNotFound;

    return [[_splitView arrangedSubviews] indexOfObjectIdenticalTo:[viewController view]];
}

/*
    Returns the item whose view is an arranged subview, or nil.
*/
- (CPSplitViewItem)_itemOfArrangedSubview:(CPView)aView
{
    for (var i = 0, count = _splitViewItems.length; i < count; i++)
    {
        var viewController = [_splitViewItems[i] viewController];

        if ([viewController isViewLoaded] && [viewController view] === aView)
            return _splitViewItems[i];
    }

    return nil;
}

// MARK: - Items

/*!
    Returns the items of the controller, in order.
*/
- (CPArray)splitViewItems
{
    return [_splitViewItems copy];
}

/*!
    Replaces the items of the controller. Each item that is not in the new array is removed
    with -removeSplitViewItem:, and each new item is inserted with
    -insertSplitViewItem:atIndex:.
*/
- (void)setSplitViewItems:(CPArray)theItems
{
    var newItems = theItems || @[];

    for (var i = _splitViewItems.length - 1; i >= 0; i--)
        if (![newItems containsObjectIdenticalTo:_splitViewItems[i]])
            [self removeSplitViewItem:_splitViewItems[i]];

    for (var i = 0, count = [newItems count]; i < count; i++)
    {
        var item = newItems[i];

        if (_splitViewItems[i] === item)
            continue;

        if ([_splitViewItems containsObjectIdenticalTo:item])
            [self removeSplitViewItem:item];

        [self insertSplitViewItem:item atIndex:i];
    }
}

/*!
    Adds an item after the others. This calls -insertSplitViewItem:atIndex:.
*/
- (void)addSplitViewItem:(CPSplitViewItem)anItem
{
    [self insertSplitViewItem:anItem atIndex:_splitViewItems.length];
}

/*!
    Inserts an item at an index. Its view controller becomes a child of the controller. When
    the controller's view is loaded and the item is not collapsed, the item's view is loaded
    and added to the split view. A subclass must call this method to add an item.

    It raises CPInvalidArgumentException for nil, for an item without a view controller and
    for an item that is in a split view controller, and CPRangeException for an index past the
    end.
*/
- (void)insertSplitViewItem:(CPSplitViewItem)anItem atIndex:(CPInteger)anIndex
{
    if (!anItem)
        [CPException raise:CPInvalidArgumentException reason:@"-[CPSplitViewController insertSplitViewItem:atIndex:] needs an item"];

    if (![anItem viewController])
        [CPException raise:CPInvalidArgumentException reason:@"-[CPSplitViewController insertSplitViewItem:atIndex:] needs an item with a view controller"];

    if ([anItem splitViewController])
        [CPException raise:CPInvalidArgumentException reason:@"-[CPSplitViewController insertSplitViewItem:atIndex:] needs an item that is not in a split view controller"];

    if (anIndex < 0 || anIndex > _splitViewItems.length)
        [CPException raise:CPRangeException reason:@"-[CPSplitViewController insertSplitViewItem:atIndex:] index " + anIndex + " is out of range"];

    [self willChangeValueForKey:@"splitViewItems"];

    [_splitViewItems insertObject:anItem atIndex:anIndex];
    [anItem _setSplitViewController:self];

    _isChangingChildren = YES;
    [super insertChildViewController:[anItem viewController] atIndex:anIndex];
    _isChangingChildren = NO;

    if (_itemViewsAreAttached && ![anItem isCollapsed])
    {
        [self _attachViewOfItem:anItem hidden:NO];
        [_splitView adjustSubviews];
    }

    [self didChangeValueForKey:@"splitViewItems"];
}

/*!
    Removes an item. Its view leaves the split view, and the other views fill the space. A
    subclass must call this method to remove an item. It raises CPInvalidArgumentException for
    an item that is not in the controller.
*/
- (void)removeSplitViewItem:(CPSplitViewItem)anItem
{
    var index = [_splitViewItems indexOfObjectIdenticalTo:anItem];

    if (index === CPNotFound)
        [CPException raise:CPInvalidArgumentException reason:@"-[CPSplitViewController removeSplitViewItem:] needs an item of the controller"];

    [self willChangeValueForKey:@"splitViewItems"];

    if ([self _viewOfItemIsAttached:anItem])
    {
        var view = [[anItem viewController] view];

        [_splitView removeArrangedSubview:view];
        [view removeFromSuperview];
        [_splitView adjustSubviews];
    }

    [_splitViewItems removeObjectAtIndex:index];
    [_autoCollapsedItems removeObjectIdenticalTo:anItem];
    [anItem _setSplitViewController:nil];

    _isChangingChildren = YES;
    [super removeChildViewControllerAtIndex:index];
    _isChangingChildren = NO;

    [self didChangeValueForKey:@"splitViewItems"];
}

- (BOOL)automaticallyNotifiesObserversOfSplitViewItems
{
    return NO;
}

/*!
    Returns the item of a child view controller, or nil when the view controller is not a
    child of the controller.
*/
- (CPSplitViewItem)splitViewItemForViewController:(CPViewController)aViewController
{
    for (var i = 0, count = _splitViewItems.length; i < count; i++)
        if ([_splitViewItems[i] viewController] === aViewController)
            return _splitViewItems[i];

    return nil;
}

/*
    The child view controller methods add and remove items with the default values, so the
    children and the items stay in the same order.
*/
- (void)insertChildViewController:(CPViewController)aChild atIndex:(CPInteger)anIndex
{
    if (_isChangingChildren)
    {
        [super insertChildViewController:aChild atIndex:anIndex];
        return;
    }

    var item = [self splitViewItemForViewController:aChild];

    if (item)
        [self removeSplitViewItem:item];

    [self insertSplitViewItem:[CPSplitViewItem splitViewItemWithViewController:aChild] atIndex:anIndex];
}

- (void)removeChildViewControllerAtIndex:(CPInteger)anIndex
{
    if (_isChangingChildren)
    {
        [super removeChildViewControllerAtIndex:anIndex];
        return;
    }

    if (anIndex < 0 || anIndex >= _splitViewItems.length)
        [CPException raise:CPRangeException reason:@"-[CPSplitViewController removeChildViewControllerAtIndex:] index " + anIndex + " is out of range"];

    [self removeSplitViewItem:_splitViewItems[anIndex]];
}

// MARK: - Changes from the items

/*
    Collapses or expands the view of an item. A collapsed view is hidden and keeps its size;
    the split view gives its space to the other views by their holding priorities, and takes
    the space for an expansion from them in the same way. An item whose view was never loaded
    loads it at its first expansion. With an animation, the split view animates every view
    that the change moves.

    The collapse behaviors that resize the window are not supported: every collapse resizes
    the siblings in a split view of a fixed size.
*/
- (void)_splitViewItemDidChangeCollapsed:(CPSplitViewItem)anItem animated:(BOOL)shouldAnimate
{
    if (!_isUpdatingInlineSidebars)
        [_autoCollapsedItems removeObjectIdenticalTo:anItem];

    if (!_itemViewsAreAttached)
        return;

    var shouldCollapse = [anItem isCollapsed];

    if (!shouldCollapse && ![self _viewOfItemIsAttached:anItem])
        [self _attachViewOfItem:anItem hidden:YES];

    if (![self _viewOfItemIsAttached:anItem])
        return;

    var view = [[anItem viewController] view],
        change = function()
        {
            [view setHidden:shouldCollapse];
            [_splitView adjustSubviews];
        };

    if (shouldAnimate)
        [_splitView _animateLayoutChange:change];
    else
        change();
}

- (void)_splitViewItemDidChangeHoldingPriority:(CPSplitViewItem)anItem
{
    var index = [self _arrangedIndexOfItem:anItem];

    if (index !== CPNotFound)
        [_splitView setHoldingPriority:[anItem holdingPriority] forSubviewAtIndex:index];
}

// MARK: - Sidebars and inspectors

/*!
    Returns the thickness of the split view below which sidebars collapse, and at or above
    which the sidebars it collapsed expand again. The default,
    CPSplitViewControllerAutomaticDimension, takes the sum of the minimum thicknesses of the
    items that are not collapsed, and of their dividers.
*/
- (float)minimumThicknessForInlineSidebars
{
    return _minimumThicknessForInlineSidebars;
}

- (void)setMinimumThicknessForInlineSidebars:(float)aThickness
{
    _minimumThicknessForInlineSidebars = aThickness;
    [self _updateInlineSidebars];
}

/*!
    Collapses or expands the first sidebar with an animation. It does nothing when there is no
    sidebar.
*/
- (void)toggleSidebar:(id)aSender
{
    [self _toggleFirstItemWithBehavior:CPSplitViewItemBehaviorSidebar];
}

/*!
    Collapses or expands the first inspector with an animation. It does nothing when there is
    no inspector.
*/
- (void)toggleInspector:(id)aSender
{
    [self _toggleFirstItemWithBehavior:CPSplitViewItemBehaviorInspector];
}

- (CPSplitViewItem)_firstItemWithBehavior:(CPSplitViewItemBehavior)aBehavior
{
    for (var i = 0, count = _splitViewItems.length; i < count; i++)
        if ([_splitViewItems[i] behavior] === aBehavior)
            return _splitViewItems[i];

    return nil;
}

- (void)_toggleFirstItemWithBehavior:(CPSplitViewItemBehavior)aBehavior
{
    var item = [self _firstItemWithBehavior:aBehavior];

    if (!item)
        return;

    [CPAnimationContext runAnimationGroup:function(aContext)
    {
        [aContext setDuration:CPSplitViewControllerToggleDuration];
        [[item animator] setCollapsed:![item isCollapsed]];
    }
    completionHandler:nil];
}

/*!
    Enables the toggleSidebar: and toggleInspector: actions when there is an item to toggle,
    and gives a menu item the title for the next toggle. Other actions are enabled.
*/
- (BOOL)validateUserInterfaceItem:(id)anItem
{
    var action = [anItem action],
        behavior,
        noun;

    if (action === @selector(toggleSidebar:))
    {
        behavior = CPSplitViewItemBehaviorSidebar;
        noun = @"Sidebar";
    }
    else if (action === @selector(toggleInspector:))
    {
        behavior = CPSplitViewItemBehaviorInspector;
        noun = @"Inspector";
    }
    else
        return YES;

    var item = [self _firstItemWithBehavior:behavior];

    if (item && [anItem isKindOfClass:[CPMenuItem class]])
        [anItem setTitle:([item isCollapsed] ? @"Show " : @"Hide ") + noun];

    return !!item;
}

/*
    Collapses the sidebars that can collapse from a resize when the split view becomes thinner
    than the minimum for inline sidebars, and expands them again when it becomes thick enough.
    A sidebar that the user or the application collapses or expands is no longer expanded
    automatically.
*/
- (void)_updateInlineSidebars
{
    if (!_itemViewsAreAttached || _isUpdatingInlineSidebars)
        return;

    _isUpdatingInlineSidebars = YES;

    var thickness = [_splitView frameSize][[_splitView isVertical] ? "width" : "height"],
        minimum = [self _effectiveMinimumThicknessForInlineSidebars];

    if (thickness < minimum)
    {
        for (var i = 0, count = _splitViewItems.length; i < count; i++)
        {
            var item = _splitViewItems[i];

            if ([item behavior] !== CPSplitViewItemBehaviorSidebar || [item isCollapsed] || ![item canCollapseFromWindowResize])
                continue;

            [_autoCollapsedItems addObject:item];
            [item setCollapsed:YES];
        }
    }
    else if (_autoCollapsedItems.length)
    {
        var items = [_autoCollapsedItems copy];

        [_autoCollapsedItems removeAllObjects];

        for (var i = 0, count = items.length; i < count; i++)
            [items[i] setCollapsed:NO];
    }

    _isUpdatingInlineSidebars = NO;
}

/*
    Returns the explicit minimum for inline sidebars, or else the sum of the minimum
    thicknesses of the items that are not collapsed, with the sidebars that were collapsed
    automatically, and of the dividers between them. With the automatic value and no
    minimum thicknesses, sidebars never collapse automatically.
*/
- (float)_effectiveMinimumThicknessForInlineSidebars
{
    if (_minimumThicknessForInlineSidebars !== CPSplitViewControllerAutomaticDimension)
        return _minimumThicknessForInlineSidebars;

    var total = 0,
        count = 0;

    for (var i = 0, itemCount = _splitViewItems.length; i < itemCount; i++)
    {
        var item = _splitViewItems[i];

        if ([item isCollapsed] && ![_autoCollapsedItems containsObjectIdenticalTo:item])
            continue;

        total += MAX(0, [item minimumThickness]);
        count++;
    }

    if (total === 0)
        return 0;

    return total + MAX(0, count - 1) * [_splitView dividerThickness];
}

// MARK: - Split view delegate

/*!
    Lets the user collapse the views of the items that can collapse.
*/
- (BOOL)splitView:(CPSplitView)aSplitView canCollapseSubview:(CPView)aSubview
{
    return !![[self _itemOfArrangedSubview:aSubview] canCollapse];
}

/*!
    Returns NO: a double click on a divider does not collapse a view, as in AppKit.
*/
- (BOOL)splitView:(CPSplitView)aSplitView shouldCollapseSubview:(CPView)aSubview forDoubleClickOnDividerAtIndex:(CPInteger)aDividerIndex
{
    return NO;
}

/*!
    Hides the first divider when the first view is collapsed and the last divider when the
    last view is collapsed.
*/
- (BOOL)splitView:(CPSplitView)aSplitView shouldHideDividerAtIndex:(CPInteger)aDividerIndex
{
    var arranged = [aSplitView arrangedSubviews],
        count = [arranged count];

    if (aDividerIndex === 0 && [arranged[0] isHidden])
        return YES;

    if (aDividerIndex === count - 2 && [arranged[count - 1] isHidden])
        return YES;

    return NO;
}

/*!
    Keeps a dragged divider where the view before it has at least its minimum thickness and the
    view after it at most its maximum thickness.
*/
- (float)splitView:(CPSplitView)aSplitView constrainMinCoordinate:(float)aProposedMinimum ofSubviewAt:(CPInteger)aDividerIndex
{
    var arranged = [aSplitView arrangedSubviews],
        before = [self _itemOfArrangedSubview:arranged[aDividerIndex]],
        after = [self _itemOfArrangedSubview:arranged[aDividerIndex + 1]],
        minimum = aProposedMinimum;

    if (before && [before minimumThickness] >= 0)
        minimum = MAX(minimum, aProposedMinimum + [before minimumThickness]);

    if (after && [after maximumThickness] >= 0)
        minimum = MAX(minimum, [aSplitView maxPossiblePositionOfDividerAtIndex:aDividerIndex] - [after maximumThickness]);

    return minimum;
}

/*!
    Keeps a dragged divider where the view before it has at most its maximum thickness and the
    view after it at least its minimum thickness.
*/
- (float)splitView:(CPSplitView)aSplitView constrainMaxCoordinate:(float)aProposedMaximum ofSubviewAt:(CPInteger)aDividerIndex
{
    var arranged = [aSplitView arrangedSubviews],
        before = [self _itemOfArrangedSubview:arranged[aDividerIndex]],
        after = [self _itemOfArrangedSubview:arranged[aDividerIndex + 1]],
        maximum = aProposedMaximum;

    if (before && [before maximumThickness] >= 0)
        maximum = MIN(maximum, [aSplitView minPossiblePositionOfDividerAtIndex:aDividerIndex] + [before maximumThickness]);

    if (after && [after minimumThickness] >= 0)
        maximum = MIN(maximum, aProposedMaximum - [after minimumThickness]);

    return maximum;
}

/*!
    Returns the proposed rect. A subclass can widen it and must call super.
*/
- (CGRect)splitView:(CPSplitView)aSplitView effectiveRect:(CGRect)aProposedEffectiveRect forDrawnRect:(CGRect)aDrawnRect ofDividerAtIndex:(CPInteger)aDividerIndex
{
    return aProposedEffectiveRect;
}

/*!
    Returns an empty rect. A subclass can add a rect and must call super.
*/
- (CGRect)splitView:(CPSplitView)aSplitView additionalEffectiveRectOfDividerAtIndex:(CPInteger)aDividerIndex
{
    return CGRectMakeZero();
}

/*!
    Records the collapses and expansions that the user made, and collapses or expands
    sidebars when the thickness of the split view changes.
*/
- (void)splitViewDidResizeSubviews:(CPNotification)aNotification
{
    if (!_isUpdatingInlineSidebars)
    {
        var arranged = [_splitView arrangedSubviews];

        for (var i = 0, count = [arranged count]; i < count; i++)
        {
            var item = [self _itemOfArrangedSubview:arranged[i]],
                isHidden = !![arranged[i] isHidden];

            if (!item || [item isCollapsed] === isHidden)
                continue;

            [_autoCollapsedItems removeObjectIdenticalTo:item];
            [item _noteCollapsed:isHidden];
        }
    }

    var thickness = [_splitView frameSize][[_splitView isVertical] ? "width" : "height"];

    if (_itemViewsAreAttached && thickness !== _lastSplitViewThickness)
    {
        _lastSplitViewThickness = thickness;
        [self _updateInlineSidebars];
    }
}

@end

// MARK: - Archiving

var CPSplitViewControllerSplitViewItemsKey                      = @"CPSplitViewControllerSplitViewItemsKey",
    CPSplitViewControllerSplitViewKey                           = @"CPSplitViewControllerSplitViewKey",
    CPSplitViewControllerMinimumThicknessForInlineSidebarsKey   = @"CPSplitViewControllerMinimumThicknessForInlineSidebarsKey";

@implementation CPSplitViewController (CPCoding)

/*
    The items come from the archive; the children that CPViewController decodes are their view
    controllers, in the same order. The item views that the archived split view arranges stay
    in place, and -viewDidLoad adds the others.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        [self _initSplitViewController];

        var items = [aCoder decodeObjectForKey:CPSplitViewControllerSplitViewItemsKey] || @[];

        _splitViewItems = [items mutableCopy];

        for (var i = 0, count = _splitViewItems.length; i < count; i++)
            [_splitViewItems[i] _setSplitViewController:self];

        if ([aCoder containsValueForKey:CPSplitViewControllerMinimumThicknessForInlineSidebarsKey])
            _minimumThicknessForInlineSidebars = [aCoder decodeFloatForKey:CPSplitViewControllerMinimumThicknessForInlineSidebarsKey];

        var splitView = [aCoder decodeObjectForKey:CPSplitViewControllerSplitViewKey];

        if (splitView)
            [self setSplitView:splitView];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_splitViewItems forKey:CPSplitViewControllerSplitViewItemsKey];
    [aCoder encodeObject:_splitView forKey:CPSplitViewControllerSplitViewKey];
    [aCoder encodeFloat:_minimumThicknessForInlineSidebars forKey:CPSplitViewControllerMinimumThicknessForInlineSidebarsKey];
}

@end
