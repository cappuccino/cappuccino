/*
 * CPComboBox.j
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

@import "CPText.j"
@import "CPTextField.j"
@import "_CPPopUpList.j"


CPComboBoxSelectionDidChangeNotification  = @"CPComboBoxSelectionDidChangeNotification";
CPComboBoxSelectionIsChangingNotification = @"CPComboBoxSelectionIsChangingNotification";
CPComboBoxWillDismissNotification         = @"CPComboBoxWillDismissNotification";
CPComboBoxWillPopUpNotification           = @"CPComboBoxWillPopUpNotification";

CPComboBoxStateButtonBordered = CPThemeState("button-bordered");

var CPComboBoxTextSubview = @"text",
    CPComboBoxButtonSubview = @"button",
    CPComboBoxDefaultNumberOfVisibleItems = 5,
    CPComboBoxFocusRingWidth = -1;


@implementation CPComboBox : CPTextField
{
    CPArray                 _items;
    _CPPopUpList            _listDelegate;
    CPComboBoxDataSource    _dataSource;
    BOOL                    _usesDataSource;
    BOOL                    _completes;
    BOOL                    _canComplete;
    int                     _numberOfVisibleItems;
    BOOL                    _forceSelection;
    BOOL                    _hasVerticalScroller;
    CPString                _selectedStringValue;
    BOOL                    _popUpButtonCausedResign;
}

+ (CPString)defaultThemeClass
{
    return "combobox";
}

+ (id)themeAttributes
{
    return @{
                @"popup-button-size": CGSizeMake(21.0, 29.0),
                @"border-inset": CGInsetMake(3.0, 3.0, 3.0, 3.0),
            };
}

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding === CPContentBinding || aBinding === CPContentValuesBinding)
        return [_CPComboBoxContentBinder class];

    return [super _binderClassForBinding:aBinding];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
        [self _initComboBox];

    return self;
}

- (void)_initComboBox
{
    _items = [CPArray array];
//    _listClass = [_CPPopUpList class];
    _usesDataSource = NO;
    _completes = NO;
    _canComplete = NO;
    _numberOfVisibleItems = CPComboBoxDefaultNumberOfVisibleItems;
    _forceSelection = NO;
    _hasVerticalScroller = YES;
    _selectedStringValue = @"";
    _popUpButtonCausedResign = NO;

    [self setTheme:[CPTheme defaultTheme]];
    [self setBordered:YES];
    [self setBezeled:YES];
    [self setEditable:YES];
    [self setThemeState:CPComboBoxStateButtonBordered];
}

#pragma mark Setting Display Attributes

- (BOOL)hasVerticalScroller
{
    return _hasVerticalScroller;
}

- (void)setHasVerticalScroller:(BOOL)flag
{
    flag = !!flag;

    if (_hasVerticalScroller === flag)
        return;

    _hasVerticalScroller = flag;
    [[_listDelegate scrollView] setHasVerticalScroller:flag];
}

- (CGSize)intercellSpacing
{
    return [[_listDelegate tableView] intercellSpacing];
}

- (void)setIntercellSpacing:(CGSize)aSize
{
    [[_listDelegate tableView] setIntercellSpacing:aSize];
}

- (BOOL)isButtonBordered
{
    return [self hasThemeState:CPComboBoxStateButtonBordered];
}

- (void)setButtonBordered:(BOOL)flag
{
    if (!!flag)
        [self setThemeState:CPComboBoxStateButtonBordered];
    else
        [self unsetThemeState:CPComboBoxStateButtonBordered];
}

- (float)itemHeight
{
    return [[_listDelegate tableView] rowHeight];
}

- (void)setItemHeight:(float)itemHeight
{
    [[_listDelegate tableView] setRowHeight:itemHeight];

    // FIXME: This shouldn't be necessary, but CPTableView does not tile after setRowHeight
    [[_listDelegate tableView] reloadData];
}

- (int)numberOfVisibleItems
{
    return _numberOfVisibleItems;
}

- (void)setNumberOfVisibleItems:(int)visibleItems
{
    // There should always be at least 1 visible item!
    _numberOfVisibleItems = MAX(visibleItems, 1);
}

#pragma mark Setting a Delegate

- (id < CPComboBoxDelegate >)delegate
{
    return [super delegate];
}

/*!
    Sets the CPComboBox delegate. Note that although the Cocoa
    docs say that the delegate must conform to the NSComboBoxDelegate
    protocol, in actual fact it doesn't. Also note that the same
    delegate may conform to the NSTextFieldDelegate protocol.
*/
- (void)setDelegate:(id < CPComboBoxDelegate >)aDelegate
{
    var delegate = [self delegate];

    if (aDelegate === delegate)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter];

    if (delegate)
    {
        [defaultCenter removeObserver:delegate name:CPComboBoxSelectionIsChangingNotification object:self];
        [defaultCenter removeObserver:delegate name:CPComboBoxSelectionDidChangeNotification object:self];
        [defaultCenter removeObserver:delegate name:CPComboBoxWillDismissNotification object:self];
        [defaultCenter removeObserver:delegate name:CPComboBoxWillPopUpNotification object:self];
    }

    if (aDelegate)
    {
        if ([aDelegate respondsToSelector:@selector(comboBoxSelectionIsChanging:)])
            [defaultCenter addObserver:delegate
                              selector:@selector(comboBoxSelectionIsChanging:)
                                  name:CPComboBoxSelectionIsChangingNotification
                                object:self];

        if ([aDelegate respondsToSelector:@selector(comboBoxSelectionDidChange:)])
            [defaultCenter addObserver:delegate
                              selector:@selector(comboBoxSelectionDidChange:)
                                  name:CPComboBoxSelectionDidChangeNotification
                                object:self];

        if ([aDelegate respondsToSelector:@selector(comboBoxWillPopUp:)])
            [defaultCenter addObserver:delegate
                              selector:@selector(comboBoxWillPopUp:)
                                  name:CPComboBoxWillPopUpNotification
                                object:self];

        if ([aDelegate respondsToSelector:@selector(comboBoxWillDismiss:)])
            [defaultCenter addObserver:delegate
                              selector:@selector(comboBoxWillDissmis:)
                                  name:CPComboBoxWillDismissNotification
                                object:self];
    }

    [super setDelegate:aDelegate];
}

