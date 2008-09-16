import <Foundation/CPString.j>

@implementation CPStringTest : OJTestCase

- (void) testBoolValue
{
	var testString = @"  090";
	[self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];
	
	testString = @"  YES";
	[self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];
	
	testString = @"  true";
	[self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];
	
	testString = @"  True";
	[self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];

	testString = @"  tTR";
	[self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];

	testString = @"  +98";
	[self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];

	testString = @"  -98";
	[self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];

	testString = @"  +08";
	[self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];

	testString = @"  -98";
	[self assertTrue:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];

	testString = @"  NO";
	[self assertFalse:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];
	
	testString = @"  -N00";
	[self assertFalse:[testString boolValue] message:"boolValue for the string " + testString +  " should return true"];
}


@end
