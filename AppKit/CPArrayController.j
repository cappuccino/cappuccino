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

@import <Foundation/CPIndexSet.j>

@import "CPObjectController.j"
@import "CPKeyValueBinding.j"

/*!

@class CPArrayController

    CPArrayController is a bindings compatible class that manages an array.
    CPArrayController also provides selection management and sorting capabilities.

*/
@implementation CPArrayController : CPObjectController
{
    BOOL    _avoidsEmptySelection;
    BOOL    _clearsFilterPredicateOnInsertion;
    BOOL    _filterRestrictsInsertion;
    BOOL    _preservesSelection;
    BOOL    _selectsInsertedObjects;
    BOOL    _alwaysUsesMultipleValuesMarker;

    BOOL    _automaticallyRearrangesObjects; // FIXME: Not in use

    CPIndexSet  _selectionIndexes;
    CPArray     _sortDescriptors;
    CPPredicate _filterPredicate;
    CPArray     _arrangedObjects;

    BOOL    _disableSetContent;
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
    return [CPSet setWithObjects:@"content"];
}

+ (CPSet)keyPathsForValuesAffectingArrangedObjects
{
    // Also depends on "filterPredicate" but we'll handle that manually.
    return [CPSet setWithObjects:@"content", @"sortDescriptors"];
}

+ (CPSet)keyPathsForValuesAffectingSelection
{
    return [CPSet setWithObjects:@"selectionIndexes"];
}

+ (CPSet)keyPathsForValuesAffectingSelectionIndex
{
    return [CPSet setWithObjects:@"selectionIndexes"];
}

+ (CPSet)keyPathsForValuesAffectingSelectionIndexes
{
    // When the arranged objects change, selection preservation may cause the indexes
    // to change.
    return [CPSet setWithObjects:@"arrangedObjects"];
}

+ (CPSet)keyPathsForValuesAffectingSelectedObjects
{
    // Don't need to depend on arrangedObjects here because selectionIndexes already does.
    return [CPSet setWithObjects:@"selectionIndexes"];
}

+ (CPSet)keyPathsForValuesAffectingCanRemove
{
    return [CPSet setWithObjects:@"selectionIndexes"];
}

+ (CPSet)keyPathsForValuesAffectingCanSelectNext
{
    return [CPSet setWithObjects:@"selectionIndexes"];
}

+ (CPSet)keyPathsForValuesAffectingCanSelectPrevious
{
    return [CPSet setWithObjects:@"selectionIndexes"];
}


- (id)init
{
    self = [super init];

    if (self)
    {
        _preservesSelection = YES;
        _selectsInsertedObjects = YES;
        _avoidsEmptySelection = YES;
        _clearsFilterPredicateOnInsertion = YES;
        _alwaysUsesMultipleValuesMarker = NO;
        _automaticallyRearrangesObjects = NO;

        _filterRestrictsInsertion = YES; // FIXME: Not in use

        [self _init];
    }

    return self;
}

- (void)_init
{
    _sortDescriptors = [CPArray array];
    _filterPredicate = nil;
    _selectionIndexes = [CPIndexSet indexSet];
    [self __setArrangedObjects:[CPArray array]];
}

- (void)prepareContent
{
    [self _setContentArray:[[self newObject]]];
}
/*!
    Returns YES if the selection should try to be preserved when the content changes, otherwise NO.
    @return BOOL YES if the selection is preserved, otherwise NO.
*/
- (BOOL)preservesSelection
{
    return _preservesSelection;
}

/*!
    Sets whether the selection is kept when the content changes.

    @param BOOL aFlag - YES if the selection should be kept, otherwise NO.
*/
- (void)setPreservesSelection:(BOOL)value
{
    _preservesSelection = value;
}

/*!
    @return BOOL - Returns YES if new objects are automatically selected, otherwise NO.
*/
- (BOOL)selectsInsertedObjects
{
    return _selectsInsertedObjects;
}

/*!
    Sets whether the controller will automatically select objects as they are inserted.
    @return BOOL - YES if new objects are selected, otherwise NO.
*/
- (void)setSelectsInsertedObjects:(BOOL)value
{
    _selectsInsertedObjects = value;
}

