
@import "CPMutableSet.j"


var hasOwnProperty = Object.prototype.hasOwnProperty;

/*!
    @class CPSet
    @ingroup foundation
    @brief An unordered collection of objects.
*/
@implementation _CPConcreteMutableSet : CPMutableSet
{
    Object      _contents;
    unsigned    _count;
}

/*
    Initializes a newly allocated set with members taken from the specified list of objects.
    @param objects A array of objects to add to the new set. If the same object appears more than once objects, it is added only once to the returned set.
    @param count The number of objects from objects to add to the new set.
*/
- (id)initWithObjects:(CPArray)objects count:(CPUInteger)aCount
{
    self = [super initWithObjects:objects count:aCount];

    if (self)
    {
        _count = 0;
        _contents = { };

        var index = 0,
            count = MIN([objects count], aCount);

        for (; index < count; ++index)
            [self addObject:objects[index]];
    }

    return self;
}

- (CPUInteger)count
{
    return _count;
}

- (id)member:(id)anObject
{
    var UID = [anObject UID];

    if (hasOwnProperty.call(_contents, UID))
        return _contents[UID];
    else
    {
        for (var objectUID in _contents)
        {
            if (!hasOwnProperty.call(_contents, objectUID))
                continue;

            var object = _contents[objectUID];

            if (object === anObject || [object isEqual:anObject])
                return object;
        }
    }

    return nil;
}

- (CPArray)allObjects
{
    var array = [],
        property;

    for (property in _contents)
    {
        if (hasOwnProperty.call(_contents, property))
            array.push(_contents[property]);
    }

    return array;
}

- (CPEnumerator)objectEnumerator
{
    return [[self allObjects] objectEnumerator];
}

/*
    Adds a given object to the receiver.
    @param anObject The object to add to the receiver.
*/
- (void)addObject:(id)anObject
{
    if (anObject === nil || anObject === undefined)
        [CPException raise:CPInvalidArgumentException reason:@"attempt to insert nil or undefined"];

    if ([self containsObject:anObject])
        return;

    _contents[[anObject UID]] = anObject;
    _count++;
}

/*
    Removes a given object from the receiver.
    @param anObject The object to remove from the receiver.
*/
- (void)removeObject:(id)anObject
{
    // Removing nil is an error.
    if (anObject === nil || anObject === undefined)
        [CPException raise:CPInvalidArgumentException reason:@"attempt to remove nil or undefined"];

    // anObject might be isEqual: another object in the set. We need the exact instance so we can remove it by UID.
    var object = [self member:anObject];

    // ...but removing an object not present in the set is not an error.
    if (object !== nil)
    {
        delete _contents[[object UID]];
        _count--;
    }
}

/*
    Performance improvement.
*/
- (void)removeAllObjects
{
    _contents = {};
    _count = 0;
}

- (Class)classForCoder
{
    return [CPSet class];
}

@end
