@import <Foundation/CPArray.j>
@import <Foundation/CPString.j>
@import <Foundation/CPNumber.j>

@implementation CPArrayTest : OJTestCase

- (void)testComponentsJoinedByString
{
    var testStrings = [
        [[], "", ""],
        [[], "-", ""],
        [[1,2], "-", "1-2"],
        [[1,2,3], "-", "1-2-3"],
        [["123", 456], "-", "123-456"]
    ];
    
    for (var i = 0; i < testStrings.length; i++)
        [self assert:[testStrings[i][0] componentsJoinedByString:testStrings[i][1]] equals:testStrings[i][2]];
}

- (void)testsInsertObjectsAtIndexes
{
    var array = [CPMutableArray arrayWithObjects:@"one", @"two", @"three", @"four", nil],
        newAdditions = [CPArray arrayWithObjects:@"a", @"b", nil],
        indexes = [CPMutableIndexSet indexSetWithIndex:1];

    [indexes addIndex:3];

    [array insertObjects:newAdditions atIndexes:indexes];

    [self assert:array equals:[@"one", @"a", @"two", @"b", @"three", @"four"]];

    var array = [CPMutableArray arrayWithObjects:@"one", @"two", @"three", @"four", nil],
        newAdditions = [CPArray arrayWithObjects:@"a", @"b", nil],
        indexes = [CPMutableIndexSet indexSetWithIndex:5];
    
    [indexes addIndex:4];
    
    [array insertObjects:newAdditions atIndexes:indexes];

    [self assert:array equals:[@"one", @"two", @"three", @"four", @"a", @"b"]];
    
    var array = [CPMutableArray arrayWithObjects: @"one", @"two", @"three", @"four", nil],
        newAdditions = [CPArray arrayWithObjects: @"a", @"b", @"c", nil],
        indexes = [CPMutableIndexSet indexSetWithIndex:1];

    [indexes addIndex:2];
    [indexes addIndex:4];
    
    [array insertObjects:newAdditions atIndexes:indexes];

    [self assert:array equals:[@"one", @"a", @"b", @"two", @"c", @"three", @"four"]];


    var array = [CPMutableArray arrayWithObjects: @"one", @"two", @"three", @"four", nil],
        newAdditions = [CPArray arrayWithObjects: @"a", @"b", @"c", nil],
        indexes = [CPMutableIndexSet indexSetWithIndex:1];

    [indexes addIndex:2];
    [indexes addIndex:6];

    [array insertObjects:newAdditions atIndexes:indexes];
    
    [self assert:array equals:[@"one", @"a", @"b", @"two", @"three", @"four", @"c"]];

    //
    
    var array = [CPMutableArray arrayWithObjects:@"one", @"two", @"three", @"four", nil],
        newAdditions = [CPArray arrayWithObjects:@"a", @"b", nil],
        indexes = [CPMutableIndexSet indexSetWithIndex:5];
    
    [indexes addIndex:6];
    
    try
    {
        [array insertObjects:newAdditions atIndexes:indexes];
        [self fail];
    }
    catch (e)
    {
        if ((e.isa) && [e name] == AssertionFailedError)
            throw e;
    }
}

- (void)testRemoveObjectsAtIndexes
{
	var array = [CPMutableArray arrayWithObjects:@"one", @"two", @"three", @"four", nil],
			indexes = [CPMutableIndexSet indexSetWithIndex: 2];
			
	[array removeObjectsAtIndexes: indexes];
	
	[self assert:array equals:[@"one", @"two", @"four"]];
}
@end
