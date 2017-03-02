@import "CABasicAnimation.j"
@import "CAKeyframeAnimation.j"
@import "CPView.j"

@import <Foundation/CPTimer.j>

@typedef Map;

var _CPAnimationContextStack   = nil,
    _animationFlushingObserver = nil,
    _animationFrameUpdaters    = {};

@implementation CPAnimationContext : CPObject
{
    double                  _duration               @accessors(property=duration);
    CAMediaTimingFunction   _timingFunction         @accessors(property=timingFunction);
    Function                _completionHandlerAgent;
    Map                     _animationsByObject;
}

+ (id)currentContext
{
    var contextStack = [self contextStack],
        context = [contextStack lastObject];

    if (!context)
    {
        context = [[CPAnimationContext alloc] init];

        [contextStack addObject:context];
        [self _scheduleAnimationContextStackFlush];
    }

    return context;
}

+ (CPArray)contextStack
{
    if (!_CPAnimationContextStack)
        _CPAnimationContextStack = [CPArray array];

    return _CPAnimationContextStack;
}

+ (void)runAnimationGroup:(Function/*(CPAnimationContext context)*/)animationsBlock completionHandler:(Function)aCompletionHandler
{
    [CPAnimationContext beginGrouping];

    var context = [CPAnimationContext currentContext];
    [context setCompletionHandler:aCompletionHandler];

    animationsBlock(context);

    [CPAnimationContext endGrouping];
}

- (id)init
{
    self = [super init];

    _duration = 0.0;
    _timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    _completionHandlerAgent = nil;
    _animationsByObject = new Map();

    return self;
}

- (id)copy
{
    var context = [[CPAnimationContext alloc] init];
    [context setDuration:[self duration]];
    [context setTimingFunction:[self timingFunction]];
    [context setCompletionHandler:[self completionHandler]];

    return context;
}

+ (void)_scheduleAnimationContextStackFlush
{
    if (!_animationFlushingObserver)
    {
#if (DEBUG)
        CPLog.debug("create new observer");
#endif
        _animationFlushingObserver = CFRunLoopObserverCreate(2, true, 0, _animationFlushingObserverCallback, 0);
        CFRunLoopAddObserver([CPRunLoop mainRunLoop], _animationFlushingObserver);
    }
}

+ (void)beginGrouping
{
    var newContext;

    if ([_CPAnimationContextStack count])
    {
        var currentContext = [_CPAnimationContextStack lastObject];
        newContext = [currentContext copy];
    }
    else
    {
        newContext = [[CPAnimationContext alloc] init];
    }

    [_CPAnimationContextStack addObject:newContext];
}

+ (BOOL)endGrouping
{
    if (![_CPAnimationContextStack count])
        return NO;

    var context = [_CPAnimationContextStack lastObject];
    [context _flushAnimations];
    [_CPAnimationContextStack removeLastObject];

#if (DEBUG)
    CPLog.debug(_cmd + "context stack =" + _CPAnimationContextStack);
#endif
    return YES;
}

- (void)_enqueueActionForObject:(id)anObject keyPath:(id)aKeyPath targetValue:(id)aTargetValue animationCompletion:(id)animationCompletion
{
    var resolvedAction = [self _actionForObject:anObject keyPath:aKeyPath targetValue:aTargetValue animationCompletion:animationCompletion];

    if (!resolvedAction)
        return;

    var animByKeyPath = _animationsByObject.get(anObject);

    if (!animByKeyPath)
    {
        var newAnimByKeyPath = @{aKeyPath:resolvedAction};
        _animationsByObject.set(anObject, newAnimByKeyPath);
    }
    else
        [animByKeyPath setObject:resolvedAction forKey:aKeyPath];
}

