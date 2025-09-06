@import <AppKit/CPSplitViewController.j>
@import <AppKit/CPViewController.j>

// MARK: - Test Implementation

@implementation CPSplitViewControllerTest : OJTestCase
{
    // Instance variables can be declared here if needed for tests.
}

// MARK: - Initialization Tests

- (void)testInit
{
    var splitViewController = [[CPSplitViewController alloc] init];

    [self assertNotNil:splitViewController message:@"CPSplitViewController should initialize."];
    [self assertNotNil:[splitViewController splitViewItems] message:@"splitViewItems should be an empty array on init."];
    [self assert:[[splitViewController splitViewItems] count] equals:0 message:@"splitViewItems should have 0 items on init."];
}

- (void)testViewLoading
{
    var splitViewController = [[CPSplitViewController alloc] init];

    // Accessing the view property triggers loadView
    var view = [splitViewController view];

    [self assertNotNil:view message:@"The controller's view should be created."];
    [self assertTrue:[view isKindOfClass:[CPSplitView class]] message:@"The controller's view should be a CPSplitView."];
    [self assert:[splitViewController splitView] equals:view message:@"The splitView accessor should return the controller's view."];
}

- (void)testSplitViewItemInit
{
    var childVC = [[CPViewController alloc] init];
    var item = [CPSplitViewItem splitViewItemWithViewController:childVC];

    [self assertNotNil:item message:@"CPSplitViewItem should be created."];
    [self assert:[item viewController] equals:childVC message:@"The item should hold the correct view controller."];
    [self assertFalse:[item isCollapsed] message:@"A new item should not be collapsed."];
}

// MARK: - Item Management Tests

- (void)testAddSplitViewItem
{
    var splitViewController = [[CPSplitViewController alloc] init];
    [splitViewController view]; // Ensure view is loaded

    var childVC1 = [[CPViewController alloc] init];
    var item1 = [CPSplitViewItem splitViewItemWithViewController:childVC1];

    [splitViewController addSplitViewItem:item1];

    [self assert:[[splitViewController splitViewItems] count] equals:1 message:@"Should have 1 split view item."];
    [self assert:[splitViewController splitViewItemForViewController:childVC1] equals:item1 message:@"Should be able to retrieve item by its view controller."];
    [self assert:[item1 splitViewController] equals:splitViewController message:@"Item should have a reference to its parent controller."];
    [self assert:[[[splitViewController splitView] arrangedSubviews] count] equals:1 message:@"The splitView should have one arranged subview."];
    [self assert:[[[childVC1 view] superview] equals:[splitViewController splitView]] message:@"Child's view should be a subview of the splitView."];
}

- (void)testInsertSplitViewItem
{
    var splitViewController = [[CPSplitViewController alloc] init];
    [splitViewController view];

    var childVC1 = [[CPViewController alloc] init];
    var childVC2 = [[CPViewController alloc] init];
    var item1 = [CPSplitViewItem splitViewItemWithViewController:childVC1];
    var item2 = [CPSplitViewItem splitViewItemWithViewController:childVC2];

    [splitViewController addSplitViewItem:item1];
    [splitViewController insertSplitViewItem:item2 atIndex:0];

    [self assert:[[splitViewController splitViewItems] count] equals:2 message:@"Should have 2 split view items."];
    [self assert:[[splitViewController splitViewItems] objectAtIndex:0] equals:item2 message:@"Item2 should be at index 0."];

    var arrangedSubviews = [[splitViewController splitView] arrangedSubviews];
    [self assert:[arrangedSubviews objectAtIndex:0] equals:[childVC2 view] message:@"The view of item2 should be the first arranged subview."];
}

- (void)testRemoveSplitViewItem
{
    var splitViewController = [[CPSplitViewController alloc] init];
    [splitViewController view];

    var childVC1 = [[CPViewController alloc] init];
    var item1 = [CPSplitViewItem splitViewItemWithViewController:childVC1];

    [splitViewController addSplitViewItem:item1];
    [self assert:[[splitViewController splitViewItems] count] equals:1 message:@"Pre-condition: Should have 1 item."];

    [splitViewController removeSplitViewItem:item1];

    [self assert:[[splitViewController splitViewItems] count] equals:0 message:@"Should have 0 split view items after removal."];
    [self assertNil:[item1 splitViewController] message:@"Item's reference to parent should be nil after removal."];
    [self assert:[[[splitViewController splitView] arrangedSubviews] count] equals:0 message:@"The splitView should have no arranged subviews after removal."];
    [self assertNil:[[childVC1 view] superview] message:@"Child's view should be removed from the splitView."];
}

