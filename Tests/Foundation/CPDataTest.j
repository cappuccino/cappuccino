@import <Foundation/CPArray.j>
@import <Foundation/CPData.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPNumber.j>

@implementation CPDataTest : OJTestCase
{
}

- (void)testPlistObjects
{
    var string = @"Hello World",
        data = [CPData dataWithPlistObject:string];

    [self assert:[data rawString] equals:@"280NPLIST;1.0;S;11;Hello World"];
    [self assert:[data plistObject] equals:@"Hello World"];

    data = [CPData dataWithRawString:@"280NPLIST;1.0;S;11;Hello World"];

    [self assert:[data rawString] equals:@"280NPLIST;1.0;S;11;Hello World"];
    [self assert:[data plistObject] equals:@"Hello World"];

    var array = [0, 1.0, "Two"];

    data = [CPData dataWithPlistObject:array];

    [self assert:[data rawString] equals:@"280NPLIST;1.0;A;d;1;0d;1;1S;3;TwoE;"];
    [self assert:[data plistObject] equals:array];

    data = [CPData dataWithRawString:@"280NPLIST;1.0;A;d;1;0d;1;1S;3;TwoE;"];

    [self assert:[data rawString] equals:@"280NPLIST;1.0;A;d;1;0d;1;1S;3;TwoE;"];
    [self assert:[[data plistObject] isEqual:array] equals:true];

    var dictionary = [CPDictionary dictionaryWithObject:array forKey:@"array"];

    data = [CPData dataWithPlistObject:dictionary];

    [self assert:[data rawString] equals:@"280NPLIST;1.0;D;K;5;arrayA;d;1;0d;1;1S;3;TwoE;E;"];
    [self assert:[data plistObject] equals:dictionary];

    data = [CPData dataWithRawString:@"280NPLIST;1.0;D;K;5;arrayA;d;1;0d;1;1S;3;TwoE;E;"];

    [self assert:[data rawString] equals:@"280NPLIST;1.0;D;K;5;arrayA;d;1;0d;1;1S;3;TwoE;E;"];
    [self assert:[[data plistObject] isEqual:dictionary] equals:true];

    [self assertNull:[data JSONObject]];
}

- (void)testJSONObjects
{
    var object = { first: { one:1 }, second: { two:2 } },
        data = [CPData dataWithJSONObject:object];

    [self assert:[data rawString] equals:JSON.stringify(object)];
    [self assert:[data JSONObject] equals:object];

    [self assertNull:[data plistObject]];

    data = [CPData dataWithRawString:"{\"first\":{\"one\":1},\"second\":{\"two\":2}}"];

    [self assert:[data rawString] equals:JSON.stringify(object)];
    [self assertNoThrow:function () { require("assert").deepEqual([data JSONObject], object); }];

    [self assertNull:[data plistObject]];
}

- (void)test_CPData_accessors
{
    var rawString = "cappuccino",
        bytes = [99, 97, 112, 112, 117, 99, 99, 105, 110, 111],
        base64 = "Y2FwcHVjY2lubw==";

    var data = [CPData dataWithBase64:base64];
    [self assert:rawString equals:[data rawString]];

    data = [CPData dataWithBase64:base64];
    [self assert:bytes equals:[data bytes]];

    data = [CPData dataWithBase64:base64];
    [self assert:base64 equals:[data base64]];


    data = [CPData dataWithRawString:rawString];
    [self assert:rawString equals:[data rawString]];

    data = [CPData dataWithRawString:rawString];
    [self assert:bytes equals:[data bytes]];

    data = [CPData dataWithRawString:rawString];
    [self assert:base64 equals:[data base64]];

    data = [CPData dataWithBytes:bytes];
    [self assert:rawString equals:[data rawString]];

    data = [CPData dataWithBytes:bytes];
    [self assert:bytes equals:[data bytes]];

    data = [CPData dataWithBytes:bytes];
    [self assert:base64 equals:[data base64]];
}

@end
