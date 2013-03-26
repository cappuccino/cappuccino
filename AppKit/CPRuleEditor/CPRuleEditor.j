/*
 * CPRuleEditor.j
 * AppKit
 *
 * Created by cacaodev.
 * Copyright 2011, cacaodev.
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

@import <Foundation/CPPredicate.j>
@import <Foundation/CPArray.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPIndexSet.j>

@import "CPPasteboard.j"
@import "CPRuleEditor_Constants.j"
@import "CPTextField.j"
@import "CPViewAnimation.j"
@import "CPView.j"

@import "_CPRuleEditorViewSliceRow.j"
@import "_CPRuleEditorLocalizer.j"

@class CPCompoundPredicate
@class CPComparisonPredicate

@global CPDirectPredicateModifier
@global CPCaseInsensitivePredicateOption
@global CPOrPredicateType

var CPRuleEditorItemPBoardType  = @"CPRuleEditorItemPBoardType",
    itemsContext                = "items",
    valuesContext               = "values",
    subrowsContext              = "subrows_array",
    boundArrayContext           = "bound_array";

/*!
    @ingroup appkit
    @class CPRuleEditor

    @brief A view for creating and configuring criteria.

    A CPRuleEditor object is a view that allows the user to visually create and configure a list of options which are expressed by the rule editor as a predicate (see Predicate documentation). The view has a delegate which offers a tree of choices to the view. The choices are presented by the view to the user as a row of popup buttons, static text fields, and custom views. Each row in the list represents a particular path down the tree of choices.

    CPRuleEditor exposes one binding, rows. You can bind rows to an ordered collection (such as an instance of CPMutableArray). Each object in the collection should have the following properties:
    @n @n
    @c @@"rowType"
    @n      An integer representing the type of the row (CPRuleEditorRowType).
    @n@n @c @@"subrows"
    @n      An ordered to-many relation (such as an instance of CPMutableArray) containing the directly nested subrows for the given row.
    @n@n @c @@"displayValues"
    @n      An ordered to-many relation containing the display values for the row.
    @n@n @c @@"criteria"
    @n      An ordered to-many relation containing the criteria for the row.
*/

@implementation CPRuleEditor : CPControl
{
    BOOL             _suppressKeyDownHandling;
    BOOL             _allowsEmptyCompoundRows;
    BOOL             _disallowEmpty;
    BOOL             _delegateWantsValidation;
    BOOL             _editable;
    BOOL             _sendAction;

    Class           _rowClass;

    CPIndexSet      _draggingRows;
    CPInteger       _subviewIndexOfDropLine;
    CPView          _dropLineView;

    CPMutableArray  _rowCache;
    CPMutableArray  _slices;

    CPPredicate     _predicate;

    CPString        _itemsKeyPath;
    CPString        _subrowsArrayKeyPath;
    CPString        _typeKeyPath;
    CPString        _valuesKeyPath;
    CPString        _boundArrayKeyPath @accessors(property=boundArrayKeyPath);

    CPView          _slicesHolder;
    CPViewAnimation _currentAnimation;

    CPInteger       _lastRow;
    CPInteger       _nestingMode;

    float           _alignmentGridWidth;
    float           _sliceHeight;

    id              _ruleDataSource;
    id              _ruleDelegate;
    id              _boundArrayOwner;

    CPString        _stringsFilename;

    BOOL            _isKeyDown;
    BOOL            _nestingModeDidChange;

    _CPRuleEditorLocalizer _standardLocalizer @accessors(property=standardLocalizer);
    CPDictionary           _itemsAndValuesToAddForRowType;
}

/*! @cond */

+ (CPString)defaultThemeClass
{
    return @"rule-editor";
}

+ (id)themeAttributes
{
    return @{
            @"alternating-row-colors": [CPNull null],
            @"selected-color": [CPNull null],
            @"slice-top-border-color": [CPNull null],
            @"slice-bottom-border-color": [CPNull null],
            @"slice-last-bottom-border-color": [CPNull null],
            @"font": [CPNull null],
            @"add-image": [CPNull null],
            @"remove-image": [CPNull null],
        };
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self !== nil)
    {
        _slices = [[CPMutableArray alloc] init];

        _sliceHeight = 26.;
        _nestingMode = CPRuleEditorNestingModeSimple; // 10.5 default is CPRuleEditorNestingModeCompound
        _editable = YES;
        _allowsEmptyCompoundRows = NO;
        _disallowEmpty = NO;

        [self setFormattingStringsFilename:nil];
        [self setCriteriaKeyPath:@"criteria"];
        [self setSubrowsKeyPath:@"subrows"];
        [self setRowTypeKeyPath:@"rowType"];
        [self setDisplayValuesKeyPath:@"displayValues"];
        [self setBoundArrayKeyPath:@"boundArray"];

        _slicesHolder = [[_CPRuleEditorViewSliceHolder alloc] initWithFrame:[self bounds]];
        [self addSubview:_slicesHolder];

        _boundArrayOwner = [[_CPRuleEditorViewUnboundRowHolder alloc] init];

        [self _initRuleEditorShared];
    }

    return self;
}

