@import <Foundation/CPObject.j>
@import <AppKit/CPRuleEditor.j>
@import <AppKit/CPTextField.j>

// Ensure the standard operator constants are explicitly defined
var CPEqualToPredicateOperatorType = 4,
    CPContainsPredicateOperatorType = 99;

@implementation RuleDelegate : CPObject
{
}

// 1. Root criteria and children
- (id)ruleEditor:(CPRuleEditor)editor child:(CPInteger)index forCriterion:(id)criterion withRowType:(CPRuleEditorRowType)rowType
{
    if (criterion == nil)
    {
        return [@[@"firstName", @"lastName", @"age"] objectAtIndex:index];
    }
    
    if ([criterion isEqualToString:@"firstName"] || [criterion isEqualToString:@"lastName"])
    {
        return [@[@"is equal to", @"contains"] objectAtIndex:index];
    }
    
    if ([criterion isEqualToString:@"age"])
    {
        return [@[@"is equal to"] objectAtIndex:index];
    }
    
    if ([criterion isEqualToString:@"contains"] || [criterion isEqualToString:@"is equal to"])
    {
        return @"value";
    }
    
    return nil;
}

// 2. Number of children
- (CPInteger)ruleEditor:(CPRuleEditor)editor numberOfChildrenForCriterion:(id)criterion withRowType:(CPRuleEditorRowType)rowType
{
    if (criterion == nil)
    {
        return 3;
    }
    
    if ([criterion isEqualToString:@"firstName"] || [criterion isEqualToString:@"lastName"])
    {
        return 2;
    }
    
    if ([criterion isEqualToString:@"age"])
    {
        return 1;
    }
    
    if ([criterion isEqualToString:@"contains"] || [criterion isEqualToString:@"is equal to"])
    {
        return 1;
    }
    
    return 0;
}

// 3. Display values
- (id)ruleEditor:(CPRuleEditor)editor displayValueForCriterion:(id)criterion inRow:(CPInteger)row
{
    if ([criterion isEqualToString:@"firstName"]) return @"firstName";
    if ([criterion isEqualToString:@"lastName"]) return @"lastName";
    if ([criterion isEqualToString:@"age"]) return @"age";
    
    if ([criterion isEqualToString:@"contains"]) return @"contains";
    if ([criterion isEqualToString:@"is equal to"]) return @"is equal to";
    
    if ([criterion isEqualToString:@"value"])
    {
        var textField = [[CPTextField alloc] initWithFrame:CGRectMake(0, 0, 120, 24)];
        [textField setBezeled:YES];
        [textField setBezelStyle:CPTextFieldSquareBezel];
        [textField setEditable:YES];
        [textField setStringValue:@""];
        return textField;
    }
    
    return nil;
}

// 4. Predicate parts
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
        var activeValue = value;
        var slices = [editor valueForKey:@"_slices"];
        
        if (slices && row < [slices count])
        {
            var slice = [slices objectAtIndex:row];
            var optionViews = [slice valueForKey:@"_ruleOptionViews"];
            if (optionViews)
            {
                var count = [optionViews count];
                for (var i = 0; i < count; i++)
                {
                    var view = [optionViews objectAtIndex:i];
                    if ([view isKindOfClass:[CPTextField class]] && [view isEditable])
                    {
                        activeValue = view;
                        break;
                    }
                }
            }
        }

        [parts setObject:[CPExpression expressionForConstantValue:[activeValue stringValue]] forKey:CPRuleEditorPredicateRightExpression];
    }
    
    return parts;
}

@end
