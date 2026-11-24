/*
 *  CPSplitViewControllerTest.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-23.
 *  Copyright David Richardson 2026.
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

@import <AppKit/CPApplication.j>
@import <AppKit/CPMenuItem.j>
@import <AppKit/CPSplitViewController.j>

@class _CPSplitViewControllerTestChild
@class _CPSplitViewControllerTestObserver

/*
    These tests state how a split view controller and its items behave as AppKit's
    NSSplitViewController and NSSplitViewItem do: the items and the child view controllers,
    the split view and its arranged subviews, the values of each item behavior, collapsing and
    expanding, holding priorities, thickness limits, sidebars and inspectors, validation and
    archiving.

    Most tests use a controller with a sidebar 100 points wide and a content item 199 points
    wide, both 100 points high. When the view loads, the split view takes the sum of their
    widths and the thin divider between them (1 point under ojtest, where no theme is loaded):
    300 by 100. The sidebar is at x = 0, the divider at x = 100 and the content at x = 101.
*/
@implementation CPSplitViewControllerTest : OJTestCase
{
    CPSplitViewController   controller;
    CPViewController        sidebarChild;
    CPViewController        contentChild;
    CPSplitViewItem         sidebarItem;
    CPSplitViewItem         contentItem;
}

- (void)setUp
{
    [[CPApplication alloc] init];

    controller = [[CPSplitViewController alloc] init];
    sidebarChild = [[_CPSplitViewControllerTestChild alloc] initWithWidth:100];
    contentChild = [[_CPSplitViewControllerTestChild alloc] initWithWidth:199];
    sidebarItem = [CPSplitViewItem sidebarWithViewController:sidebarChild];
    contentItem = [CPSplitViewItem splitViewItemWithViewController:contentChild];
}

- (void)loadTwoItems
{
    [controller addSplitViewItem:sidebarItem];
    [controller addSplitViewItem:contentItem];
    [controller view];
}

- (void)assertFrame:(CGRect)aFrame of:(CPView)aView named:(CPString)aName
{
    [self assertTrue:CGRectEqualToRect(aFrame, [aView frame]) message:aName + @": expected " + CPStringFromRect(aFrame) + @", got " + CPStringFromRect([aView frame])];
}

// MARK: - The controller and its view

- (void)testANewControllerHasNoItemsAndNoSplitView
{
    [self assert:0 equals:[[controller splitViewItems] count] message:@"no items"];
    [self assertNull:[controller splitView] message:@"no split view before the view loads"];
}

- (void)testTheViewIsAVerticalSplitViewWithThinDividersAndTheControllerAsDelegate
{
    var view = [controller view];

    [self assertTrue:[view isKindOfClass:[CPSplitView class]] message:@"the view is a split view"];
    [self assert:view equals:[controller splitView] message:@"the split view is the view"];
    [self assertTrue:[view isVertical] message:@"the split view is vertical"];
    [self assert:CPSplitViewDividerStyleThin equals:[view dividerStyle] message:@"the dividers are thin"];
    [self assert:controller equals:[view delegate] message:@"the controller is the delegate"];
}

- (void)testAControllerUsesASplitViewSetBeforeTheViewLoads
{
    var splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];

    [controller setSplitView:splitView];

    [self assert:splitView equals:[controller view] message:@"the set split view is the view"];
    [self assert:controller equals:[splitView delegate] message:@"the controller is its delegate"];
}

- (void)testTheSplitViewCannotChangeAfterTheViewLoads
{
    [controller view];

    var raised = nil;

    try
    {
        [controller setSplitView:[[CPSplitView alloc] initWithFrame:CGRectMakeZero()]];
    }
    catch (anException)
    {
        raised = [anException name];
    }

    [self assert:CPInternalInconsistencyException equals:raised message:@"a new split view raises"];
}

// MARK: - Item values

