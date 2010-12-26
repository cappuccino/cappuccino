
@import "CPMutableArray.j"


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
    return anArray.slice(0);
}

- (id)initWithArray:(CPArray)anArray copyItems:(BOOL)shouldCopyItems
{
    if (!shouldCopyItems)
        return anArray.slice(0);

    self = [super init];

    var index = 0;

    if (anArray.isa === _CPJavaScriptArray)
    {
        var count = anArray.length;

        for (; index < count; ++index)
        {
            var object = anArray[index];

            self[index] = object.isa ? [object copy] : object;
        }

        return self;
    }

    var count = [anArray count];

    for (; index < count; ++index)
    {
        var object = [anArray objectatIndex:index];

        self[index] = object.isa ? [object copy] : object;
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

    return Array.prototype.slice.call(arguments, 2, index);
}

- (id)initWithObjects:(CPArray)objects count:(CPUInteger)aCount
{
    if (objects.isa === _CPJavaScriptArray)
        return objects.slice(0);

    var array = [],
        index = 0;

    for (; index < aCount; ++index)
        array.push([objects objectAtIndex:index]);

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

- (CPUInteger)indexOfObject:(id)anObject
{
    return [self indexOfObject:anObject inRange:nil];
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

- (CPUInteger)indexOfObjectIdenticalTo:(id)anObject
{
    return [self indexOfObjectIdenticalTo:anObject inRange:nil];
}

- (CPUInteger)indexOfObjectIdenticalTo:(id)anObject inRange:(CPRange)aRange
{
    if (self.indexOf)
        return self.indexOf(anObject);

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

    return self.slice(aRange.location, CPMaxRange(aRange));
}

- (CPString)componentsJoinedByString:(CPString)aString
{
    return self.join(aString);
}

- (void)insertObject:(id)anObject atIndex:(CPUInteger)anIndex
{
    self.splice(anIndex, 0, anObject);
}

- (void)removeObjectAtIndex:(CPUInteger)anIndex
{
    self.splice(anIndex, 1);
}

- (void)addObject:(id)anObject
{
    self.push(anObject);
}

- (void)removeLastObject
{
    self.pop();
}

- (void)replaceObjectAtIndex:(int)anIndex withObject:(id)anObject
{
    self[anIndex] = anObject;
}

- (Class)classForCoder
{
    return CPArray;
}

@end

Array.prototype.isa = _CPJavaScriptArray;
