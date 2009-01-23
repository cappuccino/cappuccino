
@import "CPController.j"

@implementation CPObjectController : CPController 
{
    id              _content;
    id              _selection;
    
    CPString        _defaultClassName;
    
    BOOL            _editable;
    BOOL            _automaticallyPreparesContent;
    
    CPCountedSet    _observedKeys;
}

+ (CPSet)keyPathsForValuesAffectingValueForCanAdd
{
    return [CPSet setWithObject:"editable"];
}

+ (CPSet)keyPathsForValuesAffectingValueForCanInsert
{
    return [CPSet setWithObject:"editable"];
}

+ (CPSet)keyPathsForValuesAffectingValueForCanRemove
{
    return [CPSet setWithObjects:"editable", "selection"];
}

- (id)content
{
    return _content;
}

- (void)setContent:(id)aValue
{
    [self setContent:aValue usingKVO:YES];
}

- (void)setContent:(id)aValue usingKVO:(BOOL)kvo
{
    if (_content === aValue)
        return;

    if (kvo)
        [self _selectionWillChange];
        
    _content = aValue;
    
    if (kvo)
        [self _selectionDidChange];
}

- (CPArray)selectedObjects
{
    return [_CPObservableArray arrayWithObject:_content];
}

- (id)selection
{
    return _selection;
}

- (void)setObjectClass:(Class)aClass
{
    _defaultClassName = [aClass name];
}

- (Class)objectClass
{
    return CPClassFromString(_defaultClassName);
}

- (id)_defaultNewObject
{
    return [[[self objectClass] alloc] init];
}

- (id)newObject
{
    return [self _defaultNewObject];
}

- (void)_selectionWillChange
{
    [self willChangeValueForKey:@"selection"];
}

- (void)_selectionDidChange
{
    if (_selection === undefined || _selection === nil)
        _selection = [[CPControllerSelectionProxy alloc] initWithController:self];

    [_selection controllerDidChange];
    [self didChangeValueForKey:@"selection"];
}

- (BOOL)canAdd
{
    return [self isEditable];
}

- (BOOL)canRemove
{
    return [self isEditable] && [[self selectedObjects] count];
}

- (BOOL)isEditable
{
    return _isEditable;
}

- (void)setEditable:(BOOL)isEditable
{
    _editable = isEditable;
}

- (BOOL)automaticallyPreparesContent
{
    return _automaticallyPreparesContent;
}

- (void)setAutomaticallyPreparesContent:(BOOL)aFlag
{
    _automaticallyPreparesContent = aFlag;
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

-(id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        _defaultClassName = [aCoder decodeObjectForKey:@"CPObjectClassName"];
        _editable = [aCoder decodeBoolForKey:@"CPEditable"];
        _automaticallyPreparesContent = [aCoder decodeBoolForKey:@"CPAutomaticallyPreparesContent"];
        
        _observedKeys = [[CPCountedSet alloc] init];
    }
    
    return self;
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
    if (self=[super init])
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
        [_object observeValueForKeyPath:_keyPath ofObject:_object change:change context:context];
    
    [_observer observeValueForKeyPath:_keyPath ofObject:_object change:change context:context];
}

- (CPString)description
{
    return [super description] + [CPString stringWithFormat:@"observation proxy for %@ on key path %@", _observer, _keyPath];
}

@end

@implementation _CPObservableArray : CPMutableArray
{
    CPArray     _array;
    CPArray     _observationProxies;
}

- (id)objectAtIndex:(unsigned)anIndex
{
    return [_array objectAtIndex:anIndex];
}

- (unsigned)count
{
    return [_array count];
}

- (id)initWithObjects:(CPArray)objects count:(unsigned)count
{
    if (self = [super init])
    {
        _array = [CPArray arrayWithObjects:objects count:count];
        _observationProxies = [];
    }

    return self;
}

-(void)addObserver:(id)anObserver forKeyPath:(CPString)aKeyPath options:(CPKeyValueObservingOptions)options context:(id)context;
{
    if (aKeyPath.indexOf("@") === 0)
    {
        var proxy = [[_CPObservationProxy alloc] initWithKeyPath:aKeyPath observer:anObserver object:self];
        
        proxy._options = options;
        proxy._context = context;
        
        [_observationProxies addObject:proxy];
        
        var dotIndex = aKeyPath.indexOf("."),
            remaining = aKeyPath.substring(dotIndex+1),
            indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [_array count])];
            
        [_array addObserver:proxy toObjectsAtIndexes:indexes forKeyPath:remaining options:options context:context];
    }
    else
    {
        var indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [_array count])];
        [_array addObserver:anObserver toObjectsAtIndexes:indexes forKeyPath:aKeyPath options:options context:context];
    }
}