- (void)_initRuleEditorShared
{
    _rowCache = [[CPMutableArray alloc] init];
    _rowClass = [_CPRuleEditorRowObject class];
    _isKeyDown = NO;
    _subviewIndexOfDropLine = CPNotFound;
    _lastRow = 0;
    _delegateWantsValidation = YES;
    _suppressKeyDownHandling = NO;
    _nestingModeDidChange = NO;
    _sendAction = YES;
    _itemsAndValuesToAddForRowType = {};
    var animation = [[CPViewAnimation alloc] initWithDuration:0.5 animationCurve:CPAnimationEaseInOut];
    [self setAnimation:animation];

    [_slicesHolder setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    _dropLineView =  [self _createSliceDropSeparator];
    [_slicesHolder addSubview:_dropLineView];

    [self registerForDraggedTypes:[CPArray arrayWithObjects:CPRuleEditorItemPBoardType,nil]];
    [_boundArrayOwner addObserver:self forKeyPath:_boundArrayKeyPath options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew context:boundArrayContext];
}

/*! @endcond */

/*!
    @name Configuring a Rule Editor
*/

/*!
    @brief Returns the receiver’s delegate.
    @return The receiver’s delegate.
    @see setDelegate:
*/
- (id)delegate
{
     return _ruleDelegate;
}

/*!
    @brief Sets the receiver’s delegate.
    @param aDelegate The delegate for the receiver.
    @discussion CPRuleEditor requires a delegate that implements the required delegate methods to function.
    @see delegate
*/
- (void)setDelegate:(id)aDelegate
{
    if (_ruleDelegate === aDelegate)
        return;

    var nc = [CPNotificationCenter defaultCenter];
    if (_ruleDelegate)
        [nc removeObserver:_ruleDelegate name:nil object:self];

    _ruleDelegate = aDelegate;

    if ([_ruleDelegate respondsToSelector:@selector(ruleEditorRowsDidChange:)])
        [nc addObserver:_ruleDelegate selector:@selector(ruleEditorRowsDidChange:) name:CPRuleEditorRowsDidChangeNotification object:nil];
}
/*!
    @brief Returns a Boolean value that indicates whether the receiver is editable.
    @return @c YES if the receiver is editable, otherwise @c NO.
    @discussion The default is @c YES.
    @see setEditable:
*/
- (BOOL)isEditable
{
    return _editable;
}

/*!
    @brief Sets whether the receiver is editable.
    @param editable @c YES if the receiver is editable, otherwise @c NO.
    @see isEditable:
*/
- (void)setEditable:(BOOL)editable
{
    if (editable === _editable)
        return;

    _editable = editable;

    if (!_editable)
        [self _deselectAll];

    [_slices makeObjectsPerformSelector:@selector(setEditable:) withObject:_editable];
}

/*!
    @brief Returns the nesting mode for the receiver.
    @return The nesting mode for the receiver.
    @see setNestingMode:
*/
- (CPRuleEditorNestingMode)nestingMode
{
     return _nestingMode;
}

/*!
    @brief Sets the nesting mode for the receiver.
    @param mode The nesting mode for the receiver.
    @discussion You typically set the nesting mode at view creation time and do not subsequently modify it. The default is @c CPRuleEditorNestingModeSimple.
    @see nestingMode
    @note Currently CPRuleEditorNestingModeCompound is experimental.
*/
- (void)setNestingMode:(CPRuleEditorNestingMode)mode
{
    if (mode !== _nestingMode)
    {
        _nestingMode = mode;
        if ([self numberOfRows] > 0)
            _nestingModeDidChange = YES;
    }
}

/*!
    @brief Returns a Boolean value that indicates whether all the rows can be removed.
    @return @c YES if all the rows can be removed, otherwise @c NO.
    @see setCanRemoveAllRows:
*/
- (BOOL)canRemoveAllRows
{
    return !_disallowEmpty;
}

/*!
    @brief Sets whether all the rows can be removed.
    @param canRemove @c YES if all the rows can be removed, otherwise @c NO.
    @see canRemoveAllRows
*/
- (void)setCanRemoveAllRows:(BOOL)canRemove
{
    _disallowEmpty = !canRemove;
    [self _updateButtonVisibilities];
}

/*!
    @brief Returns a Boolean value that indicates whether compounds rows can be childless.
    @return @c YES if compounds rows can be childless, otherwise @c NO.
    @see setAllowsEmptyCompoundRows:
*/
- (BOOL)allowsEmptyCompoundRows
{
    return _allowsEmptyCompoundRows;
}

/*!
    @brief Sets whether compounds rows can be childless.
    @param allows @c YES if compounds rows can be childless, otherwise @c NO.
    @see allowsEmptyCompoundRows
*/
- (void)setAllowsEmptyCompoundRows:(BOOL)allows
{
    _allowsEmptyCompoundRows = allows;
    [self _updateButtonVisibilities];
}

/*!
    @brief Returns the row height for the receiver.
    @return The row height for the receiver.
    @see setRowHeight:
*/
- (CPInteger)rowHeight
{
    return _sliceHeight;
}

/*!
    @brief Sets the row height for the receiver.
    @param height The row height for the receiver.
    @see rowHeight
*/
- (void)setRowHeight:(float)height
{
    if (height === _sliceHeight)
        return;

    _sliceHeight = MAX([self _minimumFrameHeight], height);
    [self _reconfigureSubviewsAnimate:NO];
}

/*!
    @name Working with Formatting
*/

/*!
    @brief Returns the formatting dictionary for the receiver.
    @return The formatting dictionary for the receiver.
    @see setFormattingDictionary:
    @see setFormattingStringsFilename:
*/
- (CPDictionary)formattingDictionary
{
    return [_standardLocalizer dictionary];
}

/*!
    @brief Sets the formatting dictionary for the receiver.
    @param dictionary The formatting dictionary for the receiver.
    @discussion If you set the formatting dictionary with this method, it sets the current formatting strings file name to @c nil.
    @see formattingDictionary
    @see formattingStringsFilename
*/
- (void)setFormattingDictionary:(CPDictionary)dictionary
{
    [_standardLocalizer setDictionary:dictionary];
    _stringsFilename = nil;
}

/*!
    @brief Returns the name of the strings file for the receiver.
    @return The name of the strings file for the receiver.
    @see setFormattingStringsFilename:
*/
- (CPString)formattingStringsFilename
{
    return _stringsFilename;
}

/*!
    @brief Sets the name of the strings file used for formatting.
    @param stringsFilename The name of the strings file for the receiver.
    @discussion CPRuleEditor looks for a strings file with the given name in the main bundle and (if appropriate) the bundle containing the nib file from which it was loaded. If it finds a strings file resource with the given name, CPRuleEditor loads it and sets it as the formatting dictionary for the receiver. You can obtain the resulting dictionary using formattingDictionary.
        If you set the formatting dictionary with -#setFormattingDictionary:, it sets the current formatting strings file name nil.
    @see formattingStringsFilename
*/
- (void)setFormattingStringsFilename:(CPString)stringsFilename
{
    if (_standardLocalizer === nil)
        _standardLocalizer = [_CPRuleEditorLocalizer new];

    if (_stringsFilename !== stringsFilename)
    {
        // Convert an empty string to nil
        _stringsFilename = stringsFilename || nil;

        if (stringsFilename !== nil)
        {
            if (![stringsFilename hasSuffix:@".strings"])
                stringsFilename = stringsFilename + @".strings";

            var path = [[CPBundle mainBundle] pathForResource:stringsFilename];

            if (path !== nil)
                [_standardLocalizer loadContentOfURL:[CPURL URLWithString:path]];
        }
    }
}

/*!
    @name Providing Data
*/

/*!
    @brief Instructs the receiver to refetch criteria from its delegate.
    @discussion You can use this method to indicate that the available criteria may have changed and should be refetched from the delegate and the popups recalculated.
*/
- (void)reloadCriteria
{
    var current_rows = [_boundArrayOwner valueForKey:_boundArrayKeyPath];
    [self _stopObservingRowObjectsRecursively:current_rows];
    [_boundArrayOwner setValue:[CPArray arrayWithArray:current_rows] forKey:_boundArrayKeyPath];
}

/*!
    @brief Modifies the row at a given index to contain the given items and values.
    @param criteria The array of criteria for the row at @a rowIndex. Pass an empty array to force the receiver to query its delegate. This value must not be nil.
    @param values The array of values for the row at @a rowIndex. Pass an empty array to force the receiver to query its delegate. This value must not be @c nil.
    @param rowIndex The index of a row in the receiver.

    @discussion It is your responsibility to ensure that each item in the array is a child of the previous item, and that the first item is a root item for the row type. If the last item has child items, then the items array will be extended by querying the delegate for child items until a childless item is reached.
*/
- (void)setCriteria:(CPArray)criteria andDisplayValues:(CPArray)values forRowAtIndex:(int)rowIndex
{
    if (criteria === nil || values === nil)
        [CPException raise:CPInvalidArgumentException reason:_cmd + @". criteria and values parameters must not be nil."];

    if (rowIndex < 0 || rowIndex >= [self numberOfRows])
        [CPException raise:CPRangeException reason:_cmd + @". rowIndex is out of bounds."];

    var rowObject = [[self _rowCacheForIndex:rowIndex] rowObject];

    [rowObject setValue:criteria forKey:_itemsKeyPath];
    [rowObject setValue:values forKey:_valuesKeyPath];

    [self reloadCriteria];
}

/*!
    @brief Returns the currently chosen items for a given row.
    @param row The index of a row in the receiver.
    @return The currently chosen items for row @a row.
*/
- (id)criteriaForRow:(int)row
{
    var rowcache = [self _rowCacheForIndex:row];
    if (rowcache)
        return [[rowcache rowObject] valueForKey:_itemsKeyPath];

    return nil;
}

/*!
    @name Working with the Selection
*/

/*!
    @brief Returns the chosen values for a given row.
    @param row The index of a row in the receiver.
    @return The chosen values (strings, views, or menu items) for row row.
    @discussion The values returned are the same as those returned from the delegate method -#ruleEditor:displayValueForCriterion:inRow:
*/
- (CPMutableArray)displayValuesForRow:(int)row
{
    var rowcache = [self _rowCacheForIndex:row];
    if (rowcache)
        return [[rowcache rowObject] valueForKey:_valuesKeyPath];

    return nil;
}

/*!
    @brief Returns the number of rows in the receiver.
    @return The number of rows in the receiver.
*/
- (int)numberOfRows
{
     return [_slices count];
}

/*!
    @brief Returns the index of the parent of a given row.
    @param rowIndex The index of a row in the receiver.
    @return The index of the parent of the row at @a rowIndex. If the row at @a rowIndex is a root row, returns @c -1.
*/
- (int)parentRowForRow:(int)rowIndex
{
    if (rowIndex < 0 || rowIndex >= [self numberOfRows])
        [CPException raise:CPRangeException reason:_cmd + @" row " + rowIndex + " is out of range"];

    var targetObject = [[self _rowCacheForIndex:rowIndex] rowObject];

    for (var current_index = 0; current_index < rowIndex; current_index++)
    {
        if ([self rowTypeForRow:current_index] === CPRuleEditorRowTypeCompound)
        {
            var candidate = [[self _rowCacheForIndex:current_index] rowObject],
                subObjects = [[self _subrowObjectsOfObject:candidate] _representedObject];

            if ([subObjects indexOfObjectIdenticalTo:targetObject] !== CPNotFound)
                return current_index;
        }
    }

    return -1;
}

/*
TODO: implement
    Returns the index of the row containing a given value.

    displayValue The display value (string, view, or menu item) of an item in the receiver. This value must not be nil.

    The index of the row containing displayValue, or CPNotFound.

    This method searches each row via objects equality for the given display value, which may be present as an alternative in a popup menu for that row.

- (CPInteger)rowForDisplayValue:(id)displayValue
*/

/*!
    @brief Returns the type of a given row.
    @param rowIndex The index of a row in the receiver.
    @return The type of the row at @a rowIndex.
    @warning Raises a @c CPRangeException if rowIndex is less than @c 0 or greater than or equal to the number of rows.
*/
- (CPRuleEditorRowType)rowTypeForRow:(int)rowIndex
{
    if (rowIndex < 0 || rowIndex > [self numberOfRows])
        [CPException raise:CPRangeException reason:_cmd + @"row " + rowIndex + " is out of range"];

    var rowcache = [self _rowCacheForIndex:rowIndex];
    if (rowcache)
    {
        var rowobject = [rowcache rowObject];
        return [rowobject valueForKey:_typeKeyPath];
    }

    return CPNotFound;
}

/*!
    @brief Returns the immediate subrows of a given row.
    @param rowIndex The index of a row in the receiver, or @c -1 to get the top-level rows.
    @return The immediate subrows of the row at @a rowIndex.
    @discussion Rows are numbered starting at @c 0.
*/
- (CPIndexSet)subrowIndexesForRow:(int)rowIndex
{
    var object;

    if (rowIndex === -1)
        object = _boundArrayOwner;
    else
        object = [[self _rowCacheForIndex:rowIndex] rowObject];

    var subobjects = [self _subrowObjectsOfObject:object],
        objectsCount = [subobjects count],
        indexes = [CPMutableIndexSet indexSet],
        count = [self numberOfRows];

    for (var i = rowIndex + 1; i < count; i++)
    {
        var candidate = [[self _rowCacheForIndex:i] rowObject],
            indexInSubrows = [[subobjects _representedObject] indexOfObjectIdenticalTo:candidate];

        if (indexInSubrows !== CPNotFound)
        {
            [indexes addIndex:i];
            objectsCount--;

            if ([self rowTypeForRow:i] === CPRuleEditorRowTypeCompound)
                i += [[self subrowIndexesForRow:i] count];
        }

        if (objectsCount === 0)
            break;
    }

    return indexes;
}

/*!
    @brief Returns the indexes of the receiver’s selected rows.
    @return The indexes of the receiver’s selected rows.
*/
- (CPIndexSet)selectedRowIndexes
{
    return [self _selectedSliceIndices];
}

/*!
    @brief Sets in the receiver the indexes of rows that are selected.
    @param indexes The indexes of rows in the receiver to select.
    @param extend If @c NO, the selected rows are specified by indexes. If @c YES, the rows indicated by indexes are added to the collection of already selected rows, providing multiple selection.
*/
- (void)selectRowIndexes:(CPIndexSet)indexes byExtendingSelection:(BOOL)extend
{
    var count = [_slices count],
        lastSelected = [indexes lastIndex];

    if (lastSelected >= [self numberOfRows])
        [CPException raise:CPRangeException reason:@"row indexes " + indexes + " are out of range"];

    if (!extend)
        [self _deselectAll];

    while (count--)
    {
        var slice = _slices[count],
            rowIndex = [slice rowIndex],
            contains = [indexes containsIndex:rowIndex],
            shouldSelect = (contains && !(extend && [slice _isSelected]));

        if (contains)
            [slice _setSelected:shouldSelect];
        [slice _setLastSelected:(rowIndex === lastSelected)];
        [slice setNeedsDisplay:YES];
    }
}

/*!
    @name Manipulating Rows
*/

/*!
    @brief Adds a row to the receiver.
    @param sender Typically the object that sent the message.
    @see insertRowAtIndex:withType:asSubrowOfRow:animate:
*/
- (void)addRow:(id)sender
{
    var parentRowIndex = -1,
        rowtype,
        numberOfRows = [self numberOfRows],
        hasRows = (numberOfRows > 0),
        nestingMode = [self _applicableNestingMode];

    switch (nestingMode)
    {
        case CPRuleEditorNestingModeSimple:
            rowtype = hasRows ? CPRuleEditorRowTypeSimple : CPRuleEditorRowTypeCompound;
            if (hasRows)
                parentRowIndex = 0;
            break;
        case CPRuleEditorNestingModeSingle:
             if (hasRows)
                return;
        case CPRuleEditorNestingModeList:
            rowtype = CPRuleEditorRowTypeSimple;
            break;
        case CPRuleEditorNestingModeCompound:
            rowtype = CPRuleEditorRowTypeCompound;
            if (hasRows)
                parentRowIndex = 0;
            break;
        default:
            [CPException raise:CPInvalidArgumentException reason:@"Not supported CPRuleEditorNestingMode " + nestingMode];
        // Compound mode: parentRowIndex=(lastRowType === CPRuleEditorRowTypeCompound)?lastRow :[self parentRowForRow:lastRow]; break;
    }

    [self insertRowAtIndex:numberOfRows withType:rowtype asSubrowOfRow:parentRowIndex animate:YES];
}

/*!
    @brief Adds a new row of a given type at a given location.
    @param rowIndex The index at which the new row should be inserted. @a rowIndex must be greater than @a parentRow, and much specify a row that does not fall amongst the children of some other parent.
    @param rowType The type of the new row.
    @param parentRow The index of the row of which the new row is a child. Pass -1 to indicate that the new row should be a root row.
    @param shouldAnimate @c YES if creation of the new row should be animated, otherwise @c NO.
    @note Currently, @a shouldAnimate has no effect, rows are always animated when calling this method.
    @see addRow:
*/
- (void)insertRowAtIndex:(int)rowIndex withType:(unsigned int)rowType asSubrowOfRow:(int)parentRow animate:(BOOL)shouldAnimate
{
/*
    TODO: raise exceptions if parentRow is greater than or equal to rowIndex, or if rowIndex would fall amongst the children of some other parent, or if the nesting mode forbids this configuration.
*/
    var newObject = [self _insertNewRowAtIndex:rowIndex ofType:rowType withParentRow:parentRow];

    if (rowType === CPRuleEditorRowTypeCompound && !_allowsEmptyCompoundRows)
    {
        var subrow = [self _insertNewRowAtIndex:(rowIndex + 1) ofType:CPRuleEditorRowTypeSimple withParentRow:rowIndex];
    }
}

/*!
    @brief Removes the row at a given index.
    @param rowIndex The index of a row in the receiver.
    @warning Raises a @c CPRangeException if @a rowIndex is less than @c 0 or greater than or equal to the number of rows.
    @see removeRowsAtIndexes:includeSubrows:
*/
- (void)removeRowAtIndex:(int)rowIndex
{
    //  TO DO : Any subrows of the deleted row are adopted by the parent of the deleted row, or are made root rows.

    if (rowIndex < 0 || rowIndex >= [self numberOfRows])
        [CPException raise:CPRangeException reason:@"row " + rowIndex + " is out of range"];

    [self removeRowsAtIndexes:[CPIndexSet indexSetWithIndex:rowIndex] includeSubrows:NO];
}

/*!
    @brief Removes the rows at a given index.
    @param rowIndexes Indexes of one or more rows in the receiver.
    @param includeSubrows If @c YES, then sub-rows of deleted rows are also deleted; if @c NO, then each sub-row is adopted by its first non-deleted ancestor, or becomes a root row.
    @warning Raises a @c CPRangeException if any index in @a rowIndexes is less than 0 or greater than or equal to the number of rows.
    @see removeRowAtIndex:
*/
- (void)removeRowsAtIndexes:(CPIndexSet)rowIndexes includeSubrows:(BOOL)includeSubrows
{
    if ([rowIndexes count] === 0)
        return;

    if ([rowIndexes lastIndex] >= [self numberOfRows])
        [CPException raise:CPRangeException reason:@"rows indexes " + rowIndexes + " are out of range"];

    var current_index = [rowIndexes firstIndex],
        parentRowIndex = [self parentRowForRow:current_index],
        childsIndexes = [CPMutableIndexSet indexSet],
        subrows;

    if (parentRowIndex === -1)
        subrows = [self _rootRowsArray];
    else
    {
        var parentRowObject = [[self _rowCacheForIndex:parentRowIndex] rowObject];
        subrows = [self _subrowObjectsOfObject:parentRowObject];
    }

    while (current_index !== CPNotFound)
    {
        var rowObject = [[self _rowCacheForIndex:current_index] rowObject],
            relativeChildIndex = [[subrows _representedObject] indexOfObjectIdenticalTo:rowObject];

        if (relativeChildIndex !== CPNotFound)
            [childsIndexes addIndex:relativeChildIndex];

        if (includeSubrows && [self rowTypeForRow:current_index] === CPRuleEditorRowTypeCompound)
        {
            var more_childs = [self subrowIndexesForRow:current_index];
            [self removeRowsAtIndexes:more_childs includeSubrows:includeSubrows];
        }

        current_index = [rowIndexes indexGreaterThanIndex:current_index];
    }

    [subrows removeObjectsAtIndexes:childsIndexes];
}

/*!
    @name Working with Predicates
*/

/*!
    @brief Returns the predicate for the receiver.
    @return If the delegate implements -#ruleEditor:predicatePartsForCriterion:withDisplayValue:inRow:, the predicate for the receiver. If not, or if the delegate does not return enough parts to construct a full predicate, returns @c nil.
    @see predicateForRow:
*/
- (CPPredicate)predicate
{
    return _predicate;
}

/*!
    @brief Instructs the receiver to regenerate its predicate by invoking the corresponding delegate method.
    @discussion You typically invoke this method because something has changed (for example, a view's value).
*/
- (void)reloadPredicate
{
    [self _updatePredicate];
}

/*!
    @brief Returns the predicate for a given row.
    @param aRow The index of a row in the receiver.
    @return The predicate for the row at @a aRow.
    @discussion You should rarely have a need to call this directly, but you can override this method in a subclass to perform specialized predicate handling for certain criteria or display values.
*/
- (CPPredicate)predicateForRow:(CPInteger)aRow
{
    var predicateParts = @{},
        items = [self criteriaForRow:aRow],
        count = [items count],
        predicate,
        i;

    for (i = 0; i < count; i++)
    {
        var item = [items objectAtIndex:i],
        //var displayValue = [self _queryValueForItem:item inRow:aRow]; Ask the delegate or get cached value ?.
            displayValue = [[self displayValuesForRow:aRow] objectAtIndex:i],
            predpart = [_ruleDelegate ruleEditor:self predicatePartsForCriterion:item withDisplayValue:displayValue inRow:aRow];

        if (predpart)
            [predicateParts addEntriesFromDictionary:predpart];
    }

    if ([self rowTypeForRow:aRow] === CPRuleEditorRowTypeCompound)
    {
        var compoundPredicate,
            subpredicates = [CPMutableArray array],
            subrowsIndexes = [self subrowIndexesForRow:aRow];

        if ([subrowsIndexes count] === 0)
            return nil;

        var current_index = [subrowsIndexes firstIndex];
        while (current_index !== CPNotFound)
        {
            var subpredicate = [self predicateForRow:current_index];
            if (subpredicate !== nil)
                [subpredicates addObject:subpredicate];

            current_index = [subrowsIndexes indexGreaterThanIndex:current_index];
        }

        var compoundType = [predicateParts objectForKey:CPRuleEditorPredicateCompoundType];

        if ([subpredicates count] === 0)
            return nil;
        else
        {
            try
            {
                compoundPredicate = [[CPCompoundPredicate alloc ] initWithType:compoundType subpredicates:subpredicates];
            }
            catch(error)
            {
                CPLogConsole(@"Compound predicate error: [%@]\npredicateType:%i", [error description], compoundType);
                compoundPredicate = nil;
            }
            finally
            {
                return compoundPredicate;
            }

        }
    }

    var lhs = [predicateParts objectForKey:CPRuleEditorPredicateLeftExpression],
        rhs = [predicateParts objectForKey:CPRuleEditorPredicateRightExpression],
        operator = [predicateParts objectForKey:CPRuleEditorPredicateOperatorType],
        options  = [predicateParts objectForKey:CPRuleEditorPredicateOptions],
        modifier = [predicateParts objectForKey:CPRuleEditorPredicateComparisonModifier],
        selector = CPSelectorFromString([predicateParts objectForKey:CPRuleEditorPredicateCustomSelector]);

    if (lhs === nil)
    {
        CPLogConsole(@"missing left expression in predicate parts dictionary");
        return NULL;
    }

    if (rhs === nil)
    {
        CPLogConsole(@"missing right expression in predicate parts dictionary");
        return NULL;
    }

    if (selector === nil && operator === nil)
    {
        CPLogConsole(@"missing operator and selector in predicate parts dictionary");
        return NULL;
    }

    if (modifier === nil)
        CPLogConsole(@"missing modifier in predicate parts dictionary. Setting default: CPDirectPredicateModifier");

    if (options === nil)
        CPLogConsole(@"missing options in predicate parts dictionary. Setting default: CPCaseInsensitivePredicateOption");

    try
    {
        if (selector !== nil)
            predicate = [CPComparisonPredicate predicateWithLeftExpression:lhs
                                                           rightExpression:rhs
                                                            customSelector:selector
                         ];
        else
            predicate = [CPComparisonPredicate predicateWithLeftExpression:lhs
                                                           rightExpression:rhs
                                                                  modifier:(modifier || CPDirectPredicateModifier)
                                                                      type:operator
                                                                   options:(options || CPCaseInsensitivePredicateOption)
                         ];
    }
    catch(error)
    {
        CPLogConsole(@"Row predicate error: [" + [error description] + "] for row " + aRow);
        predicate = nil;
    }
    finally
    {
        return predicate;
    }
}

/*!
    @name Supporting Bindings
*/

/*!
    @brief Returns the class used to create a new row in the “rows” binding.
    @return The class used to create a new row in the "rows" binding.
    @see setRowClass:
*/
- (Class)rowClass
{
    return _rowClass;
}

/*!
    @brief Sets the class to use to create a new row in the "rows” binding.
    @param rowClass The class to use to create a new row in the "rows” binding.
    @see rowClass
*/
- (void)setRowClass:(Class)rowClass
{
    if (rowClass === [CPMutableDictionary class])
        rowClass = [_CPRuleEditorRowObject class];

    _rowClass = rowClass;
}

/*!
    @brief Returns the key path for the row type.
    @return The key path for the row type.
    @discussion The default value is @c @"rowType".
    The key path is used to get the row type in the “rows” binding. The corresponding property should be a number that specifies an @c CPRuleEditorRowType value.
    @see setRowTypeKeyPath:
*/
- (CPString)rowTypeKeyPath
{
    return _typeKeyPath;
}

/*!
    @brief Sets the key path for the row type.
    @param keyPath The key path for the row type.
    @see rowTypeKeyPath
*/
- (void)setRowTypeKeyPath:(CPString)keyPath
{
    if (_typeKeyPath !== keyPath)
        _typeKeyPath = keyPath;
}

/*!
    @brief Returns the key path for the subrows.
    @return The key path for the subrows.
    @discussion The default value is @"subrows".
    The key path is used to get the nested rows in the “rows” binding. The corresponding property should be an ordered to-many relationship containing additional bound row objects.
    @see setSubrowsKeyPath:
*/
- (CPString)subrowsKeyPath
{
    return _subrowsArrayKeyPath;
}

/*!
    @brief Sets the key path for the subrows.
    @param keyPath The key path for the subrows.
    @see subrowsKeyPath
*/
- (void)setSubrowsKeyPath:(CPString)keyPath
{
    if (_subrowsArrayKeyPath !== keyPath)
        _subrowsArrayKeyPath = keyPath;
}

/*!
    @brief Returns the criteria key path.
    @return The criteria key path.
    @discussion The default value is @"criteria".
    The key path is used to get the criteria for a row in the "rows" binding. The criteria objects are what the delegate returns from -#ruleEditor:child:forCriterion:withRowType: . The corresponding property should be an ordered to-many relationship.
    @see setCriteriaKeyPath:
*/
- (CPString)criteriaKeyPath
{
    return _itemsKeyPath;
}

/*!
    @brief Sets the key path for the criteria.
    @param keyPath The key path for the criteria.
    @see criteriaKeyPath
*/
- (void)setCriteriaKeyPath:(CPString)keyPath
{
    if (_itemsKeyPath !== keyPath)
        _itemsKeyPath = keyPath;
}

/*!
    @brief Returns the display values key path.
    @return The display values key path.
    @discussion The default is @"displayValues".
    The key path is used to get the display values for a row in the "rows" binding. The display values are what the delegate returns from -#ruleEditor:displayValueForCriterion:inRow: The corresponding property should be an ordered to-many relationship.
    @see setDisplayValuesKeyPath:
*/
- (CPString)displayValuesKeyPath
{
    return _valuesKeyPath;
}

/*!
    @brief Sets the key path for the display values.
    @param keyPath The key path for the the display values.
    @see displayValuesKeyPath
*/
- (void)setDisplayValuesKeyPath:(CPString)keyPath
{
    if (_valuesKeyPath !== keyPath)
        _valuesKeyPath = keyPath;
}

/*!
    @name Configuring Rows Animation
*/

/*!
    @brief Returns the current animation for the receiver.
    @return The current animation for the receiver.
    @see setAnimation:
*/
- (id)animation
{
    return _currentAnimation;
}

/*!
    @brief Sets the current animation for the receiver.
    @param animation A CPViewAnimation object used to animate rows.
    @discussion The default is a CPViewAnimation with a @c 0.5s duration and a @c CPAnimationEaseInOut curve.
    @see animation
*/
- (void)setAnimation:(CPViewAnimation)animation
{
    _currentAnimation = animation;
    [_currentAnimation setDelegate:self];
}

/*!
    @name Delegate Methods
*/

/*!
    @param editor The rule editor that sent the message.
    @param index The index of the requested child criterion. This value must be in the range from 0 up to (but not including) the number of children, as reported by the delegate in ruleEditor:numberOfChildrenForCriterion:withRowType:.
    @param criterion The parent of the requested child, or nil if the rule editor is requesting a root criterion.
    @param rowType The type of the row.
    @return An object representing the requested child (or root) criterion. This object is used by the delegate to represent that position in the tree, and is passed as a parameter in subsequent calls to the delegate.
    @discussion This method is required.

    - (id)ruleEditor:(CPRuleEditor)editor child:(CPInteger)index forCriterion:(id)criterion withRowType:(CPRuleEditorRowType)rowType
*/

/*!
    @param editor The rule editor that sent the message.
    @param criterion The criterion for which the value is required.
    @param row The row number of criterion.
    @return The value for criterion.
    @discussion The value should be an instance of CPString, CPView, or CPMenuItem. If the value is a CPView or CPMenuItem, you must ensure it is unique for every invocation of this method; that is, do not return a particular instance of CPView or CPMenuItem more than once.

    - (id)ruleEditor:(CPRuleEditor)editor displayValueForCriterion:(id)criterion inRow:(CPInteger)row
*/

/*!
    @param editor The rule editor that sent the message.
    @param criterion The criterion for which the number of children is required.
    @param rowType The type of row of criterion.
    @return The number of child items of criterion. If criterion is nil, return the number of root criteria for the row type rowType.

    - (CPInteger)ruleEditor:(CPRuleEditor)editor numberOfChildrenForCriterion:(id)criterion withRowType:(CPRuleEditorRowType)rowType
*/

/*!
    @param editor The rule editor that sent the message.
    @param criterion The criterion for which the predicate parts are required.
    @param value The display value.
    @param row The row number of criterion.
    @return A dictionary representing the parts of the predicate determined by the given criterion and value. The keys of the dictionary should be the string constants specified in Predicate Part Keys with corresponding appropriate values.

    - (CPDictionary)ruleEditor:(CPRuleEditor)editor predicatePartsForCriterion:(id)criterion withDisplayValue:(id)value inRow:(CPInteger)row
*/

/*! @cond */
- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)keyDown:(CPEvent)event
{
    if (!_suppressKeyDownHandling && [self _applicableNestingMode] === CPRuleEditorNestingModeCompound && !_isKeyDown && ([event modifierFlags] & CPAlternateKeyMask))
    {
        [_slices makeObjectsPerformSelector:@selector(_configurePlusButtonByRowType:) withObject:CPRuleEditorRowTypeCompound];
    }

    _isKeyDown = YES;
}

