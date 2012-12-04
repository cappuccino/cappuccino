
@import "_CPObjectAnimator.j"
@import "CPView.j"

@class CPAnimationContext

@implementation CPViewAnimator : _CPObjectAnimator
{
}

- (void)removeFromSuperview
{
    [self _setTargetValue:nil withKeyPath:@"CPAnimationTriggerOrderOut" setter:_cmd];
}

- (void)setHidden:(BOOL)shouldHide
{
    if ([_target isHidden] == shouldHide)
        return;

    if (shouldHide == NO)
        return [_target setHidden:NO];

    [self _setTargetValue:YES withKeyPath:@"CPAnimationTriggerOrderOut" setter:_cmd];
}

- (void)setAlphaValue:(CGPoint)alphaValue
{
    [self _setTargetValue:alphaValue withKeyPath:@"alphaValue" setter:_cmd];
}

- (void)setBackgroundColor:(CPColor)aColor
{
    [self _setTargetValue:aColor withKeyPath:@"backgroundColor" setter:_cmd];
}

- (void)setFrameOrigin:(CGPoint)aFrameOrigin
{
    [self _setTargetValue:aFrameOrigin withKeyPath:@"frameOrigin" setter:_cmd];
}

- (void)setFrame:(CGRect)aFrame
{
    [self _setTargetValue:aFrame withKeyPath:@"frame" setter:_cmd];
}

- (void)setFrameSize:(CGSize)aFrameSize
{
    [self _setTargetValue:aFrameSize withKeyPath:@"frameSize" setter:_cmd];
}

- (void)_setTargetValue:(id)aTargetValue withKeyPath:(CPString)aKeyPath setter:(SEL)aSelector
{
    var animation = [_target animationForKey:aKeyPath],
        context = [CPAnimationContext currentContext];

    if (!animation || ![animation isKindOfClass:[CAAnimation class]] || (![context duration] && ![animation duration]) || ![_CPObjectAnimator supportsCSSAnimations])
        [_target performSelector:aSelector withObject:aTargetValue];
    else
    {
        [context _enqueueActionForObject:_target keyPath:aKeyPath targetValue:aTargetValue animationCompletion:function()
        {
           [_target performSelector:aSelector withObject:aTargetValue];
           CPLog.debug(_target + " " + aSelector + " " + CPDescriptionOfObject(aTargetValue));
        }];
    }
}

@end

var PROPERTY_DESCRIPTORS = {},
    ANIMATED_KEYS = [@"alphaValue", @"frame", @"frameSize", @"frameOrigin", @"backgroundColor"];

@implementation CPView (CPAnimatablePropertyContainer)

+ (void)getCSSProperties:(CPArray)properties valueFunctions:(CPArray)valueFunctions forKeyPath:(CPString)aKeyPath
{
    var descriptors = PROPERTY_DESCRIPTORS[aKeyPath];
    if (descriptors)
    {
        [properties addObjectsFromArray:descriptors[0]];
        [valueFunctions addObjectsFromArray:descriptors[1]];
    }
    else
    {
        CSSPropertyDescriptors(aKeyPath, properties, valueFunctions);
        PROPERTY_DESCRIPTORS[aKeyPath] = [properties, valueFunctions];
    }
}

- (id)animator
{
    if (!_animator)
        _animator = [[CPViewAnimator alloc] initWithTarget:self];

    return _animator;
}


+ (CAAnimation)defaultAnimationForKey:(CPString)aKey
{
    if ([ANIMATED_KEYS containsObject:aKey])
        return [CAAnimation animation];

    return nil;
}

- (CAAnimation)animationForKey:(CPString)aKey
{
    var animations = [self animations],
        animation = nil;

    if (!animations || !(animation = [animations objectForKey:aKey]))
    {
        animation = [[self class] defaultAnimationForKey:aKey];
    }

    return animation;
}

- (CPDictionary)animations
{
    return _animationsDictionary;
}

- (void)setAnimations:(CPDictionary)animationsDict
{
    _animationsDictionary = [animationsDict copy];
}

@end

var CSSPropertyDescriptors = function(aKeyPath, properties, valueFunctions)
{
    var cssprop = null,
        valueFunction = null;

    switch (aKeyPath)
    {
        case "backgroundColor"  : cssprop = "background"; valueFunction = function(val){return [val cssString];};
        break;

        case "alphaValue"       : cssprop = "opacity";
        break;

        case "frame"            : CSSPropertyDescriptors("frameX", properties, valueFunctions);
                                  CSSPropertyDescriptors("frameY", properties, valueFunctions);
                                  CSSPropertyDescriptors("frameWidth", properties, valueFunctions);
                                  CSSPropertyDescriptors("frameHeight", properties, valueFunctions);
        break;

        case "frameOrigin"      : CSSPropertyDescriptors("frameOriginX", properties, valueFunctions);
                                  CSSPropertyDescriptors("frameOriginY", properties, valueFunctions);
        break;

        case "frameSize"        : CSSPropertyDescriptors("frameSizeWidth", properties, valueFunctions);
                                  CSSPropertyDescriptors("frameSizeHeight", properties, valueFunctions);
        break;

        case "frameOriginX"     : cssprop = "left"; valueFunction = function(val){return val.x + "px";};
        break;

        case "frameOriginY"     : cssprop = "top"; valueFunction = function(val){return val.y + "px";};
        break;

        case "frameSizeWidth"   : cssprop = "width"; valueFunction = function(val){return val.width + "px";};
        break;

        case "frameSizeHeight"  : cssprop = "height"; valueFunction = function(val){return val.height + "px";};
        break;

        case "frameX"           : cssprop = "left"; valueFunction = function(val){return val.origin.x + "px";};
        break;

        case "frameY"           : cssprop = "top"; valueFunction = function(val){return val.origin.y + "px";};
        break;

        case "frameWidth"       : cssprop = "width"; valueFunction = function(val){return val.size.width + "px";};
        break;

        case "frameHeight"      : cssprop = "height"; valueFunction = function(val){return val.size.height + "px";};
        break;
    }

    if (cssprop)
    {
        properties.push(cssprop);
        // can be null
        valueFunctions.push(valueFunction);
    }
};