
@import "CPExpression.j"
@import <Foundation/CPArray.j>
@import <Foundation/CPString.j>

@implementation CPExpression_aggregate : CPExpression
{
    CPArray _aggregate;
}

- (id)initWithAggregate:(CPArray)collection
{
    [super initWithExpressionType:CPAggregateExpressionType];
    _aggregate = collection;
    return self;
}

+ (CPExpression)expressionForAggregate:(CPArray)collection
{
    return [[self alloc] initWithAggregate:collection];
}

- (id)initWithCoder:(CPCoder)coder
{
    var aggregate = [coder decodeObjectForKey:@"CPExpressionAggregate"];
    return [self initWithAggregate:aggregate];
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_aggregate forKey:@"CPExpressionAggregate"]; // subexpressions must be CPCoding compliant.
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
        
    if (object.isa != self.isa || [object expressionType] != [self expressionType] || ![[object collection] isEqual:[self collection]])
        return NO;
        
    return YES;
}

- (id)collection
{
    return _aggregate;
}

- (CPExpression)rightExpression
{
    if ([_aggregate count] > 0)
        return [_aggregate lastObject];

    return nil;
}

- (CPExpression)leftExpression
{
    if ([_aggregate count] > 0)
        return [_aggregate objectAtIndex:0];

    return nil;
}

- (id)expressionValueWithObject:(id)object context:(CPDictionary)context
{
    var eval_array = [CPArray array],
        collection  = [_aggregate objectEnumerator],
        exp;
        
    while (exp = [collection nextObject])
    {
        var eval = [exp expressionValueWithObject:object context:context];
        if (eval != nil)[eval_array addObject:eval];
    }

    return eval_array;
}

- (CPString)description
{
    var i,
        count = [_aggregate count],   
        result = "{";
   
    for (i = 0; i < count; i++)
        result = result + [CPString stringWithFormat:@"%s%s", [[_aggregate objectAtIndex:i] description], (i + 1 < count) ? @", " : @""];
    
    result = result + "}";
   
    return result;
}

- (CPExpression)_expressionWithSubstitutionVariables:(CPDictionary)variables
{
    var subst_array = [CPArray array],
        count = [_aggregate count],
        i;
      
    for (i = 0; i < count; i++)
        [subst_array addObject:[[_aggregate objectAtIndex:i] _expressionWithSubstitutionVariables:variables]];

    return [CPExpression expressionForAggregate:subst_array];
}

@end
