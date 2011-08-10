/*
 * CPComboBox.j
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

@import <AppKit/CPTextField.j>
@import <AppKit/_CPPopUpList.j>


CPComboBoxSelectionDidChangeNotification  = @"CPComboBoxSelectionDidChangeNotification";
CPComboBoxSelectionIsChangingNotification = @"CPComboBoxSelectionIsChangingNotification";
CPComboBoxWillDismissNotification         = @"CPComboBoxWillDismissNotification";
CPComboBoxWillPopUpNotification           = @"CPComboBoxWillPopUpNotification";

var CPComboBoxTextSubview = @"text",
    CPComboBoxButtonSubview = @"button",
    CPComboBoxDefaultNumberOfVisibleItems = 5;


@implementation CPComboBox : CPTextField
{
    CPArray                     _items;
    _CPPopUpList                _list;
    Class                       _listClass;
    CPComboBoxDataSource        _dataSource;
    BOOL                        _usesDataSource;
    BOOL                        _completes;
    BOOL                        _canComplete;
    int                         _numberOfVisibleItems;
    BOOL                        _forceSelection;
    BOOL                        _hasVerticalScroller;
    CPString                    _selectedStringValue;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
        [self _init];

    return self;
}

- (void)_init
{
    _items = []
    _listClass = [_CPPopUpList class];
    _usesDataSource = NO;
    _completes = NO;
    _canComplete = NO;
    _numberOfVisibleItems = CPComboBoxDefaultNumberOfVisibleItems;
    _forceSelection = NO;
    _hasVerticalScroller = YES;
    _selectedStringValue = @"";

    [self setTarget:self];
    [self setAction:@selector(textFieldAction:)];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidChange:) name:CPControlTextDidChangeNotification object:self];
}

//#pragma mark Setting Display Attributes

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
    [[_list scrollView] setHasVerticalScroller:flag];
}

- (CGSize)intercellSpacing
{
    return [[_list tableView] intercellSpacing];
}

- (void)setIntercellSpacing:(CGSize)aSize
{
    [[_list tableView] setIntercellSpacing:aSize];
}

- (BOOL)isButtonBordered
{
    return YES;
    //return [[self ephemeralSubviewNamed:CPComboBoxButtonSubview] isBordered];
}

- (void)setButtonBordered:(BOOL)flag
{
    //[[self ephemeralSubviewNamed:CPComboBoxButtonSubview] setBordered:flag];
}

- (float)itemHeight
{
    return [[_list tableView] rowHeight];
}

- (void)setItemHeight:(float)itemHeight
{
    [[_list tableView] setRowHeight:itemHeight];
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

//#pragma mark Setting a Delegate

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

//#pragma mark Setting a Data Source

- (id < CPComboBoxDataSource >)dataSource
{
    if (_usesDataSource === NO)
        [self dataSourceWarningForMethod:_cmd condition:NO];

    return _dataSource;
}

- (void)setDataSource:(id < CPComboBoxDataSource >)aSource
{
    if (_usesDataSource === NO)
        [self dataSourceWarningForMethod:_cmd condition:NO];
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

//#pragma mark Working with an Internal List

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
        [self dataSourceWarningForMethod:_cmd condition:YES];

    [_items insertObject:anObject atIndex:anIndex];
    [self reloadData];
}

/*!
    Returns the internal array of items. Note that this does a deep copy of the array,
    effectively returning an immutable array to be consistent with Cocoa.

    If usesDataSource is YES, a warning is logged and an empty array is returned.
*/
- (CPArray)objectValues
{
    if (_usesDataSource)
        [self dataSourceWarningForMethod:_cmd condition:YES];

    return [[CPArray alloc] initWithArray:_items copyItems:YES];
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
        [self dataSourceWarningForMethod:_cmd condition:YES];

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

//#pragma mark Manipulating the Displayed List

/*!
    Returns the helper class to be used when creating the pop up list.
*/
- (Class)listClass
{
    return _listClass;
}

/*!
    Sets the helper class to be used when creating the pop up list.
    By default this is _CPPopUpList. If you are using a subclass
    of _CPPopUpList, call this method with your subclass.
*/
- (void)setListClass:(Class)aClass
{
    _listClass = aClass;
}

- (int)indexOfItemWithObjectValue:(id)anObject
{
    if (_usesDataSource)
        [self dataSourceWarningForMethod:_cmd condition:YES];

    return [_items indexOfObject:anObject];
}

- (id)itemObjectValueAtIndex:(int)index
{
    if (_usesDataSource)
        [self dataSourceWarningForMethod:_cmd condition:YES];

    return [_items objectAtIndex:index];
}

- (void)noteNumberOfItemsChanged
{
    [[_list tableView] noteNumberOfRowsChanged];
}

- (void)scrollItemAtIndexToTop:(int)index
{
    [_list scrollItemAtIndexToTop:index];
}

- (void)scrollItemAtIndexToVisible:(int)index
{
    [[_list tableView] scrollRowToVisible:index];
}

- (void)reloadData
{
    [[_list tableView] reloadData];
}

/*! @ignore */
- (void)popUpList
{
    if (!_list)
        [self makeList];

    [self selectMatchingItem];
    [_list popUpRelativeTo:[self borderFrame]];
}

/*! @ignore */
- (_CPPopUpList)makeList
{
    var defaultCenter = [CPNotificationCenter defaultCenter];

    if (_list)
    {
        [defaultCenter removeObserver:self name:_CPPopUpListWillPopUpNotification object:_list];
        [defaultCenter removeObserver:self name:_CPPopUpListWillDismissNotification object:_list];
        [defaultCenter removeObserver:self name:_CPPopUpListDidDismissNotification object:_list];
        [defaultCenter removeObserver:self name:_CPPopUpListItemWasClickedNotification object:_list];
    }

    _list = [[_listClass alloc] initWithDelegate:self];

    [defaultCenter addObserver:self
                      selector:@selector(listWillPopUp:)
                          name:_CPPopUpListWillPopUpNotification
                        object:_list];

    [defaultCenter addObserver:self
                      selector:@selector(listWillDismiss:)
                          name:_CPPopUpListWillDismissNotification
                        object:_list];

    [defaultCenter addObserver:self
                      selector:@selector(listDidDismiss:)
                          name:_CPPopUpListDidDismissNotification
                        object:_list];

    [defaultCenter addObserver:self
                      selector:@selector(itemWasClicked:)
                          name:_CPPopUpListItemWasClickedNotification
                        object:_list];

    [[_list scrollView] setHasVerticalScroller:_hasVerticalScroller];

    var tableView = [_list tableView];

    [defaultCenter addObserver:self
                      selector:@selector(comboBoxSelectionIsChanging:)
                          name:CPTableViewSelectionIsChangingNotification
                        object:tableView];

    [defaultCenter addObserver:self
                      selector:@selector(comboBoxSelectionDidChange:)
                          name:CPTableViewSelectionDidChangeNotification
                        object:tableView];
}

/*! @ignore */
- (BOOL)listIsVisible
{
    return _list ? [_list isVisible] : NO;
}

/*! @ignore */
- (void)reloadDataSourceForSelector:(SEL)cmd
{
    if (_usesDataSource)
        [self dataSourceWarningForMethod:cmd condition:YES]
    else
        [self reloadData];
}

/*!
    If the list is non-empty, sets the value of the field from the currently selected value of the list
    and returns YES. IF the list is empty, immediately returns NO.
*/
- (BOOL)takeStringValueFromList
{
    if ([_dataSource numberOfItemsInComboBox:self] === 0)
        return NO;

    _selectedStringValue = [_list selectedStringValue] || @"";

    [self setStringValue:_selectedStringValue];
    return YES;
}

/*!
    The field receives this notification when the list is about to be pop up.
*/
- (void)listWillPopUp:(CPNotification)aNotification
{
    [self comboBoxWillPopUp];
}

/*!
    The field receives this notification when the list is about to be dismissed.
*/
- (void)listWillDismiss:(CPNotification)aNotification
{
    [self comboBoxWillDismiss];
}

/*!
    The field receives this notification when the list is closed.
*/
- (void)listDidDismiss:(CPNotification)aNotification
{
    [[self window] makeFirstResponder:self];
}

/*!
    The field receives this notification when an item in the list is clicked.
*/
- (void)itemWasClicked:(CPNotification)aNotification
{
    [self takeStringValueFromList];
}

//#pragma mark Manipulating the Selection

- (void)deselectItemAtIndex:(int)index
{
    var table = [_list tableView],
        row = [table selectedRow];

    if (row !== index)
        return;

    [table deselectRow:index];
}

- (int)indexOfSelectedItem
{
    return [[_list tableView] selectedRow];
}

- (id)objectValueOfSelectedItem
{
    var row = [[_list tableView] selectedRow];

    if (row >= 0)
    {
        if (_usesDataSource)
            [self dataSourceWarningForMethod:_cmd condition:YES];

        return _items[row];
    }

    return nil;
}

- (void)selectItemAtIndex:(int)index
{
    var table = [_list tableView],
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

//#pragma mark Completing the Text Field

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
*/
- (void)setForceSelection:(BOOL)flag
{
    _forceSelection = !!flag;
}

//#pragma mark CPTextField Delegate Methods and Overrides

- (void)keyDown:(CPEvent)anEvent
{
    // Only if characters are added at the end of the value can completion occur
    _canComplete = NO;

    if (_completes)
    {
        if (![anEvent _couldBeKeyEquivalent] && [anEvent characters].charAt(0) !== CPDeleteCharacter)
        {
            var value = [self _inputElement].value,
                selectedRange = [self selectedRange];

            _canComplete = CPMaxRange(selectedRange) === value.length;
        }
    }

    [super keyDown:anEvent];
}

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

- (void)controlTextDidChange:(CPNotification)anNotification
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

    [self selectMatchingItem];
    _canComplete = NO;
}

- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    if ([[self window] firstResponder] === self)
    {
        var key = [anEvent charactersIgnoringModifiers];

        switch (key)
        {
            case CPDownArrowFunctionKey:
                if ([self listIsVisible])
                    [_list selectNextItem];
                else
                    [self popUpList];

                return YES;

            case CPUpArrowFunctionKey:
                if ([self listIsVisible])
                {
                    [_list selectPreviousItem];
                    return YES;
                }
                break;

            case CPEscapeFunctionKey:
                if ([self listIsVisible])
                {
                    if (_forceSelection)
                        [self setStringValue:_selectedStringValue];

                    [_list close];
                    return YES;
                }
                break;

            case CPPageUpFunctionKey:
                if ([self listIsVisible])
                {
                    [_list scrollPageUp];
                    return YES;
                }
                break;

            case CPPageDownFunctionKey:
                if ([self listIsVisible])
                {
                    [_list scrollPageDown];
                    return YES;
                }
                break;

            case CPHomeFunctionKey:
                if ([self listIsVisible])
                {
                    [_list scrollToTop];
                    return YES;
                }
                break;

            case CPEndFunctionKey:
                if ([self listIsVisible])
                {
                    [_list scrollToBottom];
                    return YES;
                }
                break;
        }
    }

    return [super performKeyEquivalent:anEvent];
}

