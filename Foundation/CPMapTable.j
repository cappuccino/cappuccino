@import "CPObject.j"
@import "CPEnumerator.j"
@import "CPDictionary.j"

/*!
   @class CPMapTable
   @ingroup foundation
   A mutable collection modeled after NSDictionary that allows for arbitrary
   objects or values to be used as keys. This implementation uses the native
   ECMAScript 6 Map object for its underlying storage.
 */
@implementation CPMapTable : CPObject
{
    // The underlying ES6 Map to store the key-value pairs.
    id _map;
}

/*!
   Initializes a new, empty CPMapTable.
 */
- (id)init
{
    if (self = [super init])
    {
        _map = new Map();
    }

    return self;
}

/*!
   Releases the underlying map.
 */
- (void)dealloc
{
    _map = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Accessing Content

/*!
   Returns the value associated with a given key.
   @param aKey The key for which to return the corresponding value.
   @return The value associated with aKey, or nil if no value is associated with aKey.
 */
- (id)objectForKey:(id)aKey
{
    return _map.get(aKey);
}

/*!
   Returns an enumerator object that lets you access each key in the map table.
   @return A CPEnumerator object for the keys in the map table.
 */
- (CPEnumerator)keyEnumerator
{
    return [CPEnumerator enumeratorWithIterator:_map.keys()];
}

/*!
   Returns an enumerator object that lets you access each value in the map table.
   @return A CPEnumerator object for the values in the map table.
 */
- (CPEnumerator)objectEnumerator
{
    return [CPEnumerator enumeratorWithIterator:_map.values()];
}

/*!
   Returns the number of key-value pairs in the map table.
   @return The number of entries in the map table.
 */
- (unsigned int)count
{
    return _map.size;
}

#pragma mark -
#pragma mark Manipulating Content

/*!
   Adds a given key-value pair to the map table.
   If aKey already exists in the map table, anObject takes its place.
   @param anObject The value for aKey.
   @param aKey The key for anObject.
 */
- (void)setObject:(id)anObject forKey:(id)aKey
{
    _map.set(aKey, anObject);
}

/*!
   Removes a given key and its associated value from the map table.
   @param aKey The key to remove.
 */
- (void)removeObjectForKey:(id)aKey
{
    _map.delete(aKey);
}

/*!
   Empties the map table of its entries.
 */
- (void)removeAllObjects
{
    _map.clear();
}

#pragma mark -
#pragma mark Creating a Dictionary Representation

/*!
   Returns a dictionary representation of the map table.
   Note: This will only work correctly if all keys are strings.

   @return A CPDictionary containing the entries of the map table.
 */
- (CPDictionary)dictionaryRepresentation
{
    var dictionary = [CPDictionary dictionary];

    for (var [key, value] of _map.entries())
    {
        [dictionary setObject:value forKey:key];
    }

    return dictionary;
}

@end
