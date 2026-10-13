/*
 * CPViewAnimator.j
 * AppKit
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "_CPObjectAnimator.j"
@import "CPView.j"
@import "CPCompatibility.j"
@import "CSSAnimation.j"

/* @ignore */
var DEFAULT_CSS_PROPERTIES = nil,
    FRAME_UPDATERS = {};

/*!
    @ingroup appkit
    @class CPViewAnimator
    CPViewAnimator handles animated property changes for \c CPView instances (such as frame,
    alpha, and background color), translating them into CSS animations or frame update timers.
*/
@implementation CPViewAnimator : _CPObjectAnimator
{
    BOOL    _wantsPeriodicFrameUpdates  @accessors(property=wantsPeriodicFrameUpdates);
}

/*!
    Initializes a view animator with the specified target view.
    @param aTarget the view to be animated
    @return the initialized animator instance
*/
- (id)initWithTarget:(id)aTarget
{
    self = [super initWithTarget:aTarget];

    _wantsPeriodicFrameUpdates = NO;

    return self;
}

/*!
    Animates the target view removal from its superview using an order-out animation.
*/
- (void)removeFromSuperview
{
    [self _setTargetValue:nil withKeyPath:@"CPAnimationTriggerOrderOut" setter:_cmd];
}

/*!
    Animates the target view's hidden state.
    @param shouldHide \c YES to animate out and hide the view, \c NO to show immediately
*/
- (void)setHidden:(BOOL)shouldHide
{
    if ([_target isHidden] == shouldHide)
        return;

    if (shouldHide == NO)
        return [_target setHidden:NO];

    [self _setTargetValue:YES withKeyPath:@"CPAnimationTriggerOrderOut" setter:_cmd];
}

/*!
    Animates the view's opacity/alpha value.
    @param alphaValue the target opacity (0.0 to 1.0)
*/
- (void)setAlphaValue:(float)alphaValue
{
    [self _setTargetValue:alphaValue withKeyPath:@"alphaValue" setter:_cmd];
}

/*!
    Animates the view's background color.
    @param aColor the target background color
*/
- (void)setBackgroundColor:(CPColor)aColor
{
    [self _setTargetValue:aColor withKeyPath:@"backgroundColor" setter:_cmd];
}

/*!
    Animates the origin point of the view's frame rectangle.
    @param aFrameOrigin the target origin point
*/
- (void)setFrameOrigin:(CGPoint)aFrameOrigin
{
    [self _setTargetValue:aFrameOrigin withKeyPath:@"frameOrigin" setter:_cmd];
}

/*!
    Animates the frame rectangle of the view.
    @param aFrame the target frame rectangle
*/
- (void)setFrame:(CGRect)aFrame
{
    [self _setTargetValue:aFrame withKeyPath:@"frame" setter:_cmd];
}

/*!
    Animates the size dimensions of the view's frame rectangle.
    @param aFrameSize the target size
*/
- (void)setFrameSize:(CGSize)aFrameSize
{
    [self _setTargetValue:aFrameSize withKeyPath:@"frameSize" setter:_cmd];
}

/* @ignore */
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

/* @ignore */
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

/* @ignore */
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

/*!
    Builds and appends CSS animation descriptors corresponding to an animation action.
    @param animations the array collecting CSS animations
    @param anAction the animation action descriptor
*/
+ (void)addAnimations:(CPArray)animations forAction:(id)anAction
{
    var target = anAction.object;

    if (anAction.path)
    {
        // Path animations are handled differently. They don't map to standard properties like width/height.
        // They use CSS offset-path.
        return [self _addPathAnimation:animations forAction:anAction domElement:[target _DOMElement] identifier:[target UID]];
    }

    return [self _addAnimations:animations forAction:anAction domElement:[target _DOMElement] identifier:[target UID]];
}

/* @ignore */
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

    var calculationMode = anAction.calculationMode;
    var timingFunctions = anAction.timingfunctions;

    if (calculationMode === kCAAnimationDiscrete)
    {
        // For discrete animations, we use the steps() timing function.
        // This makes the property jump between values.
        timingFunctions = "steps(1, end)";
    }

    var css_mapping = [self _cssPropertiesForKeyPath:anAction.keypath];

    [css_mapping enumerateObjectsUsingBlock:function(aDict, anIndex, stop)
    {
        var completionFunction = (anIndex == 0) ? anAction.completion : null,
            property = [aDict objectForKey:@"property"],
            getter = [aDict objectForKey:@"value"];

        animation.addPropertyAnimation(property, getter, anAction.duration, anAction.keytimes, anAction.values, timingFunctions, completionFunction);
    }];
}

