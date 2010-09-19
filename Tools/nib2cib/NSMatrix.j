
@import <Foundation/CPObject.j>
@import <AppKit/CPView.j>

@import "NSView.j"


var NSMatrixRadioModeMask = 0x40000000,
    NSMatrixDrawsBackgroundMask = 0x01000000;


@implementation NSMatrix : CPObject
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    var view = [[CPView alloc] NS_initWithCoder:aCoder];

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
                    cellView = [[CPRadio alloc] initWithFrame:frame radioGroup:radioGroup];

                [cellView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
                [cellView setTitle:[cell title]];
                [cellView setBackgroundColor:[CPColor clearColor]];  // the IB default
                [cellView setObjectValue:[cell objectValue]];

                [view addSubview:cellView];

                NIB_CONNECTION_EQUIVALENCY_TABLE[[cell UID]] = cellView;

                frame.origin.x = CGRectGetMaxX(frame) + intercellSpacing.width;
            }

            frame.origin.y = CGRectGetMaxY(frame) + intercellSpacing.height;
        }

        if (drawsBackground)
            [view setBackgroundColor:backgroundColor];

        NIB_CONNECTION_EQUIVALENCY_TABLE[[self UID]] = view;
    }

    return view;
}

@end