/*!
    @return BOOL - YES if the controller should try to avoid an empty selection otherwise NO.
*/
- (BOOL)avoidsEmptySelection
{
    return _avoidsEmptySelection;
}

/*!
    Sets whether the controller should try to avoid an empty selection.
    @param BOOL aFlag - YES if the receiver should attempt to avoid an empty selection, otherwise NO.
*/
- (void)setAvoidsEmptySelection:(BOOL)value
{
    _avoidsEmptySelection = value;
}

/*!
    Whether the receiver will clear its filter predicate when a new object is inserted.

    @return BOOL YES if the receiver clears filter predicates on insert
*/
- (BOOL)clearsFilterPredicateOnInsertion
{
    return _clearsFilterPredicateOnInsertion;
}

/*!
    Sets whether the receiver should clear its filter predicate when a new object is inserted.

    @param BOOL YES if the receiver should clear filter predicates on insert
*/
- (void)setClearsFilterPredicateOnInsertion:(BOOL)aFlag
{
    _clearsFilterPredicateOnInsertion = aFlag;
}

/*!
    Whether the receiver will always return the multiple values marker when multiple
    items are selected, even if the items have the same value.

    @return BOOL YES if the receiver always uses the multiple values marker
*/
- (BOOL)alwaysUsesMultipleValuesMarker
{
    return _alwaysUsesMultipleValuesMarker;
}

/*!
    Sets whether the receiver should always return the multiple values marker when multiple
    items are selected, even if the items have the same value.

    @param BOOL aFlag YES if the receiver should always use the multiple values marker
*/
- (void)setAlwaysUsesMultipleValuesMarker:(BOOL)aFlag
{
    _alwaysUsesMultipleValuesMarker = aFlag;
}

/*!
    Whether the receiver will rearrange its contents automatically whenever the sort
    descriptors or filter predicates are changed.

    NOTE: not yet implemented. Cappuccino always act as if this value was YES.

    @return BOOL YES if the receiver will automatically rearrange its content on new sort
        descriptors or filter predicates
*/
- (BOOL)automaticallyRearrangesObjects
{
    return _automaticallyRearrangesObjects;
}

/*!
    Sets whether the receiver should rearrange its contents automatically whenever the sort
    descriptors or filter predicates are changed.

    NOTE: not yet implemented. Cappuccino always act as if this value was YES.

    @param BOOL YES if the receiver should automatically rearrange its content on new sort
        descriptors or filter predicates
*/
- (void)setAutomaticallyRearrangesObjects:(BOOL)aFlag
{
    _automaticallyRearrangesObjects = aFlag;
}

