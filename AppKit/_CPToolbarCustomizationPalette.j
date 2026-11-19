/*
 * _CPToolbarCustomizationPalette.j
 * AppKit
 *
 * Created by David Richardson on 2026-11-19.
 * Copyright David Richardson 2026.
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

@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPKeyedUnarchiver.j>
@import <Foundation/CPObject.j>

@import "CPButton.j"
@import "CPCheckBox.j"
@import "CPDragServer_Constants.j"
@import "CPImageView.j"
@import "CPPasteboard.j"
@import "CPPopUpButton.j"
@import "CPTextField.j"
@import "CPView.j"

@class CPToolbar
@class CPToolbarItem

@global CPApp
@global CPToolbarFlexibleSpaceItemIdentifier
@global CPToolbarSeparatorItemIdentifier
@global CPToolbarSpaceItemIdentifier
@global CPToolbarDisplayModeIconAndLabel
@global CPToolbarDisplayModeIconOnly
@global CPToolbarDisplayModeLabelOnly
@global CPToolbarSizeModeRegular
@global CPToolbarSizeModeSmall

/*
    The pasteboard types of a drag in the customization palette: the identifier of one item, and
    the identifiers of the default set.
*/
_CPToolbarItemIdentifierPboardType  = @"_CPToolbarItemIdentifierPboardType";
_CPToolbarDefaultSetPboardType      = @"_CPToolbarDefaultSetPboardType";

var _CPToolbarPaletteCellSize       = CGSizeMake(76.0, 58.0),
    _CPToolbarPaletteImageSize      = CGSizeMake(32.0, 32.0),
    _CPToolbarPaletteMargin         = 16.0,
    _CPToolbarPaletteWidth          = 560.0;

/*
    Returns the index at which a drop at x inserts an item, given the horizontal centres of the
    items in order. The item goes before the first item whose centre lies at or right of x.
*/
function _CPToolbarInsertionIndex(itemCentres, x)
{
    var index = 0,
        count = itemCentres.length;

    while (index < count && itemCentres[index] < x)
        index++;

    return index;
}

