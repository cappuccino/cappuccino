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

@import "CGGeometry.j"
@import "CPImageView.j"
@import "CPView.j"


/*
    @global
    @group CPProgressIndicatorStyle
*/
CPProgressIndicatorBarStyle         = 0;
/*
    @global
    @group CPProgressIndicatorStyle
*/
CPProgressIndicatorSpinningStyle    = 1;
/*
    @global
    @group CPProgressIndicatorStyle
*/
CPProgressIndicatorHUDBarStyle      = 2;

var CPProgressIndicatorSpinningStyleColors  = nil,

    CPProgressIndicatorClassName            = nil,
    CPProgressIndicatorStyleIdentifiers     = nil,
    CPProgressIndicatorStyleSizes           = nil;

/*! 
    @ingroup appkit
    @class CPProgressIndicator

    This class is used in a Cappuccino GUI to display the progress of a
    function or task. If the duration of the task is unknown, there is
    also an indeterminate mode for the indicator.
*/
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

/*
    @ignore
*/
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
    var prefixes = [
        CPProgressIndicatorClassName + @"BezelBorder" + CPProgressIndicatorStyleIdentifiers[CPProgressIndicatorBarStyle],
        CPProgressIndicatorClassName + @"Bar" + CPProgressIndicatorStyleIdentifiers[CPProgressIndicatorBarStyle],
        CPProgressIndicatorClassName + @"BezelBorder" + CPProgressIndicatorStyleIdentifiers[CPProgressIndicatorHUDBarStyle],
        CPProgressIndicatorClassName + @"Bar" + CPProgressIndicatorStyleIdentifiers[CPProgressIndicatorHUDBarStyle]
    ];

    for (var i = 0, count = prefixes.length; i<count; i++)
    {
        var prefix = prefixes[i];
        CPProgressIndicatorStyleSizes[prefix + regularIdentifier] = [_CGSizeMake(3.0, 16.0), _CGSizeMake(1.0, 16.0), _CGSizeMake(3.0, 16.0)];
        CPProgressIndicatorStyleSizes[prefix + smallIdentifier] = [_CGSizeMake(3.0, 16.0), _CGSizeMake(1.0, 16.0), _CGSizeMake(3.0, 16.0)];
        CPProgressIndicatorStyleSizes[prefix + miniIdentifier] = [_CGSizeMake(3.0, 16.0), _CGSizeMake(1.0, 16.0), _CGSizeMake(3.0, 16.0)];
    }
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

/*
    @ignore
*/
- (void)setUsesThreadedAnimation:(BOOL)aFlag
{
}

/*!
    Starts the animation of the progress indicator in indeterminate mode.
    @param the requesting object
*/
- (void)startAnimation:(id)aSender
{
    _isAnimating = YES;
    
    [self _hideOrDisplay];
}

/*!
    Stops the animation of the progress indicator in indeterminate mode.
    @param the requesting object
*/
- (void)stopAnimation:(id)aSender
{
    _isAnimating = NO;

    [self _hideOrDisplay];
}

/*!
    Always returns \c NO. Cappuccino does not have multiple threads.
*/
- (BOOL)usesThreadedAnimation
{
    return NO;
}

// Advancing the Progress Bar
/*!
    Increases the progress of the bar by the specified value.
    @param aValue the amount to increase the progress value
*/
- (void)incrementBy:(double)aValue
{
    [self setDoubleValue:_doubleValue + aValue];
}

/*!
    Sets the progress value of the indicator.
*/
- (void)setDoubleValue:(double)aValue
{
    _doubleValue = MIN(MAX(aValue, _minValue), _maxValue);
    
    [self drawBar];
}

/*!
    Returns the value of the progress indicator.
*/
- (double)doubleValue
{
    return _doubleValue;
}

/*!
    Sets the minimum value of the progress indicator. The default is 0.0.
    @param aValue the new minimum value
*/
- (void)setMinValue:(double)aValue
{
    _minValue = aValue;
}

/*!
    Returns the minimum value of the progress indicator.
*/
- (double)minValue
{
    return _minValue;
}

/*!
    Sets the maximum value of the progress indicator. The default is 100.0.
    @param aValue the new maximum value.
*/
- (void)setMaxValue:(double)aValue
{
    _maxValue = aValue;
}

/*!
    Returns the maximum value of the progress indicator.
*/
- (double)maxValue
{
    return _maxValue;
}

