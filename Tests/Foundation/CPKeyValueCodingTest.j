/*
 * CPKeyValueCodingTest.j
 * Foundation
 *
 * Created by Daniel Stolzenberg
 * Copyright 2010, University of Rostock
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

@import <Foundation/CPObject.j>

var accessIVARS = YES;

@implementation KVCTestClass : CPObject
{
    id _privatePropertyWithoutAccessors;
    id publicPropertyWithoutAccessors;
    id _isPrivateBoolPropertyWithoutAccessors;
    id isPublicBoolPropertyWithoutAccessors;

    //use triple underscore to avoid direct access to instance variables
    id ___propertyWithPublicGetAccessor            @accessors(getter=getPropertyWithPublicGetAccessor);
    id ___propertyWithPublicAccessor               @accessors(getter=propertyWithPublicAccessor, setter=setPropertyWithPublicAccessor:);
    id ___propertyWithPublicBoolAccessor           @accessors(getter=isPropertyWithPublicBoolAccessor);
    id ___propertyWithPrivateGetAccessor           @accessors(getter=_getPropertyWithPrivateGetAccessor);
    id ___propertyWithPrivateAccessor              @accessors(getter=_propertyWithPrivateAccessor, setter=_setPropertyWithPrivateAccessor:);
    id ___propertyWithPrivateBoolAccessor          @accessors(getter=_isPropertyWithPrivateBoolAccessor);
}

+ (BOOL)accessInstanceVariablesDirectly
{
    return accessIVARS;
}

+ (void)setAccessInstanceVariablesDirectly:(BOOL)accessDirectly
{
    accessIVARS = accessDirectly;
}

- (id)init
{
    if (self = [super init])
    {
        _privatePropertyWithoutAccessors = "_privatePropertyWithoutAccessors";
        publicPropertyWithoutAccessors = "publicPropertyWithoutAccessors";
        _isPrivateBoolPropertyWithoutAccessors = "_isPrivateBoolPropertyWithoutAccessors";
        isPublicBoolPropertyWithoutAccessors = "isPublicBoolPropertyWithoutAccessors";

        ___propertyWithPublicGetAccessor = "___propertyWithPublicGetAccessor";
        ___propertyWithPublicAccessor = "___propertyWithPublicAccessor";
        ___propertyWithPublicBoolAccessor = "___propertyWithPublicBoolAccessor";
        ___propertyWithPrivateGetAccessor = "___propertyWithPrivateGetAccessor";
        ___propertyWithPrivateAccessor = "___propertyWithPrivateAccessor";
        ___propertyWithPrivateBoolAccessor = "___propertyWithPrivateBoolAccessor";
    }
    return self;
}

@end


@implementation CPKeyValueCodingTest : OJTestCase
{
    id  kvcTestObject;
}

- (void)setUp
{
    //do not allow direct access to assure that accessor are used by default
    [KVCTestClass setAccessInstanceVariablesDirectly: NO];
    kvcTestObject = [[KVCTestClass alloc] init];
}

@end

// "valueForKey:"

@implementation CPKeyValueCodingTest (AccessValueForUndefinedKey)

- (void)testIfExceptionIsThrownWhenUndefinedKeyIsAccessed
{
    [self assertThrows:function(){[kvcTestObject valueForKey:@"anUndefinedKey"];}];
}

@end

@implementation CPKeyValueCodingTest (AccessInstanceVariablesDirectly)

- (void)testIfPrivateInstanceVariableCanDirectlyBeAccessedWhenAllowedByClassMethod
{
    [KVCTestClass setAccessInstanceVariablesDirectly: YES];
    [self assertNoThrow:function(){[kvcTestObject valueForKey:@"privatePropertyWithoutAccessors"];}];
}

- (void)testIfPublicInstanceVariableCanDirectlyBeAccessedWhenAllowedByClassMethod
{
    [KVCTestClass setAccessInstanceVariablesDirectly: YES];
    [self assertNoThrow:function(){[kvcTestObject valueForKey:@"publicPropertyWithoutAccessors"];}];
}

- (void)testIfBooleanPrivateInstanceVariableCanDirectlyBeAccessedWhenAllowedByClassMethod
{
    [KVCTestClass setAccessInstanceVariablesDirectly: YES];
    [self assertNoThrow:function(){[kvcTestObject valueForKey:@"privateBoolPropertyWithoutAccessors"];}];
}

- (void)testIfBooleanPublicInstanceVariableCanDirectlyBeAccessedWhenAllowedByClassMethod
{
    [KVCTestClass setAccessInstanceVariablesDirectly: YES];
    [self assertNoThrow:function(){[kvcTestObject valueForKey:@"publicBoolPropertyWithoutAccessors"];}];
}

@end

@implementation CPKeyValueCodingTest (DoNotAccessInstanceVariablesDirectly)

- (void)testIfPrivateInstanceVariableCanNotDirectlyBeAccessedWhenProhibitedByClassMethod
{
    [self assertThrows:function(){[kvcTestObject valueForKey:@"privatePropertyWithoutAccessors"];}];
}

- (void)testIfPublicInstanceVariableCanNotDirectlyBeAccessedWhenProhibitedByClassMethod
{
    [self assertThrows:function(){[kvcTestObject valueForKey:@"publicPropertyWithoutAccessors"];}];
}

- (void)testIfBooleanPrivateInstanceVariableCanNotDirectlyBeAccessedWhenProhibitedByClassMethod
{
    [self assertThrows:function(){[kvcTestObject valueForKey:@"privateBoolPropertyWithoutAccessors"];}];
}

- (void)testIfBooleanPublicInstanceVariableCanNotDirectlyBeAccessedWhenProhibitedByClassMethod
{
    [self assertThrows:function(){[kvcTestObject valueForKey:@"publicBoolPropertyWithoutAccessors"];}];
}

@end

@implementation CPKeyValueCodingTest (AccessorMethodPatterns)

- (void)testIfPublicGetAccessorIsFound
{
    [self assertNoThrow:function(){[kvcTestObject valueForKey:@"propertyWithPublicGetAccessor"];}];
}

- (void)testIfPublicAccessorIsFound
{
    [self assertNoThrow:function(){[kvcTestObject valueForKey:@"propertyWithPublicAccessor"];}];
}

- (void)testIfPublicBoolAccessorIsFound
{
    [self assertNoThrow:function(){[kvcTestObject valueForKey:@"propertyWithPublicBoolAccessor"];}];
}

- (void)testIfPrivateGetAccessorIsFound
{
    [self assertNoThrow:function(){[kvcTestObject valueForKey:@"propertyWithPrivateGetAccessor"];}];
}

- (void)testIfPrivateAccessorIsFound
{
    [self assertNoThrow:function(){[kvcTestObject valueForKey:@"propertyWithPrivateAccessor"];}];
}

- (void)testIfPrivateBoolAccessorIsFound
{
    [self assertNoThrow:function(){[kvcTestObject valueForKey:@"propertyWithPrivateBoolAccessor"];}];
}

@end

@implementation CPKeyValueCodingTest (DictionaryWithValuesForKeys)

- (void)testIfDictionaryWithValuesForKeysDoesNotThrowsUndefinedKeyException
{
    [KVCTestClass setAccessInstanceVariablesDirectly: YES];
    var allKeys = [ "privatePropertyWithoutAccessors","publicPropertyWithoutAccessors",
                    "privateBoolPropertyWithoutAccessors","publicBoolPropertyWithoutAccessors",
                    "propertyWithPublicGetAccessor", "propertyWithPublicAccessor","propertyWithPublicBoolAccessor",
                    "propertyWithPrivateGetAccessor", "propertyWithPrivateAccessor", "propertyWithPrivateBoolAccessor"
                    ];
    [self assertNoThrow:function(){[kvcTestObject dictionaryWithValuesForKeys: allKeys];}];
}

- (void)testIfDictionaryWithValuesForKeysDoesThrowUndefinedKeyExceptionBecauseOfProhibitedDirectInstanceVariableAccess
{
    var allKeys = [ "privatePropertyWithoutAccessors","publicPropertyWithoutAccessors",
                    "privateBoolPropertyWithoutAccessors","publicBoolPropertyWithoutAccessors",
                    "propertyWithPublicGetAccessor", "propertyWithPublicAccessor","propertyWithPublicBoolAccessor",
                    "propertyWithPrivateGetAccessor", "propertyWithPrivateAccessor", "propertyWithPrivateBoolAccessor"
                    ];
    [self assertThrows:function(){[kvcTestObject dictionaryWithValuesForKeys: allKeys];}];
}

- (void)testIfDictionaryWithValuesForKeysCountIsEqualToNumberOfPropertyKeysGiven
{
    [KVCTestClass setAccessInstanceVariablesDirectly: YES];
    var allKeys = [ "privatePropertyWithoutAccessors","publicPropertyWithoutAccessors",
                    "privateBoolPropertyWithoutAccessors","publicBoolPropertyWithoutAccessors",
                    "propertyWithPublicGetAccessor", "propertyWithPublicAccessor","propertyWithPublicBoolAccessor",
                    "propertyWithPrivateGetAccessor", "propertyWithPrivateAccessor", "propertyWithPrivateBoolAccessor"
                    ],
        dictForKeys = [kvcTestObject dictionaryWithValuesForKeys: allKeys];

    [self assert: [allKeys count] equals: [dictForKeys count]];
}

- (void)testIfDictionaryWithValuesForKeysAreSameAsPropertyValues
{
    [KVCTestClass setAccessInstanceVariablesDirectly: YES];
    var allKeys = [ "privatePropertyWithoutAccessors","publicPropertyWithoutAccessors",
                    "privateBoolPropertyWithoutAccessors","publicBoolPropertyWithoutAccessors",
                    "propertyWithPublicGetAccessor", "propertyWithPublicAccessor","propertyWithPublicBoolAccessor",
                    "propertyWithPrivateGetAccessor", "propertyWithPrivateAccessor", "propertyWithPrivateBoolAccessor"
                    ],
        dictForKeys = [kvcTestObject dictionaryWithValuesForKeys: allKeys],
        key,
        value,
        keyEnumerator = [dictForKeys keyEnumerator];

    while ((key = [keyEnumerator nextObject]) !== nil)
    {
        value = [dictForKeys objectForKey: key];
        [self assert: [kvcTestObject valueForKey: key] same: value];
    }
}

@end

// "setValue: forKey:"

@implementation CPKeyValueCodingTest (ModifyValueForUndefinedKey)

- (void)testIfExceptionIsThrownWhenUndefinedKeyIsModified
{
    [self assertThrows:function(){[kvcTestObject setValue: "aValue" forKey:@"anUndefinedKey"];}];
}

@end

@implementation CPKeyValueCodingTest (ModifyInstanceVariablesDirectly)

- (void)testIfPrivateInstanceVariableCanDirectlyBeModifiedWhenAllowedByClassMethod
{
    [KVCTestClass setAccessInstanceVariablesDirectly: YES];

    var aValue = @"aValue";
    [self assert: aValue notSame: [kvcTestObject valueForKey:@"privatePropertyWithoutAccessors"]];
    [self assertNoThrow:function(){[kvcTestObject setValue: aValue forKey:@"privatePropertyWithoutAccessors"];}];
    [self assert: aValue same: [kvcTestObject valueForKey:@"privatePropertyWithoutAccessors"]];
}

- (void)testIfPublicInstanceVariableCanDirectlyBeModifiedWhenAllowedByClassMethod
{
    [KVCTestClass setAccessInstanceVariablesDirectly: YES];

    var aValue = @"aValue";
    [self assert: aValue notSame: [kvcTestObject valueForKey:@"publicPropertyWithoutAccessors"]];
    [self assertNoThrow:function(){[kvcTestObject setValue: aValue forKey:@"publicPropertyWithoutAccessors"];}];
    [self assert: aValue same: [kvcTestObject valueForKey:@"publicPropertyWithoutAccessors"]];
}

- (void)testIfBooleanPrivateInstanceVariableCanDirectlyBeModifiedWhenAllowedByClassMethod
{
    [KVCTestClass setAccessInstanceVariablesDirectly: YES];

    var aValue = @"aValue";
    [self assert: aValue notSame: [kvcTestObject valueForKey:@"privateBoolPropertyWithoutAccessors"]];
    [self assertNoThrow:function(){[kvcTestObject setValue: aValue forKey:@"privateBoolPropertyWithoutAccessors"];}];
    [self assert: aValue same: [kvcTestObject valueForKey:@"privateBoolPropertyWithoutAccessors"]];
}

- (void)testIfBooleanPublicInstanceVariableCanDirectlyBeModifiedWhenAllowedByClassMethod
{
    [KVCTestClass setAccessInstanceVariablesDirectly: YES];

    var aValue = @"aValue";
    [self assert: aValue notSame: [kvcTestObject valueForKey:@"publicBoolPropertyWithoutAccessors"]];
    [self assertNoThrow:function(){[kvcTestObject setValue: aValue forKey:@"publicBoolPropertyWithoutAccessors"];}];
    [self assert: aValue same: [kvcTestObject valueForKey:@"publicBoolPropertyWithoutAccessors"]];
}

@end

@implementation CPKeyValueCodingTest (DoNotModifyInstanceVariablesDirectly)

- (void)testIfPrivateInstanceVariableCanNotDirectlyBeModifiedWhenProhibitedByClassMethod
{
    [self assertThrows:function(){[kvcTestObject setValue: @"aValue" forKey:@"privatePropertyWithoutAccessors"];}];
}

- (void)testIfPublicInstanceVariableCanNotDirectlyBeModifiedWhenProhibitedByClassMethod
{
    [self assertThrows:function(){[kvcTestObject setValue: @"aValue" forKey:@"publicPropertyWithoutAccessors"];}];
}

- (void)testIfBooleanPrivateInstanceVariableCanNotDirectlyBeModifiedWhenProhibitedByClassMethod
{
    [self assertThrows:function(){[kvcTestObject setValue: @"aValue" forKey:@"privateBoolPropertyWithoutAccessors"];}];
}

- (void)testIfBooleanPublicInstanceVariableCanNotDirectlyBeModifiedWhenProhibitedByClassMethod
{
    [self assertThrows:function(){[kvcTestObject setValue: @"aValue" forKey:@"publicBoolPropertyWithoutAccessors"];}];
}

@end

@implementation CPKeyValueCodingTest (ModifierMethodPatterns)

- (void)testIfPublicModifierIsFound
{
    var aValue = @"aValue";
    [self assert: aValue notSame: [kvcTestObject valueForKey:@"propertyWithPublicAccessor"]];
    [self assertNoThrow:function(){[kvcTestObject setValue: aValue forKey:@"propertyWithPublicAccessor"];}];
    [self assert: aValue same: [kvcTestObject valueForKey:@"propertyWithPublicAccessor"]];
}

- (void)testIfPrivateModifierIsFound
{
    var aValue = @"aValue";
    [self assert: aValue notSame: [kvcTestObject valueForKey:@"propertyWithPrivateAccessor"]];
    [self assertNoThrow:function(){[kvcTestObject setValue: aValue forKey:@"propertyWithPrivateAccessor"];}];
    [self assert: aValue same: [kvcTestObject valueForKey:@"propertyWithPrivateAccessor"]];
}

@end

@implementation CPKeyValueCodingTest (SetValuesForKeysWithDictionary)

- (void)testIfSetValuesForKeysWithDictionaryDoesNotThrowsUndefinedKeyException
{
    [KVCTestClass setAccessInstanceVariablesDirectly: YES];

    var value = @"aValue",
        allKeys = [ "privatePropertyWithoutAccessors","publicPropertyWithoutAccessors",
                    "privateBoolPropertyWithoutAccessors","publicBoolPropertyWithoutAccessors",
                    "propertyWithPublicAccessor","propertyWithPrivateAccessor"
                    ],
        allValues = [value, value, value, value, value, value],
        dictForKeys = [CPDictionary dictionaryWithObjects: allValues forKeys: allKeys];
    [self assertNoThrow:function(){[kvcTestObject setValuesForKeysWithDictionary: dictForKeys];}];
}

- (void)testIfSetValuesForKeysWithDictionaryDoesThrowUndefinedKeyExceptionBecauseOfProhibitedDirectInstanceVariableAccess
{
    var value = @"aValue",
        allKeys = [ "privatePropertyWithoutAccessors","publicPropertyWithoutAccessors",
                    "privateBoolPropertyWithoutAccessors","publicBoolPropertyWithoutAccessors",
                    "propertyWithPublicAccessor","propertyWithPrivateAccessor"
                    ],
        allValues = [value, value, value, value, value, value],
        dictForKeys = [CPDictionary dictionaryWithObjects: allValues forKeys: allKeys];
    [self assertThrows:function(){[kvcTestObject setValuesForKeysWithDictionary: dictForKeys];}];
}

- (void)testIfSetValuesForKeysWithDictionaryAreSameAsPropertyValues
{
    [KVCTestClass setAccessInstanceVariablesDirectly: YES];

    var value = @"aValue",
        allKeys = [ "privatePropertyWithoutAccessors","publicPropertyWithoutAccessors",
                    "privateBoolPropertyWithoutAccessors","publicBoolPropertyWithoutAccessors",
                    "propertyWithPublicAccessor","propertyWithPrivateAccessor"
                    ],
        allValues = [value, value, value, value, value, value],
        dictForKeys = [CPDictionary dictionaryWithObjects: allValues forKeys: allKeys];
    [kvcTestObject setValuesForKeysWithDictionary: dictForKeys];

    var key,
        aValue,
        keyEnumerator = [dictForKeys keyEnumerator];

    while ((key = [keyEnumerator nextObject]) !== nil)
    {
        aValue = [dictForKeys objectForKey: key];
        [self assert: [kvcTestObject valueForKey: key] same: aValue];
    }
}

@end

// CPNull - nil conversion for Dictionaries

@implementation CPKeyValueCodingTest (NilToCPNullConversion)

- (void)testIfNilValuesAreProperlyConvertedToCPNullInDictionary
{
    [KVCTestClass setAccessInstanceVariablesDirectly: YES];

    [kvcTestObject setValue:nil forKey: "privatePropertyWithoutAccessors"];
    [kvcTestObject setValue:nil forKey: "publicPropertyWithoutAccessors"];
    [kvcTestObject setValue:nil forKey: "privateBoolPropertyWithoutAccessors"];
    [kvcTestObject setValue:nil forKey: "publicBoolPropertyWithoutAccessors"];
    [kvcTestObject setValue:nil forKey: "propertyWithPublicAccessor"];
    [kvcTestObject setValue:nil forKey: "propertyWithPrivateAccessor"];

    var allKeys = [ "privatePropertyWithoutAccessors","publicPropertyWithoutAccessors",
                    "privateBoolPropertyWithoutAccessors","publicBoolPropertyWithoutAccessors",
                    "propertyWithPublicAccessor", "propertyWithPrivateAccessor"
                    ],
        dictForKeys = [kvcTestObject dictionaryWithValuesForKeys: allKeys],
        key,
        value,
        keyEnumerator = [dictForKeys keyEnumerator];

    while ((key = [keyEnumerator nextObject]) !== nil)
    {
        value = [dictForKeys objectForKey: key];
        [self assert: [CPNull null] same:value ];
    }
}

- (void)testIfCPNullInDictionaryIsProperlyConvertedToNilValues
{
    [KVCTestClass setAccessInstanceVariablesDirectly: YES];

    var value = [CPNull null],
        allKeys = [ "privatePropertyWithoutAccessors","publicPropertyWithoutAccessors",
                    "privateBoolPropertyWithoutAccessors","publicBoolPropertyWithoutAccessors",
                    "propertyWithPublicAccessor","propertyWithPrivateAccessor"
                    ],
        allValues = [value,value,value,value,value,value],
        dictForKeys = [CPDictionary dictionaryWithObjects: allValues forKeys: allKeys];
    [kvcTestObject setValuesForKeysWithDictionary: dictForKeys];

    [self assertNull: [kvcTestObject valueForKey: "privatePropertyWithoutAccessors"]];
    [self assertNull: [kvcTestObject valueForKey: "publicPropertyWithoutAccessors"]];
    [self assertNull: [kvcTestObject valueForKey: "privateBoolPropertyWithoutAccessors"]];
    [self assertNull: [kvcTestObject valueForKey: "publicBoolPropertyWithoutAccessors"]];
    [self assertNull: [kvcTestObject valueForKey: "propertyWithPublicAccessor"]];
    [self assertNull: [kvcTestObject valueForKey: "propertyWithPrivateAccessor"]];
}

@end

// CPDictionary

@implementation CPKeyValueCodingTest (CPDictionaryTests)

- (void)testIfValueForKeyAccessesObjectForKey
{
    var testDictionary = @{};
    [testDictionary setObject:kvcTestObject forKey:@"testKey"];
    [self assert: kvcTestObject same: [testDictionary valueForKey: @"testKey"]];
}

- (void)testIfSetValueForKeyModifiesObjectForKey
{
    var testDictionary = @{};
    [testDictionary setValue:kvcTestObject forKey:@"testKey"];
    [self assert: kvcTestObject same: [testDictionary objectForKey: @"testKey"]];
}

@end

// CPNull

@implementation CPKeyValueCodingTest (CPNullTest)

- (void)testIfCPNullReturnsCPNullForAllKeys
{
    var nullObject = [CPNull null];
    [self assert:[CPNull null] equals:[nullObject valueForKey:@"a"] message:@"CPNull valueForKey:X returns nil"];
}

- (void)testValueForKeyPath
{
    var department = [Department2 departmentWithName:@"Engineering"],
        employee = [Employee2 employeeWithName:@"Klaas Pieter" department:department];

    [self assert:department equals:[employee valueForKey:@"department"]];
    [self assert:@"Engineering" equals:[employee valueForKeyPath:@"department.name"]];
}

@end

@implementation Employee2 : CPObject
{
    CPString                    _name @accessors(property=name);
    Department2                 _department @accessors(property=department);
}

+ (id)employeeWithName:(CPString)theName department:(Department)theDepartment
{
    return [[self alloc] initWithName:theName department:theDepartment];
}

- (id)initWithName:(CPString)theName department:(Department)theDepartment
{
    if (self = [super init])
    {
        _name = theName;
        _department = theDepartment;
    }

    return self;
}

@end

@implementation Department2 : CPObject
{
    CPString                _name @accessors(property=name);
}

+ (id)departmentWithName:(CPString)theName
{
    return [[self alloc] initWithName:theName];
}

- (id)initWithName:(CPString)theName
{
    if (self = [super init])
    {
        _name = theName;
    }

    return self;
}

@end

@implementation ObjectInObjectsAtIndexClass : CPObject
{
}

- (id)objectInObjectsAtIndex:(CPUInteger)anIndex
{
    switch (anIndex)
    {
        case 0: return @"one";
        case 1: return @"two";
        case 2: return @"three";
        case 3: return @"four";
        case 4: return @"five";
    }

    [CPException raise:CPRangeException reason:@"index (" + anIndex + @") beyond bounds (" + [self count] + @")"];
}

- (CPUInteger)countOfObjects
{
    return 5;
}

@end

@implementation ObjectsAtIndexesClass : CPObject
{
}

- (id)objectsAtIndexes:(CPIndexSet)indexes
{
    return [[@"one", @"two", @"three", @"four", @"five"] objectsAtIndexes:indexes];
}

- (CPUInteger)countOfObjects
{
    return 5;
}

@end

@implementation CPKeyValueCodingTest (IndexedAccessorPattern)

- (void)testObjectInObjectsAtIndex_
{
    var object = [ObjectInObjectsAtIndexClass new],
        array = [object valueForKey:@"objects"];

    [self assert:5 equals:[array count]];

    [self assert:@"one" equals:[array objectAtIndex:0]];
    [self assert:@"two" equals:[array objectAtIndex:1]];
    [self assert:@"three" equals:[array objectAtIndex:2]];
    [self assert:@"four" equals:[array objectAtIndex:3]];
    [self assert:@"five" equals:[array objectAtIndex:4]];

    var indexes = [CPIndexSet indexSet];

    [indexes addIndex:1];
    [indexes addIndex:3];

    [self assert:[@"two", @"four"] equals:[array objectsAtIndexes:indexes]];
}

- (void)testObjectsAtIndexes_
{
    var object = [ObjectsAtIndexesClass new],
        array = [object valueForKey:@"objects"];

    [self assert:5 equals:[array count]];

    [self assert:@"one" equals:[array objectAtIndex:0]];
    [self assert:@"two" equals:[array objectAtIndex:1]];
    [self assert:@"three" equals:[array objectAtIndex:2]];
    [self assert:@"four" equals:[array objectAtIndex:3]];
    [self assert:@"five" equals:[array objectAtIndex:4]];

    var indexes = [CPIndexSet indexSet];

    [indexes addIndex:1];
    [indexes addIndex:3];

    [self assert:[@"two", @"four"] equals:[array objectsAtIndexes:indexes]];
}

- (void)testKVArrayCopy
{
    var object = [ObjectsAtIndexesClass new],
        array = [object valueForKey:@"objects"];

    [self assert:[CPArray arrayWithObjects:@"one", @"two", @"three", @"four", @"five"] equals:[array copy]];
}

@end


@implementation UnorderedAccessorClass : CPObject
{
}

- (id)memberOfObjects:(id)anObject
{
    if ([[0, 1, 3, 5, 7] indexOfObjectIdenticalTo:anObject] !== CPNotFound)
        return anObject;

    return nil;
}

- (CPEnumerator)enumeratorOfObjects
{
    return [[0, 1, 3, 5, 7] objectEnumerator];
}

- (CPUInteger)countOfObjects
{
    return 5;
}

@end

@implementation CPKeyValueCodingTest (UnorderedAccessorPattern)

- (void)testUnorderedAccessorPattern
{
    var object = [UnorderedAccessorClass new],
        set = [object valueForKey:@"objects"];

    [self assert:set equals:[CPSet setWithObjects:0, 1, 3, 5, 7]];

    [self assertTrue:[set containsObject:0]];
    [self assertTrue:[set containsObject:1]];
    [self assertTrue:[set containsObject:3]];
    [self assertTrue:[set containsObject:5]];
    [self assertTrue:[set containsObject:7]];

    [self assertFalse:[set containsObject:2]];
    [self assertFalse:[set containsObject:4]];
    [self assertFalse:[set containsObject:6]];
    [self assertFalse:[set containsObject:8]];
    [self assertFalse:[set containsObject:10]];

    [self assert:[set setByAddingObjectsFromArray:[2, 3, 4, 5, 6]]
            equals:[CPSet setWithObjects:0, 1, 2, 3, 4, 5, 6, 7]];
}

- (void)testKVSetCopy
{
    var object = [UnorderedAccessorClass new],
        set = [object valueForKey:@"objects"];

    [self assert:[CPSet setWithObjects:0, 1, 3, 5, 7] equals:[set copy]];
}

@end
