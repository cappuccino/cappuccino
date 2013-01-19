/*
 * BadgedOutlineView.j
 *
 * Created by cacaodev on February 22, 2010.
 * Copyright 2010, All rights reserved.
 *
 * Based on PXSourceList
 * Created by Alex Rozanski on 05/09/2009.
 * Copyright 2009-10 Alex Rozanski http://perspx.com
*/

@import "AppController.j"

var MIN_BADGE_WIDTH                         = 22.0,     //The minimum badge width for each item (default 22.0)
    BADGE_HEIGHT                            = 14.0,     //The badge height for each item (default 14.0)
    BADGE_MARGIN                            = 5.0,          //The spacing between the badge and the cell for that row
    ROW_RIGHT_MARGIN                        = 5.0,          //The spacing between the right edge of the badge and the edge of the table column
    BADGE_BACKGROUND_COLOR                  = [CPColor colorWithCalibratedRed:(152/255.0) green:(168/255.0) blue:(202/255.0) alpha:1],
    BADGE_HIDDEN_BACKGROUND_COLOR           = [CPColor colorWithWhite:(180/255.0) alpha:1],
    BADGE_SELECTED_TEXT_COLOR               = [CPColor colorWithCalibratedRed:(75/255.0) green:(137/255.0) blue:(208/255.0) alpha:1],
    BADGE_SELECTED_UNFOCUSED_TEXT_COLOR     = [CPColor colorWithCalibratedRed:(153/255.0) green:(169/255.0) blue:(203/255.0) alpha:1],
    BADGE_SELECTED_HIDDEN_TEXT_COLOR        = [CPColor colorWithCalibratedWhite:(170/255.0) alpha:1],
    BADGE_FONT                              = [CPFont boldSystemFontOfSize:11];

var CPSourceListDataSource_sourceList_itemHasBadge_                   = 1 << 1,
    CPSourceListDataSource_sourceList_badgeValueForItem_              = 1 << 2,
    CPSourceListDataSource_sourceList_badgeBackgroundColorForItem_    = 1 << 3,
    CPSourceListDataSource_sourceList_badgeTextColorForItem_          = 1 << 4;

@implementation BadgedOutlineView : CPOutlineView
{
    id  _sourceListDataSource @accessors(property=sourceListDataSource);
    int _implementedSourceListDataSourceMethods;
}

- (void)setSourceListDataSource:(id)aDataSource
{
    _sourceListDataSource = aDataSource;
    implementedSourceListDataSourceMethods = 0;

    if ([_sourceListDataSource respondsToSelector:@selector(sourceList:itemHasBadge:)])
        implementedSourceListDataSourceMethods |= CPSourceListDataSource_sourceList_itemHasBadge_;
    if ([_sourceListDataSource respondsToSelector:@selector(sourceList:badgeValueForItem:)])
        implementedSourceListDataSourceMethods |= CPSourceListDataSource_sourceList_badgeValueForItem_;
    if ([_sourceListDataSource respondsToSelector:@selector(sourceList:badgeBackgroundColorForItem:)])
        implementedSourceListDataSourceMethods |= CPSourceListDataSource_sourceList_badgeBackgroundColorForItem_;
    if ([_sourceListDataSource respondsToSelector:@selector(sourceList:badgeTextColorForItem:)])
        implementedSourceListDataSourceMethods |= CPSourceListDataSource_sourceList_badgeTextColorForItem_;
}

- (BOOL)itemHasBadge:(id)item
{
    if (implementedSourceListDataSourceMethods & CPSourceListDataSource_sourceList_itemHasBadge_)
        return [_sourceListDataSource sourceList:self itemHasBadge:item];

    return NO;
}

- (CPInteger)badgeValueForItem:(id)item
{
    if ([self itemHasBadge:item] && implementedSourceListDataSourceMethods & CPSourceListDataSource_sourceList_badgeValueForItem_)
        return [_sourceListDataSource sourceList:self badgeValueForItem:item];

    return CPNotFound;
}

//This method calculates and returns the size of the badge for the row index passed to the method. If the
//row for the row index passed to the method does not have a badge, then NSZeroSize is returned.
- (CGSize)sizeOfBadgeAtRow:(CPInteger)rowIndex
{
    var rowItem = [self itemAtRow:rowIndex];

    //Make sure that the item has a badge
    if (![self itemHasBadge:rowItem])
        return CGSizeZero();

    var badgeString = [CPString stringWithFormat:@"%d", [self badgeValueForItem:rowItem]];

    var stringSize = [badgeString sizeWithFont:BADGE_FONT];

    //Calculate the width needed to display the text or the minimum width if it's smaller
    var width = MAX(MIN_BADGE_WIDTH, stringSize.width + 2 * BADGE_MARGIN);

    return CGSizeMake(width, BADGE_HEIGHT);
}

- (void)drawRow:(CPInteger)rowIndex clipRect:(CGRect)clipRect
{
    var item = [self itemAtRow:rowIndex];
    //Draw the badge if the item has one
    if ([self itemHasBadge:item])
    {
        var columnIndex = [_tableColumns indexOfObjectIdenticalTo:[self outlineTableColumn]],
            viewRect = [self frameOfDataViewAtColumn:columnIndex row:rowIndex],
            badgeSize = [self sizeOfBadgeAtRow:rowIndex],

            badgeFrame = CGRectMake(CGRectGetMaxX(viewRect) - badgeSize.width - ROW_RIGHT_MARGIN,
                                       CGRectGetMidY(viewRect) - (badgeSize.height/2.0),
                                       badgeSize.width,
                                       badgeSize.height);

        [self drawBadgeForRow:rowIndex inRect:badgeFrame];
    }
}

