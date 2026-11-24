/*
 * CPSplitViewItem.j
 * AppKit
 *
 * Created by David Richardson on 2026-11-23.
 * Copyright David Richardson 2026.
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

@import <Foundation/CPObject.j>

@import "CPViewController.j"
@import "CPWindow_Constants.j"
@import "_CPObjectAnimator.j"

@class CPSplitViewController

@typedef CPSplitViewItemBehavior
CPSplitViewItemBehaviorDefault      = 0;
CPSplitViewItemBehaviorSidebar      = 1;
CPSplitViewItemBehaviorContentList  = 2;
CPSplitViewItemBehaviorInspector    = 3;

@typedef CPSplitViewItemCollapseBehavior
CPSplitViewItemCollapseBehaviorDefault                                  = 0;
CPSplitViewItemCollapseBehaviorPreferResizingSplitViewWithFixedSiblings = 1;
CPSplitViewItemCollapseBehaviorPreferResizingSiblingsWithFixedSplitView = 2;
CPSplitViewItemCollapseBehaviorUseConstraints                           = 3;

/*!
    The value of a thickness property of a split view item that sets no limit.
*/
CPSplitViewItemUnspecifiedDimension = -1;

var CPSplitViewItemDefaultHoldingPriority   = 250,
    CPSplitViewItemSidebarThicknessFraction = 0.15,
    CPSplitViewItemContentListThicknessFraction = 0.28,
    CPSplitViewItemInspectorThickness       = 270;

/*!
    @ingroup appkit
    @class CPSplitViewItem

    A split view item describes one child view controller of a CPSplitViewController: whether
    it is collapsed, whether the user can collapse it, how it holds its size and the limits of
    its thickness. The thickness is the width of the item in a vertical split view and its
    height in a horizontal one.

    The collapsed state can be set through the animator proxy, so that

    @code
    [[item animator] setCollapsed:YES];
    @endcode

    inside a CPAnimationContext group animates the collapse.

    These properties are archived but have no effect yet: springLoaded, allowsFullHeightLayout,
    titlebarSeparatorStyle, automaticMaximumThickness, and the collapse behaviors other than
    the default and PreferResizingSiblingsWithFixedSplitView, which both resize the siblings.
*/
@implementation CPSplitViewItem : CPObject
{
    CPViewController                _viewController;
    CPSplitViewController           _splitViewController;
    CPSplitViewItemBehavior         _behavior;
    CPSplitViewItemCollapseBehavior _collapseBehavior;

    BOOL                            _isCollapsed;
    BOOL                            _canCollapse;
    BOOL                            _canCollapseFromWindowResize;
    BOOL                            _isSpringLoaded;
    BOOL                            _allowsFullHeightLayout;

    float                           _holdingPriority;
    float                           _minimumThickness;
    float                           _maximumThickness;
    float                           _preferredThicknessFraction;
    float                           _automaticMaximumThickness;

    CPTitlebarSeparatorStyle        _titlebarSeparatorStyle;

    CPDictionary                    _animations;
    id                              _animator;
}

// MARK: - Creating items

/*!
    Returns an item for a view controller, with the default values.
*/
+ (id)splitViewItemWithViewController:(CPViewController)viewController
{
    return [[self alloc] _initWithViewController:viewController behavior:CPSplitViewItemBehaviorDefault];
}

/*!
    Returns an item for a sidebar. A sidebar can collapse, also when the split view becomes
    too small for it, prefers 15% of the split view, and is spring loaded.
*/
+ (id)sidebarWithViewController:(CPViewController)viewController
{
    return [[self alloc] _initWithViewController:viewController behavior:CPSplitViewItemBehaviorSidebar];
}

/*!
    Returns an item for a content list, such as the message list of a mail application. A
    content list prefers 28% of the split view.
*/
+ (id)contentListWithViewController:(CPViewController)viewController
{
    return [[self alloc] _initWithViewController:viewController behavior:CPSplitViewItemBehaviorContentList];
}

/*!
    Returns an item for an inspector. An inspector can collapse and has a fixed thickness of
    270 points.
*/
+ (id)inspectorWithViewController:(CPViewController)viewController
{
    return [[self alloc] _initWithViewController:viewController behavior:CPSplitViewItemBehaviorInspector];
}

