#define CONTROL_STATE_VALUE(VALUE, LOWERCASEVALUE) \
- (void)set##VALUE:(id)aValue forControlState:(CPControlState)aControlState\
{\
    var currentValue = [_##LOWERCASEVALUE valueForControlState:_controlState];\
    [_##LOWERCASEVALUE setValue:aValue forControlState:aControlState];\
    if ([_##LOWERCASEVALUE valueForControlState:_controlState] === currentValue)\
        return;\
    [self setNeedsDisplay:YES];\
    [self setNeedsLayout];\
}\
- (id)LOWERCASEVALUE##ForControlState:(CPControlState)aControlState\
{\
    return [_##LOWERCASEVALUE valueForControlState:aControlState];\
}\
- (void)set##VALUE:(id)aValue\
{\
    var currentValue = [_##LOWERCASEVALUE valueForControlState:_controlState];\
    [_##LOWERCASEVALUE setValue:aValue];\
    if ([_##LOWERCASEVALUE valueForControlState:_controlState] === currentValue)\
        return;\
    [self setNeedsDisplay:YES];\
    [self setNeedsLayout];\
}\
- (id)LOWERCASEVALUE\
{\
    return [_##LOWERCASEVALUE valueForControlState:_controlState];\
}
