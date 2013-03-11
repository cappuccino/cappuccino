/*
 * CPObjectController.j
 * AppKit
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

@import <Foundation/CPDictionary.j>
@import <Foundation/CPCountedSet.j>
@import <Foundation/_CPCollectionKVCOperators.j>

@import "CPController.j"
@import "CPKeyValueBinding.j"

/*!
    @class

    CPObjectController is a bindings-compatible controller class.
    Properties of the content object of an object of this class can be bound to user interface elements to change and access their values.

    The content of an CPObjectController instance is an CPMutableDictionary object by default.
    This allows a single CPObjectController instance to be used to manage several properties accessed by key value paths.
    The default content object class can be changed by calling setObjectClass:, which a subclass must override.
*/
@implementation CPObjectController : CPController
{
    id              _contentObject;
    id              _selection;

    Class           _objectClass;
    CPString        _objectClassName;

    BOOL            _isEditable;
    BOOL            _automaticallyPreparesContent;

    CPCountedSet    _observedKeys;
}

+ (id)initialize
{
    if (self !== [CPObjectController class])
        return;

    [self exposeBinding:@"editable"];
    [self exposeBinding:@"contentObject"];
}

+ (CPSet)keyPathsForValuesAffectingContentObject
{
    return [CPSet setWithObjects:"content"];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(CPString)aKey
{
    if (aKey === @"contentObject")
        return NO;

    return YES;
}

+ (CPSet)keyPathsForValuesAffectingCanAdd
{
    return [CPSet setWithObject:"editable"];
}

+ (CPSet)keyPathsForValuesAffectingCanInsert
{
    return [CPSet setWithObject:"editable"];
}

+ (CPSet)keyPathsForValuesAffectingCanRemove
{
    return [CPSet setWithObjects:"editable", "selection"];
}

/*!
    @ignore
*/
- (id)init
{
    return [self initWithContent:nil];
}

/*!
    Inits and returns a CPObjectController object with the given content.

    @param id aContent - The object the controller will use.
    @return id the CPObjectConroller instance.
*/
- (id)initWithContent:(id)aContent
{
    if (self = [super init])
    {
        [self setEditable:YES];
        [self setObjectClass:[CPMutableDictionary class]];

        _observedKeys = [[CPCountedSet alloc] init];
        _selection = [[CPControllerSelectionProxy alloc] initWithController:self];

        [self setContent:aContent];
    }

    return self;
}

/*!
    Returns the controller's content object.
    @return id - The content object of the controller.
*/
- (id)content
{
    return _contentObject;
}

/*!
    Sets the content object for the controller.
    @param id aContent - The new content object for the controller.
*/
- (void)setContent:(id)aContent
{
    [self willChangeValueForKey:@"contentObject"];
    [self _selectionWillChange];

    _contentObject = aContent;

    [self _selectionDidChange];
    [self didChangeValueForKey:@"contentObject"];
}

/*!
    @ignore
*/
- (void)_setContentObject:(id)aContent
{
    [self setContent:aContent];
}

/*!
    @ignore
*/
- (id)_contentObject
{
    return [self content];
}

/*!
    Sets whether the controller automatically creates and inserts new content objects automatically when loading from a cib file.
    If you pass YES and the controller uses prepareContent to create the content object.
    The default is NO.

    @param BOOL shouldAutomaticallyPrepareContent - YES if the content should be prepared, otherwise NO.
*/
- (void)setAutomaticallyPreparesContent:(BOOL)shouldAutomaticallyPrepareContent
{
    _automaticallyPreparesContent = shouldAutomaticallyPrepareContent;
}

/*!
    Returns if the controller prepares the content automatically.
    @return BOOL - YES if the content is prepared, otherwise NO.
*/
- (BOOL)automaticallyPreparesContent
{
    return _automaticallyPreparesContent;
}

/*!
    Overridden by a subclass that require control over the creation of new objects.
*/
- (void)prepareContent
{
    [self setContent:[self newObject]];
}

/*!
    Sets the object class when creating new objects.
    @param Class - the class of new objects that will be created.
*/
- (void)setObjectClass:(Class)aClass
{
    _objectClass = aClass;
}

/*!
    Returns the class of what new objects will be when they are created.

    @return Class - The class of new objects.
*/
- (Class)objectClass
{
    return _objectClass;
}

/*!
    @ignore
*/
- (id)_defaultNewObject
{
    return [[[self objectClass] alloc] init];
}

/*!
    Creates and returns a new object of the appropriate class.
    @return id - The object created.
*/
- (id)newObject
{
    return [self _defaultNewObject];
}

/*!
    Sets the controller's content object.
    @param id anObject - The object to set for the controller.
*/
- (void)addObject:(id)anObject
{
    [self setContent:anObject];

    var binderClass = [[self class] _binderClassForBinding:@"contentObject"];
    [[binderClass getBinding:@"contentObject" forObject:self] reverseSetValueFor:@"contentObject"];
}

/*!
    Removes a given object from the controller.
    @param id anObject - The object to remove from the receiver.
*/
- (void)removeObject:(id)anObject
{
    if ([self content] === anObject)
        [self setContent:nil];

    var binderClass = [[self class] _binderClassForBinding:@"contentObject"];
    [[binderClass getBinding:@"contentObject" forObject:self] reverseSetValueFor:@"contentObject"];
}

/*!
    Creates and adds a sets the object as the controller's content.
    @param id aSender - The sender of the message.
*/
- (void)add:(id)aSender
{
    // FIXME: This should happen on the next run loop?
    [self addObject:[self newObject]];
}

/*!
    @return BOOL - YES if you can added to the controller using add:
*/
- (BOOL)canAdd
{
    return [self isEditable];
}

/*!
    Removes the content object from the controller.
    @param id aSender - The sender of the message.
*/
- (void)remove:(id)aSender
{
    // FIXME: This should happen on the next run loop?
    [self removeObject:[self content]];
}

/*!
    @return BOOL - Returns YES if you can remove the controller's content using remove:
*/
- (BOOL)canRemove
{
    return [self isEditable] && [[self selectedObjects] count];
}

/*!
    Sets whether the controller allows for the editing of the content.
    @param BOOL shouldBeEditable - YES if the content should be editable, otherwise NO.
*/
- (void)setEditable:(BOOL)shouldBeEditable
{
    _isEditable = shouldBeEditable;
}

/*!
    @return BOOL - Returns YES if the content of the controller is editable, otherwise NO.
*/
- (BOOL)isEditable
{
    return _isEditable;
}

/*!
    @return CPArray - Returns an array of all objects to be affected by editing.
*/
- (CPArray)selectedObjects
{
    return [[_CPObservableArray alloc] initWithArray:[_contentObject]];
}

/*!
    Returns a proxy object representing the controller's selection.
*/
- (id)selection
{
    return _selection;
}

/*!
    @ignore
*/
- (void)_selectionWillChange
{
    [_selection controllerWillChange];
    [self willChangeValueForKey:@"selection"];
}

/*!
    @ignore
*/
- (void)_selectionDidChange
{
    if (_selection === undefined || _selection === nil)
        _selection = [[CPControllerSelectionProxy alloc] initWithController:self];

    [_selection controllerDidChange];
    [self didChangeValueForKey:@"selection"];
}

/*!
    @return id - Returns the keys which are being observed.
*/
- (id)observedKeys
{
    return _observedKeys;
}

- (void)addObserver:(id)anObserver forKeyPath:(CPString)aKeyPath options:(CPKeyValueObservingOptions)options context:(id)context
{
   [_observedKeys addObject:aKeyPath];
   [super addObserver:anObserver forKeyPath:aKeyPath options:options context:context];
}

- (void)removeObserver:(id)anObserver forKeyPath:(CPString)aKeyPath
{
   [_observedKeys removeObject:aKeyPath];
   [super removeObserver:anObserver forKeyPath:aKeyPath];
}

@end

var CPObjectControllerContentKey                        = @"CPObjectControllerContentKey",
    CPObjectControllerObjectClassNameKey                = @"CPObjectControllerObjectClassNameKey",
    CPObjectControllerIsEditableKey                     = @"CPObjectControllerIsEditableKey",
    CPObjectControllerAutomaticallyPreparesContentKey   = @"CPObjectControllerAutomaticallyPreparesContentKey";

@implementation CPObjectController (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        var objectClassName = [aCoder decodeObjectForKey:CPObjectControllerObjectClassNameKey],
            objectClass = CPClassFromString(objectClassName);

        [self setObjectClass:objectClass || [CPMutableDictionary class]];
        [self setEditable:[aCoder decodeBoolForKey:CPObjectControllerIsEditableKey]];
        [self setAutomaticallyPreparesContent:[aCoder decodeBoolForKey:CPObjectControllerAutomaticallyPreparesContentKey]];
        [self setContent:[aCoder decodeObjectForKey:CPObjectControllerContentKey]];

        _observedKeys = [[CPCountedSet alloc] init];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:[self content] forKey:CPObjectControllerContentKey];

    if (_objectClass)
        [aCoder encodeObject:CPStringFromClass(_objectClass) forKey:CPObjectControllerObjectClassNameKey];
    else if (_objectClassName)
        [aCoder encodeObject:_objectClassName forKey:CPObjectControllerObjectClassNameKey];

    [aCoder encodeBool:[self isEditable] forKey:CPObjectControllerIsEditableKey];
    [aCoder encodeBool:[self automaticallyPreparesContent] forKey:CPObjectControllerAutomaticallyPreparesContentKey];
}