- (Object)_actionForObject:(id)anObject keyPath:(CPString)aKeyPath targetValue:(id)aTargetValue animationCompletion:(Function)animationCompletion
{
    var animation,
        duration,
        animatedKeyPath,
        values,
        keyTimes,
        timingFunctions,
        objectId;
        needsPeriodicFrameUpdates,

    if (!aKeyPath || !anObject || !(animation = [anObject animationForKey:aKeyPath]) || ![animation isKindOfClass:[CAAnimation class]])
        return nil;

    duration = [animation duration] || [self duration];
    needsPeriodicFrameUpdates = [[anObject animator] needsPeriodicFrameUpdatesForKeyPath:aKeyPath];

    if (_completionHandlerAgent)
        _completionHandlerAgent.increment();

    var completionFunction = function()
    {
        if (needsPeriodicFrameUpdates)
        {
            [self stopFrameUpdaterWithIdentifier:objectId];

        }

        if (animationCompletion)
            animationCompletion();

        if (needsPeriodicFrameUpdates || animationCompletion)
            [[CPRunLoop currentRunLoop] performSelectors];

        if (_completionHandlerAgent)
            _completionHandlerAgent.decrement();
    };

    if (![animation isKindOfClass:[CAPropertyAnimation class]] || !(animatedKeyPath = [animation keyPath]))
        animatedKeyPath = aKeyPath;

    if ([animation isKindOfClass:[CAKeyframeAnimation class]])
    {
        values = [animation values];
        keyTimes = [animation keyTimes];
        timingFunctions = [animation timingFunctionsControlPoints];
    }
    else
    {
        var isBasicAnimation = [animation isKindOfClass:[CABasicAnimation class]],
            fromValue,
            toValue;

        if (!isBasicAnimation || (fromValue = [animation fromValue]) == nil)
            fromValue = [anObject valueForKey:animatedKeyPath];

        if (!isBasicAnimation || (toValue = [animation toValue]) == nil)
            toValue = aTargetValue;

        values = [fromValue, toValue];
        keyTimes = [0, 1];
        timingFunctions = isBasicAnimation ? [animation timingFunctionControlPoints] : [_timingFunction controlPoints];
    }

    return {
                object:anObject,
                keypath:animatedKeyPath,
                values:values,
                keytimes:keyTimes,
                duration:duration,
                timingfunctions:timingFunctions,
                completion:completionFunction
            };
}

- (void)_flushAnimations
{
    if (![_CPAnimationContextStack count])
        return;

    if (_animationsByObject.size == 0)
    {
        if (_completionHandlerAgent)
            _completionHandlerAgent.fire();
    }
    else
        [self _startAnimations];
}

- (void)_startAnimations
{
    var cssAnimations = [],
        timers = [];

    _animationsByObject.forEach(function(animByKeyPath, targetView)
    {
        [animByKeyPath enumerateKeysAndObjectsUsingBlock:function(aKey, anAction, stop)
        {
            [self getAnimations:cssAnimations getTimers:timers forView:targetView usingAction:anAction rootView:targetView  cssAnimate:YES];
        }];
    });

    _animationsByObject.clear();

// start timers
    var k = timers.length;
    while(k--)
    {
#if (DEBUG)
        CPLog.debug("START TIMER " + timers[k].description());
#endif
        timers[k].start();
    }

// start css animations
    var n = cssAnimations.length;
    while(n--)
    {
#if (DEBUG)
        CPLog.debug("START ANIMATION " + cssAnimations[n].description());
#endif
        cssAnimations[n].start();
    }
}

