
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
    return [CPSet setWithObjects:"content", "filterPredicate", "sortDescriptors"];
}

+ (CPSet)keyPathsForValuesAffectingSelection
{
    return [CPSet setWithObjects:"selectionIndexes"];
}

+ (CPSet)keyPathsForValuesAffectingSelectionIndex
{
    return [CPSet setWithObjects:"selectionIndexes"];
}

+ (CPSet)keyPathsForValuesAffectingSelectionIndexes
{
    // When the arranged objects change, selection preservation may cause the indexes
    // to change.
    return [CPSet setWithObjects:"arrangedObjects"];
}

+ (CPSet)keyPathsForValuesAffectingSelectedObjects
{
    // Don't need to depend on arrangedObjects here because selectionIndexes already does.
    return [CPSet setWithObjects:"selectionIndexes"];
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

- (id)init
{
    self = [super init];

    if (self)
    {
        _selectionIndexes = [CPIndexSet indexSet];
    }

    return self;
}

- (void)prepareContent
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
    if (![value isKindOfClass:[CPArray class]])
        value = [value];

    var oldSelectedObjects = nil,
        oldSelectionIndexes = nil;

    if ([self preservesSelection])
        oldSelectedObjects = [self selectedObjects];
    else
        oldSelectionIndexes = [self selectionIndexes];

    /*
        When the contents are changed, the selected indexes may no longer refer to the
        same items. This would cause problems when setSelectedObjects is called below.
        Any KVO observation would try to retrieve the 'before' value which could be
        wrong or even throw an exception for no longer existing indexes.

        To avoid that, use the internal __setSelectedObjects which fires no notifications.
        The selectionIndexes notifications will fire later since they depend on the
        content key. This pattern is also applied for many other methods throughout this
        class.
    */

    if (_clearsFilterPredicateOnInsertion)
        [self willChangeValueForKey:@"filterPredicate"];

    // Don't use [super setContent:] as that would fire the contentObject change.
    // We need to be in control of when notifications fire.
    _contentObject = value;

    if (_clearsFilterPredicateOnInsertion)
        [self __setFilterPredicate:nil]; // Causes a _rearrangeObjects.
    else
        [self _rearrangeObjects];

    if ([self preservesSelection])
        [self __setSelectedObjects:oldSelectedObjects];
    else
        [self __setSelectionIndexes:oldSelectionIndexes];

    if (_clearsFilterPredicateOnInsertion)
        [self didChangeValueForKey:@"filterPredicate"];
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
    [self willChangeValueForKey:@"arrangedObjects"];
    [self _rearrangeObjects];
    [self didChangeValueForKey:@"arrangedObjects"];
}

/*
    Like rearrangeObjects but don't fire any change notifications.
    @ignore
*/
- (void)_rearrangeObjects
{
    /*
        Rearranging reapplies the selection criteria and may cause objects to disappear,
        so take care of the selection.
    */
    var oldSelectedObjects = nil,
        oldSelectionIndexes = nil;

    if ([self preservesSelection])
        oldSelectedObjects = [self selectedObjects];
    else
        oldSelectionIndexes = [self selectionIndexes];

    [self __setArrangedObjects:[self arrangeObjects:[self contentArray]]];

    if ([self preservesSelection])
        [self __setSelectedObjects:oldSelectedObjects];
    else
        [self __setSelectionIndexes:oldSelectionIndexes];
}

- (void)__setArrangedObjects:(id)value
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
    // Use the non-notification version since arrangedObjects already depends
    // on sortDescriptors.
    [self _rearrangeObjects];
}

- (CPPredicate)filterPredicate
{
    return _filterPredicate;
}

- (void)setFilterPredicate:(CPPredicate)value
{
    [self __setFilterPredicate:value];
}

/*
    Like setFilterPredicate but don't fire any change notifications.
    @ignore
*/
- (void)__setFilterPredicate:(CPPredicate)value
{
    if (_filterPredicate === value)
        return;

    _filterPredicate = value;
    // Use the non-notification version since arrangedObjects already depends
    // on filterPredicate.
    [self _rearrangeObjects];
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
    [self _selectionWillChange]
    [self __setSelectionIndexes:indexes];
    [self _selectionDidChange];
}

/*
    Like setSelectionIndex but don't fire any change notifications.
    @ignore
*/
- (BOOL)__setSelectionIndex:(int)theIndex
{
    [self __setSelectionIndexes:[CPIndexSet indexSetWithIndex:theIndex]];
}

/*
    Like setSelectionIndexes but don't fire any change notifications.
    @ignore
*/
- (BOOL)__setSelectionIndexes:(CPIndexSet)indexes
{
    if (!indexes)
        indexes = [CPIndexSet indexSet];

    if (![indexes count])
    {
        if (_avoidsEmptySelection && [[self arrangedObjects] count])
            indexes = [CPIndexSet indexSetWithIndex:0];
    }
    else
    {
        var objectsCount = [[self arrangedObjects] count];
        // Remove out of bounds indexes.
        [indexes removeIndexesInRange:CPMakeRange(objectsCount, [indexes lastIndex] + 1)];
        // When avoiding empty selection and the deleted selection was at the bottom, select the last item.
        if (![indexes count] && _avoidsEmptySelection && objectsCount)
            indexes = [CPIndexSet indexSetWithIndex:objectsCount - 1];
    }

    if ([_selectionIndexes isEqualToIndexSet:indexes])
        return NO;

    _selectionIndexes = [indexes copy];

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
    [self willChangeValueForKey:@"selectionIndexes"];
    [self _selectionWillChange];

    [self __setSelectedObjects:objects];

    [self didChangeValueForKey:@"selectionIndexes"];
    [self _selectionDidChange];
}