- (BOOL)resignFirstResponder
{
    /*
        If the list is clicked, we lose focus. In that case the list will refuse first responder,
        and we refuse to resign. But we still have to manually restore the focus to the input element.
    */
    if ([_list listWasClicked])
    {
        /*
            If an item was not clicked (probably the scrollbar), clear the click flag so that future
            clicks outside the list will allow it to close. It isn't so great doing that here, but
            the sequence of events is such that it has to be done here.
        */
        if (![_list itemWasClicked])
            [_list setListWasClicked:NO];

//#if PLATFORM(DOM)
        [self _inputElement].focus();
//#endif

        return NO;
    }

    // The list was not clicked, we need to close it now
    [_list close];

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

/*!
    We override this so that we can know when the field is about to lose focus
    because the user pressed tab.
*/
- (CPView)nextValidKeyView
{
    if ([self listIsVisible])
        [self takeStringValueFromList];

    return [super nextValidKeyView];
}

/*!
    We override this so that we can know when the field is about to lose focus
    because the user pressed shift tab.
*/
- (CPView)previousValidKeyView
{
    if ([self listIsVisible])
        [self takeStringValueFromList];

    return [super previousValidKeyView];
}

//#pragma mark Internal Helpers

- (void)dataSourceWarningForMethod:(SEL)cmd condition:(CPString)flag
{
    CPLog.warn("-[%s %s] should not be called when usesDataSource is set to %s", [self className], cmd, flag ? "YES" : "NO");
}

- (id)objectValueForItemAtIndex:(int)index
{
    return [_dataSource comboBox:self objectValueForItemAtIndex:index];
}

/*!
    Select the item that matches the current value of the combobox.
*/
- (void)selectMatchingItem
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

    [_list selectRow:index];

    // selectRow scrolls the row to visible, if a row is selected scroll it to the top
    if (index !== CPNotFound)
    {
        [_list scrollRowToTop:index];
        _selectedStringValue = stringValue;
    }
}

