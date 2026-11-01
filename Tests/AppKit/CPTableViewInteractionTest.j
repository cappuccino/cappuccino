/*
 *  CPTableViewInteractionTest.j
 *  AppKit
 *
 *  Created by David Richardson on 31/10/2026.
 *  Copyright David Richardson 2026.
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

@import <AppKit/AppKit.j>

/*
    A person selects, edits and drags rows with the mouse and the keyboard. These tests
    send a table the same events, and check what its delegate and data source receive.

    The drag session itself needs a display, so the table subclass records the call
    that would start it. A stub stands in for the dragging information. These tests
    cannot show that a drag image follows the pointer or that a drop indicator is
    visible.
*/

var InteractionDragType = @"InteractionDragType";

@implementation _CPTableInteractionTable : CPTableView
{
    CPArray     dragCalls @accessors;
}

- (void)dragView:(CPView)aView at:(CGPoint)aLocation offset:(CGSize)mouseOffset event:(CPEvent)anEvent pasteboard:(CPPasteboard)aPasteboard source:(id)aSourceObject slideBack:(BOOL)slideBack
{
    if (!dragCalls)
        dragCalls = [];

    dragCalls.push({ @"pasteboard": aPasteboard, @"source": aSourceObject });
}

@end

@implementation _CPTableInteractionDataSource : CPObject
{
    CPArray     rows @accessors;
    CPArray     editedValues @accessors;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        rows = [@"Zero", @"One", @"Two", @"Three", @"Four"];
        editedValues = [];
    }

    return self;
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return rows.length;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    return rows[aRow];
}

- (void)tableView:(CPTableView)aTableView setObjectValue:(id)aValue forTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    editedValues.push({ @"row": aRow, @"value": aValue });
}

@end

@implementation _CPTableInteractionDragDataSource : _CPTableInteractionDataSource
{
    BOOL                allowsDrag @accessors;
    CPIndexSet          writtenRows @accessors;
    CPDragOperation     validation @accessors;
    BOOL                acceptsDrop @accessors;
    CPArray             validations @accessors;
    CPArray             acceptedDrops @accessors;
    id                  retargetRow @accessors;
    id                  retargetOperation @accessors;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        allowsDrag = YES;
        validation = CPDragOperationMove;
        acceptsDrop = YES;
        validations = [];
        acceptedDrops = [];
    }

    return self;
}

- (BOOL)tableView:(CPTableView)aTableView writeRowsWithIndexes:(CPIndexSet)theIndexes toPasteboard:(CPPasteboard)aPasteboard
{
    writtenRows = theIndexes;

    if (allowsDrag)
    {
        [aPasteboard declareTypes:[InteractionDragType] owner:self];
        [aPasteboard setData:@"rows" forType:InteractionDragType];
    }

    return allowsDrag;
}

- (CPDragOperation)tableView:(CPTableView)aTableView validateDrop:(id)anInfo proposedRow:(int)aRow proposedDropOperation:(CPTableViewDropOperation)anOperation
{
    validations.push({ @"row": aRow, @"operation": anOperation });

    if (retargetRow != nil)
        [aTableView setDropRow:retargetRow dropOperation:retargetOperation];

    return validation;
}

- (BOOL)tableView:(CPTableView)aTableView acceptDrop:(id)anInfo row:(int)aRow dropOperation:(CPTableViewDropOperation)anOperation
{
    acceptedDrops.push({ @"row": aRow, @"operation": anOperation });

    return acceptsDrop;
}

@end

@implementation _CPTableInteractionDelegate : CPObject
{
    CPArray     calls @accessors;
    BOOL        allowsSelectionChange @accessors;
    BOOL        allowsEditing @accessors;
    CPArray     refusedRows @accessors;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        calls = [];
        allowsSelectionChange = YES;
        allowsEditing = YES;
        refusedRows = [];
    }

    return self;
}

