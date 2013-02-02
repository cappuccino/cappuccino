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

@import "CPImage.j"
@import "CPView.j"

@global CPApp

CPToolbarItemVisibilityPriorityStandard = 0;
CPToolbarItemVisibilityPriorityLow      = -1000;
CPToolbarItemVisibilityPriorityHigh     = 1000;
CPToolbarItemVisibilityPriorityUser     = 2000;

CPToolbarSeparatorItemIdentifier        = @"CPToolbarSeparatorItem";
CPToolbarSpaceItemIdentifier            = @"CPToolbarSpaceItem";
CPToolbarFlexibleSpaceItemIdentifier    = @"CPToolbarFlexibleSpaceItem";
CPToolbarShowColorsItemIdentifier       = @"CPToolbarShowColorsItem";
CPToolbarShowFontsItemIdentifier        = @"CPToolbarShowFontsItem";
CPToolbarCustomizeToolbarItemIdentifier = @"CPToolbarCustomizeToolbarItem";
CPToolbarPrintItemIdentifier            = @"CPToolbarPrintItem";

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

    BOOL        _autovalidates;
}

- (id)init
{
    return [self initWithItemIdentifier:@""];
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
        _autovalidates = YES;
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

/* @ignore */
- (void)_setToolbar:(CPToolbar)aToolbar
{
    _toolbar = aToolbar;
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
        [_view setToolTip:aToolTip];

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
    Sets the target of the action that is triggered when the user clicks this item. \c nil will cause
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
    Returns \c YES if the item is enabled.
*/
- (BOOL)isEnabled
{
    if ([_view respondsToSelector:@selector(isEnabled)])
        return [_view isEnabled];

    return _isEnabled;
}

/*!
    Sets whether the item is enabled.
    @param aFlag \c YES enables the item
*/
- (void)setEnabled:(BOOL)shouldBeEnabled
{
    if (_isEnabled === shouldBeEnabled)
        return;

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

    if (_minSize.width === 0 && _minSize.height === 0 &&
        _maxSize.width === 0 && _maxSize.height === 0)
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
    if (!aMinSize.height || !aMinSize.width)
        return;

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
    if (!aMaxSize.height || !aMaxSize.width)
        return;

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

- (void)validate
{
    var action = [self action],
        target = [self target];

    // View items do not do any target-action analysis.
    if (_view)
    {
        if ([target respondsToSelector:@selector(validateToolbarItem:)])
        {
            var shouldBeEnabled = [target validateToolbarItem:self];
            if (_isEnabled !== shouldBeEnabled)
                [self setEnabled:shouldBeEnabled];
        }

        return;
    }

    if (!action)
    {
        if (_isEnabled)
            return [self setEnabled:NO];
        return;
    }

    if (target && ![target respondsToSelector:action])
    {
        if (_isEnabled)
            return [self setEnabled:NO];
        return;
    }

    target = [CPApp targetForAction:action to:target from:self];

    if (!target)
    {
        if (_isEnabled)
            return [self setEnabled:NO];
        return;
    }

    if ([target respondsToSelector:@selector(validateToolbarItem:)])
    {
        var shouldBeEnabled = [target validateToolbarItem:self];
        if (_isEnabled !== shouldBeEnabled)
            [self setEnabled:shouldBeEnabled];
    }
    else
    {
        if (!_isEnabled)
            [self setEnabled:YES];
    }
}

- (BOOL)autovalidates
{
    return _autovalidates;
}

- (void)setAutovalidates:(BOOL)shouldAutovalidate
{
    _autovalidates = !!shouldAutovalidate;
}

@end

var CPToolbarItemItemIdentifierKey      = @"CPToolbarItemItemIdentifierKey",
    CPToolbarItemLabelKey               = @"CPToolbarItemLabelKey",
    CPToolbarItemPaletteLabelKey        = @"CPToolbarItemPaletteLabelKey",
    CPToolbarItemToolTipKey             = @"CPToolbarItemToolTipKey",
    CPToolbarItemTagKey                 = @"CPToolbarItemTagKey",
    CPToolbarItemTargetKey              = @"CPToolbarItemTargetKey",
    CPToolbarItemActionKey              = @"CPToolbarItemActionKey",
    CPToolbarItemEnabledKey             = @"CPToolbarItemEnabledKey",
    CPToolbarItemImageKey               = @"CPToolbarItemImageKey",
    CPToolbarItemAlternateImageKey      = @"CPToolbarItemAlternateImageKey",
    CPToolbarItemViewKey                = @"CPToolbarItemViewKey",
    CPToolbarItemMinSizeKey             = @"CPToolbarItemMinSizeKey",
    CPToolbarItemMaxSizeKey             = @"CPToolbarItemMaxSizeKey",
    CPToolbarItemVisibilityPriorityKey  = @"CPToolbarItemVisibilityPriorityKey",
    CPToolbarItemAutovalidatesKey       = @"CPToolbarItemAutovalidatesKey";

@implementation CPToolbarItem (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _itemIdentifier = [aCoder decodeObjectForKey:CPToolbarItemItemIdentifierKey];

        _minSize = [aCoder decodeSizeForKey:CPToolbarItemMinSizeKey];
        _maxSize = [aCoder decodeSizeForKey:CPToolbarItemMaxSizeKey];

        [self setLabel:[aCoder decodeObjectForKey:CPToolbarItemLabelKey]];
        [self setPaletteLabel:[aCoder decodeObjectForKey:CPToolbarItemPaletteLabelKey]];
        [self setToolTip:[aCoder decodeObjectForKey:CPToolbarItemToolTipKey]];

        [self setTag:[aCoder decodeObjectForKey:CPToolbarItemTagKey]];
        [self setTarget:[aCoder decodeObjectForKey:CPToolbarItemTargetKey]];
        [self setAction:CPSelectorFromString([aCoder decodeObjectForKey:CPToolbarItemActionKey])];

        [self setEnabled:[aCoder decodeBoolForKey:CPToolbarItemEnabledKey]];

        [self setImage:[aCoder decodeObjectForKey:CPToolbarItemImageKey]];
        [self setAlternateImage:[aCoder decodeObjectForKey:CPToolbarItemAlternateImageKey]];

        [self setView:[aCoder decodeObjectForKey:CPToolbarItemViewKey]];

        [self setVisibilityPriority:[aCoder decodeIntForKey:CPToolbarItemVisibilityPriorityKey]];
        [self setAutovalidates:[aCoder decodeBoolForKey:CPToolbarItemAutovalidatesKey]];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_itemIdentifier forKey:CPToolbarItemItemIdentifierKey];

    [aCoder encodeObject:[self label] forKey:CPToolbarItemLabelKey];
    [aCoder encodeObject:[self paletteLabel] forKey:CPToolbarItemPaletteLabelKey];

    [aCoder encodeObject:[self toolTip] forKey:CPToolbarItemToolTipKey];

    [aCoder encodeObject:[self tag] forKey:CPToolbarItemTagKey];
    [aCoder encodeObject:[self target] forKey:CPToolbarItemTargetKey];
    [aCoder encodeObject:[self action] forKey:CPToolbarItemActionKey];

    [aCoder encodeObject:[self isEnabled] forKey:CPToolbarItemEnabledKey];

    [aCoder encodeObject:[self image] forKey:CPToolbarItemImageKey];
    [aCoder encodeObject:[self alternateImage] forKey:CPToolbarItemAlternateImageKey];

    [aCoder encodeObject:[self view] forKey:CPToolbarItemViewKey];

    [aCoder encodeSize:[self minSize] forKey:CPToolbarItemMinSizeKey];
    [aCoder encodeSize:[self maxSize] forKey:CPToolbarItemMaxSizeKey];

    [aCoder encodeObject:[self visibilityPriority] forKey:CPToolbarItemVisibilityPriorityKey];
    [aCoder encodeBool:[self autovalidates] forKey:CPToolbarItemAutovalidatesKey];
}

@end

@implementation CPToolbarItem (CPCopying)

- (id)copy
{
    var copy = [[[self class] alloc] initWithItemIdentifier:_itemIdentifier];

    if (_view)
        [copy setView:[CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:_view]]];

    [copy _setToolbar:_toolbar];

    [copy setLabel:_label];
    [copy setPaletteLabel:_paletteLabel];
    [copy setToolTip:[self toolTip]];

    [copy setTag:[self tag]];
    [copy setTarget:[self target]];
    [copy setAction:[self action]];

    [copy setEnabled:[self isEnabled]];

    [copy setImage:[self image]];
    [copy setAlternateImage:[self alternateImage]];

    [copy setMinSize:_minSize];
    [copy setMaxSize:_maxSize];

    [copy setVisibilityPriority:[self visibilityPriority]];
    [copy setAutovalidates:[self autovalidates]];

    return copy;
}

@end

// Standard toolbar identifiers

@implementation CPToolbarItem (Standard)

/* @ignore */
+ (CPToolbarItem)_standardItemWithItemIdentifier:(CPString)anItemIdentifier
{
    switch (anItemIdentifier)
    {
        case CPToolbarSeparatorItemIdentifier:          return [_CPToolbarSeparatorItem new];
        case CPToolbarSpaceItemIdentifier:              return [_CPToolbarSpaceItem new];
        case CPToolbarFlexibleSpaceItemIdentifier:      return [_CPToolbarFlexibleSpaceItem new];
        case CPToolbarShowColorsItemIdentifier:         return [_CPToolbarShowColorsItem new];
        case CPToolbarShowFontsItemIdentifier:          return nil;
        case CPToolbarCustomizeToolbarItemIdentifier:   return nil;
        case CPToolbarPrintItemIdentifier:              return nil;
    }

    return nil;
}

@end

/*@import "_CPToolbarFlexibleSpaceItem.j"
@import "_CPToolbarShowColorsItem.j"
@import "_CPToolbarSeparatorItem.j"
@import "_CPToolbarSpaceItem.j"
*/
