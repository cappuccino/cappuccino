
@import "CPExpression.j"

@implementation CPExpression_unionset : CPExpression

- (id)initWithLeft:(CPExpression)left right:(CPExpression)right
{
    [super initWithExpressionType:CPUnionSetExpressionType];
    _left = left;
    _right = right;

    return self;
}

- (id)initWithCoder:(CPCoder)coder
{
    var left = [coder decodeObjectForKey:@"CPExpressionUnionSetLeftExpression"],
        right = [coder decodeObjectForKey:@"CPExpressionUnionSetRightExpression"];

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

    if (object.isa != self.isa
        || [object expressionType] != [self expressionType]
        || ![[object leftExpression] isEqual:[self leftExpression]]
        || ![[object rightExpression] isEqual:[self rightExpression]])
        return NO;

    return YES;
}

- (id)expressionValueWithObject:object context:(CPDictionary )context
{
    var right = [_right expressionValueWithObject:object context:context];
    if (![right respondsToSelector: @selector(objectEnumerator)])
        [CPException raise:CPInvalidArgumentException reason:@"The right expression for a CPIntersectSetExpressionType expression must be either a CPArray, CPDictionary or CPSet"];

    var left = [_left expressionValueWithObject:object context:context];
    if (![left isKindOfClass:[CPSet set]])
        [CPException raise:CPInvalidArgumentException reason:@"The left expression for a CPIntersectSetExpressionType expression must a CPSet"];

    var unionset = [CPSet setWithSet:left],
        e = [right objectEnumerator],
        item;

    while (item = [e nextObject])
        [unionset addObject:item];

    return [CPExpression expressionForConstantValue:unionset];
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
    return [_left description] +" UNION "+ [_right description];
}

@end

