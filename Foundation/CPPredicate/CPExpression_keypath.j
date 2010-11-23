
@import "CPExpression.j"
@import "CPExpression_function.j"
@import "CPString.j"
@import "CPKeyValueCoding.j"

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
    // Cocoa: if it's a direct path selector use valueForKey:
    self = [super initWithTarget:operand selector:@selector(valueForKeyPath:) arguments:[arg] type:CPKeyPathExpressionType];

    return self;
}

- (BOOL)isEqual:(id)object
{
    if (object === self)
        return YES;

    return ([object keyPath] == [self keyPath]); // If it appears that parsing generates nested keypaths with different targets and same keyPath, comparing -keyPath won't work.
}

- (CPExpression)pathExpression
{
    return [[self arguments] objectAtIndex:0];
}

- (CPString)keyPath
{
    return [[self pathExpression] keyPath];
}

- (CPString)description
{
    var result = "";
    if ([_operand expressionType] != CPEvaluatedObjectExpressionType)
        result += [_operand description] + ".";
    result += [self keyPath];

    return result;
}

@end

@implementation CPExpression_constant (KeyPath)

- (CPString)keyPath
{
    return [self constantValue];
}

@end