#pragma mark Setting a Data Source

- (id < CPComboBoxDataSource >)dataSource
{
    if (!_usesDataSource)
        [self _dataSourceWarningForMethod:_cmd condition:NO];

    return _dataSource;
}

- (void)setDataSource:(id < CPComboBoxDataSource >)aSource
{
    if (!_usesDataSource)
        [self _dataSourceWarningForMethod:_cmd condition:NO];
    else if (_dataSource !== aSource)
    {
        if (![aSource respondsToSelector:@selector(numberOfItemsInComboBox:)] ||
            ![aSource respondsToSelector:@selector(comboBox:objectValueForItemAtIndex:)])
        {
            CPLog.warn("Illegal %s data source (%s). Must implement numberOfItemsInComboBox: and comboBox:objectValueForItemAtIndex:", [self className], [aSource description]);
        }
        else
            _dataSource = aSource;
    }
}

- (BOOL)usesDataSource
{
    return _usesDataSource;
}

- (void)setUsesDataSource:(BOOL)flag
{
    flag = !!flag;

    if (_usesDataSource === flag)
        return;

    _usesDataSource = flag;

    // Cocoa empties the internal item list if usesDataSource is YES
    if (_usesDataSource)
        [_items removeAllObjects];

    [self reloadData];
}

#pragma mark Working with an Internal List

- (void)addItemsWithObjectValues:(CPArray)objects
{
    [_items addObjectsFromArray:objects];

    [self reloadDataSourceForSelector:_cmd];
}

- (void)addItemWithObjectValue:(id)anObject
{
    [_items addObject:anObject];

    [self reloadDataSourceForSelector:_cmd];
}

