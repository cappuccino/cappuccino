
@import "CPExpression.j"
@import <Foundation/CPString.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPCoder.j>

@implementation CPExpression_self : CPExpression{}

- (id)init
{
    [super initWithExpressionType:CPEvaluatedObjectExpressionType];
    
    return self;
}

- (id)initWithCoder:(CPCoder)coder
{
    return [self init];
}

- (void)encodeWithCoder:(CPCoder)coder
{
}

- (BOOL)isEqual:(id)object
{
    return (object == self);
}

- (id)expressionValueWithObject:object context:(CPDictionary)context
{
    return object;
}

- (CPExpression)_expressionWithSubstitutionVariables:(CPDictionary)variables
{
    return self;
}

- (CPString)description
{
    return @"SELF";
}

@end

