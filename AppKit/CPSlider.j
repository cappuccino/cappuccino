/*
 * CPSlider.j
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

@import "CPControl.j"


var CPSliderHorizontalKnobImage         = nil,
    CPSliderHorizontalBarLeftImage      = nil,
    CPSliderHorizontalBarRightImage     = nil,
    CPSliderHorizontalBarCenterImage    = nil;

/*! @class CPSlider

    An CPSlider displays, and allows control of, some value in the application. It represents a continuous stream of values of type <code>float</code>, which can be retrieved by the method <code>floatValue</code> and set by the method <code>setFloatValue:</code>.
*/
@implementation CPSlider : CPControl
{
    double      _minValue;
    double      _maxValue;
    double      _altIncrementValue;
    BOOL        _isVertical;
    
    CPView      _bar;
    CPView      _knob;

    CPImageView _standardKnob;
    CPView      _standardVerticalBar;
    CPView      _standardHorizontalBar;
}

/*
    @ignore
*/
+ (void)initialize
{
    if (self != [CPSlider class])
        return;

    var bundle = [CPBundle bundleForClass:self];
    
    CPSliderKnobImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPSlider/CPSliderKnobRegular.png"] size:CPSizeMake(11.0, 11.0)],
    CPSliderKnobPushedImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPSlider/CPSliderKnobRegularPushed.png"] size:CPSizeMake(11.0, 11.0)],
    CPSliderHorizontalBarLeftImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPSlider/CPSliderTrackHorizontalLeft.png"] size:CPSizeMake(2.0, 4.0)],
    CPSliderHorizontalBarRightImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPSlider/CPSliderTrackHorizontalRight.png"] size:CPSizeMake(2.0, 4.0)],
    CPSliderHorizontalBarCenterImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"CPSlider/CPSliderTrackHorizontalCenter.png"] size:CPSizeMake(1.0, 4.0)];
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        _value = 50.0;
        _minValue = 0.0;
        _maxValue = 100.0;
    
        _bar = [self bar];
        _knob = [self knob];
        _knobSize = [[self knobImage] size];
        _isVertical = [self isVertical];
        
        [self setContinuous:YES];
        
        [_knob setFrameOrigin:[self knobPosition]];
        
        [self addSubview:_bar];
        [self addSubview:_knob];
    }
    
    return self;
}
    
- (void)setFrameSize:(CGSize)aSize
{
    if (aSize.height > 21.0)
        aSize.height = 21.0;
    
    if (_isVertical != [self isVertical])
    {
        _isVertical = [self isVertical];
        
        var bar = [self bar],
            knob = [self knob];
        
        if (_bar != bar)
            [self replaceSubview:_bar = bar withView:_bar];
        
        if (_knob != knob)
        {
            [self replaceSubview:knob withView:_knob];
            
            _knob = knob;
            [_knob setFrameOrigin:[self knobPosition]];
        }
    }
    
    [super setFrameSize:aSize];
    
    [_knob setFrameOrigin:[self knobPosition]];
}

/*!
    Returns the value by which the slider will be
    incremented if the user holds down the <code>ALT</code>s key.
*/
- (double)altIncrementValue
{
    return _altIncrementValue;
}

/*!
    Sets the value the slider will be incremented if the user holds the <code>ALT</code> key.
*/
- (void)setAltIncrementValue:(double)anIncrementValue
{
    _altIncrementValue = anIncrementValue;
}

/*!
    Returns whether the control can continuously send its action messages.
*/
- (BOOL)isContinuous
{
    return (_sendActionOn & CPLeftMouseDraggedMask) != 0;
}

/*!
    Sets whether the cell can continuously send its action messages.
 */
- (void)setContinuous:(BOOL)flag
{
    if (flag)
        _sendActionOn |= CPLeftMouseDraggedMask;
    else 
        _sendActionOn &= ~CPLeftMouseDraggedMask;
}

