
@import "CPExpression.j"
@import <Foundation/CPString.j>
@import <Foundation/CPDictionary.j>
@import <Foundation/CPCoder.j>

@implementation CPExpression_self : CPExpression
{
}

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
    return (_type == CPEvaluatedObjectExpressionType);
}

- (id)expressionValueWithObject:(id)object context:(CPDictionary)context
{
    return object;
}

- (CPString)description
{
    return @"SELF";
}

@end

