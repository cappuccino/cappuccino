/*
 * NSSplitViewController.j
 * nib2cib
 *
 * Created by Daniel Boehringer.
 * Copyright 2025 The Cappuccino Project.
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

@import <AppKit/CPSplitViewController.j>


@implementation CPSplitViewController (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super NS_initWithCoder:aCoder])
    {
        _splitViewItems = [CPMutableArray array];
        _minimumThicknessForInlineSidebars = 20.0;

        if ([aCoder containsValueForKey:@"NSSplitView"])
            _splitView = [aCoder decodeObjectForKey:@"NSSplitView"];
        else if ([[self view] isKindOfClass:[CPSplitView class]])
            _splitView = [self view];

        if (_splitView)
            [_splitView setDelegate:self];

        if ([aCoder containsValueForKey:@"NSSplitViewItems"])
        {
            var items = [aCoder decodeObjectForKey:@"NSSplitViewItems"];
            for (var i = 0; i < [items count]; i++)
            {
                [self addSplitViewItem:items[i]];
            }
        }
    }

    return self;
}

@end

@implementation NSSplitViewController : CPSplitViewController
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPSplitViewController class];
}

@end


@implementation CPSplitViewItem (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        _viewController = [aCoder decodeObjectForKey:@"NSViewController"];
        _isCollapsed = [aCoder decodeBoolForKey:@"NSCollapsed"];
    }

    return self;
}

@end

@implementation NSSplitViewItem : CPSplitViewItem
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPSplitViewItem class];
}

@end