/*
 * NSTextView.j
 * nib2cib
 *
 * Created by Alexendre Wilhelm.
 * Copyright 2014 The Cappuccino Foundation.
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

@import <Foundation/Foundation.j>
@import <AppKit/CPColor.j>
@import <AppKit/CPParagraphStyle.j>

@class Nib2Cib

@implementation CPTextViewSharedData : CPObject
{
    BOOL                _allowsUndo             @accessors(getter=allowsUndo);
    BOOL                _editable               @accessors(getter=isEditable);
    BOOL                _richText               @accessors(getter=isRichText);
    BOOL                _selectable             @accessors(getter=isSelectable);
    BOOL                _usesFontPanel          @accessors(getter=usesFontPanel);
    CPColor             _backgroundColor        @accessors(getter=backgroundColor);
    CPColor             _insertionColor         @accessors(getter=insertionColor);
    CPDictionary        _selectedTextAttributes @accessors(getter=selectedTextAttributes);
}

- (id)init
{
    if (self = [super init])
    {

    }

    return self;
}

@end


@implementation CPTextViewSharedData (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        var flags = [aCoder decodeIntForKey:@"NSFlags"];

        _allowsUndo = (flags & 0x0000400) ? YES : NO;
        _editable = (flags & 0x00000002) ? YES : NO;
        _richText = (flags & 0x00000004) ? YES : NO;
        _selectable = (flags & 0x00000001) ? YES : NO;
        _usesFontPanel = (flags & 0x00000020) ? YES : NO;

        _backgroundColor = [aCoder decodeObjectForKey:@"NSBackgroundColor"];
        _insertionColor = [aCoder decodeObjectForKey:@"NSInsertionColor"];
        _selectedTextAttributes = [aCoder decodeObjectForKey:@"NSSelectedAttributes"];
    }

    return self;
}

@end

@implementation NSTextViewSharedData : CPTextViewSharedData
{

}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [self NS_initWithCoder:aCoder];

    if (self)
    {

    }

    return self;
}

- (Class)classForKeyedArchiver
{
    return [CPTextViewSharedData class];
}

@end
