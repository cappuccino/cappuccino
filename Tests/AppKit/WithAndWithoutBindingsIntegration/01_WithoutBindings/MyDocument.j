/*
 * MyDocument.j
 * AppKit Tests
 *
 * Created by Alexander Ljungberg.
 * Copyright 2010, WireLoad, LLC.
 *
 * Adapted from MyDocument.m in WithAndWithoutBindings by Apple Inc.
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

@implementation MyDocument : CPDocument
{
    CPString            name @accessors;
    CPString            collectionDescription @accessors;
    CPArray             collection @accessors;

    @outlet CPTableView tableView;
    @outlet CPTextField nameField;

    @outlet CPTextField selectedBookmarkTitleField;
    @outlet CPTextField selectedBookmarkURLField;
}

- (id)init
{
    if (self = [super init])
    {
        collection = [CPArray array];
    }
    return self;
}

- (void)windowControllerDidLoadCib:(CPWindowController)aController
{
    [super windowControllerDidLoadCib:aController];

    [self updateSelectionDetailFields];
}

- (@action)nameFieldChanged:(id)sender
{
    [self setName:[nameField stringValue]];
}

- (@action)selectedBookmarkTitleFieldChanged:(id)sender
{
    var selectedRow = [tableView selectedRow];

    if (selectedRow === CPNotFound)
        return;

    var selectedBookmark = [collection objectAtIndex:selectedRow];
    [selectedBookmark setTitle:[selectedBookmarkTitleField stringValue]];
    [tableView reloadData];
}

- (@action)selectedBookmarkURLFieldChanged:(id)sender
{
    var selectedRow = [tableView selectedRow];

    if (selectedRow === CPNotFound)
        return;

    var URLString = [selectedBookmarkURLField stringValue],
        URL = [CPURL URLWithString:URLString],
        selectedBookmark = [collection objectAtIndex:selectedRow];

    [selectedBookmark setURL:URL];
    [tableView reloadData];
}

- (void)updateSelectionDetailFields
{
    var selectedRow = [tableView selectedRow];

    if (selectedRow === CPNotFound)
    {
        [selectedBookmarkTitleField setStringValue:@"No selection"];
        [selectedBookmarkTitleField setSelectable:NO];
        [selectedBookmarkURLField setStringValue:@"No selection"];
        [selectedBookmarkURLField setSelectable:NO];
    }
    else
    {
        var selectedBookmark = [collection objectAtIndex:selectedRow];

        [selectedBookmarkTitleField setStringValue:[selectedBookmark title]];
        [selectedBookmarkTitleField setEditable:YES];

        var URL = [selectedBookmark URL],
            URLString = @"No URL";

        if (URL)
            URLString = [URL absoluteString];

        [selectedBookmarkURLField setStringValue:URLString];
        [selectedBookmarkURLField setEditable:YES];
    }
}

- (@action)addBookmark:(id)sender
{
    var newBookmark = [Bookmark new];
    [newBookmark setCreationDate:[CPDate date]];
    [collection addObject:newBookmark];

    [tableView reloadData];
    [self updateSelectionDetailFields];
}

- (@action)removeSelectedBookmarks:(id)sender
{
    var selectedRows = [tableView selectedRowIndexes],
        currentIndex = [selectedRows lastIndex];

    while (currentIndex != CPNotFound)
    {
        [collection removeObjectAtIndex:currentIndex];
        currentIndex = [selectedRows indexLessThanIndex: currentIndex];
    }

    [tableView reloadData];
    [self updateSelectionDetailFields];
}

- (CPData)dataRepresentationOfType:(CPString)aType
{
    var data = [CPData data],
        archiver = [[CPKeyedArchiver alloc] initForWritingWithMutableData:data];

    [archiver encodeObject:name forKey:@"name"];
    [archiver encodeObject:collectionDescription forKey:@"collectionDescription"];
    [archiver encodeObject:collection forKey:@"collection"];

    [archiver finishEncoding];

    return data;
}

- (BOOL)loadDataRepresentation:(CPData)data ofType:(CPString)aType
{
    var unarchiver = [[CPKeyedUnarchiver alloc] initForReadingWithData:data];

    name = [unarchiver decodeObjectForKey:@"name"];
    collectionDescription = [unarchiver decodeObjectForKey:@"collectionDescription"];
    collection = [unarchiver decodeObjectForKey:@"collection"];

    [unarchiver finishDecoding];

    return YES;
}

- (void)setCollection:(CPArray)aCollection
{
    if (collection !== aCollection)
        collection = [aCollection copy];
}

@end

//@import "TableViewDataSource.j"

