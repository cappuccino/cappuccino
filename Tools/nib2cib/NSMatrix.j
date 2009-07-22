
@import <Foundation/CPObject.j>
@import <AppKit/CPView.j>

@import "NSView.j"


@implementation NSMatrix : CPObject
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    var view = [[CPView alloc] NS_initWithCoder:aCoder];
    
    [view setBackgroundColor:[aCoder decodeObjectForKey:@"NSBackgroundColor"]];

    var numberOfRows = [aCoder decodeIntForKey:@"NSNumRows"],
        numberOfColumns = [aCoder decodeIntForKey:@"NSNumCols"],
        cellSize = [aCoder decodeSizeForKey:@"NSCellSize"],
        intercellSpacing = [aCoder decodeSizeForKey:@"NSIntercellSpacing"],
        cellBackgroundColor = [aCoder decodeObjectForKey:@"NSCellBackgroundColor"],
        //cellClassName = [aCoder decodeObjectForKey:@"NSCellClass"];alert("6");
        flags = [aCoder decodeIntForKey:@"NSMatrixFlags"],
        cells = [aCoder decodeObjectForKey:@"NSCells"],
        selectedCell = [aCoder decodeObjectForKey:@"NSSelectedCell"];

    if (/*(cellClassName === @"NSButtonCell") &&*/ (flags & 0x40000000))
    {
        var radioGroup = [CPRadioGroup new];
            frame = CGRectMake(0.0, 0.0, cellSize.width, cellSize.height);
            rowIndex = 0;

        for (; rowIndex < numberOfRows; ++rowIndex)
        {
            var columnIndex = 0;

            frame.origin.x = 0;

            for (; columnIndex < numberOfColumns; ++columnIndex)
            {
                var cell = cells[rowIndex * numberOfColumns + columnIndex],
                    cellView = [[CPRadio alloc] initWithFrame:frame radioGroup:radioGroup];

                [cellView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
                [cellView setTitle:[cell title]];
                [cellView setBackgroundColor:cellBackgroundColor];
                [cellView setObjectValue:[cell objectValue]];
                
                [view addSubview:cellView];

                frame.origin.x = CGRectGetMaxX(frame) + intercellSpacing.width;
            }

            frame.origin.y = CGRectGetMaxY(frame) + intercellSpacing.height;
        }
    }

    return view;
}

@end