- (void)testADefaultItemHasTheDefaultValues
{
    [self assert:contentChild equals:[contentItem viewController] message:@"the view controller"];
    [self assert:CPSplitViewItemBehaviorDefault equals:[contentItem behavior] message:@"the behavior"];
    [self assertFalse:[contentItem isCollapsed] message:@"not collapsed"];
    [self assertFalse:[contentItem canCollapse] message:@"cannot collapse"];
    [self assertFalse:[contentItem canCollapseFromWindowResize] message:@"cannot collapse from a resize"];
    [self assert:250 equals:[contentItem holdingPriority] message:@"the holding priority"];
    [self assert:CPSplitViewItemUnspecifiedDimension equals:[contentItem minimumThickness] message:@"no minimum"];
    [self assert:CPSplitViewItemUnspecifiedDimension equals:[contentItem maximumThickness] message:@"no maximum"];
    [self assert:CPSplitViewItemUnspecifiedDimension equals:[contentItem preferredThicknessFraction] message:@"no preferred fraction"];
    [self assertFalse:[contentItem isSpringLoaded] message:@"not spring loaded"];
    [self assertTrue:[contentItem allowsFullHeightLayout] message:@"allows full height layout"];
    [self assertNull:[contentItem splitViewController] message:@"no controller"];
}

- (void)testASidebarCanCollapseAndPrefersFifteenPercent
{
    [self assert:CPSplitViewItemBehaviorSidebar equals:[sidebarItem behavior] message:@"the behavior"];
    [self assertTrue:[sidebarItem canCollapse] message:@"can collapse"];
    [self assertTrue:[sidebarItem canCollapseFromWindowResize] message:@"can collapse from a resize"];
    [self assertTrue:[sidebarItem isSpringLoaded] message:@"spring loaded"];
    [self assert:0.15 equals:[sidebarItem preferredThicknessFraction] message:@"the preferred fraction"];

    [sidebarItem setCanCollapse:NO];
    [self assertFalse:[sidebarItem canCollapseFromWindowResize] message:@"canCollapse also sets canCollapseFromWindowResize for a sidebar"];
}

- (void)testAContentListPrefersTwentyEightPercent
{
    var item = [CPSplitViewItem contentListWithViewController:contentChild];

    [self assert:CPSplitViewItemBehaviorContentList equals:[item behavior] message:@"the behavior"];
    [self assertFalse:[item canCollapse] message:@"cannot collapse"];
    [self assert:0.28 equals:[item preferredThicknessFraction] message:@"the preferred fraction"];
}

- (void)testAnInspectorCanCollapseAndHasAFixedThickness
{
    var item = [CPSplitViewItem inspectorWithViewController:contentChild];

    [self assert:CPSplitViewItemBehaviorInspector equals:[item behavior] message:@"the behavior"];
    [self assertTrue:[item canCollapse] message:@"can collapse"];
    [self assertFalse:[item canCollapseFromWindowResize] message:@"cannot collapse from a resize"];
    [self assert:270 equals:[item minimumThickness] message:@"the minimum"];
    [self assert:270 equals:[item maximumThickness] message:@"the maximum"];
}

- (void)testAnItemOutsideAControllerOnlyRecordsItsCollapsedState
{
    [contentItem setCollapsed:YES];

    [self assertTrue:[contentItem isCollapsed] message:@"the item is collapsed"];
    [self assertFalse:[contentChild isViewLoaded] message:@"the view does not load"];
}

// MARK: - Items, children and arranged subviews

- (void)testItemsBecomeChildrenAndArrangedSubviews
{
    [self loadTwoItems];

    [self assert:[sidebarItem, contentItem] equals:[controller splitViewItems] message:@"the items in order"];
    [self assert:[sidebarChild, contentChild] equals:[controller childViewControllers] message:@"the children in order"];
    [self assert:controller equals:[sidebarItem splitViewController] message:@"the item knows its controller"];
    [self assert:controller equals:[sidebarChild parentViewController] message:@"the child knows its parent"];
    [self assert:[[sidebarChild view], [contentChild view]] equals:[[controller splitView] arrangedSubviews] message:@"the arranged subviews"];
    [self assert:sidebarItem equals:[controller splitViewItemForViewController:sidebarChild] message:@"the item of a child"];
    [self assertNull:[controller splitViewItemForViewController:[[CPViewController alloc] init]] message:@"no item for another view controller"];
}

- (void)testTheSplitViewTakesTheSizeOfTheItemViewsWhenTheViewLoads
{
    [self loadTwoItems];

    [self assertFrame:CGRectMake(0, 0, 300, 100) of:[controller splitView] named:@"the split view"];
    [self assertFrame:CGRectMake(0, 0, 100, 100) of:[sidebarChild view] named:@"the sidebar"];
    [self assertFrame:CGRectMake(101, 0, 199, 100) of:[contentChild view] named:@"the content"];
}

