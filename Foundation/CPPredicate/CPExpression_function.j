
@import "CPExpression.j"
@import "CPString.j"
@import "CPArray.j"
@import "CPDictionary.j"

@implementation CPExpression_function : CPExpression
{
    CPExpression    _operand;
    SEL             _selector;
    CPArray         _arguments;
    int             _argc;
    int             _maxargs;
}

- (id)initWithSelector:(SEL)aSelector arguments:(CPArray)parameters
{
    var target = [CPPredicateUtilities class];
    if (![target respondsToSelector:aSelector])
        [CPException raise:CPInvalidArgumentException reason:@"Unknown function implementation: " + aSelector];

    var operand = [CPExpression expressionForConstantValue:target];
    return [self initWithTarget:operand selector:aSelector arguments:parameters];
}

- (id)initWithTarget:(CPExpression)operand selector:(SEL)aSelector arguments:(CPArray)parameters
{
    return [self initWithTarget:operand selector:aSelector arguments:parameters type:CPFunctionExpressionType];
}

- (id)initWithTarget:(CPExpression)operand selector:(SEL)aSelector arguments:(CPArray)parameters type:(int)type
{
    [super initWithExpressionType:type];

// Cocoa doc: "This method throws an exception immediately if the selector is unknown"
// but operand's value (the target) may be resolved only at runtime.
    _selector = aSelector;
    _operand = operand;
    _arguments = parameters;
    _argc = [parameters count];
    _maxargs = [[CPStringFromSelector(_selector) componentsSeparatedByString:@":"] count] - 1;

    return self;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;

    if (object.isa != self.isa || [object expressionType] != [self expressionType] || ![[object _function] isEqualToString:[self _function]] || ![[object operand] isEqual:[self operand]] || ![[object arguments] isEqualToArray:[self arguments]])
        return NO;

    return YES;
}

- (CPString)_function // OBJJ preprocessor does not like function as a method
{
    return CPStringFromSelector(_selector);
}

- (CPString)function
{
    return [self _function];
}

- (CPArray)arguments
{
    return _arguments;
}

- (CPExpression)operand
{
    return _operand;
}

- (id)expressionValueWithObject:(id)object context:(CPDictionary)context
{
    var target = [_operand expressionValueWithObject:object context:context],
        objj_args = [target, _selector],
        i;

    for (i = 0; i < _argc; i++)
    {
        var arg = [_arguments[i] expressionValueWithObject:object context:context];
        objj_args.push(arg);
    }

    // If we have too much arguments, concatenate remaining args on the last one.
    if (_argc > _maxargs)
    {
        var r = MAX(_maxargs + 1, 2);
        objj_args = objj_args.slice(0, r).concat([objj_args.slice(r)]);
    }

    return objj_msgSend.apply(this, objj_args);
}

- (CPString)description
{
    var result = "";
    if ([_operand isEqual:[CPExpression expressionForConstantValue:[CPPredicateUtilities class]]])
        result += CPStringFromSelector(_selector) + "(";
    else
    {
        result += "FUNCTION(";
        result += _operand ? [_operand description] + ", ":"";
        result += _selector ? CPStringFromSelector(_selector) + ", ":"";
    }

    for (var i = 0; i < _argc; i++)
        result = result + [_arguments[i] description] + ((i + 1 < _argc) ? ", " : "");

    result += ")";

    return result ;
}

- (CPExpression)_expressionWithSubstitutionVariables:(CPDictionary)variables
{
    var operand = [[self operand] _expressionWithSubstitutionVariables:variables],
        args = [CPArray array];

    for (var i = 0; i < _argc; i++)
        [args addObject:[_arguments[i] _expressionWithSubstitutionVariables:variables]];

    return [CPExpression expressionForFunction:operand selectorName:[self _function] arguments:args];
}

@end

var CPSelectorNameKey = @"CPSelectorName",
    CPArgumentsKey = @"CPArguments",
    CPOperandKey = @"CPOperand",
    CPExpressionTypeKey = @"CPExpressionType";

@implementation CPExpression_function (CPCoding)

- (id)initWithCoder:(CPCoder)coder
{
    var type = [coder decodeIntForKey:CPExpressionTypeKey],
        operand = [coder decodeObjectForKey:CPOperandKey],
        selector = CPSelectorFromString([coder decodeObjectForKey:CPSelectorNameKey]),
        parameters = [coder decodeObjectForKey:CPArgumentsKey];

    return [self initWithTarget:operand selector:selector arguments:parameters type:type];
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:[self _function] forKey:CPSelectorNameKey];
    [coder encodeObject:_arguments forKey:CPArgumentsKey];
    [coder encodeObject:_operand forKey:CPOperandKey];
    [coder encodeInt:_type forKey:CPExpressionTypeKey];
}

@end

// Built-in functions
@implementation CPPredicateUtilities : CPObject
{
}

+ (float)sum:(CPArray)parameters
{
    var sum = 0,
        count = parameters.length;

    while (count--)
        sum += parameters[count];

    return sum;
}

+ (float)count:(CPArray)parameters
{
    return [parameters count];
}

+ (float)min:(CPArray)parameters
{
    return parameters.sort()[0];
}

+ (float)max:(CPArray)parameters
{
    return parameters.sort()[parameters.length - 1];
}

+ (float)average:(CPArray)parameters
{
    return [self sum:parameters] / parameters.length;
}

+ (id)first:(CPArray)parameters
{
    return parameters[0];
}

+ (id)last:(CPArray)parameters
{
    return parameters[parameters.length - 1];
}

+ (id)fromObject:(id)object index:(id)anIndex
{
    if ([object isKindOfClass:[CPDictionary class]])
        return [object objectForKey:anIndex];
    else ([object isKindOfClass:[CPArray class]])
        return [object objectAtIndex:anIndex];

    [CPException raise:CPInvalidArgumentException reason:@"object[#] requires a CPDictionary or CPArray"];
}

+ (float)add:(int)n to:(int)m
{
    return n + m;
}

+ (float)from:(int)n substract:(int)m
{
    return n - m;
}

+ (float)multiply:(float)n by:(int)m
{
    return n * m;
}

+ (float)divide:(float)n by:(float)m
{
    return n / m;
}

+ (float)sqrt:(float)n
{
    return SQRT(n);
}

+ (float)raise:(float)num to:(int)power
{
    return POW(num, power);
}

+ (float)abs:(float)num
{
    return ABS(num);
}

+ (CPDate)now
{
    return [CPDate date];
}

+ (float)ln:(float)num
{
    return LN10(num);
}

+ (float)exp:(float)num
{
    return EXP(num);
}

+ (float)ceiling:(float)num
{
    return CEIL(num);
}

+ (int)random:(int)num
{
    return ROUND(RAND() * num);
}

+ (int)modulus:(int)n by:(int)m
{
    return n % m;
}

+ (float)chs:(int)num
{
    return -num;
}

@end

