
@import "CPExpression.j"
@import <Foundation/CPString.j>
@import <Foundation/CPKeyValueCoding.j>
@import "CPExpression_function.j"

@implementation CPExpression_keypath : CPExpression_function
{
}

- (id)initWithKeyPath:(CPString)keyPath
{
    return [self initWithOperand:[CPExpression expressionForEvaluatedObject] andKeyPath:keyPath];
}

- (id)initWithOperand:(CPExpression)operand andKeyPath:(CPString)keyPath
{
    var arg = [CPExpression expressionForConstantValue:keyPath];
    // Cocoa: if it's a direct path selector is valueForKey:
    self = [super initWithTarget:operand selector:@selector(valueForKeyPath:) arguments:[arg]];

    return self;
}

- (CPExpression)pathExpression
{
    return [[self arguments] objectAtIndex:0];
}

- (CPString)keyPath
{
    return [[self pathExpression] constantValue];
}

- (CPString)description
{
    return [self keyPath];
}

@end

