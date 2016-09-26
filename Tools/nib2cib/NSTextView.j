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

@import <AppKit/CPTextView.j>

@import "NSTextViewSharedData.j"

@class Nib2Cib

@implementation CPTextView (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder textViewSharedData:(CPTextViewSharedData)aTextViewSharedData
{
    if (self = [super NS_initWithCoder:aCoder])
    {
        _textContainer = [aCoder decodeObjectForKey:@"NSTextContainer"];

        [self setEditable:[aTextViewSharedData isEditable]];
        [self setSelectable:[aTextViewSharedData isSelectable]];
        [self setRichText:[aTextViewSharedData isRichText]];
        [self setAllowsUndo:[aTextViewSharedData allowsUndo]];
        [self setUsesFontPanel:[aTextViewSharedData usesFontPanel]];

        [self setBackgroundColor:[aTextViewSharedData backgroundColor]];
        [self setInsertionPointColor:[aTextViewSharedData insertionColor]];
        [self setSelectedTextAttributes:[aTextViewSharedData selectedTextAttributes]];
        [[self textContainer] setWidthTracksTextView:YES];
    }

    return self;
}

@end

@implementation NSTextView : CPTextView
{

}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [self NS_initWithCoder:aCoder textViewSharedData:[aCoder decodeObjectForKey:@"NSSharedData"]])
    {

    }

    return self;
}

- (Class)classForKeyedArchiver
{
    return [CPTextView class];
}

@end