/* @ignore */
+ (void)_addPathAnimation:(CPArray)animations forAction:(id)anAction domElement:(Object)aDomElement identifier:(CPString)anIdentifier
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

    // 1. Get the SVG path string.
    var svgPath = [anAction.path SVGString];

    // 2. Set the offset-path property.
    aDomElement.style.offsetPath = "path('" + svgPath + "')";

    // 3. Set the anchor point and neutralize the static position.
    if (anAction.keypath === @"frameOrigin")
    {
        aDomElement.style.offsetAnchor = "0% 0%";
        aDomElement.style.left = "0px";
        aDomElement.style.top = "0px";
    }
    else
    {
        aDomElement.style.offsetAnchor = "50% 50%";
    }

    // 4. Set the rotation mode.
    var rotationMode = anAction.rotationMode;
    if (rotationMode === kCAAnimationRotateAuto)
    {
        aDomElement.style.offsetRotate = "auto";
    }
    else if (rotationMode === kCAAnimationRotateAutoReverse)
    {
        aDomElement.style.offsetRotate = "auto reverse";
    }
    else
    {
        aDomElement.style.offsetRotate = "0deg";
    }

    // Create a new completion handler that cleans up after the animation.
    var originalCompletion = anAction.completion;
    var cleanupCompletion = function()
    {
        // STEP 1: Run the original completion handler first.
        if (originalCompletion)
            originalCompletion();

        // STEP 2: Remove animation-specific styles to avoid leaks.
        aDomElement.style.offsetPath = null;
        aDomElement.style.offsetAnchor = null;
        aDomElement.style.offsetRotate = null;
    };

    // 5. Create the @keyframes rule, passing in our NEW cleanup handler.
    var getter = function(start, current) { return current; };
    var values = ["0%", "100%"];
    var keytimes = [0, 1];
    var timingfunctions;

    if (anAction.calculationMode === kCAAnimationPaced) {
        timingfunctions = "linear";
    } else {
        timingfunctions = [[CPAnimationContext currentContext] timingFunction];
    }

    animation.addPropertyAnimation("offset-distance", getter, anAction.duration, keytimes, values, timingfunctions, cleanupCompletion);

    // 6. Keep fill-mode as 'forwards'.
    animation.setFillMode("forwards");
}

/* @ignore */
+ (CPArray)_cssPropertiesForKeyPath:(CPString)aKeyPath
{
    return [[self _defaultCSSProperties] objectForKey:aKeyPath];
}