- (void)keyUp:(CPEvent)event
{
    if (!_suppressKeyDownHandling)
    {
        [_slices makeObjectsPerformSelector:@selector(_configurePlusButtonByRowType:) withObject:CPRuleEditorRowTypeSimple];
    }

    _isKeyDown = NO;
}

- (_CPRuleEditorViewSliceDropSeparator)_createSliceDropSeparator
{
    var view = [[_CPRuleEditorViewSliceDropSeparator alloc] initWithFrame:CGRectMake(0, -10, [self frame].size.width, 2)];
    [view setAutoresizingMask:CPViewWidthSizable];
    return view;
}

- (BOOL)_suppressKeyDownHandling
{
    return _suppressKeyDownHandling;
}

- (BOOL)_wantsRowAnimations
{
    return (_currentAnimation !== nil);
}

- (void)_updateButtonVisibilities
{
    [_slices makeObjectsPerformSelector:@selector(_updateButtonVisibilities)];
}

- (float)_alignmentGridWidth
{
    return  _alignmentGridWidth;
}

- (float)_minimumFrameHeight
{
    return 26.;
}

- (CPRuleEditorNestingMode)_applicableNestingMode
{
    if (!_nestingModeDidChange)
        return _nestingMode;

    var a = (_nestingMode === CPRuleEditorNestingModeCompound || _nestingMode === CPRuleEditorNestingModeSimple),
        b = ([self rowTypeForRow:0] === CPRuleEditorRowTypeCompound);

    if (a === b)
        return _nestingMode;

    return a ? CPRuleEditorNestingModeList : CPRuleEditorNestingModeSimple;
}

