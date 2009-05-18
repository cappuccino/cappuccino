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

@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>

@import <AppKit/CPImage.j>
@import <AppKit/CPView.j>


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

/*! 
    @ingroup appkit
    @class CPToolbarItem

    A representation of an item in a CPToolbar.
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
/*!
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
     
        _tag = 0;
        _isEnabled = YES;
     
        _minSize = CGSizeMakeZero();
        _maxSize = CGSizeMakeZero();
     
        _visibilityPriority = CPToolbarItemVisibilityPriorityStandard;
    }
    
    return self;
}

// Managing Attributes
/*!
    Returns the item's identifier.
*/
- (CPString)itemIdentifier
{
    return _itemIdentifier;
}

/*!
    Returns the toolbar of which this item is a part.
*/
- (CPToolbar)toolbar
{
    return _toolbar;
}

/*!
    Returns the item's label
*/
- (CPString)label
{
    return _label;
}

/*!
    Sets the item's label.
    @param aLabel the new label for the item
*/
- (void)setLabel:(CPString)aLabel
{
    _label = aLabel;
}

/*!
    Returns the palette label.
*/
- (CPString)paletteLabel
{
    return _paletteLabel;
}

/*!
    Sets the palette label
    @param aPaletteLabel the new palette label
*/
- (void)setPaletteLabel:(CPString)aPaletteLabel
{
    _paletteLabel = aPaletteLabel;
}

/*!
    Returns the item's tooltip. A tooltip pops up
    next to the cursor when the user hovers over
    the item with the mouse.
*/
- (CPString)toolTip
{
    if ([_view respondsToSelector:@selector(toolTip)])
        return [_view toolTip];
    
    return _toolTip;
}

/*!
    Sets the item's tooltip. A tooltip pops up next to the cursor when the user hovers over the item with the mouse.
    @param aToolTip the new item tool tip
*/
- (void)setToolTip:(CPString)aToolTip
{
    if ([_view respondsToSelector:@selector(setToolTip:)])
        [view setToolTip:aToolTip];
    
    _toolTip = aToolTip;
}

/*!
    Returns the item's tag.
*/
- (int)tag
{
    if ([_view respondsToSelector:@selector(tag)])
        return [_view tag];
    
    return _tag;
}

/*!
    Sets the item's tag.
    @param aTag the new tag for the item
*/
- (void)setTag:(int)aTag
{
    if ([_view respondsToSelector:@selector(setTag:)])
        [_view setTag:aTag];
    
    _tag = aTag;
}

/*!
    Returns the item's action target.
*/
- (id)target
{
    if (_view)
        return [_view respondsToSelector:@selector(target)] ? [_view target] : nil;
    
    return _target;
}

/*!
    Sets the target of the action that is triggered when the user clicks this item. <code>nil</code> will cause 
    the action to be passed on to the first responder.
    @param aTarget the new target
*/
- (void)setTarget:(id)aTarget
{
    if (!_view)
        _target = aTarget;
    
    else if ([_view respondsToSelector:@selector(setTarget:)])
        [_view setTarget:aTarget];
}

/*!
    Returns the action that is triggered when the user clicks this item.
*/
- (SEL)action
{
    if (_view)
        return [_view respondsToSelector:@selector(action)] ? [_view action] : nil;
    
    return _action;
}

/*!
    Sets the action that is triggered when the user clicks this item.
    @param anAction the new action
*/
- (void)setAction:(SEL)anAction
{
    if (!_view)
        _action = anAction;

    else if ([_view respondsToSelector:@selector(setAction:)])
        [_view setAction:anAction];
}

/*!
    Returns <code>YES</code> if the item is enabled.
*/
- (BOOL)isEnabled
{
    if ([_view respondsToSelector:@selector(isEnabled)])
        return [_view isEnabled];
    
    return _isEnabled;
}

/*!
    Sets whether the item is enabled.
    @param aFlag <code>YES</code> enables the item
*/
- (void)setEnabled:(BOOL)shouldBeEnabled
{
    if ([_view respondsToSelector:@selector(setEnabled:)])
        [_view setEnabled:shouldBeEnabled];
    
    _isEnabled = shouldBeEnabled;
}

/*!
    Returns the item's image
*/
- (CPImage)image
{
    if ([_view respondsToSelector:@selector(image)])
        return [_view image];
        
    return _image;
}

/*!
    Sets the item's image.
    @param anImage the new item image
*/
- (void)setImage:(CPImage)anImage
{
    if ([_view respondsToSelector:@selector(setImage:)])
        [_view setImage:anImage];

    _image = anImage;
    
    if (!_image)
        return;
    
    if (_minSize.width == 0 && _minSize.height == 0 && 
        _maxSize.width == 0 && _maxSize.height == 0)
    {
        var imageSize = [_image size];

        if (imageSize.width > 0 || imageSize.height > 0)
        {
            [self setMinSize:imageSize];
            [self setMaxSize:imageSize];
        }
    }
}