/*!
    Adds periodic frame updater timers for an animation action on a view hierarchy.
    @param frameUpdaters the array of active frame updaters
    @param anAction the action to update
*/
+ (void)addFrameUpdaters:(CPArray)frameUpdaters forAction:(id)anAction
{
    var rootIdentifier = [anAction.root UID];

    var frameUpdater = [frameUpdaters objectPassingTest:function(updater, idx, stop)
    {
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

/*!
    Stops and removes the frame updater with the given identifier.
    @param anIdentifier the unique identifier of the root view
*/
+ (void)stopUpdaterWithIdentifier:(CPString)anIdentifier
{
    var frameUpdater = FRAME_UPDATERS[anIdentifier];

    if (frameUpdater)
    {
        frameUpdater.stop();
        delete FRAME_UPDATERS[anIdentifier];
    }
    else
    {
        CPLog.warn("Could not find FrameUpdater with identifier " + anIdentifier);
    }
}

/*!
    Returns whether the animated property requires periodic JavaScript frame updates during animation.
    @param aKeyPath the property key path
    @return \c YES if periodic updates are required, otherwise \c NO
*/
- (BOOL)needsPeriodicFrameUpdatesForKeyPath:(CPString)aKeyPath
{
    return ((aKeyPath == @"frame" || aKeyPath == @"frameSize") &&
            (([_target hasCustomLayoutSubviews] && ![_target implementsSelector:@selector(frameRectOfView:inSuperviewSize:)])
             || [_target hasCustomDrawRect]))
            || [self wantsPeriodicFrameUpdates];
}

@end

/* @ignore */
var transformFrameToWidth = function(start, current)
{
    return current.size.width + "px";
};

/* @ignore */
var transformFrameToHeight = function(start, current)
{
    return current.size.height + "px";
};

/* @ignore */
var transformSizeToWidth = function(start, current)
{
    return current.width + "px";
};

/* @ignore */
var transformSizeToHeight = function(start, current)
{
    return current.height + "px";
};

/* @ignore */
var CSSStringFromCGAffineTransform = function(anAffineTransform)
{
    return [CPString stringWithFormat:@"matrix(%d,%d,%d,%d,%d,%d)", anAffineTransform.a, anAffineTransform.b, anAffineTransform.c, anAffineTransform.d, anAffineTransform.tx, anAffineTransform.ty];
};

/* @ignore */
var frameOriginToCSSTransformMatrix = function(start, current)
{
    var affine = CGAffineTransformMakeTranslation(current.x - start.x, current.y - start.y);

    return CSSStringFromCGAffineTransform(affine);
};

/* @ignore */
var frameToCSSTranslationTransformMatrix = function(start, current)
{
    var affine = CGAffineTransformMakeTranslation(current.origin.x - start.origin.x, current.origin.y - start.origin.y);

    return CSSStringFromCGAffineTransform(affine);
};

/*!
    @category CPView (CPAnimatablePropertyContainer)
    Adds animatable property support and animator proxy access to \c CPView.
*/
@implementation CPView (CPAnimatablePropertyContainer)

/*!
    Returns the animator class associated with this view class.
    @return the animator \c Class
*/
+ (Class)animatorClass
{
    var anim_class = CPClassFromString(CPStringFromClass(self) + "Animator");

    if (anim_class)
        return anim_class;

    return [[self superclass] animatorClass];
}

/*!
    Returns the animator proxy object for the view.
    @return the animator proxy instance
*/
- (id)animator
{
    if (!_animator)
        _animator = [[[[self class] animatorClass] alloc] initWithTarget:self];

    return _animator;
}

/*!
    Returns the default animation associated with a specified key.
    @param aKey the identifier or property key path
    @return the default \c CAAnimation, or \c nil
*/
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

/*!
    Returns the animation assigned to a key path, or the default animation if none was explicitly set.
    @param aKey the identifier or property key path
    @return the matching \c CAAnimation, or \c nil
*/
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

/*!
    Returns the dictionary of animations explicitly set on the view.
    @return the dictionary of animations
*/
- (CPDictionary)animations
{
    return _animationsDictionary;
}

/*!
    Sets the dictionary of animations for the view.
    @param animationsDict a dictionary mapping property key paths to \c CAAnimation objects
*/
- (void)setAnimations:(CPDictionary)animationsDict
{
    _animationsDictionary = [animationsDict copy];
}

/* @ignore */
- (Object)_DOMElement
{
#if PLATFORM(DOM)
    return _DOMElement;
#else
    return nil;
#endif
}

/* @ignore */
- (CPString)debug_description
{
    return [self identifier] || [self className];
}

@end

/*!
    @category CPArray (Additions)
*/
@implementation CPArray (Additions)

/*!
    Returns the first object in the array passing a predicate test function.
    @param aFunction the predicate function
    @return the matching object, or \c nil
*/
- (CPArray)objectPassingTest:(Function)aFunction
{
    var idx = [self indexOfObjectPassingTest:aFunction];

    if (idx !== CPNotFound)
        return [self objectAtIndex:idx];

    return nil;
}

@end

/* @ignore */
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

/* @ignore */
FrameUpdater.prototype.start = function()
{
    this._requestId = window.requestAnimationFrame(this._updateFunction);
};

/* @ignore */
FrameUpdater.prototype.stop = function()
{
    CPLog.warn("STOP FrameUpdater" + this._identifier);

    // window.cancelAnimationFrame support is Chrome 24, Firefox 23, IE 10, Opera 15, Safari 6.1
    if (window.cancelAnimationFrame)
        window.cancelAnimationFrame(this._requestId);

    this._stop = true;
};

/* @ignore */
FrameUpdater.prototype.updateFunction = function()
{
    return this._updateFunction;
};

/* @ignore */
FrameUpdater.prototype.identifier = function()
{
    return this._identifier;
};

/* @ignore */
FrameUpdater.prototype.description = function()
{
    return "<timer " + this._identifier + " " + this._targets.map(function(t){return [t debug_description];}) + ">";
};

/* @ignore */
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

/* @ignore */
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
        };

    return updateFrame;
};
