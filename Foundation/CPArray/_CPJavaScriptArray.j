
@import "CPMutableArray.j"


var indexOf = Array.prototype.indexOf,
    join = Array.prototype.join,
    pop = Array.prototype.pop,
    push = Array.prototype.push,
    slice = Array.prototype.slice,
    splice = Array.prototype.splice;

@implementation _CPJavaScriptArray : CPMutableArray
{
}

+ (id)alloc
{
    return [];
}

+ (CPArray)array
{
    return [];
}

+ (id)arrayWithArray:(CPArray)anArray
{
    return [[self alloc] initWithArray:anArray];
}

+ (id)arrayWithObject:(id)anObject
{
    return [anObject];
}

- (id)initWithArray:(CPArray)anArray
{
    return [self initWithArray:anArray copyItems:NO];
}

- (id)initWithArray:(CPArray)anArray copyItems:(BOOL)shouldCopyItems
{
    if (!shouldCopyItems && anArray.isa === _CPJavaScriptArray)
        return slice.call(anArray, 0);

    self = [super init];

    var index = 0;

    if (anArray.isa === _CPJavaScriptArray)
    {
        // If we're this far, shouldCopyItems must be YES.
        var count = anArray.length;

        for (; index < count; ++index)
        {
            var object = anArray[index];

            self[index] = (object && object.isa) ? [object copy] : object;
        }

        return self;
    }

    var count = [anArray count];

    for (; index < count; ++index)
    {
        var object = [anArray objectAtIndex:index];

        self[index] = (shouldCopyItems && object && object.isa) ? [object copy] : object;
    }

    return self;
}

- (id)initWithObjects:(id)anObject, ...
{
    // The arguments array contains self and _cmd, so the first object is at position 2.
    var index = 2,
        count = arguments.length;

    for (; index < count; ++index)
        if (arguments[index] === nil)
            break;

    return slice.call(arguments, 2, index);
}

- (id)initWithObjects:(CPArray)objects count:(CPUInteger)aCount
{
    if (objects.isa === _CPJavaScriptArray)
        return slice.call(objects, 0);

    var array = [],
        index = 0;

    for (; index < aCount; ++index)
        push.call(array, [objects objectAtIndex:index]);

    return array;
}

- (BOOL)count
{
    return self.length;
}

- (id)objectAtIndex:(CPUInteger)anIndex
{
    if (anIndex >= self.length || anIndex < 0)
        _CPRaiseRangeException(self, _cmd, anIndex, self.length);

    return self[anIndex];
}

- (CPUInteger)indexOfObject:(id)anObject inRange:(CPRange)aRange
{
    // Only use isEqual: if our object is a CPObject.
    if (anObject && anObject.isa)
    {
        var index = aRange ? aRange.location : 0,
            count = aRange ? CPMaxRange(aRange) : self.length;

        for (; index < count; ++index)
            if ([self[index] isEqual:anObject])
                return index;

        return CPNotFound;
    }

    return [self indexOfObjectIdenticalTo:anObject inRange:aRange];
}

- (CPUInteger)indexOfObjectIdenticalTo:(id)anObject inRange:(CPRange)aRange
{
    if (indexOf && !aRange)
        return indexOf.call(self, anObject);

    var index = aRange ? aRange.location : 0,
        count = aRange ? CPMaxRange(aRange) : self.length;

    for (; index < count; ++index)
        if (self[index] === anObject)
            return index;

    return CPNotFound;
}

- (void)makeObjectsPerformSelector:(SEL)aSelector withObjects:(CPArray)objects
{
    if (!aSelector)
        [CPException raise:CPInvalidArgumentException
                    reason:"makeObjectsPerformSelector:withObjects: 'aSelector' can't be nil"];

    var index = 0,
        count = self.length;

    if ([objects count])
    {
        argumentsArray = [[nil, aSelector] arrayByAddingObjectsFromArray:objects];

        for (; index < count; ++index)
        {
            argumentsArray[0] = self[index];
            objj_msgSend.apply(this, argumentsArray);
        }
    }

    else
        for (; index < count; ++index)
            objj_msgSend(self[index], aSelector);
}

- (CPArray)subarrayWithRange:(CPRange)aRange
{
    if (aRange.location < 0 || CPMaxRange(aRange) > self.length)
        [CPException raise:CPRangeException reason:"subarrayWithRange: aRange out of bounds"];

    return slice.call(self, aRange.location, CPMaxRange(aRange));
}

- (CPString)componentsJoinedByString:(CPString)aString
{
    return join.call(self, aString);
}

- (void)insertObject:(id)anObject atIndex:(CPUInteger)anIndex
{
    splice.call(self, anIndex, 0, anObject);
}

- (void)removeObjectAtIndex:(CPUInteger)anIndex
{
    splice.call(self, anIndex, 1);
}

- (void)addObject:(id)anObject
{
    push.call(self, anObject);
}

- (void)removeLastObject
{
    pop.call(self);
}

- (void)replaceObjectAtIndex:(int)anIndex withObject:(id)anObject
{
    self[anIndex] = anObject;
}

- (void)copy
{
    return slice.call(self, 0);
}

- (Class)classForCoder
{
    return CPArray;
}

@end

Array.prototype.isa = _CPJavaScriptArray;
