/*
 * CPBrowser.j
 * AppKit
 *
 * Created by Ross Boucher.
 * Copyright 2010, 280 North, Inc.
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

@import <Foundation/CPObject.j>
@import <Foundation/CPIndexSet.j>

@import "CPControl.j"
@import "CPImage.j"
@import "CPScrollView.j"
@import "CPTableView.j"
@import "CPTextField.j"

@global CPApp

@protocol CPBrowserDelegate <CPObject>

@optional
- (BOOL)browser:(CPBrowser)browser acceptDrop:(id)info atRow:(CPInteger)row column:(CPInteger)column dropOperation:(CPTableViewDropOperation)dropOperation;
- (BOOL)browser:(CPBrowser)browser canDragRowsWithIndexes:(CPIndexSet)rowIndexes inColumn:(CPInteger)column withEvent:(CPEvent )event;
- (BOOL)browser:(CPBrowser)browser isLeafItem:(id)item;
- (BOOL)browser:(CPBrowser)browser shouldSelectRowIndexes:(CPIndexSet)anIndexSet inColumn:(CPInteger)column;
- (BOOL)browser:(CPBrowser)browser writeRowsWithIndexes:(CPIndexSet)rowIndexes inColumn:(CPInteger)column toPasteboard:(CPPasteboard)pasteboard;
- (CPDragOperation)browser:(CPBrowser)browser validateDrop:(id)info proposedRow:(CPInteger)row column:(CPInteger)column dropOperation:(CPTableViewDropOperation)dropOperation;
- (CPImage)browser:(CPBrowser)browser imageValueForItem:(id)anItem;
- (CPImage)browser:(CPBrowser)browser draggingImageForRowsWithIndexes:(CPIndexSet)rowIndexes inColumn:(CPInteger)column withEvent:(CPEvent)event offset:(CGPoint)dragImageOffset;
- (CPImage)browser:(CPBrowser)browser imageValueForItem:(id)item;
- (CPIndexSet)browser:(CPBrowser)browser selectionIndexesForProposedSelection:(CPIndexSet)proposedSelectionIndexes inColumn:(CPInteger)column;
- (CPInteger)browser:(CPBrowser)browser numberOfChildrenOfItem:(id)item;
- (CPView)browser:(CPBrowser)browser draggingViewForRowsWithIndexes:(CPIndexSet)rowIndexes inColumn:(CPInteger)column withEvent:(CPEvent)event offset:(CGPoint)dragImageOffset;
- (id)browser:(CPBrowser)browser child:(CPInteger)index ofItem:(id)item;
- (id)browser:(CPBrowser)browser objectValueForItem:(id)item;
- (id)rootItemForBrowser:(CPBrowser)browser;
- (void)browser:(CPBrowser)browser didChangeLastColumn:(CPInteger)oldLastColumn toColumn:(CPInteger)column;
- (void)browser:(CPBrowser)browser didResizeColumn:(CPInteger)column;
- (void)browserSelectionIsChanging:(CPBrowser)browser;
- (void)browserSelectionDidChange:(CPBrowser)browser;

@end

var CPBrowserDelegate_browser_acceptDrop_atRow_column_dropOperation_                        = 1 << 1,
    CPBrowserDelegate_browser_canDragRowsWithIndexes_inColumn_withEvent_                    = 1 << 2,
    CPBrowserDelegate_browser_isLeafItem_                                                   = 1 << 3,
    CPBrowserDelegate_browser_shouldSelectRowIndexes_inColumn_                              = 1 << 4,
    CPBrowserDelegate_browser_writeRowsWithIndexes_inColumn_toPasteboard_                   = 1 << 5,
    CPBrowserDelegate_browser_validateDrop_proposedRow_column_dropOperation_                = 1 << 6,
    CPBrowserDelegate_browser_imageValueForItem_                                            = 1 << 7,
    CPBrowserDelegate_browser_draggingImageForRowsWithIndexes_inColumn_withEvent_offset_    = 1 << 8,
    CPBrowserDelegate_browser_imageValueForItem_                                            = 1 << 9,
    CPBrowserDelegate_browser_selectionIndexesForProposedSelection_inColumn_                = 1 << 10,
    CPBrowserDelegate_browser_numberOfChildrenOfItem_                                       = 1 << 11,
    CPBrowserDelegate_browser_draggingViewForRowsWithIndexes_inColumn_withEvent_offset_     = 1 << 12,
    CPBrowserDelegate_browser_child_ofItem_                                                 = 1 << 13,
    CPBrowserDelegate_browser_objectValueForItem_                                           = 1 << 14,
    CPBrowserDelegate_rootItemForBrowser_                                                   = 1 << 15,
    CPBrowserDelegate_browser_didChangeLastColumn_toColumn_                                 = 1 << 16,
    CPBrowserDelegate_browser_didResizeColumn_                                              = 1 << 17,
    CPBrowserDelegate_browserSelectionIsChanging_                                           = 1 << 18,
    CPBrowserDelegate_browserSelectionDidChange_                                            = 1 << 19;

/*!
    @ingroup appkit
    @class CPBrowser
*/
@implementation CPBrowser : CPControl
{
    id <CPBrowserDelegate>  _delegate;
    CPString                _pathSeparator;
    unsigned                _implementedDelegateMethods;

    CPView                  _contentView;
    CPScrollView            _horizontalScrollView;
    CPView                  _prototypeView;

    CPArray                 _tableViews;
    CPArray                 _tableDelegates;

    id                      _rootItem;

    BOOL                    _delegateSupportsImages;

    SEL                     _doubleAction @accessors(property=doubleAction);

    BOOL                    _allowsMultipleSelection;
    BOOL                    _allowsEmptySelection;

    Class                   _tableViewClass @accessors(property=tableViewClass);

    float                   _rowHeight;
    float                   _imageWidth;
    float                   _leafWidth;
    float                   _minColumnWidth;
    float                   _defaultColumnWidth @accessors(property=defaultColumnWidth);

    CPArray                 _columnWidths;
}

