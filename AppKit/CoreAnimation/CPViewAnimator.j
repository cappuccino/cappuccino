
@import "_CPObjectAnimator.j"
@import "CPView.j"
@import "CPCompatibility.j"
@import "CSSAnimation.j"

var DEFAULT_CSS_PROPERTIES = nil,
    FRAME_UPDATERS = {};

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
        [_target _setForceUpdates:YES];
        [_target performSelector:aSelector withObject:aTargetValue];
        [_target _setForceUpdates:NO];
    };

    [self _setTargetValue:aTargetValue withKeyPath:aKeyPath fallback:handler completion:handler];
}

- (void)_setTargetValue:(id)aTargetValue withKeyPath:(CPString)aKeyPath fallback:(Function)fallback completion:(Function)completion
{
    var animation = [_target animationForKey:aKeyPath],
        context = [CPAnimationContext currentContext];

    if (!animation || ![animation isKindOfClass:[CAAnimation class]] || (![context duration] && ![animation duration]) || !CPFeatureIsCompatible(CPCSSAnimationFeature))
    {
        if (fallback)
            fallback();
    }
    else
    {
        [context _enqueueActionForObject:_target keyPath:aKeyPath targetValue:aTargetValue animationCompletion:completion];
    }
}

+ (CPDictionary)_defaultCSSProperties
{
    if (DEFAULT_CSS_PROPERTIES == nil)
    {
        var transformProperty = "transform";

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

+ (void)addAnimations:(CPArray)animations forAction:(id)anAction
{
    var target = anAction.object;

    return [self _addAnimations:animations forAction:anAction domElement:[target _DOMElement] identifier:[target UID]];
}

+ (void)_addAnimations:(CPArray)animations forAction:(id)anAction domElement:(Object)aDomElement identifier:(CPString)anIdentifier
{
    var animation = [animations objectPassingTest:function(anim, idx, stop)
    {
        return anim.identifier == anIdentifier;
    }];

    if (animation == nil)
    {
        animation = new CSSAnimation(aDomElement, anIdentifier, [anAction.object debug_description]);
        [animations addObject:animation];
    }

    var css_mapping = [self _cssPropertiesForKeyPath:anAction.keypath];

    [css_mapping enumerateObjectsUsingBlock:function(aDict, anIndex, stop)
    {
        var completionFunction = (anIndex == 0) ? anAction.completion : null,
            property = [aDict objectForKey:@"property"],
            getter = [aDict objectForKey:@"value"];

        animation.addPropertyAnimation(property, getter, anAction.duration, anAction.keytimes, anAction.values, anAction.timingfunctions, completionFunction);
    }];
}

+ (CPArray)_cssPropertiesForKeyPath:(CPString)aKeyPath
{
    return [[self _defaultCSSProperties] objectForKey:aKeyPath];
}

+ (void)addFrameUpdaters:(CPArray)frameUpdaters forAction:(id)anAction
{
    var rootIdentifier = [anAction.root UID];

    var frameUpdater = [frameUpdaters objectPassingTest:function(updater, idx, stop)
    {
        // There is one timer, linked to the top view, that updates the whole hierarchy.
        return updater.identifier() == rootIdentifier;
    }];

    if (frameUpdater == nil)
    {
        frameUpdater = new FrameUpdater(rootIdentifier);
        [frameUpdaters addObject:frameUpdater];
        FRAME_UPDATERS[rootIdentifier] = frameUpdater;
    }

    frameUpdater.addTarget(anAction.object, anAction.keypath, anAction.duration);
}

+ (void)stopUpdaterWithIdentifier:(CPString)anIdentifier
{
    var frameUpdater = FRAME_UPDATERS[anIdentifier];

    if (frameUpdater)
    {
        frameUpdater.stop();
        delete FRAME_UPDATERS[anIdentifier];
    }
    else
        CPLog.warn("Could not find FrameUpdater with identifier " + anIdentifier);
}

- (BOOL)needsPeriodicFrameUpdatesForKeyPath:(CPString)aKeyPath
{
    return ((aKeyPath == @"frame" || aKeyPath == @"frameSize") &&
            (([_target hasCustomLayoutSubviews] && ![_target implementsSelector:@selector(frameRectOfView:inSuperviewSize:)])
             || [_target hasCustomDrawRect]))
            || [self wantsPeriodicFrameUpdates];
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
    return [CPString stringWithFormat:@"matrix(%d,%d,%d,%d,%d,%d)", anAffineTransform.a, anAffineTransform.b, anAffineTransform.c, anAffineTransform.d, anAffineTransform.tx, anAffineTransform.ty];
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

@implementation CPView (CPAnimatablePropertyContainer)

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

+ (CAAnimation)defaultAnimationForKey:(CPString)aKey
{
    // TODO: remove when supported.
    if (aKey == @"CPAnimationTriggerOrderIn")
    {
        CPLog.warn("CPView animated key path CPAnimationTriggerOrderIn is not supported yet.");
        return nil;
    }

    if ([[self animatorClass] _cssPropertiesForKeyPath:aKey] != nil)
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

- (Object)_DOMElement
{
    return _DOMElement;
}

- (CPString)debug_description
{
    return [self identifier] || [self className];
}

@end

@implementation CPArray (Additions)

- (CPArray)objectPassingTest:(Function)aFunction
{
    var idx = [self indexOfObjectPassingTest:aFunction];

    if (idx !== CPNotFound)
        return [self objectAtIndex:idx];

    return nil;
}
@end

var FrameUpdater = function(anIdentifier)
{
    this._identifier = anIdentifier;
    this._requestId = null;
    this._duration = 0;
    this._stop = false;
    this._targets = [];
    this._callbacks = [];

    var frameUpdater = this;

    this._updateFunction = function(timestamp)
    {
        if (frameUpdater._startDate == null)
            frameUpdater._startDate = timestamp;

        if (frameUpdater._stop)
            return;

        for (var i = 0; i < frameUpdater._callbacks.length; i++)
            frameUpdater._callbacks[i]();

        if (timestamp - frameUpdater._startDate < frameUpdater._duration * 1000)
            window.requestAnimationFrame(frameUpdater._updateFunction);
    };
};

FrameUpdater.prototype.start = function()
{
    this._requestId = window.requestAnimationFrame(this._updateFunction);
};

FrameUpdater.prototype.stop = function()
{
    CPLog.warn("STOP FrameUpdater" + this._identifier);

    // window.cancelAnimationFrame support is Chrome 24, Firefox 23, IE 10, Opera 15, Safari 6.1
    if (window.cancelAnimationFrame)
        window.cancelAnimationFrame(this._requestId);

    this._stop = true;
};

FrameUpdater.prototype.updateFunction = function()
{
    return this._updateFunction;
};

FrameUpdater.prototype.identifier = function()
{
    return this._identifier;
};

FrameUpdater.prototype.description = function()
{
    return "<timer " + this._identifier + " " + this._targets.map(function(t){return [t debug_description];}) + ">";
};

FrameUpdater.prototype.addTarget = function(target, keyPath, duration)
{
    var callback = createUpdateFrame(target, keyPath);

    if (callback)
    {
        this._duration = MAX(this._duration, duration);
        this._targets.push(target);
        this._callbacks.push(callback);
    }
};

var createUpdateFrame = function(aView, aKeyPath)
{
    if (aKeyPath !== "frame" && aKeyPath !== "frameSize" && aKeyPath !== "frameOrigin")
        return nil;

    var style = getComputedStyle([aView _DOMElement]),
        getCSSPropertyValue = function(prop) {
            return ROUND(parseFloat(style.getPropertyValue(prop)));
        },
        initialOrigin     = CGPointMakeCopy([aView frameOrigin]),
        transformProperty = CPBrowserStyleProperty("transform"),
        updateFrame       = function(timestamp)
        {
                if (aKeyPath === "frameSize")
                {
                    var width  = getCSSPropertyValue("width"),
                        height = getCSSPropertyValue("height");

                    [aView setFrameSize:CGSizeMake(width, height)];
                }
                else
                {
                    [aView _setInhibitDOMUpdates:YES];

                    var matrix_value = style[transformProperty];

                    if (matrix_value && matrix_value !== 'none')
                    {
                        var matrix_array = matrix_value.split('(')[1].split(')')[0].split(','),
                                       x = ROUND(initialOrigin.x + parseFloat(matrix_array[4])),
                                       y = ROUND(initialOrigin.y + parseFloat(matrix_array[5]));

                        if (aKeyPath === "frame")
                        {
                            var width  = getCSSPropertyValue("width"),
                                height = getCSSPropertyValue("height");

                            [aView setFrame:CGRectMake(x, y, width, height)];
                        }
                        else
                        {
                            [aView setFrameOrigin:CGPointMake(x, y)];
                        }
                    }

                    [aView _setInhibitDOMUpdates:NO];
                }

            [[CPRunLoop currentRunLoop] performSelectors];
    //        CPLog.debug("update " + [aView debug_description]);
        };

    return updateFrame;
};