- (BOOL)textFieldAction:(id)sender
{
    if ([self listIsVisible])
    {
        [self takeStringValueFromList];
        [_list close];
    }

    return YES;
}

/*!
    @ignore

    Calculate the frame in base coordinates that will nestle just below the visible border of the text field.
*/
- (CGRect)borderFrame
{
    // Calculate the focus inset by subtracting the focused bezel inset
    // from the unfocused bezel inset
    var unfocusedInset = [self valueForThemeAttribute:@"bezel-inset" inState:CPThemeStateBezeled],
        focusedInset = [self valueForThemeAttribute:@"bezel-inset" inState:CPThemeStateBezeled | CPThemeStateEditing],
        focusInset = CGInsetDifference(unfocusedInset, focusedInset),
        bounds = [self convertRectToBase:[self bounds]];

    bounds.origin.x += focusInset.left;
    bounds.origin.y += focusInset.top;
    bounds.size.width -= focusInset.left + focusInset.right;
    bounds.size.height -= focusInset.top + focusInset.bottom;

    return bounds;
}

@end

@implementation CPComboBox (CPComboBoxDelegate)

- (void)comboBoxSelectionIsChanging:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPComboBoxSelectionIsChangingNotification object:self];
}

- (void)comboBoxSelectionDidChange:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPComboBoxSelectionDidChangeNotification object:self];
}

