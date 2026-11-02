/*
 *  CPViewDecodedBehaviorTest.j
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
    DropInArchiveTest.j checks that a decoded view has the right content. These tests
    check that it still works: that its connections were restored, and that the
    objects a class creates or observes for itself were set up again.

    A target or delegate is encoded conditionally, so each test archives a container
    that holds the target too. Bindings are not here. They are stored in cibs as
    connectors, and not in the views.
*/

@implementation _CPDecodedTarget : CPView
{
    int     actionCount @accessors;
    id      lastSender @accessors;
}

- (void)performAction:(id)aSender
{
    actionCount++;
    lastSender = aSender;
}

@end

@implementation _CPDecodedTableDataSource : CPObject
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self init];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return 3;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    return @"Row";
}

@end

@implementation _CPDecodedOutlineDataSource : _CPDecodedTableDataSource
{
}

- (id)outlineView:(CPOutlineView)anOutlineView child:(int)anIndex ofItem:(id)anItem
{
    return anItem ? @"Child" : @"Parent";
}

- (BOOL)outlineView:(CPOutlineView)anOutlineView isItemExpandable:(id)anItem
{
    return anItem === @"Parent";
}

- (int)outlineView:(CPOutlineView)anOutlineView numberOfChildrenOfItem:(id)anItem
{
    return (!anItem || anItem === @"Parent") ? 1 : 0;
}

- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)aColumn byItem:(id)anItem
{
    return anItem;
}

@end

@implementation CPViewDecodedBehaviorTest : OJTestCase
{
    CPView              container;
    _CPDecodedTarget    target;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    container = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 300.0)];
    target = [[_CPDecodedTarget alloc] initWithFrame:CGRectMakeZero()];

    [container addSubview:target];
}

- (id)archived:(id)anObject
{
    return [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:anObject]];
}

/*
    Connects a control to the target, archives the container, and returns the decoded
    control. The decoded target is its action's receiver.
*/
- (id)decodedConnectedControl:(CPControl)aControl
{
    [aControl setTarget:target];
    [aControl setAction:@selector(performAction:)];
    [container addSubview:aControl];

    return [[self archived:container] subviews][1];
}

// MARK: Connections

- (void)testAControlKeepsItsTargetAndAction
{
    var decoded = [self decodedConnectedControl:[[CPButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 80.0, 24.0)]],
        decodedTarget = [[decoded superview] subviews][0];

    [self assert:decodedTarget equals:[decoded target]];
    [self assert:@selector(performAction:) equals:[decoded action]];
}

- (void)testADecodedButtonSendsItsAction
{
    var decoded = [self decodedConnectedControl:[[CPButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 80.0, 24.0)]];

    [decoded performClick:nil];

    [self assert:1 equals:[[decoded target] actionCount]];
    [self assert:decoded equals:[[decoded target] lastSender]];
}

- (void)testADecodedSliderSendsItsAction
{
    var decoded = [self decodedConnectedControl:[[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 80.0, 24.0)]];

    [decoded sendAction:[decoded action] to:[decoded target]];

    [self assert:1 equals:[[decoded target] actionCount]];
}

- (void)testADecodedTextFieldKeepsItsDelegate
{
    var field = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 80.0, 24.0)];

    [field setDelegate:target];
    [container addSubview:field];

    var decoded = [[self archived:container] subviews][1];

    [self assert:[[decoded superview] subviews][0] equals:[decoded delegate]];
}

- (void)testADecodedTabViewKeepsItsDelegate
{
    var tabView = [[CPTabView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];

    [tabView setDelegate:target];
    [container addSubview:tabView];

    var decoded = [[self archived:container] subviews][1];

    [self assert:[[decoded superview] subviews][0] equals:[decoded delegate]];
}

- (void)testADecodedSplitViewKeepsItsDelegate
{
    var splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];

    [splitView setDelegate:target];
    [container addSubview:splitView];

    var decoded = [[self archived:container] subviews][1];

    [self assert:[[decoded superview] subviews][0] equals:[decoded delegate]];
}

// MARK: The view hierarchy

