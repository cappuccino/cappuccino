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

import <Foundation/CPObject.j>

import <AppKit/CPView.j>


CPSelectedTab   = 0;
CPBackgroundTab = 1;
CPPressedTab    = 2;

@implementation CPTabViewItem : CPObject
{
    id          _identifier;
    CPString    _label;
    
    CPView      _view;
    CPView      _auxiliaryView;
}

- (id)initWithIdentifier:(id)anIdentifier
{
    self = [super init];
    
    if (self)
        _identifier = anIdentifier;
        
    return self;
}

// Working With Labels

- (void)setLabel:(CPString)aLabel
{
    _label = aLabel;
}

- (CPString)label
{
    return _label;
}

// Checking the Tab Display State

- (CPTabState)tabState
{
    return _tabState;
}

// Assigning an Identifier Object

- (void)setIdentifier:(id)anIdentifier
{
    _identifier = anIdentifier;
}

- (id)identifier
{
    return _identifier;
}

// Assigning a View

- (void)setView:(CPView)aView
{
    _view = aView;
}

- (CPView)view
{
    return _view;
}

// Assigning an Auxiliary View

- (void)setAuxiliaryView:(CPView)anAuxiliaryView
{
    _auxiliaryView = anAuxiliaryView;
}

- (CPView)auxiliaryView
{
    return _auxiliaryView;
}

// Accessing the Parent Tab View

- (CPView)tabView
{
    return _tabView;
}

@end
