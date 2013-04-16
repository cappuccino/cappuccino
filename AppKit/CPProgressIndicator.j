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
@import "CPWindow_Constants.j"


/*
    @global
    @group CPProgressIndicatorStyle
*/
CPProgressIndicatorBarStyle = 0;
/*
    @global
    @group CPProgressIndicatorStyle
*/
CPProgressIndicatorSpinningStyle = 1;
/*
    @global
    @group CPProgressIndicatorStyle
*/
CPProgressIndicatorHUDBarStyle = 2;

var CPProgressIndicatorSpinningStyleColors = [];

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

    BOOL                        _indeterminate;
    CPProgressIndicatorStyle    _style;

    BOOL                        _isAnimating;

    BOOL                        _isDisplayedWhenStoppedSet;
    BOOL                        _isDisplayedWhenStopped;
}

+ (CPString)defaultThemeClass
{
    return @"progress-indicator";
}

+ (CPDictionary)themeAttributes
{
    return @{
            @"indeterminate-bar-color": [CPNull null],
            @"bar-color": [CPNull null],
            @"default-height": 20,
            @"bezel-color": [CPNull null],
            @"spinning-mini-gif": [CPNull null],
            @"spinning-small-gif": [CPNull null],
            @"spinning-regular-gif": [CPNull null],
        };
}

