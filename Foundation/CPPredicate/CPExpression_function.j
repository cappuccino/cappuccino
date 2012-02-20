
@import "CPExpression.j"
@import <Foundation/CPString.j>
@import <Foundation/CPArray.j>
@import <Foundation/CPDictionary.j>

@implementation CPExpression_function : CPExpression
{
    CPExpression    _operand;
    SEL             _selector;
    CPArray         _arguments;
    int             _argc;
}

- (id)initWithSelector:(SEL)aselector arguments:(CPArray)parameters
{
    [super initWithExpressionType:CPFunctionExpressionType];  
     
    if (![self respondsToSelector:aselector])
       [CPException raise: CPInvalidArgumentException reason:@"Unknown function implementation: " + aselector];
     
    _selector = aselector;
    _operand = nil;
    _arguments = parameters;
    _argc = [parameters count];
    
    return self;
}

- (id)initWithTarget:(CPExpression)targetExpression selector:(SEL)aselector arguments:(CPArray)parameters
{
    [super initWithExpressionType:CPFunctionExpressionType];  
    
    var target = [targetExpression expressionValueWithObject:object context:context];
    if (![target respondsToSelector:aselector])
       [CPException raise: CPInvalidArgumentException reason:@"Unknown function implementation: " + aselector];
     
    _selector = aselector;
    _operand = targetExpression;
    _arguments = parameters;
    _argc = [parameters count];
    
    return self;
}

- (id)initWithCoder:(CPCoder)coder
{
    var selector = CPSelectorFromString([coder decodeObjectForKey:@"CPExpressionFunctionName"]);
    var arguments = [coder decodeObjectForKey:@"CPExpressionFunctionArguments"];
    
    return [self initWithSelector:selector arguments:arguments];
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:[self _function] forKey:@"CPExpressionFunctionName"];
    [coder encodeObject:_arguments forKey:@"CPExpressionArguments"];
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
    var eval_args = [CPArray array],
        i;

    for (i = 0; i < _argc; i++)
    {
      var arg = [[_arguments objectAtIndex:i] expressionValueWithObject:object context:context];
      if (arg != nil)
        [eval_args addObject:arg];
    }

    var target = (_operand == nil) ? self : [_operand expressionValueWithObject:object context:context];
    return [target performSelector:_selector withObject:eval_args];
}

- (CPString)description
{  
    var result =  [CPString stringWithFormat:@"%@ %s(", [_operand description], [self _function]],
        i;
  
    for (i = 0; i < _argc; i++)
        result = result + [_arguments objectAtIndex:i] + (i+1<_argc) ? ", " : "";
    
    result = result + ")";
   
    return result ;
}


- (CPExpression)_expressionWithSubstitutionVariables:(CPDictionary)variables
{
    var array = [CPArray array],
        i;
    
    for (i = 0; i < _argc; i++)
        [array addObject:[[_arguments objectAtIndex:i] _expressionWithSubstitutionVariables:variables]];

    return [CPExpression expressionForFunction:[self operand] selectorName:[self _function] arguments:array];
}

- (CPNumber)sum:(CPArray)parameters
{
    if (_argc < 1)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    var i,
        sum = 0.0;
    
    for (i = 0; i < _argc; i++)
        sum += [[parameters objectAtIndex:i] doubleValue];
    
    return [CPNumber numberWithDouble: sum];
}

- (CPNumber)count:(CPArray)parameters
{
    if (_argc < 1)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    return [CPNumber numberWithUnsignedInt: [[parameters objectAtIndex:0] count]];
}

- (CPNumber)min:(CPArray)parameters
{
    if (_argc < 1)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    return MIN([parameters objectAtIndex:0],[parameters objectAtIndex:1]);
}

- (CPNumber)max:(CPArray)parameters
{
    if (_argc < 1)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    return MAX([parameters objectAtIndex:0],[parameters objectAtIndex:1]);
}

- (CPNumber)average:(CPArray)parameters 
{
    if (_argc < 1)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    var i,
        sum = 0.0;
    
    for (i = 0; i < _argc; i++)
        sum += [[parameters objectAtIndex:i] doubleValue];
    
    return [CPNumber numberWithDouble: sum / _argc];
}

