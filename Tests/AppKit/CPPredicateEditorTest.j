@import <AppKit/AppKit.j>
@import <Foundation/CPExpression.j>

@implementation CPPredicateEditorTest : OJTestCase
{
    CPPredicateEditor _editor;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

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

- (void)testObjectValueWithRightWildcard
{
    [self _testAttribute:CPDateAttributeType value:[CPDate date]];
    [self _testAttribute:CPInteger16AttributeType value:2.0];
    [self _testAttribute:CPDoubleAttributeType value:2.5];
    [self _testAttribute:CPFloatAttributeType value:2.5];
    [self _testAttribute:CPStringAttributeType value:@"toto"];
    [self _testAttribute:CPBooleanAttributeType value:1];
}

- (void)_testAttribute:(int)attr value:(id)value
{
    var leftExp = [CPExpression expressionForKeyPath:@"keypath"],
        rightExp = [CPExpression expressionForConstantValue:value],
        predicate = [CPComparisonPredicate predicateWithLeftExpression:leftExp rightExpression:rightExp modifier:0 type:CPEqualToPredicateOperatorType options:0],
        compound = [[CPCompoundPredicate alloc] initWithType:CPAndPredicateType subpredicates:@[predicate]];

    var t1 = [[CPPredicateEditorRowTemplate alloc] initWithCompoundTypes:[0,1,2]],
        t2 = [[CPPredicateEditorRowTemplate alloc] initWithLeftExpressions:@[leftExp] rightExpressionAttributeType:attr modifier:0 operators:@[CPEqualToPredicateOperatorType] options:0];

    [_editor setRowTemplates:@[t1, t2]];

    [_editor setObjectValue:compound];
    [_editor reloadPredicate];
    [self assert:compound equals:[_editor objectValue]];
}

@end