- (BOOL)selectionShouldChangeInTableView:(CPTableView)aTableView
{
    calls.push(@"selectionShouldChange");

    return allowsSelectionChange;
}

- (BOOL)tableView:(CPTableView)aTableView shouldSelectRow:(int)aRow
{
    return refusedRows.indexOf(aRow) === -1;
}

- (BOOL)tableView:(CPTableView)aTableView shouldEditTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    calls.push(@"shouldEdit");

    return allowsEditing;
}

- (void)tableViewSelectionIsChanging:(CPNotification)aNotification
{
    calls.push(@"selectionIsChanging");
}

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    calls.push(@"selectionDidChange");
}

@end

@implementation _CPTableInteractionProposalDelegate : CPObject
{
}

- (CPIndexSet)tableView:(CPTableView)aTableView selectionIndexesForProposedSelection:(CPIndexSet)theIndexes
{
    return [CPIndexSet indexSetWithIndex:3];
}

@end

@implementation _CPTableInteractionDraggingInfo : CPObject
{
    CPPasteboard    draggingPasteboard @accessors;
    CGPoint         draggingLocation @accessors;
}

@end

@implementation CPTableViewInteractionTest : OJTestCase
{
    CPWindow                            theWindow;
    _CPTableInteractionTable            tableView;
    CPTableColumn                       tableColumn;
    _CPTableInteractionDataSource       dataSource;
    _CPTableInteractionDelegate         delegate;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 400.0) styleMask:CPWindowNotSizable];
    tableView = [[_CPTableInteractionTable alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 300.0)];
    tableColumn = [[CPTableColumn alloc] initWithIdentifier:@"Column"];

    [tableColumn setWidth:200.0];
    [tableColumn setEditable:YES];
    [tableView addTableColumn:tableColumn];
    [tableView setAllowsMultipleSelection:YES];
    [[theWindow contentView] addSubview:tableView];

    delegate = [[_CPTableInteractionDelegate alloc] init];
    [self useDataSource:[[_CPTableInteractionDataSource alloc] init]];
    [tableView setDelegate:delegate];
}

- (void)useDataSource:(id)aDataSource
{
    dataSource = aDataSource;

    [tableView setDataSource:dataSource];
    [tableView reloadData];
}

- (CGPoint)pointInRow:(int)aRow
{
    return CGPointMake(20.0, CGRectGetMidY([tableView rectOfRow:aRow]));
}

- (CPEvent)mouseEvent:(CPEventType)aType atPoint:(CGPoint)aPoint flags:(unsigned)theFlags clicks:(int)aClickCount
{
    return [CPEvent mouseEventWithType:aType
                              location:[tableView convertPoint:aPoint toView:nil]
                         modifierFlags:theFlags
                             timestamp:0
                          windowNumber:[theWindow windowNumber]
                               context:nil
                           eventNumber:0
                            clickCount:aClickCount
                              pressure:0];
}

- (void)sendEvent:(CPEvent)anEvent
{
    [CPApp sendEvent:anEvent];
    [tableView trackMouse:anEvent];
}

- (void)clickPoint:(CGPoint)aPoint flags:(unsigned)theFlags clicks:(int)aClickCount
{
    [self sendEvent:[self mouseEvent:CPLeftMouseDown atPoint:aPoint flags:theFlags clicks:aClickCount]];
    [self sendEvent:[self mouseEvent:CPLeftMouseUp atPoint:aPoint flags:theFlags clicks:aClickCount]];
}

- (void)clickRow:(int)aRow
{
    [self clickPoint:[self pointInRow:aRow] flags:0 clicks:1];
}

- (void)clickRow:(int)aRow flags:(unsigned)theFlags
{
    [self clickPoint:[self pointInRow:aRow] flags:theFlags clicks:1];
}

- (void)pressKey:(CPString)aCharacter flags:(unsigned)theFlags
{
    [tableView keyDown:[CPEvent keyEventWithType:CPKeyDown
                                        location:CGPointMakeZero()
                                   modifierFlags:theFlags
                                       timestamp:0
                                    windowNumber:[theWindow windowNumber]
                                         context:nil
                                      characters:aCharacter
                     charactersIgnoringModifiers:aCharacter
                                       isARepeat:NO
                                         keyCode:0]];
}

