/*
 * TableViewDataSource.j
 * AppKit Tests
 *
 * Created by Alexander Ljungberg.
 * Copyright 2010, WireLoad, LLC.
 *
 * Adapted from TableViewDataSource.m in WithAndWithoutBindings by Apple Inc.
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

@import "Bookmark.j"
@import "MyDocument.j"

@implementation MyDocument (TableView)

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return [collection count];
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(int)rowIndex
{
    var objectAtRow = [collection objectAtIndex:rowIndex],
        columnKey = [aTableColumn identifier];

    return  [objectAtRow valueForKey:columnKey];
}

- (void)tableView:(CPTableView)aTableView setObjectValue:(id)anObject forTableColumn:(CPTableColumn)aTableColumn row:(int)rowIndex
{
    var objectAtRow = [collection objectAtIndex:rowIndex],
        columnKey = [aTableColumn identifier];

    [objectAtRow setValue:anObject forKey:columnKey];
}

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    [self updateSelectionDetailFields];
}

// TODO Drag and drop is not implemented since it's difficult to test in a unit test and not all that relevant in a bindings context anyhow.

// - (BOOL)tableView:(CPTableView)aTableView writeRowsWithIndexes:(CPIndexSet)rowIndexes toPasteboard:(CPPasteboard)pboard
// - (CPDragOperation)tableView:(CPTableView)tv validateDrop:(id)info proposedRow:(int)row proposedDropOperation:(CPTableViewDropOperation)op
// - (BOOL)tableView:(CPTableView)tv acceptDrop:(id)info row:(int)row dropOperation:(CPTableViewDropOperation)op
// - (void)awakeFromNib

@end
