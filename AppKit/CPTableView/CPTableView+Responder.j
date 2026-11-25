/*
 * CPTableView+Responder.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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

@import "CPTableViewCore.j"


@class CPButton
@class CPClipView
@class CPUserDefaults
@class CPTableHeaderView
@class CPTableView
@class _CPTableColumnHeaderView
@class CPClipView
@class CPButton
@class _CPDropOperationDrawingView


@implementation CPTableView (Responder)


/*!
    @ignore
*/
- (void)becomeKeyWindow
{
    [self _notifyViewDidBecomeFirstResponder];
    [self setNeedsDisplay:YES];
}

/*!
    @ignore
*/
- (void)resignKeyWindow
{
    [self _notifyViewDidResignFirstResponder];
    [self setNeedsDisplay:YES];
}

/*!
    @ignore
*/
- (BOOL)acceptsFirstResponder
{
    return YES;
}

/*!
    @ignore
*/
- (BOOL)needsPanelToBecomeKey
{
    return YES;
}

/*!
    @ignore
*/
- (CPView)hitTest:(CGPoint)aPoint
{
    var hit = [super hitTest:aPoint];

    if ([[CPApp currentEvent] type] !== CPLeftMouseDown)
        return hit;

    return [self _hitTest:hit];
}

- (id)_hitTest:(CPView)aView
{
    var column,
        row;

    if ([aView acceptsFirstResponder])
    {
        [self getColumn:@ref(column) row:@ref(row) forView:aView];

        if (![self isRowSelected:row])
        {
            if (_selectionHighlightStyle == CPTableViewSelectionHighlightStyleNone)
                return aView;

            return self;
        }
    }
    else if (!_isViewBased && [aView isKindOfClass:[CPControl class]] && ![aView isKindOfClass:[CPTextField class]])
    {
        /*
            2026-11-25: a click on a checkbox in a column that is not editable changed the value.
            This branch sent every mouse-down on a control cell, such as a checkbox, to the
            control and committed its new value, and it did not check the column. As in AppKit,
            a control cell in a column that is not editable now does not take the click; the
            table view takes it and selects the row.
        */
        [self getColumn:@ref(column) row:@ref(row) forView:aView];

        if (column === -1 || ![_tableColumns[column] isEditable])
            return self;

        [aView addObserver:self forKeyPath:@"objectValue" options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew context:"editing"];
    }

    return aView;
}

- (void)_removeObservers
{
    if (!_isObserving)
        return;

    [self _stopObservingClipView];
    [super _removeObservers];
}

- (void)_addObservers
{
    if (_isObserving)
        return;

    [self _startObservingClipView];
    [super _addObservers];
}

/*!
    Called when the receiver is about to be moved to a new window.
    @param aWindow the window to which the receiver will be moved.
*/
- (void)viewWillMoveToWindow:(CPWindow)aWindow
{
    [super viewWillMoveToWindow:aWindow];

    [self _stopObservingFirstResponderForWindow:[self window]];

    if (aWindow)
        [self _startObservingFirstResponderForWindow:aWindow];
}

- (void)_startObservingClipView
{
    if (!_observedClipView)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter];

    [_observedClipView setPostsFrameChangedNotifications:YES];
    [_observedClipView setPostsBoundsChangedNotifications:YES];

    [defaultCenter addObserver:self
                          selector:@selector(superviewFrameChanged:)
                              name:CPViewFrameDidChangeNotification
                            object:_observedClipView];

    [defaultCenter addObserver:self
                      selector:@selector(superviewBoundsChanged:)
                          name:CPViewBoundsDidChangeNotification
                        object:_observedClipView];
}

- (void)_stopObservingClipView
{
    if (!_observedClipView)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter];

    [defaultCenter removeObserver:self
                             name:CPViewFrameDidChangeNotification
                           object:_observedClipView];

    [defaultCenter removeObserver:self
                          name:CPViewBoundsDidChangeNotification
                        object:_observedClipView];
}

- (void)_startObservingFirstResponderForWindow:(CPWindow)aWindow
{
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_firstResponderDidChange:) name:_CPWindowDidChangeFirstResponderNotification object:aWindow];
}

- (void)_stopObservingFirstResponderForWindow:(CPWindow)aWindow
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:_CPWindowDidChangeFirstResponderNotification object:aWindow];
}

- (void)_firstResponderDidChange:(CPNotification)aNotification
{
    var responder = [[self window] firstResponder],
        column,
        row;

    [self getColumn:@ref(column) row:@ref(row) forView:responder];

    _editingRow = row;
    _editingColumn = column;

    // We want to keep the 'First Responder' theme state for the table view as a whole, even when a subview is being edited.
    // This makes sure the theming effects of a focused table remain in effect even as cells are being edited in it.
    // Check if the firstResponder is outside the tableview:
    if (responder !== self && _editingRow == CPNotFound && _editingColumn == CPNotFound)
        [self _notifyViewDidResignFirstResponder];
    else
        [self _notifyViewDidBecomeFirstResponder];

    // The start and the end of editing change the focus of the table view.
    [self setNeedsDisplay:YES];

    // This is for cell-based tables only. In view-based mode, we do not change the textfield apprearence during an edit.
    if (!_isViewBased && _editingRow !== CPNotFound && [responder isKindOfClass:[CPTextField class]] && [responder isEditable] && [responder superview] == self)
    {
        [responder setBezeled:YES];
        [self _registerForEndEditingNote:responder];
    }
}

- (void)_registerForEndEditingNote:(CPView)aTextField
{
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_textFieldEditingDidEnd:) name:CPControlTextDidEndEditingNotification object:aTextField];
}

- (void)_unregisterForEndEditingNote:(CPView)aTextField
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:CPControlTextDidEndEditingNotification object:aTextField];
}

- (void)_textFieldEditingDidEnd:(CPNotification)aNote
{
    // FIXME: When you edit a text field and hit enter without any text modification, the CPControlTextDidEndEditingNotification
    // is NOT sent. This is a bug in CPTextField or CPControl according to cocoa.
    var textField = [aNote object];

    [self _unregisterForEndEditingNote:textField];

    if (!_isViewBased)
    {
        [self _setEditingState:NO forView:textField];
        [self _commitDataViewObjectValue:textField forColumn:_editingColumn andRow:_editingRow];
    }
    else
        [textField setBezeled:NO];

    [self _resignFirstResponderWithoutSendingAction:textField];
}

/*
    The row views and the column selection follow the focus through the signal of
    -setNeedsDisplay:, which a change of key window, first responder or editing sends. These
    methods update the data views.
*/
- (void)_notifyViewDidBecomeFirstResponder
{
    [self _updateDataViewsFocusState];
}

- (void)_notifyViewDidResignFirstResponder
{
    [self _updateDataViewsFocusState];
}

@end
