/*
 * CPSplitViewController.j
 *
 * Created by Google Gemini.
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

@import <AppKit/CPViewController.j>
@import <AppKit/CPSplitView.j>

var CPSplitViewControllerAutomaticDimension = -1.0;

@implementation CPSplitViewController : CPViewController <CPSplitViewDelegate>
{
    CPSplitView         _splitView;
    CPMutableArray      _splitViewItems;
    CPNumber            _minimumThicknessForInlineSidebars;
}

- (id)init
{
    if (self = [super init])
    {
        _splitViewItems = [CPMutableArray array];
        _minimumThicknessForInlineSidebars = 20.0;
    }
    return self;
}

- (void)loadView
{
    _splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0,0,400,400)];
    [self setView:_splitView];
    [_splitView setDelegate:self];
}

#pragma mark - Accessors

- (CPSplitView)splitView
{
    return _splitView;
}

- (CPArray)splitViewItems
{
    return _splitViewItems;
}

#pragma mark - Managing Split View Items

- (void)addSplitViewItem:(CPSplitViewItem)splitViewItem
{
    [self insertSplitViewItem:splitViewItem atIndex:[_splitViewItems count]];
}

- (void)insertSplitViewItem:(CPSplitViewItem)splitViewItem atIndex:(CPInteger)index
{
    [splitViewItem _setSplitViewController:self];
    [_splitViewItems insertObject:splitViewItem atIndex:index];
    [self addChildViewController:[splitViewItem viewController]];

    if ([self isViewLoaded])
        [[self splitView] insertArrangedSubview:[[splitViewItem viewController] view] atIndex:index];
}

- (void)removeSplitViewItem:(CPSplitViewItem)splitViewItem
{
    [[splitViewItem viewController] removeFromParentViewController];
    [splitViewItem _setSplitViewController:nil];
    [_splitViewItems removeObject:splitViewItem];
}

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

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    for (var i = 0; i < [_splitViewItems count]; i++)
    {
        var viewController = [[_splitViewItems objectAtIndex:i] viewController];
        [[self splitView] addArrangedSubview:[viewController view]];
    }
}

#pragma mark - Managing Sidebars and Inspectors

- (void)toggleSidebar:(id)sender
{
    if ([_splitViewItems count] > 0)
    {
        var sidebarItem = [_splitViewItems objectAtIndex:0];
        [sidebarItem setCollapsed:![sidebarItem isCollapsed]];
    }
}

- (void)toggleInspector:(id)sender
{
    if ([_splitViewItems count] > 1)
    {
        var inspectorItem = [_splitViewItems lastObject];
        [inspectorItem setCollapsed:![inspectorItem isCollapsed]];
    }
}

- (CPNumber)minimumThicknessForInlineSidebars
{
    return _minimumThicknessForInlineSidebars;
}

@end

@implementation CPSplitViewItem : CPObject
{
    CPViewController        _viewController;
    BOOL                    _isCollapsed;
    CPSplitViewController   _splitViewController;
}

#pragma mark - Initialization

+ (instancetype)splitViewItemWithViewController:(CPViewController)viewController
{
    return [[self alloc] initWithViewController:viewController];
}

- (id)initWithViewController:(CPViewController)viewController
{
    if (self = [super init])
    {
        _viewController = viewController;
        _isCollapsed = NO;
    }
    return self;
}

#pragma mark - Accessors

- (CPViewController)viewController
{
    return _viewController;
}

- (BOOL)isCollapsed
{
    return _isCollapsed;
}

- (void)setCollapsed:(BOOL)shouldCollapse
{
    if (_isCollapsed === shouldCollapse)
        return;

    _isCollapsed = shouldCollapse;
    [[_viewController view] setHidden:shouldCollapse];
}

- (CPSplitViewController)splitViewController
{
    return _splitViewController;
}

- (void)_setSplitViewController:(CPSplitViewController)splitViewController
{
    _splitViewController = splitViewController;
}

@end
