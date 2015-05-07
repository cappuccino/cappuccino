/*
 * CPTabViewItem.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

@import "CPView.j"
@class CPTabView
@class CPViewController

/*
    The tab is currently selected.
    @global
    @group CPTabState
*/
CPSelectedTab   = 0;
/*
    The tab is currently in the background (not selected).
    @global
    @group CPTabState
*/
CPBackgroundTab = 1;
/*
    The tab of this item is currently being pressed by the user.
    @global
    @group CPTabState
*/
CPPressedTab    = 2;

/*!
    @ingroup appkit
    @class CPTabViewItem

    The class representation of an item in a CPTabView. One tab view item
    can be shown at a time in a CPTabView.
*/
@implementation CPTabViewItem : CPObject
{
    id               _identifier;
    CPString         _label;
    CPInteger        _tag            @accessors(property=tag);

    CPView           _view;
    CPView           _auxiliaryView;

    CPTabView        _tabView;
    unsigned         _tabState;      // Looks like it is not yet implemented

    CPImage          _image          @accessors(property=image);
    CPViewController _viewController @accessors(getter=viewController);

    BOOL             _enabled        @accessors(property=enabled);
    BOOL             _selected       @accessors(property=selected);
    CGRect           _tabRect        @accessors(property=frame);
    float            _width          @accessors(property=width);
}

/*

*/
+ (CPTabViewItem)tabViewItemWithViewController:(CPViewController)aViewController
{
    var item = [[CPTabViewItem alloc] init];
    [item setViewController:aViewController];

    return item;
}

- (id)init
{
    return [self initWithIdentifier:@""];
}

- (void)_init
{
    _tag = 0;
    _viewController = nil;
    _image = nil;
    _tabState = 0;
    _tabView = nil;
    _enabled = YES;
    _selected = NO;
    _tabRect = CGRectMakeZero();
    _width = 0;
}

/*!
    Initializes the tab view item with the specified identifier.
    @return the initialized CPTabViewItem
*/
- (id)initWithIdentifier:(id)anIdentifier
{
    self = [super init];

    [self _init];

    _identifier = anIdentifier;
    _label = nil;
    _view = nil;
    //_auxiliaryView = nil;

    return self;
}

// Working With Labels
/*!
    Sets the CPTabViewItem's label.
    @param aLabel the label for the item
*/
- (void)setLabel:(CPString)aLabel
{
    if ([aLabel isEqualToString:_label])
        return;

    _label = aLabel;
    [_tabView tileWithChangedItem:self];
}

/*!
    Returns the CPTabViewItem's label
*/
- (CPString)label
{
    return _label;
}

// Working With Images
/*!
    Sets the CPTabViewItem's image.
    @param anImage the image for the item
*/
- (void)setImage:(CPImage)anImage
{
    if ([anImage isEqual:_image])
        return;

    _image = anImage;
    [_tabView tileWithChangedItem:self];
}

/*!
    Returns the CPTabViewItem's image
*/
- (CPImage)image
{
    return _image;
}

// Checking the Tab Display State
/*!
    Returns the tab's current state.
*/
- (CPTabState)tabState
{
    return _tabState;
}

// Assigning an Identifier Object
/*!
    Sets the item's identifier.
    @param anIdentifier the new identifier for the item
*/
- (void)setIdentifier:(id)anIdentifier
{
    _identifier = anIdentifier;
}

/*!
    Returns the tab's identifier.
*/
- (id)identifier
{
    return _identifier;
}

// Assigning a View
/*!
    Sets the view that gets displayed in this tab.
*/
- (void)setView:(CPView)aView
{
    if (_view == aView)
        return;

    _view = aView;

    if ([_tabView selectedTabViewItem] == self)
        [_tabView _displayItemView:_view];
}

/*!
    Returns the tab's view.
*/
- (CPView)view
{
    if (!_view && _viewController)
        return [_viewController view]; // The view controller loads here.

    return _view;
}

// Assigning an Auxiliary View
/*!
    Sets the tab's auxiliary view.
    @param anAuxiliaryView the new auxiliary view
*/
- (void)setAuxiliaryView:(CPView)anAuxiliaryView
{
    _auxiliaryView = anAuxiliaryView;
}

/*!
    Returns the tab's auxiliary view
*/
- (CPView)auxiliaryView
{
    return _auxiliaryView;
}

// Accessing the Parent Tab View
/*!
    Returns the tab view that contains this item.
*/
- (CPTabView)tabView
{
    return _tabView;
}

/*!
    @ignore
*/
- (void)_setTabView:(CPTabView)aView
{
    _tabView = aView;
}

/*!
    Sets the specified view controller for the tab view item.
    @param aViewController an instance of CPViewController.
*/
- (void)setViewController:(CPViewController)aViewController
{
    _viewController = aViewController;

    var identifier = [aViewController cibName],
        title = [_viewController title];

    if (identifier)
        _identifier = identifier;

    if (title)
        [self setLabel:title];

    if ([_tabView selectedTabViewItem] == self)
        [_tabView _displayItemView:[_viewController view]];
}

@end

var CPTabViewItemIdentifierKey  = "CPTabViewItemIdentifierKey",
    CPTabViewItemLabelKey       = "CPTabViewItemLabelKey",
    CPTabViewItemImageKey       = "CPTabViewItemImageKey",
    CPTabViewItemViewKey        = "CPTabViewItemViewKey",
    CPTabViewItemAuxViewKey     = "CPTabViewItemAuxViewKey";


@implementation CPTabViewItem (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
       [self _init];

        _identifier     = [aCoder decodeObjectForKey:CPTabViewItemIdentifierKey];
        _label          = [aCoder decodeObjectForKey:CPTabViewItemLabelKey];
        _image          = [aCoder decodeObjectForKey:CPTabViewItemImageKey];

        _view           = [aCoder decodeObjectForKey:CPTabViewItemViewKey];
        _auxiliaryView  = [aCoder decodeObjectForKey:CPTabViewItemAuxViewKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_identifier    forKey:CPTabViewItemIdentifierKey];
    [aCoder encodeObject:_label         forKey:CPTabViewItemLabelKey];
    [aCoder encodeObject:_image         forKey:CPTabViewItemImageKey];

    [aCoder encodeObject:_view          forKey:CPTabViewItemViewKey];
    [aCoder encodeObject:_auxiliaryView forKey:CPTabViewItemAuxViewKey];
}

@end