/*
    The arrows of the flexible space: a line with a head at each end, as a mask that the palette
    paints in the secondary label colour.
*/
var _CPToolbarPaletteFlexibleSpaceArrows = "url(\"data:image/svg+xml," + encodeURIComponent(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 12"><path d="M2 6h20M2 6l4-4M2 6l4 4M22 6l-4-4M22 6l-4 4" fill="none" stroke="black" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>') + "\")";

/*
    Returns a view of aFrame drawn with a border of aStyle ("dashed" or "solid") in the
    secondary label colour, with rounded corners.
*/
function _CPToolbarPaletteOutline(aFrame, aStyle)
{
    var view = [[CPView alloc] initWithFrame:aFrame];

    [view setBackgroundColor:[CPColor colorWithCSSDictionary:@{
        @"border": @[@"1px " + aStyle + " ", [CPColor secondaryLabelColor]],
        @"border-radius": @"4px",
        @"box-sizing": @"border-box"
    }]];

    return view;
}

/*
    Returns a label for the palette in the label colour.
*/
function _CPToolbarPaletteLabel(aString, aFrame, anAlignment)
{
    var label = [[CPTextField alloc] initWithFrame:aFrame];

    [label setStringValue:aString];
    [label setTextColor:[CPColor labelColor]];
    [label setFont:[CPFont systemFontOfSize:11.0]];
    [label setAlignment:anAlignment];
    [label setLineBreakMode:CPLineBreakByTruncatingTail];

    return label;
}


/*
    The palette's view of one toolbar item, or of the default set: the item's image above its
    palette label. A mouse drag starts a drag of the item's identifier, or of the default set.
    @ignore
*/
/*
    Makes aView and its subviews refuse to edit or select text. The palette shows a copy of an
    item's view, and the sheet made the first text field in it the first responder. The copy then
    showed a text cursor, and a drag in it selected its text instead of dragging the item. The copy
    keeps its enabled look.
*/
function _CPToolbarPaletteMakeInert(aView)
{
    if ([aView respondsToSelector:@selector(setEditable:)])
        [aView setEditable:NO];

    if ([aView respondsToSelector:@selector(setSelectable:)])
        [aView setSelectable:NO];

    [[aView subviews] enumerateObjectsUsingBlock:function(aSubview)
    {
        _CPToolbarPaletteMakeInert(aSubview);
    }];
}

/*
    Returns YES when an item with anIdentifier can appear more than once in a toolbar: the
    space, flexible space and separator items.
*/
function _CPToolbarItemAllowsDuplicates(anIdentifier)
{
    return anIdentifier === CPToolbarSpaceItemIdentifier ||
           anIdentifier === CPToolbarFlexibleSpaceItemIdentifier ||
           anIdentifier === CPToolbarSeparatorItemIdentifier;
}

@implementation _CPToolbarPaletteItemView : CPView
{
    CPString        _itemIdentifier     @accessors(readonly, property=itemIdentifier);
    CPArray         _defaultSet         @accessors(readonly, property=defaultSet);
}

/*
    Initializes the view for anItem. The image is the item's image; an item without one, such
    as a space or an item with a view of its own, shows a frame of the item's width.
*/
- (id)initWithItem:(CPToolbarItem)anItem origin:(CGPoint)anOrigin
{
    self = [super initWithFrame:CGRectMake(anOrigin.x, anOrigin.y, _CPToolbarPaletteCellSize.width, _CPToolbarPaletteCellSize.height)];

    if (self)
    {
        _itemIdentifier = [anItem itemIdentifier];

        var image = [anItem image],
            imageFrame = CGRectMake((_CPToolbarPaletteCellSize.width - _CPToolbarPaletteImageSize.width) / 2.0, 4.0, _CPToolbarPaletteImageSize.width, _CPToolbarPaletteImageSize.height);

        /*
            An item without an image showed a grey box, so the spaces, the separator and an
            item with a view of its own, such as a search field, could not be told apart. Each
            now has a drawing in the manner of AppKit's palette: a dashed square for the space, a
            wide dashed frame with arrows for the flexible space and a line for the separator. An
            item with a view shows a copy of its view, as AppKit's palette shows the view, so a
            search field keeps its magnifying glass. The copy does not take mouse events, and the
            item's own view stays in the toolbar.
        */
        var identifier = _itemIdentifier,
            midX = _CPToolbarPaletteCellSize.width / 2.0,
            midY = 4.0 + _CPToolbarPaletteImageSize.height / 2.0;

        if (identifier === CPToolbarSpaceItemIdentifier)
            [self addSubview:_CPToolbarPaletteOutline(CGRectMake(midX - 12.0, midY - 12.0, 24.0, 24.0), @"dashed")];
        else if (identifier === CPToolbarFlexibleSpaceItemIdentifier)
        {
            var frame = CGRectMake(6.0, midY - 12.0, _CPToolbarPaletteCellSize.width - 12.0, 24.0),
                arrows = [[CPImageView alloc] initWithFrame:CGRectInset(frame, 8.0, 6.0)];

            [self addSubview:_CPToolbarPaletteOutline(frame, @"dashed")];

            [arrows setImage:[CPImage imageWithCSSDictionary:@{
                "-webkit-mask-image": _CPToolbarPaletteFlexibleSpaceArrows,
                "mask-image": _CPToolbarPaletteFlexibleSpaceArrows,
                "background-color": [CPColor secondaryLabelColor],
                "-webkit-mask-size": "contain",
                "mask-size": "contain",
                "-webkit-mask-repeat": "no-repeat",
                "mask-repeat": "no-repeat",
                "-webkit-mask-position": "center",
                "mask-position": "center"
            } size:CGSizeMake(CGRectGetWidth(frame) - 16.0, 12.0)]];
            [self addSubview:arrows];
        }
        else if (identifier === CPToolbarSeparatorItemIdentifier)
        {
            var line = [[CPView alloc] initWithFrame:CGRectMake(FLOOR(midX), midY - 14.0, 1.0, 28.0)];

            [line setBackgroundColor:[CPColor secondaryLabelColor]];
            [self addSubview:line];
        }
        else if ([anItem view])
        {
            var view = [anItem view],
                copy = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:view]],
                size = [anItem minSize],
                width = MIN(MAX(size.width, 24.0), _CPToolbarPaletteCellSize.width - 8.0),
                height = MIN(MAX(size.height, 16.0), 30.0);

            [copy setFrame:CGRectMake(FLOOR(midX - width / 2.0), FLOOR(midY - height / 2.0), width, height)];
            [copy setHitTests:NO];
            _CPToolbarPaletteMakeInert(copy);
            [self addSubview:copy];
        }
        else if (image)
        {
            var imageView = [[CPImageView alloc] initWithFrame:imageFrame];

            [imageView setImage:image];
            [imageView setImageScaling:CPImageScaleProportionallyDown];
            [self addSubview:imageView];
        }
        else
        {
            var size = _CPToolbarPaletteImageSize;

            [self addSubview:_CPToolbarPaletteOutline(CGRectMake(FLOOR(midX - size.width / 2.0), FLOOR(midY - size.height / 2.0), size.width, size.height), @"solid")];
        }

        [self addSubview:_CPToolbarPaletteLabel([anItem paletteLabel] || [anItem label] || @"", CGRectMake(0.0, 38.0, _CPToolbarPaletteCellSize.width, 18.0), CPCenterTextAlignment)];
    }

    return self;
}

