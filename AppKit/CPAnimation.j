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

/*! @class CPAnimation
    Manages an animation. Contains timing and progress information.

    @par Delegate Methods
    
    @delegate -(BOOL)animationShouldStart:(CPAnimation)animation;
    Called at the beginning of <code>startAnimation</code>.
    @param animation the animation that will start
    @return <code>YES</code> allows the animation to start.
    <code>NO</code> stops the animation.

    @delegate -(void)animationDidEnd:(CPAnimation)animation;
    Called when an animation has completed.
    @param animation the animation that completed

    @delegate -(void)animationDidStop:(CPAnimation)animation;
    Called when the animation was stopped (before completing).
    @param animation the animation that was stopped

    @delegate - (float)animation:(CPAnimation)animation valueForProgress:(float)progress;
    The value from this method will be returned when <objj>CPAnimation</objj>'s
    <code>currentValue</code> method is called.
    @param animation the animation to obtain the curve value for
    @param progress the current animation progress
    @return the curve value
*/
@implementation CPAnimation : CPObject
{
    CPTimeInterval          _startTime;
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
        _duration = MAX(0.0, aDuration);
        _animationCurve = anAnimationCurve;
        _frameRate = 60.0;
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
    _animationCurve = anAnimationCurve;
    
    var timingFunctionName = kCAMediaTimingFunctionLinear;
    
    switch (_animationCurve)
    {
        case CPAnimationEaseInOut:  timingFunctionName = kCAMediaTimingFunctionEaseInEaseOut;
                                    break;
                                    
        case CPAnimationEaseIn:     timingFunctionName = kCAMediaTimingFunctionEaseIn;
                                    break;
                                    
        case CPAnimationEaseOut:    timingFunctionName = kCAMediaTimingFunctionEaseOut;
                                    break;

        default:                    [CPException raise:CPInvalidArgumentException
                                                reason:"Invalid value provided for animation curve"];
                                    break;
    }
    
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
    @throws CPInvalidArgumentException if <code>aDuration</code> is negative
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
    @throws CPInvalidArgumentException if <code>frameRate</code> is negative
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
    Starts the animation. The method calls <code>animationShouldStart:</code>
    on the delegate (if it implements it) to see if the animation
    should begin.
*/
- (void)startAnimation
{
    // If we're already animating, or our delegate stops us, animate.
    if (_timer || _delegate && [_delegate respondsToSelector:@selector(animationShouldStart)] && ![_delegate animationShouldStart:self])
        return;
    
    _progress = 0.0;
    ACTUAL_FRAME_RATE = 0;
    _startTime = new Date();
    // FIXME: THIS SHOULD BE A CPTIMER!!!
    _timer = window.setInterval(function() {
        [self animationTimerDidFire:_timer];
        [[CPRunLoop currentRunLoop] performSelectors];
    }, 1); // must be 1ms not 0 for IE. //_duration * 1000 / _frameRate);
}

/*
    @ignore
*/
- (void)animationTimerDidFire:(CPTimer)aTimer
{
    var elapsed = new Date() - _startTime,
        progress = MIN(1.0, 1.0 - (_duration - elapsed / 1000.0) / _duration);

    ++ACTUAL_FRAME_RATE;
    
    [self setCurrentProgress:progress];
    
    if (progress == 1.0)
    {
        window.clearTimeout(_timer);
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
    
    window.clearTimeout(_timer);
    _timer = nil;
    
    if ([_delegate respondsToSelector:@selector(animationDidStop:)])
        [_delegate animationDidStop:self];
}

/*!
    Returns <code>YES</code> if the animation
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
    if ([_delegate respondsToSelector:@selector(animation:valueForProgress:)])
        return [_delegate animation:self valueForProgress:_progress];
    
    if (_animationCurve == CPAnimationLinear)
        return _progress;
    
    alert("IMPLEMENT ANIMATION CURVES!!!");
}

@end
