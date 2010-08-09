
/*
 * CPArrayController.j
 * AppKit
 *
 * Adapted from Cocotron, by Johannes Fortmann
 *
 * Created by Ross Boucher.
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

@import <AppKit/CPObjectController.j>
@import <AppKit/CPKeyValueBinding.j>


@implementation CPArrayController : CPObjectController
{
    BOOL    _avoidsEmptySelection;
    BOOL    _clearsFilterPredicateOnInsertion;
    BOOL    _filterRestrictsInsertion;
    BOOL    _preservesSelection;
    BOOL    _selectsInsertedObjects;
    BOOL    _alwaysUsesMultipleValuesMarker;

    id      _selectionIndexes;
    id      _sortDescriptors;
    id      _filterPredicate;
    id      _arrangedObjects;
}

+ (void)initialize
{
    if (self !== [CPArrayController class])
        return;

    [self exposeBinding:@"contentArray"];
    [self exposeBinding:@"contentSet"];
}

+ (CPSet)keyPathsForValuesAffectingContentArray
{
    return [CPSet setWithObjects:"content"];
}

+ (CPSet)keyPathsForValuesAffectingArrangedObjects
{
    return [CPSet setWithObjects:"content", "contentArray", "contentSet", "filterPredicate", "sortDescriptors"];
}

+ (CPSet)keyPathsForValuesAffectingSelection
{
    return [CPSet setWithObjects:"content", "contentArray", "contentSet", "selectionIndexes"];
}

+ (CPSet)keyPathsForValuesAffectingSelectionIndex
{
    return [CPSet setWithObjects:"content", "contentArray", "contentSet", "selectionIndexes", "selection"];
}

+ (CPSet)keyPathsForValuesAffectingSelectedObjects
{
    return [CPSet setWithObjects:"content", "contentArray", "contentSet", "selectionIndexes", "selection"];
}

+ (CPSet)keyPathsForValuesAffectingCanRemove
{
    return [CPSet setWithObjects:"selectionIndexes"];
}

+ (CPSet)keyPathsForValuesAffectingCanSelectNext
{
    return [CPSet setWithObjects:"selectionIndexes"];
}

+ (CPSet)keyPathsForValuesAffectingCanSelectPrevious
{
    return [CPSet setWithObjects:"selectionIndexes"];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(CPString)aKey
{
    if (![super automaticallyNotifiesObserversForKey:aKey])
        return NO;
    if (aKey === @"selectionIndexes")
        return NO;

    return YES;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _selectionIndexes = [CPIndexSet indexSet];
    }

    return self;
}

-(void)prepareContent
{
    [self _setContentArray:[[self newObject]]];
}

- (BOOL)preservesSelection
{
    return _preservesSelection;
}

- (void)setPreservesSelection:(BOOL)value
{
    _preservesSelection = value;
}

- (BOOL)selectsInsertedObjects
{
    return _selectsInsertedObjects;
}

- (void)setSelectsInsertedObjects:(BOOL)value
{
    _selectsInsertedObjects = value;
}

- (BOOL)avoidsEmptySelection
{
    return _avoidsEmptySelection;
}

- (void)setAvoidsEmptySelection:(BOOL)value
{
    _avoidsEmptySelection = value;
}

- (void)setContent:(id)value
{
    if(![value isKindOfClass:[CPArray class]])
        value = [value];

    var oldSelection = nil,
        oldSelectionIndexes = [self selectionIndexes];

    if ([self preservesSelection])
        oldSelection = [self selectedObjects];

    // Avoid out of bounds selections.
    _selectionIndexes = [CPIndexSet indexSet];
    //FIXME: copy?
    [super setContent:value];

    if(_clearsFilterPredicateOnInsertion)
        [self setFilterPredicate:nil];

    [self rearrangeObjects];

    if (oldSelection)
        [self setSelectedObjects:oldSelection];
    else
        [self setSelectionIndexes:oldSelectionIndexes];
}

- (void)_setContentArray:(id)anArray
{
   [self setContent:anArray];
}

- (void)_setContentSet:(id)aSet
{
    [self setContent:aSet];
}

- (id)contentArray
{
    return [self content];
}

- (id)contentSet
{
    return [self content];
}

- (CPArray)arrangeObjects:(CPArray)objects
{
    var filterPredicate = [self filterPredicate],
        sortDescriptors = [self sortDescriptors];

    if (filterPredicate && sortDescriptors)
    {
        var sortedObjects = [objects filteredArrayUsingPredicate:filterPredicate];
        [sortedObjects sortUsingDescriptors:sortDescriptors];
        return sortedObjects;
    }
    else if (filterPredicate)
        return [objects filteredArrayUsingPredicate:filterPredicate];
    else if (sortDescriptors)
        return [objects sortedArrayUsingDescriptors:sortDescriptors];

    return [objects copy];
}

- (void)rearrangeObjects
{
    // Rearranging reapplies the selection criteria and may cause objects to disappear,
    // so take care of the selection.
    //
    // Sometimes rearrangeObjects is called by setContent which may cause two rounds of
    // selection preservation. This is okay because setContent temporarily clears the
    // selection and so this code below ends up preserving nothing in that case.
    var oldSelection = nil,
        oldSelectionIndexes = [[self selectionIndexes] copy];

    if ([self preservesSelection])
        oldSelection = [self selectedObjects];

    // Avoid out of bounds selections.
    _selectionIndexes = [CPIndexSet indexSet];

    [self _setArrangedObjects:[self arrangeObjects:[self contentArray]]];

    if (oldSelection)
        [self setSelectedObjects:oldSelection];
    else
        [self setSelectionIndexes:oldSelectionIndexes];
}

- (void)_setArrangedObjects:(id)value
{
    if (_arrangedObjects === value)
        return;

   _arrangedObjects = [[_CPObservableArray alloc] initWithArray:value];
}

- (id)arrangedObjects
{
    return _arrangedObjects;
}


- (CPArray)sortDescriptors
{
    return _sortDescriptors;
}

- (void)setSortDescriptors:(CPArray)value
{
    if (_sortDescriptors === value)
        return;

    _sortDescriptors = [value copy];
    [self rearrangeObjects];
}

- (CPPredicate)filterPredicate
{
    return _filterPredicate;
}

- (void)setFilterPredicate:(CPPredicate)value
{
    if (_filterPredicate === value)
        return;

    _filterPredicate = value;
    [self rearrangeObjects];
}

- (BOOL)alwaysUsesMultipleValuesMarker
{
    return _alwaysUsesMultipleValuesMarker;
}

//Selection

- (unsigned)selectionIndex
{
    return [_selectionIndexes firstIndex];
}

- (BOOL)setSelectionIndex:(unsigned)index
{
    return [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:index]];
}

- (CPIndexSet)selectionIndexes
{
    return _selectionIndexes;
}

- (BOOL)setSelectionIndexes:(CPIndexSet)indexes
{
    if ([_selectionIndexes isEqualToIndexSet:indexes])
        return NO;

    if (![indexes count])
    {
        if(_avoidsEmptySelection && [[self arrangedObjects] count])
            indexes = [CPIndexSet indexSetWithIndex:0];
    }
    else
    {
        var objectsCount = [[self arrangedObjects] count];
        // Remove out of bounds indexes.
        [indexes removeIndexesInRange:CPMakeRange(objectsCount, [indexes lastIndex]+1)];
        // When avoiding empty selection and the deleted selection was at the bottom, select the last item.
        if(![indexes count] && _avoidsEmptySelection && objectsCount)
            indexes = [CPIndexSet indexSetWithIndex:objectsCount-1];
    }

    [self willChangeValueForKey:@"selectionIndexes"];
    [self _selectionWillChange];

    _selectionIndexes = [indexes copy];

    [self _selectionDidChange];
    [self didChangeValueForKey:@"selectionIndexes"];

    // Push back the new selection to the model for selectionIndexes if we have one.
    // There won't be an infinite loop because of the equality check above.
    [[CPKeyValueBinding getBinding:@"selectionIndexes" forObject:self] reverseSetValueFor:@"selectionIndexes"];

    return YES;
}

- (CPArray)selectedObjects
{
    var objects = [[self arrangedObjects] objectsAtIndexes:[self selectionIndexes]];

    return [_CPObservableArray arrayWithArray:(objects || [])];
}

- (BOOL)setSelectedObjects:(CPArray)objects
{
    var set = [CPIndexSet indexSet],
        count = [objects count],
        arrangedObjects = [self arrangedObjects];

    for (var i=0; i<count; i++)
    {
        var index = [arrangedObjects indexOfObject:[objects objectAtIndex:i]];

        if (index !== CPNotFound)
            [set addIndex:index];
    }

    [self setSelectionIndexes:set];
    return YES;
}

//Moving selection

-(BOOL)canSelectPrevious
{
    return [[self selectionIndexes] firstIndex] > 0
}

-(BOOL)canSelectNext
{
    return [[self selectionIndexes] firstIndex] < [[self arrangedObjects] count] -1;
}

-(void)selectNext:(id)sender
{
    var index = [[self selectionIndexes] firstIndex] + 1 || 0;

    if (index < [[self arrangedObjects] count])
        [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:index]];
}

-(void)selectPrevious:(id)sender
{
    var index = [[self selectionIndexes] firstIndex] - 1 || [[self arrangedObjects] count] - 1;

    if (index >= 0)
        [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:index]];
}

//Add/Remove

- (void)addObject:(id)object
{
    if (![self canAdd])
        return;

    [self willChangeValueForKey:@"content"];
    [_contentObject addObject:object];
    [self didChangeValueForKey:@"content"];

    if (_clearsFilterPredicateOnInsertion)
        [self setFilterPredicate:nil];

    if (_filterPredicate === nil || [_filterPredicate evaluateWithObject:object])
    {
        var pos = [_arrangedObjects insertObject:object inArraySortedByDescriptors:_sortDescriptors];

        if (_selectsInsertedObjects)
        {
            [self setSelectionIndex:pos];
        }
        else
        {
            [self willChangeValueForKey:@"selectionIndexes"];
            [_selectionIndexes shiftIndexesStartingAtIndex:pos by:1];
            [self didChangeValueForKey:@"selectionIndexes"];
        }
    }
    else
        [self rearrangeObjects];
}

- (void)removeObject:(id)object
{
    if (![self canRemove])
        return;

   [self willChangeValueForKey:@"content"];
   [_contentObject removeObject:object];
   [self didChangeValueForKey:@"content"];

   if ([_filterPredicate evaluateWithObject:object])
   {
        [self willChangeValueForKey:@"selectionIndexes"];
        var pos = [_arrangedObjects indexOfObject:object];

        [_selectionIndexes shiftIndexesStartingAtIndex:pos by:-1];
        [self didChangeValueForKey:@"selectionIndexes"];
   }
}

-(void)add:(id)sender
{
    if(![self canAdd])
        return;

    [self insert:sender];
}

- (void)insert:(id)sender
{
    if(![self canInsert])
        return;

    var newObject = [self automaticallyPreparesContent] ? [self newObject] : [self _defaultNewObject];

    [self addObject:newObject];
}

- (void)remove:(id)sender
{
   [self removeObjects:[[self arrangedObjects] objectsAtIndexes:[self selectionIndexes]]];
}

- (void)removeObjectsAtArrangedObjectIndexes:(CPIndexSet)indexes
{
    [self _removeObjects:[[self arrangedObjects] objectsAtIndexes:indexes]];
}


- (void)addObjects:(CPArray)objects
{
    if(![self canAdd])
        return;

    var contentArray = [self contentArray],
        count = [objects count];

    for (var i=0; i<count; i++)
        [contentArray addObject:[objects objectAtIndex:i]];

    [self setContent:contentArray];
}

- (void)removeObjects:(CPArray)objects
{
    if(![self canRemove])
        return;

    [self _removeObjects:objects];
}

- (void)_removeObjects:(CPArray)objects
{
    var contentArray = [self contentArray],
        count = [objects count];

    for (var i=0; i<count; i++)
        [contentArray removeObject:[objects objectAtIndex:i]];

    [self setContent:contentArray];
}

- (BOOL)canInsert
{
    return [self isEditable];
}

@end

@implementation CPArrayController (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:coder];

    if (self)
    {
        _avoidsEmptySelection = [coder decodeBoolForKey:@"CPArrayControllerAvoidsEmptySelection"];
        _clearsFilterPredicateOnInsertion = [coder decodeBoolForKey:@"CPClearsFilterPredicateOnInsertion"];
        _filterRestrictsInsertion = [coder decodeBoolForKey:@"CPArrayControllerFilterRestrictsInsertion"];
        _preservesSelection = [coder decodeBoolForKey:@"CPArrayControllerPreservesSelection"];
        _selectsInsertedObjects = [coder decodeBoolForKey:@"CPArrayControllerSelectsInsertedObjects"];
        _alwaysUsesMultipleValuesMarker = [coder decodeBoolForKey:@"CPArrayControllerAlwaysUsesMultipleValuesMarker"];

        if ([self automaticallyPreparesContent])
            [self prepareContent];
        else
            [self _setContentArray:[]];
    }

    return self;
}

- (void)awakeFromCib
{
    [self _selectionWillChange];
    [self _selectionDidChange];
}

@end