- (void)awakeFromCib
{
    if (![self content] && [self automaticallyPreparesContent])
        [self prepareContent];
}

@end

@implementation _CPObservationProxy : CPObject
{
    id      _keyPath;
    id      _observer;
    id      _object;

    BOOL    _notifyObject;

    id      _context;
    int     _options;
}

- (id)initWithKeyPath:(id)aKeyPath observer:(id)anObserver object:(id)anObject
{
    if (self = [super init])
    {
        _keyPath  = aKeyPath;
        _observer = anObserver;
        _object   = anObject;
    }

    return self;
}

- (id)observer
{
    return _observer;
}

- (id)keyPath
{
    return _keyPath;
}

- (id)context
{
   return _context;
}

- (int)options
{
   return _options;
}

- (void)setNotifyObject:(BOOL)notify
{
   _notifyObject = notify;
}

- (BOOL)isEqual:(id)anObject
{
    if ([anObject class] === [self class])
    {
        if (anObject._observer === _observer && [anObject._keyPath isEqual:_keyPath] && [anObject._object isEqual:_object])
            return YES;
    }

    return NO;
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)change context:(id)context
{
    if (_notifyObject)
        [_object observeValueForKeyPath:aKeyPath ofObject:_object change:change context:context];

    [_observer observeValueForKeyPath:aKeyPath ofObject:_object change:change context:context];
}

