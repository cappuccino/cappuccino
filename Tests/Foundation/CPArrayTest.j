import <Foundation/CPArray.j>
import <Foundation/CPString.j>
import <Foundation/CPNumber.j>

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

@end
