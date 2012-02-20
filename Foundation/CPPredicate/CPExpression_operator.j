
@import "CPExpression.j"
@import <Foundation/CPArray.j>
@import <Foundation/CPString.j>
@import <Foundation/CPDictionary.j>

var CPExpressionOperatorNegate = "CPExpressionOperatorNegate";
var CPExpressionOperatorAdd = "CPExpressionOperatorAdd";
var CPExpressionOperatorSubtract = "CPExpressionOperatorSubtract";
var CPExpressionOperatorMultiply = "CPExpressionOperatorMultiply";
var CPExpressionOperatorDivide = "CPExpressionOperatorDivide";
var CPExpressionOperatorExp = "CPExpressionOperatorExp";
var CPExpressionOperatorAssign = "CPExpressionOperatorAssign";
var CPExpressionOperatorKeypath = "CPExpressionOperatorKeypath";
var CPExpressionOperatorIndex = "CPExpressionOperatorIndex";
var CPExpressionOperatorIndexFirst = "CPExpressionOperatorIndexFirst";
var CPExpressionOperatorIndexLast = "CPExpressionOperatorIndexLast";
var CPExpressionOperatorIndexSize = "CPExpressionOperatorIndexSize";

@implementation CPExpression_operator : CPExpression
{
    int     _operator;
    CPArray _arguments;
}

- (id)initWithOperator:(int)operator arguments:(CPArray)arguments
{
    _operator = operator;
    _arguments = arguments;
    return self;
}

+ (CPExpression)expressionForOperator:(CPExpressionOperator)operator arguments:(CPArray)arguments
{
    return [self initWithOperator:operator arguments:arguments];
}

- (CPArray)arguments
{
    return _arguments;
}

- (CPString)description
{
    var result = [CPString string],
        args = [CPArray array],
        count = [_arguments count],
        i;
    
    for (i = 0; i < count; i++)
    {
        var check = [_arguments objectAtIndex:i],
            precedence = [check description];
        
        if ([check isKindOfClass:[CPExpression_operator class]])
            precedence = [CPString stringWithFormat:@"(%@)", precedence];
        
        [args addObject:precedence];
    }
    
    switch (_operator)
    {
     case CPExpressionOperatorNegate : 
         result = result + [CPString stringWithFormat:@"-%@", [args objectAtIndex:0]];
         break;
     case CPExpressionOperatorAdd : 
         result = result + [CPString stringWithFormat:@"%@ + %@", [args objectAtIndex:0], [args objectAtIndex:1]];
         break;
     case CPExpressionOperatorSubtract : 
         result = result + [CPString stringWithFormat:@"%@ - %@", [args objectAtIndex:0], [args objectAtIndex:1]];
         break;
     case CPExpressionOperatorMultiply : 
         result = result + [CPString stringWithFormat:@"%@ * %@", [args objectAtIndex:0], [args objectAtIndex:1]];
         break;
     case CPExpressionOperatorDivide : 
         result = result + [CPString stringWithFormat:@"%@ / %@", [args objectAtIndex:0], [args objectAtIndex:1]];
         break;
     case CPExpressionOperatorExp : 
         result = result + [CPString stringWithFormat:@"%@ ** %@", [args objectAtIndex:0], [args objectAtIndex:1]];
         break;
     case CPExpressionOperatorAssign : 
         result = result + [CPString stringWithFormat:@"%@ := %@", [args objectAtIndex:0], [args objectAtIndex:1]];
         break;
     case CPExpressionOperatorKeypath : 
         result = result + [CPString stringWithFormat:@"%@.%@", [args objectAtIndex:0], [args objectAtIndex:1]];
         break;
     case CPExpressionOperatorIndex : 
         result = result + [CPString stringWithFormat:@"%@[%@]", [args objectAtIndex:0], [args objectAtIndex:1]];
         break;
     case CPExpressionOperatorIndexFirst : 
         result = result + [CPString stringWithFormat:@"%@[FIRST]", [args objectAtIndex:0]];
         break;
     case CPExpressionOperatorIndexLast : 
         result = result + [CPString stringWithFormat:@"%@[LAST]", [args objectAtIndex:0]];
         break;
     case CPExpressionOperatorIndexSize : 
         result = result + [CPString stringWithFormat:@"%@[SIZE]", [args objectAtIndex:0]];
         break;
    }
    
    return result;
}

- (CPExpression)_expressionWithSubstitutionVariables:(CPDictionary)variables
{
    var array = [CPArray array],
        count = [_arguments count],
        i;
    
    for (i = 0; i < count; i++)
        [array addObject:[[_arguments objectAtIndex:i] _expressionWithSubstitutionVariables:variables]];
    
    return [CPExpression_operator expressionForOperator:_operator arguments:array];
}

@end