- (void)testAddingItemsBeforeViewLoads
{
    var splitViewController = [[CPSplitViewController alloc] init];

    var childVC1 = [[CPViewController alloc] init];
    var childVC2 = [[CPViewController alloc] init];
    var item1 = [CPSplitViewItem splitViewItemWithViewController:childVC1];
    var item2 = [CPSplitViewItem splitViewItemWithViewController:childVC2];

    [splitViewController addSplitViewItem:item1];
    [splitViewController addSplitViewItem:item2];

    [self assert:[[[splitViewController childViewControllers] objectAtIndex:0] equals:childVC1] message:@"Child view controllers should be added immediately."];

    // View is not loaded yet, so it should have no arranged subviews
    [self assertNil:[splitViewController _splitView] message:@"SplitView should not exist yet."];

    // Trigger viewDidLoad
    [splitViewController view];

    // Now check if the views were added
    var arrangedSubviews = [[splitViewController splitView] arrangedSubviews];
    [self assert:[arrangedSubviews count] equals:2 message:@"SplitView should have 2 subviews after loading."];
    [self assert:[arrangedSubviews objectAtIndex:0] equals:[childVC1 view]];
    [self assert:[arrangedSubviews objectAtIndex:1] equals:[childVC2 view]];
}


// MARK: - Toggling and State Tests

- (void)testToggleSidebar
{
    var splitViewController = [[CPSplitViewController alloc] init];
    var childVC1 = [[CPViewController alloc] init];
    var item1 = [CPSplitViewItem splitViewItemWithViewController:childVC1];
    [splitViewController addSplitViewItem:item1];

    [splitViewController toggleSidebar:self];
    [self assertTrue:[item1 isCollapsed] message:@"Sidebar item should be collapsed."];
    [self assertTrue:[[childVC1 view] isHidden] message:@"Sidebar view should be hidden."];

    [splitViewController toggleSidebar:self];
    [self assertFalse:[item1 isCollapsed] message:@"Sidebar item should be expanded again."];
    [self assertFalse:[[childVC1 view] isHidden] message:@"Sidebar view should be visible again."];
}

- (void)testToggleInspector
{
    var splitViewController = [[CPSplitViewController alloc] init];
    var childVC1 = [[CPViewController alloc] init];
    var childVC2 = [[CPViewController alloc] init];
    var item1 = [CPSplitViewItem splitViewItemWithViewController:childVC1];
    var item2 = [CPSplitViewItem splitViewItemWithViewController:childVC2];
    [splitViewController addSplitViewItem:item1];
    [splitViewController addSplitViewItem:item2];

    [splitViewController toggleInspector:self];
    [self assertTrue:[item2 isCollapsed] message:@"Inspector item should be collapsed."];
    [self assertTrue:[[childVC2 view] isHidden] message:@"Inspector view should be hidden."];

    [splitViewController toggleInspector:self];
    [self assertFalse:[item2 isCollapsed] message:@"Inspector item should be expanded again."];
    [self assertFalse:[[childVC2 view] isHidden] message:@"Inspector view should be visible again."];
}

- (void)testSetCollapsed
{
    var childVC = [[CPViewController alloc] init];
    var item = [CPSplitViewItem splitViewItemWithViewController:childVC];
    var childView = [childVC view];

    [item setCollapsed:YES];
    [self assertTrue:[item isCollapsed] message:@"Item's collapsed property should be YES."];
    [self assertTrue:[childView isHidden] message:@"The item's view should be hidden."];

    [item setCollapsed:NO];
    [self assertFalse:[item isCollapsed] message:@"Item's collapsed property should be NO."];
    [self assertFalse:[childView isHidden] message:@"The item's view should be visible."];

    // Test idempotency
    [item setCollapsed:NO];
    [self assertFalse:[item isCollapsed] message:@"Setting the same value should have no effect."];
}

@end