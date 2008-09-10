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

/*
    @global
    @class CPToolbarItem
*/
CPToolbarItemVisibilityPriorityStandard = 0;
/*
    @global
    @class CPToolbarItem
*/
CPToolbarItemVisibilityPriorityLow      = -1000;
/*
    @global
    @class CPToolbarItem
*/
CPToolbarItemVisibilityPriorityHigh     = 1000;
/*
    @global
    @class CPToolbarItem
*/
CPToolbarItemVisibilityPriorityUser     = 2000;

CPToolbarSeparatorItemIdentifier        = @"CPToolbarSeparatorItemIdentifier";
CPToolbarSpaceItemIdentifier            = @"CPToolbarSpaceItemIdentifier";
CPToolbarFlexibleSpaceItemIdentifier    = @"CPToolbarFlexibleSpaceItemIdentifier";
CPToolbarShowColorsItemIdentifier       = @"CPToolbarShowColorsItemIdentifier";
CPToolbarShowFontsItemIdentifier        = @"CPToolbarShowFontsItemIdentifier";
CPToolbarCustomizeToolbarItemIdentifier = @"CPToolbarCustomizeToolbarItemIdentifier";
CPToolbarPrintItemIdentifier            = @"CPToolbarPrintItemIdentifier";

/*
    A representation of an item in a <objj>CPToolbar</objj>.
*/
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
/*
    Initializes the toolbar item with a specified identifier.
    @param anItemIdentifier the item's identifier
    @return the initialized toolbar item
*/
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
/*
    Returns the item's identifier.
*/
- (CPString)itemIdentifier
{
    return _itemIdentifier;
}

/*
    Returns the toolbar of which this item is a part.
*/
- (CPToolbar)toolbar
{
    return _toolbar;
}

/*
    Returns the item's label
*/
- (CPString)label
{
    return _label;
}

/*
    Sets the item's label.
    @param aLabel the new label for the item
*/
- (void)setLabel:(CPString)aLabel
{
    _label = aLabel;
}

/*
    Returns the palette label.
*/
- (CPString)paletteLabel
{
    return _paletteLabel;
}

/*
    Sets the palette label
    @param aPaletteLabel the new palette label
*/
- (void)setPaletteLabel:(CPString)aPaletteLabel
{
    _paletteLabel = aPaletteLabel;
}

/*
    Returns the item's tooltip. A tooltip pops up
    next to the cursor when the user hovers over
    the item with the mouse.
*/
- (CPString)toolTip
{
    return _toolTip;
}

/*
    Sets the item's tooltip. A tooltip pops up next to the cursor when the user hovers over the item with the mouse.
    @param aToolTip the new item tool tip
*/
- (void)setToolTip:(CPString)aToolTip
{
    _toolTip = aToolTip;
}

/*
    Returns the item's tag.
*/
- (int)tag
{
    return _tag;
}

/*
    Sets the item's tag.
    @param aTag the new tag for the item
*/
- (void)setTag:(int)aTag
{
    _tag = aTag;
}

/*
    Returns the item's action target.
*/
- (id)target
{
    return _target;
}

/*
    Sets the target of the action that is triggered when the user clicks this item. <code>nil</code> will cause 
    the action to be passed on to the first responder.
    @param aTarget the new target
*/
- (void)setTarget:(id)aTarget
{
    _target = aTarget;
    
    [_view setTarget:aTarget];
}

/*
    Returns the action that is triggered when the user clicks this item.
*/
- (SEL)action
{
    return _action;
}

/*
    Sets the action that is triggered when the user clicks this item.
    @param anAction the new action
*/
- (void)setAction:(SEL)anAction
{
    _action = anAction;

    [_view setAction:anAction];
}

/*
    Returns <code>YES</code> if the item is enabled.
*/
- (BOOL)isEnabled
{
    return _isEnabled;
}

/*
    Sets whether the item is enabled.
    @param aFlag <code>YES</code> enables the item
*/
- (void)setEnabled:(BOOL)aFlag
{
    _isEnabled = aFlag;
}

/*
    Returns the item's image
*/
- (CPImage)image
{
    return _image;
}

/*
    Sets the item's image.
    @param anImage the new item image
*/
- (void)setImage:(CPImage)anImage
{
    _image = anImage;
    
    [_view setImage:anImage];
}

/*
    Sets the alternate image. This image is displayed on the item when the user is clicking it.
    @param anImage the new alternate image
*/
- (void)setAlternateImage:(CPImage)anImage
{
    _alternateImage = anImage;
    
    [_view setAlternateImage:anImage];
}

/*
    Returns the alternate image. This image is displayed on the item when the user is clicking it.
*/
- (CPImage)alternateImage
{
    return _alternateImage;
}

/*
    Returns the item's view.
*/
- (CPView)view
{
    return _view;
}

/*
    Sets the item's view
    @param aView the item's new view
*/
- (void)setView:(CPView)aView
{
    _view = aView;
}

/*
    Returns the item's minimum size.
*/
- (CGSize)minSize
{
    return _minSize;
}

/*
    Sets the item's minimum size.
    @param aMinSize the new minimum size
*/
- (void)setMinSize:(CGSize)aMinSize
{
    _minSize = CGSizeCreateCopy(aMinSize);
}

/*
    Returns the item's maximum size.
*/
- (CGSize)maxSize
{
    return _maxSize;
}

/*
    Sets the item's new maximum size.
    @param aMaxSize the new maximum size
*/
- (void)setMaxSize:(CGSize)aMaxSize
{
    _maxSize = CGSizeCreateCopy(aMaxSize);
}

// Visibility Priority
/*
    Returns the item's visibility priority. The value will be one of:
<pre>
CPToolbarItemVisibilityPriorityStandard
CPToolbarItemVisibilityPriorityLow
CPToolbarItemVisibilityPriorityHigh
CPToolbarItemVisibilityPriorityUser
</pre>
*/
- (int)visibilityPriority
{
    return _visibilityPriority;
}

/*
    Sets the item's visibility priority. The value must be one of:
<pre>
CPToolbarItemVisibilityPriorityStandard
CPToolbarItemVisibilityPriorityLow
CPToolbarItemVisibilityPriorityHigh
CPToolbarItemVisibilityPriorityUser
</pre>
    @param aVisiblityPriority the priority
*/
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

/* @ignore */
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
