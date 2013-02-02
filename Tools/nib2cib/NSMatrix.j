/*
 * NSMatrix.j
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

@import <Foundation/CPObject.j>
@import <AppKit/CPRadio.j>
@import <AppKit/CPView.j>

@import "NSView.j"

@global NIB_CONNECTION_EQUIVALENCY_TABLE

var NSMatrixRadioModeMask = 0x40000000,
    NSMatrixDrawsBackgroundMask = 0x01000000;


@implementation NSMatrix : CPView

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        var numberOfRows = [aCoder decodeIntForKey:@"NSNumRows"],
            numberOfColumns = [aCoder decodeIntForKey:@"NSNumCols"],
            cellSize = [aCoder decodeSizeForKey:@"NSCellSize"],
            intercellSpacing = [aCoder decodeSizeForKey:@"NSIntercellSpacing"],
            flags = [aCoder decodeIntForKey:@"NSMatrixFlags"],
            isRadioMode = flags & NSMatrixRadioModeMask,
            drawsBackground = flags & NSMatrixDrawsBackgroundMask,
            backgroundColor = [aCoder decodeObjectForKey:@"NSBackgroundColor"],
            cells = [aCoder decodeObjectForKey:@"NSCells"],
            selectedCell = [aCoder decodeObjectForKey:@"NSSelectedCell"];

        if (isRadioMode)
        {
            var radioGroup = [CPRadioGroup new],
                frame = CGRectMake(0.0, 0.0, cellSize.width, cellSize.height);

            for (var rowIndex = 0; rowIndex < numberOfRows; ++rowIndex)
            {
                frame.origin.x = 0;

                for (var columnIndex = 0; columnIndex < numberOfColumns; ++columnIndex)
                {
                    var cell = cells[rowIndex * numberOfColumns + columnIndex],
                        cellView = [[CPRadio alloc] initWithFrame:frame radioGroup:radioGroup cell:cell];

                    [self addSubview:cellView];

                    NIB_CONNECTION_EQUIVALENCY_TABLE[[cell UID]] = cellView;

                    frame.origin.x = CGRectGetMaxX(frame) + intercellSpacing.width;
                }

                frame.origin.y = CGRectGetMaxY(frame) + intercellSpacing.height;
            }

            if (drawsBackground)
                [self setBackgroundColor:backgroundColor];

            self.isa = [CPView class];
            NIB_CONNECTION_EQUIVALENCY_TABLE[[self UID]] = radioGroup;
        }
        else
        {
            // Non-radio group NSMatrix is not supported
            self = nil;
        }
    }

    return self;
}

@end

@implementation CPRadio (NS)

- (id)initWithFrame:(CGRect)aFrame radioGroup:(CPRadioGroup)aRadioGroup cell:(NSButtonCell)aCell
{
    self = [self initWithFrame:aFrame radioGroup:aRadioGroup];

    if (self)
    {
        [self setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [self setTitle:[aCell title]];
        [self setBackgroundColor:[CPColor clearColor]];  // the IB default
        [self setFont:[aCell font]];
        [self setAlignment:[aCell alignment]];
        [self setLineBreakMode:[aCell lineBreakMode]];
        [self setImagePosition:[aCell imagePosition]];
        [self setKeyEquivalent:[aCell keyEquivalent]];
        [self setKeyEquivalentModifierMask:[aCell keyEquivalentModifierMask]];
        [self setAllowsMixedState:[aCell allowsMixedState]];
        [self setObjectValue:[aCell objectValue]];
        [self setEnabled:[aCell isEnabled]];
        [self setTag:[aCell tag]];
    }

    return self;
}

@end