/*
    Initializes the view of the default set: the items of the set in a row, in aFrame.
*/
- (id)initWithDefaultSet:(CPArray)theItems frame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _defaultSet = [theItems valueForKey:@"itemIdentifier"];

        [self setBackgroundColor:[CPColor quaternaryLabelColor]];

        var x = 4.0;

        for (var i = 0; i < theItems.length && x + _CPToolbarPaletteCellSize.width <= CGRectGetWidth(aFrame); i++)
        {
            var view = [[_CPToolbarPaletteItemView alloc] initWithItem:theItems[i] origin:CGPointMake(x, 0.0)];

            [view setHitTests:NO];
            [self addSubview:view];
            x += _CPToolbarPaletteCellSize.width;
        }
    }

    return self;
}

- (void)mouseDragged:(CPEvent)anEvent
{
    var pasteboard = [CPPasteboard pasteboardWithName:CPDragPboard];

    if (_defaultSet)
    {
        [pasteboard declareTypes:[_CPToolbarDefaultSetPboardType] owner:nil];
        [pasteboard setPropertyList:_defaultSet forType:_CPToolbarDefaultSetPboardType];
    }
    else
    {
        [pasteboard declareTypes:[_CPToolbarItemIdentifierPboardType] owner:nil];
        [pasteboard setString:_itemIdentifier forType:_CPToolbarItemIdentifierPboardType];
    }

    var dragView = [[CPView alloc] initWithFrame:[self bounds]];

    [dragView setBackgroundColor:[CPColor colorWithCalibratedWhite:0.5 alpha:0.3]];

    [self dragView:dragView at:CGPointMakeZero() offset:CGSizeMakeZero() event:anEvent pasteboard:pasteboard source:self slideBack:YES];
}

@end


/*
    A view over the toolbar view while the palette runs. It takes every mouse event, so that a
    click on an item, even an item with a view of its own, starts a drag instead of the item's
    action. Dragging an item within the toolbar moves it; dropping it outside the toolbar removes
    it. It accepts the drags of the palette's items and of the default set.
    @ignore
*/
@implementation _CPToolbarCustomizationOverlay : CPView
{
    CPToolbar       _toolbar;
    CPView          _insertionIndicator;
    CPInteger       _draggedIndex;
    BOOL            _droppedOnToolbar;
}

- (id)initWithToolbar:(CPToolbar)aToolbar frame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _toolbar = aToolbar;
        _draggedIndex = CPNotFound;

        [self setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [self registerForDraggedTypes:[_CPToolbarItemIdentifierPboardType, _CPToolbarDefaultSetPboardType]];

        _insertionIndicator = [[CPView alloc] initWithFrame:CGRectMake(0.0, 4.0, 2.0, CGRectGetHeight(aFrame) - 8.0)];
        [_insertionIndicator setBackgroundColor:[CPColor controlAccentColor]];
        [_insertionIndicator setHidden:YES];
        [self addSubview:_insertionIndicator];
    }

    return self;
}

/*
    Returns the horizontal centres of the toolbar's items in the receiver. An item that the
    toolbar hides for lack of room counts as lying beyond the right edge.
*/
- (CPArray)_itemCentres
{
    var toolbarView = [_toolbar _toolbarView],
        items = [_toolbar items];

    return items.map(function(anItem)
    {
        var view = [toolbarView viewForItem:anItem];

        if (!view || [view isHidden] || ![view superview])
            return Infinity;

        return CGRectGetMidX([self convertRect:[view frame] fromView:[view superview]]);
    });
}

