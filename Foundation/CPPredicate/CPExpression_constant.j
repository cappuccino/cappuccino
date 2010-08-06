
@import "CPExpression.j"
@import <Foundation/CPDictionary.j>

@implementation CPExpression_constant : CPExpression
{
    id _value;
}

- (id)initWithValue:(id)value
{
    [super initWithExpressionType:CPConstantValueExpressionType];
    _value = value;
    
    return self;
}

- (id)initWithCoder:(CPCoder)coder
{
    var value = [coder decodeObjectForKey:@"CPExpressionConstantValue"];
    
    return [self initWithValue:value];
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_value forKey:@"CPExpressionConstantValue"];
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
        
    if (object.isa != self.isa || [object expressionType] != [self expressionType] || ![[object constantValue] isEqual:[self constantValue]])
        return NO;
        
    return YES;
}

- (id)constantValue
{
    return _value;
}

- (id)expressionValueWithObject:object context:(CPDictionary)context
{
    return _value;
}

- (CPExpression)_expressionWithSubstitutionVariables:(CPDictionary)variables
{
    return self;
}

- (CPString)description
{
    if ([_value isKindOfClass:[CPString class]])
        return @"\"" + _value + @"\"";

    return [_value description];
}

@end

