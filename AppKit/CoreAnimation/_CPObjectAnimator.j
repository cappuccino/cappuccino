
@import <Foundation/CPProxy.j>
@import "CAAnimation.j"

@class CPAnimationContext

var _supportsCSSAnimations = null;

@implementation _CPObjectAnimator : CPProxy
{
    id /*CPAnimatablePropertyContainer*/ _target;
}

+ (BOOL)supportsCSSAnimations
{
    if (_supportsCSSAnimations === null)
        _supportsCSSAnimations = CPBrowserCSSProperty("animation");

    return _supportsCSSAnimations;
}

- (id)initWithTarget:(id)aTarget
{
    _target = aTarget;

    return self;
}

- (id)animator
{
    return self;
}

- (BOOL)isEqual:(id)anObject
{
   return [_target isEqual:anObject];
}

- (id)methodSignatureForSelector:(SEL)aSelector
{
    return [_target methodSignatureForSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return _target;
}

- (void)forwardInvocation:(id)anInvocation
{
    [anInvocation setTarget:_target];
    [anInvocation invoke];
}

- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    [_target doesNotRecognizeSelector:aSelector];
}

- (CPString)description
{
    return [CPString stringWithFormat:@"%@ Animator Proxy for %@", [self class], _target];
}

- (void)setValue:(id)aTargetValue forKey:(id)aKeyPath
{
    var animation = [_target animationForKey:aKeyPath],
        context = [CPAnimationContext currentContext];

    if (!animation || ![animation isKindOfClass:[CAAnimation class]] || (![context duration] && ![animation duration]) || ![_CPObjectAnimator supportsCSSAnimations])
        [_target setValue:aTargetValue forKey:aKeyPath];
    else
    {
        [context _enqueueActionForObject:_target keyPath:aKeyPath targetValue:aTargetValue completionHandler:function()
        {
            [_target setValue:aTargetValue forKey:aKeyPath];
        }];
    }
}

@end