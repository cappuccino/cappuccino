
@import <Foundation/CPProxy.j>
@import "CPAnimationContext.j"

var _supportsCSSAnimations = null;

@protocol CPAnimatablePropertyContainer <CPObject>

+ (id)defaultAnimationForKey:(CPString)key;
- (id)animationForKey:(CPString)key;

- (id)animator;
- (CPDictionary)animations;
- (void)setAnimations:(CPDictionary)animations;

@end

@implementation _CPObjectAnimator : CPProxy
{
    id <CPAnimatablePropertyContainer> _target;
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

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return _target;
}

- (CPMethodSignature)methodSignatureForSelector:(SEL)aSelector
{
    return [_target methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(CPInvocation)anInvocation
{
    var target = [self forwardingTargetForSelector:[anInvocation selector]];
    [anInvocation invokeWithTarget:target];
    return;
}

- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    [CPException raise:CPInvalidArgumentException reason:@"Animator does not recognize selector " + CPStringFromSelector(aSelector)];
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