/*
    Returns the index of the item under aPoint, or CPNotFound.
*/
- (CPInteger)_indexOfItemAtPoint:(CGPoint)aPoint
{
    var toolbarView = [_toolbar _toolbarView],
        items = [_toolbar items];

    for (var i = 0; i < items.length; i++)
    {
        var view = [toolbarView viewForItem:items[i]];

        if (view && ![view isHidden] && [view superview] && CGRectContainsPoint([self convertRect:[view frame] fromView:[view superview]], aPoint))
            return i;
    }

    return CPNotFound;
}

- (void)mouseDown:(CPEvent)anEvent
{
}

- (void)mouseDragged:(CPEvent)anEvent
{
    if (_draggedIndex !== CPNotFound)
        return;

    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        index = [self _indexOfItemAtPoint:point];

    if (index === CPNotFound)
        return;

    var item = [_toolbar items][index],
        itemView = [[_toolbar _toolbarView] viewForItem:item],
        itemFrame = [self convertRect:[itemView frame] fromView:[itemView superview]],
        pasteboard = [CPPasteboard pasteboardWithName:CPDragPboard],
        dragView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(itemFrame), CGRectGetHeight(itemFrame))];

    _draggedIndex = index;
    _droppedOnToolbar = NO;

    [pasteboard declareTypes:[_CPToolbarItemIdentifierPboardType] owner:nil];
    [pasteboard setString:[item itemIdentifier] forType:_CPToolbarItemIdentifierPboardType];

    [dragView setBackgroundColor:[CPColor colorWithCalibratedWhite:0.5 alpha:0.3]];

    [self dragView:dragView at:itemFrame.origin offset:CGSizeMakeZero() event:anEvent pasteboard:pasteboard source:self slideBack:NO];
}

/*
    An item dragged from the toolbar and dropped anywhere but on the toolbar is removed. The
    receiver notes a drop on the toolbar itself instead of reading the drag operation, because in
    the browser the operation comes from the browser's drop effect when the drag ends, which need
    not be none after a drop that no view accepted.
*/
- (void)draggedView:(CPView)aView endedAt:(CGPoint)aLocation operation:(CPDragOperation)anOperation
{
    var index = _draggedIndex;

    _draggedIndex = CPNotFound;
    [_insertionIndicator setHidden:YES];

    if (!_droppedOnToolbar && index !== CPNotFound && index < [[_toolbar items] count])
        [_toolbar removeItemAtIndex:index];

    _droppedOnToolbar = NO;
}

- (CPDragOperation)draggingEntered:(id)aSender
{
    return [self draggingUpdated:aSender];
}

- (CPDragOperation)draggingUpdated:(id)aSender
{
    var point = [self convertPoint:[aSender draggingLocation] fromView:nil],
        centres = [self _itemCentres],
        index = _CPToolbarInsertionIndex(centres, point.x),
        x = 8.0;

    if ([[[aSender draggingPasteboard] types] containsObject:_CPToolbarDefaultSetPboardType])
    {
        [_insertionIndicator setHidden:YES];
        return CPDragOperationCopy;
    }

    if (index > 0 && centres[index - 1] !== Infinity)
    {
        var previousView = [[_toolbar _toolbarView] viewForItem:[_toolbar items][index - 1]];

        x = CGRectGetMaxX([self convertRect:[previousView frame] fromView:[previousView superview]]) + 2.0;
    }

    [_insertionIndicator setFrameOrigin:CGPointMake(x, 4.0)];
    [_insertionIndicator setHidden:NO];

    return [aSender draggingSource] === self ? CPDragOperationMove : CPDragOperationCopy;
}

- (void)draggingExited:(id)aSender
{
    [_insertionIndicator setHidden:YES];
}

- (BOOL)prepareForDragOperation:(id)aSender
{
    [_insertionIndicator setHidden:YES];

    return YES;
}

