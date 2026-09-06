/*
 * CPAnimationContext.j
 * AppKit
 *
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

@import "CABasicAnimation.j"
@import "CAKeyframeAnimation.j"
@import "CPView.j"

@import <Foundation/CPTimer.j>
@import <Foundation/CPRunLoop.j>

@typedef Map;

/* @ignore */
var _CPAnimationContextStack   = nil,
    _animationFlushingObserver = nil;

/*!
    @ingroup appkit
    @class CPAnimationContext
    CPAnimationContext manages animation groupings, timing parameters, duration,
    and completion handlers across animated property changes.
*/
@implementation CPAnimationContext : CPObject
{
    double                  _duration               @accessors(property=duration);
    CAMediaTimingFunction   _timingFunction         @accessors(property=timingFunction);
    Function                _completionHandlerAgent;
    Map                     _animationsByObject;
}

/*!
    Returns the current active animation context on top of the context stack,
    creating one if none currently exists.
    @return the current active animation context
*/
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

/*!
    Returns the array stack of active animation contexts.
    @return the context stack array
*/
+ (CPArray)contextStack
{
    if (!_CPAnimationContextStack)
        _CPAnimationContextStack = [CPArray array];

    return _CPAnimationContextStack;
}

/*!
    Executes a block of animations within a scoped animation grouping and invokes
    a completion handler when all animations finish.
    @param animationsBlock a function taking the active \c CPAnimationContext
    @param aCompletionHandler a function to execute upon completion of all animations
*/
+ (void)runAnimationGroup:(Function/*(CPAnimationContext context)*/)animationsBlock completionHandler:(Function)aCompletionHandler
{
    [CPAnimationContext beginGrouping];

    var context = [CPAnimationContext currentContext];
    [context setCompletionHandler:aCompletionHandler];

    animationsBlock(context);

    [CPAnimationContext endGrouping];
}

/*!
    Initializes a newly allocated animation context with default duration and linear timing.
    @return the initialized animation context instance
*/
- (id)init
{
    self = [super init];

    _duration = 0.0;
    _timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    _completionHandlerAgent = nil;
    _animationsByObject = new Map();

    return self;
}

/* @ignore */
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

/*!
    Pushes a new animation context onto the context stack, inheriting duration and timing
    parameters from the previous context if available.
*/
+ (void)beginGrouping
{
    var newContext = [[CPAnimationContext alloc] init];

    if ([_CPAnimationContextStack count])
    {
        var currentContext = [_CPAnimationContextStack lastObject];
        [newContext setDuration:[currentContext duration]];
        [newContext setTimingFunction:[currentContext timingFunction]];
    }

    [_CPAnimationContextStack addObject:newContext];
}

/*!
    Flushes animations in the current context, pops it from the stack, and ends the grouping.
    @return \c YES if a context was popped, \c NO if the stack was already empty
*/
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

/* @ignore */
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

/* @ignore */
- (Object)_actionForObject:(id)anObject keyPath:(CPString)aKeyPath targetValue:(id)aTargetValue animationCompletion:(Function)animationCompletion
{
    var animation,
        duration,
        animatedKeyPath,
        values,
        keyTimes,
        timingFunctions,
        needsPeriodicFrameUpdates,
        objectId = [anObject UID];

    if (!aKeyPath || !anObject || !(animation = [anObject animationForKey:aKeyPath]) || ![animation isKindOfClass:[CAAnimation class]])
        return nil;

    duration = [animation duration] || [self duration];
    needsPeriodicFrameUpdates = [[anObject animator] needsPeriodicFrameUpdatesForKeyPath:aKeyPath];

    var animatorClass = [[anObject class] animatorClass];

    var completionFunction = function()
    {
        if (needsPeriodicFrameUpdates)
            [animatorClass stopUpdaterWithIdentifier:objectId];

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

        var path = [animation path];
        var calculationMode = [animation calculationMode] || kCAAnimationLinear; // Default to linear
        var rotationMode = [animation rotationMode];
        var tensionValues = [animation tensionValues];
        var continuityValues = [animation continuityValues];
        var biasValues = [animation biasValues];

        return {
                    object: anObject,
                    root: anObject,
                    keypath: animatedKeyPath,
                    duration: duration,
                    completion: completionFunction,

                    // Keyframe-specific properties
                    values: values,
                    keytimes: keyTimes,
                    timingfunctions: timingFunctions,
                    path: path,
                    calculationMode: calculationMode,
                    rotationMode: rotationMode,
                    tensionValues: tensionValues,
                    continuityValues: continuityValues,
                    biasValues: biasValues
                };
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

        // Return a basic animation action
        return {
                    object:anObject,
                    root:anObject,
                    keypath:animatedKeyPath,
                    values:values,
                    keytimes:keyTimes,
                    duration:duration,
                    timingfunctions:timingFunctions,
                    completion:completionFunction
                };
    }
}