- (CPArray)selectedRows
{
    var rows = [];

    [[tableView selectedRowIndexes] getIndexes:rows maxCount:-1 inIndexRange:nil];

    return rows;
}

- (id)draggingInfoAtPoint:(CGPoint)aPoint
{
    var info = [[_CPTableInteractionDraggingInfo alloc] init],
        pasteboard = [CPPasteboard pasteboardWithName:CPDragPboard];

    [pasteboard declareTypes:[InteractionDragType] owner:self];
    [info setDraggingPasteboard:pasteboard];
    [info setDraggingLocation:[tableView convertPoint:aPoint toView:nil]];

    return info;
}

- (void)useDragDataSource
{
    [self useDataSource:[[_CPTableInteractionDragDataSource alloc] init]];
    [tableView registerForDraggedTypes:[InteractionDragType]];
}

// MARK: Selection

- (void)testClickSelectsARow
{
    [self clickRow:2];

    [self assert:[2] equals:[self selectedRows]];
}

- (void)testClickReplacesTheSelection
{
    [self clickRow:1];
    [self clickRow:3];

    [self assert:[3] equals:[self selectedRows]];
}

- (void)testClickOutsideTheRowsClearsTheSelection
{
    [self clickRow:1];
    [self clickPoint:CGPointMake(20.0, 290.0) flags:0 clicks:1];

    [self assert:[] equals:[self selectedRows]];
}

- (void)testClickOutsideTheRowsKeepsTheSelectionWhenItCannotBeEmpty
{
    [tableView setAllowsEmptySelection:NO];
    [self clickRow:1];
    [self clickPoint:CGPointMake(20.0, 290.0) flags:0 clicks:1];

    [self assert:[1] equals:[self selectedRows]];
}

- (void)testCommandClickAddsAndRemovesARow
{
    [self clickRow:1];
    [self clickRow:3 flags:CPCommandKeyMask];

    [self assert:[1, 3] equals:[self selectedRows]];

    [self clickRow:1 flags:CPCommandKeyMask];

    [self assert:[3] equals:[self selectedRows]];
}

- (void)testCommandClickReplacesTheSelectionWithoutMultipleSelection
{
    [tableView setAllowsMultipleSelection:NO];
    [self clickRow:1];
    [self clickRow:3 flags:CPCommandKeyMask];

    [self assert:[3] equals:[self selectedRows]];
}

- (void)testShiftClickExtendsFromTheAnchor
{
    [self clickRow:1];
    [self clickRow:3 flags:CPShiftKeyMask];

    [self assert:[1, 2, 3] equals:[self selectedRows]];
}

- (void)testDraggingAcrossRowsExtendsTheSelection
{
    [self sendEvent:[self mouseEvent:CPLeftMouseDown atPoint:[self pointInRow:1] flags:0 clicks:1]];
    [self sendEvent:[self mouseEvent:CPLeftMouseDragged atPoint:[self pointInRow:2] flags:0 clicks:1]];
    [self sendEvent:[self mouseEvent:CPLeftMouseDragged atPoint:[self pointInRow:3] flags:0 clicks:1]];
    [self sendEvent:[self mouseEvent:CPLeftMouseUp atPoint:[self pointInRow:3] flags:0 clicks:1]];

    [self assert:[1, 2, 3] equals:[self selectedRows]];
}

- (void)testDelegateCanRefuseASelectionChange
{
    [delegate setAllowsSelectionChange:NO];
    [self clickRow:2];

    [self assert:[] equals:[self selectedRows]];
    [self assertTrue:[delegate calls].indexOf(@"selectionShouldChange") !== -1];
}

- (void)testDelegateCanRefuseARow
{
    [delegate setRefusedRows:[2]];
    [self clickRow:2];

    [self assert:[] equals:[self selectedRows]];
}