/*!
    Returns the thickness of the slider's knob. This value is in pixels, 
    and is the size of the knob along the slider's track.
*/
- (float)knobThickness
{
    return CPRectGetWidth([_knob frame]);
}

/*
    @ignore
*/
- (CPImage)leftTrackImage
{
    return CPSliderHorizontalBarLeftImage;
}

/*
    @ignore
*/
- (CPImage)rightTrackImage
{
    return CPSliderHorizontalBarRightImage;
}

/*
    @ignore
*/
- (CPImage)centerTrackImage
{
    return CPSliderHorizontalBarCenterImage
}

/*
    @ignore
*/
- (CPImage)knobImage
{
    return CPSliderKnobImage;
}

/*
    @ignore
*/
- (CPImage)pushedKnobImage
{
    return CPSliderKnobPushedImage;
}

/*!
    Returns the slider's knob.
*/
- (CPView)knob
{
    if (!_standardKnob)
    {
        var knobImage = [self knobImage],
            knobSize = [knobImage size];
        
        _standardKnob = [[CPImageView alloc] initWithFrame:CPRectMake(0.0, 0.0, knobSize.width, knobSize.height)];
        
        [_standardKnob setHitTests:NO];
        [_standardKnob setImage:knobImage];
    }
    
    return _standardKnob;
}

/*!
    Returns the slider's bar.
*/
- (CPView)bar
{
    // FIXME: veritcal.
    if ([self isVertical])
        return nil;
    else
    {
        if (!_standardHorizontalBar)
        {
            var frame = [self frame],
                barFrame = CPRectMake(0.0, 0.0, CPRectGetWidth(frame), 4.0);
                
            _standardHorizontalBar = [[CPView alloc] initWithFrame:barFrame];
            
            [_standardHorizontalBar setBackgroundColor:[CPColor colorWithPatternImage:[[CPThreePartImage alloc] initWithImageSlices:
                [[self leftTrackImage], [self centerTrackImage], [self rightTrackImage]] isVertical:NO]]];

            [_standardHorizontalBar setFrame:CPRectMake(0.0, (CPRectGetHeight(frame) - CPRectGetHeight(barFrame)) / 2.0, CPRectGetWidth(_isVertical ? barFrame : frame), CPRectGetHeight(_isVertical ? frame : barFrame))];
            [_standardHorizontalBar setAutoresizingMask:_isVertical ? CPViewHeightSizable : CPViewWidthSizable];
        }
        
        return _standardHorizontalBar;
    }
}

/*!
    Returns <code>YES</code> if the slider is vertical.
*/
- (BOOL)isVertical
{
    var frame = [self frame];
    
    if (CPRectGetWidth(frame) == CPRectGetHeight(frame))
        return -1;
    
    return CPRectGetWidth(frame) < CPRectGetHeight(frame);
}

/*!
    Returns the slider's maximum value
*/
- (double)maxValue
{
    return _maxValue;
}

/*!
    Returns the slider's minimum value
*/
- (double)minValue
{
    return _minValue;
}

/*!
    Sets the slider's maximum value
    @param aMaxValue the new maximum value
*/
- (void)setMaxValue:(double)aMaxValue
{
    _maxValue = aMaxValue;
}

/*!
    Sets the slider's minimum value
    @param aMinValue the new minimum value
*/
- (void)setMinValue:(double)aMinValue
{
    _minValue = aMinValue;
}

/*!
    Sets the slider's value
    @param aValue the new slider value
    @deprecated Use setFloatValue, setObjectValue, etc
*/
- (void)setValue:(double)aValue
{
    [self setObjectValue:aValue];
}

/*!
    Returns the slider's value
    @deprecated Use floatValue, objectValue, etc
*/
- (double)value
{
    return [self floatValue];
}

- (void)setObjectValue:(id)anObject
{
    [super setObjectValue:anObject];
    
    if (_knob)
        [_knob setFrameOrigin:[self knobPosition]];
}