/*!
    Sets the controller's content object.

    @param id value - the content object of the controller.
*/
- (void)setContent:(id)value
{
    // This is used to ignore expected setContent: calls caused by a binding to our content
    // object when we are the ones modifying the content object and can deal with the update
    // faster directly in the code in charge of the modification.
    if (_disableSetContent)
        return;

    if (value === nil)
        value = [];

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
    // Note that if we have a contentArray binding, setting the content does /not/
    // cause a reverse binding set.
    _contentObject = value;

    if (_clearsFilterPredicateOnInsertion && _filterPredicate != nil)
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

/*!
    @ignore
*/
- (void)_setContentArray:(id)anArray
{
    [self setContent:anArray];
}

/*!
    @ignore
*/
- (void)_setContentSet:(id)aSet
{
    [self setContent:[aSet allObjects]];
}

/*!
    Returns the content array of the controller.
    @return id the content array of the receiver
*/
- (id)contentArray
{
    return [self content];
}

/*!
    Returns the content of the receiver as a CPSet.

    @return id - the content of the controller as a set.
*/
- (id)contentSet
{
    return [CPSet setWithArray:[self content]];
}

/*!
    Sorts and filters a given array and returns it.

    @param CPArray anArray - an array of objects.
    @return CPArray - the array of sorted objects.
*/
- (CPArray)arrangeObjects:(CPArray)objects
{
    var filterPredicate = [self filterPredicate],
        sortDescriptors = [self sortDescriptors];

    if (filterPredicate && [sortDescriptors count] > 0)
    {
        var sortedObjects = [objects filteredArrayUsingPredicate:filterPredicate];
        [sortedObjects sortUsingDescriptors:sortDescriptors];
        return sortedObjects;
    }
    else if (filterPredicate)
        return [objects filteredArrayUsingPredicate:filterPredicate];
    else if ([sortDescriptors count] > 0)
        return [objects sortedArrayUsingDescriptors:sortDescriptors];

    return [objects copy];
}

/*!
    Triggers the filtering of the objects in the controller.
*/
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

/*!
    @ignore
*/
- (void)__setArrangedObjects:(id)value
{
    if (_arrangedObjects === value)
        return;

    _arrangedObjects = [[_CPObservableArray alloc] initWithArray:value];
}

/*!
    Returns an array of the controller's objects sorted and filtered.
    @return - array of objects
*/
- (id)arrangedObjects
{
    return _arrangedObjects;
}

/*!
    Returns the receiver's array of sort descriptors.
    @return CPArray an array of sort descriptors
*/
- (CPArray)sortDescriptors
{
    return _sortDescriptors;
}

/*!
    Sets the sort descriptors for the controller.

    @param CPArray descriptors - the new sort descriptors.
*/
- (void)setSortDescriptors:(CPArray)value
{
    if (_sortDescriptors === value)
        return;

    _sortDescriptors = [value copy];
    // Use the non-notification version since arrangedObjects already depends
    // on sortDescriptors.
    [self _rearrangeObjects];
}

/*!
    Returns the predicate used by the controller to filter the contents of the receiver.
    If no predicate is set nil is returned.

    @return CPPredicate the predicate used by the controller
*/
- (CPPredicate)filterPredicate
{
    return _filterPredicate;
}

/*!
    Sets the predicate for the controller to filter the content.
    Passing nil will remove an existing prediate.

    @param CPPrediate aPredicate - the new predicate.
*/
- (void)setFilterPredicate:(CPPredicate)value
{
    if (_filterPredicate === value)
        return;

    // __setFilterPredicate will call _rearrangeObjects without
    // sending notifications, so we must send them instead.
    [self willChangeValueForKey:@"arrangedObjects"];
    [self __setFilterPredicate:value];
    [self didChangeValueForKey:@"arrangedObjects"];
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
    // Use the non-notification version.
    [self _rearrangeObjects];
}

/*!
    Returns a BOOL indicating whether the receiver always returns the multiple values marker when multiple objects are selected.
    @return BOOL YES is the controller always uses multiple value markers, otherwise NO.
*/
- (BOOL)alwaysUsesMultipleValuesMarker
{
    return _alwaysUsesMultipleValuesMarker;
}

//Selection
/*!
    Returns the index of the first object in the controller's selection.
    @return unsigned - Index of the first selected object.
*/
- (unsigned)selectionIndex
{
    return [_selectionIndexes firstIndex];
}

/*!
    Sets the selected index

    @param unsigned anIndex - the new index to select
    @return BOOL - Returns YES if the selection was changed, otherwise NO.
*/
- (BOOL)setSelectionIndex:(unsigned)index
{
    return [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:index]];
}

/*!
    Returns an index set of the selected indexes.

    @return CPIndexSet - The selected indexes.
*/
- (CPIndexSet)selectionIndexes
{
    return _selectionIndexes;
}

/*!
    Sets the selection indexes of the controller.

    @param CPIndexSet indexes - the indexes to select
    @return BOOL - Returns YES if the selection changed, otherwise NO.
*/
- (BOOL)setSelectionIndexes:(CPIndexSet)indexes
{
    [self _selectionWillChange]
    var r = [self __setSelectionIndexes:indexes avoidEmpty:NO];
    [self _selectionDidChange];
    return r;
}

/*
    Like setSelectionIndex but don't fire any change notifications.
    @ignore
*/
- (BOOL)__setSelectionIndex:(int)theIndex
{
    return [self __setSelectionIndexes:[CPIndexSet indexSetWithIndex:theIndex]];
}

