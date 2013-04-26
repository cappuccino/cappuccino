/*
 * _CPPopUpList.j
 * AppKit
 *
 * Created by Aparajita Fishman.
 * Copyright (c) 2012, The Cappuccino Foundation
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

@import "CPPanel.j"
@import "CPTableView.j"
@import "CPText.j"
@import "_CPPopUpListDataSource.j"

@class CPScrollView
@class CPApp

@global CPLineBorder


/*!
    Notification sent when the list is about to pop up. \c object is the _CPPopUpList.
*/
_CPPopUpListWillPopUpNotification = @"_CPPopUpListWillPopUpNotification";

/*!
    Notification sent when the list is about to be dismissed. \c object is the _CPPopUpList.
*/
_CPPopUpListWillDismissNotification = @"_CPPopUpListWillDismissNotification";

/*!
    Notification sent when the list is dismissed. \c object is the _CPPopUpList.
*/
_CPPopUpListDidDismissNotification = @"_CPPopUpListDidDismissNotification";

/*!
    Notification sent by when an item is selected. \c object is the _CPPopUpList.
    When this is received the list has already been dismissed and the dismiss notification has been sent.
*/
_CPPopUpListItemWasClickedNotification = @"_CPPopUpListItemWasClickedNotification";

/*!
    @ignore

    The minimum number of items that must be visible below the related field.
    If less than this number would be completely visible, and there is room for this many complete items
    above the field, the list is displayed above.
*/
var ListMinimumItems = 3;

/*! @ignore */
var ListColumnIdentifier = @"1";


/*!
    This class is a controller for a panel that can pop up and display a scrollable list of items in a CPTableView.
    It is used by CPComboBox to display the list of choices.

    This class requires a data source which must conform to the interface of _CPPopUpListDataSource.

    Objects of this class send the following notifications:

    _CPPopUpListWillPopUpNotification
    _CPPopUpListWillDismissNotification
    _CPPopUpListDidDismissNotification
    _CPPopUpListItemWasClickedNotification
*/
@implementation _CPPopUpList : CPObject
{
    _CPPopUpListDataSource  _dataSource;
    BOOL                    _itemWasClicked;
    BOOL                    _listWasClicked;
    int                     _listWidth;
    _CPPopUpPanel           _panel;
    CPScrollView            _scrollView;
    _CPPopUpTableView       _tableView;
    CPTableColumn           _tableColumn;
}

#pragma mark Creating and Displaying a List

/*!
    Creates a pop up list of choices that will display in a scrollable CPTableView.

    @param aDataSource    A subclass of _CPPopUpListDataSource
*/
- (id)initWithDataSource:(_CPPopUpListDataSource)aDataSource
{
    self = [super init];

    if (self)
    {
        [self setDataSource:aDataSource];
        _itemWasClicked = NO;
        _listWasClicked = NO;
        _listWidth = 0;

        _tableView = [self makeTableView];

        // Start with a default size, we will resize it later
        var frame = CGRectMake(0, 0, 200, 200);

        _tableColumn = [[CPTableColumn alloc] initWithIdentifier:ListColumnIdentifier];
        [_tableColumn setWidth:CGRectGetWidth(frame) - [CPScroller scrollerWidth]];
        [_tableColumn setResizingMask:CPTableColumnAutoresizingMask];
        [_tableView addTableColumn:_tableColumn];

        _scrollView = [self makeScrollViewWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))];
        [_scrollView setDocumentView:_tableView];

        // This has to be done after setDocumentView so that the table knows which scroll view to update
        [_tableView setHeaderView:nil];

        _panel = [self makeListPanelWithFrame:frame];
        [[_panel contentView] addSubview:_scrollView];
        [_panel setInitialFirstResponder:_tableView];

        if ([_dataSource numberOfItemsInList:self] > 0)
            [_tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        else
            [_tableView setEnabled:NO];

        [_scrollView scrollToBeginningOfDocument:nil];
    }

    return self;
}

