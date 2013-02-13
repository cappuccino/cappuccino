/*
 * _CPPopUpListDataSource.j
 * AppKit
 *
 * Created by Aparajita Fishman.
 * Copyright (c) 2012, The Cappuccino Foundation
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
@import <Foundation/CPException.j>

/*!
    This abstract base class defines the methods that delegates of _CPPopUpList must implement.
    You may either subclass this class to use the default implementation of
    list:objectValueForItemAtIndex: and list:displayValueForObjectValue: or use your
    own class and define these methods yourself.
*/
@implementation _CPPopUpListDataSource : CPObject

/*!
    Returns whether the given object conforms to the minimum protocol defined by this class.
*/
+ (BOOL)protocolIsImplementedByObject:(id)anObject
{
    return (anObject &&
            [anObject respondsToSelector:@selector(numberOfItemsInList:)] &&
            [anObject respondsToSelector:@selector(numberOfVisibleItemsInList:)] &&
            [anObject respondsToSelector:@selector(list:objectValueForItemAtIndex:)] &&
            [anObject respondsToSelector:@selector(list:displayValueForObjectValue:)] &&
            [anObject respondsToSelector:@selector(list:stringValueForObjectValue:)]);
}

/*!
    Returns the number of items managed by the list.
*/
- (int)numberOfItemsInList:(_CPPopUpList)aList
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

/*!
    Returns the number of items to display at one time.
*/
- (int)numberOfVisibleItemsInList:(_CPPopUpList)aList
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

/*!
    Returns the data for a given row index.
*/
- (id)list:(_CPPopUpList)aList objectValueForItemAtIndex:(int)index
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

/*!
    Returns a value to display for a single row in the list. Subclasses should override
    this if the table data needs to be converted or formatted in some way to be displayed.
    If your data source use a data representation other than CPStrings, you must override
    this method and return the appropriate data when there are no search results.

    If the _CPPopUpList's table uses a custom data view, this method should return a value suitable
    for sending to the setObjectValue: method of the data view.

    @param  aValue  Data for the given row
    @return         A value to be displayed in the list
*/
- (id)list:(_CPPopUpList)aList displayValueForObjectValue:(id)aValue
{
    return aValue || @"";
}

/*!
    Returns a single-line string representation for an object value. Subclasses should override
    this if the object data is not convertible to a simple single-line string.

    @param  aValue  Table data to be converted to a string
    @return         A value to be displayed in the autocomplete field
*/
- (CPString)list:(_CPPopUpList)aList stringValueForObjectValue:(id)aValue
{
   return String(aValue);
}

@end