/*
    Like setSelectionIndexes but don't fire any change notifications.
    @ignore
*/
- (BOOL)__setSelectionIndexes:(CPIndexSet)indexes
{
    return [self __setSelectionIndexes:indexes avoidEmpty:_avoidsEmptySelection];
}

- (BOOL)__setSelectionIndexes:(CPIndexSet)indexes avoidEmpty:(BOOL)avoidEmpty
{
    var newIndexes = indexes;

    if (!newIndexes)
        newIndexes = [CPIndexSet indexSet];

    if (![newIndexes count])
    {
        if (avoidEmpty && [[self arrangedObjects] count])
            newIndexes = [CPIndexSet indexSetWithIndex:0];
    }
    else
    {
        var objectsCount = [[self arrangedObjects] count];

        // Don't trash the input - the caller might depend on it or we might have been
        // given _selectionIndexes as the input in which case the equality test below
        // would always succeed despite our change below.
        newIndexes = [newIndexes copy];

        // Remove out of bounds indexes.
        [newIndexes removeIndexesInRange:CPMakeRange(objectsCount, [newIndexes lastIndex] + 1)];
        // When avoiding empty selection and the deleted selection was at the bottom, select the last item.
        if (![newIndexes count] && avoidEmpty && objectsCount)
            newIndexes = [CPIndexSet indexSetWithIndex:objectsCount - 1];
    }

    if ([_selectionIndexes isEqualToIndexSet:newIndexes])
        return NO;

    // If we haven't already created our own index instance, make sure to copy it here so that
    // the copy the user sent in is decoupled from our internal copy.
    _selectionIndexes = indexes === newIndexes ? [indexes copy] : newIndexes;

    // Push back the new selection to the model for selectionIndexes if we have one.
    // There won't be an infinite loop because of the equality check above.
    var binderClass = [[self class] _binderClassForBinding:@"selectionIndexes"];
    [[binderClass getBinding:@"selectionIndexes" forObject:self] reverseSetValueFor:@"selectionIndexes"];

    return YES;
}

/*!
    Returns an array of the selected objects.
    @return CPArray - the selected objects.
*/
- (CPArray)selectedObjects
{
    var objects = [[self arrangedObjects] objectsAtIndexes:[self selectionIndexes]];

    return [_CPObservableArray arrayWithArray:(objects || [])];
}

/*!
    Sets the selected objects of the controller.

    @param CPArray anArray - the objects to select
    @return BOOL - Returns YES if the selection was changed, otherwise NO.
*/
- (BOOL)setSelectedObjects:(CPArray)objects
{
    [self willChangeValueForKey:@"selectionIndexes"];
    [self _selectionWillChange];

    var r = [self __setSelectedObjects:objects avoidEmpty:NO];

    [self didChangeValueForKey:@"selectionIndexes"];
    [self _selectionDidChange];
    return r;
}

/*
    Like setSelectedObjects but don't fire any change notifications.
    @ignore
*/
- (BOOL)__setSelectedObjects:(CPArray)objects
{
    [self __setSelectedObjects:objects avoidEmpty:_avoidsEmptySelection];
}

- (BOOL)__setSelectedObjects:(CPArray)objects avoidEmpty:(BOOL)avoidEmpty
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

    [self __setSelectionIndexes:set avoidEmpty:avoidEmpty];
    return YES;
}

//Moving selection
/*!
    Returns YES if the previous object, relative to the current selection, in the controller's content array can be selected.

    @return BOOL - YES if the object can be selected, otherwise NO.
*/
- (BOOL)canSelectPrevious
{
    return [[self selectionIndexes] firstIndex] > 0
}

/*!
    Selects the previous object, relative to the current selection, in the controllers arranged content.
    @param id sender - the sender of the message.
*/
- (void)selectPrevious:(id)sender
{
    var index = [[self selectionIndexes] firstIndex] - 1;

    if (index >= 0)
        [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:index]];
}

/*!
    Returns YES if the next object, relative to the current selection, in the controller's content array can be selected.

    @return BOOL - YES if the object can be selected, otherwise NO.
*/
- (BOOL)canSelectNext
{
    return [[self selectionIndexes] firstIndex] < [[self arrangedObjects] count] - 1;
}