- (void)insertItemWithObjectValue:(id)anObject atIndex:(int)anIndex
{
    // Issue the warning first, because removeObjectAtIndex may raise
    if (_usesDataSource)
        [self _dataSourceWarningForMethod:_cmd condition:YES];

    [_items insertObject:anObject atIndex:anIndex];
    [self reloadData];
}

/*!
    Returns the internal array of items. NOTE: Unlike Cocoa the array is mutable,
    since all arrays in Objective-J are mutable. But you should treat it as
    an immutable array. Do <b>NOT</b> attempt to change the returned array in any way.

    If usesDataSource is YES, a warning is logged and an empty array is returned.
*/
- (CPArray)objectValues
{
    if (_usesDataSource)
        [self _dataSourceWarningForMethod:_cmd condition:YES];

    return _items;
}

- (void)removeAllItems
{
    [_items removeAllObjects];

    [self reloadDataSourceForSelector:_cmd];
}

- (void)removeItemAtIndex:(int)index
{
    // Issue the warning first, because removeObjectAtIndex may raise
    if (_usesDataSource)
        [self _dataSourceWarningForMethod:_cmd condition:YES];

    [_items removeObjectAtIndex:index];
    [self reloadData];
}

- (void)removeItemWithObjectValue:(id)anObject
{
    [_items removeObject:anObject];

    [self reloadDataSourceForSelector:_cmd];
}

- (int)numberOfItems
{
    if (_usesDataSource)
        return [_dataSource numberOfItemsInComboBox:self];
    else
        return _items.length;
}

#pragma mark Manipulating the Displayed List

/*!
    Returns the delegate to be used when creating the pop up list.
*/
- (_CPPopUpList)listDelegate
{
    return _listDelegate;
}

/*!
    Sets the delegate to be used when creating the pop up list.
    By default this is _CPPopUpList. If you are using a subclass
    of _CPPopUpList, call this method with your subclass.
*/
- (void)setListDelegate:(_CPPopUpList)aDelegate
{
    if (_listDelegate === aDelegate)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter];

    if (_listDelegate)
    {
        [defaultCenter removeObserver:self name:_CPPopUpListWillPopUpNotification object:_listDelegate];
        [defaultCenter removeObserver:self name:_CPPopUpListWillDismissNotification object:_listDelegate];
        [defaultCenter removeObserver:self name:_CPPopUpListDidDismissNotification object:_listDelegate];
        [defaultCenter removeObserver:self name:_CPPopUpListItemWasClickedNotification object:_listDelegate];

        var oldTableView = [_listDelegate tableView];

        if (oldTableView)
        {
            [defaultCenter removeObserver:self name:CPTableViewSelectionIsChangingNotification object:oldTableView];
            [defaultCenter removeObserver:self name:CPTableViewSelectionDidChangeNotification object:oldTableView];
        }
    }

    _listDelegate = aDelegate;

    [defaultCenter addObserver:self
                      selector:@selector(comboBoxWillPopUp:)
                          name:_CPPopUpListWillPopUpNotification
                        object:_listDelegate];

    [defaultCenter addObserver:self
                      selector:@selector(comboBoxWillDismiss:)
                          name:_CPPopUpListWillDismissNotification
                        object:_listDelegate];

    [defaultCenter addObserver:self
                      selector:@selector(listDidDismiss:)
                          name:_CPPopUpListDidDismissNotification
                        object:_listDelegate];

    [defaultCenter addObserver:self
                      selector:@selector(itemWasClicked:)
                          name:_CPPopUpListItemWasClickedNotification
                        object:_listDelegate];

    [[_listDelegate scrollView] setHasVerticalScroller:_hasVerticalScroller];

    var tableView = [_listDelegate tableView];

    [defaultCenter addObserver:self
                      selector:@selector(comboBoxSelectionIsChanging:)
                          name:CPTableViewSelectionIsChangingNotification
                        object:tableView];

    [defaultCenter addObserver:self
                      selector:@selector(comboBoxSelectionDidChange:)
                          name:CPTableViewSelectionDidChangeNotification
                        object:tableView];

    // Apply our text style to the list
    [_listDelegate setFont:[self font]];
    [_listDelegate setAlignment:[self alignment]];
}

