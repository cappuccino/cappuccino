
@import "_CPObjectAnimator.j"
@import "CPView.j"

@implementation CPViewAnimator : _CPObjectAnimator
{
    BOOL    wantPeriodicFrameUpdates    @accessors;
}

- (id)initWithTarget:(id)aTarget
{
    self = [super initWithTarget:aTarget];

    wantPeriodicFrameUpdates = ([aTarget hasCustomDrawRect] || [aTarget hasCustomLayoutSubviews]);

    return self;
}

- (void)viewWillMoveToSuperview:(CPView)aSuperview
{
    var orderInAnim = [self animationForKey:@"CPAnimationTriggerOrderIn"];

    if (orderInAnim && [orderInAnim isKindOfClass:[CAPropertyAnimation class]])
    {
        [_target setValue:[orderInAnim fromValue] forKeyPath:[orderInAnim keyPath]];
    }

    [_target viewWillMoveToSuperview:aSuperview];
}

- (void)viewDidMoveToSuperview
{
    var orderInAnim = [self animationForKey:@"CPAnimationTriggerOrderIn"];

    if (orderInAnim && [orderInAnim isKindOfClass:[CAPropertyAnimation class]])
    {
        [self _setTargetValue:YES withKeyPath:@"CPAnimationTriggerOrderIn" fallback:nil completion:function()
        {
            [_target setValue:[orderInAnim toValue] forKeyPath:[orderInAnim keyPath]];
        }];
    }
    else
    {
        [_target viewDidMoveToSuperview];
    }
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

// Convenience method for the common case where the setter has zero or one argument
- (void)_setTargetValue:(id)aTargetValue withKeyPath:(CPString)aKeyPath setter:(SEL)aSelector
{
    var handler = function()
    {
        [_target performSelector:aSelector withObject:aTargetValue];
    };

    [self _setTargetValue:aTargetValue withKeyPath:aKeyPath fallback:handler completion:handler];
}

- (void)_setTargetValue:(id)aTargetValue withKeyPath:(CPString)aKeyPath fallback:(Function)fallback completion:(Function)completion
{
    var animation = [_target animationForKey:aKeyPath],
        context = [CPAnimationContext currentContext];

    if (!animation || ![animation isKindOfClass:[CAAnimation class]] || (![context duration] && ![animation duration]) || ![_CPObjectAnimator supportsCSSAnimations])
    {
        if (fallback)
            fallback();
    }
    else
    {
        [context _enqueueActionForObject:_target keyPath:aKeyPath targetValue:aTargetValue animationCompletion:completion];
    }
}

@end

var CSSStringFromCGAffineTransform = function(anAffineTransform)
{
    // Firefox : add px to the translate values.
    return "matrix(" + anAffineTransform.a + ", " + anAffineTransform.b + ", " + anAffineTransform.c + ", " + anAffineTransform.d + ", " + anAffineTransform.tx + ", " + anAffineTransform.ty + ")";
};

var frameOriginToCSSTransformMatrix = function(start, current)
{
    var affine = CGAffineTransformMakeTranslation(current.x - start.x, current.y - start.y);

    return CSSStringFromCGAffineTransform(affine);
};

var frameSizeToCSSTransformMatrix = function(start, current)
{
    // !! Zero start size
    var offsetX = (current.width - start.width) / 2,
        offsetY = (current.height - start.height) / 2;

    var affine = CGAffineTransformMake(current.width / start.width, 0, 0, current.height / start.height, offsetX, offsetY);

    return CSSStringFromCGAffineTransform(affine);
};

var frameToCSSTransformMatrix = function(start, current)
{
    // !! Zero start size
    var offsetX = (current.size.width  - start.size.width)  / 2,
        offsetY = (current.size.height - start.size.height) / 2;

    var affine = CGAffineTransformMake(current.size.width / start.size.width, 0, 0, current.size.height / start.size.height, current.origin.x - start.origin.x + offsetX, current.origin.y - start.origin.y + offsetY);

    return CSSStringFromCGAffineTransform(affine);
};

var DEFAULT_CSS_PROPERTIES = nil;

@implementation CPView (CPAnimatablePropertyContainer)

+ (CPDictionary)defaultCSSProperties
{
    if (DEFAULT_CSS_PROPERTIES == nil)
    {
        var transformProperty = CPBrowserCSSProperty("transform");

        DEFAULT_CSS_PROPERTIES =  @{
                                    "backgroundColor"  : [@{"property":"background", "value":function(sv, val){return [val cssString];}}],
                                    "alphaValue"       : [@{"property":"opacity"}],
                                    "frame"            : [@{"property":transformProperty, "value":frameToCSSTransformMatrix}],
                                    "frameOrigin"      : [@{"property":transformProperty, "value":frameOriginToCSSTransformMatrix}],
                                    "frameSize"        : [@{"property":transformProperty, "value":frameSizeToCSSTransformMatrix}]
                                    };
    }

    return DEFAULT_CSS_PROPERTIES;
}

+ (CPArray)cssPropertiesForKeyPath:(CPString)aKeyPath
{
    return [[self defaultCSSProperties] objectForKey:aKeyPath];
}

+ (Class)animatorClass
{
    var anim_class = CPClassFromString(CPStringFromClass(self) + "Animator");

    if (anim_class)
        return anim_class;

    return [[self superclass] animatorClass];
}

- (id)animator
{
    if (!_animator)
        _animator = [[[[self class] animatorClass] alloc] initWithTarget:self];

    return _animator;
}

- (id)DOMElementForKeyPath:(CPString)aKeyPath
{
    return _DOMElement;
}

+ (CAAnimation)defaultAnimationForKey:(CPString)aKey
{
    if ([self cssPropertiesForKeyPath:aKey] !== nil)
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