- (void)drawBadgeForRow:(CPInteger)rowIndex inRect:(CGRect)badgeFrame
{

    var rowItem = [self itemAtRow:rowIndex],
        badgePath = [CPBezierPath bezierPath];

    [badgePath appendBezierPathWithRoundedRect:badgeFrame xRadius:(BADGE_HEIGHT/2.0) yRadius:(BADGE_HEIGHT/2.0)];

    //Get window and control state to determine colours used
    var isFocused = [[[self window] firstResponder] isEqual:self],
        rowBeingEdited = -1 // uninplemented [self editedRow];

    //Set the attributes based on the row state
    var backgroundColor,
        textColor;

    if ([[self selectedRowIndexes] containsIndex:rowIndex])
    {
        backgroundColor = [CPColor whiteColor];

        //Set the text color based on window and control state
        if (isFocused || rowBeingEdited == rowIndex)
            textColor = BADGE_SELECTED_TEXT_COLOR;
        else if (!isFocused)
            textColor = BADGE_SELECTED_UNFOCUSED_TEXT_COLOR;
        else
            textColor = BADGE_SELECTED_HIDDEN_TEXT_COLOR;
    }
    else
    {
        //Set the text colour based on window and control state
        textColor = [CPColor whiteColor];

        //If the data source returns a custom colour..
        if (implementedSourceListDataSourceMethods & CPSourceListDataSource_sourceList_badgeBackgroundColorForItem_)
        {
            backgroundColor = [_sourceListDataSource sourceList:self badgeBackgroundColorForItem:rowItem];

            if (backgroundColor == nil)
                backgroundColor = BADGE_BACKGROUND_COLOR;
        }
        else //Otherwise use the default (purple-blue colour)
            backgroundColor = BADGE_BACKGROUND_COLOR;

        //If the delegate wants a custom badge text colour..
        if (implementedSourceListDataSourceMethods & CPSourceListDataSource_sourceList_badgeTextColorForItem_)
        {
            textColor = [_sourceListDataSource sourceList:self badgeTextColorForItem:rowItem];

            if (textColor == nil)
                textColor = [CPColor whiteColor];
        }
    }

    [backgroundColor set];
    [badgePath fill];

    //Draw the badge text
    var badgeString = [CPString stringWithFormat:@"%d", [self badgeValueForItem:rowItem]],
        stringSize = [badgeString sizeWithFont:BADGE_FONT],
        badgeTextPoint = CGPointMake(CGRectGetMidX(badgeFrame) - (stringSize.width/2.0),        //Center in the badge frame
                                         CGRectGetMidY(badgeFrame) + (stringSize.height/4.0));  //Center in the badge frame
    [textColor setFill];
    [badgeString drawAtPoint:badgeTextPoint withFont:BADGE_FONT];
}

/* This CPOutlineView subclass is necessary only if you want to delete items by dragging them to the trash.  In order to support drags to the trash, you need to implement draggedImage:endedAt:operation: and handle the CPDragOperationDelete operation.  For any other operation, pass the message to the superclass
*/
- (void)draggedImage:(CPImage)image endedAt:(CGPoint)screenPoint operation:(CPDragOperation)operation
{
    if (operation == CPDragOperationDelete)
    {
        // Tell all of the dragged nodes to remove themselves from the model.
        var selection = [[self dataSource] draggedNodes],
            count = [selection count];

        while (count--)
        {
            var node = selection[count];
            [[[node parentNode] mutableChildNodes] removeObject:node];
        }

        [self reloadData];
        [self deselectAll:nil];
    }
    else
    {
        [super draggedImage:image endedAt:screenPoint operation:operation];
    }
}

@end

@implementation CPOutlineView (MyExtensions)

- (CPView)preparedViewAtColumn:(int)column row:(int)row
{
    return [self _newDataViewForRow:row tableColumn:_tableColumns[column]];
}

- (CPArray)selectedItems
{
    var items = [CPArray array],
        selectedRows = [self selectedRowIndexes],
        row = [selectedRows firstIndex];

    if (selectedRows != nil)
    {
        while (row != CPNotFound)
        {
            [items addObject:[self itemAtRow:row]];
            row = [selectedRows indexGreaterThanIndex:row];
        }
    }

    return items;
}

- (void)setSelectedItems:(CPArray)items
{
    // If we are extending the selection, we start with the existing selection; otherwise, we create a new blank set of the indexes.
    var newSelection = [CPIndexSet indexSet],
        count = [items count];

    for (var i = 0; i < count; i++)
    {
        var row = [self rowForItem:[items objectAtIndex:i]];
        if (row != CPNotFound)
            [newSelection addIndex:row];
    }

    [self selectRowIndexes:newSelection byExtendingSelection:NO];
}

@end

@implementation CPString (DrawingAdditions)

- (CGSize)drawAtPoint:(CGPoint)point withFont:(CPFont)font
{
    var ctx = [[CPGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(ctx);
    CGContextSetFont(ctx, font);
    CGContextShowTextAtPoint(ctx, point.x, point.y + 1, self, 0);
    CGContextRestoreGState(ctx);
    return [self sizeWithFont:font];
}

@end

function CGContextShowTextAtPoint(aContext, x, y, aString,/* unused */ aStringLength)
{
    aContext.fillText(aString, x, y);
}

function CGContextSetFont(aContext, aFont)
{
    aContext.font = [aFont cssString];
}