- (int)indexOfItemWithObjectValue:(id)anObject
{
    if (_usesDataSource)
        [self _dataSourceWarningForMethod:_cmd condition:YES];

    return [_items indexOfObject:anObject];
}

- (id)itemObjectValueAtIndex:(int)index
{
    if (_usesDataSource)
        [self _dataSourceWarningForMethod:_cmd condition:YES];

    return [_items objectAtIndex:index];
}

- (void)noteNumberOfItemsChanged
{
    [[_listDelegate tableView] noteNumberOfRowsChanged];
}

- (void)scrollItemAtIndexToTop:(int)index
{
    [_listDelegate scrollItemAtIndexToTop:index];
}

- (void)scrollItemAtIndexToVisible:(int)index
{
    [[_listDelegate tableView] scrollRowToVisible:index];
}

- (void)reloadData
{
    [[_listDelegate tableView] reloadData];
}

/*! @ignore */
- (void)popUpList
{
    if (!_listDelegate)
        [self setListDelegate:[[_CPPopUpList alloc] initWithDataSource:self]];

    [self _selectMatchingItem];

    // Note the offset here is 1 less than the focus ring width because the outer edge
    // of the focus ring is very transparent and it looks better if the list is closer.
    if (CPComboBoxFocusRingWidth < 0)
    {
        var inset = [self currentValueForThemeAttribute:@"border-inset"];

        CPComboBoxFocusRingWidth = inset.bottom;
    }

    [_listDelegate popUpRelativeToRect:[self _borderFrame] view:self offset:CPComboBoxFocusRingWidth - 1];
}

/*! @ignore */
- (BOOL)listIsVisible
{
    return _listDelegate ? [_listDelegate isVisible] : NO;
}

/*! @ignore */
- (void)reloadDataSourceForSelector:(SEL)cmd
{
    if (_usesDataSource)
        [self _dataSourceWarningForMethod:cmd condition:YES]
    else
        [self reloadData];
}

/*!
    If the list is non-empty, sets the value of the field from the currently selected value of the list
    and returns YES. If the list is empty or the list has no selected item, returns NO.
    @ignore
*/
- (BOOL)takeStringValueFromList
{
    if (_usesDataSource && _dataSource && [_dataSource numberOfItemsInComboBox:self] === 0)
        return NO;

    var selectedStringValue = [_listDelegate selectedStringValue];

    if (selectedStringValue === nil)
        return NO;
    else
        _selectedStringValue = selectedStringValue;

    [self setStringValue:_selectedStringValue];
    [self _reverseSetBinding];

    return YES;
}

/*!
    The receiver receives this notification when the list is closed.
    @ignore
*/
- (void)listDidDismiss:(CPNotification)aNotification
{
    [[self window] makeFirstResponder:self];
}

/*!
    The receiver receives this notification when an item in the list is clicked.
    @ignore
*/
- (void)itemWasClicked:(CPNotification)aNotification
{
    [self takeStringValueFromList];
    [self sendAction:[self action] to:[self target]];
}

#pragma mark Manipulating the Selection

- (void)deselectItemAtIndex:(int)index
{
    var table = [_listDelegate tableView],
        row = [table selectedRow];

    if (row !== index)
        return;

    [table deselectRow:index];
}

- (int)indexOfSelectedItem
{
    return [[_listDelegate tableView] selectedRow];
}

- (id)objectValueOfSelectedItem
{
    var row = [[_listDelegate tableView] selectedRow];

    if (row >= 0)
    {
        if (_usesDataSource)
            [self _dataSourceWarningForMethod:_cmd condition:YES];

        return _items[row];
    }

    return nil;
}