/*!
    Selects the next object, relative to the current selection, in the controllers arranged content.
    @param id sender - the sender of the message.
*/
- (void)selectNext:(id)sender
{
    var index = [[self selectionIndexes] firstIndex] + 1;

    if (index < [[self arrangedObjects] count])
        [self setSelectionIndexes:[CPIndexSet indexSetWithIndex:index]];
}

//Add/Remove

/*!
    Adds object to the receiver's content collection and the arranged objects array.

    @param id anObject - the object to add the controller.
*/
- (void)addObject:(id)object
{
    if (![self canAdd])
        return;

    var willClearPredicate = NO;

    if (_clearsFilterPredicateOnInsertion && _filterPredicate)
    {
        [self willChangeValueForKey:@"filterPredicate"];
        willClearPredicate = YES;
    }

    [self willChangeValueForKey:@"content"];

    /*
    If the content array is bound then our addObject: message below will cause the observed
    array to change. The binding will call setContent:_contentObject on this array
    controller to let it know about the change. We want to ignore that message since we
    A) already have the right _contentObject and B) properly update _arrangedObjects
    by hand below.
    */
    _disableSetContent = YES;
    [_contentObject addObject:object];

    // Allow handlesContentAsCompoundValue reverse sets to trigger.
    [[CPBinder getBinding:@"contentArray" forObject:self] _contentArrayDidChange];

    _disableSetContent = NO;

    if (willClearPredicate)
    {
        // Full rearrange needed due to changed filter.
        _filterPredicate = nil;
        [self _rearrangeObjects];
    }
    else if (_filterPredicate === nil || [_filterPredicate evaluateWithObject:object])
    {
        // Insert directly into the array.
        var pos = [_arrangedObjects insertObject:object inArraySortedByDescriptors:_sortDescriptors];

        // selectionIndexes change notification will be fired as a result of the
        // content change. Don't fire manually.
        if (_selectsInsertedObjects)
            [self __setSelectionIndex:pos];
        else
            [_selectionIndexes shiftIndexesStartingAtIndex:pos by:1];
    }
    /*
    else if (_filterPredicate !== nil)
    ...
    // Implies _filterPredicate && ![_filterPredicate evaluateWithObject:object], so the new object does
    // not appear in arrangedObjects and we do not have to update at all.
    */

    // TODO: Remove these lines when granular notifications are implemented
    var proxy = [_CPKVOProxy proxyForObject:self];
    [proxy setAdding:YES];

    // This will also send notifications for arrangedObjects.
    [self didChangeValueForKey:@"content"];

    if (willClearPredicate)
        [self didChangeValueForKey:@"filterPredicate"];

    // TODO: Remove this line when granular notifications are implemented
    [proxy setAdding:NO];
}

/*!
    Adds an object at a given index in the receiver's arrangedObjects. Also add the object
    to the content collection (although at the end rather than the given index).

    @param id anObject - The object to add to the collection.
    @param int anIndex - The index to insert the object at.
*/
- (void)insertObject:(id)anObject atArrangedObjectIndex:(int)anIndex
{
    if (![self canAdd])
        return;

    var willClearPredicate = NO;

    if (_clearsFilterPredicateOnInsertion && _filterPredicate)
    {
        [self willChangeValueForKey:@"filterPredicate"];
        willClearPredicate = YES;
    }

    [self willChangeValueForKey:@"content"];

    /*
    See _disableSetContent explanation in addObject:.
    */
    _disableSetContent = YES;

    // The atArrangedObjectIndex: part of this method's name only refers to where the
    // object goes in arrangedObjects, not in the content array. So use addObject:,
    // not insertObject:atIndex: here for speed.
    [_contentObject addObject:anObject];
    // Allow handlesContentAsCompoundValue reverse sets to trigger.
    [[CPBinder getBinding:@"contentArray" forObject:self] _contentArrayDidChange];

    _disableSetContent = NO;

    if (willClearPredicate)
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

    var proxy = [_CPKVOProxy proxyForObject:self];
    [proxy setAdding:YES];

    [self didChangeValueForKey:@"content"];

    if (willClearPredicate)
        [self didChangeValueForKey:@"filterPredicate"];

    [proxy setAdding:NO];
}

