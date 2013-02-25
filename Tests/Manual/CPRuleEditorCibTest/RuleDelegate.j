/*
 *     Created by cacaodev@gmail.com.
 *     Copyright (c) 2008 Pear, Inc. All rights reserved.
 */

@import <AppKit/CPRuleEditor.j>
@import "RuleControls.j"

var CPRuleEditorPredicateKeys = [
                                    CPRuleEditorPredicateLeftExpression,
                                    CPRuleEditorPredicateRightExpression,
                                    CPRuleEditorPredicateComparisonModifier,
                                    CPRuleEditorPredicateOptions,
                                    CPRuleEditorPredicateOperatorType,
                                    CPRuleEditorPredicateCustomSelector,
                                    CPRuleEditorPredicateCompoundType
                                ];

var CPRuleEditorCustomControlClass = @"CPRuleEditorCustomControlClass";

@implementation RuleDelegate : CPObject
{
    CPDictionary criteria;
}

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        var path = [[CPBundle mainBundle] pathForResource:@"criteria.plist"],
            request = [CPURLRequest requestWithURL:path],
            connection = [CPURLConnection connectionWithRequest:request delegate:self];
    }

    return self;
}

- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)dataString
{
    if (!dataString)
        return;

    var data = [[CPData alloc] initWithRawString:dataString];
    criteria = [CPPropertyListSerialization propertyListFromData:data format:CPPropertyListXMLFormat_v1_0];
}

/* When called, you should return the number of child items of the given criterion.  If criterion is nil, you should return the number of root criteria for the given row type. Implementation of this method is required. */

- (int)ruleEditor:(CPRuleEditor)editor numberOfChildrenForCriterion:(id)criterion withRowType:(CPRuleEditorRowType)rowType
{
    var childs;
    if (criterion)
        childs = [criterion objectForKey:@"criteria"];
    else
        childs = [criteria valueForKeyPath:(rowType == CPRuleEditorRowTypeSimple) ? @"rootChildren.subrows" : @"rootHeaders.subrows"];

    return (childs == NULL) ? 0 : [childs count];
}

/* When called, you should return the child of the given item at the given index.  If criterion is nil, return the root criterion for the given row type at the given index. Implementation of this method is required. */

- (id)ruleEditor:(CPRuleEditor)editor child:(int)index forCriterion:(id)criterion withRowType:(CPRuleEditorRowType)rowType
{
    var childs;

    if (criterion)
        childs = [criterion objectForKey:@"criteria"];
    else
        childs = [criteria valueForKeyPath:(rowType == CPRuleEditorRowTypeSimple) ? @"rootChildren.subrows" : @"rootHeaders.subrows"];

    return [childs objectAtIndex:index];

}

/*
 When called, you should return a value for the given criterion.  The value should be an instance of CPString, CPView, or CPMenuItem (1).  If the value is an CPView or CPMenuItem (1), you must ensure it is unique for every invocation of this method; that is, do not return a particular instance of CPView or CPMenuItem more than once.  Implementation of this method is required.
 (1) CPMenuItem: not implemented yet.
*/

- (id)ruleEditor:(CPRuleEditor)editor displayValueForCriterion:(id)criterion inRow:(int)row
{
    var custom_control_class = [criterion objectForKey:CPRuleEditorCustomControlClass];

    if (custom_control_class != nil)
    {
        var control = [criterion objectForKey:("control_"+row)];
        if (control == nil)
        {
            var custom_class = CPClassFromString(custom_control_class);
            control = [[custom_class alloc] initWithFrame:CGRectMake(0, 0, 100, 18)];
            [criterion setObject:control forKey:("control_"+row)];
        }

        return control;
    }

    return [criterion objectForKey:@"valeur"];
}

- (CPDictionary)ruleEditor:(CPRuleEditor)editor predicatePartsForCriterion:(id)criterion withDisplayValue:(id)value inRow:(int)row
{
    var predicatePartsForCriterion = @{};

    if ([editor rowTypeForRow:row] == CPRuleEditorRowTypeCompound)
    {
        var compound_type = [criterion objectForKey:CPRuleEditorPredicateCompoundType];
        if (compound_type != nil)
        	[predicatePartsForCriterion setObject:compound_type forKey:CPRuleEditorPredicateCompoundType];
        return predicatePartsForCriterion;
    }

    var count = CPRuleEditorPredicateKeys.length;
    for (var i = 0 ;i<count ;i++)
    {
        var key = CPRuleEditorPredicateKeys[i],
            predicatePart = nil ;

        if ([key isEqualToString:CPRuleEditorPredicateLeftExpression])
        {
            var str = [criterion objectForKey:key];
            if (str != nil) predicatePart = [CPExpression expressionForKeyPath:str];
        }
        else if ([key isEqualToString:CPRuleEditorPredicateRightExpression])
        {
            var transformedValue;
            if ([criterion objectForKey:CPRuleEditorCustomControlClass] != nil)
                transformedValue = ([value isKindOfClass:[CPView class]]) ? [value objectValue] : value;
            else
                transformedValue = [criterion objectForKey:key];
            predicatePart = [CPExpression expressionForConstantValue:transformedValue];
        }
        else if ([key isEqualToString:CPRuleEditorPredicateOperatorType] ||
        		 [key isEqualToString:CPRuleEditorPredicateCustomSelector] ||
        		 [key isEqualToString:CPRuleEditorPredicateOptions])
        {
            var value = [criterion objectForKey:key];
            if (value != nil) predicatePart = value;
        }
        else
            continue;

        if (predicatePart != nil)[predicatePartsForCriterion setObject:predicatePart forKey:key];
    }

    return predicatePartsForCriterion;
}


- (void)ruleEditorRowsDidChange:(CPNotification)notification
{
}

@end