- (BOOL)performDragOperation:(id)aSender
{
    var pasteboard = [aSender draggingPasteboard];

    if ([[pasteboard types] containsObject:_CPToolbarDefaultSetPboardType])
    {
        [_toolbar setConfigurationFromDictionary:@{ @"TB Item Identifiers": [pasteboard propertyListForType:_CPToolbarDefaultSetPboardType] }];
        return YES;
    }

    var identifier = [pasteboard stringForType:_CPToolbarItemIdentifierPboardType],
        point = [self convertPoint:[aSender draggingLocation] fromView:nil],
        index = _CPToolbarInsertionIndex([self _itemCentres], point.x);

    if (!identifier)
        return NO;

    /*
        A drop from the palette of an item already in the toolbar added a second item. The
        delegate can give the same view for each request, and a view has one superview, so the
        new item showed only its label. As in AppKit, only the space items can appear more than
        once; a drop of any other item already in the toolbar moves that item.
    */
    var fromIndex = CPNotFound;

    if ([aSender draggingSource] === self && _draggedIndex !== CPNotFound)
    {
        fromIndex = _draggedIndex;
        _droppedOnToolbar = YES;
    }
    else if (!_CPToolbarItemAllowsDuplicates(identifier))
        fromIndex = [[[_toolbar items] valueForKey:@"itemIdentifier"] indexOfObject:identifier];

    if (fromIndex !== CPNotFound)
    {
        if (index === fromIndex || index === fromIndex + 1)
            return YES;

        [_toolbar removeItemAtIndex:fromIndex];

        if (index > fromIndex)
            index--;
    }

    [_toolbar insertItemWithItemIdentifier:identifier atIndex:index];

    return YES;
}

@end


/*
    The customization palette of a toolbar: a sheet on the toolbar's window that shows the
    allowed items and the default set. The user drags items into the toolbar, within it and out
    of it; the Show menu sets the display mode, Use small size the size mode, and Done ends the
    palette.
    @ignore
*/
@implementation _CPToolbarCustomizationPalette : CPObject
{
    CPToolbar                       _toolbar;
    CPWindow                        _sheet          @accessors(readonly, property=sheet);
    CPArray                         _itemViews      @accessors(readonly, property=itemViews);
    _CPToolbarPaletteItemView       _defaultSetView @accessors(readonly, property=defaultSetView);
    CPPopUpButton                   _displayModeButton;
    CPCheckBox                      _smallSizeCheckBox;
    _CPToolbarCustomizationOverlay  _overlay;
}

- (id)initWithToolbar:(CPToolbar)aToolbar
{
    self = [super init];

    if (self)
    {
        _toolbar = aToolbar;
        [self _buildSheet];
    }

    return self;
}