+ (Class)_binderClassForBinding:(CPString)aBinding
{
    if (aBinding === CPValueBinding || aBinding === @"isIndeterminate")
        return [_CPProgressIndicatorBinder class];

    return [super _binderClassForBinding:aBinding];
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

        [self setNeedsLayout];
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
    Not yet implemented.
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
- (void)setIndeterminate:(BOOL)indeterminate
{
    if (_indeterminate == indeterminate)
        return;

    _indeterminate = indeterminate;

    [self updateBackgroundColor];
}

/*!
    Returns \c YES if the progress bar is indeterminate.
*/
- (BOOL)isIndeterminate
{
    return _indeterminate;
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

    [self setTheme:(_style === CPProgressIndicatorHUDBarStyle) ? [CPTheme defaultHudTheme] : [CPTheme defaultTheme]];

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
        [self setFrameSize:CGSizeMake(CGRectGetWidth([self frame]), [self valueForThemeAttribute:@"default-height"])];
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
    [self setNeedsLayout];
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    return [[CPView alloc] initWithFrame:CGRectMakeZero()];
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aViewName
{
    if (aViewName === @"bar-view" && _style !== CPProgressIndicatorSpinningStyle)
    {
        var width = CGRectGetWidth([self bounds]),
            barWidth = width * ((_doubleValue - _minValue) / (_maxValue - _minValue));

        if (barWidth > 0.0 && barWidth < 4.0)
            barWidth = 4.0;

        if (_indeterminate)
            barWidth = width;

        return CGRectMake(0, 0, barWidth, [self valueForThemeAttribute:@"default-height"]);
    }

    return nil;
}

/* @ignore */
- (void)updateBackgroundColor
{
    if ([CPProgressIndicatorSpinningStyleColors count] === 0)
    {
        CPProgressIndicatorSpinningStyleColors[CPMiniControlSize] = [self valueForThemeAttribute:@"spinning-mini-gif"];
        CPProgressIndicatorSpinningStyleColors[CPSmallControlSize] = [self valueForThemeAttribute:@"spinning-small-gif"];
        CPProgressIndicatorSpinningStyleColors[CPRegularControlSize] = [self valueForThemeAttribute:@"spinning-regular-gif"];
    }

    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    if (YES)//_isBezeled)
    {
        if (_style == CPProgressIndicatorSpinningStyle)
        {
            // This will cause the bar view to go away due to having a nil rect when _style == CPProgressIndicatorSpinningStyle.
            [self layoutEphemeralSubviewNamed:"bar-view"
                                   positioned:CPWindowBelow
              relativeToEphemeralSubviewNamed:nil];

            [self setBackgroundColor:CPProgressIndicatorSpinningStyleColors[_controlSize]];
        }
        else
        {
           [self setBackgroundColor:[self currentValueForThemeAttribute:@"bezel-color"]];

           var barView = [self layoutEphemeralSubviewNamed:"bar-view"
                                                 positioned:CPWindowBelow
                            relativeToEphemeralSubviewNamed:nil];

           if (_indeterminate)
               [barView setBackgroundColor:[self currentValueForThemeAttribute:@"indeterminate-bar-color"]];
           else
               [barView setBackgroundColor:[self currentValueForThemeAttribute:@"bar-color"]];
        }
    }
    else
        [self setBackgroundColor:nil];
}

@end


@implementation CPProgressIndicator (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _minValue                   = [aCoder decodeObjectForKey:@"_minValue"];
        _maxValue                   = [aCoder decodeObjectForKey:@"_maxValue"];
        _doubleValue                = [aCoder decodeObjectForKey:@"_doubleValue"];
        _controlSize                = [aCoder decodeObjectForKey:@"_controlSize"];
        _indeterminate              = [aCoder decodeObjectForKey:@"_indeterminate"];
        _style                      = [aCoder decodeIntForKey:@"_style"];
        _isAnimating                = [aCoder decodeObjectForKey:@"_isAnimating"];
        _isDisplayedWhenStoppedSet  = [aCoder decodeObjectForKey:@"_isDisplayedWhenStoppedSet"];
        _isDisplayedWhenStopped     = [aCoder decodeObjectForKey:@"_isDisplayedWhenStopped"];

        [self updateBackgroundColor];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    // Don't encode the background colour. It can be recreated based on the flags
    // and if encoded causes hardcoded image paths in the cib while just wasting space.
    var backgroundColor = [self backgroundColor];
    [self setBackgroundColor:nil];
    [super encodeWithCoder:aCoder];
    [self setBackgroundColor:backgroundColor];

    [aCoder encodeObject:_minValue forKey:@"_minValue"];
    [aCoder encodeObject:_maxValue forKey:@"_maxValue"];
    [aCoder encodeObject:_doubleValue forKey:@"_doubleValue"];
    [aCoder encodeObject:_controlSize forKey:@"_controlSize"];
    [aCoder encodeObject:_indeterminate forKey:@"_indeterminate"];
    [aCoder encodeInt:_style forKey:@"_style"];
    [aCoder encodeObject:_isAnimating forKey:@"_isAnimating"];
    [aCoder encodeObject:_isDisplayedWhenStoppedSet forKey:@"_isDisplayedWhenStoppedSet"];
    [aCoder encodeObject:_isDisplayedWhenStopped forKey:@"_isDisplayedWhenStopped"];
}

@end


@implementation _CPProgressIndicatorBinder : CPBinder

- (void)_updatePlaceholdersWithOptions:(CPDictionary)options forBinding:(CPString)aBinding
{
    var value = aBinding === CPValueBinding ? 0.0 : YES;

    [self _setPlaceholder:value forMarker:CPMultipleValuesMarker isDefault:YES];
    [self _setPlaceholder:value forMarker:CPNoSelectionMarker isDefault:YES];
    [self _setPlaceholder:value forMarker:CPNotApplicableMarker isDefault:YES];
    [self _setPlaceholder:value forMarker:CPNullMarker isDefault:YES];
}

- (id)valueForBinding:(CPString)aBinding
{
    if (aBinding === CPValueBinding)
        return [_source doubleValue];
    else if (aBinding === @"isIndeterminate")
        [_source isIndeterminate];
    else
        return [super valueForBinding:aBinding];
}

- (BOOL)_setValue:(id)aValue forBinding:(CPString)aBinding
{
    if (aBinding === CPValueBinding)
        [_source setDoubleValue:aValue];
    else if (aBinding === @"isIndeterminate")
        [_source setIndeterminate:aValue];
    else
        return NO;

    return YES;
}

- (void)setValue:(id)aValue forBinding:(CPString)aBinding
{
    if (![self _setValue:aValue forBinding:aBinding])
        [super setValue:aValue forBinding:aBinding];
}

- (void)setPlaceholderValue:(id)aValue withMarker:(CPString)aMarker forBinding:(CPString)aBinding
{
    if (![self _setValue:aValue forBinding:aBinding])
        [super setPlaceholderValue:aValue withMarker:aMarker forBinding:aBinding];
}

@end