- (void)testItemsAddedBeforeTheViewLoadsAreChildrenAtOnce
{
    [controller addSplitViewItem:sidebarItem];

    [self assert:[sidebarChild] equals:[controller childViewControllers] message:@"the child is added at once"];
    [self assertFalse:[sidebarChild isViewLoaded] message:@"its view does not load yet"];
}

- (void)testAnInsertedItemTakesItsPlaceInTheSplitView
{
    [self loadTwoItems];

    var otherChild = [[_CPSplitViewControllerTestChild alloc] initWithWidth:50],
        otherItem = [CPSplitViewItem splitViewItemWithViewController:otherChild];

    [controller insertSplitViewItem:otherItem atIndex:1];

    [self assert:[sidebarItem, otherItem, contentItem] equals:[controller splitViewItems] message:@"the items in order"];
    [self assert:[[sidebarChild view], [otherChild view], [contentChild view]] equals:[[controller splitView] arrangedSubviews] message:@"the arranged subviews in order"];
}

- (void)testARemovedItemLeavesTheSplitViewAndTheChildren
{
    [self loadTwoItems];

    [controller removeSplitViewItem:sidebarItem];

    [self assert:[contentItem] equals:[controller splitViewItems] message:@"the items"];
    [self assert:[contentChild] equals:[controller childViewControllers] message:@"the children"];
    [self assertNull:[sidebarItem splitViewController] message:@"the item has no controller"];
    [self assertNull:[sidebarChild parentViewController] message:@"the child has no parent"];
    [self assertNull:[[sidebarChild view] superview] message:@"the view leaves the split view"];
    [self assertFrame:CGRectMake(0, 0, 300, 100) of:[contentChild view] named:@"the content fills the split view"];
}

- (void)testTheChildMethodsAddAndRemoveDefaultItems
{
    [controller view];
    [controller addChildViewController:contentChild];

    var item = [controller splitViewItemForViewController:contentChild];

    [self assertNotNull:item message:@"an added child gets an item"];
    [self assert:CPSplitViewItemBehaviorDefault equals:[item behavior] message:@"the item has the default behavior"];
    [self assert:[[contentChild view]] equals:[[controller splitView] arrangedSubviews] message:@"its view is arranged"];

    [contentChild removeFromParentViewController];

    [self assert:0 equals:[[controller splitViewItems] count] message:@"a removed child loses its item"];
}

- (void)testSettingTheItemsReplacesThem
{
    [self loadTwoItems];

    var otherItem = [CPSplitViewItem splitViewItemWithViewController:[[_CPSplitViewControllerTestChild alloc] initWithWidth:50]];

    [controller setSplitViewItems:[contentItem, otherItem]];

    [self assert:[contentItem, otherItem] equals:[controller splitViewItems] message:@"the new items"];
    [self assertNull:[sidebarItem splitViewController] message:@"the dropped item has no controller"];
}

- (void)testInvalidInsertionsRaise
{
    var names = [],
        attempts = [
            function() { [controller addSplitViewItem:nil]; },
            function() { [controller addSplitViewItem:[CPSplitViewItem splitViewItemWithViewController:nil]]; },
            function() { [controller insertSplitViewItem:contentItem atIndex:1]; },
            function() { [controller removeSplitViewItem:contentItem]; }
        ];

    for (var i = 0; i < attempts.length; i++)
    {
        try
        {
            attempts[i]();
            names.push("none");
        }
        catch (anException)
        {
            names.push([anException name]);
        }
    }

    [self assert:[CPInvalidArgumentException, CPInvalidArgumentException, CPRangeException, CPInvalidArgumentException] equals:names message:@"each invalid call raises"];
}

- (void)testTheViewControllerOfAnAddedItemCannotChange
{
    [controller addSplitViewItem:contentItem];

    var raised = nil;

    try
    {
        [contentItem setViewController:sidebarChild];
    }
    catch (anException)
    {
        raised = [anException name];
    }

    [self assert:CPInternalInconsistencyException equals:raised message:@"a new view controller raises"];
}

// MARK: - Collapsing

