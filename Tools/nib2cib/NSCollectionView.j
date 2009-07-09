/*
 * NSCollectionView.j
 * nib2cib
 *
 * Created by Marc Nijdam.
 * Copyright 2009, imadjine, LLC.
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

@import <AppKit/CPCollectionView.j>

@implementation CPCollectionView (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super NS_initWithCoder:aCoder])
    {
        _maxNumberOfRows    = [aCoder decodeIntForKey:@"NSMaxNumberOfGridRows"];
        _maxNumberOfColumns = [aCoder decodeIntForKey:@"NSMaxNumberOfGridColumns"];
        
        _isSelectable             = [aCoder decodeBoolForKey:@"NSSelectable"];
        _allowsMultipleSelection  = [aCoder decodeBoolForKey:@"NSAllowsMultipleSelection"];
        
    }
    
    return self;
}

@end

@implementation NSCollectionView : CPCollectionView
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPCollectionView class];
}

@end


@implementation CPCollectionViewItem (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    return [super init];
}

@end

@implementation NSCollectionViewItem : CPCollectionViewItem
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPCollectionViewItem class];
}

@end