/*
 * CPAnimation.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

@import <Foundation/CPObject.j>
@import <Foundation/CPTimer.j>

@import "CAMediaTimingFunction.j"


/*
    @global
    @group CPAnimationCurve
*/
CPAnimationEaseInOut    = 0;
/*
    @global
    @group CPAnimationCurve
*/
CPAnimationEaseIn       = 1;
/*
    @global
    @group CPAnimationCurve
*/
CPAnimationEaseOut      = 2;
/*
    @global
    @group CPAnimationCurve
*/
CPAnimationLinear       = 3;

ACTUAL_FRAME_RATE = 0;

/*!
    @ingroup appkit
    @class CPAnimation

    Manages an animation. Contains timing and progress information.

    @par Delegate Methods

    @delegate -(BOOL)animationShouldStart:(CPAnimation)animation;
    Called at the beginning of \c -startAnimation.
    @param animation the animation that will start
    @return \c YES allows the animation to start.
    \c NO stops the animation.

    @delegate -(void)animationDidEnd:(CPAnimation)animation;
    Called when an animation has completed.
    @param animation the animation that completed

    @delegate -(void)animationDidStop:(CPAnimation)animation;
    Called when the animation was stopped (before completing).
    @param animation the animation that was stopped

    @delegate - (float)animation:(CPAnimation)animation valueForProgress:(float)progress;
    The value from this method will be returned when CPAnimation's
    \c currentValue method is called.
    @param animation the animation to obtain the curve value for
    @param progress the current animation progress
    @return the curve value
*/
@implementation CPAnimation : CPObject
{
    CPTimeInterval          _lastTime;
    CPTimeInterval          _duration;

    CPAnimationCurve        _animationCurve;
    CAMediaTimingFunction   _timingFunction;

    float                   _frameRate;
    float                   _progress;

    id                      _delegate;
    CPTimer                 _timer;
}

/*!
    Initializes the animation with a duration and animation curve.
    @param aDuration the length of the animation
    @param anAnimationCurve defines the animation's pace
    @throws CPInvalidArgumentException if an invalid animation curve is specified
*/
- (id)initWithDuration:(float)aDuration animationCurve:(CPAnimationCurve)anAnimationCurve
{
    self = [super init];

    if (self)
    {
        _progress = 0.0;
        _duration = MAX(0.0, aDuration);
        _frameRate = 60.0;

        [self setAnimationCurve:anAnimationCurve];
    }

    return self;
}

/*!
    Sets the animation's pace.
    @param anAnimationCurve the animation's pace
    @throws CPInvalidArgumentException if an invalid animation curve is specified
*/
- (void)setAnimationCurve:(CPAnimationCurve)anAnimationCurve
{
    var timingFunctionName;

    switch (anAnimationCurve)
    {
        case CPAnimationEaseInOut:
            timingFunctionName = kCAMediaTimingFunctionEaseInEaseOut;
            break;

        case CPAnimationEaseIn:
            timingFunctionName = kCAMediaTimingFunctionEaseIn;
            break;

        case CPAnimationEaseOut:
            timingFunctionName = kCAMediaTimingFunctionEaseOut;
            break;

        case CPAnimationLinear:
            timingFunctionName = kCAMediaTimingFunctionLinear;
            break;

        default:
            [CPException raise:CPInvalidArgumentException
                        reason:@"Invalid value provided for animation curve"];
            break;
    }

    _animationCurve = anAnimationCurve;
    _timingFunction = [CAMediaTimingFunction functionWithName:timingFunctionName];
}

/*!
    Returns the animation's pace
*/
- (CPAnimationCurve)animationCurve
{
    return _animationCurve;
}

/*!
    Sets the animation's length.
    @param aDuration the new animation length
    @throws CPInvalidArgumentException if \c aDuration is negative
*/
- (void)setDuration:(CPTimeInterval)aDuration
{
    if (aDuration < 0)
        [CPException raise:CPInvalidArgumentException reason:"aDuration can't be negative"];

    _duration = aDuration;
}

/*!
    Returns the length of the animation.
*/
- (CPTimeInterval)duration
{
    return _duration;
}

/*!
    Sets the animation frame rate. This is not a guaranteed frame rate. 0 means to go as fast as possible.
    @param frameRate the new desired frame rate
    @throws CPInvalidArgumentException if \c frameRate is negative
*/
- (void)setFrameRate:(float)frameRate
{
    if (frameRate < 0)
        [CPException raise:CPInvalidArgumentException reason:"frameRate can't be negative"];

    _frameRate = frameRate;
}

/*!
    Returns the desired frame rate.
*/
- (float)frameRate
{
    return _frameRate;
}

/*!
    Returns the animation's delegate
*/
- (id)delegate
{
    return _delegate;
}

/*!
    Sets the animation's delegate.
    @param aDelegate the new delegate
*/
- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