+ (CPString)defaultThemeClass
{
    return "browser";
}

+ (CPDictionary)themeAttributes
{
    return @{
        @"image-control-resize": [CPNull null],
        @"image-control-leaf": [CPNull null],
        @"image-control-leaf-pressed": [CPNull null]
    };
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self _init];
    }

    return self;
}

- (void)_init
{
    _rowHeight = 23.0;
    _defaultColumnWidth = 140.0;
    _minColumnWidth = 80.0;
    _imageWidth = 23.0;
    _leafWidth = 13.0;
    _columnWidths = [];

    _pathSeparator = "/";
    _tableViews = [];
    _tableDelegates = [];
    _allowsMultipleSelection = YES;
    _allowsEmptySelection = YES;
    _tableViewClass = [_CPBrowserTableView class];

    _prototypeView = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    [_prototypeView setVerticalAlignment:CPCenterVerticalTextAlignment];
    [_prototypeView setValue:[CPColor whiteColor] forThemeAttribute:"text-color" inState:CPThemeStateSelectedDataView];
    [_prototypeView setLineBreakMode:CPLineBreakByTruncatingTail];

    _horizontalScrollView = [[CPScrollView alloc] initWithFrame:[self bounds]];

    [_horizontalScrollView setHasVerticalScroller:NO];
    [_horizontalScrollView setAutohidesScrollers:YES];
    [_horizontalScrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    _contentView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 0, CGRectGetHeight([self bounds]))];
    [_contentView setAutoresizingMask:CPViewHeightSizable];

    [_horizontalScrollView setDocumentView:_contentView];

    [self addSubview:_horizontalScrollView];
}

- (void)setPrototypeView:(CPView)aPrototypeView
{
    _prototypeView = [CPKeyedUnarchiver unarchiveObjectWithData:
                        [CPKeyedArchiver archivedDataWithRootObject:aPrototypeView]];
}

- (CPView)prototypeView
{
    return [CPKeyedUnarchiver unarchiveObjectWithData:
            [CPKeyedArchiver archivedDataWithRootObject:_prototypeView]];
}