/*!
    Removes a given object from the receiver's collection.

    @param id anObject - The object to remove from the collection.
*/
- (void)removeObject:(id)object
{
    [self willChangeValueForKey:@"content"];

    // See _disableSetContent explanation in addObject:.
    _disableSetContent = YES;

    [_contentObject removeObject:object];
    // Allow handlesContentAsCompoundValue reverse sets to trigger.
    [[CPBinder getBinding:@"contentArray" forObject:self] _contentArrayDidChange];

    _disableSetContent = NO;

    if (_filterPredicate === nil || [_filterPredicate evaluateWithObject:object])
    {
        // selectionIndexes change notification will be fired as a result of the
        // content change. Don't fire manually.
        var pos = [_arrangedObjects indexOfObject:object];

        [_arrangedObjects removeObjectAtIndex:pos];
        [_selectionIndexes shiftIndexesStartingAtIndex:pos by:-1];

        // This will automatically handle the avoidsEmptySelection case.
        [self __setSelectionIndexes:_selectionIndexes];
    }

    [self didChangeValueForKey:@"content"];
}

/*!
    Creates and adds a new object to the receiver's content and arranged objects.

    @param id sender - The sender of the message.
*/
- (void)add:(id)sender
{
    if (![self canAdd])
        return;

    var newObject = [self automaticallyPreparesContent] ? [self newObject] : [self _defaultNewObject];

    [self addObject:newObject];
}

/*!
    Creates a new object and inserts it into the receiver's content array.
    @param id sender - The sender of the message.
*/
- (void)insert:(id)sender
{
    if (![self canInsert])
        return;

    var newObject = [self automaticallyPreparesContent] ? [self newObject] : [self _defaultNewObject],
        lastSelectedIndex = [_selectionIndexes lastIndex];

    if (lastSelectedIndex !== CPNotFound)
        [self insertObject:newObject atArrangedObjectIndex:lastSelectedIndex];
    else
        [self addObject:newObject];
}

/*!
    Removes the controller's selected objects from the controller's collection.
    @param id sender - The sender of the message.
*/
- (void)remove:(id)sender
{
    [self removeObjectsAtArrangedObjectIndexes:_selectionIndexes];
}

/*!
    Removes the object at the specified index in the controller's arranged objects from the content array.
    @param int index - index of the object to remove.
*/
- (void)removeObjectAtArrangedObjectIndex:(int)index
{
    [self removeObjectsAtArrangedObjectIndexes:[CPIndexSet indexSetWithIndex:index]];
}

/*!
    Removes the objects at the specified indexes in the controller's arranged objects from the content array.
    @param CPIndexSet indexes - indexes of the objects to remove.
*/
- (void)removeObjectsAtArrangedObjectIndexes:(CPIndexSet)anIndexSet
{
    [self willChangeValueForKey:@"content"];

    /*
    See _disableSetContent explanation in addObject:.
    */
    _disableSetContent = YES;

    var arrangedObjects = [self arrangedObjects],
        position = CPNotFound,
        newSelectionIndexes = [_selectionIndexes copy];

    [anIndexSet enumerateIndexesWithOptions:CPEnumerationReverse
                                 usingBlock:function(anIndex)
        {
            var object = [arrangedObjects objectAtIndex:anIndex];

            // First try the simple case which should work if there are no sort descriptors.
            if ([_contentObject objectAtIndex:anIndex] === object)
                [_contentObject removeObjectAtIndex:anIndex];
            else
            {
                // Since we don't have a reverse mapping between the sorted order and the
                // unsorted one, we'll just simply have to remove an arbitrary pointer. It might
                // be the 'wrong' one - as in not the one the user selected - but the wrong
                // one is still just another pointer to the same object, so the user will not
                // be able to see any difference.
                var contentIndex = [_contentObject indexOfObjectIdenticalTo:object];
                [_contentObject removeObjectAtIndex:contentIndex];
            }
            [arrangedObjects removeObjectAtIndex:anIndex];

            if (!_avoidsEmptySelection || [newSelectionIndexes count] > 1)
            {
                [newSelectionIndexes removeIndex:anIndex];
                [newSelectionIndexes shiftIndexesStartingAtIndex:anIndex by:-1];
            }
            else if ([newSelectionIndexes lastIndex] !== anIndex)
                [newSelectionIndexes shiftIndexesStartingAtIndex:anIndex by:-1];
        }];

    // Allow handlesContentAsCompoundValue reverse sets to trigger.
    [[CPBinder getBinding:@"contentArray" forObject:self] _contentArrayDidChange];
    _disableSetContent = NO;

    // This will automatically handle the avoidsEmptySelection case.
    [self __setSelectionIndexes:newSelectionIndexes];

    [self didChangeValueForKey:@"content"];
}