- (void)testACollapsedItemIsHiddenKeepsItsSizeAndHidesItsOuterDivider
{
    [self loadTwoItems];

    [sidebarItem setCollapsed:YES];

    var splitView = [controller splitView];

    [self assertTrue:[[sidebarChild view] isHidden] message:@"the sidebar is hidden"];
    [self assertTrue:[splitView isSubviewCollapsed:[sidebarChild view]] message:@"the split view sees it collapsed"];
    [self assert:100 equals:CGRectGetWidth([[sidebarChild view] frame]) message:@"the sidebar keeps its width"];
    [self assert:0 equals:CGRectGetWidth([splitView rectOfDividerAtIndex:0]) message:@"the divider beside it is hidden"];
    [self assertFrame:CGRectMake(0, 0, 300, 100) of:[contentChild view] named:@"the content fills the split view"];
}

- (void)testAnExpandedItemTakesBackItsSize
{
    [self loadTwoItems];

    [sidebarItem setCollapsed:YES];
    [sidebarItem setCollapsed:NO];

    [self assertFalse:[[sidebarChild view] isHidden] message:@"the sidebar is shown"];
    [self assertFrame:CGRectMake(0, 0, 100, 100) of:[sidebarChild view] named:@"the sidebar"];
    [self assertFrame:CGRectMake(101, 0, 199, 100) of:[contentChild view] named:@"the content"];
}

- (void)testAnItemCollapsedWhenAddedLoadsItsViewAtItsFirstExpansion
{
    [sidebarItem setCollapsed:YES];
    [self loadTwoItems];

    [self assertFalse:[sidebarChild isViewLoaded] message:@"the view of the collapsed item does not load"];
    [self assert:[[contentChild view]] equals:[[controller splitView] arrangedSubviews] message:@"only the content is arranged"];

    [sidebarItem setCollapsed:NO];

    [self assertTrue:[sidebarChild isViewLoaded] message:@"the expansion loads the view"];
    [self assert:[[sidebarChild view], [contentChild view]] equals:[[controller splitView] arrangedSubviews] message:@"the sidebar is arranged first"];
    [self assertFalse:[[sidebarChild view] isHidden] message:@"the sidebar is shown"];
}

- (void)testAUserCollapseUpdatesTheItemAndItsObservers
{
    [self loadTwoItems];

    var observer = [[_CPSplitViewControllerTestObserver alloc] init];

    [sidebarItem addObserver:observer forKeyPath:@"collapsed" options:0 context:nil];
    [[controller splitView] setPosition:0 ofDividerAtIndex:0];
    [sidebarItem removeObserver:observer forKeyPath:@"collapsed"];

    [self assertTrue:[sidebarItem isCollapsed] message:@"the item is collapsed"];
    [self assert:1 equals:observer.count message:@"observers learn of the collapse"];
}

- (void)testOnlyAnItemThatCanCollapseCollapsesFromADrag
{
    [self loadTwoItems];

    [[controller splitView] setPosition:300 ofDividerAtIndex:0];

    [self assertFalse:[contentItem isCollapsed] message:@"the content cannot collapse"];
    [self assertFalse:[[contentChild view] isHidden] message:@"the content stays visible"];
}

- (void)testTheAnimatorCollapsesTheItem
{
    [self loadTwoItems];

    [CPAnimationContext runAnimationGroup:function(aContext)
    {
        [aContext setDuration:0.25];
        [[sidebarItem animator] setCollapsed:YES];
    }
    completionHandler:nil];

    [self assertTrue:[sidebarItem isCollapsed] message:@"the item is collapsed"];
    [self assertTrue:[[sidebarChild view] isHidden] message:@"the sidebar is hidden"];
    [self assertFrame:CGRectMake(0, 0, 300, 100) of:[contentChild view] named:@"the content fills the split view"];
}

// MARK: - Sizes

- (void)testTheHoldingPriorityDecidesWhichItemTakesAResize
{
    [self loadTwoItems];

    [sidebarItem setHoldingPriority:260];
    [[controller splitView] setFrameSize:CGSizeMake(400, 100)];

    [self assert:260 equals:[[controller splitView] holdingPriorityForSubviewAtIndex:0] message:@"the split view has the item's priority"];
    [self assertFrame:CGRectMake(0, 0, 100, 100) of:[sidebarChild view] named:@"the sidebar keeps its width"];
    [self assertFrame:CGRectMake(101, 0, 299, 100) of:[contentChild view] named:@"the content takes the change"];
}

