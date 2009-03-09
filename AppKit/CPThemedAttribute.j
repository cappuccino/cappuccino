
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
    JSObject            _cache;

    CPString            _name;
    id                  _defaultValue;
    
    CPTheme             _theme;
    Class               _themedClass;
    
    CPDictionary        _values;
    CPThemedAttribute   _attributeFromTheme;
}

- (id)initWithName:(CPString)aName defaultValue:(id)aDefaultValue theme:(CPTheme)aTheme class:(Class)aClass
{
    self = [super init];

    if (self)
    {
        _cache = {};

        _name = aName;

        _defaultValue = aDefaultValue;

        _theme = aTheme;
        _themedClass = aClass;

        _values = [CPDictionary dictionary];
        _attributeFromTheme = nil;//[_theme valueForAttributeName:_name inClass:_themedClass];
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
    _cache = {};
    _defaultValue = aValue;
}

- (void)setTheme:(CPTheme)aTheme
{
    if (_theme === aTheme)
        return;
    
    _cache = {};
    _theme = aTheme;
    _attributeFromTheme = nil;//[_theme valueForAttributeName:_name inClass:_themedClass];
}

- (void)setThemedClass:(Class)aClass
{
    if (_themedClass === aClass)
        return;
    
    _cache = {};
    _themedClass = aClass;
    _attributeFromTheme = nil;//[_theme valueForAttributeName:_name inClass:_themedClass];
}

- (void)setValue:(id)aValue
{
    _cache = {};

    if (aValue === undefined || aValue === nil)
        _values = [CPDictionary dictionary];
    else
        _values = [CPDictionary dictionaryWithObject:aValue forKey:String(CPControlStateNormal)];
}

- (id)value
{
    return [self valueForControlState:CPControlStateNormal];
}

- (void)setValue:(id)aValue forControlState:(CPControlState)aState
{
    //delete _cache[aState];
    _cache = {};

    if ((aValue === undefined) || (aValue === nil))
        [_values removeObjectForKey:String(aState)];
    else
        [_values setObject:aValue forKey:String(aState)];
}

- (id)valueForControlState:(CPControlState)aState
{
    var value = _cache[aState];

    // This can be nil.
    if (value !== undefined)
        return value;

    value = [_values objectForKey:String(aState)];

    // If we don't have a value, and we have a non-normal state...
    if ((value === undefined || value === nil) && aState > 0)
    {
        // If this is a composite state, find the closest partial subset match.
        if (aState & (aState - 1))
        {
            var highestBitCount = 0,
                states = [_values allKeys],
                count = states.length;

            while (count--)
            {
                // state is a string!
                state = Number(states[count]);

                // A & B = A iff A < B
                if ((state & aState) === state)
                {
                    var bitCount = (state < BIT_COUNT.length) ? BIT_COUNT[state] : bit_count(state);

                    if (bitCount > highestBitCount)
                    {
                        highestBitCount = bitCount;
                        value = [_values objectForKey:String(state)];
                    }
                }
            }
        }

        // Still don't have a value? OK, let's use the normal value.
        if (value === undefined || value === nil)
            value = [_values objectForKey:String(CPControlStateNormal)];
    }

    if (value === undefined || value === nil)
        value = [_attributeFromTheme valueForControlState:aState];

    if (value === undefined || value === nil)
        value = _defaultValue;

    _cache[aState] = value;

    return value;
}

- (CPThemedAttribute)themedAttributeMergedWithThemedAttribute:(CPThemedAttribute)aThemedAttribute
{
    var mergedAttribute = CPThemedAttributeMake(_name, _defaultValue, _theme, _themedClass);
    
    mergedAttribute._values = [_values copy];
    [mergedAttribute._values addEntriesFromDictionary:aThemedAttribute._values];

    return mergedAttribute;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _cache = {};
        _values = [aCoder decodeObjectForKey:@"values"];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_values forKey:@"values"];
}

@end

function CPThemedAttributeMake(aName, aDefaultValue, aTheme, aClass)
{
    return [[CPThemedAttribute alloc] initWithName:aName defaultValue:aDefaultValue theme:aTheme class:aClass];
}

function CPThemedAttributeEncode(aCoder, aThemedAttribute)
{
    var values = aThemedAttribute._values,
        count = [values count];

    if (count === 1)
    {
        var key = [values allKeys][0];

        if (Number(key) === 0)
            return [aCoder encodeObject:[values objectForKey:key] forKey:"$a" + [aThemedAttribute name]];
    }

    if (count >= 1)
        [aCoder encodeObject:aThemedAttribute forKey:"$a" + [aThemedAttribute name]];
}

function CPThemedAttributeDecode(aCoder, anAttributeName, aDefaultValue, aTheme, aClass)
{
    var key = "$a" + anAttributeName;

    if (![aCoder containsValueForKey:key])
        return CPThemedAttributeMake(anAttributeName, aDefaultValue, aTheme, aClass);

    var attribute = [aCoder decodeObjectForKey:key];

    if (!attribute.isa || ![attribute isKindOfClass:[CPThemedAttribute class]])
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