- (void)removeObserver:(id)anObserver forKeyPath:(CPString)aKeyPath
{
    if (aKeyPath.indexOf("@") === 0)
    {
        var proxy = [[_CPObservationProxy alloc] initWithKeyPath:aKeyPath observer:anObsever object:self],
            index = [_observationProxies indexOfObject:proxy];

        proxy = [_observationProxies objectAtIndex:index];

        var dotIndex = aKeyPath.indexOf("."),
            remaining = aKeyPath.substring(dotIndex+1),
            indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [_array count])];

        [_array removeObserver:proxy fromObjectsAtIndexes:indexes forKeyPath:remaining];
    }
    else
    {
        var indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [_array count])];
        [_array removeObserver:observer fromObjectsAtIndexes:indexes forKeyPath:aKeyPath];
    }
}

- (void)insertObject:(id)anObject atIndex:(unsigned)anIndex
{
    for (var i=0, count=[_observationProxies count]; i<count; i++)
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

    [_array insertObject:anObject atIndex:anIndex];
}

- (void)removeObjectAtIndex:(unsigned)anIndex
{
    for (var i=0, count=[_observationProxies count]; i<count; i++)
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

    [_array removeObjectAtIndex:anIndex];
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
    var currentObject = [_array objectAtIndex:anIndex];
    
    for (var i=0, count=[_observationProxies count]; i<count; i++)
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

    [_array replaceObjectAtIndex:anIndex withObject:anObject];
}

@end

@implementation CPControllerSelectionProxy : NSObject
{
    id              _controller;
    id              _keys;
    
    CPDictionary    _cachedValues;
    CPArray         _observationProxies;
}

- (id)initWithController:(id)aController
{
    if (self = [super init])
    {
        _cachedValues = [CPDictionary dictionary];
        _observationProxies = [CPArray array];
        
        _controller = aController;
    }
}

- (id)valueForKey:(CPString)aKey
{
    var value = [_cachedValues objectForKey:aKey];
    
    if (value)
        return value;

    var allValues = [[_controller selectedObjects] valueForKeyPath:aKey],
        count = [allValues count];
    
    if (!count)
        value = CPNoSelectionMarker;
    else if (count === 1)
        value = [allValues lastObject];
    else
    {
        if ([_controller alwaysUsesMultipleValuesMarker])
            value = CPMultipleValuesMarker;
        else
        {
            value = [allValues objectAtIndex:0];
            
            for (var i=0, count=[allValues count]; i<count && value!=CPMultipleValuesMarker; i++)
            {
                if (![values isEqual:[allValues objectAtIndex:i]])
                    value = CPMultipleValuesMarker;
            }
        }
    }
    
    [_cachedValues setValue:value forKey:aKey];
    
    return value;
}

- (unsigned)count
{
    return [_cachedValues count];
}

- (id)keyEnumerator
{
    return [_cachedValues keyEnumerator];
}

- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    [[_controller selectedObjects] setValue:aValue forKey:aKey];
}

-(void)controllerWillChange
{
    _keys = [_cachedValues allKeys];
    
    for (var i=0, count=_keys.length; i<count; i++)
        [self willChangeValueForKey:_keys[i]];

    [_cachedValues removeAllObjects];
}

-(void)controllerDidChange
{   
    [_cachedValues removeAllObjects];

    for (var i=0, count=_keys.length; i<count; i++)
        [self willChangeValueForKey:_keys[i]];

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
    
    [[_controller selectedObjects] addObserver:proxy forKeyPath:aKeyPath options:options context:context];
}

- (void)removeObserver:(id)anObject forKeyPath:(CPString)aKeyPath
{
    var proxy = [[_CPObservationProxy alloc] initWithKeyPath:aKeyPath observer:anObject object:self],
        index = [_observationProxies indexOfObject:proxy];
    
    [[_controller selectedObjects] removeObserver:[_observationProxies objectAtIndex:index] forKeyPath:aKeyPath];
    [_observationProxies removeObjectAtIndex:index];
}

@end