- (void)testADecodedSubviewKeepsItsResponderChain
{
    var child = [[CPView alloc] initWithFrame:CGRectMakeZero()];

    [container addSubview:child];

    var decoded = [self archived:container];

    [self assert:decoded equals:[[decoded subviews][1] nextResponder]];
}

- (void)testADecodedViewAutoresizesItsSubviews
{
    var child = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];

    [child setAutoresizingMask:CPViewWidthSizable];
    [container addSubview:child];

    var decoded = [self archived:container];

    [decoded setFrameSize:CGSizeMake(400.0, 300.0)];

    [self assert:200.0 equals:CGRectGetWidth([[decoded subviews][1] frame])];
}

// MARK: Objects a class creates or observes

- (void)testADecodedButtonBarFollowsAHiddenButton
{
    var buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 26.0)],
        buttons = [[CPButtonBar plusButton], [CPButtonBar minusButton]];

    [buttonBar setButtons:buttons];
    [buttonBar layoutSubviews];

    var decoded = [self archived:buttonBar],
        decodedButtons = [decoded buttons];

    [decoded layoutSubviews];
    [_CPDisplayServer run];

    var firstOrigin = CGRectGetMinX([decodedButtons[0] frame]);

    [decodedButtons[0] setHidden:YES];
    [_CPDisplayServer run];

    [self assert:firstOrigin equals:CGRectGetMinX([decodedButtons[1] frame])];
}

- (void)testADecodedStepperStepsItsValue
{
    var stepper = [[CPStepper alloc] initWithFrame:CGRectMake(0.0, 0.0, 30.0, 25.0)];

    [stepper setMinValue:1.0];
    [stepper setMaxValue:9.0];
    [stepper setDoubleValue:4.0];

    var decoded = [self decodedConnectedControl:stepper];

    [decoded performClickUp:nil];
    [self assert:5.0 equals:[decoded doubleValue]];

    [decoded performClickDown:nil];
    [self assert:4.0 equals:[decoded doubleValue]];

    [self assert:2 equals:[[decoded target] actionCount]];
}

- (void)testADecodedSearchFieldCancelsItsText
{
    var field = [[CPSearchField alloc] initWithFrame:CGRectMake(0.0, 0.0, 120.0, 30.0)];

    [field setStringValue:@"Text"];

    var decoded = [self archived:field];

    [decoded cancelOperation:nil];

    [self assert:@"" equals:[decoded stringValue]];
    [self assertTrue:[[decoded cancelButton] isHidden]];
}

- (void)testADecodedPopUpButtonAcceptsNewItems
{
    var button = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 120.0, 24.0)];

    [button addItemsWithTitles:[@"One", @"Two"]];
    [button selectItemAtIndex:1];

    var decoded = [self archived:button];

    [self assert:1 equals:[decoded indexOfSelectedItem]];
    [self assert:@"Two" equals:[decoded titleOfSelectedItem]];

    [decoded addItemWithTitle:@"Three"];
    [decoded selectItemAtIndex:2];

    [self assert:3 equals:[decoded numberOfItems]];
    [self assert:@"Three" equals:[decoded title]];
}

- (void)testADecodedSegmentedControlSelectsASegment
{
    var control = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 24.0)];

    [control setSegmentCount:2];
    [control setLabel:@"One" forSegment:0];
    [control setLabel:@"Two" forSegment:1];
    [control setSelectedSegment:0];

    var decoded = [self archived:control];

    [self assert:0 equals:[decoded selectedSegment]];
    [self assert:@"Two" equals:[decoded labelForSegment:1]];

    [decoded setSelectedSegment:1];

    [self assert:1 equals:[decoded selectedSegment]];
}

- (void)testADecodedTabViewSwitchesItsContent
{
    var tabView = [[CPTabView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)];

    [@"one", @"two"].forEach(function(anIdentifier)
    {
        var item = [[CPTabViewItem alloc] initWithIdentifier:anIdentifier];

        [item setLabel:anIdentifier];
        [item setView:[[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, 50.0)]];
        [tabView addTabViewItem:item];
    });

    [tabView selectTabViewItemAtIndex:1];

    var decoded = [self archived:tabView];

    [self assert:@"two" equals:[[decoded selectedTabViewItem] identifier]];
    [self assertNotNull:[[[decoded selectedTabViewItem] view] superview]];

    [decoded selectTabViewItemAtIndex:0];

    [self assert:@"one" equals:[[decoded selectedTabViewItem] identifier]];
    [self assertNotNull:[[[decoded selectedTabViewItem] view] superview]];
}