- (void)testDelegateCanReplaceTheProposedSelection
{
    [tableView setDelegate:[[_CPTableInteractionProposalDelegate alloc] init]];
    [self clickRow:1];

    [self assert:[3] equals:[self selectedRows]];
}

- (void)testAClickReportsOneSelectionChange
{
    [self clickRow:2];

    var changes = [delegate calls].filter(function(aCall)
    {
        return aCall === @"selectionDidChange";
    });

    [self assert:1 equals:changes.length];
}

- (void)testClickingTheSelectedRowReportsNoChange
{
    [self clickRow:2];
    [delegate setCalls:[]];
    [self clickRow:2];

    [self assertTrue:[delegate calls].indexOf(@"selectionDidChange") === -1];
}

- (void)testSelectAllSelectsEveryRow
{
    [tableView selectAll:nil];

    [self assert:[0, 1, 2, 3, 4] equals:[self selectedRows]];
}

- (void)testDownArrowMovesTheSelection
{
    [self clickRow:1];
    [self pressKey:CPDownArrowFunctionKey flags:0];

    [self assert:[2] equals:[self selectedRows]];
}

- (void)testUpArrowMovesTheSelection
{
    [self clickRow:2];
    [self pressKey:CPUpArrowFunctionKey flags:0];

    [self assert:[1] equals:[self selectedRows]];
}

- (void)testArrowStopsAtTheLastRow
{
    [self clickRow:4];
    [self pressKey:CPDownArrowFunctionKey flags:0];

    [self assert:[4] equals:[self selectedRows]];
}

- (void)testArrowSelectsAnEndRowWhenNothingIsSelected
{
    [self pressKey:CPDownArrowFunctionKey flags:0];
    [self assert:[0] equals:[self selectedRows]];

    [tableView deselectAll:nil];
    [self pressKey:CPUpArrowFunctionKey flags:0];
    [self assert:[4] equals:[self selectedRows]];
}

- (void)testShiftArrowExtendsAndShrinksTheSelection
{
    [self clickRow:1];
    [self pressKey:CPDownArrowFunctionKey flags:CPShiftKeyMask];

    [self assert:[1, 2] equals:[self selectedRows]];

    [self pressKey:CPUpArrowFunctionKey flags:CPShiftKeyMask];

    [self assert:[1] equals:[self selectedRows]];
}

- (void)testArrowSkipsARefusedRow
{
    [delegate setRefusedRows:[2]];
    [self clickRow:1];
    [self pressKey:CPDownArrowFunctionKey flags:0];

    [self assert:[3] equals:[self selectedRows]];
}

- (void)testArrowRespectsARefusedSelectionChange
{
    [self clickRow:1];
    [delegate setAllowsSelectionChange:NO];
    [self pressKey:CPDownArrowFunctionKey flags:0];

    [self assert:[1] equals:[self selectedRows]];
}

// MARK: Editing

- (void)testEditingAnUnselectedRowRaises
{
    [self assertThrows:function()
    {
        [tableView editColumn:0 row:1 withEvent:nil select:YES];
    }];
}

- (void)testEditingReportsTheEditedCell
{
    [self clickRow:1];
    [tableView editColumn:0 row:1 withEvent:nil select:YES];

    [self assert:0 equals:[tableView editedColumn]];
    [self assert:1 equals:[tableView editedRow]];
}

- (void)testEditingMakesTheCellTheFirstResponder
{
    [self clickRow:1];
    [tableView editColumn:0 row:1 withEvent:nil select:YES];

    [self assertTrue:[[theWindow firstResponder] isKindOfClass:[CPTextField class]]];
    [self assert:@"One" equals:[[theWindow firstResponder] stringValue]];
}

