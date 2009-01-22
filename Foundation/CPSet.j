/*
 * CPSet.j
 * Foundation
 *
 * Created by Bailey Carlson
 * Extended by Ross Boucher
 * Extended by Nabil Elisa
 * 
 * TODO: Needs to implement CPCoding, CPCopying.
 */
 
@import "CPObject.j"
@import "CPArray.j"
@import "CPNumber.j"
@import "CPEnumerator.j"


@implementation CPSet : CPObject
{
    Object      _contents;
    unsigned    _count;
}

/*
    Creates and returns an empty set.
*/
+ (id)set
{
    return [[self alloc] init];
}

/*
    Creates and returns a set containing a uniqued collection of those objects contained in a given array.
    @param anArray array containing the objects to add to the new set. If the same object appears more than once objects, it is added only once to the returned set.
*/
+ (id)setWithArray:(CPArray)array
{
    return [[self alloc] initWithArray:array];
}

/*
    Creates and returns a set that contains a single given object.
    @param anObject The object to add to the new set.
*/
+ (id)setWithObject:(id)anObject
{
    return [[self alloc] initWithArray:[anObject]];
}

/*
    Creates and returns a set containing a specified number of objects from a given array of objects.
    @param objects A array of objects to add to the new set. If the same object appears more than once objects, it is added only once to the returned set.
    @param count The number of objects from objects to add to the new set.
*/
+ (id)setWithObjects:(id)objects count:(unsigned)count
{
    return [[self alloc] initWithObjects:objects count:count];
}

/*
    Creates and returns a set containing the objects in a given argument list.
    @param anObject The first object to add to the new set.
    @param ... A comma-separated list of objects, ending with nil, to add to the new set. If the same object appears more than once objects, it is added only once to the returned set. 
*/
+ (id)setWithObjects:(id)anObject, ...
{
    var set = [[self alloc] init],
        argLength = arguments.length,
        i = 2;

    for(; i < argLength && (argument = arguments[i]) != nil; ++i)
        [set addObject:argument];
    
    return set;
}

/*
    Creates and returns a set containing the objects from another set.
    @param aSet A set containing the objects to add to the new set.
*/
+ (id)setWithSet:(CPSet)set
{
    return [[self alloc] initWithSet:set];
}

/*
    Basic initializer, returns an empty set
*/
- (id)init
{
    if (self = [super init])
    {
        _count = 0;
        _contents = {};
    }
    
    return self;
}

/*
    Initializes a newly allocated set with the objects that are contained in a given array.
    @param array An array of objects to add to the new set. If the same object appears more than once in array, it is represented only once in the returned set.
*/
- (id)initWithArray:(CPArray)anArray
{    
    if (self = [self init])
    {
        var count = anArray.length;
        
        while (count--)
            [self addObject:anArray[count]];
    }
    
    return self;
}

/*
    Initializes a newly allocated set with members taken from the specified list of objects.
    @param objects A array of objects to add to the new set. If the same object appears more than once objects, it is added only once to the returned set. 
    @param count The number of objects from objects to add to the new set.
*/
- (id)initWithObjects:(id)objects count:(unsigned)count
{
    return [self initWithArray:objects.splice(0, count)];
}

/*
    Initializes a newly allocated set with members taken from the specified list of objects.
    @param anObject The first object to add to the new set.
    @param ... A comma-separated list of objects, ending with nil, to add to the new set. If the same object appears more than once in the list, it is represented only once in the returned set.
*/
- (id)initWithObjects:(id)anObject, ...
{
    if (self = [self init])
    {
		var argLength = arguments.length,
			i = 2;

        for(; i < argLength && (argument = arguments[i]) != nil; ++i)
            [self addObject:argument];
    }
    
    return self;
}

/*
    Initializes a newly allocated set and adds to it objects from another given set. Only included for compatability.
*/
- (id)initWithSet:(CPSet)aSet
{
    return [self initWithSet:aSet copyItems:NO];
}

/*
    Initializes a newly allocated set and adds to it members of another given set. Only included for compatability.
*/
- (id)initWithSet:(CPSet)aSet copyItems:(BOOL)shouldCopyItems
{
    self = [self init];

    if (!aSet)
        return self;
            
    var contents = aSet._contents;
    
    for (var property in contents)
    {
        if (_contents.hasOwnProperty(property))
        {
            if (shouldCopyItems)
                [self addObject:[contents[property] copy]];
            else
                [self addObject:contents[property]];
        }
    }
    
    return self;
}

/*
    Returns an array containing the receiver’s members, or an empty array if the receiver has no members.
*/
- (CPArray)allObjects
{
    var array = [];
    
    for (var property in _contents)
    {
        if (_contents.hasOwnProperty(property))
            array.push(_contents[property]);
    }
    
    return array;
}

/*
    Returns one of the objects in the receiver, or nil if the receiver contains no objects.
*/
- (id)anyObject
{
    for (var property in _contents)
    {
        if (_contents.hasOwnProperty(property))
            return _contents[property];
    }
    
    return nil;
}

/*
    Returns a Boolean value that indicates whether a given object is present in the receiver.
    @param anObject The object for which to test membership of the receiver.
*/
- (BOOL)containsObject:(id)anObject
{
    if (_contents[[anObject hash]] && [_contents[[anObject hash]] isEqual:anObject])
        return YES;
    
    return NO;
}

/*
    Returns the number of members in the receiver.
*/
- (unsigned)count
{
    return _count;
}

//- (CPString)description;
//
//- (CPString)descriptionWithLocale:(CPDictionary)locale;

