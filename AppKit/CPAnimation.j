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

import <Foundation/CPObject.j>

import "CAMediaTimingFunction.j"


CPAnimationEaseInOut    = 0,
CPAnimationEaseIn       = 1,
CPAnimationEaseOut      = 2,
CPAnimationLinear       = 3;

ACTUAL_FRAME_RATE = 0;

@implementation CPAnimation : CPObject
{
    CPTimeInterval          _startTime;
    CPTimeInterval          _duration;
    
    CPAnimationCurve        _animationCurve;
    CAMediaTimingFunction   _timingFunction;
    
    float                   _frameRate;
    CPAnimationProgress     _progress;
    
    id                      _delegate;
    CPTimer                 _timer;
}

- (id)initWithDuration:(float)aDuration animationCurve:(CPAnimationCurve)anAnimationCurve
{
    self = [super init];
    
    if (self)
    {
        _duration = aDuration;
        _animationCurve = anAnimationCurve;
        _frameRate = 60.0;
    }
    
    return self;
}

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
    }
    
    _timingFunction = [CAMediaTimingFunction functionWithName:timingFunctionName];
}

- (CPAnimationCurve)animationCurve
{
    return _animationCurve;
}

- (void)setDuration:(CPTimeInterval)aDuration
{
    _duration = aDuration;
}

- (CPTimeInterval)duration
{
    return _duration;
}

- (void)setFramesPerSecond:(float)framesPerSecond
{
    _frameRate = framesPerSecond;
}

- (float)frameRate
{
    return _frameRate;
}

- (id)delegate
{
    return _delegate;
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

- (void)startAnimation
{
    // If we're already animating, or our delegate stops us, animate.
    if (_timer || _delegate && ![_delegate animationShouldStart:self])
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

- (void)stopAnimation
{
    if (!_timer)
        return;
    
    window.clearTimeout(_timer);
    _timer = nil;
    
    [_delegate animationDidStop:self];
}

- (BOOL)isAnimating
{
    return _timer;
}

- (void)setCurrentProgress:(CPAnimationProgress)aProgress
{
    _progress = aProgress;
}

- (CPAnimationProgress)currentProgress
{
    return _progress;
}

- (float)currentValue
{
    if ([_delegate respondsToSelector:@selector(animation:valueForProgress:)])
        return [_delegate animation:self valueForProgress:_progress];
    
    if (_animationCurve == CPAnimationLinear)
        return _progress;
    
    alert("IMPLEMENT ANIMATION CURVES!!!");
}

@end
