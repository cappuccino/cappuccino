
@import "CPExpression.j"
@import "CPExpression_variable.j"
@import <Foundation/CPString.j>


@implementation CPExpression_assignment: CPExpression
{
    CPExpression_variable   _assignmentVariable;
    CPExpression            _subexpression;
}

- (id)initWithAssignmentVariable:(CPString)variable expression:(CPExpression)expression
{
    _assignmentVariable = [CPExpression expressionForVariable:variable];
    _subexpression = expression;
   
    return self;
}

- (id)initWithAssignmentExpression:(CPExpression)variableExpression expression:(CPExpression)expression
{
    _assignmentVariable = variableExpression;
    _subexpression = expression;
   
    return self;
}

- (id)initWithCoder:(CPCoder)coder
{
    var variable = [coder decodeObjectForKey:@"CPExpressionAssignmentVariable"];
    var expression = [coder decodeObjectForKey:@"CPExpressionAssignmentExpression"];
    
    return [self initWithAssignmentVariable:variable expression:expression];
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_assignmentVariable forKey:@"CPExpressionAssignmentVariable"];
    [coder encodeObject:_subexpression forKey:@"CPExpressionAssignmentExpression"];
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
        
    if (object.isa != self.isa || [object expressionType] != [self expressionType] || ![[object subexpression] isEqual:[self subexpression]] || ![[object variable] isEqualToString:[self variable]])
        return NO;
        
    return YES;
}

- (CPExpression)assignmentVariable
{
    return _assignmentVariable;
}

- (CPExpression)subexpression
{
    return _subexpression;
}

- (CPString)variable
{
    return [_assignmentVariable variable];
}

- (CPString)description
{
    var pretty = [_expression description];
   
    if ([_subexpression isKindOfClass:[CPExpression_operator class]])
        pretty = [CPString stringWithFormat:@"(%@)", pretty];
    
    return [CPString stringWithFormat:@"%@ := %@", [self variable], pretty];
}

- (id)expressionValueWithObject:(id)object context:(id)context
{
    // UNIMPLEMENTED
    return nil;
}

- (CPExpression)_expressionWithSubstitutionVariables:(CPDictionary)variables
{
    // UNIMPLEMENTED
    return nil;
}

@end

