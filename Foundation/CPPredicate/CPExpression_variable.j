
@import "CPExpression.j"
@import <Foundation/CPString.j>
@import <Foundation/CPDictionary.j>

@implementation CPExpression_variable :  CPExpression
{
    CPString _variable;
}

- (id)initWithVariable:(CPString)variable
{
    [super initWithExpressionType:CPVariableExpressionType];
    _variable = [variable copy];

    return self;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;

    if (object.isa != self.isa || [object expressionType] != [self expressionType] || ![[object variable] isEqualToString:[self variable]])
        return NO;

    return YES;
}

- (CPString)variable
{
    return _variable;
}

- (id)expressionValueWithObject:object context:(CPDictionary)context
{
    var expression = [self _expressionWithSubstitutionVariables:context];
        
    return [expression expressionValueWithObject:object context:context];    
}

- (CPString)description
{
    return [CPString stringWithFormat:@"$%s", _variable];
}

- (CPExpression)_expressionWithSubstitutionVariables:(CPDictionary)variables
{
    var value = [variables objectForKey:_variable];
    if (value == nil)
        [CPException raise:CPInvalidArgumentException reason:@"Can't get value for '" + _variable + "' in bindings" + variables];
        
    if ([value isKindOfClass:[CPExpression class]])
        return value;
        
    return [CPExpression expressionForConstantValue:value];
}

@end

var CPVariableKey = @"CPVariable";

@implementation CPExpression_variable (CPCoding)

- (id)initWithCoder:(CPCoder)coder
{
    var variable = [coder decodeObjectForKey:CPVariableKey];
    return [self initWithVariable:variable];
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_variable forKey:CPVariableKey];
}

@end

