
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
    CPLog.debug("Set value for animated keypath " + aKeyPath);

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

var CPVIEW_PROPERTIES_DESCRIPTOR = @{
    "backgroundColor"  : [@{"property":"background", "value":function(val){return [val cssString];}}],
    "alphaValue"       : [@{"property":"opacity"}],
    "frame"            : [@{"property":"left", "value":function(val){return val.origin.x + "px";}},
                          @{"property":"top", "value":function(val){return val.origin.y + "px";}},
                          @{"property":"width", "value":function(val){return val.size.width + "px";}},
                          @{"property":"height", "value":function(val){return val.size.height + "px";}}],
    "frameOrigin"      : [@{"property":"left", "value":function(val){return val.x + "px";}},
                          @{"property":"top", "value":function(val){return val.y + "px";}}],
    "frameSize"        : [@{"property":"width", "value":function(val){return val.width + "px";}},
                          @{"property":"height", "value":function(val){return val.height + "px";}}]
};

@implementation CPView (CPAnimatablePropertyContainer)

+ (CPArray)cssPropertiesForKeyPath:(CPString)aKeyPath
{
    return [CPVIEW_PROPERTIES_DESCRIPTOR objectForKey:aKeyPath];
}

- (id)DOMElementForKeyPath:(CPString)aKeyPath
{
    return _DOMElement;
}

- (id)animator
{
    if (!_animator)
        _animator = [[CPViewAnimator alloc] initWithTarget:self];

    return _animator;
}

+ (CAAnimation)defaultAnimationForKey:(CPString)aKey
{
    if ([[self class] cssPropertiesForKeyPath:aKey] !== nil)
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