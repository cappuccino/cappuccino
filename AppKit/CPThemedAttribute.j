
@import <Foundation/CPObject.j>


CPControlStateNormal        = 0,
CPControlStateHighlighted   = 1 << 0,
CPControlStateDisabled      = 1 << 1,
CPControlStateSelected      = 1 << 2,
CPControlStateDefault       = 1 << 3,
CPControlStateBordered      = 1 << 4,
CPControlStateBezeled       = 1 << 5,
CPControlStateVertical      = 1 << 6;

var BIT_COUNT   = [ 0 /*00000*/, 1 /*00001*/, 1 /*00010*/, 2 /*00011*/, 1 /*00100*/, 2 /*00101*/, 2 /*00110*/, 3 /*00111*/, 
                    1 /*01000*/, 2 /*01001*/, 2 /*01010*/, 3 /*01011*/, 2 /*01100*/, 3 /*01101*/, 3 /*01110*/, 4 /*01111*/,
                    1 /*10000*/, 2 /*10001*/, 2 /*10010*/, 3 /*10011*/, 2 /*10100*/, 3 /*10101*/, 3 /*10110*/, 4 /*10111*/, 
                    2 /*11000*/, 3 /*11001*/, 3 /*11010*/, 4 /*11011*/, 3 /*11100*/, 4 /*11101*/, 4 /*11110*/, 5 /*11111*/],
    bit_count   = function(bits)
    {
        var count = 0;
        
        while (bits)
        {
            ++count;
            bits &= (bits - 1);
        }

        return count ;
    }

@implementation CPThemedAttribute : CPObject
{
    BOOL        _isSingularObject;
    
    CPString    _name;
    id          _defaultValue;
    
    CPTheme     _theme;
    Class       _themedClass;
    
    id          _values;
    id          _valueFromTheme;
}

- (id)initWithName:(CPString)aName defaultValue:(id)aDefaultValue theme:(CPTheme)aTheme class:(Class)aClass
{
    self = [super init];
    
    if (self)
    {
        _name = aName;
        
        _defaultValue = aDefaultValue;
        
        _theme = aTheme;
        _themedClass = aClass;
        
        _isSingularObject = YES;
        _values = nil;
        _valueFromTheme = [_theme valueForAttributeName:_name inClass:_themedClass];
    }
    
    return self;
}

- (void)setName:(CPString)aName
{
    _name = aName;
}

- (CPString)name
{
    return _name;
}

- (void)setDefaultValue:(id)aValue
{
    _defaultValue = aValue;
}

- (void)setTheme:(CPTheme)aTheme
{
    if (_theme === aTheme)
        return;
    
    _theme = aTheme;
    _valueFromTheme = [_theme valueForAttributeName:_name inClass:_themedClass];
}

- (void)setThemedClass:(Class)aClass
{
    if (_themedClass === aClass)
        return;
    
    _themedClass = aClass;
    _valueFromTheme = [_theme valueForAttributeName:_name inClass:_themedClass];
}

- (void)setValue:(id)aValue
{
    _isSingularObject = YES;
    _values = aValue;
}

- (id)value
{
    return [self valueForControlState:CPControlStateNormal];
}

- (void)setValue:(id)aValue forControlState:(CPControlState)aState
{
    if (aState !== CPControlStateNormal)
    {
        if (_isSingularObject)
        {
            var normalValue = _values;
            
            _isSingularObject = NO;
            
            _values = {};
            
            if (normalValue)
                _values[CPControlStateNormal] = normalValue;
        }
        
        _values[aState] = aValue;
    }
    
    else if (_isSingularObject)
        _values = aValue;
        
    else
        _values[CPControlStateNormal] = aValue;
}

