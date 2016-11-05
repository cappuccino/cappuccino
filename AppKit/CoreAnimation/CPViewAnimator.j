
@import "_CPObjectAnimator.j"
@import "CPView.j"
@import "CPCompatibility.j"

@implementation CPViewAnimator : _CPObjectAnimator
{
    BOOL    _wantsPeriodicFrameUpdates  @accessors(property=wantsPeriodicFrameUpdates);
}

- (id)initWithTarget:(id)aTarget
{
    self = [super initWithTarget:aTarget];

    _wantsPeriodicFrameUpdates = NO;

    return self;
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

var transformFrameToWidth = function(start, current)
{
    return current.size.width + "px";
};

var transformFrameToHeight = function(start, current)
{
    return current.size.height + "px";
};

var transformSizeToWidth = function(start, current)
{
    return current.width + "px";
};

var transformSizeToHeight = function(start, current)
{
    return current.height + "px";
};

var CSSStringFromCGAffineTransform = function(anAffineTransform)
{
    return "matrix(" + anAffineTransform.a + ", " + anAffineTransform.b + ", " + anAffineTransform.c + ", " + anAffineTransform.d + ", " + anAffineTransform.tx + (CPBrowserIsEngine(CPGeckoBrowserEngine) ? "px, " : ", ") + anAffineTransform.ty + (CPBrowserIsEngine(CPGeckoBrowserEngine) ? "px)" : ")");
};

var frameOriginToCSSTransformMatrix = function(start, current)
{
    var affine = CGAffineTransformMakeTranslation(current.x - start.x, current.y - start.y);

    return CSSStringFromCGAffineTransform(affine);
};

var frameToCSSTranslationTransformMatrix = function(start, current)
{
    var affine = CGAffineTransformMakeTranslation(current.origin.x - start.origin.x, current.origin.y - start.origin.y);

    return CSSStringFromCGAffineTransform(affine);
};

var DEFAULT_CSS_PROPERTIES = nil;

@implementation CPView (CPAnimatablePropertyContainer)

+ (CPDictionary)_defaultCSSProperties
{
    if (DEFAULT_CSS_PROPERTIES == nil)
    {
        var transformProperty = CPBrowserCSSProperty("transform");

        DEFAULT_CSS_PROPERTIES =  @{
                                    "backgroundColor"  : [@{"property":"background", "value":function(sv, val){return [val cssString];}}],
                                    "alphaValue"       : [@{"property":"opacity"}],
                                    "frame"            : [@{"property":transformProperty, "value":frameToCSSTranslationTransformMatrix},
                                                          @{"property":"width", "value":transformFrameToWidth},
                                                          @{"property":"height", "value":transformFrameToHeight}],
                                    "frameOrigin"      : [@{"property":transformProperty, "value":frameOriginToCSSTransformMatrix}],
                                    "frameSize"        : [@{"property":"width", "value":transformSizeToWidth},
                                                          @{"property":"height", "value":transformSizeToHeight}]
                                    };
    }

    return DEFAULT_CSS_PROPERTIES;
}

+ (CPArray)_cssPropertiesForKeyPath:(CPString)aKeyPath
{
    return [[self _defaultCSSProperties] objectForKey:aKeyPath];
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
    // TODO: remove when supported.
    if (aKey == @"CPAnimationTriggerOrderIn")
    {
        CPLog.warn("CPView animated key path CPAnimationTriggerOrderIn is not supported yet.");
        return nil;
    }

    if ([self _cssPropertiesForKeyPath:aKey] !== nil)
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