- (void)getAnimations:(CPArray)cssAnimations getTimers:(CPArray)timers forView:(CPView)aTargetView usingAction:(Object)anAction rootView:(CPView)rootView cssAnimate:(BOOL)needsCSSAnimation
{
    var keyPath = anAction.keypath,
        isFrameKeyPath = (keyPath == @"frame" || keyPath == @"frameSize"),
        customLayout = [aTargetView hasCustomLayoutSubviews],
        customDrawing = [aTargetView hasCustomDrawRect],

    if (needsCSSAnimation)
    {
        var identifier = [aTargetView UID],
            duration = anAction.duration,
            timingFunctions = anAction.timingfunctions,
            properties = [],
            valueFunctions = [],
            cssAnimation = nil;

        [cssAnimations enumerateObjectsUsingBlock:function(anim, idx, stop)
        {
            if (anim.identifier == identifier)
            {
                cssAnimation = anim;
                stop(YES);
            }
        }];

        if (cssAnimation == nil)
        {
            var domElement = [aTargetView DOMElementForKeyPath:keyPath];
            cssAnimation = new CSSAnimation(domElement, identifier);
            cssAnimations.push(cssAnimation);
        }

        var css_mapping = [[aTargetView class] _cssPropertiesForKeyPath:keyPath];

        [css_mapping enumerateObjectsUsingBlock:function(aDict, anIndex, stop)
        {
            var completionFunction = (anIndex == 0) ? anAction.completion : null;
            var property = [aDict objectForKey:@"property"],
                getter = [aDict objectForKey:@"value"];
        needsPeriodicFrameUpdates    = [[targetView animator] needsPeriodicFrameUpdatesForKeyPath:keyPath],

            cssAnimation.addPropertyAnimation(property, getter, duration, anAction.keytimes, anAction.values, timingFunctions, completionFunction);
        }];
    }

    if (needsPeriodicFrameUpdates)
    {
        var timer = [self addFrameUpdaterWithIdentifier:[rootView UID] forView:aTargetView keyPath:keyPath duration:anAction.duration];

        if (timer)
            timers.push(timer);
    }

    var subviews = [aTargetView subviews],
        count = [subviews count],
        customLayout = [aTargetView hasCustomLayoutSubviews];

    if (count && isFrameKeyPath)
    {
        var frameTimerId = [rootView UID],
        lastIndex = count - 1;

        [subviews enumerateObjectsUsingBlock:function(aSubview, idx, stop)
         {
             var action = [self actionFromAction:anAction forAnimatedSubview:aSubview],
                targetFrame = [action.values lastObject];

            if (CGRectEqualToRect([aSubview frame], targetFrame))
                return;

            if ([aSubview hasCustomDrawRect])
            {
                action.completion = function()
                {
                    [aSubview setFrame:targetFrame];
#if (DEBUG)
                    CPLog.debug(aSubview + " setFrame: " + CPStringFromRect(targetFrame));
#endif
                     if (idx == lastIndex)
                         [self stopFrameUpdaterWithIdentifier:frameTimerId];
                 };
             }

             var animate = !needsPeriodicFrameUpdates;
             [self getAnimations:cssAnimations getTimers:timers usingAction:action cssAnimate:animate];
         }];
    }
}

- (Object)actionFromAction:(Object)anAction forAnimatedSubview:(CPView)aView
{
    var targetValue = [anAction.values lastObject],
        endFrame,
        values;

    if (anAction.keypath == "frame")
        targetValue = targetValue.size;

    endFrame = [aView frameWithNewSuperviewSize:targetValue];
    values = [[aView frame], endFrame];

    return {
                object:aView,
                keypath:"frame",
                values:values,
                keytimes:[0, 1],
                duration:anAction.duration,
                timingfunctions:anAction.timingfunctions
            };
}

- (Function)addFrameUpdaterWithIdentifier:(CPString)anIdentifier forView:(CPView)aView keyPath:(CPString)aKeyPath duration:(float)aDuration
{
    var frameUpdater = _animationFrameUpdaters[anIdentifier],
        result = nil;

    if (frameUpdater == null)
    {
        frameUpdater = new FrameUpdater(anIdentifier);
        _animationFrameUpdaters[anIdentifier] = frameUpdater;
        result = frameUpdater;
    }

    frameUpdater.addTarget(aView, aKeyPath, aDuration);

    return result;
}

- (void)stopFrameUpdaterWithIdentifier:(CPString)anIdentifier
{
    var frameUpdater = _animationFrameUpdaters[anIdentifier];

    if (frameUpdater)
    {
        frameUpdater.stop();
        delete _animationFrameUpdaters[anIdentifier];
    }
    else
        CPLog.warn("Could not find FrameUpdater with identifier " + anIdentifier);
}

- (void)setCompletionHandler:(Function)aCompletionHandler
{
    if (_completionHandlerAgent)
        _completionHandlerAgent.invalidate();

    _completionHandlerAgent = aCompletionHandler ? (new CompletionHandlerAgent(aCompletionHandler)) : nil;
}

- (void)completionHandler
{
    if (!_completionHandlerAgent)
        return nil;

    return _completionHandlerAgent.completionHandler();
}

@end

@implementation CPView (CPAnimationContext)

