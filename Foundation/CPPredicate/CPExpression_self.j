
@import "CPExpression.j"
@import "CPString.j"
@import "CPDictionary.j"

var evaluatedObject = nil;
@implementation CPExpression_self : CPExpression
{
}

+ (id)evaluatedObject
{
    if (evaluatedObject == nil)
        evaluatedObject = [CPExpression_self new];

    return evaluatedObject;
}

- (id)init
{
    [super initWithExpressionType:CPEvaluatedObjectExpressionType];

    return self;
}

- (id)initWithCoder:(CPCoder)coder
{
    return [CPExpression_self evaluatedObject];
}

- (void)encodeWithCoder:(CPCoder)coder
{
}

- (BOOL)isEqual:(id)object
{
    return (object === self);
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

