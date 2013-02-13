/*
 * CPCollectionViewItem.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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

@import "CPViewController.j"

/*!
    Represents an object inside a CPCollectionView.
*/
@implementation CPCollectionViewItem : CPViewController
{
    BOOL    _isSelected;
    CPData  _cachedArchive;
}

- (id)copy
{
    var cibName = [self cibName],
        copy;

    if (cibName)
    {
        copy = [[[self class] alloc] initWithCibName:cibName bundle:[self cibBundle]];
    }
    else
    {
        if (!_cachedArchive)
            _cachedArchive = [CPKeyedArchiver archivedDataWithRootObject:self];

        copy = [CPKeyedUnarchiver unarchiveObjectWithData:_cachedArchive];

        // copy connections
    }

    [copy setRepresentedObject:[self representedObject]];
    [copy setSelected:_isSelected];

    return copy;
}

// Setting the Represented Object
/*!
    Sets the object to be represented by this item.
    @param anObject the object to be represented
*/
- (void)setRepresentedObject:(id)anObject
{
    [super setRepresentedObject:anObject];

    var view = [self view];

    if ([view respondsToSelector:@selector(setRepresentedObject:)])
        [view setRepresentedObject:[self representedObject]];
}

// Modifying the Selection
/*!
    Sets whether this view item should be selected.
    @param shouldBeSelected \c YES makes the item selected. \c NO deselects it.
*/
- (void)setSelected:(BOOL)shouldBeSelected
{
    shouldBeSelected = !!shouldBeSelected;

    if (_isSelected === shouldBeSelected)
        return;

    _isSelected = shouldBeSelected;

    var view = [self view];

    if ([view respondsToSelector:@selector(setSelected:)])
        [view setSelected:[self isSelected]];
}

/*!
    Returns \c YES if the item is currently selected. \c NO if the item is not selected.
*/
- (BOOL)isSelected
{
    return _isSelected;
}

// Parent Collection View
/*!
    Returns the collection view of which this item is a part.
*/
- (CPCollectionView)collectionView
{
    return [_view superview];
}

@end