// Setting the Appearance
/*!
    Sets the progress indicator's size.
    @param aControlSize the new size
*/
- (void)setControlSize:(CPControlSize)aControlSize
{
    if (_controlSize == aControlSize)
        return;
    
    _controlSize = aControlSize;

    [self updateBackgroundColor];
}

/*!
    Returns the progress indicator's size
*/
- (CPControlSize)controlSize
{
    return _controlSize;
}

/*
    Not yet implemented
*/
- (void)setControlTint:(CPControlTint)aControlTint
{
}

/*
    Not yet impemented.
*/
- (CPControlTint)controlTint
{
    return 0;
}

/*
    Not yet implemented.
*/
- (void)setBezeled:(BOOL)isBezeled
{
}

/*
    Not yet implemented.
*/
- (BOOL)isBezeled
{
    return YES;
}

/*!
    Specifies whether this progress indicator should be indeterminate or display progress based on it's max and min.
    @param isDeterminate \c YES makes the indicator indeterminate
*/
- (void)setIndeterminate:(BOOL)isIndeterminate
{
    if (_isIndeterminate == isIndeterminate)
        return;
    
    _isIndeterminate = isIndeterminate;

    [self updateBackgroundColor];
}

/*!
    Returns \c YES if the progress bar is indeterminate.
*/
- (BOOL)isIndeterminate
{
    return _isIndeterminate;
}

/*!
    Sets the progress indicator's style
    @param aStyle the style to set it to
*/
- (void)setStyle:(CPProgressIndicatorStyle)aStyle
{
    if (_style == aStyle)
        return;
    
    _style = aStyle;
    
    [self updateBackgroundColor];
}

/*!
    Resizes the indicator based on it's style.
*/
- (void)sizeToFit
{
    if (_style == CPProgressIndicatorSpinningStyle)
        [self setFrameSize:[[CPProgressIndicatorSpinningStyleColors[_controlSize] patternImage] size]];
    else
        [self setFrameSize:CGSizeMake(CGRectGetWidth([self frame]), CPProgressIndicatorStyleSizes[
            CPProgressIndicatorClassName + @"BezelBorder" + CPProgressIndicatorStyleIdentifiers[CPProgressIndicatorBarStyle] + 
            _CPControlIdentifierForControlSize(_controlSize)][0].height)];
}

/*!
    Sets whether the indicator should be displayed when it isn't animating. By default this is \c YES if the style
    is CPProgressIndicatorBarStyle, and \c NO if it's CPProgressIndicatorSpinningStyle.
    @param isDisplayedWhenStopped \c YES means the indicator will be displayed when it's not animating.
*/
- (void)setDisplayedWhenStopped:(BOOL)isDisplayedWhenStopped
{
    if (_isDisplayedWhenStoppedSet && _isDisplayedWhenStopped == isDisplayedWhenStopped)
        return;
        
    _isDisplayedWhenStoppedSet = YES;
    
    _isDisplayedWhenStopped = isDisplayedWhenStopped;
    
    [self _hideOrDisplay];
}

/*!
    Returns \c YES if the progress bar is displayed when not animating.
*/
- (BOOL)isDisplayedWhenStopped
{
    if (_isDisplayedWhenStoppedSet)
        return _isDisplayedWhenStopped;
    
    if (_style == CPProgressIndicatorBarStyle || _style == CPProgressIndicatorHUDBarStyle)
        return YES;
    
    return NO;
}

/* @ignore */
- (void)_hideOrDisplay
{
    [self setHidden:!_isAnimating && ![self isDisplayedWhenStopped]];
}

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    
    [self drawBar];
}

/* @ignore */
- (void)drawBar
{
    if (_style == CPProgressIndicatorSpinningStyle)
        return;
    
    if (!_barView)
    {
        _barView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 16.0)];        
        [self addSubview:_barView];
    }
    
    [_barView setBackgroundColor:_CPControlThreePartImagePattern(
        NO,
        CPProgressIndicatorStyleSizes,
        CPProgressIndicatorClassName,
        @"Bar",
        CPProgressIndicatorStyleIdentifiers[_style],
        _CPControlIdentifierForControlSize(_controlSize))];

    var width = CGRectGetWidth([self bounds]),
        barWidth = width * ((_doubleValue - _minValue) / (_maxValue - _minValue));

    if (barWidth > 0.0 && barWidth < 4.0)
        barWidth = 4.0;

    [_barView setFrameSize:CGSizeMake(barWidth, 16.0)];
}

/* @ignore */
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