/*!
    Adds an array of objects to the controller's collection.

    @param CPArray anArray - The array of objects to add to the collection.
*/
- (void)addObjects:(CPArray)objects
{
    if (![self canAdd])
        return;

    var contentArray = [self contentArray],
        count = [objects count];

    for (var i = 0; i < count; i++)
        [contentArray addObject:[objects objectAtIndex:i]];

    [self setContent:contentArray];
    // Allow handlesContentAsCompoundValue reverse sets to trigger.
    [[CPBinder getBinding:@"contentArray" forObject:self] _contentArrayDidChange];
}

/*!
    Removes an array of objects from the collection.
    @param CPArray anArray - The array of objects to remove
*/
- (void)removeObjects:(CPArray)objects
{
    [self _removeObjects:objects];
}

/*!
    @ignore
*/
- (void)_removeObjects:(CPArray)objects
{
    [self willChangeValueForKey:@"content"];

    // See _disableSetContent explanation in addObject:.
    _disableSetContent = YES;

    [_contentObject removeObjectsInArray:objects];
    // Allow handlesContentAsCompoundValue reverse sets to trigger.
    [[CPBinder getBinding:@"contentArray" forObject:self] _contentArrayDidChange];

    _disableSetContent = NO;

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

/*!
    Returns a BOOL indicating whether an object can be inserted into the controller's collection.
    @return BOOL - YES if an object can be inserted, otherwise NO.
*/
- (BOOL)canInsert
{
    return [self isEditable];
}

@end

@implementation CPArrayController (CPBinder)

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding == @"contentArray")
        return [_CPArrayControllerContentBinder class];

    return [super _binderClassForBinding:aBinding];
}

@end

@implementation _CPArrayControllerContentBinder : CPBinder

- (void)setValueFor:(CPString)aBinding
{
    var destination = [_info objectForKey:CPObservedObjectKey],
        keyPath = [_info objectForKey:CPObservedKeyPathKey],
        options = [_info objectForKey:CPOptionsKey],
        isCompound = [self handlesContentAsCompoundValue],
        dotIndex = keyPath.lastIndexOf("."),
        firstPart = dotIndex !== CPNotFound ? keyPath.substring(0, dotIndex) : nil,
        isSelectionProxy = firstPart && [[destination valueForKeyPath:firstPart] isKindOfClass:CPControllerSelectionProxy],
        newValue;

    if (!isCompound && !isSelectionProxy)
    {
        newValue = [destination mutableArrayValueForKeyPath:keyPath];
    }
    else
    {
        // 1. If handlesContentAsCompoundValue we cannot just set up a proxy.
        // Every read and every write must go through transformValue and
        // reverseTransformValue, and the resulting object cannot be described by
        // a key path.

        // 2. If isSelectionProxy, we don't want to proxy a proxy - that's bad
        // for performance and won't work with markers.

        newValue = [destination valueForKeyPath:keyPath];
    }

    var isPlaceholder = CPIsControllerMarker(newValue);

    if (isPlaceholder)
    {
        if (newValue === CPNotApplicableMarker && [options objectForKey:CPRaisesForNotApplicableKeysBindingOption])
        {
           [CPException raise:CPGenericException
                       reason:@"can't transform non applicable key on: " + _source + " value: " + newValue];
        }

        newValue = [self _placeholderForMarker:newValue];

        // This seems to be what Cocoa does.
        if (!newValue)
            newValue = [CPMutableArray array];
    }
    else
        newValue = [self transformValue:newValue withOptions:options];

    if (isCompound)
    {
        // Make sure we can edit our copy of the content. TODO In Cocoa, this copy
        // appears to be deferred until the array actually needs to be edited.
        newValue = [newValue mutableCopy];
    }

    [_source setValue:newValue forKey:aBinding];
}

