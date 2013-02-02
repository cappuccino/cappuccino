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

@import <AppKit/CPButton.j>
@import <AppKit/CPDocument.j>
@import <AppKit/CPTableView.j>

@import "Bookmark2.j"
@import "TableViewDataSource.j"

@implementation MyDocument2 : CPDocument
{
    CPString            name @accessors;
    CPString            collectionDescription @accessors;
    CPArray             collection @accessors;

    @outlet CPTableView tableView;

    // For debugging only.
    @outlet CPTextField nameField;

    @outlet CPButton    addButton;
    @outlet CPButton    removeButton;
    @outlet MyArrayController arrayController;

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
