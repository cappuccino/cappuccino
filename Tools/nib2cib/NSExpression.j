@import <Foundation/CPExpression.j>

@implementation NSKeyPathExpression : CPExpression_keypath
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPExpression_keypath class];
}

@end

@implementation CPKeyPathSpecifierExpression : CPExpression_constant
{
}

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var keyPath = [aCoder decodeObjectForKey:@"NSKeyPath"];
    self = [super initWithValue:keyPath];
    return self;
}

@end

@implementation NSKeyPathSpecifierExpression : CPKeyPathSpecifierExpression
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPExpression_constant class];
}

@end

@implementation CPExpression_constant (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var value = [aCoder decodeObjectForKey:@"NSConstantValue"];    
    return [self initWithValue:value];
}

@end

@implementation NSConstantValueExpression : CPExpression_constant
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPExpression_constant class];
}

@end

@implementation CPExpression_function (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{   
    var type = [aCoder decodeIntForKey:@"NSExpressionType"],
        operand = [aCoder decodeObjectForKey:@"NSOperand"],
        selector = CPSelectorFromString([aCoder decodeObjectForKey:@"NSSelectorName"]),
        args = [aCoder decodeObjectForKey:@"NSArguments"];
    
    return [self initWithTarget:operand selector:selector arguments:args type:type];
}

@end

@implementation NSFunctionExpression : CPExpression_function
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPExpression_function class];
}

@end

@implementation CPExpression_set (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var type = [aCoder decodeIntForKey:@"NSExpressionType"],
        left = [aCoder decodeObjectForKey:@"NSLeftExpression"],
        right = [aCoder decodeObjectForKey:@"NSRightExpression"];
    
    return [self initWithType:type left:left right:right];
}

@end

@implementation NSSetExpression : CPExpression_set
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPExpression_set class];
}

@end

@implementation NSSelfExpression : CPExpression_self
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [super init];
}

- (Class)classForKeyedArchiver
{
    return [CPExpression_self class];
}

@end

@implementation CPExpression_variable (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var variable = [aCoder decodeObjectForKey:@"NSVariable"];
    return [self initWithVariable:variable];
}

@end

@implementation NSVariableExpression : CPExpression_variable
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPExpression_variable class];
}

@end

@implementation CPExpression_aggregate (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    var collection = [aCoder decodeObjectForKey:@"NSCollection"];
    return [self initWithAggregate:collection];
}

@end

@implementation NSAggregateExpression : CPExpression_aggregate
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPExpression_aggregate class];
}

@end