- (void)testEndingAnEditCommitsTheValue
{
    [self clickRow:1];
    [tableView editColumn:0 row:1 withEvent:nil select:YES];

    var field = [theWindow firstResponder];

    [field setStringValue:@"Edited"];
    [[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidEndEditingNotification object:field];

    [self assert:1 equals:[dataSource editedValues].length];
    [self assert:1 equals:[dataSource editedValues][0].row];
    [self assert:@"Edited" equals:[dataSource editedValues][0].value];
    [self assert:tableView equals:[theWindow firstResponder]];
}

- (void)testDoubleClickStartsEditing
{
    [self clickRow:1];
    [self clickPoint:[self pointInRow:1] flags:0 clicks:2];

    [self assert:1 equals:[tableView editedRow]];
    [self assertTrue:[delegate calls].indexOf(@"shouldEdit") !== -1];
}

- (void)testDelegateCanRefuseAnEdit
{
    [delegate setAllowsEditing:NO];
    [self clickRow:1];
    [self clickPoint:[self pointInRow:1] flags:0 clicks:2];

    [self assert:CPNotFound equals:[tableView editedRow]];
}

- (void)testAColumnThatIsNotEditableDoesNotStartAnEdit
{
    [tableColumn setEditable:NO];
    [self clickRow:1];
    [self clickPoint:[self pointInRow:1] flags:0 clicks:2];

    [self assert:CPNotFound equals:[tableView editedRow]];
}

// MARK: Starting a drag

- (void)dragFromRow:(int)aRow toPoint:(CGPoint)aPoint
{
    [self sendEvent:[self mouseEvent:CPLeftMouseDown atPoint:[self pointInRow:aRow] flags:0 clicks:1]];
    [self sendEvent:[self mouseEvent:CPLeftMouseDragged atPoint:aPoint flags:0 clicks:1]];
}

- (void)testADraggableTableSelectsOnMouseUp
{
    [self useDragDataSource];

    [self sendEvent:[self mouseEvent:CPLeftMouseDown atPoint:[self pointInRow:2] flags:0 clicks:1]];
    [self assert:[] equals:[self selectedRows]];

    [self sendEvent:[self mouseEvent:CPLeftMouseUp atPoint:[self pointInRow:2] flags:0 clicks:1]];
    [self assert:[2] equals:[self selectedRows]];
}

- (void)testDraggingARowStartsADrag
{
    [self useDragDataSource];

    var start = [self pointInRow:2];

    [self dragFromRow:2 toPoint:CGPointMake(start.x + 20.0, start.y)];

    [self assert:1 equals:[[tableView dragCalls] count]];
    [self assert:[CPIndexSet indexSetWithIndex:2] equals:[dataSource writtenRows]];
    [self assert:[InteractionDragType] equals:[[tableView dragCalls][0].pasteboard types]];
    [self assert:tableView equals:[tableView dragCalls][0].source];
}

- (void)testDraggingASelectedRowDragsTheWholeSelection
{
    [self useDragDataSource];
    [tableView selectRowIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(1, 2)] byExtendingSelection:NO];

    var start = [self pointInRow:2];

    [self dragFromRow:2 toPoint:CGPointMake(start.x + 20.0, start.y)];

    [self assert:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(1, 2)] equals:[dataSource writtenRows]];
}

- (void)testAMoveWithinTheClickSlopDoesNotStartADrag
{
    [self useDragDataSource];

    var start = [self pointInRow:2];

    [self dragFromRow:2 toPoint:CGPointMake(start.x + 2.0, start.y)];

    [self assertNull:[tableView dragCalls]];
}

- (void)testDataSourceCanRefuseADrag
{
    [self useDragDataSource];
    [dataSource setAllowsDrag:NO];

    var start = [self pointInRow:2];

    [self dragFromRow:2 toPoint:CGPointMake(start.x + 20.0, start.y)];

    [self assertNull:[tableView dragCalls]];
}

// MARK: Dropping

- (void)testAnUnregisteredTypeIsRefused
{
    [self useDragDataSource];
    [tableView unregisterDraggedTypes];

    [self assert:CPDragOperationNone equals:[tableView draggingEntered:[self draggingInfoAtPoint:[self pointInRow:2]]]];
    [self assert:0 equals:[dataSource validations].length];
}

