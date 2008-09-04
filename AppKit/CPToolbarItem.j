/*
 * CPToolbarItem.j
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
import <Foundation/CPString.j>

import <AppKit/CPImage.j>
import <AppKit/CPView.j>


CPToolbarItemVisibilityPriorityStandard = 0;
CPToolbarItemVisibilityPriorityLow      = -1000;
CPToolbarItemVisibilityPriorityHigh     = 1000;
CPToolbarItemVisibilityPriorityUser     = 2000;

CPToolbarSeparatorItemIdentifier        = @"CPToolbarSeparatorItemIdentifier";
CPToolbarSpaceItemIdentifier            = @"CPToolbarSpaceItemIdentifier";
CPToolbarFlexibleSpaceItemIdentifier    = @"CPToolbarFlexibleSpaceItemIdentifier";
CPToolbarShowColorsItemIdentifier       = @"CPToolbarShowColorsItemIdentifier";
CPToolbarShowFontsItemIdentifier        = @"CPToolbarShowFontsItemIdentifier";
CPToolbarCustomizeToolbarItemIdentifier = @"CPToolbarCustomizeToolbarItemIdentifier";
CPToolbarPrintItemIdentifier            = @"CPToolbarPrintItemIdentifier";

@implementation CPToolbarItem : CPObject
{
    CPString    _itemIdentifier;
    
    CPToolbar   _toolbar;
    
    CPString    _label;
    CPString    _paletteLabel;
    CPString    _toolTip;
    int         _tag;
    id          _target;
    SEL         _action;
    BOOL        _isEnabled;
    CPImage     _image;
    CPImage     _alternateImage;
    CPView      _view;
    CGSize      _minSize;
    CGSize      _maxSize;    
    
    int         _visibilityPriority;
}

// Creating a Toolbar Item

- (id)initWithItemIdentifier:(CPString)anItemIdentifier
{
    self = [super init];
    
    if (self)
    {
        _itemIdentifier = anItemIdentifier;
     
        _minSize = CGSizeMakeZero();
        _maxSize = CGSizeMakeZero();
     
        _visibilityPriority = CPToolbarItemVisibilityPriorityStandard;
    }
    
    return self;
}

// Managing Attributes

- (CPString)itemIdentifier
{
    return _itemIdentifier;
}

- (CPToolbar)toolbar
{
    return _toolbar;
}

- (CPString)label
{
    return _label;
}

- (void)setLabel:(CPString)aLabel
{
    _label = aLabel;
}

- (CPString)paletteLabel
{
    return _paletteLabel;
}

- (void)setPaletteLabel:(CPString)aPaletteLabel
{
    _paletteLabel = aPaletteLabel;
}

- (CPString)toolTip
{
    return _toolTip;
}

- (void)setToolTip:(CPString)aToolTip
{
    _toolTip = aToolTip;
}

- (int)tag
{
    return _tag;
}

- (void)setTag:(int)aTag
{
    _tag = aTag;
}

- (id)target
{
    return _target;
}

- (void)setTarget:(id)aTarget
{
    _target = aTarget;
    
    [_view setTarget:aTarget];
}

- (SEL)action
{
    return _action;
}

- (void)setAction:(SEL)anAction
{
    _action = anAction;

    [_view setAction:anAction];
}

- (BOOL)isEnabled
{
    return _isEnabled;
}

- (void)setEnabled:(BOOL)aFlag
{
    _isEnabled = aFlag;
}

- (CPImage)image
{
    return _image;
}

- (void)setImage:(CPImage)anImage
{
    _image = anImage;
    
    [_view setImage:anImage];
}

- (void)setAlternateImage:(CPImage)anImage
{
    _alternateImage = anImage;
    
    [_view setAlternateImage:anImage];
}

- (CPImage)alternateImage
{
    return _alternateImage;
}

- (CPView)view
{
    return _view;
}

- (void)setView:(CPView)aView
{
    _view = aView;
}

- (CGSize)minSize
{
    return _minSize;
}

- (void)setMinSize:(CGSize)aMinSize
{
    _minSize = CGSizeCreateCopy(aMinSize);
}

- (CGSize)maxSize
{
    return _maxSize;
}

- (void)setMaxSize:(CGSize)aMaxSize
{
    _maxSize = CGSizeCreateCopy(aMaxSize);
}

// Visibility Priority

- (int)visibilityPriority
{
    return _visibilityPriority;
}

- (void)setVisibilityPriority:(int)aVisibilityPriority
{
    _visibilityPriority = aVisibilityPriority;
}

@end

@implementation CPToolbarItem (CPCopying)

- (id)copy
{
    var copy = [[[self class] alloc] initWithItemIdentifier:_itemIdentifier];
    
    [copy setLabel:_label];
    [copy setPaletteLabel:_paletteLabel];
    [copy setToolTip:_toolTip];
    
    [copy setTag:_tag];
    [copy setTarget:_target];
    [copy setAction:_action];
    
    [copy setEnabled:_isEnabled];
    [copy setImage:_image];
    [copy setAlternateImage:_alternateImage];
    
    if (_view)
        [copy setView:[CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:_view]]];

    [copy setMinSize:_minSize];
    [copy setMaxSize:_maxSize];
    
    [copy setVisibilityPriority:_visibilityPriority];
    
    return copy;
}

@end

// Standard toolbar identifiers

@implementation CPToolbarItem (Standard)

+ (CPToolbarItem)_standardItemWithItemIdentifier:(CPString)anItemIdentifier
{
    var item = [[CPToolbarItem alloc] initWithItemIdentifier:anItemIdentifier];                                                        

    switch (anItemIdentifier)
    {
        case CPToolbarSeparatorItemIdentifier:          return nil;

        case CPToolbarSpaceItemIdentifier:              [item setMinSize:CGSizeMake(32.0, 32.0)];
                                                        [item setMaxSize:CGSizeMake(32.0, 32.0)];
                                                        
                                                        return item;
                                                        
        case CPToolbarFlexibleSpaceItemIdentifier:      [item setMinSize:CGSizeMake(32.0, 32.0)];
                                                        [item setMaxSize:CGSizeMake(10000.0, 32.0)];
                                                        
                                                        return item;
                                                        
        case CPToolbarShowColorsItemIdentifier:         return nil;
        case CPToolbarShowFontsItemIdentifier:          return nil;
        case CPToolbarCustomizeToolbarItemIdentifier:   return nil;
        case CPToolbarPrintItemIdentifier:              return nil;
    }
    
    return nil;
}

@end
