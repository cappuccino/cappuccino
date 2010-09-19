
@import "CPExpression.j"
@import <Foundation/CPString.j>
@import <Foundation/CPKeyValueCoding.j>

@implementation CPExpression_keypath : CPExpression
{
    CPString _keyPath;
}

- (id)initWithKeyPath:(CPString)keyPath
{
    [super initWithExpressionType:CPKeyPathExpressionType];
    _keyPath = keyPath ;
    
    return self;
}

- (id)initWithCoder:(CPCoder)coder
{
    var keyPath = [coder decodeObjectForKey:@"CPExpressionKeyPath"];
    
    return [self initWithKeyPath:keyPath];
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_keyPath forKey:@"CPExpressionKeyPath"];
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
        
    if (object.isa != self.isa || [object expressionType] != [self expressionType] || ![[object keyPath] isEqualToString:[self keyPath]])
        return NO;
        
    return YES;
}

- (CPString)keyPath
{
    return _keyPath;
}

- (id)expressionValueWithObject:object context:(CPDictionary)context
{
    return [object valueForKeyPath:_keyPath];
}

- (CPExpression)_expressionWithSubstitutionVariables:(CPDictionary)variables
{
    return self;
}

- (CPString)description
{
    return _keyPath;
}

@end

