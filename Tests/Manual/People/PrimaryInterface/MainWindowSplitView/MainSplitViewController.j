/*
 * MainSplitViewController.j
 * People
 *
 * Content view controller of the main window: the three panes of the library side by side,
 * Navigation | Content | Detail. Exercises:
 *   - CPSplitViewController as a window's content view controller
 *   - CPSplitViewItem: a sidebar item, a content list item and a default item, with minimum
 *     and maximum thicknesses and holding priorities
 *   - animated collapse and expansion of the sidebar and the detail pane
 *   - autosave of the split view, and a button bar resize control on the first divider
 *   - the detail pane shows the content's selection through its representedObject, and its
 *     selectionCount covers the pane unless one row is selected, so the panes do not know
 *     about each other; only this controller knows the layout
 *   - key-value observing of the sidebar item's collapsed state: while the sidebar is
 *     collapsed, the people table's button bar shows the main menu button
 */

@import <AppKit/AppKit.j>

@import "../../Library/Navigation/SourceListViewController.j"
@import "../../Library/ContentViewer/PeopleViewController.j"
@import "../../Library/PersonInspector/PersonDetailViewController.j"

var SidebarDefaultWidth     = 230.0,
    SidebarMinimumWidth     = 160.0,
    SidebarMaximumWidth     = 420.0,
    ContentMinimumWidth     = 300.0,
    ToggleDuration          = 0.25,
    SplitViewAutosaveName   = @"People.MainSplitView";

@implementation MainSplitViewController : CPSplitViewController
{
    SourceListViewController    _sourceListController;
    PeopleViewController        _peopleController;
    PersonDetailViewController  _detailController;

    CPSplitViewItem             _sidebarItem;
    CPSplitViewItem             _contentItem;
    CPSplitViewItem             _detailItem;
}

- (id)initWithSourceListController:(SourceListViewController)aSourceListController peopleController:(PeopleViewController)aPeopleController
{
    if (self = [super initWithCibName:nil bundle:nil])
    {
        _sourceListController = aSourceListController;
        _peopleController = aPeopleController;
        _detailController = [[PersonDetailViewController alloc] initWithLibrary:[_peopleController library]];

        [_detailController bind:@"representedObject" toObject:[_peopleController arrayController] withKeyPath:@"selection" options:nil];
        [_detailController bind:@"selectionCount" toObject:[_peopleController arrayController] withKeyPath:@"selectedObjects.@count" options:nil];

        _sidebarItem = [CPSplitViewItem sidebarWithViewController:_sourceListController];
        [_sidebarItem setMinimumThickness:SidebarMinimumWidth];
        [_sidebarItem setMaximumThickness:SidebarMaximumWidth];

        _contentItem = [CPSplitViewItem contentListWithViewController:_peopleController];
        [_contentItem setMinimumThickness:ContentMinimumWidth];

        _detailItem = [CPSplitViewItem splitViewItemWithViewController:_detailController];
        [_detailItem setCanCollapse:YES];
        [_detailItem setMinimumThickness:PersonDetailMinimumWidth];

        /*
            The table takes the space the window gains or loses; the sidebar and the detail
            pane keep their widths.
        */
        [_sidebarItem setHoldingPriority:270];
        [_detailItem setHoldingPriority:260];
        [_contentItem setHoldingPriority:250];

        [self setSplitViewItems:[_sidebarItem, _contentItem, _detailItem]];

        /*
            The item posts the change for every way the sidebar collapses or expands: the
            menu, the toolbar, the key equivalent and a drag of the divider.
        */
        [_sidebarItem addObserver:self forKeyPath:@"collapsed" options:CPKeyValueObservingOptionInitial context:nil];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    var splitView = [self splitView];

    [splitView setButtonBar:[_sourceListController buttonBar] forDividerAtIndex:0];
    [splitView setAutosaveName:SplitViewAutosaveName];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)aChange context:(id)aContext
{
    [_peopleController setShowsMainMenuButton:[_sidebarItem isCollapsed]];
}

// ---------------------------------------------------------------- Panes

- (BOOL)isSidebarVisible
{
    return ![_sidebarItem isCollapsed];
}

- (BOOL)isDetailVisible
{
    return ![_detailItem isCollapsed];
}

/*
    The detail pane is a default item, not an inspector item, so -toggleInspector: does not
    reach it.
*/
- (void)toggleDetail:(id)sender
{
    [CPAnimationContext runAnimationGroup:function(aContext)
    {
        [aContext setDuration:ToggleDuration];
        [[_detailItem animator] setCollapsed:![_detailItem isCollapsed]];
    }
    completionHandler:nil];
}

/*
    Shows the sidebar and the detail pane, and gives both their default widths.
*/
- (void)restoreDefaultLayout
{
    var splitView = [self splitView];

    [_sidebarItem setCollapsed:NO];
    [_detailItem setCollapsed:NO];

    [splitView setPosition:CGRectGetWidth([splitView bounds]) - [splitView dividerThickness] - PersonDetailPreferredWidth ofDividerAtIndex:1];
    [splitView setPosition:SidebarDefaultWidth ofDividerAtIndex:0];
}

@end
