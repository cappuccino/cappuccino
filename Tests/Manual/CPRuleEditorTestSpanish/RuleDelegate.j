@import <Foundation/CPObject.j>
@import <AppKit/CPRuleEditor.j>
@import <AppKit/CPTextField.j>

@implementation RuleDelegate : CPObject
{
}

// 1. Root criteria and children
- (id)ruleEditor:(CPRuleEditor)editor child:(CPInteger)index forCriterion:(id)criterion withRowType:(CPRuleEditorRowType)rowType
{
    if (criterion == nil)
    {
        // Root criteria
        return [@[@"firstName", @"lastName", @"age"] objectAtIndex:index];
    }
    
    if ([criterion isEqualToString:@"firstName"] || [criterion isEqualToString:@"lastName"])
    {
        return [@[@"contains", @"is equal to"] objectAtIndex:index];
    }
    
    if ([criterion isEqualToString:@"age"])
    {
        return [@[@"is equal to"] objectAtIndex:index];
    }
    
    if ([criterion isEqualToString:@"contains"] || [criterion isEqualToString:@"is equal to"])
    {
        // The child of an operator is the leaf value node
        return @"value";
    }
    
    return nil;
}

// 2. Number of children for a given criterion
- (CPInteger)ruleEditor:(CPRuleEditor)editor numberOfChildrenForCriterion:(id)criterion withRowType:(CPRuleEditorRowType)rowType
{
    if (criterion == nil)
    {
        return 3; // firstName, lastName, age
    }
    
    if ([criterion isEqualToString:@"firstName"] || [criterion isEqualToString:@"lastName"])
    {
        return 2; // contains, is equal to
    }
    
    if ([criterion isEqualToString:@"age"])
    {
        return 1; // is equal to
    }
    
    if ([criterion isEqualToString:@"contains"] || [criterion isEqualToString:@"is equal to"])
    {
        // Operators have one child representing the input field value
        return 1;
    }
    
    return 0; // Leaf nodes return 0
}

// 3. Display values (labels, popup titles, or text input fields)
- (id)ruleEditor:(CPRuleEditor)editor displayValueForCriterion:(id)criterion inRow:(CPInteger)row
{
    if ([criterion isEqualToString:@"firstName"]) return @"firstName";
    if ([criterion isEqualToString:@"lastName"]) return @"lastName";
    if ([criterion isEqualToString:@"age"]) return @"age";
    
    if ([criterion isEqualToString:@"contains"]) return @"contains";
    if ([criterion isEqualToString:@"is equal to"]) return @"is equal to";
    
    if ([criterion isEqualToString:@"value"])
    {
        // Return the actual editable text field view for the leaf node
        var textField = [[CPTextField alloc] initWithFrame:CGRectMake(0, 0, 120, 24)];
        [textField setBezeled:YES];
        [textField setBezelStyle:CPTextFieldSquareBezel];
        [textField setEditable:YES];
        [textField setStringValue:@""];
        return textField;
    }
    
    return nil;
}

// 4. Predicate parts mapping
- (CPDictionary)ruleEditor:(CPRuleEditor)editor predicatePartsForCriterion:(id)criterion withDisplayValue:(id)value inRow:(CPInteger)row
{
    var parts = @{};
    
    if ([criterion isEqualToString:@"firstName"] || [criterion isEqualToString:@"lastName"] || [criterion isEqualToString:@"age"])
    {
        [parts setObject:[CPExpression expressionForKeyPath:criterion] forKey:CPRuleEditorPredicateLeftExpression];
    }
    else if ([criterion isEqualToString:@"contains"])
    {
        [parts setObject:[CPNumber numberWithUnsignedInt:CPContainsPredicateOperatorType] forKey:CPRuleEditorPredicateOperatorType];
    }
    else if ([criterion isEqualToString:@"is equal to"])
    {
        [parts setObject:[CPNumber numberWithUnsignedInt:CPEqualToPredicateOperatorType] forKey:CPRuleEditorPredicateOperatorType];
    }
    else if ([criterion isEqualToString:@"value"])
    {
        [parts setObject:[CPExpression expressionForConstantValue:[value stringValue]] forKey:CPRuleEditorPredicateRightExpression];
    }
    
    return parts;
}

@end