- (void)_buildSheet
{
    var identifiers = [_toolbar _allowedItemIdentifiers],
        columns = FLOOR((_CPToolbarPaletteWidth - 2.0 * _CPToolbarPaletteMargin) / _CPToolbarPaletteCellSize.width),
        rows = MAX(1, CEIL(identifiers.length / columns)),
        gridHeight = rows * _CPToolbarPaletteCellSize.height,
        height = _CPToolbarPaletteMargin + 20.0 + gridHeight + 12.0 + 20.0 + _CPToolbarPaletteCellSize.height + 16.0 + 24.0 + _CPToolbarPaletteMargin;

    _sheet = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, _CPToolbarPaletteWidth, height) styleMask:CPDocModalWindowMask];

    var contentView = [_sheet contentView],
        y = _CPToolbarPaletteMargin;

    [contentView addSubview:_CPToolbarPaletteLabel(@"Drag your favorite items into the toolbar…", CGRectMake(_CPToolbarPaletteMargin, y, _CPToolbarPaletteWidth - 2.0 * _CPToolbarPaletteMargin, 18.0), CPLeftTextAlignment)];
    y += 20.0;

    _itemViews = [];

    for (var i = 0; i < identifiers.length; i++)
    {
        var item = [_toolbar _paletteItemForItemIdentifier:identifiers[i]];

        if (!item)
            continue;

        var column = _itemViews.length % columns,
            row = FLOOR(_itemViews.length / columns),
            view = [[_CPToolbarPaletteItemView alloc] initWithItem:item origin:CGPointMake(_CPToolbarPaletteMargin + column * _CPToolbarPaletteCellSize.width, y + row * _CPToolbarPaletteCellSize.height)];

        [_itemViews addObject:view];
        [contentView addSubview:view];
    }

    y += gridHeight + 12.0;

    [contentView addSubview:_CPToolbarPaletteLabel(@"…or drag the default set into the toolbar.", CGRectMake(_CPToolbarPaletteMargin, y, _CPToolbarPaletteWidth - 2.0 * _CPToolbarPaletteMargin, 18.0), CPLeftTextAlignment)];
    y += 20.0;

    var defaultItems = [[_toolbar _defaultItemIdentifiers] arrayByApplyingBlock:function(anIdentifier)
        {
            return [_toolbar _paletteItemForItemIdentifier:anIdentifier];
        }].filter(function(anItem) { return !!anItem; });

    _defaultSetView = [[_CPToolbarPaletteItemView alloc] initWithDefaultSet:defaultItems frame:CGRectMake(_CPToolbarPaletteMargin, y, _CPToolbarPaletteWidth - 2.0 * _CPToolbarPaletteMargin, _CPToolbarPaletteCellSize.height)];
    [contentView addSubview:_defaultSetView];
    y += _CPToolbarPaletteCellSize.height + 16.0;

    [contentView addSubview:_CPToolbarPaletteLabel(@"Show", CGRectMake(_CPToolbarPaletteMargin, y + 4.0, 40.0, 18.0), CPLeftTextAlignment)];

    _displayModeButton = [[CPPopUpButton alloc] initWithFrame:CGRectMake(_CPToolbarPaletteMargin + 44.0, y, 140.0, 24.0) pullsDown:NO];

    [self _addDisplayMode:CPToolbarDisplayModeIconAndLabel title:@"Icon and Text"];
    [self _addDisplayMode:CPToolbarDisplayModeIconOnly title:@"Icon Only"];
    [self _addDisplayMode:CPToolbarDisplayModeLabelOnly title:@"Text Only"];
    [_displayModeButton selectItemWithTag:[_toolbar displayMode] || CPToolbarDisplayModeIconAndLabel];
    [_displayModeButton setTarget:self];
    [_displayModeButton setAction:@selector(_setDisplayMode:)];
    [contentView addSubview:_displayModeButton];

    _smallSizeCheckBox = [[CPCheckBox alloc] initWithFrame:CGRectMake(_CPToolbarPaletteMargin + 200.0, y + 2.0, 130.0, 20.0)];
    [_smallSizeCheckBox setTitle:@"Use small size"];
    [_smallSizeCheckBox setState:[_toolbar sizeMode] === CPToolbarSizeModeSmall ? CPOnState : CPOffState];
    [_smallSizeCheckBox setTarget:self];
    [_smallSizeCheckBox setAction:@selector(_setSmallSize:)];
    [contentView addSubview:_smallSizeCheckBox];

    var doneButton = [[CPButton alloc] initWithFrame:CGRectMake(_CPToolbarPaletteWidth - _CPToolbarPaletteMargin - 80.0, y, 80.0, 24.0)];

    [doneButton setTitle:@"Done"];
    [doneButton setKeyEquivalent:CPCarriageReturnCharacter];
    [doneButton setTarget:self];
    [doneButton setAction:@selector(done:)];
    [contentView addSubview:doneButton];
}

- (void)_addDisplayMode:(CPToolbarDisplayMode)aMode title:(CPString)aTitle
{
    [_displayModeButton addItemWithTitle:aTitle];
    [[_displayModeButton lastItem] setTag:aMode];
}

- (void)_setDisplayMode:(id)aSender
{
    [_toolbar setDisplayMode:[[aSender selectedItem] tag]];
}

- (void)_setSmallSize:(id)aSender
{
    [_toolbar setSizeMode:[aSender state] === CPOnState ? CPToolbarSizeModeSmall : CPToolbarSizeModeRegular];
}

/*
    Shows the palette as a sheet on the toolbar's window and lays the overlay over the toolbar.
*/
- (void)run
{
    var toolbarView = [_toolbar _toolbarView];

    _overlay = [[_CPToolbarCustomizationOverlay alloc] initWithToolbar:_toolbar frame:[toolbarView bounds]];
    [toolbarView _setCustomizationOverlay:_overlay];

    [CPApp beginSheet:_sheet modalForWindow:[_toolbar _window] modalDelegate:self didEndSelector:@selector(_sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)done:(id)aSender
{
    [CPApp endSheet:_sheet];
}

- (void)_sheetDidEnd:(CPWindow)aSheet returnCode:(int)aCode contextInfo:(id)aContext
{
    [aSheet orderOut:self];
    [[_toolbar _toolbarView] _setCustomizationOverlay:nil];
    _overlay = nil;

    [_toolbar _customizationPaletteDidEnd];
}

@end
