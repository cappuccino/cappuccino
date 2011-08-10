/*
 * _CPPopUpList.j
 * AppKit
 *
 * Created by Aparajita Fishman.
 * Copyright (c) 2011, Intalio, Inc.
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

@import <AppKit/CPTableView.j>


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
    Notification sent when the selection of the list changes. \c object is the _CPPopUpList.
*/
_CPPopUpListDidDismissNotification = @"_CPPopUpListDidDismissNotification";

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
    The minimum number of items that must be visible below the related field.
    If less than this number would be completely visible, and there is room for this many complete items
    above the field, the list is displayed above.
*/
var ListMinimumItems = 3;

/*! @ignore */
var ListColumnIdentifier = @"1";


/*!
    This class is a controller for a panel that can pop up and display a scrollable list of items in a CPTableView.
    For tables that display single-line rows of scalar data, no subclassing should be necessary.

    The delegate of this class MUST implement the following methods:

    numberOfItems               The number of items the list should display
    numberOfVisibleItems        The maximum number of items to display at once
    objectValueForItemAtIndex:  Retrieves an object value for an item in the range 0..(numberOfItems - 1)

    Objects of this class send the following notifications:

    _CPPopUpListWillPopUpNotification
    _CPPopUpListWillDismissNotification
    _CPPopUpListDidDismissNotification
    _CPPopUpListItemWasClickedNotification
*/
@implementation _CPPopUpList : CPObject
{
    _CPPopUpListDelegate    _delegate;
    BOOL                    _itemWasClicked;
    BOOL                    _listWasClicked;
    int                     _listWidth;
    _CPPopUpPanel           _panel @accessors(readonly, property=panel);
    CPScrollView            _scrollView @accessors(readonly, property=scrollView);
    _CPPopUpTableView       _tableView @accessors(readonly, property=tableView);
    CPTableColumn           _tableColumn;
}

