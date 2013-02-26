
@import "CPMutableArray.j"


var concat = Array.prototype.concat,
    indexOf = Array.prototype.indexOf,
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
    if (!shouldCopyItems && [anArray isKindOfClass:_CPJavaScriptArray])
        return slice.call(anArray, 0);

    self = [super init];

    var index = 0;

    if ([anArray isKindOfClass:_CPJavaScriptArray])
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
    if ([objects isKindOfClass:_CPJavaScriptArray])
        return slice.call(objects, 0);

    var array = [],
        index = 0;

    for (; index < aCount; ++index)
        push.call(array, [objects objectAtIndex:index]);

    return array;
}

- (id)initWithCapacity:(CPUInteger)aCapacity
{
    return self;
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

- (CPArray)objectsAtIndexes:(CPIndexSet)indexes
{
    if ([indexes lastIndex] >= self.length)
        [CPException raise:CPRangeException reason:_cmd + " indexes out of bounds"];

    var ranges = indexes._ranges,
        count  = ranges.length,
        result = [],
             i = 0;

    for (; i < count; i++)
    {
        var range = ranges[i],
            loc = range.location,
            len = range.length,
            subArray = self.slice(loc, loc + len);

        result.splice.apply(result, [result.length, 0].concat(subArray));
    }

    return result;
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
        _CPRaiseInvalidArgumentException(self, _cmd, 'attempt to pass a nil selector');

    var index = 0,
        count = self.length;

    if ([objects count])
    {
        var argumentsArray = [[nil, aSelector] arrayByAddingObjectsFromArray:objects];

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

- (CPArray)arrayByAddingObject:(id)anObject
{
    // concat flattens arrays, so wrap it in an *additional* array if anObject is an array itself.
    if (anObject && anObject.isa && [anObject isKindOfClass:_CPJavaScriptArray])
        return concat.call(self, [anObject]);

    return concat.call(self, anObject);
}

- (CPArray)arrayByAddingObjectsFromArray:(CPArray)anArray
{
    if (!anArray)
        return [self copy];

    return concat.call(self, [anArray isKindOfClass:_CPJavaScriptArray] ? anArray : [anArray _javaScriptArrayCopy]);
}

- (CPArray)subarrayWithRange:(CPRange)aRange
{
    if (aRange.location < 0 || CPMaxRange(aRange) > self.length)
        [CPException raise:CPRangeException reason:_cmd + " aRange out of bounds"];

    return slice.call(self, aRange.location, CPMaxRange(aRange));
}

- (CPString)componentsJoinedByString:(CPString)aString
{
    return join.call(self, aString);
}

- (void)insertObject:(id)anObject atIndex:(int)anIndex
{
    if (anIndex > self.length || anIndex < 0)
        _CPRaiseRangeException(self, _cmd, anIndex, self.length);

    splice.call(self, anIndex, 0, anObject);
}

- (void)removeObjectAtIndex:(int)anIndex
{
    if (anIndex >= self.length || anIndex < 0)
        _CPRaiseRangeException(self, _cmd, anIndex, self.length);

    splice.call(self, anIndex, 1);
}

- (void)removeObjectIdenticalTo:(id)anObject
{
    if (indexOf)
    {
        var anIndex;
        while ((anIndex = indexOf.call(self, anObject)) !== -1)
            splice.call(self, anIndex, 1);
    }
    else
        [super removeObjectIdenticalTo:anObject inRange:CPMakeRange(0, self.length)];
}

- (void)removeObjectIdenticalTo:(id)anObject inRange:(CPRange)aRange
{
    if (indexOf && !aRange)
        [self removeObjectIdenticalTo:anObject];

    [super removeObjectIdenticalTo:anObject inRange:aRange];
}

- (void)addObject:(id)anObject
{
    push.call(self, anObject);
}

- (void)removeAllObjects
{
    splice.call(self, 0, self.length);
}

- (void)removeLastObject
{
    pop.call(self);
}

- (void)removeObjectsInRange:(CPRange)aRange
{
    if (aRange.location < 0 || CPMaxRange(aRange) > self.length)
        [CPException raise:CPRangeException reason:_cmd + " aRange out of bounds"];

    splice.call(self, aRange.location, aRange.length);
}

- (void)replaceObjectAtIndex:(int)anIndex withObject:(id)anObject
{
    if (anIndex >= self.length || anIndex < 0)
        _CPRaiseRangeException(self, _cmd, anIndex, self.length);

    self[anIndex] = anObject;
}

- (void)replaceObjectsInRange:(CPRange)aRange withObjectsFromArray:(CPArray)anArray range:(CPRange)otherRange
{
    if (aRange.location < 0 || CPMaxRange(aRange) > self.length)
        [CPException raise:CPRangeException reason:_cmd + " aRange out of bounds"];

    if (otherRange && (otherRange.location < 0 || CPMaxRange(otherRange) > anArray.length))
        [CPException raise:CPRangeException reason:_cmd + " otherRange out of bounds"];

    if (otherRange && (otherRange.location !== 0 || otherRange.length !== [anArray count]))
        anArray = [anArray subarrayWithRange:otherRange];

    if (anArray.isa !== _CPJavaScriptArray)
        anArray = [anArray _javaScriptArrayCopy];

    splice.apply(self, [aRange.location, aRange.length].concat(anArray));
}

- (void)setArray:(CPArray)anArray
{
    if ([anArray isKindOfClass:_CPJavaScriptArray])
        splice.apply(self, [0, self.length].concat(anArray));

    else
        [super setArray:anArray];
}

- (void)addObjectsFromArray:(CPArray)anArray
{
    if ([anArray isKindOfClass:_CPJavaScriptArray])
        splice.apply(self, [self.length, 0].concat(anArray));

    else
        [super addObjectsFromArray:anArray];
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