/*
    Returns the knob's position
    @ignore
*/
- (CGPoint)knobPosition
{
    if ([self isVertical])
        return CPPointMake(0.0, 0.0);
    else
        return CPPointMake(
            (([self floatValue] - _minValue) / (_maxValue - _minValue)) * (CPRectGetWidth([self frame]) - CPRectGetWidth([_knob frame])), 
            (CPRectGetHeight([self frame]) - CPRectGetHeight([_knob frame])) / 2.0);
}

/*
    @ignore
*/
- (float)valueForKnobPosition:(CGPoint)aPoint
{
    if ([self isVertical])
        return 0.0;
    else
        return MAX(MIN((aPoint.x) * (_maxValue - _minValue) / ( CPRectGetWidth([self frame]) - CPRectGetWidth([_knob frame]) ) + _minValue, _maxValue), _minValue);
}

- (CGPoint)constrainKnobPosition:(CGPoint)aPoint
{
    //FIXME
    aPoint.x -= _knobSize.width / 2.0;
    return CPPointMake(MAX(MIN(CPRectGetWidth([self bounds]) - _knobSize.width, aPoint.x), 0.0), (CPRectGetHeight([self bounds]) - CPRectGetHeight([_knob frame])) / 2.0);
}

- (BOOL)tracksMouseOutsideOfFrame
{
    return YES;
}

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    [[self knob] setImage:[self pushedKnobImage]];
    
    [_knob setFrameOrigin:[self constrainKnobPosition:aPoint]];

    [super setObjectValue:[self valueForKnobPosition:[_knob frame].origin]];
    
    return YES;   
}

- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)aPoint
{
    [_knob setFrameOrigin:[self constrainKnobPosition:aPoint]];
    
    [super setObjectValue:[self valueForKnobPosition:[_knob frame].origin]];
    
    return YES;
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    [[self knob] setImage:[self knobImage]];
    
    if ([_target respondsToSelector:@selector(sliderDidFinish:)])
        [_target sliderDidFinish:self];
}

@end

var CPSliderMinValueKey     = "CPSliderMinValueKey",
    CPSliderMaxValueKey     = "CPSliderMaxValueKey",
    CPSliderAltIncrValueKey = "CPSliderAltIncrValueKey",
    CPSliderIsVerticalKey   = "CPSliderIsVerticalKey";

@implementation CPSlider (CPCoding)

/*!
    Initializes the slider from the data in a coder.
    @param aCoder the coder from which to read the data
    @return the initialized slider
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        _minValue = [aCoder decodeDoubleForKey:CPSliderMinValueKey];
        _maxValue = [aCoder decodeDoubleForKey:CPSliderMaxValueKey];
        _altIncrementValue = [aCoder decodeDoubleForKey:CPSliderAltIncrValueKey];
        _isVertical = [aCoder decodeDoubleForKey:CPSliderIsVerticalKey];
    
        _bar = [self bar];
        _knob = [self knob];
        _knobSize = [[self knobImage] size];
        _isVertical = [self isVertical];
        
        [_knob setFrameOrigin:[self knobPosition]];
        
        [self addSubview:_bar];
        [self addSubview:_knob];
    }
    
    return self;
}

/*!
    Writes out the slider's instance information to a coder.
    @param aCoder the coder to which to write the data
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    var subviews = _subviews;
    
    _subviews = [];
         
    [super encodeWithCoder:aCoder];
    
    _subviews = subviews;
    
    [aCoder encodeDouble:_minValue forKey:CPSliderMinValueKey];
    [aCoder encodeDouble:_maxValue forKey:CPSliderMaxValueKey];
    [aCoder encodeDouble:_altIncrementValue forKey:CPSliderAltIncrValueKey];
    [aCoder encodeBool:_isVertical forKey:CPSliderIsVerticalKey];
}

@end
