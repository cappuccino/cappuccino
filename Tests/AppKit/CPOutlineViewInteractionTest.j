/*
 *  CPOutlineViewInteractionTest.j
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
    An outline view adds a parent to every row, so it reports a drag by item and a drop
    by parent item and child index. Selection and editing come from CPTableView, and
    CPTableViewInteractionTest.j covers them. These tests cover what an outline view
    changes.
*/

var OutlineInteractionDragType = @"OutlineInteractionDragType";

@implementation _CPOutlineInteractionView : CPOutlineView
{
    CPArray     dragCalls @accessors;
}

- (void)dragView:(CPView)aView at:(CGPoint)aLocation offset:(CGSize)mouseOffset event:(CPEvent)anEvent pasteboard:(CPPasteboard)aPasteboard source:(id)aSourceObject slideBack:(BOOL)slideBack
{
    if (!dragCalls)
        dragCalls = [];

    dragCalls.push(aPasteboard);
}

@end

@implementation _CPOutlineInteractionDataSource : CPObject
{
    id          tree @accessors;
    CPArray     writtenItems @accessors;
    CPArray     validations @accessors;
    CPArray     acceptedDrops @accessors;
    id          retargetItem @accessors;
    id          retargetIndex @accessors;
    BOOL        shouldRetarget @accessors;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        tree = {
            @"root": [@"A", @"B", @"C"],
            @"A": [@"A1", @"A2"],
            @"B": [],
            @"C": [@"C1"]
        };
        validations = [];
        acceptedDrops = [];
    }

    return self;
}

- (CPArray)childrenOfItem:(id)anItem
{
    return tree[anItem || @"root"] || [];
}

- (id)outlineView:(CPOutlineView)anOutlineView child:(int)anIndex ofItem:(id)anItem
{
    return [self childrenOfItem:anItem][anIndex];
}

- (BOOL)outlineView:(CPOutlineView)anOutlineView isItemExpandable:(id)anItem
{
    return [self childrenOfItem:anItem].length > 0;
}

- (int)outlineView:(CPOutlineView)anOutlineView numberOfChildrenOfItem:(id)anItem
{
    return [self childrenOfItem:anItem].length;
}

- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)aColumn byItem:(id)anItem
{
    return anItem;
}

- (BOOL)outlineView:(CPOutlineView)anOutlineView writeItems:(CPArray)theItems toPasteboard:(CPPasteboard)aPasteboard
{
    writtenItems = theItems;

    [aPasteboard declareTypes:[OutlineInteractionDragType] owner:self];
    [aPasteboard setData:@"items" forType:OutlineInteractionDragType];

    return YES;
}

- (CPDragOperation)outlineView:(CPOutlineView)anOutlineView validateDrop:(id)anInfo proposedItem:(id)anItem proposedChildIndex:(int)anIndex
{
    validations.push({ @"item": anItem, @"index": anIndex });

    if (shouldRetarget)
        [anOutlineView setDropItem:retargetItem dropChildIndex:retargetIndex];

    return CPDragOperationMove;
}

- (BOOL)outlineView:(CPOutlineView)anOutlineView acceptDrop:(id)anInfo item:(id)anItem childIndex:(int)anIndex
{
    acceptedDrops.push({ @"item": anItem, @"index": anIndex });

    return YES;
}

@end

@implementation _CPOutlineInteractionDraggingInfo : CPObject
{
    CPPasteboard    draggingPasteboard @accessors;
    CGPoint         draggingLocation @accessors;
}

@end

@implementation CPOutlineViewInteractionTest : OJTestCase
{
    CPWindow                            theWindow;
    _CPOutlineInteractionView           outlineView;
    _CPOutlineInteractionDataSource     dataSource;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 400.0, 400.0) styleMask:CPWindowNotSizable];
    outlineView = [[_CPOutlineInteractionView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 300.0)];

    var column = [[CPTableColumn alloc] initWithIdentifier:@"Column"];

    [column setWidth:200.0];
    [outlineView addTableColumn:column];
    [outlineView setOutlineTableColumn:column];
    [outlineView setAllowsMultipleSelection:YES];
    [[theWindow contentView] addSubview:outlineView];

    dataSource = [[_CPOutlineInteractionDataSource alloc] init];

    [outlineView setDataSource:dataSource];
    [outlineView registerForDraggedTypes:[OutlineInteractionDragType]];
    [outlineView expandItem:@"A"];
    [outlineView reloadData];
}

- (CGPoint)pointInItem:(id)anItem
{
    return CGPointMake(100.0, CGRectGetMidY([outlineView rectOfRow:[outlineView rowForItem:anItem]]));
}

- (id)draggingInfoAtPoint:(CGPoint)aPoint
{
    var info = [[_CPOutlineInteractionDraggingInfo alloc] init],
        pasteboard = [CPPasteboard pasteboardWithName:CPDragPboard];

    [pasteboard declareTypes:[OutlineInteractionDragType] owner:self];
    [info setDraggingPasteboard:pasteboard];
    [info setDraggingLocation:[outlineView convertPoint:aPoint toView:nil]];

    return info;
}

- (void)sendMouse:(CPEventType)aType atPoint:(CGPoint)aPoint
{
    var event = [CPEvent mouseEventWithType:aType
                                   location:[outlineView convertPoint:aPoint toView:nil]
                              modifierFlags:0
                                  timestamp:0
                               windowNumber:[theWindow windowNumber]
                                    context:nil
                                eventNumber:0
                                 clickCount:1
                                   pressure:0];

    [CPApp sendEvent:event];
    [outlineView trackMouse:event];
}

