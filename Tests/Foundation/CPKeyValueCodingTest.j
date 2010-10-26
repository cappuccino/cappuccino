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
	id			_privatePropertyWithoutAccessors;
	id			publicPropertyWithoutAccessors;
	id			_isPrivateBoolPropertyWithoutAccessors;
	id			isPublicBoolPropertyWithoutAccessors;

	id			___propertyWithPublicGetAccessor			@accessors(getter=getPropertyWithPublicGetAccessor);
	id			___propertyWithPublicAccessor				@accessors(getter=propertyWithPublicAccessor);
	id			___propertyWithPublicBoolAccessor			@accessors(getter=isPropertyWithPublicBoolAccessor);
	id			___propertyWithPrivateGetAccessor			@accessors(getter=_getPropertyWithPrivateGetAccessor);
	id			___propertyWithPrivateAccessor				@accessors(getter=_propertyWithPrivateAccessor);
	id			___propertyWithPrivateBoolAccessor			@accessors(getter=_isPropertyWithPrivateBoolAccessor);
}

+ (BOOL)accessInstanceVariablesDirectly
{
    return accessIVARS;
}

+ (void)setAccessInstanceVariablesDirectly:(BOOL)accessDirectly
{
	accessIVARS = accessDirectly;
}

@end


@implementation CPKeyValueCodingTest : OJTestCase
{
	id	kvcTestObject;
}

- (void)setUp
{
	//do not allow direct access to assure that accessor are used by default
	[KVCTestClass setAccessInstanceVariablesDirectly: NO];
	kvcTestObject = [[KVCTestClass alloc] init];
}

- (void)tearDown
{
}

@end

// "valueForKey:"

@implementation CPKeyValueCodingTest (CPNullTest)

- (void)testIfCPNullReturnsCPNullForAllKeys
{
    var nullObject = [CPNull null];
    [self assert:[CPNull null] equals:[nullObject valueForKey:@"a"] message:@"CPNull valueForKey:X returns nil"];
}

@end

@implementation CPKeyValueCodingTest (AccessValueForUndefinedKey)

- (void)testIfExceptionIsThrownForUndefinedKey
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

@implementation CPKeyValueCodingTest (DoNotAccessInstanceVariables)

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
	var allKeys = [	"privatePropertyWithoutAccessors","publicPropertyWithoutAccessors",
					"privateBoolPropertyWithoutAccessors","publicBoolPropertyWithoutAccessors",
	 				"propertyWithPublicGetAccessor", "propertyWithPublicAccessor","propertyWithPublicBoolAccessor",
					"propertyWithPrivateGetAccessor", "propertyWithPrivateAccessor", "propertyWithPrivateBoolAccessor"
					];
	[self assertNoThrow:function(){[kvcTestObject dictionaryWithValuesForKeys: allKeys];}];
}

- (void)testIfDictionaryWithValuesForKeysDoesThrowUndefinedKeyExceptionBecauseOfProhibitedDirectInstanceVariableAccess
{
	var allKeys = [	"privatePropertyWithoutAccessors","publicPropertyWithoutAccessors",
					"privateBoolPropertyWithoutAccessors","publicBoolPropertyWithoutAccessors",
	 				"propertyWithPublicGetAccessor", "propertyWithPublicAccessor","propertyWithPublicBoolAccessor",
					"propertyWithPrivateGetAccessor", "propertyWithPrivateAccessor", "propertyWithPrivateBoolAccessor"
					];
	[self assertThrows:function(){[kvcTestObject dictionaryWithValuesForKeys: allKeys];}];
}

- (void)testIfDictionaryWithValuesForKeysContainsValuesForEveryProperty
{
	[KVCTestClass setAccessInstanceVariablesDirectly: YES];
	var allKeys = [	"privatePropertyWithoutAccessors","publicPropertyWithoutAccessors",
					"privateBoolPropertyWithoutAccessors","publicBoolPropertyWithoutAccessors",
	 				"propertyWithPublicGetAccessor", "propertyWithPublicAccessor","propertyWithPublicBoolAccessor",
					"propertyWithPrivateGetAccessor", "propertyWithPrivateAccessor", "propertyWithPrivateBoolAccessor"
					];
	var dictForKeys = [kvcTestObject dictionaryWithValuesForKeys: allKeys];

	[self assert: [allKeys count] equals: [dictForKeys count]];
}

@end

// "setValue: forKey:"