- (CPString)description
{
    return [super description] + [CPString stringWithFormat:@"observation proxy for %@ on key path %@", _observer, _keyPath];
}

@end

// FIXME: This should subclass CPMutableArray not _CPJavaScriptArray
@implementation _CPObservableArray : _CPJavaScriptArray
{
    CPArray     _observationProxies;
}

+ (id)alloc
{
    var a = [];
    a.isa = self;

    var ivars = class_copyIvarList(self),
        count = ivars.length;

    while (count--)
        a[ivar_getName(ivars[count])] = nil;

    return a;
}

- (CPString)description
{
    return "<_CPObservableArray: " + [super description] + " >";
}

- (id)initWithArray:(CPArray)anArray
{
    self = [super initWithArray:anArray];

    self.isa = [_CPObservableArray class];
    self._observationProxies = [];

    return self;
}

- (void)addObserver:(id)anObserver forKeyPath:(CPString)aKeyPath options:(CPKeyValueObservingOptions)options context:(id)context
{
    if (aKeyPath.charAt(0) === "@")
    {
        // Simple collection operators are scalar and can't be proxied
        if ([_CPCollectionKVCOperator isSimpleCollectionOperator:aKeyPath])
            return;

        var proxy = [[_CPObservationProxy alloc] initWithKeyPath:aKeyPath observer:anObserver object:self];

        proxy._options = options;
        proxy._context = context;

        [_observationProxies addObject:proxy];

        var dotIndex = aKeyPath.indexOf("."),
            remaining = aKeyPath.substring(dotIndex + 1),
            indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self count])];

        [self addObserver:proxy toObjectsAtIndexes:indexes forKeyPath:remaining options:options context:context];
    }
    else
    {
        var indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self count])];
        [self addObserver:anObserver toObjectsAtIndexes:indexes forKeyPath:aKeyPath options:options context:context];
    }
}