- (void)selectItemAtIndex:(int)index
{
    var table = [_listDelegate tableView],
        row = [table selectedRow];

    if (row === index)
        return;

    [table selectRowIndexes:[CPIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
}

- (void)selectItemWithObjectValue:(id)anObject
{
    var index = [self indexOfItemWithObjectValue:anObject];

    if (index !== CPNotFound)
        [self selectItemAtIndex:index];
}

#pragma mark Completing the Text Field

- (BOOL)completes
{
    return _completes;
}

- (void)setCompletes:(BOOL)flag
{
    _completes = !!flag;
}

- (CPString)completedString:(CPString)substring
{
    if (_usesDataSource)
        return [self comboBoxCompletedString:substring];
    else
    {
        var index = [_items indexOfObjectPassingTest:CPComboBoxCompletionTest context:substring];

        return index !== CPNotFound ? _items[index] : nil;
    }
}

/*!
    Returns whether the combo box forces the user to enter or select
    an item that is in the item list.
*/
- (BOOL)forceSelection
{
    return _forceSelection;
}

/*!
    Sets whether the combo box forces the user to enter or select
    an item that is in the item list. If \c flag is \c YES and the user enters a value
    that is not in the list, when the field loses focus it will revert
    to the previous value. If \c flag is \c NO, the user can enter any value they wish.

    Note that this flag is ignored if \ref setStringValue or \ref setObjectValue are
    called directly.
*/
- (void)setForceSelection:(BOOL)flag
{
    _forceSelection = !!flag;
}

#pragma mark CPTextField Delegate Methods and Overrides

/*! @ignore */
- (BOOL)sendAction:(SEL)anAction to:(id)anObject
{
    // When the action is sent, be sure to get the value and close the list.
    // This covers the case where the action is triggered by pressing a key
    // that triggers the text field action.

    if ([self listIsVisible])
    {
        [self takeStringValueFromList];
        [_listDelegate close];
    }

    return [super sendAction:anAction to:anObject];
}

/*! @ignore */
- (void)setObjectValue:(id)object
{
    [super setObjectValue:object];

    _selectedStringValue = [self stringValue];
}

/*! @ignore */
- (void)interpretKeyEvents:(CPArray)events
{
    var theEvent = events[0];

    // Only if characters are added at the end of the value can completion occur
    _canComplete = NO;

    if (_completes)
    {
        if (![theEvent _couldBeKeyEquivalent] && [theEvent characters].charAt(0) !== CPDeleteCharacter)
        {
            var value = [self _inputElement].value,
                selectedRange = [self selectedRange];

            _canComplete = CPMaxRange(selectedRange) === value.length;
        }
    }

    [super interpretKeyEvents:events];
}

/*! @ignore */
- (void)paste:(id)sender
{
    if (_completes)
    {
        // Completion can occur only if pasting at the end of the value
        var value = [self _inputElement].value,
            selectedRange = [self selectedRange];

        _canComplete = CPMaxRange(selectedRange) === value.length;
    }
    else
        _canComplete = NO;

    [super paste:sender];
}

/*! @ignore */
- (void)textDidChange:(CPNotification)aNotification
{
    /*
        Completion is attempted iff:
          - _completes is YES
          - Characters were added at the end of the value
    */
    var uncompletedString = [self stringValue],
        newString = uncompletedString;

    if (_completes && _canComplete)
    {
        newString = [self completedString:uncompletedString];

        if (newString && newString.length > uncompletedString.length)
        {
            [self setStringValue:newString];
            [self setSelectedRange:CPMakeRange(uncompletedString.length, newString.length - uncompletedString.length)];
        }
    }

    [self _selectMatchingItem];
    _canComplete = NO;

    [super textDidChange:aNotification];
}

/*!
    Override of CPView -performKeyEquivalent
    @ignore
*/
- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    if ([[self window] firstResponder] === self)
    {
        var key = [anEvent charactersIgnoringModifiers];

        switch (key)
        {
            case CPDownArrowFunctionKey:
                if (![self listIsVisible])
                {
                    [self popUpList];
                    return YES;
                }
                break;

            case CPEscapeFunctionKey:
                if ([self listIsVisible])
                {
                    // If we are forcing a selection and the user has entered a value which is not
                    // in the list, revert to the most recent valid value.
                    if (_forceSelection && ([self _inputElement].value !== _selectedStringValue))
                        [self setStringValue:_selectedStringValue];
                }
                break;
        }

        if ([_listDelegate performKeyEquivalent:anEvent])
            return YES;
    }

    return [super performKeyEquivalent:anEvent];
}

/*! @ignore */
- (BOOL)resignFirstResponder
{
    var buttonCausedResign = _popUpButtonCausedResign;

    _popUpButtonCausedResign = NO;

    /*
        If the list or popup button is clicked, we lose focus. The list will refuse first responder,
        and we refuse to resign. But we still have to manually restore the focus to the input element.
    */
    var shouldResign = !buttonCausedResign && (!_listDelegate || [_listDelegate controllingViewShouldResign]);

    if (!shouldResign)
    {
#if PLATFORM(DOM)
        // In FireFox this needs to be done in setTimeout, otherwise there is no caret
        // We have to save the input element now, when we lose focus it will change.
        var element = [self _inputElement];
        window.setTimeout(function() { element.focus(); }, 0);
#endif

        return NO;
    }

    // The list was not clicked, we need to close it now
    [_listDelegate close];

    // If the field is empty, allow it to remain empty.
    // Otherwise restore the most recently selected value if forcing selection.
    var value = [self stringValue];

    if (value)
    {
        if (_forceSelection && ![value isEqual:_selectedStringValue])
            [self setStringValue:_selectedStringValue];
    }
    else
        _selectedStringValue = @"";

    return [super resignFirstResponder];
}

- (void)setFont:(CPFont)aFont
{
    [super setFont:aFont];
    [_listDelegate setFont:aFont];
}

- (void)setAlignment:(CPTextAlignment)alignment
{
    [super setAlignment:alignment];
    [_listDelegate setAlignment:alignment];
}

#pragma mark Pop Up Button Layout

- (CGRect)popupButtonRectForBounds:(CGRect)bounds
{
    var borderInset = [self currentValueForThemeAttribute:@"border-inset"],
        buttonSize = [self currentValueForThemeAttribute:@"popup-button-size"];

    bounds.origin.x = CGRectGetMaxX(bounds) - borderInset.right - buttonSize.width;
    bounds.origin.y += borderInset.top;

    bounds.size.width = buttonSize.width;
    bounds.size.height = buttonSize.height;

    return bounds;
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "popup-button-view")
        return [self popupButtonRectForBounds:[self bounds]];

    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "popup-button-view")
    {
        var view = [[_CPComboBoxPopUpButton alloc] initWithFrame:CGRectMakeZero() comboBox:self];

        return view;
    }

    return [super createEphemeralSubviewNamed:aName];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    var popupButtonView = [self layoutEphemeralSubviewNamed:@"popup-button-view"
                                                 positioned:CPWindowAbove
                            relativeToEphemeralSubviewNamed:@"content-view"];
}

