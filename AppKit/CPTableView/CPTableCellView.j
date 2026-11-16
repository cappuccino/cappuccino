/*
 * CPTableCellView.j
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


@implementation CPTableCellView : CPView
{
    id _objectValue         @accessors(property=objectValue);

    CPTextField _textField  @accessors(property=textField);
    CPImageView _imageView  @accessors(property=imageView);
}

- (void)awakeFromCib
{
    [super awakeFromCib];
    [self setThemeState:CPThemeStateTableDataView];
}

- (BOOL)setThemeState:(ThemeState)aState
{
    [super setThemeState:aState];
    [self recursivelyPerformSelector:@selector(setThemeState:) withObject:aState startingFrom:self];
}

- (BOOL)unsetThemeState:(ThemeState)aState
{
    [super unsetThemeState:aState];
    [self recursivelyPerformSelector:@selector(unsetThemeState:) withObject:aState startingFrom:self];
}

- (void)recursivelyPerformSelector:(SEL)selector withObject:(id)anObject startingFrom:(id)aView
{
    [[aView subviews] enumerateObjectsUsingBlock:function(view, idx)
    {
        [view performSelector:selector withObject:anObject];

        if (![view isKindOfClass:[self class]]) // Avoid infinite loop if a subview is a CPTableCellView.
            [self recursivelyPerformSelector:selector withObject:anObject startingFrom:view];
    }];
}

- (CPString)description
{
    return "<" + [self className] + " 0x" + [CPString stringWithHash:[self UID]] + " identifier=" + [self identifier] + ">";
}


@end