/* @ignore */
- (void)_flushAnimations
{
    if (![_CPAnimationContextStack count])
        return;

    if (_animationsByObject.size == 0)
    {
        if (_completionHandlerAgent)
        {
#if (DEBUG)
            CPLog.debug("No animations are scheduled. Firing completion handler");
#endif
            _completionHandlerAgent.fire();
        }
    }
    else
        [self _startAnimations];
}

/* @ignore */
- (void)_startAnimations
{
    var cssAnimations = [],
        timers = [];

    _animationsByObject.forEach(function(animByKeyPath, targetView)
    {
        [animByKeyPath enumerateKeysAndObjectsUsingBlock:function(aKey, anAction, stop)
        {
            [self getAnimations:cssAnimations getTimers:timers usingAction:anAction cssAnimate:YES];
        }];
    });

    _animationsByObject.clear();

    var k = timers.length,
        n = cssAnimations.length;

    if (_completionHandlerAgent)
    {
        if (n == 0)
        {
#if (DEBUG)
            CPLog.debug("Animations are not needed. Firing completion handler");
#endif
            _completionHandlerAgent.fire();
        }
        else
            _completionHandlerAgent.increment(n);
    }

    // Start timers
    while(k--)
    {
#if (DEBUG)
        CPLog.debug("START TIMER " + timers[k].description());
#endif
        timers[k].start();
    }

    // Start CSS animations
    while(n--)
    {
#if (DEBUG)
        CPLog.debug("START ANIMATION " + cssAnimations[n].description());
#endif
        cssAnimations[n].start();
    }
}

/* @ignore */
- (void)getAnimations:(CPArray)cssAnimations getTimers:(CPArray)timers usingAction:(Object)anAction cssAnimate:(BOOL)needsCSSAnimation
{
    var values = anAction.values;

    if (values.length == 2)
    {
        var start = values[0],
            end = values[1];

        if (anAction.keypath    == @"frame" && CGRectEqualToRect(start, end)
            || anAction.keypath == @"frameSize" && CGSizeEqualToSize(start, end)
            || anAction.keypath == @"frameOrigin" && CGPointEqualToPoint(start, end))
            return;
    }

    var targetView                   = anAction.object,
        keyPath                      = anAction.keypath,
        isFrameKeyPath               = (keyPath == @"frame" || keyPath == @"frameSize"),
        customLayout                 = [targetView hasCustomLayoutSubviews],
        customDrawing                = [targetView hasCustomDrawRect],
        declarative_subviews_layout  = (!customLayout || [targetView implementsSelector:@selector(frameRectOfView:inSuperviewSize:)]),
        needsPeriodicFrameUpdates    = [[targetView animator] needsPeriodicFrameUpdatesForKeyPath:keyPath],
        timer                        = nil,
        animatorClass                = [[targetView class] animatorClass];

    if (needsCSSAnimation)
    {
        [animatorClass addAnimations:cssAnimations forAction:anAction];
    }

    if (needsPeriodicFrameUpdates)
    {
        [animatorClass addFrameUpdaters:timers forAction:anAction];
    }

    var subviews = [targetView subviews],
        count = [subviews count];

    if (count && isFrameKeyPath)
    {
        [subviews enumerateObjectsUsingBlock:function(aSubview, idx, stop)
        {
            if (!declarative_subviews_layout && [aSubview autoresizingMask] == 0)
                return;

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
                    if (idx == count - 1)
                        [animatorClass stopUpdaterWithIdentifier:[anAction.root UID]];
                 };
             }

             var animate = !needsPeriodicFrameUpdates;
             [self getAnimations:cssAnimations getTimers:timers usingAction:action cssAnimate:animate];
         }];
    }
}