- (void)setDelegate:(id <CPBrowserDelegate>)anObject
{
    if (_delegate === anObject)
        return;

    _delegate = anObject;
    _implementedDelegateMethods = 0;
    _delegateSupportsImages = NO;

    if ([_delegate respondsToSelector:@selector(browser:acceptDrop:atRow:column:dropOperation:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browser_acceptDrop_atRow_column_dropOperation_;

    if ([_delegate respondsToSelector:@selector(browser:canDragRowsWithIndexes:inColumn:withEvent:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browser_canDragRowsWithIndexes_inColumn_withEvent_;

    if ([_delegate respondsToSelector:@selector(browser:isLeafItem:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browser_isLeafItem_;

    if ([_delegate respondsToSelector:@selector(browser:shouldSelectRowIndexes:inColumn:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browser_shouldSelectRowIndexes_inColumn_;

    if ([_delegate respondsToSelector:@selector(browser:writeRowsWithIndexes:inColumn:toPasteboard:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browser_writeRowsWithIndexes_inColumn_toPasteboard_;

    if ([_delegate respondsToSelector:@selector(browser:validateDrop:proposedRow:column:dropOperation:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browser_validateDrop_proposedRow_column_dropOperation_;

    if ([_delegate respondsToSelector:@selector(browser:imageValueForItem:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browser_imageValueForItem_;

    if ([_delegate respondsToSelector:@selector(browser:draggingImageForRowsWithIndexes:inColumn:withEvent:offset:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browser_draggingImageForRowsWithIndexes_inColumn_withEvent_offset_;

    if ([_delegate respondsToSelector:@selector(browser:imageValueForItem:)])
    {
        _delegateSupportsImages = YES;
        _implementedDelegateMethods |= CPBrowserDelegate_browser_imageValueForItem_;
    }

    if ([_delegate respondsToSelector:@selector(browser:selectionIndexesForProposedSelection:inColumn:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browser_selectionIndexesForProposedSelection_inColumn_;

    if ([_delegate respondsToSelector:@selector(browser:numberOfChildrenOfItem:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browser_numberOfChildrenOfItem_;

    if ([_delegate respondsToSelector:@selector(browser:draggingViewForRowsWithIndexes:inColumn:withEvent:offset:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browser_draggingViewForRowsWithIndexes_inColumn_withEvent_offset_;

    if ([_delegate respondsToSelector:@selector(browser:child:ofItem:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browser_child_ofItem_;

    if ([_delegate respondsToSelector:@selector(browser:objectValueForItem:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browser_objectValueForItem_;

    if ([_delegate respondsToSelector:@selector(rootItemForBrowser:)])
        _implementedDelegateMethods |= CPBrowserDelegate_rootItemForBrowser_;

    if ([_delegate respondsToSelector:@selector(browser:didChangeLastColumn:toColumn:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browser_didChangeLastColumn_toColumn_;

    if ([_delegate respondsToSelector:@selector(browser:didChangeLastColumn:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browser_didResizeColumn_;

    if ([_delegate respondsToSelector:@selector(browserSelectionIsChanging:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browserSelectionIsChanging_;

    if ([_delegate respondsToSelector:@selector(browserSelectionDidChange:)])
        _implementedDelegateMethods |= CPBrowserDelegate_browserSelectionDidChange_;

    [self loadColumnZero];
}

- (id)delegate
{
    return _delegate;
}

- (CPTableView)tableViewInColumn:(unsigned)index
{
    return _tableViews[index];
}

- (unsigned)columnOfTableView:(CPTableView)aTableView
{
    return [_tableViews indexOfObject:aTableView];
}

- (void)loadColumnZero
{
    _rootItem = [self _sendDelegateRootItemForBrowser];

    [self setLastColumn:-1];
    [self addColumn];
}

- (void)setLastColumn:(CPInteger)columnIndex
{
    if (columnIndex >= _tableViews.length)
        return;

    var oldValue = _tableViews.length - 1,
        indexPlusOne = columnIndex + 1; // unloads all later columns.

    if (columnIndex > 0)
        [_tableViews[columnIndex - 1] setNeedsDisplay:YES];

    [_tableViews[columnIndex] setNeedsDisplay:YES];

    [[_tableViews.slice(indexPlusOne) valueForKey:"enclosingScrollView"]
      makeObjectsPerformSelector:@selector(removeFromSuperview)];

    _tableViews = _tableViews.slice(0, indexPlusOne);
    _tableDelegates = _tableDelegates.slice(0, indexPlusOne);

    [self _sendDelegateBrowserDidChangeLastColumn:oldValue toColumn:columnIndex];

    [self tile];
}

- (int)lastColumn
{
    return _tableViews.length - 1;
}

- (void)addColumn
{
    var lastIndex = [self lastColumn],
        lastColumn = _tableViews[lastIndex],
        selectionIndexes = [lastColumn selectedRowIndexes];

    if (lastIndex >= 0 && [selectionIndexes count] > 1)
        [CPException raise:CPInvalidArgumentException
                    reason:"Can't add column, column "+lastIndex+" has invalid selection."];

    var index = lastIndex + 1,
        item = index === 0 ? _rootItem : [_tableDelegates[lastIndex] childAtIndex:[selectionIndexes firstIndex]];

    if (index > 0 && item && [self isLeafItem:item])
        return;

    var table = [[_tableViewClass alloc] initWithFrame:CGRectMakeZero() browser:self];

    [table setHeaderView:nil];
    [table setCornerView:nil];
    [table setAllowsMultipleSelection:_allowsMultipleSelection];
    [table setAllowsEmptySelection:_allowsEmptySelection];
    [table registerForDraggedTypes:[self registeredDraggedTypes]];

    [self _addTableColumnsToTableView:table forColumnIndex:index];

    var delegate = [[_CPBrowserTableDelegate alloc] init];

    [delegate _setDelegate:_delegate];
    [delegate _setBrowser:self];
    [delegate _setIndex:index];
    [delegate _setItem:item];

    _tableViews[index] = table;
    _tableDelegates[index] = delegate;

    [table setDelegate:delegate];
    [table setDataSource:delegate];
    [table setTarget:delegate];
    [table setAction:@selector(_tableViewClicked:)];
    [table setDoubleAction:@selector(_tableViewDoubleClicked:)];
    [table setDraggingDestinationFeedbackStyle:CPTableViewDraggingDestinationFeedbackStyleRegular];

    var scrollView = [[_CPBrowserScrollView alloc] initWithFrame:CGRectMakeZero()];
    [scrollView _setBrowser:self];
    [scrollView setDocumentView:table];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutoresizingMask:CPViewHeightSizable];

    [_contentView addSubview:scrollView];

    [self tile];

    [self scrollColumnToVisible:index];
}

- (void)_addTableColumnsToTableView:(CPTableView)aTableView forColumnIndex:(unsigned)index
{
    if (_delegateSupportsImages)
    {
        var column = [[CPTableColumn alloc] initWithIdentifier:@"Image"],
            view = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];

        [view setImageScaling:CPImageScaleProportionallyDown];

        [column setDataView:view];
        [column setResizingMask:CPTableColumnNoResizing];

        [aTableView addTableColumn:column];
    }

    var column = [[CPTableColumn alloc] initWithIdentifier:@"Content"];

    [column setDataView:_prototypeView];
    [column setResizingMask:CPTableColumnNoResizing];

    [aTableView addTableColumn:column];

    var column = [[CPTableColumn alloc] initWithIdentifier:@"Leaf"],
        view = [[_CPBrowserLeafView alloc] initWithFrame:CGRectMakeZero()];

    [view setBranchImage:[self valueForThemeAttribute:@"image-control-leaf"]];
    [view setHighlightedBranchImage:[self valueForThemeAttribute:@"image-control-leaf-pressed"]];

    [column setDataView:view];
    [column setResizingMask:CPTableColumnNoResizing];

    [aTableView addTableColumn:column];
}

- (void)reloadColumn:(CPInteger)column
{
    [[self tableViewInColumn:column] reloadData];
}

- (void)tile
{
    var xOrigin = 0,
        scrollerWidth = [CPScroller scrollerWidth],
        height = CGRectGetHeight([_contentView bounds]);

    for (var i = 0, count = _tableViews.length; i < count; i++)
    {
        var tableView = _tableViews[i],
            scrollView = [tableView enclosingScrollView],
            width = [self widthOfColumn:i],
            tableHeight = CGRectGetHeight([tableView bounds]);

        [[tableView tableColumnWithIdentifier:"Image"] setWidth:_imageWidth];
        [[tableView tableColumnWithIdentifier:"Content"] setWidth:[self columnContentWidthForColumnWidth:width]];
        [[tableView tableColumnWithIdentifier:"Leaf"] setWidth:_leafWidth];

        [tableView setRowHeight:_rowHeight];
        [tableView setFrameSize:CGSizeMake(width - scrollerWidth, tableHeight)];
        [scrollView setFrameOrigin:CGPointMake(xOrigin, 0)];
        [scrollView setFrameSize:CGSizeMake(width, height)];

        xOrigin += width;
    }

    [_contentView setFrameSize:CGSizeMake(xOrigin, height)];
}

- (unsigned)rowAtPoint:(CGPoint)aPoint
{
    var column = [self columnAtPoint:aPoint];
    if (column === -1)
        return -1;

    var tableView = _tableViews[column];
    return [tableView rowAtPoint:[tableView convertPoint:aPoint fromView:self]];
}

- (unsigned)columnAtPoint:(CGPoint)aPoint
{
    var adjustedPoint = [_contentView convertPoint:aPoint fromView:self];

    for (var i = 0, count = _tableViews.length; i < count; i++)
    {
        var frame = [[_tableViews[i] enclosingScrollView] frame];
        if (CGRectContainsPoint(frame, adjustedPoint))
            return i;
    }

    return -1;
}

- (CGRect)rectOfRow:(unsigned)aRow inColumn:(unsigned)aColumn
{
    var tableView = _tableViews[aColumn],
        rect = [tableView rectOfRow:aRow];

    rect.origin = [self convertPoint:rect.origin fromView:tableView];
    return rect;
}

// ITEMS

- (id)itemAtRow:(CPInteger)row inColumn:(CPInteger)column
{
    return [_tableDelegates[column] childAtIndex:row];
}

- (BOOL)isLeafItem:(id)item
{
    return (_implementedDelegateMethods & CPBrowserDelegate_browser_isLeafItem_) && [_delegate browser:self isLeafItem:item];
}

- (id)parentForItemsInColumn:(CPInteger)column
{
    return [_tableDelegates[column] _item];
}

- (CPSet)selectedItems
{
    var selectedColumn = [self selectedColumn],
        selectedIndexes = [self selectedRowIndexesInColumn:selectedColumn],
        set = [CPSet set],
        index = [selectedIndexes firstIndex];

    while (index !== CPNotFound)
    {
        [set addObject:[self itemAtRow:index inColumn:selectedColumn]];
        index = [selectedIndexes indexGreaterThanIndex:index];
    }

    return set;
}

- (id)selectedItem
{
    var selectedColumn = [self selectedColumn],
        selectedRow = [self selectedRowInColumn:selectedColumn];

    return [self itemAtRow:selectedRow inColumn:selectedColumn];
}

// CLICK EVENTS

- (void)trackMouse:(CPEvent)anEvent
{
}

- (void)_column:(unsigned)columnIndex clickedRow:(unsigned)rowIndex
{
    [self setLastColumn:columnIndex];

    if (rowIndex >= 0)
        [self addColumn];

    [self doClick:self];
}

- (void)sendAction
{
    [self sendAction:_action to:_target];
}

- (void)doClick:(id)sender
{
    [self sendAction:_action to:_target];
}

- (void)doDoubleClick:(id)sender
{
    [self sendAction:_doubleAction to:_target];
}

- (void)keyDown:(CPEvent)anEvent
{
    var key = [anEvent charactersIgnoringModifiers],
        column = [self selectedColumn];

    if (column === CPNotFound)
        return;

    if (key === CPLeftArrowFunctionKey || key === CPRightArrowFunctionKey)
    {
        if (key === CPLeftArrowFunctionKey)
        {
            var previousColumn = column - 1,
                selectedRow = [self selectedRowInColumn:previousColumn];

            [self selectRow:selectedRow inColumn:previousColumn];
        }
        else
            [self selectRow:0 inColumn:column + 1];
    }
    else
        [_tableViews[column] keyDown:anEvent];
}

// SIZING

- (float)columnContentWidthForColumnWidth:(float)aWidth
{
    var columnSpacing = [_tableViews[0] intercellSpacing].width;
    return aWidth - (_leafWidth + columnSpacing + (_delegateSupportsImages ? _imageWidth + columnSpacing : 0)) - columnSpacing - [CPScroller scrollerWidth];
}

- (float)columnWidthForColumnContentWidth:(float)aWidth
{
    var columnSpacing = [_tableViews[0] intercellSpacing].width;
    return aWidth + (_leafWidth + columnSpacing + (_delegateSupportsImages ? _imageWidth + columnSpacing: 0)) + columnSpacing + [CPScroller scrollerWidth];
}

- (void)setImageWidth:(float)aWidth
{
    _imageWidth = aWidth;
    [self tile];
}

- (float)imageWidth
{
    return _imageWidth;
}

- (void)setMinColumnWidth:(float)minWidth
{
    _minColumnWidth = minWidth;
    [self tile];
}

- (float)minColumnWidth
{
    return _minColumnWidth;
}

- (void)setWidth:(float)aWidth ofColumn:(unsigned)column
{
    _columnWidths[column] = aWidth;

    [self _sendDelegateBrowserDidResizeColumn:column];
    [self tile];
}

- (float)widthOfColumn:(unsigned)column
{
    var width = _columnWidths[column];

    if (width == null)
        width = _defaultColumnWidth;

    return MAX([CPScroller scrollerWidth], MAX(_minColumnWidth, width));
}

- (void)setRowHeight:(float)aHeight
{
    _rowHeight = aHeight;
}

- (float)rowHeight
{
    return _rowHeight;
}

// SCROLLERS

- (void)scrollColumnToVisible:(unsigned)columnIndex
{
    [_contentView scrollRectToVisible:[[[self tableViewInColumn:columnIndex] enclosingScrollView] frame]];
}

- (void)scrollRowToVisible:(unsigned)rowIndex inColumn:(unsigned)columnIndex
{
    [self scrollColumnToVisible:columnIndex];
    [[self tableViewInColumn:columnIndex] scrollRowToVisible:rowIndex];
}

- (BOOL)autohidesScroller
{
    return [_horizontalScrollView autohidesScrollers];
}

- (void)setAutohidesScroller:(BOOL)shouldHide
{
    [_horizontalScrollView setAutohidesScrollers:shouldHide];
}

// SELECTION

- (unsigned)selectedRowInColumn:(unsigned)columnIndex
{
    if (columnIndex > [self lastColumn] || columnIndex < 0)
        return -1;

    return [_tableViews[columnIndex] selectedRow];
}

- (unsigned)selectedColumn
{
    var column = [self lastColumn],
        row = [self selectedRowInColumn:column];

    if (row >= 0)
        return column;
    else
        return column - 1;
}

- (void)selectRow:(unsigned)row inColumn:(unsigned)column
{
    var selectedIndexes = row === -1 ? [CPIndexSet indexSet] : [CPIndexSet indexSetWithIndex:row];
    [self selectRowIndexes:selectedIndexes inColumn:column];
}

- (BOOL)allowsMultipleSelection
{
    return _allowsMultipleSelection;
}

- (void)setAllowsMultipleSelection:(BOOL)shouldAllow
{
    if (_allowsMultipleSelection === shouldAllow)
        return;

    _allowsMultipleSelection = shouldAllow;
    [_tableViews makeObjectsPerformSelector:@selector(setAllowsMultipleSelection:) withObject:shouldAllow];
}

- (BOOL)allowsEmptySelection
{
    return _allowsEmptySelection;
}

- (void)setAllowsEmptySelection:(BOOL)shouldAllow
{
    if (_allowsEmptySelection === shouldAllow)
        return;

    _allowsEmptySelection = shouldAllow;
    [_tableViews makeObjectsPerformSelector:@selector(setAllowsEmptySelection:) withObject:shouldAllow];
}

- (CPIndexSet)selectedRowIndexesInColumn:(unsigned)column
{
    if (column < 0 || column > [self lastColumn] +1)
        return [CPIndexSet indexSet];

    return [[self tableViewInColumn:column] selectedRowIndexes];
}

- (void)selectRowIndexes:(CPIndexSet)indexSet inColumn:(unsigned)column
{
    if (column < 0 || column > [self lastColumn] + 1)
        return;

    indexSet = [self _sendDelegateBrowserSelectionIndexesForProposedSelection:indexSet inColumn:column];

    if (![self _sendDelegateBrowserShouldSelectRowIndexes:indexSet inColumn:column])
        return;

    [self _sendDelegateBrowserSelectionIsChanging];

    if (column > [self lastColumn])
        [self addColumn];

    [self setLastColumn:column];

    [[self tableViewInColumn:column] selectRowIndexes:indexSet byExtendingSelection:NO];

    [self scrollColumnToVisible:column];

    [self _sendDelegateBrowserSelectionDidChange];
}

- (void)setBackgroundColor:(CPColor)aColor
{
    [super setBackgroundColor:aColor];
    [_contentView setBackgroundColor:aColor];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

// DRAG AND DROP

- (void)registerForDraggedTypes:(CPArray)types
{
    [super registerForDraggedTypes:types];
    [_tableViews makeObjectsPerformSelector:@selector(registerForDraggedTypes:) withObject:types];
}

@end

@implementation CPBrowser (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self _init];

        _allowsEmptySelection = [aCoder decodeBoolForKey:@"CPBrowserAllowsEmptySelectionKey"];
        _allowsMultipleSelection = [aCoder decodeBoolForKey:@"CPBrowserAllowsMultipleSelectionKey"];
        _prototypeView = [aCoder decodeObjectForKey:@"CPBrowserPrototypeViewKey"];
        _rowHeight = [aCoder decodeFloatForKey:@"CPBrowserRowHeightKey"];
        _imageWidth = [aCoder decodeFloatForKey:@"CPBrowserImageWidthKey"];
        _minColumnWidth = [aCoder decodeFloatForKey:@"CPBrowserMinColumnWidthKey"];
        _columnWidths = [aCoder decodeObjectForKey:@"CPBrowserColumnWidthsKey"];

        [self setDelegate:[aCoder decodeObjectForKey:@"CPBrowserDelegateKey"]];
        [self setAutohidesScroller:[aCoder decodeBoolForKey:@"CPBrowserAutohidesScrollerKey"]];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    // Don't encode the subviews, they're transient and will be recreated from data.
    var actualSubviews = _subviews;
    _subviews = [];
    [super encodeWithCoder:aCoder];
    _subviews = actualSubviews;

    [aCoder encodeBool:[self autohidesScroller] forKey:@"CPBrowserAutohidesScrollerKey"];
    [aCoder encodeBool:_allowsEmptySelection forKey:@"CPBrowserAllowsEmptySelectionKey"];
    [aCoder encodeBool:_allowsMultipleSelection forKey:@"CPBrowserAllowsMultipleSelectionKey"];
    [aCoder encodeObject:_delegate forKey:@"CPBrowserDelegateKey"];
    [aCoder encodeObject:_prototypeView forKey:@"CPBrowserPrototypeViewKey"];
    [aCoder encodeFloat:_rowHeight forKey:@"CPBrowserRowHeightKey"];
    [aCoder encodeFloat:_imageWidth forKey:@"CPBrowserImageWidthKey"];
    [aCoder encodeFloat:_minColumnWidth forKey:@"CPBrowserMinColumnWidthKey"];
    [aCoder encodeObject:_columnWidths forKey:@"CPBrowserColumnWidthsKey"];
}

@end


@implementation _CPBrowserResizeControl : CPView
{
    CGPoint     _mouseDownX;
    CPBrowser   _browser;
    unsigned    _index;
    unsigned    _width;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        var browser = [[CPBrowser alloc] init];
        [self setBackgroundColor:[CPColor colorWithPatternImage:[browser valueForThemeAttribute:@"image-control-resize"]]];
    }


    return self;
}

- (void)mouseDown:(CPEvent)anEvent
{
    _mouseDownX = [anEvent locationInWindow].x;
    _browser = [[self superview] _browser];
    _index = [_browser columnOfTableView:[[self superview] documentView]];
    _width = [_browser widthOfColumn:_index];
}

- (void)mouseDragged:(CPEvent)anEvent
{
    var deltaX = [anEvent locationInWindow].x - _mouseDownX;
    [_browser setWidth:_width + deltaX ofColumn:_index];
}

- (void)mouseUp:(CPEvent)anEvent
{
}

@end

@implementation _CPBrowserScrollView : CPScrollView
{
    _CPBrowserResizeControl  _resizeControl;
    CPBrowser                _browser @accessors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _resizeControl = [[_CPBrowserResizeControl alloc] initWithFrame:CGRectMakeZero()];
        [self addSubview:_resizeControl];
    }

    return self;
}

- (void)reflectScrolledClipView:(CPClipView)aClipView
{
    [super reflectScrolledClipView:aClipView];

    var frame = [_verticalScroller frame];
    frame.size.height = CGRectGetHeight([self bounds]) - 14.0 - frame.origin.y;
    [_verticalScroller setFrameSize:frame.size];

    var resizeFrame = CGRectMake(CGRectGetMinX(frame), CGRectGetMaxY(frame), [CPScroller scrollerWidth], 14.0);
    [_resizeControl setFrame:resizeFrame];
}

@end

@implementation _CPBrowserTableView : CPTableView
{
    CPBrowser   _browser;
}

- (id)initWithFrame:(CGRect)aFrame browser:(CPBrowser)aBrowser
{
    if (self = [super initWithFrame:aFrame])
        _browser = aBrowser;

    return self;
}

- (BOOL)acceptsFirstResponder
{
    return NO;
}

- (void)mouseDown:(CPEvent)anEvent
{
    [super mouseDown:anEvent];
    [[self window] makeFirstResponder:_browser];
}

- (CPView)browserView
{
    return _browser;
}

/*!
    @ignore
*/
- (BOOL)_isFocused
{
    return ([super _isFocused] || [_browser tableViewInColumn:[_browser selectedColumn]] === self);
}

- (BOOL)canDragRowsWithIndexes:(CPIndexSet)rowIndexes atPoint:(CGPoint)mouseDownPoint
{
    return [_browser canDragRowsWithIndexes:rowIndexes inColumn:[_browser columnOfTableView:self] withEvent:[CPApp currentEvent]];
}

- (CPImage)dragImageForRowsWithIndexes:(CPIndexSet)dragRows tableColumns:(CPArray)theTableColumns event:(CPEvent)dragEvent offset:(CGPoint)dragImageOffset
{
    return [_browser draggingImageForRowsWithIndexes:dragRows inColumn:[_browser columnOfTableView:self] withEvent:dragEvent offset:dragImageOffset] ||
           [super dragImageForRowsWithIndexes:dragRows tableColumns:theTableColumns event:dragEvent offset:dragImageOffset];
}

- (CPView)dragViewForRowsWithIndexes:(CPIndexSet)dragRows tableColumns:(CPArray)theTableColumns event:(CPEvent)dragEvent offset:(CGPoint)dragViewOffset
{
    var count = theTableColumns.length;
    while (count--)
    {
        if ([theTableColumns[count] identifier] === "Leaf")
            [theTableColumns removeObject:theTableColumns[count]];
    }

    return [_browser draggingViewForRowsWithIndexes:dragRows inColumn:[_browser columnOfTableView:self] withEvent:dragEvent offset:dragViewOffset] ||
           [super dragViewForRowsWithIndexes:dragRows tableColumns:theTableColumns event:dragEvent offset:dragViewOffset];
}


@end

@implementation _CPBrowserTableDelegate : CPObject
{
    CPBrowser   _browser @accessors;
    unsigned    _index @accessors;
    id          _delegate @accessors;
    id          _item @accessors;
}

- (unsigned)numberOfRowsInTableView:(CPTableView)aTableView
{
    return [_delegate browser:_browser numberOfChildrenOfItem:_item];
}

- (void)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)column row:(unsigned)row
{
    if ([column identifier] === "Image")
        return [_delegate browser:_browser imageValueForItem:[self childAtIndex:row]];
    else if ([column identifier] === "Leaf")
        return ![_browser isLeafItem:[self childAtIndex:row]];
    else
        return [_delegate browser:_browser objectValueForItem:[self childAtIndex:row]];
}

- (void)_tableViewDoubleClicked:(CPTableView)aTableView
{
    [_browser doDoubleClick:self];
}

- (void)_tableViewClicked:(CPTableView)aTableView
{
    var selectedIndexes = [aTableView selectedRowIndexes];
    [_browser _column:_index clickedRow:[selectedIndexes count] === 1 ? [selectedIndexes firstIndex] : -1];
}

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    var selectedIndexes = [[aNotification object] selectedRowIndexes];
    [_browser selectRowIndexes:selectedIndexes inColumn:_index];
}

- (id)childAtIndex:(CPUInteger)index
{
    return [_delegate browser:_browser child:index ofItem:_item];
}

- (BOOL)tableView:(CPTableView)aTableView acceptDrop:(id)info row:(CPInteger)row dropOperation:(CPTableViewDropOperation)operation
{
    if (_browser._implementedDelegateMethods & CPBrowserDelegate_browser_acceptDrop_atRow_column_dropOperation_)
        return [_delegate browser:_browser acceptDrop:info atRow:row column:_index dropOperation:operation];
    else
        return NO;
}

- (CPDragOperation)tableView:(CPTableView)aTableView validateDrop:(id)info proposedRow:(CPInteger)row proposedDropOperation:(CPTableViewDropOperation)operation
{
    if (_browser._implementedDelegateMethods & CPBrowserDelegate_browser_validateDrop_proposedRow_column_dropOperation_)
        return [_delegate browser:_browser validateDrop:info proposedRow:row column:_index dropOperation:operation];
    else
        return CPDragOperationNone;
}

- (BOOL)tableView:(CPTableView)aTableView writeRowsWithIndexes:(CPIndexSet)rowIndexes toPasteboard:(CPPasteboard)pboard
{
    if (_browser._implementedDelegateMethods & CPBrowserDelegate_browser_writeRowsWithIndexes_inColumn_toPasteboard_)
        return [_delegate browser:_browser writeRowsWithIndexes:rowIndexes inColumn:_index toPasteboard:pboard];
    else
        return NO;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if (aSelector === @selector(browser:writeRowsWithIndexes:inColumn:toPasteboard:))
        return [_delegate respondsToSelector:@selector(browser:writeRowsWithIndexes:inColumn:toPasteboard:)];
    else
        return [super respondsToSelector:aSelector];
}

@end

@implementation _CPBrowserLeafView : CPView
{
    BOOL        _isLeaf @accessors(readonly, property=isLeaf);
    CPImage     _branchImage @accessors(property=branchImage);
    CPImage     _highlightedBranchImage @accessors(property=highlightedBranchImage);
}

- (BOOL)objectValue
{
    return _isLeaf;
}

- (void)setObjectValue:(id)aValue
{
    _isLeaf = !!aValue;
    [self setNeedsLayout];
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "image-view")
        return CGRectInset([self bounds], 1, 1);

    return [super rectForEphemeralSubviewNamed:aName];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "image-view")
        return [[CPImageView alloc] initWithFrame:CGRectMakeZero()];

    return [super createEphemeralSubviewNamed:aName];
}

- (void)layoutSubviews
{
    var imageView = [self layoutEphemeralSubviewNamed:@"image-view"
                                           positioned:CPWindowAbove
                      relativeToEphemeralSubviewNamed:nil],
        isHighlighted = [self hasThemeState:CPThemeStateSelectedDataView];

    [imageView setImage: _isLeaf ? (isHighlighted ? _highlightedBranchImage : _branchImage) : nil];
    [imageView setImageScaling:CPImageScaleNone];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeBool:_isLeaf forKey:"_CPBrowserLeafViewIsLeafKey"];
    [aCoder encodeObject:_branchImage forKey:"_CPBrowserLeafViewBranchImageKey"];
    [aCoder encodeObject:_highlightedBranchImage forKey:"_CPBrowserLeafViewHighlightedBranchImageKey"];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _isLeaf = [aCoder decodeBoolForKey:"_CPBrowserLeafViewIsLeafKey"];
        _branchImage = [aCoder decodeObjectForKey:"_CPBrowserLeafViewBranchImageKey"];
        _highlightedBranchImage = [aCoder decodeObjectForKey:"_CPBrowserLeafViewHighlightedBranchImageKey"];
    }

    return self;
}

@end

@implementation CPBrowser (CPBrowserDelegate)

/*!
    @ignore
    Call delegate rootItemForBrowser:
*/
- (id)_sendDelegateRootItemForBrowser
{
    if (!(_implementedDelegateMethods & CPBrowserDelegate_rootItemForBrowser_))
        return nil;

    return [_delegate rootItemForBrowser:self];
}

/*!
    @ignore
    Call delegate browser:didChangeLastColumn:toColumn:
*/
- (void)_sendDelegateBrowserDidChangeLastColumn:(CPInteger)lastColumn toColumn:(CPInteger)newColumn
{
    if (!(_implementedDelegateMethods & CPBrowserDelegate_browser_didChangeLastColumn_toColumn_))
        return;

    [_delegate browser:self didChangeLastColumn:lastColumn toColumn:newColumn];
}

/*!
    @ignore
    Call delegate browser:didResizeColumn:
*/
- (void)_sendDelegateBrowserDidResizeColumn:(CPInteger)column
{
    if (!(_implementedDelegateMethods & CPBrowserDelegate_browser_didResizeColumn_))
        return;

    [_delegate browser:self didResizeColumn:column];
}

/*!
    @ignore
    Call delegate browserSelectionIsChanging:
*/
- (void)_sendDelegateBrowserSelectionIsChanging
{
    if (!(_implementedDelegateMethods & CPBrowserDelegate_browserSelectionIsChanging_))
        return;

    [_delegate browserSelectionIsChanging:self];
}

/*!
    @ignore
    Call delegate browser:shouldSelectRowIndexes:inColumn:
*/
- (BOOL)_sendDelegateBrowserShouldSelectRowIndexes:(CPIndexSet)anIndexSet inColumn:(CPInteger)aColumn
{
    if (!(_implementedDelegateMethods & CPBrowserDelegate_browser_shouldSelectRowIndexes_inColumn_))
        return YES;

    return [_delegate browser:self shouldSelectRowIndexes:anIndexSet inColumn:aColumn];
}

/*!
    @ignore
    Call delegate browser:selectionIndexesForProposedSelection:inColumn:
*/
- (CPIndexSet)_sendDelegateBrowserSelectionIndexesForProposedSelection:(CPIndexSet)anIndexSet inColumn:(CPInteger)aColumn
{
    if (!(_implementedDelegateMethods & CPBrowserDelegate_browser_selectionIndexesForProposedSelection_inColumn_))
        return anIndexSet;

    return [_delegate browser:self selectionIndexesForProposedSelection:anIndexSet inColumn:aColumn];
}

/*!
    @ignore
    Call delegate browserSelectionDidChange
*/
- (void)_sendDelegateBrowserSelectionDidChange
{
    if (!(_implementedDelegateMethods & CPBrowserDelegate_browserSelectionDidChange_))
        return;

    [_delegate browserSelectionDidChange:self];
}

- (BOOL)canDragRowsWithIndexes:(CPIndexSet)rowIndexes inColumn:(CPInteger)columnIndex withEvent:(CPEvent)dragEvent
{
    if (_implementedDelegateMethods & CPBrowserDelegate_browser_canDragRowsWithIndexes_inColumn_withEvent_)
        return [_delegate browser:self canDragRowsWithIndexes:rowIndexes inColumn:columnIndex withEvent:dragEvent];

    return YES;
}

- (CPImage)draggingImageForRowsWithIndexes:(CPIndexSet)rowIndexes inColumn:(CPInteger)columnIndex withEvent:(CPEvent)dragEvent offset:(CGPoint)dragImageOffset
{
    if (_implementedDelegateMethods & CPBrowserDelegate_browser_draggingImageForRowsWithIndexes_inColumn_withEvent_offset_)
        return [_delegate browser:self draggingImageForRowsWithIndexes:rowIndexes inColumn:columnIndex withEvent:dragEvent offset:dragImageOffset];

    return nil;
}

- (CPView)draggingViewForRowsWithIndexes:(CPIndexSet)rowIndexes inColumn:(CPInteger)columnIndex withEvent:(CPEvent)dragEvent offset:(CGPoint)dragImageOffset
{
    if (_implementedDelegateMethods & CPBrowserDelegate_browser_draggingViewForRowsWithIndexes_inColumn_withEvent_offset_)
        return [_delegate browser:self draggingViewForRowsWithIndexes:rowIndexes inColumn:columnIndex withEvent:dragEvent offset:dragImageOffset];

    return nil;
}

@end
