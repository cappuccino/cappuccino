/*
 * NSControl.j
 * nib2cib
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

@import <AppKit/CPControl.j>

@import "NSCell.j"
@import "NSView.j"


@implementation CPControl (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        // Enabled state is derived from the NSEnabled flag or the control's cell.
        // For example NSTableView uses the NSEnabled flag, but NSButton uses it's cell isEnabled state.
        // We use the NSEnabled flag here and override the behavior in controls using different logic (NSButton).
        [self setEnabled:[aCoder decodeBoolForKey:@"NSEnabled"]];

        [self sendActionOn:CPLeftMouseUpMask];
        [self setTarget:[aCoder decodeObjectForKey:@"NSTarget"]];
        [self setAction:[aCoder decodeObjectForKey:@"NSAction"]];

        // In IB, both cells and controls can have tags.
        // If the control has a tag, that takes precedence.
        if ([aCoder containsValueForKey:@"NSTag"])
            [self setTag:[aCoder decodeIntForKey:@"NSTag"]];
    }

    return self;
}

- (void)NS_initWithCell:(NSCell)cell
{
    [self setSendsActionOnEndEditing:[cell sendsActionOnEndEditing]];
    [self setObjectValue:[cell objectValue]];
    [self setFont:[cell font]];
    [self setAlignment:[cell alignment]];
    [self setContinuous:[cell isContinuous]];
    [self setLineBreakMode:[cell lineBreakMode]];
    [self setFormatter:[cell formatter]];
}

@end

@implementation NSControl : CPControl

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
    return [CPControl class];
}

@end
