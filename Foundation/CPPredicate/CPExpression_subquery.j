@import "CPExpression.j"

@implementation CPExpression_subquery : CPExpression
{
    CPExpression _collection;
    CPExpression _variableExpression;
    CPPredicate  _subpredicate;
}

- (id)initWithExpression:(CPExpression)collection usingIteratorVariable:(CPString)variable predicate:(CPPredicate)subpredicate
{
    [super initWithExpressionType:CPSubqueryExpressionType];
    
    _subpredicate = subpredicate;
    _collection = collection;
    _variableExpression = [CPExpression expressionForVariable:variable];
    
    return self;
}

- (id)expressionValueWithObject:(id)object context:(id)context
{
    var collection = [_collection expressionValueWithObject:object context:context],
        count = [collection count],
        result = [CPArray array],
        
        bindings = [CPDictionary dictionaryWithObject:[CPExpression expressionForEvaluatedObject] forKey:[self variable]];
    
    for (var i = 0; i < count; i++)
    {
        var item = [collection objectAtIndex:i];
        if ([_subpredicate evaluateWithObject:item substitutionVariables:bindings])
            [result addObject:item];
    }
    
    return result;
}

- (BOOL)isEqual:(id)object;
{
    if (self === object)
        return YES;
    
    if (![_collection isEqual:[object collection]] || ![_subpredicate isEqual:[object predicate]])
        return NO;
    
    return YES;
}

- (id)collection
{
    return _collection;
}

- (id)copy
{
    return [[CPExpression_subquery alloc] initWithExpression:[_collection copy] usingIteratorExpression:[_variableExpression copy] predicate:[_subpredicate copy]];
}

- (id)predicate
{
    return _subpredicate;
}

- (id)predicateFormat
{
    return @"SUBQUERY(" + [_collection description] + ", " + [_variableExpression description] + ", " + [_subpredicate predicateFormat] + ")";
}

- (id)variable
{
    return [_variableExpression variable];
}

- (id)variableExpression
{
    return _variableExpression;
}
@end

var CPExpressionKey = @"CPExpression",
    CPSubpredicateKey = @"CPSubpredicate",
    CPVariableKey = @"CPVariable";
    
@implementation CPExpression_subquery (CPCoding)

- (id)initWithCoder:(CPCoder)coder
{
    var collection = [coder decodeObjectForKey:CPExpressionKey],    
        subpredicate = [coder decodeObjectForKey:CPSubpredicateKey],
        variable = [coder decodeObjectForKey:CPVariableKey];
    
    return [self initWithExpression:collection usingIteratorVariable:variable predicate:subpredicate];
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_collection forKey:CPExpressionKey];
    [coder encodeObject:_subpredicate forKey:CPSubpredicateKey];
    [coder encodeObject:[variableExpression variable] forKey:CPVariableKey];
}

@end