- (BOOL)_shouldHideAddButtonForSlice:(id)slice
{
    return (!_editable || [self _applicableNestingMode] === CPRuleEditorNestingModeSingle);
}

- (BOOL)_shouldHideSubtractButtonForSlice:(id)slice
{
    if (!_editable)
        return YES;

    if (!_disallowEmpty)
        return NO;

    var shouldHide,
        rowIndex = [slice rowIndex],
        parentIndex = [self parentRowForRow:rowIndex],
        subrowsIndexes = [self subrowIndexesForRow:parentIndex],
        nestingMode = [self _applicableNestingMode];

    switch (nestingMode)
    {
        case CPRuleEditorNestingModeCompound:
        case CPRuleEditorNestingModeSimple: shouldHide = ([subrowsIndexes count] === 1 && !_allowsEmptyCompoundRows) || parentIndex === -1;
                break;
        case CPRuleEditorNestingModeList: shouldHide = ([self numberOfRows] === 1);
                break;
        case CPRuleEditorNestingModeSingle: shouldHide = YES;
                break;
        default: shouldHide = NO;
    }

    return shouldHide;
}

#pragma mark Rows management

- (id)_rowCacheForIndex:(int)index
{
    return [_rowCache objectAtIndex:index];
}

- (id)_searchCacheForRowObject:(id)rowObject
{
    var count = [_rowCache count],
        i;

    for (i = 0; i < count; i++)
    {
         var cache = _rowCache[i];
         if ([cache rowObject] === rowObject)
              return cache;
    }

    return nil;
}

- (int)_rowIndexForRowObject:(id)rowobject
{
    if (rowobject === _boundArrayOwner)
        return -1;

    return [[self _searchCacheForRowObject:rowobject] rowIndex]; // Pas bon car le rowIndex du row cache n'est pas synchro avec la position dans _rowCache.
}

- (CPMutableArray)_subrowObjectsOfObject:(id)object
{
    if (object === _boundArrayOwner)
        return [self _rootRowsArray];

    return [object mutableArrayValueForKey:_subrowsArrayKeyPath];
}

- (CPIndexSet)_childlessParentsIfSlicesWereDeletedAtIndexes:(id)indexes
{
    var childlessParents = [CPIndexSet indexSet],
        current_index = [indexes firstIndex];

    while (current_index !== CPNotFound)
    {
        var parentIndex = [self parentRowForRow:current_index],
            subrowsIndexes = [self subrowIndexesForRow:parentIndex];

        if ([subrowsIndexes count] === 1)
        {
            if (parentIndex !== -1)
                return [CPIndexSet indexSetWithIndex:0];

            var childlessGranPa = [self _childlessParentsIfSlicesWereDeletedAtIndexes:[CPIndexSet indexSetWithIndex:parentIndex]];
            [childlessParents addIndexes:childlessGranPa];
        }

        current_index = [indexes indexGreaterThanIndex:current_index];
    }

    return childlessParents;
    // (id)-[RuleEditor _includeSubslicesForSlicesAtIndexes:]
}

- (CPIndexSet)_includeSubslicesForSlicesAtIndexes:(CPIndexSet)indexes
{
    var subindexes = [indexes copy],
        current_index = [indexes firstIndex];

    while (current_index !== CPNotFound)
    {
        var sub = [self subrowIndexesForRow:current_index];
        [subindexes addIndexes:[self _includeSubslicesForSlicesAtIndexes:sub]];
        current_index = [indexes indexGreaterThanIndex:current_index];
    }

    return subindexes;
}

- (void)_deleteSlice:(id)slice
{
    var rowindexes = [CPIndexSet indexSetWithIndex:[slice rowIndex]];

    if (!_allowsEmptyCompoundRows)
    {
        var childlessIndexes = [self _childlessParentsIfSlicesWereDeletedAtIndexes:rowindexes];
        if ([childlessIndexes count] > 0)
            rowindexes = childlessIndexes;
    }

    [self removeRowsAtIndexes:rowindexes includeSubrows:YES];

    [self _updatePredicate];
    [self _sendRuleAction];
    [self _postRuleOptionChangedNotification];
    [self _postRowCountChangedNotificationOfType:CPRuleEditorRowsDidChangeNotification indexes:rowindexes];
}

- (CPArray)_rootRowsArray
{
    return [_boundArrayOwner mutableArrayValueForKey:_boundArrayKeyPath];
}