- (id)init
{
    return [self _initWithViewController:nil behavior:CPSplitViewItemBehaviorDefault];
}

/*
    The values for each behavior follow the AppKit headers. AppKit gives sidebars and content
    lists standard minimum and maximum thicknesses that its headers do not state; here they are
    unspecified. A content list prefers 28% when a sidebar beside it is visible and 33% when
    not; here it prefers 28% in both cases.
*/
- (id)_initWithViewController:(CPViewController)viewController behavior:(CPSplitViewItemBehavior)aBehavior
{
    if (self = [super init])
    {
        _viewController = viewController;
        _behavior = aBehavior;
        _collapseBehavior = CPSplitViewItemCollapseBehaviorDefault;
        _isCollapsed = NO;
        _canCollapse = NO;
        _canCollapseFromWindowResize = NO;
        _isSpringLoaded = NO;
        _allowsFullHeightLayout = YES;
        _holdingPriority = CPSplitViewItemDefaultHoldingPriority;
        _minimumThickness = CPSplitViewItemUnspecifiedDimension;
        _maximumThickness = CPSplitViewItemUnspecifiedDimension;
        _preferredThicknessFraction = CPSplitViewItemUnspecifiedDimension;
        _automaticMaximumThickness = CPSplitViewItemUnspecifiedDimension;
        _titlebarSeparatorStyle = CPTitlebarSeparatorStyleAutomatic;
        _animations = @{};

        switch (aBehavior)
        {
            case CPSplitViewItemBehaviorSidebar:
                _canCollapse = YES;
                _canCollapseFromWindowResize = YES;
                _isSpringLoaded = YES;
                _preferredThicknessFraction = CPSplitViewItemSidebarThicknessFraction;
                break;

            case CPSplitViewItemBehaviorContentList:
                _preferredThicknessFraction = CPSplitViewItemContentListThicknessFraction;
                break;

            case CPSplitViewItemBehaviorInspector:
                _canCollapse = YES;
                _minimumThickness = CPSplitViewItemInspectorThickness;
                _maximumThickness = CPSplitViewItemInspectorThickness;
                break;
        }
    }

    return self;
}

// MARK: - The view controller

/*!
    Returns the view controller that the item represents.
*/
- (CPViewController)viewController
{
    return _viewController;
}

/*!
    Sets the view controller that the item represents. It raises
    CPInternalInconsistencyException when the item is in a split view controller.
*/
- (void)setViewController:(CPViewController)viewController
{
    if (_splitViewController)
        [CPException raise:CPInternalInconsistencyException reason:@"The view controller of a split view item cannot change while the item is in a split view controller"];

    _viewController = viewController;
}

/*!
    Returns the standard behavior of the item, from the method that created it.
*/
- (CPSplitViewItemBehavior)behavior
{
    return _behavior;
}

// MARK: - Collapsing

/*!
    Returns YES when the item is collapsed. The value follows the user's collapses and
    expansions too.
*/
- (BOOL)isCollapsed
{
    return _isCollapsed;
}

/*!
    Collapses or expands the item. A collapsed item takes no space and keeps its thickness for
    its expansion. An item that is collapsed when it is added to a split view controller does
    not load its view until it expands. Send this to the animator proxy to animate it.
*/
- (void)setCollapsed:(BOOL)shouldCollapse
{
    [self _setCollapsed:shouldCollapse animated:NO];
}

- (void)_setCollapsed:(BOOL)shouldCollapse animated:(BOOL)shouldAnimate
{
    shouldCollapse = !!shouldCollapse;

    if (_isCollapsed === shouldCollapse)
        return;

    [self willChangeValueForKey:@"collapsed"];
    _isCollapsed = shouldCollapse;
    [self didChangeValueForKey:@"collapsed"];

    [_splitViewController _splitViewItemDidChangeCollapsed:self animated:shouldAnimate];
}

/*
    The collapsed state changes through the animator proxy too, which does not call
    -setCollapsed:, so the item posts its own change notifications.
*/
+ (BOOL)automaticallyNotifiesObserversOfCollapsed
{
    return NO;
}

