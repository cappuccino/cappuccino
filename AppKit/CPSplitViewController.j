/*
 * CPSplitViewController.j
 *
 * Created by Daniel Boehringer on September 2, 2025.
 * Copyright (c) 2025 [Copyright Holder]. All rights reserved.
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

var CPSplitViewControllerAutomaticDimension = -1.0;

/**
 * A container view controller that manages two or more child view
 * controllers in a split view interface.
 *
 * This class provides a controller-level abstraction for CPSplitView,
 * managing the addition, removal, and arrangement of view controllers
 * through CPSplitViewItem instances.
 *
 * This implementation was synthesized with the assistance of an LLM,
 * directed by the author.
 */
@implementation CPSplitViewController : CPViewController <CPSplitViewDelegate>
{
    /** @private The underlying split view that arranges the child views. */
    CPSplitView         _splitView;

    /** @private An array of CPSplitViewItem objects managed by this controller. */
    CPMutableArray      _splitViewItems;

    /** @private The minimum thickness for sidebars to be displayed inline. */
    CPNumber            _minimumThicknessForInlineSidebars;
}

// MARK: - Initialization

- (id)init
{
    if (self = [super init])
    {
        _splitViewItems = [CPMutableArray array];
        _minimumThicknessForInlineSidebars = 20.0;
    }
    return self;
}

// MARK: - View Lifecycle

- (void)loadView
{
    _splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0,0,400,400)];
    [self setView:_splitView];
    [_splitView setDelegate:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    for (var i = 0; i < [_splitViewItems count]; i++)
    {
        var viewController = [[_splitViewItems objectAtIndex:i] viewController];
        [[self splitView] addArrangedSubview:[viewController view]];
    }
}

// MARK: - Accessors

/**
 * Returns the CPSplitView instance managed by the controller.
 *
 * @returns {CPSplitView} The split view.
 */
- (CPSplitView)splitView
{
    return _splitView;
}

/**
 * Returns the array of split view items.
 *
 * @returns {CPArray} The array of CPSplitViewItem objects.
 */
- (CPArray)splitViewItems
{
    return _splitViewItems;
}

// MARK: - Managing Split View Items

/**
 * Adds a split view item to the end of the split view.
 *
 * @param {CPSplitViewItem} splitViewItem The split view item to add.
 */
- (void)addSplitViewItem:(CPSplitViewItem)splitViewItem
{
    [self insertSplitViewItem:splitViewItem atIndex:[_splitViewItems count]];
}

/**
 * Inserts a split view item at a specific index.
 *
 * @param {CPSplitViewItem} splitViewItem The split view item to insert.
 * @param {CPInteger} index The zero-based index at which to insert the item.
 */
- (void)insertSplitViewItem:(CPSplitViewItem)splitViewItem atIndex:(CPInteger)index
{
    [splitViewItem _setSplitViewController:self];
    [_splitViewItems insertObject:splitViewItem atIndex:index];
    [self addChildViewController:[splitViewItem viewController]];

    if ([self isViewLoaded])
        [[self splitView] insertArrangedSubview:[[splitViewItem viewController] view] atIndex:index];
}

/**
 * Removes the specified split view item.
 *
 * @param {CPSplitViewItem} splitViewItem The split view item to remove.
 */
- (void)removeSplitViewItem:(CPSplitViewItem)splitViewItem
{
    [[splitViewItem viewController] removeFromParentViewController];
    [splitViewItem _setSplitViewController:nil];
    [_splitViewItems removeObject:splitViewItem];
}

/**
 * Retrieves the split view item associated with a given view controller.
 *
 * @param {CPViewController} viewController The view controller to find.
 * @returns {CPSplitViewItem | null} The corresponding split view item, or nil if not found.
 */
- (CPSplitViewItem)splitViewItemForViewController:(CPViewController)viewController
{
    for (var i = 0; i < [_splitViewItems count]; i++)
    {
        var item = [_splitViewItems objectAtIndex:i];
        if ([item viewController] === viewController)
            return item;
    }
    return nil;
}

