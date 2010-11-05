
@import "CPExpression.j"

@implementation CPExpression_set : CPExpression
{
    CPExpression _left;
    CPExpression _right;
}

- (id)initWithType:(int)type left:(CPExpression)left right:(CPExpression)right
{
    [super initWithExpressionType:type];
    _left = left;
    _right = right;

    return self;
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
    if ([right isKindOfClass:[CPArray class]]) // Or we could do [[right objectEnumerator] allObjects]
        right = [CPSet setWithArray:right];
    else if ([right isKindOfClass:[CPDictionary class]])
        right = [CPSet setWithArray:[right allValues]];
    else if (![right isKindOfClass:[CPSet class]])
        [CPException raise:CPInvalidArgumentException reason:@"The right expression for a CP*SetExpressionType expression must evaluate to a CPArray, CPDictionary or CPSet"];

    var left = [_left expressionValueWithObject:object context:context];
    if (![left isKindOfClass:[CPSet class]])
        [CPException raise:CPInvalidArgumentException reason:@"The left expression for a CP*SetExpressionType expression must evaluate to a CPSet"];

    var result = [left copy];
    switch (_type)
    {
        case CPIntersectSetExpressionType : [result intersectSet:right];
        break;
        case CPUnionSetExpressionType     : [result unionSet:right];
        break;
        case CPMinusSetExpressionType     : [result minusSet:right];
        break;
        default:
    }

    return [CPExpression expressionForConstantValue:result];
}

- (CPExpression )_expressionWithSubstitutionVariables:(CPDictionary )variables
{
    // UNIMPLEMENTED
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

- (CPString)description
{
    var desc;
    switch (_type)
    {
        case CPIntersectSetExpressionType : desc = @" INTERSECT ";
        break;
        case CPUnionSetExpressionType : desc = @" UNION ";
        break;
        case CPMinusSetExpressionType : desc = @" MINUS ";
        break;
        default:
    }

    return [_left description] + desc + [_right description];
}

@end

var CPLeftExpressionKey = @"CPLeftExpression",
    CPRightExpressionKey = @"CPRightExpression",
    CPExpressionType = @"CPExpressionType";

@implementation CPExpression_set (CPCoding)

- (id)initWithCoder:(CPCoder)coder
{
    var left = [coder decodeObjectForKey:CPLeftExpressionKey],
        right = [coder decodeObjectForKey:CPRightExpressionKey],
        type = [coder decodeIntForKey:CPExpressionType];

    return [self initWithType:type left:left right:right];
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_left forKey:CPLeftExpressionKey];
    [coder encodeObject:_right forKey:CPRightExpressionKey];
    [coder encodeInt:_type forKey:CPExpressionType];
}

@end