- (CPNumber)add:to:(CPArray)parameters
{
    if (_argc != 2)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    var left = [parameters objectAtIndex:0],
        right = [parameters objectAtIndex:1];
    
    return [CPNumber numberWithDouble: [left doubleValue] + [right doubleValue]];
}

- (CPNumber)from:subtract:(CPArray)parameters
{
    if (_argc != 2)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    var left = [parameters objectAtIndex:0],
        right = [parameters objectAtIndex:1];
    
    return [CPNumber numberWithDouble: [left doubleValue] - [right doubleValue]];
}

- (CPNumber)multiply:by:(CPArray)parameters
{
    if (_argc != 2)
      [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    var left = [parameters objectAtIndex:0],
        right = [parameters objectAtIndex:1];
    
    return [CPNumber numberWithDouble: [left doubleValue] * [right doubleValue]];
}

- (CPNumber)divide:by:(CPArray)parameters
{
    if (_argc != 2)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    var left = [parameters objectAtIndex:0],
        right = [parameters objectAtIndex:1];
    
    return [CPNumber numberWithDouble: [left doubleValue] / [right doubleValue]];
}

- (CPNumber)sqrt:(CPArray)parameters
{
    if (_argc != 1)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    var num = [[parameters objectAtIndex:0] doubleValue];
    
    return [CPNumber numberWithDouble: SQRT(num)];
}

- (CPNumber)raise:to:(CPArray)parameters
{
    if (_argc < 2)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    var num = [[parameters objectAtIndex:0] doubleValue],
        power = [[parameters objectAtIndex:1] doubleValue];
    
    return [CPNumber numberWithDouble: POW(num,power)];    
}

- (CPNumber)abs:(CPArray)parameters
{
    if (_argc != 1)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    var num = [[parameters objectAtIndex:0] doubleValue];
    
    return [CPNumber numberWithDouble:ABS(num)];
}

- (CPDate)now
{
    return [CPDate date];
}

- (CPNumber)ln:(CPArray)parameters
{
    if (_argc != 1)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    var num = [[parameters objectAtIndex:0] doubleValue];
    
    return [CPNumber numberWithDouble:Math.log(num)];
}

- (CPNumber)exp:(CPArray)parameters
{
    if (_argc != 1)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    var num = [[parameters objectAtIndex:0] doubleValue];
    
    return [CPNumber numberWithDouble:EXP(num)];
}

- (CPNumber)ceiling:(CPArray)parameters
{
    if (_argc != 1)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    var num = [[parameters objectAtIndex:0] doubleValue];
    
    return [CPNumber numberWithDouble:CEIL(num)];
}

- (CPNumber)random
{
    return [CPNumber numberWithDouble:RAND()];
}

- (CPNumber)modulus:by:(CPArray)parameters
{
    if (_argc != 2)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    var left = [parameters objectAtIndex:0],
        right = [parameters objectAtIndex:1];
    
    return [CPNumber numberWithInt:([left intValue] % [right intValue])];
}


- (id)first:(CPArray)parameters
{
    if (_argc == 0)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    return [[parameters objectAtIndex:0] objectAtIndex:0];
}

- (id)last:(CPArray)parameters
{
    if (_argc == 0)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    return [[parameters objectAtIndex:0] lastObject];
}

- (CPNumber)chs:(CPArray)parameters
{
    if (_argc == 0)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    return [CPNumber numberWithInt: - [[parameters objectAtIndex:0] intValue]];
}

- (id)index:(CPArray)parameters
{
    if (_argc < 2)
        [CPException raise:CPInvalidArgumentException reason:"Invalid number of parameters"];
    
    var left = [parameters objectAtIndex:0],
        right = [parameters objectAtIndex:1];
    
    if ([left isKindOfClass: [CPDictionary class]])
        return [left objectForKey:right];
    else
        return [left objectAtIndex: [right intValue]];
}

/*
- (CPNumber)median:(CPArray)parameters
{
}
- (CPNumber)mode:(CPArray)parameters
{
}
- (CPNumber)stddev:(CPArray)parameters
{
}
- (CPNumber)log:(CPArray)parameters
{
}
- (CPNumber)raise:to:(CPArray)parameters
{
}
- (CPNumber)trunc:(CPArray)parameters
{
}

// These functions are used when parsing
*/

@end