- (id)valueForControlState:(CPControlState)aState
{
    if (_isSingularObject)
    {
        var value = _values;

        if (value === undefined || value === nil)
            value = [_valueFromTheme valueForControlState:aState];

        if (value === undefined || value === nil)
            value = _defaultValue;

        return value;
    }

    var value = _values[aState];
    
    // If we don't have a value, and we have a non-normal state...
    if ((value === undefined || value === nil) && aState > 0)
    {
        // If this is a composite state, find the closest partial subset match.
        if (aState & (aState - 1))
        {
            var highestBitCount = 0;
                
            for (state in _values)
            {                    
                if (!_values.hasOwnProperty(state))
                    continue;
                
                // state is a string!
                state = Number(state);
                
                // A & B = A iff A < B
                if ((state & aState) === state)
                {
                    var bitCount = (state < BIT_COUNT.length) ? BIT_COUNT[state] : bit_count(state);
                        
                    if (bitCount > highestBitCount)
                    {
                        highestBitCount = bitCount;
                        value = _values[state];
                    }
                }
            }
        }

        // Still don't have a value? OK, let's use the normal value.        
        if (value === undefined || value === nil)
            value = _values[CPControlStateNormal];
    }

    if (value === undefined || value === nil)
        value = [_valueFromTheme valueForControlState:aState];

    if (value === undefined || value === nil)
        value = _defaultValue;

    return value;
}

- (CPThemedAttribute)themedAttributeMergedWithThemedAttribute:(CPThemedAttribute)aThemedAttribute
{
    var themedAttribute = CPThemedAttributeMake(_name, _defaultValue, _theme, _themedClass);
    
    themedAttribute._isSingularObject = NO;
    themedAttribute._values = {};
    
    if (_isSingularObject)
        themedAttribute._values[CPControlStateNormal] = _values;

    else
    {
        var values = _values;
        
        for (state in _values)
            if (_values.hasOwnProperty(state))
                themedAttribute._values[state] = _values[state];
    }

    if (aThemedAttribute._isSingularObject)
        themedAttribute._values[CPControlStateNormal] = aThemedAttribute._values;

    else
    {
        var values = aThemedAttribute._values;
        
        for (state in values)
            if (values.hasOwnProperty(state))
                themedAttribute._values[state] = values[state];
    }
    
    return themedAttribute;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _isSingularObject = [aCoder containsValueForKey:@"value"];
        
        if (_isSingularObject)
            _values = [aCoder decodeObjectForKey:"value"];
        
        else
        {       
            _values = {};     
            
            var statesAndValues = [aCoder decodeObjectForKey:"statesAndValues"];
                count = [statesAndValues count];
                    
            while (count--)
            {
                var value = statesAndValues[count--],
                    state = statesAndValues[count];
                
                _values[state] = value;
            }
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    if (_isSingularObject)
    {
        [aCoder encodeObject:_values forKey:@"value"];
    
        return;
    }
    
    var statesAndValues = [];
    
    for (state in _values)
    {
        if (!_values.hasOwnProperty(state))
            continue;

        statesAndValues.push(state);
        statesAndValues.push(_values[state]);
    }

    [aCoder encodeObject:statesAndValues forKey:@"statesAndValues"];
}

@end

function CPThemedAttributeMake(aName, aDefaultValue, aTheme, aClass)
{
    return [[CPThemedAttribute alloc] initWithName:aName defaultValue:aDefaultValue theme:aTheme class:aClass];
}

function CPThemedAttributeEncode(aCoder, aThemedAttribute)
{
    if (aThemedAttribute._isSingularObject)
    {
        var actualValue = aThemedAttribute._values;

        if (aThemedAttribute._values)
            [aCoder encodeObject:actualValue forKey:"$a" + [aThemedAttribute name]];
    }
    else
        [aCoder encodeObject:aThemedAttribute forKey:"$a" + [aThemedAttribute name]];
}

function CPThemedAttributeDecode(aCoder, anAttributeName, aDefaultValue, aTheme, aClass)
{
    var key = "$a" + anAttributeName;

    if (![aCoder containsValueForKey:key])
        return CPThemedAttributeMake(anAttributeName, aDefaultValue, aTheme, aClass);

    var attribute = [aCoder decodeObjectForKey:key];

    if (![attribute isKindOfClass:[CPThemedAttribute class]])
    {
        var themedAttribute = CPThemedAttributeMake(anAttributeName, aDefaultValue, aTheme, aClass);

        [themedAttribute setValue:attribute];

        attribute = themedAttribute;
    }
    else
    {
        [attribute setName:anAttributeName];
        [attribute setDefaultValue:aDefaultValue];
        [attribute setTheme:aTheme];
        [attribute setThemedClass:aClass];
    }

    return attribute;
}