- (void)testARegisteredTypeIsValidated
{
    [self useDragDataSource];

    [self assert:CPDragOperationMove equals:[tableView draggingEntered:[self draggingInfoAtPoint:[self pointInRow:2]]]];
    [self assert:1 equals:[dataSource validations].length];
}

- (void)testValidationCanRefuseADrop
{
    [self useDragDataSource];
    [dataSource setValidation:CPDragOperationNone];

    [self assert:CPDragOperationNone equals:[tableView draggingUpdated:[self draggingInfoAtPoint:[self pointInRow:2]]]];
}

- (void)testTheMiddleOfARowProposesADropOnThatRow
{
    [self useDragDataSource];
    [tableView draggingUpdated:[self draggingInfoAtPoint:[self pointInRow:2]]];

    [self assert:2 equals:[dataSource validations][0].row];
    [self assert:CPTableViewDropOn equals:[dataSource validations][0].operation];
}

- (void)testTheTopOfARowProposesADropAboveThatRow
{
    [self useDragDataSource];

    var rect = [tableView rectOfRow:2];

    [tableView draggingUpdated:[self draggingInfoAtPoint:CGPointMake(20.0, CGRectGetMinY(rect) + 1.0)]];

    [self assert:2 equals:[dataSource validations][0].row];
    [self assert:CPTableViewDropAbove equals:[dataSource validations][0].operation];
}

- (void)testTheBottomOfARowProposesADropAboveTheNextRow
{
    [self useDragDataSource];

    var rect = [tableView rectOfRow:2];

    [tableView draggingUpdated:[self draggingInfoAtPoint:CGPointMake(20.0, CGRectGetMaxY(rect) - 1.0)]];

    [self assert:3 equals:[dataSource validations][0].row];
    [self assert:CPTableViewDropAbove equals:[dataSource validations][0].operation];
}

- (void)testBelowTheLastRowProposesADropAtTheEnd
{
    [self useDragDataSource];
    [tableView draggingUpdated:[self draggingInfoAtPoint:CGPointMake(20.0, 290.0)]];

    [self assert:5 equals:[dataSource validations][0].row];
    [self assert:CPTableViewDropAbove equals:[dataSource validations][0].operation];
}

- (void)testAcceptingADropReceivesTheProposedRow
{
    [self useDragDataSource];

    var info = [self draggingInfoAtPoint:[self pointInRow:2]];

    [tableView draggingUpdated:info];

    [self assertTrue:[tableView prepareForDragOperation:info]];
    [self assertTrue:[tableView performDragOperation:info]];
    [self assert:2 equals:[dataSource acceptedDrops][0].row];
    [self assert:CPTableViewDropOn equals:[dataSource acceptedDrops][0].operation];
}

- (void)testDataSourceCanRefuseADrop
{
    [self useDragDataSource];
    [dataSource setAcceptsDrop:NO];

    var info = [self draggingInfoAtPoint:[self pointInRow:2]];

    [tableView draggingUpdated:info];

    [self assertFalse:[tableView performDragOperation:info]];
}

- (void)testDataSourceCanRetargetADrop
{
    [self useDragDataSource];
    [dataSource setRetargetRow:4];
    [dataSource setRetargetOperation:CPTableViewDropAbove];

    var info = [self draggingInfoAtPoint:[self pointInRow:2]];

    [tableView draggingUpdated:info];
    [tableView performDragOperation:info];

    [self assert:4 equals:[dataSource acceptedDrops][0].row];
    [self assert:CPTableViewDropAbove equals:[dataSource acceptedDrops][0].operation];
}

- (void)testPreparingADropNeedsValidation
{
    var info = [self draggingInfoAtPoint:[self pointInRow:2]];

    [self assertFalse:[tableView prepareForDragOperation:info]];
}

@end