/*
    Returns a Boolean value that indicates whether at least one object in the receiver is also present in another given set.
    @param set The set with which to compare the receiver.
*/
- (BOOL)intersectsSet:(CPSet)set
{
    var items = [set allObjects];
    for (var i = items.length; i > 0; i--)
    {
        // If the sets share at least one item, they intersect
        if ([self containsObject:items[i]])
            return YES;
    }
    
    return NO;
}

/*
    Compares the receiver to another set.
    @param set The set with which to compare the receiver.
*/
- (BOOL)isEqualToSet:(CPSet)set
{    
    // If both are subsets of each other, they are equal
    return self === set || ([self count] === [set count] && [set isSubsetOfSet:self]);
}

/*
    Returns a Boolean value that indicates whether every object in the receiver is also present in another given set.
    @param set The set with which to compare the receiver.
*/
- (BOOL)isSubsetOfSet:(CPSet)set
{
    var items = [self allObjects];
    for (var i = 0; i < items.length; i++)
    {
        // If at least one item is not in both sets, self isn't a subset
        if (![set containsObject:items[i]])
            return NO;
    }
    
    return YES;
}

/*
    Sends to each object in the receiver a message specified by a given selector.
    @param aSelector A selector that specifies the message to send to the members of the receiver. The method must not take any arguments. It should not have the side effect of modifying the receiver. This value must not be NULL.
*/
- (void)makeObjectsPerformSelector:(SEL)aSelector
{
    [self makeObjectsPerformSelector:aSelector withObject:nil];
}

/*
    Sends to each object in the receiver a message specified by a given selector.
    @param aSelector A selector that specifies the message to send to the receiver's members. The method must take a single argument of type id. The method should not, as a side effect, modify the receiver. The value must not be NULL.
    @param anObject The object to pass as an argument to the method specified by aSelector.
*/
- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)argument
{
    var items = [self allObjects];
    for (var i = 0; i < items.length; i++)
    {
        [items[i] performSelector:aSelector withObject:argument];
    }
}

/*
    Determines whether the receiver contains an object equal to a given object, and returns that object if it is present.
    @param anObject The object for which to test for membership of the receiver.
*/
- (id)member:(id)object
{
    if ([self containsObject:object])
        return object;
    
    return nil;
}

- (CPEnumerator)objectEnumerator
{
    return [[self allObjects] objectEnumerator];
}


// Mutable Set Methods
/*
    Returns an initialized set with a given initial capacity.
    @param numItems, only present for compatability
*/
- (id)initWithCapacity:(unsigned)numItems
{
    // Only here for compatability with Cocoa
    self = [self init];
    return self;
}

/*
    Creates and returns a set with a given initial capacity.
    @param numItems, only present for compatability
*/
+ (id)setWithCapacity:(unsigned)numItems
{
    return [[self alloc] initWithCapacity:numItems];
}

/*
    Empties the receiver, then adds to the receiver each object contained in another given set.
    @param set The set whose members replace the receiver's content.
*/
- (void)setSet:(CPSet)set
{
    [self removeAllObjects];
    [self addObjectsFromArray:[set allObjects]];
}

/*
    Adds a given object to the receiver.
    @param anObject The object to add to the receiver.
*/
- (void)addObject:(id)anObject
{
    _contents[[anObject hash]] = anObject;
    _count++;
}

/*
    Adds to the receiver each object contained in a given array that is not already a member.
    @param array An array of objects to add to the receiver.
*/
- (void)addObjectsFromArray:(CPArray)array
{
    for (var i = 0, count = array.length; i < count; i++) 
    {
        [self addObject:array[i]];
    }
}

/*
    Removes a given object from the receiver.
    @param anObject The object to remove from the receiver.
*/
- (void)removeObject:(id)anObject
{
    if ([self containsObject:anObject])
    {
        delete _contents[[anObject hash]];
        _count--;
    }
}

/*
    Empties the receiver of all of its members.
*/
- (void)removeAllObjects
{
    _contents = {};
    _count = 0;
}

/*
    Removes from the receiver each object that isn’t a member of another given set.
    @param set The set with which to perform the intersection.
*/
- (void)intersectSet:(CPSet)set
{
    var items = [self allObjects];
    for (var i = 0, count = items.length; i < count; i++)
    {
        if (![set containsObject:items[i]])
            [self removeObject:items[i]];
    }
}

/*
    Removes from the receiver each object contained in another given set that is present in the receiver.
    @param set The set of objects to remove from the receiver.
*/
- (void)minusSet:(CPSet)set
{
    var items = [set allObjects];
    for (var i = 0; i < items.length; i++)
    {
        if ([self containsObject:items[i]])
            [self removeObject:items[i]];
    }
}

/*
    Adds to the receiver each object contained in another given set
    @param set The set of objects to add to the receiver.
*/
- (void)unionSet:(CPSet)set
{
    var items = [set allObjects];
    for (var i = 0, count = items.length; i < count; i++)
    {
        [self addObject:items[i]];
    }
}

@end

@implementation CPSet (CPCopying)

- (id)copy
{
    return [[CPSet alloc] initWithSet:self];
}

- (id)mutableCopy
{
    return [self copy];
}

@end

var CPSetObjectsKey = @"CPSetObjectsKey";

@implementation CPSet (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self initWithArray:[aCoder decodeObjectForKey:CPSetObjectsKey]];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:[self allObjects] forKey:CPSetObjectsKey];
}

@end

@implementation CPMutableSet : CPSet
@end

