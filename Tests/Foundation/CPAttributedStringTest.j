import "CPAttributedString.j"

@implementation CPAttributedStringTest : OJTestCase


- (id)testInitWithString
{
    var string = [[CPAttributedString alloc] initWithString:@"hi there"];

    [self assertTrue:([string string] === @"hi there") 
             message:"testInitWithString: expected:" + @"hi there" + " actual:" + [string string]];
}
/*
- (id)testInitWithAttributedString
{
    var string = [[CPAttributedString alloc] initWithString:@"hi there"],
        attributedString = [[CPAttributedString alloc] initWithAttributedString:string];

    [self assertTrue:([string isEqualToAttributedString:attributedString]) 
             message:"testInitWithAttributedString: expected:" + string + " actual:" + attributedString];
             
    //add a case where we init with a string that actually adds attributes
}

- (id)testIinitWithString_attributes
{
    var string = [[CPAttributedString alloc] initWithString:@"hi there" attributes:[CPDictionary dictionary]];

    [self assertTrue:([string string] === @"hi there") 
             message:"testIinitWithString_attributes: expected:" + @"hi there" + " actual:" + [string string]];

    var string = [[CPAttributedString alloc] initWithString:@"hi there" attributes:[CPDictionary dictionaryWithObjects:[1, "bar"] forKeys["number", "foo"]]];

    [self assertTrue:([[string attributesAtIndex:0 effectiveRange:nil] objectForKey:@"number"] === 1) 
             message:"testIinitWithString_attributes: value for key 'number' expected:" + 1 + " actual:" + [[string attributesAtIndex:0 effectiveRange:nil] objectForKey:@"number"]];

    [self assertTrue:([[string attributesAtIndex:0 effectiveRange:nil] objectForKey:@"bar"] === "foo") 
             message:"testIinitWithString_attributes: value for key 'foo' expected:" + "bar" + " actual:" + [[string attributesAtIndex:0 effectiveRange:nil] objectForKey:@"foo"]];
}

//Retrieving Character Information
- (CPString)testString
{
    var string = [[CPAttributedString alloc] initWithString:@"hi there"];

    [self assertTrue:([string string] === string._string) 
             message:"testString: expected:" + @"hi there" + " actual:" + [string string]];
}

- (unsigned)testLength
{
    var string = [[CPAttributedString alloc] initWithString:@"hi there"];

    [self assertTrue:([string length] === 8) 
             message:"testLength: expected:" + 8 + " actual:" + [string length]];
}

- (unsigned)test_indexOfEntryWithIndex
{

}

//Retrieving Attribute Information
- (CPDictionary)attributesAtIndex:(unsigned)anIndex effectiveRange:(CPRangePointer)aRange
{
    //find the range entry that contains anIndex.
    var entryIndex = [self _indexOfEntryWithIndex:anIndex];
    
    if (entryIndex == CPNotFound)
        return nil;

    var matchingRange = _rangeEntries[entryIndex];
    
    if (aRange)
    {
        aRange.location = matchingRange.range.location;
        aRange.length = matchingRange.range.length;
    }
    
    return matchingRange.attributes;
}

- (CPDictionary)attributesAtIndex:(unsigned)anIndex longestEffectiveRange:(CPRangePointer)aRange inRange:(CPRange)rangeLimit
{    
    var startingEntryIndex = [self _indexOfEntryWithIndex:anIndex];

    if (startingEntryIndex == CPNotFound)
        return nil;
    
    if (!aRange)
        return _rangeEntries[startingEntryIndex].attributes;

    if (CPRangeInRange(_rangeEntries[startingEntryIndex].range, rangeLimit))
    {
        aRange.location = rangeLimit.location;
        aRange.length = rangeLimit.length;
        
        return _rangeEntries[startingEntryIndex].attributes;
    }

    var currentRange = _rangeEntries[startingEntryIndex],
        currentRangeIndex = startingEntryIndex,
        comparisonDict = currentRange.attributes;
    
    while (CPMaxRange(currentRange) > rangeLimit.location && [currentRange.attributes isEqualToDictionary:comparisonDict])
        currentRange = _rangeEntries[--currentRangeIndex];

    aRange.location = currentRange.location;
    currentRange = _rangeEntries[startingEntryIndex],
    currentRangeIndex = startingEntryIndex;

    while (currentRange.location < CPMaxRange(rangeLimit) && [currentRange.attributes isEqualToDictionary:comparisonDict])
        currentRange = _rangeEntries[++currentRangeIndex];

    aRange.length = CPMaxRange(currentRange) - aRange.location;
    
    return currentRange.attributes;
}

- (id)attribute:(CPString)attribute atIndex:(unsigned)index effectiveRange:(CPRangePointer)aRange
{
    if (!attribute)
    {
        if (aRange)
        {
            aRange.location = 0;
            aRange.length = _string.length;
        }

        return nil;
    }

    return [[self attributesAtIndex:index effectiveRange:aRange] valueForKey:attribute];
}

- (id)attribute:(CPString)attribute atIndex:(unsigned)index longestEffectiveRange:(CPRangePointer)aRange inRange:(CPRange)rangeLimit
{
    //find the range entry that contains anIndex.
    var startingEntryIndex = [self _indexOfEntryWithIndex:anIndex];
    
    if (startingEntryIndex == CPNotFound || !attribute)
        return nil;

    if (!aRange)
        return [_rangeEntries[startingEntryIndex].attributes objectForKey:attribute];

    if (CPRangeInRange(_rangeEntries[startingEntryIndex].range, rangeLimit))
    {
        aRange.location = rangeLimit.location;
        aRange.length = rangeLimit.length;
        
        return [_rangeEntries[startingEntryIndex].attributes objectForKey:attribute];
    }

    var currentRange = _rangeEntries[startingEntryIndex],
        currentRangeIndex = startingEntryIndex,
        comparisonAttribute = [currentRange.attributes objectForKey:attribute];
    
    while (CPMaxRange(currentRange) > rangeLimit.location)
    {
        var thisAttribute = [currentRange.attributes objectForKey:attribute];
        
        if (isEqual(comparisonAttribute, thisAttribute))
            currentRange = _rangeEntries[--currentRangeIndex];
        else
            break;
    }

    aRange.location = currentRange.location;
    currentRange = _rangeEntries[startingEntryIndex],
    currentRangeIndex = startingEntryIndex;

    while (currentRange.location < CPMaxRange(rangeLimit))
    {
        var thisAttribute = [currentRange.attributes objectForKey:attribute];
        
        if (isEqual(comparisonAttribute, thisAttribute))
            currentRange = _rangeEntries[++currentRangeIndex];
        else
            break;
    }

    aRange.length = CPMaxRange(currentRange) - aRange.location;

    return comparisonAttribute;
}

//Comparing Attributed Strings
- (BOOL)isEqualToAttributedString:(CPAttributedString)aString
{
	if(!aString)
		return NO;
		
	if(_string != [aString string])
		return NO;
  
    var myRange = CPMakeRange(),
        comparisonRange = CPMakeRange(),
        myAttributes = [self attributesAtIndex:0 effectiveRange:myRange],
        comparisonAttributes = [aString attributesAtIndex:0 effectiveRange:comparisonRange],
        length = _string.length;

    while (CPMaxRange(CPUnionRange(myRange, comparisonRange)) < length)
    {
        if (CPIntersectionRange(myRange, comparisonRange).length > 0 && ![myAttributes isEqualToDictionary:comparisonAttributes])
            return NO;
        
        if (CPMaxRange(myRange) < CPMaxRange(comparisonRange))
            myAttributes = [self attributesAtIndex:CPMaxRange(myRange) effectiveRange:myRange];
        else
            comparisonAttributes = [aString attributesAtIndex:CPMaxRange(comparisonRange) effectiveRange:comparisonRange];
    }
    
    return YES;
}

- (BOOL)isEqual:(id)anObject
{
	if (anObject == self)
		return YES;
		
	if ([anObject isKindOfClass:[self class]])
		return [self isEqualToAttributedString:anObject];
		
	return NO;
}

//Extracting a Substring
- (CPAttributedString)attributedSubstringFromRange:(CPRange)aRange
{
    if (!aRange || CPMaxRange(aRange) > _string.length || aRange.location < 0)
        [CPException raise:CPRangeException 
                    reason:"tried to get attributedSubstring for an invalid range: "+(aRange?CPStringFromRange(aRange):"nil")];
          
    var newString = [[CPAttributedString alloc] initWithString:_string.substring(aRange.location, CPMaxRange(aRange))],
        entryIndex = [self _indexOfEntryWithIndex:aRange.location],
        currentRangeEntry = _rangeEntries[entryIndex],
        lastIndex = CPMaxRange(aRange);
    
    while (CPMaxRange(currentRangeEntry.range) < lastIndex);
    {
        newString._rangeEntries.push(copyRangeEntry(currentRangeEntry));
        currentRangeEntry = _rangeEntries[++entryIndex];
    }

    var newRangeEntry = copyRangeEntry(currentRangeEntry);
    newString._rangeEntries.push(newRangeEntry);

    newRangeEntry.range.length = CPMaxRange(aRange) - newRangeEntry.range.location;

    return newString;
}

//Changing Characters
- (void)replaceCharactersInRange:(CPRange)aRange withString:(CPString)aString
{
    [self beginEditing];

    if (!aString)
        aString = "";
        
    var startingIndex = [self _indexOfEntryWithIndex:characterIndex],
        startingRangeEntry = _rangeEntries[index],
        endingIndex = [self _indexOfEntryWithIndex:CPMaxRange(aRange)],
        endingRangeEntry = _rangeEntries[endingIndex],
        additionalLength = aString.length - aRange.length;

    _string = _string.substring(0, aRange.location) + aString + _string.substring(CPMaxRange(aRange));

    if (startingIndex == endingIndex)
        startingRangeEntry.range.length += additionalLength;
    else
    {
        endingRangeEntry.range.length = CPMaxRange(endingRangeEntry.range) - CPMaxRange(aRange);
        endingRangeEntry.range.location = CPMaxRange(aRange);

        startingRangeEntry.range.length = CPMaxRange(aRange) - startingRangeEntry.range.location;

        _rangeEntries.splice(startingIndex, endingIndex - startingIndex);
    }

    [self endEditing];
}

- (void)deleteCharactersInRange:(CPRange)aRange
{
    [self replaceCharactersInRange:aRange withString:nil];
}

//Changing Attributes
- (void)setAttributes:(CPDictionary)aDictionary range:(CPRange)aRange
{
    [self beginEditing];

    var startingEntryIndex = [self _indexOfRangeEntryForIndex:aRange.location splitIfNecessary:YES],
        endingEntryIndex = [self _indexOfRangeEntryForIndex:CPMaxRange(aRange) splitIfNecessary:YES] - 1,
        current = startingEntryIndex;

    while (current < endingEntryIndex)
        _rangeEntries[current++].attributes = [aDictionary copy];

    //necessary?
    [self _coalesceRangeEntriesFromIndex:startingEntryIndex toIndex:endingEntryIndex];

    [self endEditing];
}

- (void)addAttributes:(CPDictionary)aDictionary range:(CPRange)aRange
{
    [self beginEditing];

    var startingEntryIndex = [self _indexOfRangeEntryForIndex:aRange.location splitIfNecessary:YES],
        endingEntryIndex = [self _indexOfRangeEntryForIndex:CPMaxRange(aRange) splitIfNecessary:YES] - 1,
        current = startingEntryIndex;

    while (current < endingEntryIndex)
    {
        var keys = [aDictionary keys],
            count = [keys count];
            
        while (count--)
            [_rangeEntries[current].attributes setObject:[aDictionary objectForKey:keys[count]] forKey:keys[count]];

        current++;
    }

    //necessary?
    [self _coalesceRangeEntriesFromIndex:startingEntryIndex toIndex:endingEntryIndex];

    [self endEditing];
}

- (void)addAttribute:(CPString)anAttribute value:(id)aValue range:(CPRange)aRange
{
    [self beginEditing];

    var startingEntryIndex = [self _indexOfRangeEntryForIndex:aRange.location splitIfNecessary:YES],
        endingEntryIndex = [self _indexOfRangeEntryForIndex:CPMaxRange(aRange) splitIfNecessary:YES] - 1,
        current = startingEntryIndex;

    while (current < endingEntryIndex)
        [_rangeEntries[current++].attributes setObject:aValue forKey:anAttribute];

    //necessary?
    //[self _coalesceRangeEntriesFromIndex:startingEntryIndex toIndex:endingEntryIndex];

    [self endEditing];
}

- (void)removeAttribute:(CPString)anAttribute range:(CPRange)aRange
{
    [self addAttribute:anAttribute value:nil range:aRange];
}

//Changing Characters and Attributes
- (void)appendAttributedString:(CPAttributedString)aString
{
    [self insertAttributedString:aString atIndex:_string.length];
}

- insertAttributedString:(CPAttributedString)aString atIndex:(CPString)anIndex
{
    [self beginEditing];
    
    var startingEntryIndex = [self _indexOfRangeEntryForIndex:anIndex splitIfNecessary:YES],
        rangeEntries = aString._rangeEntries,
        count = rangeEntries.length;
    
    _string = _string.substring(0, anIndex) + aString._string + _string.substring(anIndex);
    
    while (count--)
    {
        var newEntry = copyRangeEntry(rangeEntries[count]);
        
        newEntry.range.location += anIndex;
        
        _rangeEntries.splice(startingEntryIndex, 0, newEntry);
    }
    
    //necessary?
    //[self _coalesceRangeEntriesFromIndex:startingEntryIndex toIndex:endingEntryIndex];

    [self endEditing];
}

- (void)replaceCharactersInRange:(CPRange)aRange withAttributedString:(CPAttributedString)aString
{
    [self beginEditing];
        
    [self deleteCharactersInRange:aRange];
    [self insertAttributeString:aString atIndex:aRange.location];
    
    [self endEditing];
}

- (void)setAttributedString:(CPAttributedString)aString
{
    [self beginEditing];
    
    _string = aString;
    _rangeEntries = [];
    
    for (var i=0, count = aString._rangeEntries.length; i<count; i++)
        _rangeEntries.push(copyRangeEntry(aString._rangeEntries[i]));

    [self endEditing];
}

//Private methods
- (void)_indexOfRangeEntryForIndex:(unsigned)characterIndex splitIfNecessary:(BOOL)split
{
    var index = [self _indexOfEntryWithIndex:characterIndex],
        rangeEntry = _rangeEntries[index];

    if (!anAttribute)
        return index;
        
    if (split && rangeEntry.range.location != characterIndex)
    {
        var newEntries = splitRangeEntryAtIndex(rangeEntry, characterIndex);
        _rangeEntries.splice(index, 1, newEntries[0], newEntries[1]);
        index++;
    }
    
    return index;
}

- (void)_coalesceRangeEntriesFromIndex:(unsigned)start toIndex:(unsigned)end
{
    var current = start;
    
    while (current < end)
    {
        var a = _rangeEntries[current],
            b = _rangeEntries[current+1];

        if ([a.attributes isEqualToDictionary:b.attributes])
        {
            a.range.length = CPMaxRange(b.range) - a.range.location;
            _rangeEntries.splice(current, 1);
            end--;
        }
        else
            current++;
    }
}
*/

@end