/*
    Records a collapse or expansion that the split view made, after a drag or a double click,
    so that observers of "collapsed" learn of it.
*/
- (void)_noteCollapsed:(BOOL)isCollapsed
{
    isCollapsed = !!isCollapsed;

    if (_isCollapsed === isCollapsed)
        return;

    [self willChangeValueForKey:@"collapsed"];
    _isCollapsed = isCollapsed;
    [self didChangeValueForKey:@"collapsed"];
}

/*!
    Returns YES when the user can collapse the item, by dragging or double-clicking a divider.
    The default is NO; sidebars and inspectors can collapse.
*/
- (BOOL)canCollapse
{
    return _canCollapse;
}

/*!
    Sets whether the user can collapse the item. For a sidebar, this also sets whether the item
    collapses when the split view becomes too small for it.
*/
- (void)setCanCollapse:(BOOL)canCollapse
{
    _canCollapse = !!canCollapse;

    if (_behavior === CPSplitViewItemBehaviorSidebar)
        _canCollapseFromWindowResize = _canCollapse;
}

/*!
    Returns YES when the item collapses when the split view becomes smaller than
    -minimumThicknessForInlineSidebars of its controller. Only sidebars do this; it is YES for
    sidebars and NO otherwise.
*/
- (BOOL)canCollapseFromWindowResize
{
    return _canCollapseFromWindowResize;
}

- (void)setCanCollapseFromWindowResize:(BOOL)canCollapse
{
    _canCollapseFromWindowResize = !!canCollapse;
}

/*!
    Returns the way the item changes the layout when its collapsed state is set in code.
*/
- (CPSplitViewItemCollapseBehavior)collapseBehavior
{
    return _collapseBehavior;
}

- (void)setCollapseBehavior:(CPSplitViewItemCollapseBehavior)aBehavior
{
    _collapseBehavior = aBehavior;
}

// MARK: - Thickness

/*!
    Returns the priority with which the item holds its thickness when the split view resizes.
    The item with the lowest priority takes a change first. The default is 250.
*/
- (float)holdingPriority
{
    return _holdingPriority;
}

- (void)setHoldingPriority:(float)aPriority
{
    _holdingPriority = aPriority;
    [_splitViewController _splitViewItemDidChangeHoldingPriority:self];
}

/*!
    Returns the smallest thickness to which the user can drag the item, or
    CPSplitViewItemUnspecifiedDimension for no limit.
*/
- (float)minimumThickness
{
    return _minimumThickness;
}

- (void)setMinimumThickness:(float)aThickness
{
    _minimumThickness = aThickness;
}

/*!
    Returns the largest thickness to which the user can drag the item, or
    CPSplitViewItemUnspecifiedDimension for no limit.
*/
- (float)maximumThickness
{
    return _maximumThickness;
}

- (void)setMaximumThickness:(float)aThickness
{
    _maximumThickness = aThickness;
}

/*!
    Returns the part of the split view that the item prefers, from 0 to 1, or
    CPSplitViewItemUnspecifiedDimension. An item whose view has no thickness takes this part
    when its view is added to the split view.
*/
- (float)preferredThicknessFraction
{
    return _preferredThicknessFraction;
}

- (void)setPreferredThicknessFraction:(float)aFraction
{
    _preferredThicknessFraction = aFraction;
}

/*!
    Returns the largest thickness for automatic sizing, or CPSplitViewItemUnspecifiedDimension.
*/
- (float)automaticMaximumThickness
{
    return _automaticMaximumThickness;
}

- (void)setAutomaticMaximumThickness:(float)aThickness
{
    _automaticMaximumThickness = aThickness;
}

// MARK: - Other properties

/*!
    Returns YES when the item expands for a while during a drag over its divider. The default
    is NO; sidebars are spring loaded.
*/
- (BOOL)isSpringLoaded
{
    return _isSpringLoaded;
}

- (void)setSpringLoaded:(BOOL)isSpringLoaded
{
    _isSpringLoaded = !!isSpringLoaded;
}

/*!
    Returns YES when a sidebar or inspector can take the full height of a window whose content
    goes under its title bar. The default is YES.
*/
- (BOOL)allowsFullHeightLayout
{
    return _allowsFullHeightLayout;
}