- (void)comboBoxWillPopUp
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPComboBoxWillPopUpNotification object:self];
}

- (void)comboBoxWillDismiss
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPComboBoxWillDismissNotification object:self];
}

@end

@implementation CPComboBox (CPComboBoxDataSource)

- (CPString)comboBoxCompletedString:(CPString)uncompletedString
{
    if ([_dataSource respondsToSelector:@selector(comboBox:completedString:)])
        return [_dataSource comboBox:self completedString:uncompletedString];
    else
        return nil;
}

@end

var CPComboBoxItemsKey                  = @"CPComboBoxItemsKey",
    CPComboBoxListKey                   = @"CPComboBoxListKey",
    CPComboBoxDelegateKey               = @"CPComboBoxDelegateKey",
    CPComboBoxDataSourceKey             = @"CPComboBoxDataSourceKey",
    CPComboBoxUsesDataSourceKey         = @"CPComboBoxUsesDataSourceKey",
    CPComboBoxCompletesKey              = @"CPComboBoxCompletesKey",
    CPComboBoxNumberOfVisibleItemsKey   = @"CPComboBoxNumberOfVisibleItemsKey",
    CPComboBoxHasVerticalScrollerKey    = @"CPComboBoxHasVerticalScrollerKey";

@implementation CPComboBox (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self _init];

        _items = [aCoder decodeObjectForKey:CPComboBoxItemsKey];
        _list = [aCoder decodeObjectForKey:CPComboBoxListKey];
        _delegate = [aCoder decodeObjectForKey:CPComboBoxDelegateKey];
        _dataSource = [aCoder decodeObjectForKey:CPComboBoxDataSourceKey];
        _usesDataSource = [aCoder decodeBoolForKey:CPComboBoxUsesDataSourceKey];
        _completes = [aCoder decodeBoolForKey:CPComboBoxCompletesKey];
        _numberOfVisibleItems = [aCoder decodeIntForKey:CPComboBoxNumberOfVisibleItemsKey];
        _hasVerticalScroller = [aCoder decodeBoolForKey:CPComboBoxHasVerticalScrollerKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_items forKey:CPComboBoxItemsKey];
    [aCoder encodeObject:_list forKey:CPComboBoxListKey];
    [aCoder encodeObject:_delegate forKey:CPComboBoxDelegateKey];
    [aCoder encodeObject:_dataSource forKey:CPComboBoxDataSourceKey];
    [aCoder encodeBool:_usesDataSource forKey:CPComboBoxUsesDataSourceKey];
    [aCoder encodeBool:_completes forKey:CPComboBoxCompletesKey];
    [aCoder encodeInt:_numberOfVisibleItems forKey:CPComboBoxNumberOfVisibleItemsKey];
    [aCoder encodeBool:_hasVerticalScroller forKey:CPComboBoxHasVerticalScrollerKey];
}

@end


var CPComboBoxCompletionTest = function(object, index, context)
{
    return object.toString().indexOf(context) === 0;
};