- (BOOL)_nextUnusedItems:(CPArray)items andValues:(CPArray)values forRow:(int)rowIndex forRowType:(unsigned int)type
{
    var parentItem = [items lastObject], // if empty items array, this is NULL aka the root item;
        childrenCount = [self _queryNumberOfChildrenOfItem:parentItem withRowType:type],
        foundIndex = CPNotFound;

    if (childrenCount === 0)
        return NO;

    var current_criterions = [CPMutableArray array],
        count = [self numberOfRows],
        row;

    for (row = 0; row < count; row++) // num of rows should be num of siblings of parentItem
    {
        var aCriteria = [self criteriaForRow:row],
            itemIndex = [items count];

        if ([self rowTypeForRow:row] === type && itemIndex < [aCriteria count])
        {
            var crit = [aCriteria objectAtIndex:itemIndex];
            [current_criterions addObject:crit];
        }
    }

    while (foundIndex === CPNotFound)
    {
        var buffer = [CPMutableArray arrayWithArray:current_criterions],
            i;
        for (i = 0; i < childrenCount; i++)
        {
            var child =  [self _queryChild:i ofItem:parentItem withRowType:type];
            if ([current_criterions indexOfObject:child] === CPNotFound)
            {
                foundIndex = i;
                break;
            }
        }

        if (foundIndex === CPNotFound)
        {
            for (var k = 0; k < childrenCount; k++)
            {
                var anobject = [self _queryChild:k ofItem:parentItem withRowType:type],
                    index = [buffer indexOfObject:anobject];
                if (index !== CPNotFound)
                    [buffer removeObjectAtIndex:index];
            }

            current_criterions = buffer;
        }
    }

    var foundItem = [self _queryChild:foundIndex ofItem:parentItem withRowType:type],
        foundValue = [self _queryValueForItem:foundItem inRow:rowIndex];

    [items addObject:foundItem];
    [values addObject:foundValue];

    return YES;
}

- (CPMutableArray)_getItemsAndValuesToAddForRow:(int)rowIndex ofType:(CPRuleEditorRowType)type
{
    //var cachedItemsAndValues = _itemsAndValuesToAddForRowType[type];
    //if (cachedItemsAndValues)
    //    return cachedItemsAndValues;

    var itemsAndValues = [CPMutableArray array],
        items = [CPMutableArray array],
        values = [CPMutableArray array],
        unusedItems = YES;

    while (unusedItems)
        unusedItems = [self _nextUnusedItems:items andValues:values forRow:rowIndex forRowType:type];

    var count = [items count];

    for (var i = 0; i < count; i++)
    {
        var item = [items objectAtIndex:i],
            value = [values objectAtIndex:i],
            itemAndValue = @{
                    "item": item,
                    "value": value,
                };

        [itemsAndValues addObject:itemAndValue];
    }

    return itemsAndValues;
}

- (void)_addOptionFromSlice:(id)slice ofRowType:(unsigned int)type
{
    // for CPRuleEditorNestingModeSimple only

    var rowIndexEvent = [slice rowIndex],
        rowTypeEvent = [self rowTypeForRow:rowIndexEvent],
        insertIndex = rowIndexEvent + 1,
        parentRowIndex = (rowTypeEvent === CPRuleEditorRowTypeCompound) ? rowIndexEvent:[self parentRowForRow:rowIndexEvent];

    [self insertRowAtIndex:insertIndex withType:type asSubrowOfRow:parentRowIndex animate:YES];
}

- (id)_insertNewRowAtIndex:(int)insertIndex ofType:(CPRuleEditorRowType)rowtype withParentRow:(int)parentRowIndex
{
    var row = [[[self rowClass] alloc] init],
        itemsandvalues = [self _getItemsAndValuesToAddForRow:insertIndex ofType:rowtype],
        newitems = [itemsandvalues valueForKey:@"item"],
        newvalues = [itemsandvalues valueForKey:@"value"];

    [row setValue:newitems forKey:_itemsKeyPath];
    [row setValue:newvalues forKey:_valuesKeyPath];
    [row setValue:rowtype forKey:_typeKeyPath];
    [row setValue:[CPMutableArray array] forKey:_subrowsArrayKeyPath];

    var subrowsObjects;
    if (parentRowIndex === -1 || [self _applicableNestingMode] === CPRuleEditorNestingModeList)
        subrowsObjects = [self _rootRowsArray];
    else
    {
        var parentRowObject = [[self _rowCacheForIndex:parentRowIndex] rowObject];
        subrowsObjects = [self _subrowObjectsOfObject:parentRowObject];
    }

    var relInsertIndex = insertIndex - parentRowIndex - 1;
    [subrowsObjects insertObject:row atIndex:relInsertIndex];

    [self _updatePredicate];
    [self _sendRuleAction];
    [self _postRuleOptionChangedNotification];
    [self _postRowCountChangedNotificationOfType:CPRuleEditorRowsDidChangeNotification indexes:[CPIndexSet indexSetWithIndex:insertIndex]];

    return row;
}

#pragma mark Key value observing

- (void)_startObservingRowObjectsRecursively:(CPArray)rowObjects
{
    [_boundArrayOwner addObserver:self forKeyPath:_boundArrayKeyPath options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew context:boundArrayContext];

    var count = [rowObjects count];

    for (var i = 0; i < count; i++)
    {
        var rowObject = [rowObjects objectAtIndex:i];

        [rowObject addObserver:self forKeyPath:_itemsKeyPath options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew context:itemsContext];
        [rowObject addObserver:self forKeyPath:_valuesKeyPath options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew context:valuesContext];
        [rowObject addObserver:self forKeyPath:_subrowsArrayKeyPath options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew context:subrowsContext];

        var subrows = [self _subrowObjectsOfObject:rowObject];
        if ([subrows count] > 0)
            [self _startObservingRowObjectsRecursively:subrows];
    }
    // ORIG IMPL : calls +keyPathsForValuesAffectingValueForKey: for all keys
}

- (void)_stopObservingRowObjectsRecursively:(CPArray)rowObjects
{
    [_boundArrayOwner removeObserver:self forKeyPath:_boundArrayKeyPath];

    var count = [rowObjects count];

    for (var i = 0; i < count; i++)
    {
        var rowObject = [rowObjects objectAtIndex:i];
        [rowObject removeObserver:self forKeyPath:_itemsKeyPath];
        [rowObject removeObserver:self forKeyPath:_valuesKeyPath];
        [rowObject removeObserver:self forKeyPath:_subrowsArrayKeyPath];

        var subrows = [rowObject valueForKey:_subrowsArrayKeyPath];
        if ([subrows count] > 0)
            [self _stopObservingRowObjectsRecursively:subrows];
    }
}

- (void)observeValueForKeyPath:(CPString)keypath ofObject:(id)object change:(CPDictionary)change context:(void)context
{
    var changeKind = [change objectForKey:CPKeyValueChangeKindKey],
        changeNewValue = [change objectForKey:CPKeyValueChangeNewKey],
        changeOldValue = [change objectForKey:CPKeyValueChangeOldKey],
        newRows,
        oldRows;

    if (context === boundArrayContext || context === subrowsContext)
    {
        if (changeKind === CPKeyValueChangeSetting)
        {
            newRows = changeNewValue;
            oldRows = changeOldValue;

        }
        else if (changeKind === CPKeyValueChangeInsertion)
        {
            newRows = [self _subrowObjectsOfObject:object];
            oldRows = [CPArray arrayWithArray:newRows];
            [oldRows removeObjectsInArray:changeNewValue];
        }

        [self _changedRowArray:newRows withOldRowArray:oldRows forParent:object];
        [self _reconfigureSubviewsAnimate:[self _wantsRowAnimations]];
    }
}

- (void)_changedItem:(id)fromItem toItem:(id)toItem inRow:(int)aRow atCriteriaIndex:(int)fromItemIndex
{
    var criteria = [self criteriaForRow:aRow],
        displayValues = [self displayValuesForRow:aRow],
        rowType = [self rowTypeForRow:aRow],
        anItem = toItem,

        items = [criteria subarrayWithRange:CPMakeRange(0, fromItemIndex)],
        values = [displayValues subarrayWithRange:CPMakeRange(0, fromItemIndex)];

    _lastRow = aRow;

    while (YES)
    {
        [items addObject:anItem];
        var value = [self _queryValueForItem:anItem inRow:aRow];
        [values addObject:value];

        if (![self _queryNumberOfChildrenOfItem:anItem withRowType:rowType])
            break;

        anItem = [self _queryChild:0 ofItem:anItem withRowType:rowType];
    }

    var object = [[self _rowCacheForIndex:aRow] rowObject];
    [object setValue:items forKey:_itemsKeyPath];
    [object setValue:values forKey:_valuesKeyPath];

    var slice = [_slices objectAtIndex:aRow];
    [slice _reconfigureSubviews];

    [self _updatePredicate];
    [self _sendRuleAction];
    [self _postRuleOptionChangedNotification];
}

- (void)_changedRowArray:(CPArray)newRows withOldRowArray:(CPArray)oldRows forParent:(id)parentRowObject
{
    var newRowCount = [newRows count],
        oldRowCount = [oldRows count],
        deltaCount = newRowCount - oldRowCount,
        minusCount = MIN(newRowCount, oldRowCount),
        maxCount = MAX(newRowCount, oldRowCount),

        insertCacheIndexes = [CPIndexSet indexSet],
        newCaches = [CPArray array],

        parentCacheIndentation,
        parentCacheIndex = [self _rowIndexForRowObject:parentRowObject],

        newRowCacheIndex = 0,
        changeStartIndex = 0;

    [self _stopObservingRowObjectsRecursively:oldRows];
    [self _startObservingRowObjectsRecursively:newRows];

    //var gindexes = [self _globalIndexesForSubrowIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0,oldRowCount)] ofParentObject:parentRowObject];

    if (parentCacheIndex === -1)
        parentCacheIndentation = -1;
    else
        parentCacheIndentation = [[self _rowCacheForIndex:parentCacheIndex] indentation];

    for (; newRowCacheIndex < newRowCount; newRowCacheIndex++)
    {
        var newCacheGlobalIndex = (parentCacheIndex + 1) + newRowCacheIndex,
            obj = [newRows objectAtIndex:newRowCacheIndex],
            newRowType = [obj valueForKey:_typeKeyPath],
            cache = [[_CPRuleEditorCache alloc] init];

        [cache setRowObject:obj];
        [cache setRowIndex:newCacheGlobalIndex];
        [cache setIndentation:parentCacheIndentation + 1];

        [insertCacheIndexes addIndex:newCacheGlobalIndex];
        [newCaches addObject:cache];
    }

    //var lastCacheIndex = [self _rowIndexForRowObject:[oldRows lastObject]];
    [_rowCache removeObjectsInRange:CPMakeRange(parentCacheIndex + 1, [oldRows count])];
    [_rowCache insertObjects:newCaches atIndexes:insertCacheIndexes];

    for (; changeStartIndex < minusCount; changeStartIndex++)
    {
        var oldrow = [oldRows objectAtIndex:changeStartIndex],
            newrow = [newRows objectAtIndex:changeStartIndex];

        if (newrow !== oldrow)
            break;
    }

    var replaceCount = (deltaCount === 0) ? maxCount : maxCount - minusCount,
        startIndex = parentCacheIndex + changeStartIndex + 1;

    if (deltaCount <= 0)
    {
        var removeIndexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(startIndex, replaceCount)],
            removeSlices = [_slices objectsAtIndexes:removeIndexes];

        [removeSlices makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_slices removeObjectsAtIndexes:removeIndexes];
    }

    if (deltaCount >= 0)
    {
        var newIndentation = parentCacheIndentation + 1,
            newIndex = startIndex;

        for (; newIndex < startIndex + replaceCount; newIndex++)
        {
            var newslice = [self _newSlice],
                rowType = [self rowTypeForRow:newIndex];

            [newslice setRowIndex:newIndex];
            [newslice setIndentation:newIndentation];
            [newslice _setRowType:rowType];
            [newslice _configurePlusButtonByRowType:CPRuleEditorRowTypeSimple];

            [_slices insertObject:newslice atIndex:newIndex];
        }
    }

    var emptyArray = [CPArray array],
        count = [oldRows count],
        n;
    for (n = 0; n < count; n++)
    {
        var oldRow = [oldRows objectAtIndex:n],
            subOldRows = [self _subrowObjectsOfObject:oldRow];

        if ([subOldRows count] > 0)
            [self _changedRowArray:emptyArray withOldRowArray:subOldRows forParent:oldRow];
    }

    count = [newRows count];
    for (n = 0; n < count; n++)
    {
        var newRow = [newRows objectAtIndex:n],
            subnewRows = [self _subrowObjectsOfObject:newRow];

        if ([subnewRows count] > 0)
            [self _changedRowArray:subnewRows withOldRowArray:emptyArray forParent:newRow];
    }
}