#pragma mark Internal Helpers

/*! @ignore */
- (void)_dataSourceWarningForMethod:(SEL)cmd condition:(CPString)flag
{
    CPLog.warn("-[%s %s] should not be called when usesDataSource is set to %s", [self className], cmd, flag ? "YES" : "NO");
}

/*!
    Select the item that matches the current value of the combobox.
    @ignore
*/
- (void)_selectMatchingItem
{
    var index = CPNotFound,
        stringValue = [self stringValue];

    if (_usesDataSource)
    {
        if (_dataSource && [_dataSource respondsToSelector:@selector(comboBox:indexOfItemWithStringValue:)])
            index = [_dataSource comboBox:self indexOfItemWithStringValue:stringValue]
    }
    else
        index = [self indexOfItemWithObjectValue:stringValue];

    [_listDelegate selectRow:index];

    // selectRow scrolls the row to visible, if a row is selected scroll it to the top
    if (index !== CPNotFound)
    {
        [_listDelegate scrollItemAtIndexToTop:index];
        _selectedStringValue = stringValue;
    }
}

/*!
    Calculate the frame in base coordinates that will nestle just below the visible border of the text field.
    @ignore
*/
- (CGRect)_borderFrame
{
    var inset = [self currentValueForThemeAttribute:@"border-inset"],
        frame = [self bounds];

    frame.origin.x += inset.left;
    frame.origin.y += inset.top;
    frame.size.width -= inset.left + inset.right;
    frame.size.height -= inset.top + inset.bottom;

    return frame;
}

