/*
 * CPProgressIndicator.j
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

import <AppKit/CGGeometry.j>
import <AppKit/CPImageView.j>
import <AppKit/CPView.j>

#include "CoreGraphics/CGGeometry.h"


CPProgressIndicatorBarStyle         = 0;
CPProgressIndicatorSpinningStyle    = 1;
CPProgressIndicatorHUDBarStyle      = 2;

var CPProgressIndicatorSpinningStyleColors  = nil,

    CPProgressIndicatorClassName            = nil,
    CPProgressIndicatorStyleIdentifiers     = nil,
    CPProgressIndicatorStyleSizes           = nil;

@implementation CPProgressIndicator : CPView
{
    double                      _minValue;
    double                      _maxValue;
    
    double                      _doubleValue;
    
    CPControlSize               _controlSize;
    
    BOOL                        _isIndeterminate;
    CPProgressIndicatorStyle    _style;
    
    BOOL                        _isAnimating;
    
    BOOL                        _isDisplayedWhenStoppedSet;
    BOOL                        _isDisplayedWhenStopped;
    
    CPView                      _barView;
}

+ (void)initialize
{
    if (self != [CPProgressIndicator class])
        return;
    
    var bundle = [CPBundle bundleForClass:self];
    
    CPProgressIndicatorSpinningStyleColors = [];
    
    CPProgressIndicatorSpinningStyleColors[CPMiniControlSize]       = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:
        [bundle pathForResource:@"CPProgressIndicator/CPProgressIndicatorSpinningStyleRegular.gif"] size:CGSizeMake(64.0, 64.0)]];
    CPProgressIndicatorSpinningStyleColors[CPSmallControlSize]      = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:
        [bundle pathForResource:@"CPProgressIndicator/CPProgressIndicatorSpinningStyleRegular.gif"] size:CGSizeMake(64.0, 64.0)]];
    CPProgressIndicatorSpinningStyleColors[CPRegularControlSize]    = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:
        [bundle pathForResource:@"CPProgressIndicator/CPProgressIndicatorSpinningStyleRegular.gif"] size:CGSizeMake(64.0, 64.0)]];

    CPProgressIndicatorBezelBorderViewPool = [];
    
    var start = CPProgressIndicatorBarStyle,
        end = CPProgressIndicatorHUDBarStyle;
    
    for (; start <= end; ++start)
    {
        CPProgressIndicatorBezelBorderViewPool[start] = [];
    
        CPProgressIndicatorBezelBorderViewPool[start][CPMiniControlSize]    = [];
        CPProgressIndicatorBezelBorderViewPool[start][CPSmallControlSize]   = [];
        CPProgressIndicatorBezelBorderViewPool[start][CPRegularControlSize]  = [];
    }
    
    CPProgressIndicatorClassName = [self className];
    
    
    CPProgressIndicatorStyleIdentifiers = [];
    
    CPProgressIndicatorStyleIdentifiers[CPProgressIndicatorBarStyle]        = @"Bar";
    CPProgressIndicatorStyleIdentifiers[CPProgressIndicatorSpinningStyle]   = @"Spinny";
    CPProgressIndicatorStyleIdentifiers[CPProgressIndicatorHUDBarStyle]     = @"HUDBar";
    
    var regularIdentifier = _CPControlIdentifierForControlSize(CPRegularControlSize),
        smallIdentifier = _CPControlIdentifierForControlSize(CPSmallControlSize),
        miniIdentifier = _CPControlIdentifierForControlSize(CPMiniControlSize);

    CPProgressIndicatorStyleSizes = [];

    // Bar Sttyle
    var prefix = CPProgressIndicatorClassName + @"BezelBorder" + CPProgressIndicatorStyleIdentifiers[CPProgressIndicatorBarStyle];

    CPProgressIndicatorStyleSizes[prefix + regularIdentifier] = [_CGSizeMake(3.0, 15.0), _CGSizeMake(1.0, 15.0), _CGSizeMake(3.0, 15.0)];
    CPProgressIndicatorStyleSizes[prefix + smallIdentifier] = [_CGSizeMake(3.0, 15.0), _CGSizeMake(1.0, 15.0), _CGSizeMake(3.0, 15.0)];
    CPProgressIndicatorStyleSizes[prefix + miniIdentifier] = [_CGSizeMake(3.0, 15.0), _CGSizeMake(1.0, 15.0), _CGSizeMake(3.0, 15.0)];

    prefix = CPProgressIndicatorClassName + @"Bar" + CPProgressIndicatorStyleIdentifiers[CPProgressIndicatorBarStyle];

    CPProgressIndicatorStyleSizes[prefix + regularIdentifier] = _CGSizeMake(1.0, 9.0);
    CPProgressIndicatorStyleSizes[prefix + smallIdentifier] = _CGSizeMake(1.0, 9.0);
    CPProgressIndicatorStyleSizes[prefix + miniIdentifier] = _CGSizeMake(1.0, 9.0);

    // HUD Bar Style
    prefix = CPProgressIndicatorClassName + @"BezelBorder" + CPProgressIndicatorStyleIdentifiers[CPProgressIndicatorHUDBarStyle];

    CPProgressIndicatorStyleSizes[prefix + regularIdentifier] = [_CGSizeMake(3.0, 15.0), _CGSizeMake(1.0, 15.0), _CGSizeMake(3.0, 15.0)];
    CPProgressIndicatorStyleSizes[prefix + smallIdentifier] = [_CGSizeMake(3.0, 15.0), _CGSizeMake(1.0, 15.0), _CGSizeMake(3.0, 15.0)];
    CPProgressIndicatorStyleSizes[prefix + miniIdentifier] = [_CGSizeMake(3.0, 15.0), _CGSizeMake(1.0, 15.0), _CGSizeMake(3.0, 15.0)];

    prefix = CPProgressIndicatorClassName + @"Bar" + CPProgressIndicatorStyleIdentifiers[CPProgressIndicatorHUDBarStyle];

    CPProgressIndicatorStyleSizes[prefix + regularIdentifier] = _CGSizeMake(1.0, 9.0);
    CPProgressIndicatorStyleSizes[prefix + smallIdentifier] = _CGSizeMake(1.0, 9.0);
    CPProgressIndicatorStyleSizes[prefix + miniIdentifier] = _CGSizeMake(1.0, 9.0);
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _minValue = 0.0;
        _maxValue = 100.0;
        
        _doubleValue = 0.0;
        
        _style = CPProgressIndicatorBarStyle;
        _isDisplayedWhenStoppedSet = NO;
        
        _controlSize = CPRegularControlSize;
        
        [self updateBackgroundColor];
        [self drawBar];
    }
    
    return self;
}

- (void)setUsesThreadedAnimation:(BOOL)aFlag
{
}

- (void)startAnimation:(id)aSender
{
    _isAnimating = YES;
    
    [self _hideOrDisplay];
}

- (void)stopAnimation:(id)aSender
{
    _isAnimating = NO;

    [self _hideOrDisplay];
}

- (BOOL)usesThreadedAnimation
{
    return NO;
}

// Advancing the Progress Bar

- (void)incrementBy:(double)aValue
{
    [self setDoubleValue:_doubleValue + aValue];
}

- (void)setDoubleValue:(double)aValue
{
    _doubleValue = MIN(MAX(aValue, _minValue), _maxValue);
    
    [self drawBar];
}

- (double)doubleValue
{
    return _doubleValue;
}

- (void)setMinValue:(double)aValue
{
    _minValue = aValue;
}

- (double)minValue
{
    return _minValue;
}

- (void)setMaxValue:(double)aValue
{
    _maxValue = aValue;
}

- (double)maxValue
{
    return _maxValue;
}

// Setting the Appearance

- (void)setControlSize:(CPControlSize)aControlSize
{
    if (_controlSize == aControlSize)
        return;
    
    _controlSize = aControlSize;

    [self updateBackgroundColor];
}

- (CPControlSize)controlSize
{
    return _controlSize;
}

- (void)setControlTint:(CPControlTint)aControlTint
{
}

- (CPControlTint)controlTint
{
    return 0;
}

- (void)setBezeled:(BOOL)isBezeled
{
}

- (BOOL)isBezeled
{
    return YES;
}

- (void)setIndeterminate:(BOOL)isIndeterminate
{
    if (_indeterminate == isIndeterminate)
        return;
    
    _isIndeterminate = isIndeterminate;

    [self updateBackgroundColor];
}

- (BOOL)isIndeterminate
{
    return _isIndeterminate;
}

- (void)setStyle:(CPProgressIndicatorStyle)aStyle
{
    if (_style == aStyle)
        return;
    
    _style = aStyle;
    
    [self updateBackgroundColor];
}

- (void)sizeToFit
{
    if (_style == CPProgressIndicatorSpinningStyle)
        [self setFrameSize:[[CPProgressIndicatorSpinningStyleColors[_controlSize] patternImage] size]];
    else
        [self setFrameSize:CGSizeMake(CGRectGetWidth([self frame]), CPProgressIndicatorStyleSizes[
            CPProgressIndicatorClassName + @"BezelBorder" + CPProgressIndicatorStyleIdentifiers[CPProgressIndicatorBarStyle] + 
            _CPControlIdentifierForControlSize(_controlSize)][0].height)];
}

- (void)setDisplayedWhenStopped:(BOOL)isDisplayedWhenStopped
{
    if (_isDisplayedWhenStoppedSet && _isDisplayedWhenStopped == isDisplayedWhenStopped)
        return;
        
    _isDisplayedWhenStoppedSet = YES;
    
    _isDisplayedWhenStopped = isDisplayedWhenStopped;
    
    [self _hideOrDisplay];
}

- (BOOL)isDisplayedWhenStopped
{
    if (_isDisplayedWhenStoppedSet)
        return _isDisplayedWhenStopped;
    
    if (_style == CPProgressIndicatorBarStyle || _style == CPProgressIndicatorHUDBarStyle)
        return YES;
    
    return NO;
}

- (void)_hideOrDisplay
{
    [self setHidden:!_isAnimating && ![self isDisplayedWhenStopped]];
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    
    [self drawBar];
}

- (void)drawBar
{
    if (_style == CPProgressIndicatorSpinningStyle)
        return;
    
    if (!_barView)
    {
        _barView = [[CPView alloc] initWithFrame:CGRectMake(2.0, 2.0, 0.0, 9.0)];
        
        [_barView setBackgroundColor:[CPColor redColor]];
        
        [self addSubview:_barView];
    }
    
    [_barView setBackgroundColor:_CPControlColorWithPatternImage(
        CPProgressIndicatorStyleSizes,
        CPProgressIndicatorClassName,
        @"Bar",
        CPProgressIndicatorStyleIdentifiers[_style],
        _CPControlIdentifierForControlSize(_controlSize))];
                    
    [_barView setFrameSize:CGSizeMake(CGRectGetWidth([self bounds]) * (_doubleValue - _minValue) / (_maxValue - _minValue) - 4.0, 9.0)];
}

- (void)updateBackgroundColor
{
    if (YES)//_isBezeled)
    {
        if (_style == CPProgressIndicatorSpinningStyle)
        {
            [_barView removeFromSuperview];
            
            _barView = nil;
            
            [self setBackgroundColor:CPProgressIndicatorSpinningStyleColors[_controlSize]];
        }
        else
        {
            [self setBackgroundColor:_CPControlThreePartImagePattern(
                NO,
                CPProgressIndicatorStyleSizes,
                CPProgressIndicatorClassName,
                @"BezelBorder",
                CPProgressIndicatorStyleIdentifiers[_style],
                _CPControlIdentifierForControlSize(_controlSize))];
                
            [self drawBar];
        }
    }
    else
        [self setBackgroundColor:nil];
}

@end