- (void)_contentArrayDidChange
{
    // When handlesContentAsCompoundValue == YES, it is not sufficient to modify the content object
    // in place because what we are holding is an array 'unwrapped' from a compound value by
    // a value transformer. So when we modify it we need a reverse set and transform to create
    // a new compound value.
    //
    // (The Cocoa documentation on the subject is not very clear but after substantial
    // experimentation this seems both reasonable and compliant.)
    if ([self handlesContentAsCompoundValue])
    {
        var destination = [_info objectForKey:CPObservedObjectKey],
            keyPath = [_info objectForKey:CPObservedKeyPathKey];

        [self suppressSpecificNotificationFromObject:destination keyPath:keyPath];
        [self reverseSetValueFor:@"contentArray"];
        [self unsuppressSpecificNotificationFromObject:destination keyPath:keyPath];
    }
}

@end

var CPArrayControllerAvoidsEmptySelection             = @"CPArrayControllerAvoidsEmptySelection",
    CPArrayControllerClearsFilterPredicateOnInsertion = @"CPArrayControllerClearsFilterPredicateOnInsertion",
    CPArrayControllerFilterRestrictsInsertion         = @"CPArrayControllerFilterRestrictsInsertion",
    CPArrayControllerPreservesSelection               = @"CPArrayControllerPreservesSelection",
    CPArrayControllerSelectsInsertedObjects           = @"CPArrayControllerSelectsInsertedObjects",
    CPArrayControllerAlwaysUsesMultipleValuesMarker   = @"CPArrayControllerAlwaysUsesMultipleValuesMarker",
    CPArrayControllerAutomaticallyRearrangesObjects   = @"CPArrayControllerAutomaticallyRearrangesObjects";

@implementation CPArrayController (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _avoidsEmptySelection = [aCoder decodeBoolForKey:CPArrayControllerAvoidsEmptySelection];
        _clearsFilterPredicateOnInsertion = [aCoder decodeBoolForKey:CPArrayControllerClearsFilterPredicateOnInsertion];
        _filterRestrictsInsertion = [aCoder decodeBoolForKey:CPArrayControllerFilterRestrictsInsertion];
        _preservesSelection = [aCoder decodeBoolForKey:CPArrayControllerPreservesSelection];
        _selectsInsertedObjects = [aCoder decodeBoolForKey:CPArrayControllerSelectsInsertedObjects];
        _alwaysUsesMultipleValuesMarker = [aCoder decodeBoolForKey:CPArrayControllerAlwaysUsesMultipleValuesMarker];
        _automaticallyRearrangesObjects = [aCoder decodeBoolForKey:CPArrayControllerAutomaticallyRearrangesObjects];
        _sortDescriptors = [CPArray array];

        if (![self content] && [self automaticallyPreparesContent])
            [self prepareContent];
        else if (![self content])
            [self _setContentArray:[]];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeBool:_avoidsEmptySelection forKey:CPArrayControllerAvoidsEmptySelection];
    [aCoder encodeBool:_clearsFilterPredicateOnInsertion forKey:CPArrayControllerClearsFilterPredicateOnInsertion];
    [aCoder encodeBool:_filterRestrictsInsertion forKey:CPArrayControllerFilterRestrictsInsertion];
    [aCoder encodeBool:_preservesSelection forKey:CPArrayControllerPreservesSelection];
    [aCoder encodeBool:_selectsInsertedObjects forKey:CPArrayControllerSelectsInsertedObjects];
    [aCoder encodeBool:_alwaysUsesMultipleValuesMarker forKey:CPArrayControllerAlwaysUsesMultipleValuesMarker];
    [aCoder encodeBool:_automaticallyRearrangesObjects forKey:CPArrayControllerAutomaticallyRearrangesObjects];
}

- (void)awakeFromCib
{
    [self _selectionWillChange];
    [self _selectionDidChange];
}

@end