/*! @ignore */
- (CPPanel)makeListPanelWithFrame:(CGRect)aFrame
{
    var panel = [[_CPPopUpPanel alloc] initWithContentRect:aFrame styleMask:CPBorderlessWindowMask];

    [panel setTitle:@""];
    [panel setFloatingPanel:YES];
    [panel setBecomesKeyOnlyIfNeeded:YES];
    [panel setLevel:CPPopUpMenuWindowLevel];
    [panel setHasShadow:YES];
    [panel setShadowStyle:CPMenuWindowShadowStyle];
    [panel setDelegate:self];

    return panel;
}

/*! @ignore */
- (_CPPopUpTableView)makeTableView
{
    [self removeTableViewObservers];

    var table = [[_CPPopUpTableView alloc] initWithFrame:CGRectMakeZero()];

    [table setDelegate:self];
    [table setDataSource:self];
    [table setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [table setUsesAlternatingRowBackgroundColors:NO];
    [table setAllowsMultipleSelection:NO];
    [table setIntercellSpacing:CGSizeMake(3, 2)];
    [table setTarget:self];
    [table setDoubleAction:@selector(tableViewClickAction:)];
    [table setAction:@selector(tableViewClickAction:)];
    [table setRowHeight:[self rowHeightForTableView:table]];

    return table;
}

/*! @ignore */
- (void)removeTableViewObservers
{
    if (_tableView)
    {
        var defaultCenter = [CPNotificationCenter defaultCenter];

        [defaultCenter removeObserver:self name:CPTableViewSelectionIsChangingNotification object:_tableView];
        [defaultCenter removeObserver:self name:CPTableViewSelectionDidChangeNotification object:_tableView];
    }
}

/*! @ignore */
- (CPScrollView)makeScrollViewWithFrame:(CGRect)aFrame
{
    var scroll = [[CPScrollView alloc] initWithFrame:aFrame];

    [scroll setBorderType:CPLineBorder];
    [scroll setAutohidesScrollers:NO];
    [scroll setHasVerticalScroller:YES];
    [scroll setHasHorizontalScroller:NO];
    [scroll setLineScroll:[_tableView rowHeight]];
    [scroll setVerticalPageScroll:0.0];

    return scroll;
}

/*!
    Pop up the list if it is not already visible.
    If it is not visible, a _CPPopUpListWillPopUpNotification will be sent.

    @param aRect    A rect (in \c aView coordinates) to display relative to
    @param aView    The view whose coordinate system \c aRect is in
    @param offset   How far to offset the list from \c aRect
*/
- (void)popUpRelativeToRect:(CGRect)aRect view:(CPView)aView offset:(int)offset
{
    if ([_panel isVisible])
        return;

    var rowRect = [_tableView rectOfRow:[self numberOfRowsInTableView:_tableView] - 1],
        frame = CGRectMake(0, 0, MAX(_listWidth, CGRectGetWidth(aRect)), CGRectGetMaxY(rowRect));

    // Place the frame relative to aRect and constrain it to the screen bounds
    frame = [self constrain:frame relativeToRect:aRect view:aView offset:offset];

    [_panel setFrame:frame];
    [_scrollView setFrameSize:CGSizeMakeCopy(frame.size)];
    [_tableView setEnabled:[_dataSource numberOfItemsInList:self] > 0];
    [self scrollItemAtIndexToTop:[_tableView selectedRow]];

    [self listWillPopUp];

    [_panel orderFront:nil];
}

#pragma mark Setting Display Attributes

/*!
    Returns the desired width of the list.
*/
- (int)listWidth
{
    return _listWidth;
}

/*!
    Sets the desired width of the list for the next call to \ref showListForfield:relativeTo:.
    Note that the actual display width may be larger if the given width is less than the width of the associated
    field.
*/
- (void)setListWidth:(int)width
{
    _listWidth = width;
}

- (void)setFont:(CPFont)aFont
{
    var oldDataView = [_tableColumn dataView],
        newDataView = [CPTextField new];

    [newDataView setFont:aFont];
    [newDataView setAlignment:[oldDataView alignment]];
    [_tableColumn setDataView:newDataView];

    // Force the data view cache to flush
    [_tableView reloadData];
}

- (void)setAlignment:(CPTextAlignment)alignment
{
    var oldDataView = [_tableColumn dataView],
        newDataView = [CPTextField new];

    [newDataView setAlignment:alignment];
    [newDataView setFont:[oldDataView font]];
    [_tableColumn setDataView:newDataView];

    // Force the data view cache to flush
    [_tableView reloadData];
}

/*!
    Returns whether the list is currently visible.
*/
- (BOOL)isVisible
{
    return [_panel isVisible];
}

/*!
    Returns the desired row height for the table view.
    Subclasses should override this if they want something other than the default.
*/
- (int)rowHeightForTableView:(CPTableView)aTableView
{
    return [aTableView rowHeight];
}

/*!
    Returns the table view used by the list.
*/
- (CPTableView)tableView
{
    return _tableView;
}

/*!
    Returns the single table column used by the list.
*/
- (CPTableColumn)tableColumn
{
    return _tableColumn;
}

/*!
    Returns the scroll view used by the list.
*/
- (CPScrollView)scrollView
{
    return _scrollView;
}

/*!
    Returns the panel in which the list appears.
*/
- (CPPanel)panel
{
    return _panel;
}

#pragma mark Setting a Data Source

- (void)setDataSource:(_CPPopUpListDataSource)aDataSource
{
    if (_dataSource === aDataSource)
        return;

    if (![_CPPopUpListDataSource protocolIsImplementedByObject:aDataSource])
    {
        CPLog.warn("Illegal %s data source (%s). Must implement the methods in _CPPopUpListDataSource.", [self className], [aDataSource description]);
    }
    else
        _dataSource = aDataSource;
}

- (_CPPopUpListDataSource)dataSource
{
    return _dataSource;
}

#pragma mark Manipulating the Selection

/*!
    Select the next item in the list if there one. If there is currently no selected item,
    the first item is selected. Returns YES if the selection changed.
*/
- (BOOL)selectNextItem
{
    if (![_tableView isEnabled])
        return NO;

    var row = [_tableView selectedRow];

    if (row < ([_dataSource numberOfItemsInList:self] - 1))
        return [self selectRow:++row];
    else
        return NO;
}

/*!
    Select the previous item in the list. If there is currently no selected item,
    nothing happens. Returns YES if the selection changed.
*/
- (BOOL)selectPreviousItem
{
    if (![_tableView isEnabled])
        return NO;

    var row = [_tableView selectedRow];

    if (row > 0)
        return [self selectRow:--row];
    else
        return NO;
}

/*!
    Returns the selected object value. If no value is selected,
    returns nil.
*/
- (id)selectedObjectValue
{
    var row = [_tableView selectedRow];

    return (row >= 0) ? [_dataSource list:self objectValueForItemAtIndex:row] : nil;
}

/*!
    Returns the selected value as a single-line string. If no value is selected,
    returns nil.
*/
- (CPString)selectedStringValue
{
    var value = [self selectedObjectValue];

    return value !== nil ? [_dataSource list:self stringValueForObjectValue:value] : nil;
}

/*!
    Returns the last selected row in the list. If no row has been selected, returns -1.
*/
- (int)selectedRow
{
    return [_tableView selectedRow];
}

/*!
    Selects a row and scrolls it to be visible. Returns YES if the selection actually changed.
*/
- (BOOL)selectRow:(int)row
{
    if (row === [_tableView selectedRow])
        return NO;

    var validRow = (row >= 0 && row < [self numberOfRowsInTableView:_tableView]),
        indexes = validRow ? [CPIndexSet indexSetWithIndex:row] : [CPIndexSet indexSet];

    [_tableView selectRowIndexes:indexes byExtendingSelection:NO];

    if (validRow)
    {
        [_tableView scrollRowToVisible:row];
        return YES;
    }
    else
        return NO;
}

#pragma mark Manipulating the Displayed List

/*!
    Scroll the list down one page.
*/
- (void)scrollPageDown
{
    [_scrollView scrollPageDown:nil];
}

/*!
    Scroll the list up one page.
*/
- (void)scrollPageUp
{
    [_scrollView scrollPageUp:nil];
}

/*!
    Scroll to the top of the list.
*/
- (void)scrollToTop
{
    [_scrollView scrollToBeginningOfDocument:nil];
}

/*!
    Scroll to the bottom of the list.
*/
- (void)scrollToBottom
{
    [_scrollView scrollToEndOfDocument:nil];
}

- (void)scrollItemAtIndexToTop:(int)row
{
    var rect = [_tableView rectOfRow:row];

    [[_tableView superview] scrollToPoint:rect.origin];
}

/*!
    Close the list if it is currently visible. If it is visible,
    a CPComboBoxWillDismissNotification will be sent. If the
    list is being closed after an item was clicked, the close
    is delayed slightly so the user can briefly see the clicked row
    get highlighted.
*/
- (void)close
{
    if (![_panel isVisible])
        return;

    if ([self listWasClicked])
    {
        [self setListWasClicked:NO];

        // Wait until we get through the run loop and delay a little
        // so the user can briefly see the clicked row get highlighted.
        if ([self itemWasClicked])
        {
            [self setItemWasClicked:NO];
            [CPTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(closeListAfterItemClick) userInfo:nil repeats:NO];
            return;
        }
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:_CPPopUpListWillDismissNotification object:self];
    [_panel close];
    [[CPNotificationCenter defaultCenter] postNotificationName:_CPPopUpListDidDismissNotification object:self];
}

/*!
    Close the list after an item was clicked.
*/
- (void)closeListAfterItemClick
{
    [self close];
    [[CPNotificationCenter defaultCenter] postNotificationName:_CPPopUpListItemWasClickedNotification object:self];
}

#pragma mark Handling Events

/*!
    Handles standard key equivalents for moving the selection
    and selecting an item. This method should be called by
    the -performKeyEquivalent method of the field that is
    controlling the list.
*/
- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    var key = [anEvent charactersIgnoringModifiers];

    switch (key)
    {
        case CPDownArrowFunctionKey:
            if ([self isVisible])
            {
                [self selectNextItem];
                return YES;
            }
            break;

        case CPUpArrowFunctionKey:
            if ([self isVisible])
            {
                [self selectPreviousItem];
                return YES;
            }
            break;

        case CPEscapeFunctionKey:
            if ([self isVisible])
            {
                [self close];
                return YES;
            }
            break;

        case CPPageUpFunctionKey:
            if ([self isVisible])
            {
                [self scrollPageUp];
                return YES;
            }
            break;

        case CPPageDownFunctionKey:
            if ([self isVisible])
            {
                [self scrollPageDown];
                return YES;
            }
            break;

        case CPHomeFunctionKey:
            if ([self isVisible])
            {
                [self scrollToTop];
                return YES;
            }
            break;

        case CPEndFunctionKey:
            if ([self isVisible])
            {
                [self scrollToBottom];
                return YES;
            }
            break;

        case CPCarriageReturnCharacter:
            if ([self isVisible])
            {
                [self closeListAfterItemClick];
                return YES;
            }
            break;
    }

    return NO;
}

