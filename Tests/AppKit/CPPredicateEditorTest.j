@import <AppKit/AppKit.j>
@import <Foundation/CPExpression.j>

@implementation CPPredicateEditorTest : OJTestCase
{
    CPPredicateEditor _editor;
}

- (void)setUp
{
    _editor = [[CPPredicateEditor alloc] initWithFrame:CGRectMakeZero()];
}

- (void)testTemplatesMerging
{
    var le1 = [CPExpression expressionForKeyPath:@"keypath1"],
        le2 = [CPExpression expressionForKeyPath:@"keypath2"],
        le3 = [CPExpression expressionForKeyPath:@"keypath3"];

    var lexps1 = [le1, le2],
        lexps2 = [le2, le3];

    var ops1 = [CPBeginsWithPredicateOperatorType, CPEndsWithPredicateOperatorType],
        ops2 = [CPGreaterThanPredicateOperatorType, CPEqualToPredicateOperatorType];

    var t1 = [[CPPredicateEditorRowTemplate alloc] initWithLeftExpressions:lexps1 rightExpressionAttributeType:CPStringAttributeType modifier:0 operators:ops1 options:0],
        t2 = [[CPPredicateEditorRowTemplate alloc] initWithLeftExpressions:lexps2 rightExpressionAttributeType:CPInteger16AttributeType modifier:0 operators:ops2 options:0];

    var errorFormat = @"The left criterion %@ should have children with the following templates:\n%@\nbut was:\n%@";

    [_editor setRowTemplates:[t1, t2]];

    var trees = _editor._rootTrees,
        count = [trees count];

    // We are expecting 3 criterion on the left.
    [self assertTrue:(count == 3) message:"We should have 3 criterion on the left, was " + count];

    for (var i = 0; i < count; i++)
    {
        var aTree = [trees objectAtIndex:i],
            title = [aTree title],
            templates = [[aTree children] valueForKey:@"template"],
            expected;

        if ([title isEqualToString:@"keypath1"])
            expected = [t1, t1];
        else if ([title isEqualToString:@"keypath2"])
            expected = [t1, t1, t2, t2];
        else if ([title isEqualToString:@"keypath3"])
            expected = [t2, t2];

        [self assertTrue:[templates isEqualToArray:expected] message:[CPString stringWithFormat:errorFormat, title, [expected description], [templates description]]];
    }
}

@end
