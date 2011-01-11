
@import <Foundation/CPDictionary.j>
@import <Foundation/CPCountedSet.j>

@import "CPController.j"


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

- (id)init
{
    return [self initWithContent:nil];
}

- (id)initWithContent:(id)aContent
{
    if (self = [super init])
    {
        [self setContent:aContent];
        [self setEditable:YES];
        [self setObjectClass:[CPMutableDictionary class]];

        _observedKeys = [[CPCountedSet alloc] init];
    }

    return self;
}

- (id)content
{
    return _contentObject;
}

- (void)setContent:(id)aContent
{
    [self willChangeValueForKey:@"contentObject"];
    [self _selectionWillChange];

    _contentObject = aContent;

    [self didChangeValueForKey:@"contentObject"];
    [self _selectionDidChange];
}

- (void)_setContentObject:(id)aContent
{
    [self setContent:aContent];
}

- (id)_contentObject
{
    return [self content];
}

- (void)setAutomaticallyPreparesContent:(BOOL)shouldAutomaticallyPrepareContent
{
    _automaticallyPreparesContent = shouldAutomaticallyPrepareContent;
}

- (BOOL)automaticallyPreparesContent
{
    return _automaticallyPreparesContent;
}

- (void)prepareContent
{
    [self setContent:[self newObject]];
}

- (void)setObjectClass:(Class)aClass
{
    _objectClass = aClass;
}

- (Class)objectClass
{
    return _objectClass;
}

- (id)_defaultNewObject
{
    return [[[self objectClass] alloc] init];
}

- (id)newObject
{
    return [self _defaultNewObject];
}

- (void)addObject:(id)anObject
{
    [self setContent:anObject];

    var binderClass = [[self class] _binderClassForBinding:@"contentObject"];
    [[binderClass getBinding:@"contentObject" forObject:self] reverseSetValueFor:@"contentObject"];
}

- (void)removeObject:(id)anObject
{
    if ([self content] === anObject)
        [self setContent:nil];

    var binderClass = [[self class] _binderClassForBinding:@"contentObject"];
    [[binderClass getBinding:@"contentObject" forObject:self] reverseSetValueFor:@"contentObject"];
}

- (void)add:(id)aSender
{
    // FIXME: This should happen on the next run loop?
    [self addObject:[self newObject]];
}

- (BOOL)canAdd
{
    return [self isEditable];
}

- (void)remove:(id)aSender
{
    // FIXME: This should happen on the next run loop?
    [self removeObject:[self content]];
}

- (BOOL)canRemove
{
    return [self isEditable] && [[self selectedObjects] count];
}

- (void)setEditable:(BOOL)shouldBeEditable
{
    _isEditable = shouldBeEditable;
}

- (BOOL)isEditable
{
    return _isEditable;
}

- (CPArray)selectedObjects
{
    return [[_CPObservableArray alloc] initWithArray:[_contentObject]];
}

- (id)selection
{
    return _selection;
}

- (void)_selectionWillChange
{
    [_selection controllerWillChange];
    [self willChangeValueForKey:@"selection"];
}

- (void)_selectionDidChange
{
    if (_selection === undefined || _selection === nil)
        _selection = [[CPControllerSelectionProxy alloc] initWithController:self];

    [_selection controllerDidChange];
    [self didChangeValueForKey:@"selection"];
}

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
        [self setAutomaticallyPreparesContent:[aCoder decodeBoolForKey:CPObjectControllerAutomaticallyPreparesContentKey] || NO];
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
    return "<_CPObservableArray: "+[super description]+" >";
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
    if (aKeyPath.indexOf("@") === 0)
    {
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
    if (aKeyPath.indexOf("@") === 0)
    {
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
            operator = keyPath.indexOf(".") === 0;

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
    for (var i = 0, count = [_observationProxies count]; i < count; i++)
    {
        var proxy = [_observationProxies objectAtIndex:i],
            keyPath = [proxy keyPath],
            operator = keyPath.indexOf(".") === 0;

        if (operator)
            [self willChangeValueForKey:keyPath];

        [anObject removeObserver:proxy forKeyPath:keyPath];

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
            operator = keyPath.indexOf(".") === 0;

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
        _cachedValues = [CPDictionary dictionary];
        _observationProxies = [CPArray array];
        _controller = aController;
        _observedObjectsByKeyPath = {};
    }

    return self;
}

- (id)_controllerMarkerForValues:(CPArray)theValues
{
 var count = [theValues count];

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

            for (var i = 0, count= [theValues count]; i < count && value != CPMultipleValuesMarker; i++)
            {
                if (![value isEqual:[theValues objectAtIndex:i]])
                    value = CPMultipleValuesMarker;
            }
        }
    }

    return value;
}

- (id)valueForKeyPath:(CPString)theKeyPath
{
    var values = [[_controller selectedObjects] valueForKeyPath:theKeyPath];
    value = [self _controllerMarkerForValues:values];

    [_cachedValues setObject:value forKey:theKeyPath];

    return value;
}

- (id)valueForKey:(CPString)theKeyPath
{
    return [self valueForKeyPath:theKeyPath];
}

- (void)setValue:(id)theValue forKeyPath:(CPString)theKeyPath
{
    [[_controller selectedObjects] setValue:theValue forKeyPath:theKeyPath];
    [_cachedValues removeObjectForKey:theKeyPath];
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

    // We keep are reference to the observed objects
    // because the removeObserver: will be called after the selection changes
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

    _observedObjects = nil;
}

@end