/*!
    Returns whether an item in the list was clicked since it was opened.
    If there are no items, \ref itemWasClicked will always return NO.
*/
- (BOOL)itemWasClicked
{
    return _itemWasClicked && ([_dataSource numberOfItemsInList:self] > 0);
}

/*!
    Sets whether an item in the list was clicked since it was opened.
    If there are no items, \ref itemWasClicked will always return NO.

    Subclasses will usually want to set this in the mouseDown:
    of the control.
*/
- (void)setItemWasClicked:(BOOL)flag
{
    _itemWasClicked = ([_dataSource numberOfItemsInList:self] > 0) && flag;
}

/*!
    Returns whether any view in the list was clicked since it was opened.
    If there are no items, \ref listWasClicked will always return NO.
*/
- (BOOL)listWasClicked
{
    return _listWasClicked && ([_dataSource numberOfItemsInList:self] > 0);
}

/*!
    Sets whether any view in the list was clicked since it was opened.
    If there are no items, \ref listWasClicked will always return NO.

    Subclasses will usually want to use a subclass of CPPanel and override
    sendEvent: to set this flag when the event type is CPLeftMouseDown
    or CPRightMouseDown. This is distinct from \ref itemWasClicked because,
    for example, a scroller in the list may be clicked without clicking an
    item in the list.
*/
- (void)setListWasClicked:(BOOL)flag
{
    _listWasClicked = ([_dataSource numberOfItemsInList:self] > 0) && flag;
}