- (void)testTheThicknessLimitsOfTheItemsLimitADrag
{
    [sidebarItem setMinimumThickness:80];
    [sidebarItem setMaximumThickness:150];
    [contentItem setMinimumThickness:180];
    [self loadTwoItems];

    var splitView = [controller splitView];

    [splitView setPosition:200 ofDividerAtIndex:0];
    [self assert:119 equals:CGRectGetMinX([splitView rectOfDividerAtIndex:0]) message:@"the content keeps its minimum"];

    [contentItem setMinimumThickness:CPSplitViewItemUnspecifiedDimension];
    [splitView setPosition:200 ofDividerAtIndex:0];
    [self assert:150 equals:CGRectGetMinX([splitView rectOfDividerAtIndex:0]) message:@"the sidebar keeps its maximum"];

    [splitView setPosition:85 ofDividerAtIndex:0];
    [self assert:85 equals:CGRectGetMinX([splitView rectOfDividerAtIndex:0]) message:@"a position inside the limits"];

    [sidebarItem setCanCollapse:NO];
    [splitView setPosition:20 ofDividerAtIndex:0];
    [self assert:80 equals:CGRectGetMinX([splitView rectOfDividerAtIndex:0]) message:@"the sidebar keeps its minimum"];
}

- (void)testASidebarCollapsesWhenTheSplitViewBecomesThinnerThanTheMinimum
{
    [self loadTwoItems];
    [controller setMinimumThicknessForInlineSidebars:250];

    var splitView = [controller splitView];

    [splitView setFrameSize:CGSizeMake(240, 100)];
    [self assertTrue:[sidebarItem isCollapsed] message:@"the sidebar collapses"];

    [splitView setFrameSize:CGSizeMake(300, 100)];
    [self assertFalse:[sidebarItem isCollapsed] message:@"the sidebar expands again"];
}

- (void)testAnAutomaticMinimumComesFromTheMinimumThicknesses
{
    [sidebarItem setMinimumThickness:80];
    [contentItem setMinimumThickness:150];
    [self loadTwoItems];

    [self assert:CPSplitViewControllerAutomaticDimension equals:[controller minimumThicknessForInlineSidebars] message:@"the default is automatic"];

    [[controller splitView] setFrameSize:CGSizeMake(230, 100)];
    [self assertTrue:[sidebarItem isCollapsed] message:@"below 80 + 1 + 150 the sidebar collapses"];

    [[controller splitView] setFrameSize:CGSizeMake(231, 100)];
    [self assertFalse:[sidebarItem isCollapsed] message:@"at 231 it expands again"];
}

// MARK: - Sidebars and inspectors

- (void)testToggleSidebarTogglesTheFirstSidebar
{
    [controller addSplitViewItem:contentItem];
    [controller addSplitViewItem:sidebarItem];
    [controller view];

    [controller toggleSidebar:nil];
    [self assertTrue:[sidebarItem isCollapsed] message:@"the sidebar collapses"];
    [self assertFalse:[contentItem isCollapsed] message:@"the first item is not a sidebar"];

    [controller toggleSidebar:nil];
    [self assertFalse:[sidebarItem isCollapsed] message:@"the sidebar expands"];
}

- (void)testToggleInspectorTogglesTheFirstInspector
{
    var inspectorChild = [[_CPSplitViewControllerTestChild alloc] initWithWidth:270],
        inspectorItem = [CPSplitViewItem inspectorWithViewController:inspectorChild];

    [self loadTwoItems];
    [controller addSplitViewItem:inspectorItem];

    [controller toggleInspector:nil];
    [self assertTrue:[inspectorItem isCollapsed] message:@"the inspector collapses"];
    [self assertFalse:[sidebarItem isCollapsed] message:@"the sidebar does not"];
}

- (void)testTogglesWithoutAMatchingItemDoNothing
{
    [controller addSplitViewItem:contentItem];
    [controller view];

    [controller toggleSidebar:nil];
    [controller toggleInspector:nil];

    [self assertFalse:[contentItem isCollapsed] message:@"the default item does not collapse"];
}