- (void)setAllowsFullHeightLayout:(BOOL)allowsFullHeightLayout
{
    _allowsFullHeightLayout = !!allowsFullHeightLayout;
}

/*!
    Returns the style of the separator between the title bar and the item.
*/
- (CPTitlebarSeparatorStyle)titlebarSeparatorStyle
{
    return _titlebarSeparatorStyle;
}

- (void)setTitlebarSeparatorStyle:(CPTitlebarSeparatorStyle)aStyle
{
    _titlebarSeparatorStyle = aStyle;
}

/*!
    Returns the split view controller that has the item, or nil.
*/
- (CPSplitViewController)splitViewController
{
    return _splitViewController;
}

- (void)_setSplitViewController:(CPSplitViewController)aController
{
    _splitViewController = aController;
}

- (CPString)description
{
    return [super description] + " " + [_viewController description] + (_isCollapsed ? " (collapsed)" : "");
}

@end

// MARK: - Animation

@implementation CPSplitViewItem (CPAnimatablePropertyContainer)

+ (id)defaultAnimationForKey:(CPString)aKey
{
    return nil;
}

/*!
    Returns the proxy through which a change of the collapsed state animates.
*/
- (id)animator
{
    if (!_animator)
        _animator = [[CPSplitViewItemAnimator alloc] initWithTarget:self];

    return _animator;
}

/*!
    Returns the animations of the item, by key. The collapse uses the duration of the current
    CPAnimationContext group; an animation stored under "collapsed" is kept but not used yet.
*/
- (CPDictionary)animations
{
    return _animations;
}

- (void)setAnimations:(CPDictionary)theAnimations
{
    _animations = theAnimations || @{};
}

- (id)animationForKey:(CPString)aKey
{
    return [_animations objectForKey:aKey] || [[self class] defaultAnimationForKey:aKey];
}

@end

/*
    The animator proxy of a split view item. A collapse or expansion sent to it animates the
    split view of the item's controller inside the current CPAnimationContext group. Other
    messages go to the item.
*/
@implementation CPSplitViewItemAnimator : _CPObjectAnimator

- (void)setCollapsed:(BOOL)shouldCollapse
{
    [_target _setCollapsed:shouldCollapse animated:YES];
}

@end

// MARK: - Archiving

var CPSplitViewItemViewControllerKey                = @"CPSplitViewItemViewControllerKey",
    CPSplitViewItemSplitViewControllerKey           = @"CPSplitViewItemSplitViewControllerKey",
    CPSplitViewItemBehaviorKey                      = @"CPSplitViewItemBehaviorKey",
    CPSplitViewItemCollapseBehaviorKey              = @"CPSplitViewItemCollapseBehaviorKey",
    CPSplitViewItemCollapsedKey                     = @"CPSplitViewItemCollapsedKey",
    CPSplitViewItemCanCollapseKey                   = @"CPSplitViewItemCanCollapseKey",
    CPSplitViewItemCanCollapseFromWindowResizeKey   = @"CPSplitViewItemCanCollapseFromWindowResizeKey",
    CPSplitViewItemSpringLoadedKey                  = @"CPSplitViewItemSpringLoadedKey",
    CPSplitViewItemAllowsFullHeightLayoutKey        = @"CPSplitViewItemAllowsFullHeightLayoutKey",
    CPSplitViewItemHoldingPriorityKey               = @"CPSplitViewItemHoldingPriorityKey",
    CPSplitViewItemMinimumThicknessKey              = @"CPSplitViewItemMinimumThicknessKey",
    CPSplitViewItemMaximumThicknessKey              = @"CPSplitViewItemMaximumThicknessKey",
    CPSplitViewItemPreferredThicknessFractionKey    = @"CPSplitViewItemPreferredThicknessFractionKey",
    CPSplitViewItemAutomaticMaximumThicknessKey     = @"CPSplitViewItemAutomaticMaximumThicknessKey",
    CPSplitViewItemTitlebarSeparatorStyleKey        = @"CPSplitViewItemTitlebarSeparatorStyleKey";