/*!
    Starts the animation. The method calls \c -animationShouldStart:
    on the delegate (if it implements it) to see if the animation
    should begin.
*/
- (void)startAnimation
{
    // If we're already animating, or our delegate stops us, animate.
    if (_timer || _delegate && [_delegate respondsToSelector:@selector(animationShouldStart:)] && ![_delegate animationShouldStart:self])
        return;

    if (_progress === 1.0)
        _progress = 0.0;

    ACTUAL_FRAME_RATE = 0;
    _lastTime = new Date();

    _timer = [CPTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(animationTimerDidFire:) userInfo:nil repeats:YES];
}

/*
    @ignore
*/
- (void)animationTimerDidFire:(CPTimer)aTimer
{
    var currentTime = new Date(),
        progress = MIN(1.0, [self currentProgress] + (currentTime - _lastTime) / (_duration * 1000.0));

    _lastTime = currentTime;

    ++ACTUAL_FRAME_RATE;

    [self setCurrentProgress:progress];

    if (progress === 1.0)
    {
        [_timer invalidate];
        _timer = nil;

        if ([_delegate respondsToSelector:@selector(animationDidEnd:)])
            [_delegate animationDidEnd:self];
    }
}

/*!
    Stops the animation before it has completed.
*/
- (void)stopAnimation
{
    if (!_timer)
        return;

    [_timer invalidate];
    _timer = nil;

    if ([_delegate respondsToSelector:@selector(animationDidStop:)])
        [_delegate animationDidStop:self];
}

/*!
    Returns \c YES if the animation
    is running.
*/
- (BOOL)isAnimating
{
    return _timer;
}

/*!
    Sets the animation's progress.
    @param aProgress the animation's progress
*/
- (void)setCurrentProgress:(float)aProgress
{
    _progress = aProgress;
}

/*!
    Returns the animation's progress
*/
- (float)currentProgress
{
    return _progress;
}

/*!
    Returns the animation's timing progress.
*/
- (float)currentValue
{
    var t = [self currentProgress];

    if ([_delegate respondsToSelector:@selector(animation:valueForProgress:)])
        return [_delegate animation:self valueForProgress:t];

    if (_animationCurve == CPAnimationLinear)
        return t;

    var c1 = [],
        c2 = [];

    [_timingFunction getControlPointAtIndex:1 values:c1];
    [_timingFunction getControlPointAtIndex:2 values:c2];

    return CubicBezierAtTime(t, c1[0], c1[1], c2[0], c2[1], _duration);
}

@end

// currently used function to determine time
// 1:1 conversion to js from webkit source files
// UnitBezier.h, WebCore_animation_AnimationBase.cpp
var CubicBezierAtTime = function(t, p1x, p1y, p2x, p2y, duration)
{
    var ax = 0,
        bx = 0,
        cx = 0,
        ay = 0,
        by = 0,
        cy = 0;
    // `ax t^3 + bx t^2 + cx t' expanded using Horner's rule.
    function sampleCurveX(t)
    {
        return ((ax * t + bx) * t + cx) * t;
    }

    function sampleCurveY(t)
    {
        return ((ay * t + by) * t + cy) * t;
    }

    function sampleCurveDerivativeX(t)
    {
        return (3.0 * ax * t + 2.0 * bx) * t + cx;
    }

    // The epsilon value to pass given that the animation is going to run over |duration| seconds. The longer the animation, the more precision is needed in the timing function result to avoid ugly discontinuities.
    function solveEpsilon(duration)
    {
        return 1.0 / (200.0 * duration);
    }

    function solve(x, epsilon)
    {
        return sampleCurveY(solveCurveX(x, epsilon));
    }

    // Given an x value, find a parametric value it came from.
    function solveCurveX(x, epsilon)
    {
        var t0,
            t1,
            t2 = x,
            x2,
            d2,
            i = 0;

        // First try a few iterations of Newton's method -- normally very fast.
        for (; i < 8; i++)
        {
            x2 = sampleCurveX(t2) - x;

            if (ABS(x2) < epsilon)
                return t2;

            d2 = sampleCurveDerivativeX(t2);

            if (ABS(d2) < 1e-6)
                break;

            t2 = t2 - x2 / d2;
        }

        // Fall back to the bisection method for reliability.
        t0 = 0.0;
        t1 = 1.0;
        t2 = x;

        if (t2 < t0)
            return t0;

        if (t2 > t1)
            return t1;

        while (t0 < t1)
        {
            x2 = sampleCurveX(t2);

            if (ABS(x2 - x) < epsilon)
                return t2;

            if (x > x2)
                t0 = t2;

            else
                t1 = t2;

            t2 = (t1 - t0) * 0.5 + t0;
        }

        return t2; // Failure.
    };
    // Calculate the polynomial coefficients, implicit first and last control points are (0,0) and (1,1).
    cx = 3.0 * p1x;
    bx = 3.0 * (p2x - p1x) - cx;
    ax = 1.0 - cx - bx;
    cy = 3.0 * p1y;
    by = 3.0 * (p2y - p1y) - cy;
    ay = 1.0 - cy - by;

    // Convert from input time to parametric value in curve, then from that to output time.
    return solve(t, solveEpsilon(duration));
};