- (void)bind:(CPString)aBinding toObject:(id)observableController withKeyPath:(CPString)aKeyPath options:(CPDictionary)options
{
  if ([aBinding isEqualToString:@"rows"])
  {
    [self unbind:aBinding];
    [self _setBoundDataSource:observableController withKeyPath:aKeyPath options:options];

    [_rowCache removeAllObjects];
    [_slices removeAllObjects];

    var newRows = [CPArray array],
        oldRows = [self _rootRowsArray];

    [self _changedRowArray:newRows withOldRowArray:oldRows forParent:_boundArrayOwner];
  }
  else
    [super bind:aBinding toObject:observableController withKeyPath:aKeyPath options:options];
}

- (void)unbind:(id)object
{
    _rowClass = [_CPRuleEditorRowObject class];
    [super unbind:object];
}

- (void)_setBoundDataSource:(id)datasource withKeyPath:(CPString)keyPath options:(CPDictionary)options
{
    if ([datasource respondsToSelector:@selector(objectClass)])
        _rowClass = [datasource objectClass];

    _boundArrayKeyPath = keyPath;
    _boundArrayOwner = datasource;

    //var boundRows = [_boundArrayOwner valueForKey:_boundArrayKeyPath];

    [_boundArrayOwner addObserver:self forKeyPath:_boundArrayKeyPath options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew context:boundArrayContext];

    //if ([boundRows isKindOfClass:[CPArray class]] && [boundRows count] > 0)
    //    [_boundArrayOwner setValue:boundRows forKey:_boundArrayKeyPath];
}

- (void)_setPredicate:(CPPredicate)predicate
{
    if (_predicate !== predicate)
        _predicate = predicate;
}

- (void)_updatePredicate
{
    if (_delegateWantsValidation)
    {
        var selector = @selector(ruleEditor:predicatePartsForCriterion:withDisplayValue:inRow:);
        if (![_ruleDelegate respondsToSelector:selector])
            return;

        _delegateWantsValidation = NO;
    }

    var subpredicates = [CPMutableArray array],
        subindexes = [self subrowIndexesForRow:-1],
        current_index = [subindexes firstIndex];

    while (current_index !== CPNotFound)
    {
        var subpredicate = [self predicateForRow:current_index];

        if (subpredicate !== nil)
            [subpredicates addObject:subpredicate];

        current_index = [subindexes indexGreaterThanIndex:current_index];
    }

    var new_predicate = [[CPCompoundPredicate alloc] initWithType:CPOrPredicateType subpredicates:subpredicates];

    [self _setPredicate:new_predicate];
}

- (_CPRuleEditorViewSliceRow)_newSlice
{
    var sliceRect = CGRectMake(0, 0, CGRectGetWidth([self frame]), 0),
        slice = [self _createNewSliceWithFrame:sliceRect ruleEditorView:self];

    return slice;
}

- (_CPRuleEditorViewSliceRow)_createNewSliceWithFrame:(CGRect)frame ruleEditorView:(CPRuleEditor)editor
{
    return [[_CPRuleEditorViewSliceRow alloc] initWithFrame:frame ruleEditorView:editor];
}

- (void)_reconfigureSubviewsAnimate:(BOOL)animate
{
    var viewAnimations = [CPMutableArray array],
        added_slices = [CPMutableArray array],
        count = [_slices count];

    [self _updateSliceRows];

    if ([[self superview] isKindOfClass:[CPClipView class]])
        [self setFrameSize:CGSizeMake(CGRectGetWidth([self frame]), count * _sliceHeight)];

    for (var i = 0; i < count; i++)
    {
        var aslice = [_slices objectAtIndex:i],
            targetRect = [aslice _animationTargetRect],
            startRect = [aslice frame],
            startIndex = [aslice rowIndex] - 1;

        if ([aslice superview] === nil)
        {
            startRect = CGRectMake(0, startIndex * _sliceHeight, CGRectGetWidth(startRect), _sliceHeight);
            [aslice _reconfigureSubviews];
            [added_slices addObject:aslice];
        }

        if (animate)
        {
            var animation = @{};
            [animation setObject:aslice forKey:CPViewAnimationTargetKey];
            [animation setObject:startRect forKey:CPViewAnimationStartFrameKey];
            [animation setObject:targetRect forKey:CPViewAnimationEndFrameKey];

            [viewAnimations insertObject:animation atIndex:0];
        }
        else
            [aslice setFrame:targetRect];
    }

    var addcount = [added_slices count];
    for (var i = 0; i < addcount; i++)
        [_slicesHolder addSubview:added_slices[i] positioned:CPWindowBelow relativeTo:nil];

    if (animate)
    {
        [_currentAnimation setViewAnimations:viewAnimations];
        [_currentAnimation startAnimation];
    }

    _lastRow = [self numberOfRows] - 1;

    if (_lastRow === -1)
        _nestingModeDidChange = NO;

    [self setNeedsDisplay:YES];
    [_slices makeObjectsPerformSelector:@selector(_updateButtonVisibilities)];
}

- (void)animationDidEnd:(CPViewAnimation)animation
{
//  var nextSimple = [self _getItemsAndValuesToAddForRow:0 ofType:CPRuleEditorRowTypeSimple],
//      nextCompound = [self _getItemsAndValuesToAddForRow:0 ofType:CPRuleEditorRowTypeCompound];

//  _itemsAndValuesToAddForRowType = {CPRuleEditorRowTypeSimple:nextSimple, CPRuleEditorRowTypeCompound:nextCompound};
}

- (void)_updateSliceRows
{
    var width =  [self frame].size.width,
        count = [_slices count];

    for (var i = 0; i < count; i++)
    {
        var slice = [_slices objectAtIndex:i],
            targetRect = CGRectMake(0, i * _sliceHeight, width, _sliceHeight);

        [slice setRowIndex:i];
        [slice _setAnimationTargetRect:targetRect];
    }
}

- (CPArray)_backgroundColors
{
    return [self valueForThemeAttribute:@"alternating-row-colors"];
}

- (CPColor)_selectedRowColor
{
    return [self valueForThemeAttribute:@"selected-color"];
}

- (CPColor)_sliceTopBorderColor
{
    return [self valueForThemeAttribute:@"slice-top-border-color"];
}

- (CPColor)_sliceBottomBorderColor
{
    return [self valueForThemeAttribute:@"slice-bottom-border-color"];
}

- (CPColor)_sliceLastBottomBorderColor
{
    return [self valueForThemeAttribute:@"slice-last-bottom-border-color"];
}

- (CPFont)font
{
    return [self valueForThemeAttribute:@"font"];
}

- (CPImage)_addImage
{
    return [self valueForThemeAttribute:@"add-image"];
}

- (CPImage)_removeImage
{
    return [self valueForThemeAttribute:@"remove-image"];
}

- (CPString)_toolTipForAddCompoundRowButton
{
    return [_standardLocalizer localizedStringForString:@"Add compound row"];
}

- (CPString)_toolTipForAddSimpleRowButton
{
    return [_standardLocalizer localizedStringForString:@"Add row"];
}

- (CPString)_toolTipForDeleteRowButton
{
    return [_standardLocalizer localizedStringForString:@"Delete row"];
}

- (void)_updateSliceIndentations
{
    [self _updateSliceIndentationAtIndex:0 toIndentation:0 withIndexSet:[self subrowIndexesForRow:0]];
}

- (void)_updateSliceIndentationAtIndex:(int)index toIndentation:(int)indentation withIndexSet:(id)indexes
{
    var current_index = [indexes firstIndex];

    while (current_index !== CPNotFound)
    {
        var subindexes = [self subrowIndexesForRow:index];
        [self _updateSliceIndentationAtIndex:current_index toIndentation:indentation + 1 withIndexSet:subindexes];
        current_index = [indexes indexGreaterThanIndex:current_index];
    }

    [[_slices objectAtIndex:index] setIndentation:indentation];
}

- (CPArray)_selectedSlices
{
    var _selectedSlices = [CPMutableArray array],
        count = [_slices count],
        i;

    for (i = 0; i < count; i++)
    {
        var slice = _slices[i];
        if ([slice _isSelected])
            [_selectedSlices addObject:slice];
    }

    return _selectedSlices;
}

- (int)_lastSelectedSliceIndex
{
    var lastIndex = -1,
        count = [_slices count],
        i;

    for (i = 0; i < count; i++)
    {
         var slice = _slices[i];
         if ([slice _isLastSelected])
            return [slice rowIndex];
    }

    return CPNotFound;
}

- (void)_mouseUpOnSlice:(id)slice withEvent:(CPEvent)event
{
    if ([slice _rowType] !== CPRuleEditorRowTypeSimple)
        return;

    var modifierFlags = [event modifierFlags],
        extend = (modifierFlags & CPCommandKeyMask) || (modifierFlags & CPShiftKeyMask),
        rowIndexes = [CPIndexSet indexSetWithIndex:[slice rowIndex]];

    [self selectRowIndexes:rowIndexes byExtendingSelection:extend];
}

- (void)_mouseDownOnSlice:(id)slice withEvent:(CPEvent)event
{
}

- (void)_rightMouseDownOnSlice:(_CPRuleEditorViewSlice)slice withEvent:(CPEvent)event
{
}

- (void)_performClickOnSlice:(id)slice withEvent:(CPEvent)event
{
}

- (void)_setSuppressKeyDownHandling:(BOOL)flag
{
    _suppressKeyDownHandling = flag;
}

- (void)selectAll:(id)sender
{
    var count = [_slices count];

    while (count--)
    {
        var slice = _slices[count];
        [slice _setSelected:YES];
        [slice setNeedsDisplay:YES];
    }
}

