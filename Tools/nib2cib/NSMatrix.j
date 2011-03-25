
@import <Foundation/CPObject.j>
@import <AppKit/CPView.j>

@import "NSView.j"


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
                        cellView = [[CPRadio alloc] initWithFrame:frame radioGroup:radioGroup];

                    [cellView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
                    [cellView setTitle:[cell title]];
                    [cellView setBackgroundColor:[CPColor clearColor]];  // the IB default
                    [cellView setObjectValue:[cell objectValue]];

                    [self addSubview:cellView];

                    NIB_CONNECTION_EQUIVALENCY_TABLE[[cell UID]] = cellView;

                    frame.origin.x = CGRectGetMaxX(frame) + intercellSpacing.width;
                }

                frame.origin.y = CGRectGetMaxY(frame) + intercellSpacing.height;
            }

            if (drawsBackground)
                [self setBackgroundColor:backgroundColor];

            // Change this object into a CPView
            self.isa = [CPView class];
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
