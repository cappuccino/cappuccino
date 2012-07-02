@import <Foundation/CPExpression.j>

@implementation NSKeyPathExpression : _CPKeyPathExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPKeyPathExpression class];
}

@end

@implementation _CPKeyPathSpecifierExpression : _CPConstantValueExpression
{
}

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var keyPath = [aCoder decodeObjectForKey:@"NSKeyPath"];
    self = [super initWithValue:keyPath];
    return self;
}

@end

@implementation NSKeyPathSpecifierExpression : _CPKeyPathSpecifierExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPConstantValueExpression class];
}

@end

@implementation _CPConstantValueExpression (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var value = [aCoder decodeObjectForKey:@"NSConstantValue"];
    return [self initWithValue:value];
}

@end

@implementation NSConstantValueExpression : _CPConstantValueExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPConstantValueExpression class];
}

@end

@implementation _CPFunctionExpression (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var type = [aCoder decodeIntForKey:@"NSExpressionType"],
        operand = [aCoder decodeObjectForKey:@"NSOperand"],
        selector = CPSelectorFromString([aCoder decodeObjectForKey:@"NSSelectorName"]),
        args = [aCoder decodeObjectForKey:@"NSArguments"];

    return [self initWithTarget:operand selector:selector arguments:args type:type];
}

@end

@implementation NSFunctionExpression : _CPFunctionExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPFunctionExpression class];
}

@end

@implementation _CPSetExpression (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var type = [aCoder decodeIntForKey:@"NSExpressionType"],
        left = [aCoder decodeObjectForKey:@"NSLeftExpression"],
        right = [aCoder decodeObjectForKey:@"NSRightExpression"];

    return [self initWithType:type left:left right:right];
}

@end

@implementation NSSetExpression : _CPSetExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPSetExpression class];
}

@end

@implementation NSSelfExpression : _CPSelfExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [super init];
}

- (Class)classForKeyedArchiver
{
    return [_CPSelfExpression class];
}

@end

@implementation _CPVariableExpression (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var variable = [aCoder decodeObjectForKey:@"NSVariable"];
    return [self initWithVariable:variable];
}

@end

@implementation NSVariableExpression : _CPVariableExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPVariableExpression class];
}

@end

@implementation _CPAggregateExpression (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var collection = [aCoder decodeObjectForKey:@"NSCollection"];
    return [self initWithAggregate:collection];
}

@end

@implementation NSAggregateExpression : _CPAggregateExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPAggregateExpression class];
}

@end