/* @ignore */
- (Object)actionFromAction:(Object)anAction forAnimatedSubview:(CPView)aView
{
    var targetValue = [anAction.values lastObject],
        startFrame = [aView frame],
        endFrame,
        values;

    if (anAction.keypath == "frame")
        targetValue = targetValue.size;

    endFrame = [[aView superview] frameRectOfView:aView inSuperviewSize:targetValue];
    values = [startFrame, endFrame];

    return {
                object:aView,
                root:anAction.root,
                keypath:"frame",
                values:values,
                keytimes:[0, 1],
                duration:anAction.duration,
                timingfunctions:anAction.timingfunctions
            };
}

/*!
    Sets the completion handler function for the current animation grouping.
    @param aCompletionHandler a callback function executed once all animations in this context finish
*/
- (void)setCompletionHandler:(Function)aCompletionHandler
{
    if (_completionHandlerAgent)
    {
        if (aCompletionHandler === _completionHandlerAgent._completionHandler)
            return;

        _completionHandlerAgent.invalidate();
    }

    if (aCompletionHandler)
    {
        _completionHandlerAgent = new CompletionHandlerAgent(aCompletionHandler);
#if (DEBUG)
        CPLog.debug("created a new completion Agent with id " + _completionHandlerAgent.id);
#endif
    }
    else
    {
        _completionHandlerAgent = nil;
    }
}

/*!
    Returns the current completion handler function.
    @return the completion handler function, or \c nil
*/
- (Function)completionHandler
{
    if (!_completionHandlerAgent)
        return nil;

    return _completionHandlerAgent.completionHandler();
}

@end

/*!
    @category CPView (CPAnimationContext)
    Extends \c CPView to support geometric recalculations and animation flag querying.
*/
@implementation CPView (CPAnimationContext)

/*!
    Calculates the frame rectangle of a given subview within a superview of the specified size.
    @param aView the subview to layout
    @param aSize the new size of the superview
    @return the adjusted frame rectangle
*/
- (CGRect)frameRectOfView:(CPView)aView inSuperviewSize:(CGSize)aSize
{
    return [aView frameWithNewSuperviewSize:aSize];
}

/*!
    Calculates the receiver's frame rectangle when resizing its superview to the specified size.
    @param newSize the new superview size
    @return the adjusted frame rectangle
*/
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

/*!
    Returns whether the view has custom \c drawRect: implementation.
    @return \c YES if the view implements a custom \c drawRect:
*/
- (BOOL)hasCustomDrawRect
{
   return self._viewClassFlags & 1;
}

/*!
    Returns whether the view has custom \c layoutSubviews implementation.
    @return \c YES if the view implements custom \c layoutSubviews
*/
- (BOOL)hasCustomLayoutSubviews
{
   return self._viewClassFlags & 2;
}

@end

/*!
    @category CAMediaTimingFunction (Additions)
*/
@implementation CAMediaTimingFunction (Additions)

/*!
    Returns the control points of the media timing function as an array.
    @return an array containing \c [_c1x, _c1y, _c2x, _c2y]
*/
- (CPArray)controlPoints
{
    return [_c1x, _c1y, _c2x, _c2y];
}

@end

/*!
    @category CAAnimation (Additions)
*/
@implementation CAAnimation (Additions)

/*!
    Returns the control points of the animation's timing function, or linear defaults \c [0, 0, 1, 1].
    @return an array containing the control points
*/
- (CPArray)timingFunctionControlPoints
{
    if (_timingFunction)
        return [_timingFunction controlPoints];

    return [0, 0, 1, 1];
}

@end

/*!
    @category CAKeyframeAnimation (Additions)
*/
@implementation CAKeyframeAnimation (Additions)

/*!
    Returns an array containing control point arrays for each timing function in the keyframe animation.
    @return an array of control point arrays
*/
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

/* @ignore */
var COMPLETION_AGENT_ID = 0;

/* @ignore */
var CompletionHandlerAgent = function(aCompletionHandler)
{
    this._completionHandler = aCompletionHandler;
    this.total = 0;
    this.valid = true;
    this.id = COMPLETION_AGENT_ID++;
};

/* @ignore */
CompletionHandlerAgent.prototype.completionHandler = function()
{
    return this._completionHandler;
};

/* @ignore */
CompletionHandlerAgent.prototype.fire = function()
{
    if (this.valid)
    {
        this._completionHandler();
        this.valid = false;
        this.total = 0;
    }
};

/* @ignore */
CompletionHandlerAgent.prototype.increment = function(inc)
{
    this.total += inc;
};

/* @ignore */
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

/* @ignore */
CompletionHandlerAgent.prototype.invalidate = function()
{
    this.valid = false;
    this.total = 0;
    this._completionHandler = null;
};

/* @ignore */
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
