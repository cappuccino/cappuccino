/*
 * WithBindingsTest.j
 * AppKit Tests
 *
 * Created by Alexander Ljungberg.
 * Copyright 2010, WireLoad, LLC.
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

@import <AppKit/CPApplication.j>

@import "MyDocument2.j"
@import "StringToURLTransformer.j"

/*!
    Bindings test exercising the functionality seen in the Cocoa example "WithAndWithoutBindings" part 1. Part 1 does in fact not use bindings and serves only as a base line test case.
*/
@implementation WithBindingsTest : OJTestCase
{
}

- (void)setUp
{
    // CPApp must be initialised or action sending will not work.
    [CPApplication sharedApplication];
}

- (void)test
{
    var theDocument = [MyDocument2 new],
        cib = [CPBundle loadCibFile:[[CPBundle bundleForClass:WithBindingsTest] pathForResource:"02_WithBindings.cib"] externalNameTable:[CPDictionary dictionaryWithObject:theDocument forKey:CPCibOwner]];

    [theDocument windowControllerDidLoadCib:self];

    [theDocument.nameField setStringValue:@"Document A"];
    [theDocument.nameField performClick:self];
    [self assert:@"Document A" equals:[theDocument name]];

    [self assert:@"No Selection" equals:[theDocument.selectedBookmarkTitleField placeholderString]];
    [self assert:@"No Selection" equals:[theDocument.selectedBookmarkURLField placeholderString]];

    [theDocument.addButton performClick:self];
    [theDocument.addButton performClick:self];
    [self assert:2 equals:[theDocument.collection count]];

    [theDocument.tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO]

    [self assert:@"new title" equals:[theDocument.selectedBookmarkTitleField stringValue]];
    [self assert:@"" equals:[theDocument.selectedBookmarkURLField stringValue]];

    // Edit the selected entry.
    [theDocument.selectedBookmarkTitleField setStringValue:@"A Title"];
    [theDocument.selectedBookmarkTitleField performClick:self];
    [self assert:@"A Title" equals:[theDocument.collection[0] title] message:"changing selectedBookmarkTitleField updated the model title"];

    [theDocument.selectedBookmarkURLField setStringValue:@"http://www.slevenbits.com"];
    [theDocument.selectedBookmarkURLField performClick:self];
    [self assert:[CPURL URLWithString:@"http://www.slevenbits.com"] equals:[theDocument.collection[0] URL]];

    // Edit the other entry.
    [theDocument.tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:1] byExtendingSelection:NO]
    [theDocument.selectedBookmarkTitleField setStringValue:@"Another Title"];
    [theDocument.selectedBookmarkTitleField performClick:self];
    [self assert:@"Another Title" equals:[theDocument.collection[1] title]];

    [theDocument.selectedBookmarkURLField setStringValue:@"http://www.cappuccino-project.org"];
    [theDocument.selectedBookmarkURLField performClick:self];
    [self assert:[CPURL URLWithString:@"http://www.cappuccino-project.org"] equals:[theDocument.collection[1] URL]];

    // Verify the first entry remains.
    [theDocument.tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO]
    [self assert:@"A Title" equals:[theDocument.selectedBookmarkTitleField stringValue] message:"first entry should not change when the second is deleted"];
    [self assert:@"http://www.slevenbits.com" equals:[theDocument.selectedBookmarkURLField stringValue]];

    // Remove it.
    [theDocument.removeButton performClick:self];
    [self assert:@"Another Title" equals:[theDocument.selectedBookmarkTitleField stringValue]];
    [self assert:@"http://www.cappuccino-project.org" equals:[theDocument.selectedBookmarkURLField stringValue]];
}

@end