/*!
    Returns whether a controlling view should resign. This should be called
    from the controlling view's resignFirstResponder method.
*/
- (BOOL)controllingViewShouldResign
{
    if ([self listWasClicked])
    {
        /*
            If an item was not clicked (probably the scrollbar), clear the click flag so that future
            clicks outside the list will allow it to close.
        */
        if ([self listWasClicked] && ![self itemWasClicked])
            [self setListWasClicked:NO];

        return NO;
    }
    else
        return YES;
}

#pragma mark Internal Helpers

/*! @ignore */
- (void)listWillPopUp
{
    [[CPNotificationCenter defaultCenter] postNotificationName:_CPPopUpListWillPopUpNotification object:self];
}

/*!
    Return a frame in platform window base coordinates such that the list, when displayed, will show at least ListMinimumItems
    items completely on screen. Normally the list should be displayed below \c aRect, but if there is not room
    for at least ListMinimumItems items, an attempt should be made to display that many
    items above \c aRect. If the minimum cannot be displayed on top, whichever direction can display more items
    is chosen.
    @ignore
*/
- (CGRect)constrain:(CGRect)aFrame relativeToRect:(CGRect)aRect view:(CPView)aView offset:(int)offset
{
    // Convert from the view's coordinate system to the coordinate system of the primary platform window
    var baseOrigin = [aView convertPointToBase:aRect.origin],
        windowOrigin = [[aView window] convertBaseToPlatformWindow:baseOrigin],
        rowHeight = [self rowHeightForTableView:_tableView] + [_tableView intercellSpacing].height,

        // Be sure to clip the number of displayed rows to what the field wants
        numberOfRows = MIN([self numberOfRowsInTableView:_tableView], [_dataSource numberOfVisibleItemsInList:self]),

        // Add 2 to height for border
        frame = CGRectMake(windowOrigin.x, windowOrigin.y + CGRectGetHeight(aRect) + offset, MAX(_listWidth, CGRectGetWidth(aFrame)), (rowHeight * numberOfRows) + 2),

        // Get the bottom coordinate of the frame and the platform window
        bottomFrame = CGRectMakeCopy(frame),
        bottom = CGRectGetMaxY(bottomFrame),
        viewRect = [[CPPlatformWindow primaryPlatformWindow] visibleFrame],
        visibleBottom = CGRectGetMaxY(viewRect),
        bottomVisibleRows = numberOfRows;

    // Make sure it will fit in the screen. If not, reduce the number of items till we reach the minimum.
    while (bottom > visibleBottom && bottomVisibleRows >= ListMinimumItems)
    {
        bottom -= rowHeight;
        bottomFrame.size.height -= rowHeight;
        --bottomVisibleRows;
    }

    if (bottom >= visibleBottom || bottomVisibleRows < ListMinimumItems)
    {
        // The minimum number of items will not fit, try above
        var topFrame = CGRectMakeCopy(frame);

        topFrame.origin.y = windowOrigin.y - offset - CGRectGetHeight(topFrame);

        var visibleTop = CGRectGetMinY(viewRect),
            topVisibleRows = numberOfRows;

        while (topFrame.origin.y <= visibleTop && topVisibleRows >= ListMinimumItems)
        {
            topFrame.origin.y += rowHeight;
            topFrame.size.height -= rowHeight;
            --topVisibleRows;
        }

        // If there is room on the top or it can display more than at the bottom, show it there
        if ((topFrame.origin.y > visibleTop && topVisibleRows >= ListMinimumItems) || topVisibleRows > bottomVisibleRows)
            frame = topFrame;
        else
            frame = bottomFrame;
    }
    else
        frame = bottomFrame;

    return frame;
}

