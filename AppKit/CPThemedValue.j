
@import <Foundation/CPObject.j>


CPControlStateNormal        = 0,
CPControlStateHighlighted   = 1 << 0,
CPControlStateDisabled      = 1 << 1,
CPControlStateSelected      = 1 << 2,
CPControlStateDefault       = 1 << 3;

var BIT_COUNT   = [ 0 /*0000*/, 1 /*0001*/, 1 /*0010*/, 2 /*0011*/, 1 /*0100*/, 2 /*0101*/, 2 /*0110*/, 3 /*0111*/, 
                    1 /*1000*/, 2 /*1001*/, 2 /*1010*/, 3 /*1011*/, 2 /*1100*/, 3 /*1101*/, 3 /*1110*/, 4 /*1111*/],
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

@implementation CPThemedValue : CPObject
{
    BOOL        _isSingularObject;
    
    CPTheme     _theme;
    CPString    _identifier;
    Class       _themedClass;
    
    id          _defaultValue;
    
    id          _values;
    id          _valueFromTheme;
}

- (id)initWithDefaultValue:(id)aDefaultValue identifier:(CPString)anIdentifier theme:(CPTheme)aTheme class:(Class)aClass
{
    self = [super init];
    
    if (self)
    {
        _theme = aTheme;
        _themedClass = aClass;
        _identifier = anIdentifier;
        _defaultValue = aDefaultValue;
        
        _isSingularObject = YES;
        _values = nil;
        _valueFromTheme = [_theme valueForIdentifier:_identifier inClass:_themedClass];
    }
    
    return self;
}

- (void)setDefaultValue:(id)aValue
{
    _defaultValue = aValue;
}

- (void)setIdentifier:(CPString)anIdentifier
{
    if (_identifier === anIdentifier)
        return;
    
    _identifier = anIdentifier;
    _valueFromTheme = [_theme valueForIdentifier:_identifier inClass:_themedClass];
}

- (CPString)identifier
{
    return _identifier;
}

- (void)setTheme:(CPTheme)aTheme
{
    if (_theme === aTheme)
        return;
    
    _theme = aTheme;
    _valueFromTheme = [_theme valueForIdentifier:_identifier inClass:_themedClass];
}

- (void)setThemedClass:(Class)aClass
{
    if (_themedClass === aClass)
        return;
    
    _themedClass = aClass;
    _valueFromTheme = [_theme valueForIdentifier:_identifier inClass:_themedClass];
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
    
    else if (isSingularObject)
        _values = aValue;
        
    else
        _values[CPControlStateNormal] = aValue;
}

- (id)valueForControlState:(CPControlState)aState
{
    if (_isSingularObject)
        return _values || [_valueFromTheme valueForControlState:aState] || _defaultValue;
        
    var value = _values[aState];
    
    // If we don't have a value, and we have a non-normal state...
    if (value === undefined && aState > 0)
    {
        // If this is a composite state, find the closest partial subset match.
        if (!(aState & (aState - 1)))
        {
            var highestBitCount = 0;
                
            for (state in _values)
            {                    
                if (!_values.hasOwnProperty(state))
                    continue;
                
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
        if (value === undefined)
            value = _values[CPControlStateNormal];
    }
    
    return value || [_valueFromTheme valueForControlState:aState] || _defaultValue;
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

function CPThemedValueMake(aDefaultValue, anIdentifier, aTheme, aClass)
{
    return [[CPThemedValue alloc] initWithDefaultValue:aDefaultValue identifier:anIdentifier theme:aTheme class:aClass];
}

function CPThemedValueEncode(aCoder, aKey, aThemedValue)
{
    if (aThemedValue._isSingularObject)
    {
        var actualValue = aThemedValue._values;
        
        if (aThemedValue._values)
            [aCoder encodeObject:actualValue forKey:aKey];
    }
    else
        [aCoder encodeObject:aThemedValue forKey:aKey];
}

function CPThemedValueDecode(aCoder, aKey, aDefaultValue, anIdentifier, aTheme, aClass)
{
    if (![aCoder containsValueForKey:aKey])
        return CPThemedValueMake(aDefaultValue, anIdentifier, aTheme, aClass);
    
    var value = [aCoder decodeObjectForKey:aKey];
    
    if (![value isKindOfClass:[CPThemedValue class]])
    {
        var themedValue = CPThemedValueMake(aDefaultValue, anIdentifier, aTheme, aClass);
        
        [themedValue setValue:value];
        
        value = themedValue;
    }
    else
    {
        [value setDefaultValue:aDefaultValue];
        [value setTheme:aTheme];
        [value setIdentifier:anIdentifier];
        [value setThemedClass:aClass];
    }
    
    return value;
}
