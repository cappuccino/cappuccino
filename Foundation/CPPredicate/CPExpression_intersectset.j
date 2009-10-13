
@import "CPExpression.j"

@implementation CPExpression_intersectset : CPExpression
{
    CPExpression _left;
    CPExpression _right;
}

- (id)initWithLeft:(CPExpression)left right:(CPExpression)right
{
    [super initWithExpressionType:CPIntersectSetExpressionType];
    _left = left ;
    _right = right;
    
    return self;
}

- (id)initWithCoder:(CPCoder)coder
{
    var left = [coder decodeObjectForKey:@"CPExpressionUnionSetLeftExpression"];
    var right = [coder decodeObjectForKey:@"CPExpressionUnionSetRightExpression"];
    
    return [self initWithLeft:left right:right];
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_left forKey:@"CPExpressionUnionSetLeftExpression"];
    [coder encodeObject:_right forKey:@"CPExpressionUnionSetRightExpression"];
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
        
    if (object.isa != self.isa || [object expressionType] != [self expressionType] || ![[object leftExpression] isEqual:[self leftExpression]] || ![[object rightExpression] isEqual:[self rightExpression]])
        return NO;
        
    return YES;
}

- (id)expressionValueWithObject:object context:(CPDictionary)context
{   
    var right = [_right expressionValueWithObject:object context:context];  
    if (![right respondsToSelector: @selector(objectEnumerator)])
        [CPException raise:CPInvalidArgumentException reason:@"The right expression for a CPIntersectSetExpressionType expression must be either a CPArray, CPDictionary or CPSet"];

    var left = [_left expressionValueWithObject:object context:context];    
    if (![left isKindOfClass:[CPSet set]])
        [CPException raise:CPInvalidArgumentException reason:@"The left expression for a CPIntersectSetExpressionType expression must a CPSet"];

    var set = [CPSet setWithSet:left],
        e = [right objectEnumerator],
        item;
        
    while (item = [e nextObject])
        if ([left containsObject:item])
            [set addObject:item];

    return [CPExpression expressionForConstantValue:set];
}

- (CPExpression )_expressionWithSubstitutionVariables:(CPDictionary )variables
{
    return self;
}

- (CPExpression)leftExpression
{
    return _left;
}

- (CPExpression)rightExpression
{
    return _right;
}

- (CPString )description
{
    return [_left description] +" INTERSECT "+ [_right description];
}

@end

