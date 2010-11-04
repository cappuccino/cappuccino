
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
    return [context objectForKey:_variable];
}

- (CPString)description
{
    return [CPString stringWithFormat:@"$%s", _variable];
}

- (CPExpression)_expressionWithSubstitutionVariables:(CPDictionary)variables
{
    var aconstant = [variables objectForKey:_variable];
      
    if (aconstant != nil)
        return [CPExpression expressionForConstantValue:aconstant];
   
    return self;
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