/*!
    Sets the alternate image. This image is displayed on the item when the user is clicking it.
    @param anImage the new alternate image
*/
- (void)setAlternateImage:(CPImage)anImage
{
    if ([_view respondsToSelector:@selector(setAlternateImage:)])
        [_view setAlternateImage:anImage];
    
    _alternateImage = anImage;
}

/*!
    Returns the alternate image. This image is displayed on the item when the user is clicking it.
*/
- (CPImage)alternateImage
{
    if ([_view respondsToSelector:@selector(alternateIamge)])
        return [_view alternateImage];
    
    return _alternateImage;
}

/*!
    Returns the item's view.
*/
- (CPView)view
{
    return _view;
}

/*!
    Sets the item's view
    @param aView the item's new view
*/
- (void)setView:(CPView)aView
{
    if (_view == aView)
        return;
    
    _view = aView;

    if (_view)
    {
        // Tags get forwarded.
        if (_tag !== 0 && [_view respondsToSelector:@selector(setTag:)])
            [_view setTag:_tag];
        
        _target = nil;
        _action = nil;
    }
}

/*!
    Returns the item's minimum size.
*/
- (CGSize)minSize
{
    return _minSize;
}

/*!
    Sets the item's minimum size.
    @param aMinSize the new minimum size
*/
- (void)setMinSize:(CGSize)aMinSize
{
    _minSize = CGSizeMakeCopy(aMinSize);
    
    // Try to provide some sanity: Make maxSize >= minSize
    _maxSize = CGSizeMake(MAX(_minSize.width, _maxSize.width), MAX(_minSize.height, _maxSize.height));
}

/*!
    Returns the item's maximum size.
*/
- (CGSize)maxSize
{
    return _maxSize;
}

/*!
    Sets the item's new maximum size.
    @param aMaxSize the new maximum size
*/
- (void)setMaxSize:(CGSize)aMaxSize
{
    _maxSize = CGSizeMakeCopy(aMaxSize);
    
    // Try to provide some sanity: Make minSize <= maxSize
    _minSize = CGSizeMake(MIN(_minSize.width, _maxSize.width), MIN(_minSize.height, _maxSize.height));
}

// Visibility Priority
/*!
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

/*!
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
    
    if (_view)
        [copy setView:[CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:_view]]];
    
    [copy setLabel:_label];
    [copy setPaletteLabel:_paletteLabel];
    [copy setToolTip:[self toolTip]];
    
    [copy setTag:[self tag]];
    [copy setTarget:[self target]];
    [copy setAction:[self action]];
    
    [copy setEnabled:[self isEnabled]];
    [copy setImage:_image];
    [copy setAlternateImage:_alternateImage];
    
    [copy setMinSize:_minSize];
    [copy setMaxSize:_maxSize];
    
    [copy setVisibilityPriority:_visibilityPriority];
    
    return copy;
}

@end

// Standard toolbar identifiers

var _CPToolbarSeparatorItemView = nil,
    _CPToolbarSpaceItemView     = nil;

@implementation CPToolbarItem (Standard)

+ (CPView)_separatorItemView
{
    if (!_CPToolbarSeparatorItemView)
    {
        _CPToolbarSeparatorItemView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 2.0, 32.0)];
        
        sizes = {};
        sizes[@"CPToolbarItemSeparator"] = [CGSizeMake(2.0, 26.0), CGSizeMake(2.0, 1.0), CGSizeMake(2.0, 26.0)];
        [_CPToolbarSeparatorItemView setBackgroundColor:_CPControlThreePartImagePattern(YES, sizes, @"CPToolbarItem", @"Separator")];
    }

    return _CPToolbarSeparatorItemView;
}

+ (CPView)_spaceItemView
{
    if (!_CPToolbarSpaceItemView)
        _CPToolbarSpaceItemView = [[CPView alloc] initWithFrame:CGRectMakeZero()];
    
    return _CPToolbarSpaceItemView;
}

/* @ignore */
+ (CPToolbarItem)_standardItemWithItemIdentifier:(CPString)anItemIdentifier
{
    var item = [[CPToolbarItem alloc] initWithItemIdentifier:anItemIdentifier];                                                        

    switch (anItemIdentifier)
    {
        case CPToolbarSeparatorItemIdentifier:          [item setView:[self _separatorItemView]];
                                                        
                                                        [item setMinSize:CGSizeMake(2.0, 0.0)];
                                                        [item setMaxSize:CGSizeMake(2.0, 100000.0)];
                                                        
                                                        return item;

        case CPToolbarSpaceItemIdentifier:              [item setView:[self _spaceItemView]];
                                                        
                                                        [item setMinSize:CGSizeMake(32.0, 32.0)];
                                                        [item setMaxSize:CGSizeMake(32.0, 32.0)];
                                                        
                                                        return item;
                                                        
        case CPToolbarFlexibleSpaceItemIdentifier:      [item setView:[self _spaceItemView]];
        
                                                        [item setMinSize:CGSizeMake(32.0, 32.0)];
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
