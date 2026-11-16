/*
 * CPTableView+Bindings.j
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

@import "CPTableViewCore.j"


@class CPButton
@class CPClipView
@class CPUserDefaults
@class CPTableHeaderView
@class CPTableView
@class _CPTableColumnHeaderView
@class CPClipView
@class CPButton
@class _CPDropOperationDrawingView


@implementation CPTableView (Bindings)

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding == @"content")
        return [CPTableContentBinder class];

    return [super _binderClassForBinding:aBinding];
}

/*!
    @ignore
*/
- (CPString)_replacementKeyPathForBinding:(CPString)aBinding
{
    if (aBinding === @"selectionIndexes")
        return @"selectedRowIndexes";

    return [super _replacementKeyPathForBinding:aBinding];
}

/*!
    @ignore
*/
- (void)_establishBindingsIfUnbound:(id)destination
{
    if ([[self infoForBinding:@"content"] objectForKey:CPObservedObjectKey] !== destination)
    {
        [super bind:@"content" toObject:destination withKeyPath:@"arrangedObjects" options:nil];
        _contentBindingExplicitlySet = NO;
    }

    // If the content binding was set manually assume the user is taking manual control of establishing bindings.
    if (!_contentBindingExplicitlySet)
    {
        if ([[self infoForBinding:@"selectionIndexes"] objectForKey:CPObservedObjectKey] !== destination)
            [self bind:@"selectionIndexes" toObject:destination withKeyPath:@"selectionIndexes" options:nil];

        if ([[self infoForBinding:@"sortDescriptors"] objectForKey:CPObservedObjectKey] !== destination)
            [self bind:@"sortDescriptors" toObject:destination withKeyPath:@"sortDescriptors" options:nil];
    }
}

- (void)bind:(CPString)aBinding toObject:(id)anObject withKeyPath:(CPString)aKeyPath options:(CPDictionary)options
{
    if (aBinding == @"content")
        _contentBindingExplicitlySet = YES;
    else if (aBinding == @"doubleClickTarget")
    {
        if ([options objectForKey:CPSelectorNameBindingOption])
            [self setDoubleAction:CPSelectorFromString([options objectForKey:CPSelectorNameBindingOption])];
    }

    [super bind:aBinding toObject:anObject withKeyPath:aKeyPath options:options];
}

@end


@implementation CPTableContentBinder : CPBinder
{
    id _content @accessors(property=content);
}

- (void)setValueFor:(CPString)aBinding
{
    var destination = [_info objectForKey:CPObservedObjectKey],
        keyPath = [_info objectForKey:CPObservedKeyPathKey];

    _content = [destination valueForKey:keyPath];
    // FIXME: reload data for all rows or just exposed rows ?
    [_source _reloadDataViews];
}

@end