// MARK: - Managing Sidebars and Inspectors

/**
 * Toggles the collapsed state of the first split view item, typically a sidebar.
 *
 * @param {id} sender The object that initiated the action.
 */
- (void)toggleSidebar:(id)sender
{
    if ([_splitViewItems count] > 0)
    {
        var sidebarItem = [_splitViewItems objectAtIndex:0];
        [sidebarItem setCollapsed:![sidebarItem isCollapsed]];
    }
}

/**
 * Toggles the collapsed state of the last split view item, typically an inspector.
 *
 * @param {id} sender The object that initiated the action.
 */
- (void)toggleInspector:(id)sender
{
    if ([_splitViewItems count] > 1)
    {
        var inspectorItem = [_splitViewItems lastObject];
        [inspectorItem setCollapsed:![inspectorItem isCollapsed]];
    }
}

/**
 * Returns the minimum thickness for sidebars to be displayed inline.
 *
 * @returns {CPNumber} The minimum thickness.
 */
- (CPNumber)minimumThicknessForInlineSidebars
{
    return _minimumThicknessForInlineSidebars;
}

@end

/**
 * An object that manages a view controller within a CPSplitViewController.
 *
 * A CPSplitViewItem acts as a wrapper around a CPViewController,
 * maintaining properties like its collapsed state within the parent
 * split view controller.
 */
@implementation CPSplitViewItem : CPObject
{
    /** @private The view controller managed by this item. */
    CPViewController        _viewController;

    /** @private A boolean indicating whether the item is collapsed. */
    BOOL                    _isCollapsed;

    /** @private A weak reference to the owning split view controller. */
    CPSplitViewController   _splitViewController;
}

// MARK: - Class Methods

/**
 * Creates and returns a new split view item with the specified view controller.
 *
 * @param {CPViewController} viewController The view controller for the new item.
 * @returns {instancetype} A new CPSplitViewItem instance.
 */
+ (instancetype)splitViewItemWithViewController:(CPViewController)viewController
{
    return [[self alloc] initWithViewController:viewController];
}

// MARK: - Initialization

/**
 * Initializes a new split view item with the specified view controller.
 *
 * @param {CPViewController} viewController The view controller for the new item.
 * @returns {id} The initialized CPSplitViewItem instance.
 */
- (id)initWithViewController:(CPViewController)viewController
{
    if (self = [super init])
    {
        _viewController = viewController;
        _isCollapsed = NO;
    }
    return self;
}

// MARK: - Accessors

/**
 * Returns the view controller associated with the item.
 *
 * @returns {CPViewController} The associated view controller.
 */
- (CPViewController)viewController
{
    return _viewController;
}

/**
 * Returns a boolean value indicating whether the item is collapsed.
 *
 * @returns {BOOL} YES if the item is collapsed, otherwise NO.
 */
- (BOOL)isCollapsed
{
    return _isCollapsed;
}

/**
 * Sets the collapsed state of the item.
 * When collapsed, the view controller's view is hidden.
 *
 * @param {BOOL} shouldCollapse YES to collapse the item, NO to expand it.
 */
- (void)setCollapsed:(BOOL)shouldCollapse
{
    if (_isCollapsed === shouldCollapse)
        return;

    _isCollapsed = shouldCollapse;
    [[_viewController view] setHidden:shouldCollapse];
}

/**
 * Returns the split view controller that owns this item.
 *
 * @returns {CPSplitViewController | null} The parent split view controller.
 */
- (CPSplitViewController)splitViewController
{
    return _splitViewController;
}

/**
 * @private
 * Sets the owning split view controller. This method is for internal use by
 * CPSplitViewController.
 *
 * @param {CPSplitViewController} splitViewController The parent controller.
 */
- (void)_setSplitViewController:(CPSplitViewController)splitViewController
{
    _splitViewController = splitViewController;
}

@end
