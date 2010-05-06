
// TODO: add many many more of these...
var sprintfTestCases = [
    [["[%@]", "hello world"], "[hello world]"],
    [["[%d]", 123], "[123]"],
    [["[%f]", 123.1234], "[123.1234]"],
    [["[%d]", 123.1234], "[123]"]
];

@implementation sprintfTest : OJTestCase

- (void)test_sprintf
{
    for (var i = 0; i < sprintfTestCases.length; i++)
    {
        [self assert:ObjectiveJ.sprintf.apply(null, sprintfTestCases[i][0]) equals:sprintfTestCases[i][1]];
    }
}

@end
