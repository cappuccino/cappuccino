/*
 * NSSearchField.j
 * nib2cib
 *
 * Created by Francisco Tolmasky.
 * Copyright 2010, 280 North, Inc.
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

@import <AppKit/CPSearchField.j>

@import "NSTextField.j"

@class Nib2Cib


@implementation CPSearchField (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    return [super NS_initWithCoder:aCoder];
}

- (void)NS_initWithCell:(NSCell)cell
{
    [super NS_initWithCell:cell];

    [self setRecentsAutosaveName:[cell recentsAutosaveName]];
    [self setMaximumRecents:[cell maximumRecents]];
    [self setSendsWholeSearchString:[cell sendsWholeSearchString]];
    [self setSendsSearchStringImmediately:[cell sendsSearchStringImmediately]];

    if ([[Nib2Cib defaultTheme] name] === @"Aristo" && [self isBezeled])
    {
        // NSTextField.j makes the field +7.0 pixels tall. We want +8.0 to go to 30.
        var frame = [self frame];
        [self setFrameSize:CGSizeMake(frame.size.width, frame.size.height)];
    }
}

@end

@implementation NSSearchField : CPSearchField
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [self NS_initWithCoder:aCoder];

    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];
        [self NS_initWithCell:cell];
    }

    return self;
}

- (Class)classForKeyedArchiver
{
    return [CPSearchField class];
}

@end

@implementation NSSearchFieldCell : NSTextFieldCell
{
    CPString    _recentsAutosaveName @accessors(property=recentsAutosaveName);
    int         _maximumRecents @accessors(property=maximumRecents);
    BOOL        _sendsWholeSearchString @accessors(property=sendsWholeSearchString);
    BOOL        _sendsSearchStringImmediately @accessors(property=sendsSearchStringImmediately);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _recentsAutosaveName = [aCoder decodeObjectForKey:@"NSRecentsAutosaveName"];
        _maximumRecents = [aCoder decodeIntForKey:@"NSMaximumRecents"];
        _sendsWholeSearchString = [aCoder decodeBoolForKey:@"NSSendsWholeSearchString"];

        // These bytes don't seem to be used for anything else but the send immediately flag
        _sendsSearchStringImmediately = [aCoder decodeBytesForKey:@"NSSearchFieldFlags"] ? YES : NO;
    }

    return self;
}

@end