/*
    Like setSelectedObjects but don't fire any change notifications.
    @ignore
*/
- (BOOL)__setSelectedObjects:(CPArray)objects
{
    var set = [CPIndexSet indexSet],
        count = [objects count],
        arrangedObjects = [self arrangedObjects];

    for (var i = 0; i < count; i++)
    {
        var index = [arrangedObjects indexOfObject:[objects objectAtIndex:i]];

        if (index !== CPNotFound)
            [set addIndex:index];
    }

    [self __setSelectionIndexes:set];
    return YES;
}

//Moving selection

- (BOOL)canSelectPrevious
{
    return [[self selectionIndexes] firstIndex] > 0
}

- (void)selectPrevious:(id)sender
{
    var index = [[self selectionIndexes] firstIndex] - 1;

    if (index >= 0)
        [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:index]];
}

- (BOOL)canSelectNext
{
    return [[self selectionIndexes] firstIndex] < [[self arrangedObjects] count] - 1;
}

- (void)selectNext:(id)sender
{
    var index = [[self selectionIndexes] firstIndex] + 1;

    if (index < [[self arrangedObjects] count])
        [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:index]];
}

//Add/Remove

- (void)addObject:(id)object
{
    if (![self canAdd])
        return;

    if (_clearsFilterPredicateOnInsertion)
        [self willChangeValueForKey:@"filterPredicate"];

    [self willChangeValueForKey:@"content"];
    [_contentObject addObject:object];

    if (_clearsFilterPredicateOnInsertion)
        [self __setFilterPredicate:nil];

    if (_filterPredicate === nil || [_filterPredicate evaluateWithObject:object])
    {
        var pos = [_arrangedObjects insertObject:object inArraySortedByDescriptors:_sortDescriptors];

        // selectionIndexes change notification will be fired as a result of the
        // content change. Don't fire manually.
        if (_selectsInsertedObjects)
            [self __setSelectionIndex:pos];
        else
            [_selectionIndexes shiftIndexesStartingAtIndex:pos by:1];
    }
    else
        [self _rearrangeObjects];

    [self didChangeValueForKey:@"content"];
    if (_clearsFilterPredicateOnInsertion)
        [self didChangeValueForKey:@"filterPredicate"];
}

- (void)insertObject:(id)anObject atArrangedObjectIndex:(int)anIndex
{
    if (![self canAdd])
        return;

    if (_clearsFilterPredicateOnInsertion)
        [self willChangeValueForKey:@"filterPredicate"];

    [self willChangeValueForKey:@"content"];
    [_contentObject insertObject:anObject atIndex:anIndex];

    if (_clearsFilterPredicateOnInsertion)
        [self __setFilterPredicate:nil];

    [[self arrangedObjects] insertObject:anObject atIndex:anIndex];

    // selectionIndexes change notification will be fired as a result of the
    // content change. Don't fire manually.
    if ([self selectsInsertedObjects])
        [self __setSelectionIndex:anIndex];
    else
        [[self selectionIndexes] shiftIndexesStartingAtIndex:anIndex by:1];

    if ([self avoidsEmptySelection] && [[self selectionIndexes] count] <= 0 && [_contentObject count] > 0)
        [self __setSelectionIndexes:[CPIndexSet indexSetWithIndex:0]];

    [self didChangeValueForKey:@"content"];
    if (_clearsFilterPredicateOnInsertion)
        [self didChangeValueForKey:@"filterPredicate"];
}

- (void)removeObject:(id)object
{
    if (![self canRemove])
        return;

   [self willChangeValueForKey:@"content"];
   [_contentObject removeObject:object];

   if (_filterPredicate === nil || [_filterPredicate evaluateWithObject:object])
   {
       // selectionIndexes change notification will be fired as a result of the
       // content change. Don't fire manually.
        var pos = [_arrangedObjects indexOfObject:object];

        [_arrangedObjects removeObjectAtIndex:pos];
        [_selectionIndexes shiftIndexesStartingAtIndex:pos by:-1];
   }

   [self didChangeValueForKey:@"content"];
}

- (void)add:(id)sender
{
    if (![self canAdd])
        return;

    [self insert:sender];
}

- (void)insert:(id)sender
{
    if (![self canInsert])
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
    if (![self canAdd])
        return;

    var contentArray = [self contentArray],
        count = [objects count];

    for (var i = 0; i < count; i++)
        [contentArray addObject:[objects objectAtIndex:i]];

    [self setContent:contentArray];
}

- (void)removeObjects:(CPArray)objects
{
    if (![self canRemove])
        return;

    [self _removeObjects:objects];
}

- (void)_removeObjects:(CPArray)objects
{
    [self willChangeValueForKey:@"content"];
    [_contentObject removeObjectsInArray:objects];

    var arrangedObjects = [self arrangedObjects],
        position = [arrangedObjects indexOfObject:[objects objectAtIndex:0]];

    [arrangedObjects removeObjectsInArray:objects];

    var objectsCount = [arrangedObjects count],
        selectionIndexes = [CPIndexSet indexSet];

    if ([self preservesSelection] || [self avoidsEmptySelection])
    {
        selectionIndexes = [CPIndexSet indexSetWithIndex:position];

        // Remove the selection if there are no objects
        if (objectsCount <= 0)
            selectionIndexes = [CPIndexSet indexSet];

        // Shift selection to last object if position is out of bounds
        else if (position >= objectsCount)
            selectionIndexes = [CPIndexSet indexSetWithIndex:objectsCount - 1];
     }

     _selectionIndexes = selectionIndexes;

     [self didChangeValueForKey:@"content"];
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