- (void)tableViewClickAction:(id)sender
{
    [self close];
}

@end


var _CPPopUpListDataSourceKey   = @"_CPPopUpListDataSourceKey",
    _CPPopUpListListWidthKey    = @"_CPPopUpListListWidthKey",
    _CPPopUpListListPanelKey    = @"_CPPopUpListListPanelKey",
    _CPPopUpListScrollViewKey   = @"_CPPopUpListScrollViewKey",
    _CPPopUpListTableViewKey    = @"_CPPopUpListTableViewKey";

@implementation _CPPopUpList (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _listWasClicked = NO;
        _itemWasClicked = NO;

        _dataSource = [aCoder decodeObjectForKey:_CPPopUpListDataSourceKey];
        _listWidth = [aCoder decodeIntForKey:_CPPopUpListListWidthKey];
        _panel = [aCoder decodeObjectForKey:_CPPopUpListListPanelKey];
        _scrollView = [aCoder decodeObjectForKey:_CPPopUpListScrollViewKey];
        _tableView = [aCoder decodeObjectForKey:_CPPopUpListTableViewKey];
        _tableColumn = [_tableView tableColumnWithIdentifier:ListColumnIdentifier];
        [_scrollView setDocumentView:_tableView];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_dataSource forKey:_CPPopUpListDataSourceKey];
    [aCoder encodeObject:_listWidth forKey:_CPPopUpListListWidthKey];
    [aCoder encodeObject:_panel forKey:_CPPopUpListListPanelKey];
    [aCoder encodeObject:_scrollView forKey:_CPPopUpListScrollViewKey];
    [aCoder encodeObject:_tableView forKey:_CPPopUpListTableViewKey];
}