@implementation CPSplitViewItem (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [self _initWithViewController:[aCoder decodeObjectForKey:CPSplitViewItemViewControllerKey]
                                behavior:[aCoder decodeIntForKey:CPSplitViewItemBehaviorKey]];

    if (self)
    {
        _splitViewController = [aCoder decodeObjectForKey:CPSplitViewItemSplitViewControllerKey];
        _collapseBehavior = [aCoder decodeIntForKey:CPSplitViewItemCollapseBehaviorKey];
        _isCollapsed = [aCoder decodeBoolForKey:CPSplitViewItemCollapsedKey];
        _canCollapse = [aCoder decodeBoolForKey:CPSplitViewItemCanCollapseKey];
        _canCollapseFromWindowResize = [aCoder decodeBoolForKey:CPSplitViewItemCanCollapseFromWindowResizeKey];
        _isSpringLoaded = [aCoder decodeBoolForKey:CPSplitViewItemSpringLoadedKey];

        if ([aCoder containsValueForKey:CPSplitViewItemAllowsFullHeightLayoutKey])
            _allowsFullHeightLayout = [aCoder decodeBoolForKey:CPSplitViewItemAllowsFullHeightLayoutKey];

        if ([aCoder containsValueForKey:CPSplitViewItemHoldingPriorityKey])
            _holdingPriority = [aCoder decodeFloatForKey:CPSplitViewItemHoldingPriorityKey];

        if ([aCoder containsValueForKey:CPSplitViewItemMinimumThicknessKey])
            _minimumThickness = [aCoder decodeFloatForKey:CPSplitViewItemMinimumThicknessKey];

        if ([aCoder containsValueForKey:CPSplitViewItemMaximumThicknessKey])
            _maximumThickness = [aCoder decodeFloatForKey:CPSplitViewItemMaximumThicknessKey];

        if ([aCoder containsValueForKey:CPSplitViewItemPreferredThicknessFractionKey])
            _preferredThicknessFraction = [aCoder decodeFloatForKey:CPSplitViewItemPreferredThicknessFractionKey];

        if ([aCoder containsValueForKey:CPSplitViewItemAutomaticMaximumThicknessKey])
            _automaticMaximumThickness = [aCoder decodeFloatForKey:CPSplitViewItemAutomaticMaximumThicknessKey];

        _titlebarSeparatorStyle = [aCoder decodeIntForKey:CPSplitViewItemTitlebarSeparatorStyleKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_viewController forKey:CPSplitViewItemViewControllerKey];
    [aCoder encodeConditionalObject:_splitViewController forKey:CPSplitViewItemSplitViewControllerKey];
    [aCoder encodeInt:_behavior forKey:CPSplitViewItemBehaviorKey];
    [aCoder encodeInt:_collapseBehavior forKey:CPSplitViewItemCollapseBehaviorKey];
    [aCoder encodeBool:_isCollapsed forKey:CPSplitViewItemCollapsedKey];
    [aCoder encodeBool:_canCollapse forKey:CPSplitViewItemCanCollapseKey];
    [aCoder encodeBool:_canCollapseFromWindowResize forKey:CPSplitViewItemCanCollapseFromWindowResizeKey];
    [aCoder encodeBool:_isSpringLoaded forKey:CPSplitViewItemSpringLoadedKey];
    [aCoder encodeBool:_allowsFullHeightLayout forKey:CPSplitViewItemAllowsFullHeightLayoutKey];
    [aCoder encodeFloat:_holdingPriority forKey:CPSplitViewItemHoldingPriorityKey];
    [aCoder encodeFloat:_minimumThickness forKey:CPSplitViewItemMinimumThicknessKey];
    [aCoder encodeFloat:_maximumThickness forKey:CPSplitViewItemMaximumThicknessKey];
    [aCoder encodeFloat:_preferredThicknessFraction forKey:CPSplitViewItemPreferredThicknessFractionKey];
    [aCoder encodeFloat:_automaticMaximumThickness forKey:CPSplitViewItemAutomaticMaximumThicknessKey];
    [aCoder encodeInt:_titlebarSeparatorStyle forKey:CPSplitViewItemTitlebarSeparatorStyleKey];
}

@end