- (void)removeObserver:(id)anObserver forKeyPath:(CPString)aKeyPath
{
    if (aKeyPath.charAt(0) === "@")
    {
        // Simple collection operators are scalar and can't be proxied
        if ([_CPCollectionKVCOperator isSimpleCollectionOperator:aKeyPath])
            return;

        var proxy = [[_CPObservationProxy alloc] initWithKeyPath:aKeyPath observer:anObserver object:self],
            index = [_observationProxies indexOfObject:proxy];

        proxy = [_observationProxies objectAtIndex:index];

        var dotIndex = aKeyPath.indexOf("."),
            remaining = aKeyPath.substring(dotIndex + 1),
            indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self count])];

        [self removeObserver:proxy fromObjectsAtIndexes:indexes forKeyPath:remaining];
    }
    else
    {
        var indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self count])];
        [self removeObserver:anObserver fromObjectsAtIndexes:indexes forKeyPath:aKeyPath];
    }
}

- (void)insertObject:(id)anObject atIndex:(unsigned)anIndex
{
    for (var i = 0, count = [_observationProxies count]; i < count; i++)
    {
        var proxy = [_observationProxies objectAtIndex:i],
            keyPath = [proxy keyPath],
            operator = keyPath.charAt(0) === ".";

        if (operator)
            [self willChangeValueForKey:keyPath];

        [anObject addObserver:proxy forKeyPath:keyPath options:[proxy options] context:[proxy context]];

        if (operator)
            [self didChangeValueForKey:keyPath];
    }

    [super insertObject:anObject atIndex:anIndex];
}

- (void)removeObjectAtIndex:(unsigned)anIndex
{
    var currentObject = [self objectAtIndex:anIndex];

    for (var i = 0, count = [_observationProxies count]; i < count; i++)
    {
        var proxy = [_observationProxies objectAtIndex:i],
            keyPath = [proxy keyPath],
            operator = keyPath.charAt(0) === ".";

        if (operator)
            [self willChangeValueForKey:keyPath];

        [currentObject removeObserver:proxy forKeyPath:keyPath];

        if (operator)
            [self didChangeValueForKey:keyPath];
    }

    [super removeObjectAtIndex:anIndex];
}

- (_CPObservableArray)objectsAtIndexes:(CPIndexSet)theIndexes
{
    return [_CPObservableArray arrayWithArray:[super objectsAtIndexes:theIndexes]];
}

- (void)addObject:(id)anObject
{
   [self insertObject:anObject atIndex:[self count]];
}

- (void)removeLastObject
{
   [self removeObjectAtIndex:[self count]];
}

- (void)replaceObjectAtIndex:(unsigned)anIndex withObject:(id)anObject
{
    var currentObject = [self objectAtIndex:anIndex];

    for (var i = 0, count = [_observationProxies count]; i < count; i++)
    {
        var proxy = [_observationProxies objectAtIndex:i],
            keyPath = [proxy keyPath],
            operator = keyPath.charAt(0) === ".";

        if (operator)
            [self willChangeValueForKey:keyPath];

        [currentObject removeObserver:proxy forKeyPath:keyPath];
        [anObject addObserver:proxy forKeyPath:keyPath options:[proxy options] context:[proxy context]];

        if (operator)
            [self didChangeValueForKey:keyPath];
    }

    [super replaceObjectAtIndex:anIndex withObject:anObject];
}

@end

@implementation CPControllerSelectionProxy : CPObject
{
    id                  _controller;
    id                  _keys;

    CPDictionary        _cachedValues;
    CPArray             _observationProxies;

    Object              _observedObjectsByKeyPath;
}

- (id)initWithController:(id)aController
{
    if (self = [super init])
    {
        _cachedValues = @{};
        _observationProxies = [CPArray array];
        _controller = aController;
        _observedObjectsByKeyPath = {};
    }

    return self;
}