/*!
    Creates a pop up list of choices which will display relative to the given rect in base coordinates.

    @param aDelegate    The object that usually is controlling this list.
    @param baseRect     A rect in base coordinates relative to which the list should be displayed
*/
- (id)initWithDelegate:(_CPPopUpListDelegate)aDelegate
{
    self = [super init];

    if (self)
    {
        _delegate = aDelegate;
        _tableView = [self makeTableView];

        // Start with a default size, we will resize it later
        frame = CGRectMake(0, 0, 200, 200);

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

        if ([_delegate numberOfItems] > 0)
            [_tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        else
            [_tableView setEnabled:NO];

        [_scrollView scrollToBeginningOfDocument:nil];

        [self finalizeTableView:_tableView];
    }

    return self;
}

/*!
    Create and configure the panel containing the table view.
    Subclasses should override this (and usually call super first)
    if they want to customize the list panel.
*/
- (CPPanel)makeListPanelWithFrame:(CGRect)aFrame
{
    var panel = [[_CPPopUpPanel alloc] initWithContentRect:aFrame styleMask:CPBorderlessWindowMask];

    [panel setTitle:@""];
    [panel setFloatingPanel:YES];
    [panel setBecomesKeyOnlyIfNeeded:YES];
    [panel setHasShadow:NO];
    [panel setDelegate:self];

    return panel;
}

/*!
    Create and configure the table view. Subclasses should use \ref finalizeTableView:.
*/
- (_CPPopUpTableView)makeTableView
{
    [self removeTableViewObservers];

    var table = [[_CPPopUpTableView alloc] initWithFrame:CGRectMakeZero()];

    [table setDelegate:self];
    [table setDataSource:self];
    [table setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [table setUsesAlternatingRowBackgroundColors:NO];
    [table setAllowsMultipleSelection:NO];
    [table setIntercellSpacing:CGSizeMake(0, 0)];
    [table setTarget:self];
    [table setDoubleAction:@selector(tableViewClickAction:)];
    [table setAction:@selector(tableViewClickAction:)];
    [table setRowHeight:[self rowHeightForTableView:table]];

    return table;
}

- (void)removeTableViewObservers
{
    if (_tableView)
    {
        var defaultCenter = [CPNotificationCenter defaultCenter];

        [defaultCenter removeObserver:self name:CPTableViewSelectionIsChangingNotification object:_tableView];
        [defaultCenter removeObserver:self name:CPTableViewSelectionDidChangeNotification object:_tableView];
    }
}

/*!
    If subclasses want to configure the table view after it has been
    completely configured, for example to set a custom data view,
    this is the place. Such customization can also be done by an
    observer of _CPPopUpListListWillDisplayNotification.
*/
- (void)finalizeTableView:(CPTableView)aTableView
{
}

/*!
    Creates and configures the scroll view containing the table view.
    Subclasses should override this (and usually call super first)
    if they want to customize the scroll view.
*/
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

/!*
    Pop up the list if it is not already visible.
    If it is not visible, a _CPPopUpListWillPopUpNotification will be sent.
*/
- (void)popUpRelativeTo:(CGRect)baseRect
{
    if ([_panel isVisible])
        return;

    var frame = CGRectMake(0, 0, MAX(_listWidth, CGRectGetWidth(baseRect)), [self rowHeightForTableView:_tableView] * [self numberOfRowsInTableView:_tableView]);

    // Place the frame relative to the baseRect and constrain it to the screen bounds
    frame = [self constrain:frame relativeTo:baseRect];

    [_panel setFrame:frame];
    [_scrollView setFrameSize:CGSizeMakeCopy(frame.size)];

    [self listWillPopUp];

    [_panel orderFront:nil];
}

/*!
    Return a frame in base coordinates such that the list, when displayed, will show at least ListMinimumItems
    items completely on screen. Normally the list should be displayed below \c baseRect, but if there is not room
    for at least ListMinimumItems items, an attempt should be made to display that many
    items above \c baseRect. If the minimum cannot be displayed on top, whichever direction can display more items
    is chosen.
*/
- (CGRect)constrain:(CGRect)aFrame relativeTo:(CGRect)baseRect
{
    var baseOrigin = CGPointMake(CGRectGetMinX(baseRect), CGRectGetMaxY(baseRect)),
        rowHeight = [self rowHeightForTableView:_tableView],
        // Be sure to clip the number of displayed rows to what the field wants
        numberOfRows = MIN([self numberOfRowsInTableView:_tableView], [_delegate numberOfVisibleItems]),
        // Add 2 to height for border
        frame = CGRectMake(baseOrigin.x, baseOrigin.y, MAX(_listWidth, CGRectGetWidth(aFrame)), (rowHeight * numberOfRows) + 2),
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

        topFrame.origin.y = CGRectGetMinY(baseRect) - CGRectGetHeight(topFrame);

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

/*!
    Returns whether the list is currently visible.
*/
- (BOOL)isVisible
{
    return [_panel isVisible];
}

/*!
    Subclasses MUST call this method just before the list is about to display.
*/
- (void)listWillPopUp
{
    [[CPNotificationCenter defaultCenter] postNotificationName:_CPPopUpListWillPopUpNotification object:self];
}

/*!
    Select the next item in the list if there one. If there is currently no selected item,
    the first item is selected. Returns YES if the selection changed.
*/
- (BOOL)selectNextItem
{
    if (![_tableView isEnabled])
        return NO;

    var row = [_tableView selectedRow];

    if (row < ([_delegate numberOfItems] - 1))
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

- (BOOL)selectRow:(int)row
{
    if (row === [_tableView selectedRow])
        return NO;

    var indexes = row >= 0 ? [CPIndexSet indexSetWithIndex:row] : [CPIndexSet indexSet];

    [_tableView selectRowIndexes:indexes byExtendingSelection:NO];

    if (row >= 0)
    {
        [_tableView scrollRowToVisible:row];
        return YES;
    }
    else
        return NO;
}

- (void)scrollRowToTop:(int)row
{
    var rect = [_tableView rectOfRow:row];

    [[_tableView superview] scrollToPoint:rect.origin];
}

/*!
    Returns the selected value as a single-line string. If no value is selected,
    returns nil.
*/
- (CPString)selectedStringValue
{
    var row = [_tableView selectedRow];

    return (row >= 0) ? [self stringValueForObjectValue:[_delegate objectValueForItemAtIndex:row] row:row] : nil;
}

/*!
    Returns whether an item in the list was clicked since it was opened.
    If there are no items, \ref itemWasClicked will always return NO.
*/
- (BOOL)itemWasClicked
{
    return _itemWasClicked && ([_delegate numberOfItems] > 0);
}

/*!
    Sets whether an item in the list was clicked since it was opened.
    If there are no items, \ref itemWasClicked will always return NO.

    Subclasses will usually want to set this in the mouseDown:
    of the control.
*/
- (void)setItemWasClicked:(BOOL)flag
{
    _itemWasClicked = ([_delegate numberOfItems] > 0) && flag;
}

/*!
    Returns whether any view in the list was clicked since it was opened.
    If there are no items, \ref listWasClicked will always return NO.
*/
- (BOOL)listWasClicked
{
    return _listWasClicked && ([_delegate numberOfItems] > 0);
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
    _listWasClicked = ([_delegate numberOfItems] > 0) && flag;
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

/*!
    Returns the desired row height for the table view.
    Subclasses should override this if they want something other than the default.
*/
- (int)rowHeightForTableView:(CPTableView)aTableView
{
    return [aTableView rowHeight];
}

/*!
    Returns a value to display for a single row in the list. Subclasses should override
    this if the table data needs to be converted or formatted in some way to be displayed.
    If there are no search results, an empty string is returned.
    If subclasses use a data representation other than CPStrings, they must override
    this method and return the appropriate data when there are no search results.

    If the table uses a custom data view, this method should return a value suitable
    for sending to the setObjectValue: method of the data view.

    @param  aValue  Table data for the given row
    @param  aRow    The row being displayed
    @return         A value to be displayed in the list
*/
- (id)displayValueForObjectValue:(id)aValue row:(int)aRow
{
    return aValue || @"";
}

/*!
    Returns a single-line string for use in an autocomplete field. Subclasses should override
    this if the row data is not convertable to a simple string, and return the data as a single-line string.

    @param  aValue  Table data to be converted to a string
    @param  aRow    The row whose data is being converted
    @return         A value to be displayed in the autocomplete field
*/
- (CPString)stringValueForObjectValue:(id)aValue row:(int)aRow
{
    return String(aValue);
}

- (void)tableViewClickAction:(id)sender
{
    [self close];
}

@end


var _CPPopUpListFieldKey        = @"_CPPopUpListDelegateKey",
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
        _delegate = [aCoder decodeObjectForKey:_CPPopUpListDelegateKey];
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

    [aCoder encodeObject:_delegate forKey:_CPPopUpListDelegateKey];
    [aCoder encodeObject:_listWidth forKey:_CPPopUpListListWidthKey];
    [aCoder encodeObject:_panel forKey:_CPPopUpListListPanelKey];
    [aCoder encodeObject:_scrollView forKey:_CPPopUpListScrollViewKey];
    [aCoder encodeObject:_tableView forKey:_CPPopUpListTableViewKey];
}

@end

@implementation _CPPopUpList (CPTableViewDelegate)



@end

@implementation _CPPopUpList (CPTableViewDataSource)

- (int)numberOfRowsInTableView:(id)aTableView
{
    return MAX([_delegate numberOfItems], 1);
}

- (id)tableView:(id)aTableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{
    return [self displayValueForObjectValue:[_delegate objectValueForItemAtIndex:aRow] row:aRow];
}

@end

@implementation _CPPopUpTableView : CPTableView

- (void)mouseDown:(CPEvent)anEvent
{
    if (![self isEnabled])
        return;

    [[self delegate] setItemWasClicked:YES];
    [super mouseDown:anEvent];
}

/*
    We always want the autocomplete to have focus
*/
- (BOOL)acceptsFirstResponder
{
    return NO;
}

/*!
    Return the column used for the list.
*/
- (CPTableColumn)listColumn
{
    return [self tableColumnWithIdentifier:ListColumnIdentifier];
}

@end

@implementation _CPPopUpPanel : CPPanel

- (void)sendEvent:(CPEvent)anEvent
{
    var type = [anEvent type];

    if (type === CPLeftMouseDown || type === CPRightMouseDown)
        [[self delegate] setListWasClicked:YES];

    return [super sendEvent:anEvent];
}

@end