- (void)testValidationEnablesTheToggleAndGivesTheMenuItemItsTitle
{
    var menuItem = [[CPMenuItem alloc] initWithTitle:@"Sidebar" action:@selector(toggleSidebar:) keyEquivalent:@""];

    [self loadTwoItems];

    [self assertTrue:[controller validateUserInterfaceItem:menuItem] message:@"enabled with a sidebar"];
    [self assert:@"Hide Sidebar" equals:[menuItem title] message:@"the title when the sidebar is visible"];

    [sidebarItem setCollapsed:YES];
    [controller validateUserInterfaceItem:menuItem];
    [self assert:@"Show Sidebar" equals:[menuItem title] message:@"the title when the sidebar is collapsed"];

    var inspectorMenuItem = [[CPMenuItem alloc] initWithTitle:@"Inspector" action:@selector(toggleInspector:) keyEquivalent:@""];

    [self assertFalse:[controller validateUserInterfaceItem:inspectorMenuItem] message:@"disabled without an inspector"];
}

// MARK: - Archiving

- (void)testAnItemIsArchivedWithItsValues
{
    [sidebarItem setHoldingPriority:260];
    [sidebarItem setMinimumThickness:80];
    [sidebarItem setMaximumThickness:300];
    [sidebarItem setCollapseBehavior:CPSplitViewItemCollapseBehaviorPreferResizingSiblingsWithFixedSplitView];
    [sidebarItem setAllowsFullHeightLayout:NO];
    [sidebarItem setTitlebarSeparatorStyle:CPTitlebarSeparatorStyleLine];
    [sidebarItem setCollapsed:YES];

    var copy = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:sidebarItem]];

    [self assert:CPSplitViewItemBehaviorSidebar equals:[copy behavior] message:@"the behavior"];
    [self assertTrue:[copy isCollapsed] message:@"collapsed"];
    [self assertTrue:[copy canCollapse] message:@"can collapse"];
    [self assertTrue:[copy isSpringLoaded] message:@"spring loaded"];
    [self assert:260 equals:[copy holdingPriority] message:@"the holding priority"];
    [self assert:80 equals:[copy minimumThickness] message:@"the minimum"];
    [self assert:300 equals:[copy maximumThickness] message:@"the maximum"];
    [self assert:0.15 equals:[copy preferredThicknessFraction] message:@"the preferred fraction"];
    [self assert:CPSplitViewItemCollapseBehaviorPreferResizingSiblingsWithFixedSplitView equals:[copy collapseBehavior] message:@"the collapse behavior"];
    [self assertFalse:[copy allowsFullHeightLayout] message:@"full height layout"];
    [self assert:CPTitlebarSeparatorStyleLine equals:[copy titlebarSeparatorStyle] message:@"the separator style"];
    [self assertNotNull:[copy viewController] message:@"the view controller"];
}

- (void)testAControllerIsArchivedWithItsItemsAndSplitView
{
    [sidebarItem setHoldingPriority:260];
    [controller setMinimumThicknessForInlineSidebars:200];
    [self loadTwoItems];

    var copy = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:controller]],
        items = [copy splitViewItems],
        splitView = [copy splitView];

    [self assert:2 equals:[items count] message:@"both items"];
    [self assert:CPSplitViewItemBehaviorSidebar equals:[items[0] behavior] message:@"the sidebar comes first"];
    [self assert:copy equals:[items[0] splitViewController] message:@"a decoded item knows its controller"];
    [self assert:[[items[0] viewController], [items[1] viewController]] equals:[copy childViewControllers] message:@"the children are the items' view controllers"];
    [self assert:200 equals:[copy minimumThicknessForInlineSidebars] message:@"the minimum for inline sidebars"];
    [self assertNotNull:splitView message:@"the split view"];
    [self assert:copy equals:[splitView delegate] message:@"the controller is the delegate of the split view"];

    [copy view];

    [self assert:[[[items[0] viewController] view], [[items[1] viewController] view]] equals:[splitView arrangedSubviews] message:@"the item views are arranged once"];

    [items[0] setCollapsed:YES];
    [self assertTrue:[[[items[0] viewController] view] isHidden] message:@"a decoded item collapses its view"];
}

@end

@implementation _CPSplitViewControllerTestChild : CPViewController
{
    float _width;
}

- (id)initWithWidth:(float)aWidth
{
    if (self = [super initWithCibName:nil bundle:nil])
        _width = aWidth;

    return self;
}

- (void)loadView
{
    [self setView:[[CPView alloc] initWithFrame:CGRectMake(0, 0, _width, 100)]];
}

@end

@implementation _CPSplitViewControllerTestObserver : CPObject
{
    int count;
}

- (id)init
{
    if (self = [super init])
        count = 0;

    return self;
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)aChange context:(id)aContext
{
    count++;
}

@end