- (id)_controllerMarkerForValues:(CPArray)theValues
{
    var count = [theValues count],
        value;

    if (!count)
        value = CPNoSelectionMarker;
    else if (count === 1)
        value = [theValues objectAtIndex:0];
    else
    {
        if ([_controller alwaysUsesMultipleValuesMarker])
            value = CPMultipleValuesMarker;
        else
        {
            value = [theValues objectAtIndex:0];

            for (var i = 0, count = [theValues count]; i < count && value != CPMultipleValuesMarker; i++)
            {
                if (![value isEqual:[theValues objectAtIndex:i]])
                    value = CPMultipleValuesMarker;
            }
        }
    }

    if (value === nil || value.isa && [value isEqual:[CPNull null]])
        value = CPNullMarker;

    return value;
}

- (id)valueForKeyPath:(CPString)theKeyPath
{
    var values = [[_controller selectedObjects] valueForKeyPath:theKeyPath];

    // Simple collection operators like @count return a scalar value, not an array or set
    if ([values isKindOfClass:CPArray] || [values isKindOfClass:CPSet])
    {
        var value = [self _controllerMarkerForValues:values];
        [_cachedValues setObject:value forKey:theKeyPath];

        return value;
    }
    else
        return values;
}

- (id)valueForKey:(CPString)theKeyPath
{
    return [self valueForKeyPath:theKeyPath];
}

- (void)setValue:(id)theValue forKeyPath:(CPString)theKeyPath
{
    [[_controller selectedObjects] setValue:theValue forKeyPath:theKeyPath];
    [_cachedValues removeObjectForKey:theKeyPath];

    // Allow handlesContentAsCompoundValue to work, based on observation of Cocoa's
    // NSArrayController - when handlesContentAsCompoundValue and setValue:forKey:@"selection.X"
    // is called, the array controller causes the compound value to be rewritten if
    // handlesContentAsCompoundValue == YES. Note that
    // A) this doesn't use observation (observe: X is not visible in backtraces)
    // B) it only happens through the selection proxy and not on arrangedObject.X, content.X
    // or even selectedObjects.X.
    // FIXME The main code for this should somehow be in CPArrayController and also work
    // for table based row edits.
    [[CPBinder getBinding:@"contentArray" forObject:_controller] _contentArrayDidChange];
}

- (void)setValue:(id)theValue forKey:(CPString)theKeyPath
{
    [self setValue:theKeyPath forKeyPath:theKeyPath];
}

- (unsigned)count
{
    return [_cachedValues count];
}

- (id)keyEnumerator
{
    return [_cachedValues keyEnumerator];
}

- (void)controllerWillChange
{
    _keys = [_cachedValues allKeys];

    if (!_keys)
        return;

    for (var i = 0, count = _keys.length; i < count; i++)
        [self willChangeValueForKey:_keys[i]];

    [_cachedValues removeAllObjects];
}

- (void)controllerDidChange
{
    [_cachedValues removeAllObjects];

    if (!_keys)
        return;

    for (var i = 0, count = _keys.length; i < count; i++)
        [self didChangeValueForKey:_keys[i]];

   _keys = nil;
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)change context:(id)context
{
    [_cachedValues removeObjectForKey:aKeyPath];
}

- (void)addObserver:(id)anObject forKeyPath:(CPString)aKeyPath options:(CPKeyValueObservingOptions)options context:(id)context
{
    var proxy = [[_CPObservationProxy alloc] initWithKeyPath:aKeyPath observer:anObject object:self];

    [proxy setNotifyObject:YES];
    [_observationProxies addObject:proxy];

    // We keep a reference to the observed objects because removeObserver: will be called after the selection changes.
    var observedObjects = [_controller selectedObjects];
    _observedObjectsByKeyPath[aKeyPath] = observedObjects;
    [observedObjects addObserver:proxy forKeyPath:aKeyPath options:options context:context];
}

- (void)removeObserver:(id)anObject forKeyPath:(CPString)aKeyPath
{
    var proxy = [[_CPObservationProxy alloc] initWithKeyPath:aKeyPath observer:anObject object:self],
        index = [_observationProxies indexOfObject:proxy];

    var observedObjects = _observedObjectsByKeyPath[aKeyPath];
    [observedObjects removeObserver:[_observationProxies objectAtIndex:index] forKeyPath:aKeyPath];

    [_observationProxies removeObjectAtIndex:index];

    _observedObjectsByKeyPath[aKeyPath] = nil;
}

@end