/* @ignore */
- (void)_popUpButtonWasClicked
{
    if (![self isEnabled])
        return;

    // If we are currently the first responder, we will be asked to resign when the list pops up.
    // Set a flag to let resignResponder know that the button was clicked and we should not resign.
    var firstResponder = [[self window] firstResponder];

    _popUpButtonCausedResign = firstResponder === self;

    if ([self listIsVisible])
        [_listDelegate close];
    else
    {
        if (firstResponder !== self)
            [[self window] makeFirstResponder:self];

        [self popUpList];
    }
}

@end

@implementation CPComboBox (CPComboBoxDelegate)

/*! @ignore */
- (void)comboBoxSelectionIsChanging:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPComboBoxSelectionIsChangingNotification object:self];
}

/*! @ignore */
- (void)comboBoxSelectionDidChange:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPComboBoxSelectionDidChangeNotification object:self];
}

/*! @ignore */
- (void)comboBoxWillPopUp:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPComboBoxWillPopUpNotification object:self];
}

/*! @ignore */
- (void)comboBoxWillDismiss:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPComboBoxWillDismissNotification object:self];
}

@end

@implementation CPComboBox (CPComboBoxDataSource)

/*! @ignore */
- (CPString)comboBoxCompletedString:(CPString)uncompletedString
{
    if ([_dataSource respondsToSelector:@selector(comboBox:completedString:)])
        return [_dataSource comboBox:self completedString:uncompletedString];
    else
        return nil;
}

@end

@implementation CPComboBox (_CPPopUpListDataSource)

- (int)numberOfItemsInList:(_CPPopUpList)aList
{
    return [self numberOfItems];
}

- (int)numberOfVisibleItemsInList:(_CPPopUpList)aList
{
    return [self numberOfVisibleItems];
}

- (id)list:(_CPPopUpList)aList objectValueForItemAtIndex:(int)index
{
    if (_usesDataSource)
        return [_dataSource comboBox:self objectValueForItemAtIndex:index];
    else
        return _items[index];
}

- (id)list:(_CPPopUpList)aList displayValueForObjectValue:(id)aValue
{
    return aValue || @"";
}

- (CPString)list:(_CPPopUpList)aList stringValueForObjectValue:(id)aValue
{
   return String(aValue);
}

@end

@implementation CPComboBox (Bindings)

/*! @ignore */
- (void)setContentValues:(CPArray)anArray
{
    [self setUsesDataSource:NO];
    [self removeAllItems];
    [self addItemsWithObjectValues:anArray];
}

/*! @ignore */
- (void)setContent:(CPArray)anArray
{
    [self setUsesDataSource:NO];

    // Directly nuke _items, [_items removeAll] will trigger an extra call to setContent
    _items = [];

    var values = [];

    [anArray enumerateObjectsUsingBlock:function(object)
    {
        values.push([object description]);
    }];

    [self addItemsWithObjectValues:values];
}

@end

var CPComboBoxItemsKey                  = @"CPComboBoxItemsKey",
    CPComboBoxListKey                   = @"CPComboBoxListKey",
    CPComboBoxDelegateKey               = @"CPComboBoxDelegateKey",
    CPComboBoxDataSourceKey             = @"CPComboBoxDataSourceKey",
    CPComboBoxUsesDataSourceKey         = @"CPComboBoxUsesDataSourceKey",
    CPComboBoxCompletesKey              = @"CPComboBoxCompletesKey",
    CPComboBoxNumberOfVisibleItemsKey   = @"CPComboBoxNumberOfVisibleItemsKey",
    CPComboBoxHasVerticalScrollerKey    = @"CPComboBoxHasVerticalScrollerKey",
    CPComboBoxButtonBorderedKey         = @"CPComboBoxButtonBorderedKey";