- (void)testADecodedSplitViewMovesItsDivider
{
    var splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 100.0)];

    [splitView setVertical:YES];
    [splitView addSubview:[[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 95.0, 100.0)]];
    [splitView addSubview:[[CPView alloc] initWithFrame:CGRectMake(100.0, 0.0, 95.0, 100.0)]];

    var decoded = [self archived:splitView];

    [decoded setPosition:60.0 ofDividerAtIndex:0];

    [self assert:60.0 equals:CGRectGetWidth([[decoded arrangedSubviews][0] frame])];
}

- (void)testADecodedScrollViewScrollsItsDocument
{
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];

    [scrollView setDocumentView:[[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 300.0)]];

    var decoded = [self archived:scrollView];

    [[decoded documentView] scrollPoint:CGPointMake(0.0, 50.0)];

    [self assert:50.0 equals:CGRectGetMinY([decoded documentVisibleRect])];
}

- (void)testADecodedBoxAcceptsANewContentView
{
    var box = [[CPBox alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 100.0)];

    [box setContentView:[[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, 50.0)]];

    var decoded = [self archived:box],
        newContentView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 60.0)];

    [decoded setContentView:newContentView];

    [self assert:newContentView equals:[decoded contentView]];
    [self assertNotNull:[newContentView superview]];
}

- (void)testADecodedAccordionKeepsACollapsedItem
{
    var accordion = [[CPAccordionView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)],
        item = [[CPAccordionViewItem alloc] initWithIdentifier:@"item"];

    [item setLabel:@"Item"];
    [item setView:[[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 50.0)]];
    [accordion addItem:item];
    [accordion collapseItemAtIndex:0];

    var decoded = [self archived:accordion];

    [self assertFalse:[[decoded expandedItemIndexes] containsIndex:0]];

    [decoded toggleItemAtIndex:0];

    [self assertTrue:[[decoded expandedItemIndexes] containsIndex:0]];
}

- (void)testADecodedStackViewAcceptsAnArrangedSubview
{
    var stackView = [[CPStackView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)];

    [stackView addArrangedSubview:[[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, 50.0)]];

    var decoded = [self archived:stackView];

    [decoded addArrangedSubview:[[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, 50.0)]];

    [self assert:2 equals:[[decoded arrangedSubviews] count]];
}

- (void)testADecodedTokenFieldEndsWithItsTokens
{
    var field = [[CPTokenField alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 30.0)];

    [field setObjectValue:[@"One", @"Two"]];

    var decoded = [self archived:field];

    [self assert:[@"One", @"Two"] equals:[decoded objectValue]];

    [decoded setObjectValue:[@"Two"]];

    [self assert:[@"Two"] equals:[decoded objectValue]];
}

- (void)testADecodedTableReadsItsDataSource
{
    var tableView = [[CPTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)];

    [tableView addTableColumn:[[CPTableColumn alloc] initWithIdentifier:@"Column"]];
    [tableView setDataSource:[[_CPDecodedTableDataSource alloc] init]];

    var decoded = [self archived:tableView];

    [decoded reloadData];

    [self assert:3 equals:[decoded numberOfRows]];
}

- (void)testADecodedOutlineReadsItsDataSource
{
    var outlineView = [[CPOutlineView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)],
        column = [[CPTableColumn alloc] initWithIdentifier:@"Column"];

    [outlineView addTableColumn:column];
    [outlineView setOutlineTableColumn:column];
    [outlineView setDataSource:[[_CPDecodedOutlineDataSource alloc] init]];

    var decoded = [self archived:outlineView];

    [decoded reloadData];

    [self assert:1 equals:[decoded numberOfRows]];
    [self assert:@"Parent" equals:[decoded itemAtRow:0]];
    [self assert:@"Parent" equals:[decoded _objectValueForTableColumn:[decoded outlineTableColumn] row:0 useCache:NO]];

    [decoded expandItem:@"Parent"];

    [self assert:2 equals:[decoded numberOfRows]];
}

@end