@end

@implementation _CPPopUpList (CPTableViewDataSource)

- (int)numberOfRowsInTableView:(id)aTableView
{
    return MAX([_dataSource numberOfItemsInList:self], 1);
}

- (id)tableView:(id)aTableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    return [_dataSource list:self displayValueForObjectValue:[_dataSource list:self objectValueForItemAtIndex:aRow]];
}

@end

@implementation _CPPopUpTableView : CPTableView
{
    BOOL _acceptFirstResponder;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        // We want the autocomplete to remain first responder until we are clicked.
        _acceptFirstResponder = NO;
    }

    return self;
}

- (void)trackMouse:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;

    [[self delegate] setItemWasClicked:YES];

    // CPTableView will not track the click if it is not first responder
    _acceptFirstResponder = YES;
    [[self window] makeFirstResponder:self];
    [super trackMouse:anEvent];
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    _acceptFirstResponder = NO;
    [super stopTracking:lastPoint at:aPoint mouseIsUp:mouseIsUp];
}

- (BOOL)acceptsFirstResponder
{
    return _acceptFirstResponder;
}

/*!
    Return the column used for the list.
*/
- (CPTableColumn)listColumn
{
    return _tableColumns[0];
}

@end

@implementation _CPPopUpPanel : CPPanel

- (id)initWithContentRect:(CGRect)aContentRect styleMask:(unsigned int)aStyleMask
{
    if (self = [super initWithContentRect:aContentRect styleMask:aStyleMask])
        _constrainsToUsableScreen = NO;

    [self _trapNextMouseDown];

    return self;
}

- (void)sendEvent:(CPEvent)anEvent
{
    var type = [anEvent type];

    if (type === CPLeftMouseDown || type === CPRightMouseDown)
        [[self delegate] setListWasClicked:YES];

    return [super sendEvent:anEvent];
}

- (void)orderFront:(id)sender
{
    [self _trapNextMouseDown];
    [super orderFront:sender];
}

- (void)_mouseWasClicked:(CPEvent)anEvent
{
    var mouseWindow = [anEvent window],
        rect = [[[self delegate] dataSource] bounds],
        point = [[[self delegate] dataSource] convertPoint:[anEvent locationInWindow] fromView:nil];

    if (mouseWindow != self && !CGRectContainsPoint(rect, point))
        [[self delegate] close];
    else if ([mouseWindow firstResponder] == [[self delegate] dataSource])
        [self _trapNextMouseDown];
}

- (void)_trapNextMouseDown
{
    // Don't dequeue the event so clicks in controls will work
    [CPApp setTarget:self selector:@selector(_mouseWasClicked:) forNextEventMatchingMask:CPLeftMouseDownMask untilDate:nil inMode:CPDefaultRunLoopMode dequeue:NO];
}

@end