@implementation CPComboBox (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self _initComboBox];

        _items = [aCoder decodeObjectForKey:CPComboBoxItemsKey];
        _listDelegate = [aCoder decodeObjectForKey:CPComboBoxListKey];
        _delegate = [aCoder decodeObjectForKey:CPComboBoxDelegateKey];
        _dataSource = [aCoder decodeObjectForKey:CPComboBoxDataSourceKey];
        _usesDataSource = [aCoder decodeBoolForKey:CPComboBoxUsesDataSourceKey];
        _completes = [aCoder decodeBoolForKey:CPComboBoxCompletesKey];
        _numberOfVisibleItems = [aCoder decodeIntForKey:CPComboBoxNumberOfVisibleItemsKey];
        _hasVerticalScroller = [aCoder decodeBoolForKey:CPComboBoxHasVerticalScrollerKey];
        [self setButtonBordered:[aCoder decodeBoolForKey:CPComboBoxButtonBorderedKey]];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_items forKey:CPComboBoxItemsKey];
    [aCoder encodeObject:_listDelegate forKey:CPComboBoxListKey];
    [aCoder encodeObject:_delegate forKey:CPComboBoxDelegateKey];
    [aCoder encodeObject:_dataSource forKey:CPComboBoxDataSourceKey];
    [aCoder encodeBool:_usesDataSource forKey:CPComboBoxUsesDataSourceKey];
    [aCoder encodeBool:_completes forKey:CPComboBoxCompletesKey];
    [aCoder encodeInt:_numberOfVisibleItems forKey:CPComboBoxNumberOfVisibleItemsKey];
    [aCoder encodeBool:_hasVerticalScroller forKey:CPComboBoxHasVerticalScrollerKey];
    [aCoder encodeBool:[self isButtonBordered] forKey:CPComboBoxButtonBorderedKey];
}

@end


var CPComboBoxCompletionTest = function(object, index, context)
{
    return object.toString().indexOf(context) === 0;
};


/*
    This class is only used for CPContentBinding and CPContentValuesBinding.
*/
@implementation _CPComboBoxContentBinder : CPBinder

- (void)setValueFor:(CPString)aBinding
{
    var destination = [_info objectForKey:CPObservedObjectKey],
        keyPath = [_info objectForKey:CPObservedKeyPathKey],
        options = [_info objectForKey:CPOptionsKey],
        newValue = [destination valueForKeyPath:keyPath],
        isPlaceholder = CPIsControllerMarker(newValue);

    [_source removeAllItems];

    if (isPlaceholder)
    {
        // By default the placeholders will all result in an empty list
        switch (newValue)
        {
            case CPMultipleValuesMarker:
                newValue = [options objectForKey:CPMultipleValuesPlaceholderBindingOption] || [];
                break;

            case CPNoSelectionMarker:
                newValue = [options objectForKey:CPNoSelectionPlaceholderBindingOption] || [];
                break;

            case CPNotApplicableMarker:
                if ([options objectForKey:CPRaisesForNotApplicableKeysBindingOption])
                    [CPException raise:CPGenericException
                                reason:@"can't transform non applicable key on: " + _source + " value: " + newValue];

                newValue = [options objectForKey:CPNotApplicablePlaceholderBindingOption] || [];
                break;

            case CPNullMarker:
                newValue = [options objectForKey:CPNullPlaceholderBindingOption] || [];
                break;
        }

        if (![newValue isKindOfClass:[CPArray class]])
            newValue = [];
    }
    else
        newValue = [self transformValue:newValue withOptions:options];

    switch (aBinding)
    {
        case CPContentBinding:
            [_source setContent:newValue];
            break;

        case CPContentValuesBinding:
            [_source setContentValues:newValue];
            break;
    }
}

@end

@implementation _CPComboBoxPopUpButton : CPView
{
    CPComboBox _comboBox;
}

- (id)initWithFrame:(CGRect)aFrame comboBox:(CPComboBox)aComboBox
{
    self = [super initWithFrame:aFrame];

    if (self)
        _comboBox = aComboBox;

    return self;
}

- (void)mouseDown:(CPEvent)theEvent
{
    [_comboBox _popUpButtonWasClicked];
}

- (BOOL)acceptsFirstResponder
{
    return NO;
}

@end