- (void)testDraggingARowWritesItsItem
{
    var start = [self pointInItem:@"A1"];

    [self sendMouse:CPLeftMouseDown atPoint:start];
    [self sendMouse:CPLeftMouseDragged atPoint:CGPointMake(start.x + 20.0, start.y)];

    [self assert:[@"A1"] equals:[dataSource writtenItems]];
    [self assert:1 equals:[[outlineView dragCalls] count]];
}

- (void)testDraggingASelectionWritesEachItem
{
    var firstRow = [outlineView rowForItem:@"A1"];

    [outlineView selectRowIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(firstRow, 2)] byExtendingSelection:NO];

    var start = [self pointInItem:@"A2"];

    [self sendMouse:CPLeftMouseDown atPoint:start];
    [self sendMouse:CPLeftMouseDragged atPoint:CGPointMake(start.x + 20.0, start.y)];

    [self assert:[@"A1", @"A2"] equals:[dataSource writtenItems]];
}

- (void)testTheMiddleOfARowProposesADropOnThatItem
{
    [outlineView draggingUpdated:[self draggingInfoAtPoint:[self pointInItem:@"B"]]];

    [self assert:@"B" equals:[dataSource validations][0].item];
    [self assert:CPOutlineViewDropOnItemIndex equals:[dataSource validations][0].index];
}

- (void)testTheTopOfAChildRowProposesADropInItsParent
{
    var rect = [outlineView rectOfRow:[outlineView rowForItem:@"A2"]];

    [outlineView draggingUpdated:[self draggingInfoAtPoint:CGPointMake(100.0, CGRectGetMinY(rect) + 1.0)]];

    [self assert:@"A" equals:[dataSource validations][0].item];
    [self assert:1 equals:[dataSource validations][0].index];
}

/*
    Between a child and a root row, either parent is possible, and the horizontal
    position of the drag chooses between them.
*/
- (void)testAnUnindentedDropAboveARootRowProposesTheRoot
{
    var rect = [outlineView rectOfRow:[outlineView rowForItem:@"B"]];

    [outlineView draggingUpdated:[self draggingInfoAtPoint:CGPointMake(5.0, CGRectGetMinY(rect) + 1.0)]];

    [self assertNull:[dataSource validations][0].item];
    [self assert:1 equals:[dataSource validations][0].index];
}

- (void)testAnIndentedDropAboveARootRowProposesTheEndOfThePreviousParent
{
    var rect = [outlineView rectOfRow:[outlineView rowForItem:@"B"]];

    [outlineView draggingUpdated:[self draggingInfoAtPoint:CGPointMake(100.0, CGRectGetMinY(rect) + 1.0)]];

    [self assert:@"A" equals:[dataSource validations][0].item];
    [self assert:2 equals:[dataSource validations][0].index];
}

- (void)testBelowTheLastRowProposesADropAtTheEndOfTheRoot
{
    [outlineView draggingUpdated:[self draggingInfoAtPoint:CGPointMake(100.0, 290.0)]];

    [self assertNull:[dataSource validations][0].item];
    [self assert:3 equals:[dataSource validations][0].index];
}

- (void)testAcceptingADropReceivesTheProposedItem
{
    var info = [self draggingInfoAtPoint:[self pointInItem:@"B"]];

    [outlineView draggingUpdated:info];

    [self assertTrue:[outlineView performDragOperation:info]];
    [self assert:@"B" equals:[dataSource acceptedDrops][0].item];
    [self assert:CPOutlineViewDropOnItemIndex equals:[dataSource acceptedDrops][0].index];
}

- (void)testDataSourceCanRetargetADropBetweenChildren
{
    [dataSource setShouldRetarget:YES];
    [dataSource setRetargetItem:@"A"];
    [dataSource setRetargetIndex:0];

    var info = [self draggingInfoAtPoint:[self pointInItem:@"B"]];

    [outlineView draggingUpdated:info];
    [outlineView performDragOperation:info];

    [self assert:@"A" equals:[dataSource acceptedDrops][0].item];
    [self assert:0 equals:[dataSource acceptedDrops][0].index];
}

- (void)testDataSourceCanRetargetADropOnAnItem
{
    [dataSource setShouldRetarget:YES];
    [dataSource setRetargetItem:@"C"];
    [dataSource setRetargetIndex:CPOutlineViewDropOnItemIndex];

    var info = [self draggingInfoAtPoint:[self pointInItem:@"B"]];

    [outlineView draggingUpdated:info];
    [outlineView performDragOperation:info];

    [self assert:@"C" equals:[dataSource acceptedDrops][0].item];
    [self assert:CPOutlineViewDropOnItemIndex equals:[dataSource acceptedDrops][0].index];
}

- (void)testHoveringOverACollapsedItemExpandsIt
{
    [self assertFalse:[outlineView isItemExpanded:@"C"]];

    [outlineView setDropItem:@"C" dropChildIndex:CPOutlineViewDropOnItemIndex];
    [outlineView._dragHoverTimer fire];

    [self assertTrue:[outlineView isItemExpanded:@"C"]];
}

- (void)testAChildIndexCancelsTheHover
{
    [outlineView setDropItem:@"C" dropChildIndex:CPOutlineViewDropOnItemIndex];
    [outlineView setDropItem:@"C" dropChildIndex:0];

    [self assertNull:outlineView._dragHoverTimer];
}

- (void)testEndingADragCancelsTheHover
{
    [outlineView setDropItem:@"C" dropChildIndex:CPOutlineViewDropOnItemIndex];
    [outlineView draggedView:nil endedAt:CGPointMakeZero() operation:CPDragOperationNone];

    [self assertNull:outlineView._dragHoverTimer];
    [self assertFalse:[outlineView isItemExpanded:@"C"]];
}

@end