- (CGRect)frameWithNewSuperviewSize:(CGSize)newSize
{
    var mask = [self autoresizingMask];


    if (mask == CPViewNotSizable)
        return _frame;

    var oldSize = _superview._frame.size,
        newFrame = CGRectMakeCopy(_frame),
        dX = newSize.width - oldSize.width,
        dY = newSize.height - oldSize.height,
        evenFractionX = 1.0 / ((mask & CPViewMinXMargin ? 1 : 0) + (mask & CPViewWidthSizable ? 1 : 0) + (mask & CPViewMaxXMargin ? 1 : 0)),
        evenFractionY = 1.0 / ((mask & CPViewMinYMargin ? 1 : 0) + (mask & CPViewHeightSizable ? 1 : 0) + (mask & CPViewMaxYMargin ? 1 : 0)),
        baseX = (mask & CPViewMinXMargin    ? _frame.origin.x : 0) +
                (mask & CPViewWidthSizable  ? _frame.size.width : 0) +
                (mask & CPViewMaxXMargin    ? oldSize.width - _frame.size.width - _frame.origin.x : 0),
        baseY = (mask & CPViewMinYMargin    ? _frame.origin.y : 0) +
                (mask & CPViewHeightSizable ? _frame.size.height : 0) +
                (mask & CPViewMaxYMargin    ? oldSize.height - _frame.size.height - _frame.origin.y : 0);


    if (mask & CPViewMinXMargin)
        newFrame.origin.x += dX * (baseX > 0 ? _frame.origin.x / baseX : evenFractionX);
    if (mask & CPViewWidthSizable)
        newFrame.size.width += dX * (baseX > 0 ? _frame.size.width / baseX : evenFractionX);

    if (mask & CPViewMinYMargin)
        newFrame.origin.y += dY * (baseY > 0 ? _frame.origin.y / baseY : evenFractionY);
    if (mask & CPViewHeightSizable)
        newFrame.size.height += dY * (baseY > 0 ? _frame.size.height / baseY : evenFractionY);

    return newFrame;
}

- (BOOL)hasCustomDrawRect
{
   return self._viewClassFlags & 1;
}

- (BOOL)hasCustomLayoutSubviews
{
   return self._viewClassFlags & 2;
}

@end

@implementation CAMediaTimingFunction (Additions)

- (CPArray)controlPoints
{
    return [_c1x, _c1y, _c2x, _c2y];
}

@end

@implementation CAAnimation (Additions)

- (CPArray)timingFunctionControlPoints
{
    if (_timingFunction)
        return [_timingFunction controlPoints];

    return [0, 0, 1, 1];
}

@end

@implementation CAKeyframeAnimation (Additions)

- (CPArray)timingFunctionsControlPoints
{
    var result = [CPArray array];

    [_timingFunctions enumerateObjectsUsingBlock:function(timingFunction, idx)
    {
        [result addObject:[timingFunction controlPoints]];
    }];

    return result;
}

@end

var CompletionHandlerAgent = function(aCompletionHandler)
{
    this._completionHandler = aCompletionHandler;
    this.total = 0;
    this.valid = true;
};

CompletionHandlerAgent.prototype.completionHandler = function()
{
    return this._completionHandler;
};

CompletionHandlerAgent.prototype.fire = function()
{
    this._completionHandler();
};

CompletionHandlerAgent.prototype.increment = function()
{
    this.total++;
};

CompletionHandlerAgent.prototype.decrement = function()
{
    if (this.total <= 0)
        return;

    this.total--;

    if (this.valid && this.total == 0)
    {
        this.fire();
    }
};

CompletionHandlerAgent.prototype.invalidate = function()
{
    this.valid = false;
};

var _animationFlushingObserverCallback = function()
{
#if (DEBUG)
    CPLog.debug("_animationFlushingObserverCallback");
#endif
    if ([_CPAnimationContextStack count] == 1)
    {
        var context = [_CPAnimationContextStack lastObject];
        [context _flushAnimations];
        [_CPAnimationContextStack removeLastObject];
    }

#if (DEBUG)
    CPLog.debug("_animationFlushingObserver "+_animationFlushingObserver+" stack:" + [_CPAnimationContextStack count]);
#endif

    if (_animationFlushingObserver && ![_CPAnimationContextStack count])
    {
#if (DEBUG)
        CPLog.debug("removeObserver");
#endif
        CFRunLoopObserverInvalidate([CPRunLoop mainRunLoop], _animationFlushingObserver);
        _animationFlushingObserver = nil;
    }
};