- (void)_deselectAll
{
    var count = [_slices count];

    while (count--)
    {
        var slice = _slices[count];
        [slice _setSelected:NO];
        [slice _setLastSelected:NO];
        [slice setNeedsDisplay:YES];
    }
}

- (int)_queryNumberOfChildrenOfItem:(id)item withRowType:(CPRuleEditorRowType)type
{
    return [_ruleDelegate ruleEditor:self numberOfChildrenForCriterion:item withRowType:type];
}

- (id)_queryChild:(int)childIndex ofItem:(id)item withRowType:(CPRuleEditorRowType)type
{
    return [_ruleDelegate ruleEditor:self child:childIndex forCriterion:item withRowType:type];
}

- (id)_queryValueForItem:(id)item inRow:(int)row
{
    return [_ruleDelegate ruleEditor:self displayValueForCriterion:item inRow:row];
}

- (int)_lastRow
{
    return _lastRow;
}

- (int)_countOfRowsStartingAtObject:(id)object
{
    var index = [self _rowIndexForRowObject:object];
    return ([self numberOfRows] - index);
}

- (void)_setAlignmentGridWidth:(float)width
{
    _alignmentGridWidth = width;
}

- (BOOL)_validateItem:(id)item value:(id)value inRow:(int)row
{
    return [self _queryCanSelectItem:item displayValue:value inRow:row];
}

- (BOOL)_queryCanSelectItem:(id)item displayValue:(id)value inRow:(int)row
{
    return YES;
}

- (void)_windowChangedKeyState
{
    [self setNeedsDisplay:YES];
}

- (void)setNeedsDisplay:(BOOL)flag
{
    [_slices makeObjectsPerformSelector:@selector(setNeedsDisplay:) withObject:flag];
    [super setNeedsDisplay:flag];
}

- (void)setFrameSize:(CGSize)size
{
    [self setNeedsDisplay:YES];

    if (CGRectGetWidth([self frame]) !== size.width)
        [_slices makeObjectsPerformSelector:@selector(setNeedsLayout)];

    [super setFrameSize:size];
}

- (CPIndexSet)_selectedSliceIndices
{
    var selectedIndices = [CPMutableIndexSet indexSet],
        count = [_slices count],
        i;

    for (i = 0; i < count; i++)
    {
        var slice = _slices[i];
        if ([slice _isSelected])
            [selectedIndices addIndex:[slice rowIndex]];
    }

    return selectedIndices;
}

- (void)mouseDragged:(CPEvent)event
{
    if (!_editable)
        return;

    var point = [self convertPoint:[event locationInWindow] fromView:nil],
        view = [_slices objectAtIndex:FLOOR(point.y / _sliceHeight)];

    if ([self _dragShouldBeginFromMouseDown:view])
        [self _performDragForSlice:view withEvent:event];
}

- (BOOL)_dragShouldBeginFromMouseDown:(CPView)view
{
    return (([self nestingMode] === CPRuleEditorNestingModeList ||  [view rowIndex] !== 0) && _editable && [view isKindOfClass:[_CPRuleEditorViewSliceRow class]] && _draggingRows === nil);
}

- (BOOL)_performDragForSlice:(id)slice withEvent:(CPEvent)event
{
    var dragPoint,
        mainRowIndex = [slice rowIndex],
        draggingRows = [CPIndexSet indexSetWithIndex:mainRowIndex],
        selected_indices = [self _selectedSliceIndices],
        pasteboard = [CPPasteboard pasteboardWithName:CPDragPboard];

    [pasteboard declareTypes:[CPArray arrayWithObjects:CPRuleEditorItemPBoardType, nil] owner: self];

    if ([selected_indices containsIndex:mainRowIndex])
        [draggingRows addIndexes:selected_indices];
    _draggingRows = [self _includeSubslicesForSlicesAtIndexes:draggingRows];

    var firstIndex = [_draggingRows firstIndex],
        firstSlice = [_slices objectAtIndex:firstIndex],
        dragview = [[CPView alloc] initWithFrame:[firstSlice frame]];

#if PLATFORM(DOM)
    var html = firstSlice._DOMElement.innerHTML;
    dragview._DOMElement.innerHTML = [html copy];
#endif
    [dragview setBackgroundColor:[firstSlice backgroundColor]];
    [dragview setAlphaValue:0.7];

    dragPoint = CGPointMake(0, firstIndex * _sliceHeight);

    [self dragView:dragview
                at:dragPoint
            offset:CGSizeMake(0, _sliceHeight)
             event:event
        pasteboard:pasteboard
            source:self
         slideBack:YES];

    return YES;
}

- (CPDragOperation)draggingEntered:(id < CPDraggingInfo >)sender
{
    if ([sender draggingSource] === self)
    {
        [self _clearDropLine];
        return CPDragOperationMove;
    }

    return CPDragOperationNone;
}

- (void)draggingExited:(id)sender
{
    [self _clearDropLine];
    [self setNeedsDisplay:YES];
}

- (void)_clearDropLine
{
    [_dropLineView setAlphaValue:0];

    if (_subviewIndexOfDropLine !== CPNotFound && _subviewIndexOfDropLine < _lastRow)
    {
        var previousBelowSlice = [_slices objectAtIndex:_subviewIndexOfDropLine];
        [previousBelowSlice setFrameOrigin:CGPointMake(0, [previousBelowSlice rowIndex] * _sliceHeight)];
    }

    _subviewIndexOfDropLine = CPNotFound;
}

- (CPDragOperation)draggingUpdated:(id <CPDraggingInfo>)sender
{
    var point = [self convertPoint:[sender draggingLocation] fromView:nil],
        y = point.y + _sliceHeight / 2,
        indexOfDropLine =  FLOOR(y / _sliceHeight),
        numberOfRows = [self numberOfRows];

    if (indexOfDropLine < 0 || indexOfDropLine > numberOfRows || (indexOfDropLine >= [_draggingRows firstIndex] && indexOfDropLine <= [_draggingRows lastIndex] + 1))
    {
        if (_subviewIndexOfDropLine !== CPNotFound && indexOfDropLine !== _subviewIndexOfDropLine)
            [self _clearDropLine];
        return CPDragOperationNone;
    }

    if (_subviewIndexOfDropLine !== indexOfDropLine)
    {
        if (_subviewIndexOfDropLine !== CPNotFound && _subviewIndexOfDropLine < numberOfRows)
        {
            var previousBelowSlice = [_slices objectAtIndex:_subviewIndexOfDropLine];
            [previousBelowSlice setFrameOrigin:CGPointMake(0, [previousBelowSlice rowIndex] * _sliceHeight)];
        }

        if (indexOfDropLine <= _lastRow && indexOfDropLine < numberOfRows)
        {
            var belowSlice = [_slices objectAtIndex:indexOfDropLine];
            [belowSlice setFrameOrigin:CGPointMake(0, [belowSlice rowIndex] * _sliceHeight + 2)];
        }

        [_dropLineView setAlphaValue:1];
        [_dropLineView setFrameOrigin:CGPointMake(CGRectGetMinX([_dropLineView frame]), indexOfDropLine * _sliceHeight)];

        _subviewIndexOfDropLine = indexOfDropLine;
    }

    return CPDragOperationMove;
}

- (BOOL)prepareForDragOperation:(id < CPDraggingInfo >)sender
{
    return (_subviewIndexOfDropLine !== CPNotFound);
}

- (BOOL)performDragOperation:(id < CPDraggingInfo >)info
{
    var aboveInsertIndexCount = 0,
        object,
        removeIndex;

    var rowObjects = [_rowCache valueForKey:@"rowObject"],
        index = [_draggingRows lastIndex];

    var parentRowIndex = [self parentRowForRow:index], // first index of draggingrows
        parentRowObject = (parentRowIndex === -1) ? _boundArrayOwner : [[self _rowCacheForIndex:parentRowIndex] rowObject],
        insertIndex = _subviewIndexOfDropLine;

    while (index !== CPNotFound)
    {
        if (index >= insertIndex)
        {
            removeIndex = index + aboveInsertIndexCount;
            aboveInsertIndexCount += 1;
        }
        else
        {
            removeIndex = index;
            insertIndex -= 1;
        }

        object = [rowObjects objectAtIndex:removeIndex];
        [self removeRowAtIndex:removeIndex];
        [[self _subrowObjectsOfObject:parentRowObject] insertObject:object atIndex:insertIndex - parentRowIndex - 1];

        index = [_draggingRows indexLessThanIndex:index];
    }

    [self _clearDropLine];
    _draggingRows = nil;
    return YES;
}

- (CPIndexSet)_draggingTypes
{
    return [CPIndexSet indexSetWithIndex:CPDragOperationMove];
}

- (void)draggedView:(CPView)dragView endedAt:(CGPoint)aPoint operation:(CPDragOperation)operation
{
    _draggingRows = nil;

    [self _updatePredicate];
    [self _sendRuleAction];
    [self _postRuleOptionChangedNotification];
    [self _postRowCountChangedNotificationOfType:CPRuleEditorRowsDidChangeNotification indexes:nil]; // FIXME
}

- (BOOL)wantsPeriodicDraggingUpdates
{
    return NO;
}

- (void)pasteboard:(CPPasteboard)pasteboard provideDataForType:(int)type
{
}

- (void)_setWindow:(id)window
{
    [super _setWindow:window];
}

- (void)_windowUpdate:(id)sender
{
    [super _windowUpdate:sender];
}

- (void)_postRuleOptionChangedNotification
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPRuleEditorRulesDidChangeNotification object:self];
}

- (void)_postRowCountChangedNotificationOfType:(CPString)notificationName indexes:indexes
{
    var userInfo = indexes === nil ? @{} : @{ "indexes": indexes };
    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:userInfo];
}

- (CPIndexSet)_globalIndexesForSubrowIndexes:(CPIndexSet)indexes ofParentObject:(id)parentRowObject
{
    var _subrows = [self _subrowObjectsOfObject:parentRowObject],
        parentRowIndex = [self _rowIndexForRowObject:parentRowObject],

        globalIndexes = [CPMutableIndexSet indexSet],
        current_index = [indexes firstIndex],
        numberOfChildrenOfPreviousBrother = 0;

    while (current_index !== CPNotFound)
    {
        var globalChildIndex = current_index + parentRowIndex + 1 + numberOfChildrenOfPreviousBrother;
        [globalIndexes addIndex:globalChildIndex];

        if ([self rowTypeForRow:globalChildIndex] === CPRuleEditorRowTypeCompound)
        {
            var rowObject = [[self _rowCacheForIndex:current_index] rowObject],
                subrows = [self _subrowObjectsOfObject:rowObject],
                subIndexes = [self _globalIndexesForSubrowIndexes:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [subrows count])] ofParentObject:rowObject];

            numberOfChildrenOfPreviousBrother = [subIndexes count];
        }

        current_index = [indexes indexGreaterThanIndex:current_index];
    }

    return globalIndexes;
}

- (void)_sendRuleAction
{
    var action = [self action],
        target = [self target];

    [self sendAction:action to:target];
}

- (BOOL)_sendsActionOnIncompleteTextChange
{
    return YES;
}

- (void)_getAllAvailableItems:(id)items values:(id)values asChildrenOfItem:(id)parentItem inRow:(int)aRow
{
    var type,
        indexofCriterion,
        numOfChildren;

    var availItems = [CPMutableArray array],
        availValues = [CPMutableArray array];

    var criterion = nil,
        value = nil;

    _lastRow = aRow;
    type = [self rowTypeForRow:aRow];
    numOfChildren = [self _queryNumberOfChildrenOfItem:parentItem withRowType:type];

    var criteria = [self criteriaForRow:aRow];
    indexofCriterion = [criteria indexOfObject:criterion];

    if (parentItem !== nil
        && indexofCriterion !== CPNotFound
        && indexofCriterion < [criteria count] - 1)
    {
        var next = indexofCriterion + 1;

        criterion = [criteria objectAtIndex:next];
        var values = [self displayValuesForRow:aRow];
        value = [values objectAtIndex:next];
    }

    for (var i = 0; i < numOfChildren; ++i)
    {
        var aChild = [self _queryChild:i ofItem:parentItem withRowType:type],
            availChild = aChild,
            availValue = value;

        if (criterion !== aChild)
            availValue = [self _queryValueForItem:aChild inRow:aRow];

        if (!availValue)
            availValue = [self _queryValueForItem:availChild inRow:aRow];

        [availItems addObject:availChild];
        [availValues addObject:availValue];
    }

    [items addObjectsFromArray:availItems];
    [values addObjectsFromArray:availValues];
}

@end

var CPRuleEditorAlignmentGridWidthKey       = @"CPRuleEditorAlignmentGridWidth",
    CPRuleEditorSliceHeightKey              = @"CPRuleEditorSliceHeight",
    CPRuleEditorStringsFilenameKey          = @"CPRuleEditorStringsFilename",
    CPRuleEditorEditableKey                 = @"CPRuleEditorEditable",
    CPRuleEditorAllowsEmptyCompoundRowsKey  = @"CPRuleEditorAllowsEmptyCompoundRows",
    CPRuleEditorDisallowEmptyKey            = @"CPRuleEditorDisallowEmpty",
    CPRuleEditorNestingModeKey              = @"CPRuleEditorNestingMode",
    CPRuleEditorRowTypeKeyPathKey           = @"CPRuleEditorRowTypeKeyPath",
    CPRuleEditorItemsKeyPathKey             = @"CPRuleEditorItemsKeyPath",
    CPRuleEditorValuesKeyPathKey            = @"CPRuleEditorValuesKeyPath",
    CPRuleEditorSubrowsArrayKeyPathKey      = @"CPRuleEditorSubrowsArrayKeyPath",
    CPRuleEditorBoundArrayKeyPathKey        = @"CPRuleEditorBoundArrayKeyPath",
    CPRuleEditorRowClassKey                 = @"CPRuleEditorRowClass",
    CPRuleEditorSlicesHolderKey             = @"CPRuleEditorSlicesHolder",
    CPRuleEditorSlicesKey                   = @"CPRuleEditorSlices",
    CPRuleEditorDelegateKey                 = @"CPRuleEditorDelegate",
    CPRuleEditorBoundArrayOwnerKey          = @"CPRuleEditorBoundArrayOwner";

@implementation CPRuleEditor (CPCoding)

- (id)initWithCoder:(CPCoder)coder
{
    self = [super initWithCoder:coder];
    if (self !== nil)
    {
        [self setFormattingStringsFilename:[coder decodeObjectForKey:CPRuleEditorStringsFilenameKey]];
        _alignmentGridWidth      = [coder decodeFloatForKey:CPRuleEditorAlignmentGridWidthKey];
        _sliceHeight             = [coder decodeDoubleForKey:CPRuleEditorSliceHeightKey];
        _editable                = [coder decodeBoolForKey:CPRuleEditorEditableKey];
        _allowsEmptyCompoundRows = [coder decodeBoolForKey:CPRuleEditorAllowsEmptyCompoundRowsKey];
        _disallowEmpty           = [coder decodeBoolForKey:CPRuleEditorDisallowEmptyKey];
        _nestingMode             = [coder decodeIntForKey:CPRuleEditorNestingModeKey];
        _typeKeyPath             = [coder decodeObjectForKey:CPRuleEditorRowTypeKeyPathKey];
        _itemsKeyPath            = [coder decodeObjectForKey:CPRuleEditorItemsKeyPathKey];
        _valuesKeyPath           = [coder decodeObjectForKey:CPRuleEditorValuesKeyPathKey];
        _subrowsArrayKeyPath     = [coder decodeObjectForKey:CPRuleEditorSubrowsArrayKeyPathKey];
        _boundArrayKeyPath       = [coder decodeObjectForKey:CPRuleEditorBoundArrayKeyPathKey];

        _slicesHolder = [[self subviews] objectAtIndex:0];
        _boundArrayOwner = [coder decodeObjectForKey:CPRuleEditorBoundArrayOwnerKey];
        _slices = [coder decodeObjectForKey:CPRuleEditorSlicesKey];
        _ruleDelegate = [coder decodeObjectForKey:CPRuleEditorDelegateKey];

        [self _initRuleEditorShared];
    }

    return self;
}

- (void)encodeWithCoder:(id)coder
{
    [super encodeWithCoder:coder];

    [coder encodeBool:_editable forKey:CPRuleEditorEditableKey];
    [coder encodeBool:_allowsEmptyCompoundRows forKey:CPRuleEditorAllowsEmptyCompoundRowsKey];
    [coder encodeBool:_disallowEmpty forKey:CPRuleEditorDisallowEmptyKey];

    [coder encodeFloat:_alignmentGridWidth forKey:CPRuleEditorAlignmentGridWidthKey];
    [coder encodeDouble:_sliceHeight forKey:CPRuleEditorSliceHeightKey];
    [coder encodeInt:_nestingMode forKey:CPRuleEditorNestingModeKey];

    [coder encodeObject:_stringsFilename forKey:CPRuleEditorStringsFilenameKey];
    [coder encodeObject:_typeKeyPath forKey:CPRuleEditorRowTypeKeyPathKey];
    [coder encodeObject:_itemsKeyPath forKey:CPRuleEditorItemsKeyPathKey];
    [coder encodeObject:_valuesKeyPath forKey:CPRuleEditorValuesKeyPathKey];
    [coder encodeObject:_boundArrayKeyPath forKey:CPRuleEditorBoundArrayKeyPathKey];
    [coder encodeObject:_subrowsArrayKeyPath forKey:CPRuleEditorSubrowsArrayKeyPathKey];

    [coder encodeConditionalObject:_slicesHolder forKey:CPRuleEditorSlicesHolderKey];
    [coder encodeObject:_slices forKey:CPRuleEditorSlicesKey];
    [coder encodeObject:_boundArrayOwner forKey:CPRuleEditorBoundArrayOwnerKey];
}

@end

var CriteriaKey         = @"criteria",
    SubrowsKey          = @"subrows",
    DisplayValuesKey    = @"displayValues",
    RowTypeKey          = @"rowType";

@implementation _CPRuleEditorRowObject : CPObject
{
    CPArray     subrows @accessors;
    CPArray     criteria @accessors;
    CPArray     displayValues @accessors;
    CPInteger   rowType @accessors;
}

- (id)copy
{
    var copy = [[_CPRuleEditorRowObject alloc] init];
    [copy setSubrows:[[CPArray alloc] initWithArray:subrows copyItems:YES]];
    [copy setCriteria:[[CPArray alloc] initWithArray:criteria copyItems:YES]];
    [copy setDisplayValues:[[CPArray alloc] initWithArray:displayValues copyItems:YES]];
    [copy setRowType:rowType];

    return copy;
}

- (CPString)description
{
    return "<" + [self className] + ">\nsubrows = " + [subrows description] + "\ncriteria = " + [criteria description] + "\ndisplayValues = " + [displayValues description];
}

- (id)initWithCoder:(id)coder
{
    self = [super init];
    if (self !== nil)
    {
        subrows = [coder decodeObjectForKey:SubrowsKey];
        criteria = [coder decodeObjectForKey:CriteriaKey];
        displayValues = [coder decodeObjectForKey:DisplayValuesKey];
        rowType = [coder decodeIntForKey:RowTypeKey];
    }

    return self;
}

- (void)encodeWithCoder:(id)coder
{
    [coder encodeObject:subrows forKey:SubrowsKey];
    [coder encodeObject:criteria forKey:CriteriaKey];
    [coder encodeObject:displayValues forKey:DisplayValuesKey];
    [coder encodeInt:rowType forKey:RowTypeKey];
}

@end

@implementation _CPRuleEditorCache : CPObject
{
    CPDictionary    rowObject   @accessors;
    CPInteger       rowIndex    @accessors;
    CPInteger       indentation @accessors;
}

- (CPString)description
{
    return [CPString stringWithFormat:@"<%d object:%d rowIndex:%d indentation:%d>", [self hash], [rowObject hash], rowIndex, indentation];
}

@end

var CPBoundArrayKey = @"CPBoundArray";

@implementation _CPRuleEditorViewUnboundRowHolder : CPObject
{
    CPArray boundArray;
}

- (id)init
{
    if (self = [super init])
        boundArray = [[CPArray alloc] init];

    return self;
}

- (id)initWithCoder:(id)coder
{
    if (self = [super init])
        boundArray = [coder decodeObjectForKey:CPBoundArrayKey];

    return self;
}

- (void)encodeWithCoder:(id)coder
{
    [coder encodeObject:boundArray forKey:CPBoundArrayKey];
}

@end

@implementation _CPRuleEditorViewSliceHolder : CPView
{
}

- (void)addSubview:(CPView)subview
{
    [self setNeedsDisplay:YES];
    [super addSubview:subview];
}

@end

var dropSeparatorColor = [CPColor colorWithHexString:@"4886ca"];

@implementation _CPRuleEditorViewSliceDropSeparator : CPView
{
}

- (void)drawRect:(CGRect)rect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];
    CGContextSetFillColor(context, dropSeparatorColor);
    CGContextFillRect(context, [self bounds]);
}

@end

@implementation CPObject (CPRuleEditorSliceRow)

- (int)valueType
{
    var result = 0,
        isString = [self isKindOfClass:CPString];

    if (!isString)
    {
        var isView = [self isKindOfClass:CPView];
        result = 1;

        if (!isView)
        {
            var ismenuItem = [self isKindOfClass:CPMenuItem];
            result = 2;

            if (!ismenuItem)
            {
                [CPException raise:CPGenericException reason:@"Unknown type for " + self];
                result = -1;
            }
        }
    }

    return result;
}

@end
/*! @endcond */
