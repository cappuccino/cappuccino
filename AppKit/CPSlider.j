/*
 * CPSlider.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
 *
 * Adapted by Didier Korthoudt
 * Copyright 2018 <didier.korthoudt@uliege.be>
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
@import "CPWindow_Constants.j"


/*! SLIDER STATES */

@typedef CPSliderType
CPLinearSlider   = 0;
CPCircularSlider = 1;

/*! SLIDER TICK MARK POSITION */

@typedef CPTickMarkPosition
CPTickMarkPositionBelow    = 0;
CPTickMarkPositionAbove    = 1;
CPTickMarkPositionLeading  = CPTickMarkPositionAbove;
CPTickMarkPositionTrailing = CPTickMarkPositionBelow;

/*! Ticked sliders specific states */

CPThemeStateTickedSlider           = CPThemeState("ticked-slider");
CPThemeStateAboveLeftTickedSlider  = CPThemeState("above-left-ticked-slider");
CPThemeStateBelowRightTickedSlider = CPThemeState("below-right-ticked-slider");

/*! Tick mark affinity distance */
var AFFINITY = 5;

/*!
    @ingroup appkit
*/

@implementation CPSlider : CPControl
{
    double              _minValue;
    double              _maxValue;
    double              _altIncrementValue;

    CPInteger           _isVertical;
    BOOL                _isCircular;
    BOOL                _isTicked;
    BOOL                _isContinuous;

    CGSize              _dragOffset;

    CPSliderType        _sliderType                 @accessors(property=sliderType);
    BOOL                _allowsTickMarkValuesOnly   @accessors(property=allowsTickMarkValuesOnly);
    CPTickMarkPosition  _tickMarkPosition           @accessors(property=tickMarkPosition);
    CPInteger           _numberOfTickMarks          @accessors(property=numberOfTickMarks);

    CPMutableArray      _cachedTickMarksRects;
    CPMutableArray      _cachedTickMarksSegments;
    CPMutableArray      _cachedTickMarksValues;
    CPInteger           _currentTickMarkSegment;
    CPInteger           _closestTickMarkIndex;
    CPInteger           _affinityPoint;
    BOOL                _canStickOnTickMarks;
    BOOL                _stickingOnTickMark;
}

+ (CPString)defaultThemeClass
{
    return "slider";
}

+ (CPDictionary)themeAttributes
{
    return @{
             @"left-track-color": [CPNull null],
             @"knob-color": [CPNull null],
             @"knob-size": CGSizeMakeZero(),
             @"knob-offset": 0.0,
             @"track-width": 0.0,
             @"track-color": [CPNull null],
             @"direct-nib2cib-adjustment": NO,
             @"tick-mark-size": CGSizeMakeZero(),
             @"tick-mark-color": [CPNull null],
             @"tick-mark-margin": 0,
             @"top-margin": 0,
             @"bottom-margin": 0,
             @"ib-size": -1
        };
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
    {
        _minValue = 0.0;
        _maxValue = 100.0;

        [self setObjectValue:50.0];
        [self setContinuous:YES];
        [self setNumberOfTickMarks:0];
        [self setSliderType:CPLinearSlider];

        [self _refreshCachesAndStates];
    }

    return self;
}

- (void)setMinValue:(float)aMinimumValue
{
    if (_minValue === aMinimumValue)
        return;

    _minValue = aMinimumValue;

    var doubleValue = [self doubleValue];

    if (doubleValue < _minValue)
        [self setDoubleValue:_minValue];

    [self _refreshCachesAndStates];

    // The relative position may have (did) change.
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (float)minValue
{
    return _minValue;
}

- (void)setMaxValue:(float)aMaximumValue
{
    if (_maxValue === aMaximumValue)
        return;

    _maxValue = aMaximumValue;

    var doubleValue = [self doubleValue];

    if (doubleValue > _maxValue)
        [self setDoubleValue:_maxValue];

    [self _refreshCachesAndStates];

    // The relative position may have (did) change.
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (float)maxValue
{
    return _maxValue;
}

- (void)setObjectValue:(id)aValue
{
    [self willChangeValueForKey:@"objectValue"];
    [super setObjectValue:MIN(MAX(aValue, _minValue), _maxValue)];
    [self didChangeValueForKey:@"objectValue"];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (void)setSliderType:(CPSliderType)aSliderType
{
    if (aSliderType === _sliderType)
        return;

    _sliderType = aSliderType;

    [self _refreshCachesAndStates];
}

- (CPSliderType)sliderType
{
    return _sliderType;
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    var trackRect = CGRectCreateCopy(bounds);

    if (_isCircular)
    {
        var tickMarkMargin = [self currentValueForThemeAttribute:@"tick-mark-margin"];

        trackRect.size.width = MIN(trackRect.size.width, trackRect.size.height) - tickMarkMargin * 2;
        trackRect.size.height = trackRect.size.width;

        trackRect.origin.x = tickMarkMargin;
        trackRect.origin.y = tickMarkMargin;
    }
    else
    {
        var trackWidth     = [self currentValueForThemeAttribute:@"track-width"],
            tickMarkSize   = [self currentValueForThemeAttribute:@"tick-mark-size"],
            tickMarkMargin = [self currentValueForThemeAttribute:@"tick-mark-margin"],
            topMargin      = [self currentValueForThemeAttribute:@"top-margin"],
            bottomMargin   = [self currentValueForThemeAttribute:@"bottom-margin"];

        if (trackWidth <= 0)
            return CGRectMakeZero();

        if (_isVertical)
        {
            var usableWidth = trackRect.size.width - topMargin - bottomMargin - (_isTicked ? (tickMarkSize.width + tickMarkMargin) : 0);

            trackRect.origin.x = (usableWidth - trackWidth) / 2.0 + topMargin + ((_isTicked && (_tickMarkPosition === CPTickMarkPositionLeading)) ? (tickMarkSize.width + tickMarkMargin) : 0);
            trackRect.size.width = trackWidth;
        }
        else
        {
            var usableHeight = trackRect.size.height - topMargin - bottomMargin - (_isTicked ? (tickMarkSize.height + tickMarkMargin) : 0);
            
            trackRect.origin.y = (usableHeight - trackWidth) / 2.0 + topMargin + ((_isTicked && (_tickMarkPosition === CPTickMarkPositionAbove)) ? (tickMarkSize.height + tickMarkMargin) : 0);
            trackRect.size.height = trackWidth;
        }
    }

    return trackRect;
}

- (CGRect)leftTrackRectForBounds:(CGRect)bounds
{
    // Circular and ticked slider do not have left and right parts, so we don't need to deal with them
    if (_isCircular || _isTicked)
        return CGRectMakeZero();

    var trackRect    = CGRectCreateCopy(bounds),
        trackWidth   = [self currentValueForThemeAttribute:@"track-width"],
        currentValue = [self doubleValue];
    
    if (_isVertical)
    {
        trackRect.origin.x = (trackRect.size.width - trackWidth) / 2.0;
        trackRect.origin.y = ((_maxValue - currentValue) / (_maxValue - _minValue)) * trackRect.size.height;
        trackRect.size.width = trackWidth;
        trackRect.size.height = ((currentValue - _minValue) / (_maxValue - _minValue)) * trackRect.size.height;
    }
    else
    {
        trackRect.origin.y = (trackRect.size.height - trackWidth) / 2.0;
        trackRect.size.width = ((currentValue - _minValue) / (_maxValue - _minValue)) * trackRect.size.width;
        trackRect.size.height = trackWidth;
    }
    
    return trackRect;
}

- (CGRect)rightTrackRectForBounds:(CGRect)bounds
{
    // Circular and ticked slider do not have left and right parts, so we don't need to deal with them
    if (_isCircular || _isTicked)
        return CGRectMakeZero();

    var trackRect    = CGRectCreateCopy(bounds),
        trackWidth   = [self currentValueForThemeAttribute:@"track-width"],
        currentValue = [self doubleValue];

    if (_isVertical)
    {
        trackRect.origin.x = (trackRect.size.width - trackWidth) / 2.0;
        trackRect.size.width = trackWidth;
        trackRect.size.height = ((_maxValue - currentValue) / (_maxValue - _minValue)) * trackRect.size.height;
    }
    else
    {
        trackRect.origin.x = ((currentValue - _minValue) / (_maxValue - _minValue)) * trackRect.size.width;
        trackRect.origin.y = (trackRect.size.height - trackWidth) / 2.0;
        trackRect.size.width = ((_maxValue - currentValue) / (_maxValue - _minValue)) * trackRect.size.width;
        trackRect.size.height = trackWidth;
    }

    return trackRect;
}

- (CGRect)knobRectForBounds:(CGRect)bounds
{
    var knobSize = [self currentValueForThemeAttribute:@"knob-size"];

    if (knobSize.width <= 0 || knobSize.height <= 0)
        return CGRectMakeZero();

    var knobRect   = CGRectMake(0.0, 0.0, knobSize.width, knobSize.height),
        trackRect  = [self trackRectForBounds:bounds],
        knobOffset = [self currentValueForThemeAttribute:@"knob-offset"];

    // No track, do our best to approximate a place for this thing.
    if (!trackRect || CGRectIsEmpty(trackRect))
        trackRect = bounds;

    [self closestTickMarkValueToValue:[self doubleValue]]; // we only need the side effect …
    _currentTickMarkSegment = _closestTickMarkIndex; // … when "Only stop on tick marks" selected

    if (_isCircular)
    {
        var angle  = 3 * PI_2 - (1.0 - [self doubleValue] - _minValue) / (_maxValue - _minValue) * PI2,
            radius = trackRect.size.width / 2.0 - (knobOffset ? knobOffset : 8.0);
        
        knobRect.origin.x = radius * COS(angle) + CGRectGetMidX(trackRect) - knobSize.width / 2; // 3.0;
        knobRect.origin.y = radius * SIN(angle) + CGRectGetMidY(trackRect) - knobSize.height / 2; // 2.0;
    }
    else if (_isVertical)
    {
        knobRect.origin.x = CGRectGetMidX(trackRect) - knobSize.width / 2.0 + knobOffset;

        if (_isTicked && _allowsTickMarkValuesOnly && _cachedTickMarksRects)
            // This is done to garantee that the knob is perfectly aligned with the tick mark
            knobRect.origin.y = _cachedTickMarksRects[_currentTickMarkSegment].origin.y - (knobSize.height - 1) / 2;
        else
            knobRect.origin.y = ROUND(((_maxValue - [self doubleValue]) / (_maxValue - _minValue)) * (trackRect.size.height - knobSize.height));
    }
    else
    {
        if (_isTicked && _allowsTickMarkValuesOnly && _cachedTickMarksRects)
            // This is done to garantee that the knob is perfectly aligned with the tick mark
            knobRect.origin.x = _cachedTickMarksRects[_currentTickMarkSegment].origin.x - (knobSize.width - 1) / 2;
        else
            knobRect.origin.x = ROUND((([self doubleValue] - _minValue) / (_maxValue - _minValue)) * (trackRect.size.width - knobSize.width));

        knobRect.origin.y = CGRectGetMidY(trackRect) - knobSize.height / 2.0 + knobOffset;
    }

    return knobRect;
}

- (CGRect)rectForEphemeralSubviewNamed:(CPString)aName
{
    switch (aName)
    {
        case @"track-view":
            return [self trackRectForBounds:[self bounds]];

        case @"knob-view":
            return [self knobRectForBounds:[self bounds]];

        case @"left-track-view":
            return [self leftTrackRectForBounds:[self bounds]];

        case @"right-track-view":
            return [self rightTrackRectForBounds:[self bounds]];

        default:
            return [super rectForEphemeralSubviewNamed:aName];
    }
}

- (CPView)createEphemeralSubviewNamed:(CPString)aName
{
    if (aName === "track-view" || aName === "knob-view" || aName === "left-track-view" || aName === "right-track-view")
    {
        var view = [[CPView alloc] init];

        [view setHitTests:NO];

        return view;
    }

    return [super createEphemeralSubviewNamed:aName];
}

- (void)setAltIncrementValue:(float)anAltIncrementValue
{
    // FIXME: This is not used. BTW, tested in Cocoa and it is totally useless. So leave it like that for now...
    _altIncrementValue = anAltIncrementValue;
}

- (float)altIncrementValue
{
    return _altIncrementValue;
}

- (CPInteger)isVertical
{
    return _isVertical;
}

- (void)layoutSubviews
{
    var leftTrackColor = [self currentValueForThemeAttribute:@"left-track-color"];

    if (leftTrackColor && !_isCircular && !_isTicked)
    {
        // Two parts layout (needed by Aristo3)
        var leftTrackView = [self layoutEphemeralSubviewNamed:@"left-track-view"
                                                   positioned:CPWindowBelow
                              relativeToEphemeralSubviewNamed:@"knob-view"],
            rightTrackView = [self layoutEphemeralSubviewNamed:@"right-track-view"
                                                    positioned:CPWindowBelow
                               relativeToEphemeralSubviewNamed:@"knob-view"];
        
        [leftTrackView  setBackgroundColor:leftTrackColor];
        [rightTrackView setBackgroundColor:[self currentValueForThemeAttribute:@"track-color"]];

        var knobView = [self layoutEphemeralSubviewNamed:@"knob-view"
                                              positioned:CPWindowAbove
                         relativeToEphemeralSubviewNamed:@"left-track-view"];
        
        [knobView setBackgroundColor:[self currentValueForThemeAttribute:"knob-color"]];
    }
    else
    {
        // Normal layout
        var trackView = [self layoutEphemeralSubviewNamed:@"track-view"
                                               positioned:CPWindowBelow
                          relativeToEphemeralSubviewNamed:@"knob-view"];
        
        [trackView setBackgroundColor:[self currentValueForThemeAttribute:@"track-color"]];

        var knobView = [self layoutEphemeralSubviewNamed:@"knob-view"
                                              positioned:CPWindowAbove
                         relativeToEphemeralSubviewNamed:@"track-view"];
        
        [knobView setBackgroundColor:[self currentValueForThemeAttribute:"knob-color"]];
    }
}

- (void)drawRect:(CGRect)aRect
{
    // We only draw tick marks here

    if (!_isTicked)
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSetFillColor(context, [self currentValueForThemeAttribute:@"tick-mark-color"]);

    for (var i = 0; i < _numberOfTickMarks; i++)
        CGContextFillRect(context, [self rectOfTickMarkAtIndex:i]);
}

- (BOOL)tracksMouseOutsideOfFrame
{
    return YES;
}

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    var bounds   = [self bounds],
        knobRect = [self knobRectForBounds:bounds];

    if (CGRectContainsPoint(knobRect, aPoint))
        _dragOffset = CGSizeMake(CGRectGetMidX(knobRect) - aPoint.x, CGRectGetMidY(knobRect) - aPoint.y);
    else
    {
        _dragOffset = CGSizeMakeZero();

        if (_allowsTickMarkValuesOnly)
        {
            _currentTickMarkSegment = [self indexOfTickMarkAtPoint:aPoint];
            [self setObjectValue:_cachedTickMarksValues[_currentTickMarkSegment]];
        }
        else
            [self setObjectValue:[self _valueAtPoint:aPoint]];
    }

    _stickingOnTickMark = NO;

    [self setHighlighted:YES];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];

    return YES;
}

- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)aPoint
{
    var bounds = [self bounds],
        newPoint = _isCircular ? CGPointMake(aPoint.x + _dragOffset.width, aPoint.y + _dragOffset.height)
                               : CGPointMake(MAX(0, MIN(bounds.size.width-1,  aPoint.x + _dragOffset.width)),
                                             MAX(0, MIN(bounds.size.height-1, aPoint.y + _dragOffset.height)));

    if (_allowsTickMarkValuesOnly)
    {
        var tickMarkSegment = [self indexOfTickMarkAtPoint:newPoint];

        if (tickMarkSegment !== _currentTickMarkSegment)
        {
            _currentTickMarkSegment = tickMarkSegment;
            [self setObjectValue:_cachedTickMarksValues[_currentTickMarkSegment]];
        }
    }

    else if (_canStickOnTickMarks)
    {
        // Ticked but not constrained to tick marks
        // We're using a tick affinity with a latency of AFFINITY pixels

        // Search the nearest tick mark
        var tickMarkSegment = [self indexOfTickMarkAtPoint:newPoint],
            tickRect        = _cachedTickMarksRects[tickMarkSegment];

        // Does the knob point to it ?
        if ((!_isVertical && (newPoint.x === CGRectGetMidX(tickRect))) ||
            ( _isVertical && (newPoint.y === CGRectGetMidY(tickRect))))
        {
            // Start an affinity
            [self setObjectValue:_cachedTickMarksValues[tickMarkSegment]];

            _stickingOnTickMark = YES;
            _affinityPoint = _isVertical ? newPoint.y : newPoint.x;
        }

        // Are we going too far from the tick mark ?
        else if (_stickingOnTickMark && (ABS((_isVertical ? newPoint.y : newPoint.x) - _affinityPoint) > AFFINITY))
        {
            // Yes. Stop affinity

            _stickingOnTickMark = NO;
            [self setObjectValue:[self _valueAtPoint:newPoint]];
        }

        else if (!_stickingOnTickMark) // Normal situation
            [self setObjectValue:[self _valueAtPoint:newPoint]];
    }

    else // Not ticked at all or no possible affinity
        [self setObjectValue:[self _valueAtPoint:newPoint]];

    return YES;
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    [self setHighlighted:NO];

    if ([_target respondsToSelector:@selector(sliderDidFinish:)])
        [_target sliderDidFinish:self];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (BOOL)isContinuous
{
    return _isContinuous;
}

- (void)setContinuous:(BOOL)flag
{
    _isContinuous = flag;

    if (_isContinuous)
        _sendActionOn |= CPLeftMouseDraggedMask;
    else
        _sendActionOn &= ~CPLeftMouseDraggedMask;
}

- (void)takeValueFromKeyPath:(CPString)aKeyPath ofObjects:(CPArray)objects
{
    var count = objects.length,
        value = [objects[0] valueForKeyPath:aKeyPath];

    [self setObjectValue:value];

    while (count-- > 1)
        if (value !== ([objects[count] valueForKeyPath:aKeyPath]))
            return [self setFloatValue:1.0];
}

#pragma mark - New methods as in High Sierra (10.13)

/*!
    Creates and returns a continuous horizontal slider whose values range from 0.0 to 1.0.
    @param aTarget
    @param anAction
 */
+ (CPSlider)sliderWithTarget:(id)aTarget action:(SEL)anAction
{
    return [self sliderWithValue:0.0 minValue:0.0 maxValue:1.0 target:aTarget action:anAction];
}

// Creates and returns a continuous horizontal slider that represents values over the specified range.
+ (CPSlider)sliderWithValue:(double)value minValue:(double)minValue maxValue:(double)maxValue target:(id)target action:(SEL)action
{
    var slider = [[self alloc] initWithFrame:CGRectMake(0, 0, 104, 19)]; // Size used by Cocoa

    [slider setMinValue:minValue];
    [slider setMaxValue:maxValue];
    [slider setDoubleValue:value];
    [slider setTarget:target];
    [slider setAction:action];
    [slider setContinuous:YES];

    [slider _refreshCachesAndStates];

    return slider;
}

// The knob’s thickness, in pixels.
// The thickness is defined to be the extent of the knob along the long dimension of the bar.
// In a vertical slider, a knob’s thickness is its height; in a horizontal slider, a knob’s thickness is its width.
- (float)knobThickness
{
    var knobSize = [self currentValueForThemeAttribute:@"knob-size"];

    return _isVertical ? knobSize.height : knobSize.width;
}

// allowsTickMarkValuesOnly : A Boolean value that indicates whether the receiver fixes
// its values to those values represented by its tick marks.

// YES if the slider fixes its values to the values represented by its tick marks; otherwise, NO.
// For example, if a slider has a minimum value of 0, a maximum value of 100, and five markers,
// the allowable values are 0, 25, 50, 75, and 100. When users move the slider’s knob,
// it jumps to the tick mark nearest the cursor when the mouse button is released.
// This method has no effect if the slider has no tick marks.

- (void)setAllowsTickMarkValuesOnly:(BOOL)shouldAllowTickMarkValuesOnly
{
    if (shouldAllowTickMarkValuesOnly === _allowsTickMarkValuesOnly)
        return;

    [self willChangeValueForKey:@"allowsTickMarkValuesOnly"];
    _allowsTickMarkValuesOnly = shouldAllowTickMarkValuesOnly;
    [self didChangeValueForKey:@"allowsTickMarkValuesOnly"];

    [self _refreshCachesAndStates];
    [self setNeedsDisplay:YES];
}

// Returns the value of the tick mark closest to the specified value.
- (double)closestTickMarkValueToValue:(double)value
{
    if (_numberOfTickMarks === 1)
        return _cachedTickMarksValues[0];

    _closestTickMarkIndex = CPNotFound;

    var foundDelta = 2 * _maxValue,
        delta;

    for (var i = 0; i < _numberOfTickMarks; i++)
    {
        delta = ABS(value - _cachedTickMarksValues[i]);

        if (delta < foundDelta)
        {
            foundDelta = delta;
            _closestTickMarkIndex = i;
        }
    }

    return _closestTickMarkIndex ? _cachedTickMarksValues[_closestTickMarkIndex] : _minValue;
}

// Returns the index of the tick mark closest to the location of the receiver represented by the given point.
- (CPInteger)indexOfTickMarkAtPoint:(CGPoint)point
{
    var foundIndex = CPNotFound;

    if (_isCircular)
    {
        // CPCircularSlider

        var bounds = [self bounds],
            dx     = point.x - bounds.size.width / 2,
            dy     = bounds.size.height / 2 - point.y,
            angle  = 1 + (((-3 * PI_2 - ATAN2(dy, dx)) % PI2) / PI2);

        for (var i = 0; (i < _numberOfTickMarks) && (foundIndex === CPNotFound); i++)
            if ((angle < _cachedTickMarksSegments[i]) || ((i === 0) && (angle >= (1 - _cachedTickMarksSegments[i]))))
                foundIndex = i;
    }
    else
    {
        // CPLinearSlider

        if (_isVertical)
        {
            for (var i = 0; (i < _numberOfTickMarks) && (foundIndex === CPNotFound); i++)
                if (point.y <= _cachedTickMarksSegments[i])
                    foundIndex = i;
        }
        else
        {
            for (var i = 0; (i < _numberOfTickMarks) && (foundIndex === CPNotFound); i++)
                if (point.x <= _cachedTickMarksSegments[i])
                    foundIndex = i;
        }
    }

    return foundIndex;
}

// The number of the slider's tick marks. The tick marks assigned to the minimum and maximum values are included.
- (void)setNumberOfTickMarks:(CPInteger)aNumber
{
    if (aNumber === _numberOfTickMarks)
        return;

    // We try to play nicer than Cocoa when passing from a non-ticked slider to a ticked one (and vice versa)
    var tickedChanged = (((_numberOfTickMarks == 0) && (aNumber > 0)) || ((_numberOfTickMarks > 0) && (aNumber == 0)));

    [self willChangeValueForKey:@"numberOfTickMarks"];
    _numberOfTickMarks = aNumber;
    [self didChangeValueForKey:@"numberOfTickMarks"];

    // If tickedChanged, this refresh is necessary to set new states but we'll have to call it again after for correct geometry
    [self _refreshCachesAndStates];

    if (tickedChanged)
    {
        // First, remove ephemeral subviews as they may change with new state (needed ones will be created by layoutSubviews)

        [self removeEphemeralSubviewNamed:@"track-view"];
        [self removeEphemeralSubviewNamed:@"left-track-view"];
        [self removeEphemeralSubviewNamed:@"right-track-view"];
        [self removeEphemeralSubviewNamed:@"knob-view"];

        // Now adapt the frame size to match what Xcode IB would have provided

        var currentSize = [self frameSize],
            newSize     = [self currentValueForThemeAttribute:@"ib-size"];

        if (_isCircular)
            [self setFrameSize:CGSizeMake(newSize, newSize)];

        else if (_isVertical)
            [self setFrameSize:CGSizeMake(newSize, currentSize.height)];

        else
            [self setFrameSize:CGSizeMake(currentSize.width, newSize)];

        // _refreshCachesAndStates, setNeedsDisplay and setNeedsLayout are called in setFrameSize
    }
    else
        [self setNeedsDisplay:YES];
}

// Returns the bounding rectangle of the tick mark at the given index.
- (CGRect)rectOfTickMarkAtIndex:(CPInteger)index
{
    // If no tick mark is associated with index, the method raises NSRangeException
    if ((index < 0) || (index >= _numberOfTickMarks))
        [CPException raise:CPRangeException reason:@"rectOfTickMarkAtIndex: index ("+index+") is outside permitted values (0.."+(_numberOfTickMarks-1)+")"];

    return _cachedTickMarksRects[index];
}

// tickMarkPosition : Determines how the receiver’s tick marks are aligned with it.
// Possible values are CPTickMarkBelow, CPTickMarkAbove, CPTickMarkLeft, and CPTickMarkRight
// (the last two are for vertical sliders). The default alignments are CPTickMarkBelow and CPTickMarkLeft.
// This property has no effect if no tick marks have been assigned (that is, numberOfTickMarks returns 0).
- (void)setTickMarkPosition:(CPTickMarkPosition)aTickMarkPosition
{
    if (aTickMarkPosition === _tickMarkPosition)
        return;

    [self willChangeValueForKey:@"tickMarkPosition"];
    _tickMarkPosition = aTickMarkPosition;
    [self didChangeValueForKey:@"tickMarkPosition"];

    [self _refreshCachesAndStates];
    [self setNeedsDisplay:YES];
}

// Returns the receiver’s value represented by the tick mark at the specified index.
- (double)tickMarkValueAtIndex:(CPInteger)index
{
    // If no tick mark is associated with index, the method raises NSRangeException
    if ((index < 0) || (index >= _numberOfTickMarks))
        [CPException raise:CPRangeException reason:@"tickMarkValueAtIndex: index ("+index+") is outside permitted values (0.."+(_numberOfTickMarks-1)+")"];

    return _cachedTickMarksValues[index];
}

// The color of the filled portion of the slider track, in appearances that support it.
- (void)setTrackFillColor:(CPColor)aColor
{
    var normalState = _isVertical ? [CPThemeStateVertical, CPThemeStateKeyWindow] : [CPThemeStateKeyWindow],
        leftTrackColor = [self valueForThemeAttribute:@"left-track-color" inStates:normalState];

    if (leftTrackColor === aColor)
        return;

    [self setValue:aColor forThemeAttribute:@"left-track-color" inStates:normalState];
}

- (CPColor)trackFillColor
{
    var normalState = _isVertical ? [CPThemeStateVertical, CPThemeStateKeyWindow] : [CPThemeStateKeyWindow];

    return [self valueForThemeAttribute:@"left-track-color" inStates:normalState];
}

#pragma mark - Private methods

- (void)_refreshCachesAndStates
{
    // Purge caches
    _cachedTickMarksRects    = @[];
    _cachedTickMarksValues   = @[];
    _cachedTickMarksSegments = @[];

    // Reset affinity
    _canStickOnTickMarks = NO;

    // Recalculate _isVertical.
    var bounds       = [self bounds],
        boundsWidth  = bounds.size.width,
        boundsHeight = bounds.size.height;

    _isVertical = (boundsWidth < boundsHeight) ? 1 : ((boundsWidth > boundsHeight) ? 0 : -1);

    if (_isVertical)
        [self setThemeState:CPThemeStateVertical];
    else
        [self unsetThemeState:CPThemeStateVertical];

    // Recalculate _isCircular
    _isCircular = (_sliderType === CPCircularSlider);

    if (_isCircular)
        [self setThemeState:CPThemeStateCircular];
    else
        [self unsetThemeState:CPThemeStateCircular];

    // Recalculate _isTicked
    _isTicked = (_numberOfTickMarks > 0);

    // If this slider has no tick marks, we're done.
    if (!_isTicked)
    {
        [self unsetThemeState:CPThemeStateTickedSlider];
        [self unsetThemeState:CPThemeStateAboveLeftTickedSlider];
        [self unsetThemeState:CPThemeStateBelowRightTickedSlider];
        return;
    }

    // Set specific theme states
    [self setThemeState:CPThemeStateTickedSlider];

    if (!_isCircular)
        if (_tickMarkPosition === CPTickMarkPositionAbove)
        {
            [self setThemeState:CPThemeStateAboveLeftTickedSlider];
            [self unsetThemeState:CPThemeStateBelowRightTickedSlider];
        }
        else
        {
            [self unsetThemeState:CPThemeStateAboveLeftTickedSlider];
            [self setThemeState:CPThemeStateBelowRightTickedSlider];
        }

    // Calculate cached values : tick marks rects, values and segments

    var tickSize       = [self currentValueForThemeAttribute:@"tick-mark-size"],
        tickMarkMargin = [self currentValueForThemeAttribute:@"tick-mark-margin"],
        topMargin      = [self currentValueForThemeAttribute:@"top-margin"],
        bottomMargin   = [self currentValueForThemeAttribute:@"bottom-margin"],
        knobSize       = [self currentValueForThemeAttribute:@"knob-size"],
        width          = tickSize.width,
        height         = tickSize.height,
        x,
        y,
        tickRect,
        value;

    if (_isCircular)
    {
        // CPCircularSlider

        // Remark : Cocoa doesn't use tick affinity with circular sliders

        var delta      = 1 / _numberOfTickMarks,
            dX         = width / 2,
            dY         = height / 2,
            cX         = boundsWidth / 2,
            cY         = boundsHeight / 2,
            radius     = cX - dX,
            deltaValue = (_maxValue - _minValue) / _numberOfTickMarks;

        value = _minValue;

        for (var i = 0, angle; i < _numberOfTickMarks; i++, value += deltaValue)
        {
            angle = PI_2 - PI2 * i * delta;
            x     = radius * COS(angle) + cX;
            y     = radius * SIN(-angle) + cY; // Vertical coordinates are reversed in Cappuccino

            tickRect = CGRectMake(ROUND(x - dX), ROUND(y - dY), width, height);

            [_cachedTickMarksRects    addObject:tickRect];
            [_cachedTickMarksValues   addObject:value];
            [_cachedTickMarksSegments addObject:(i + 0.5) * delta];
        }
    }
    else
    {
        // CPLinearSlider

        if (_isVertical)
        {
            // Vertical slider

            // If there's only one tick mark, it's centered.
            // If there's more than one tick mark, there's at least one at the min value and one at the max value

            var usableHeight = boundsHeight - knobSize.height,
                dY           = (height - 1)/2;

            x = (_tickMarkPosition === CPTickMarkPositionLeading) ? topMargin : (boundsWidth - width - bottomMargin);

            if (_numberOfTickMarks === 1)
            {
                y        = (boundsHeight - height) / 2;
                value    = (_maxValue - _minValue) / 2 + _minValue;
                tickRect = CGRectMake(x, ROUND(y - dY), width, height);

                [_cachedTickMarksRects    addObject:tickRect];
                [_cachedTickMarksValues   addObject:value];
                [_cachedTickMarksSegments addObject:bounds];
            }
            else
            {
                var delta      = usableHeight / (_numberOfTickMarks - 1),
                    deltaValue = (_maxValue - _minValue) / (_numberOfTickMarks - 1);

                y                    = (knobSize.height - 1) / 2;
                value                = _maxValue;
                _canStickOnTickMarks = !_allowsTickMarkValuesOnly && (delta > AFFINITY+3);

                for (var i = 0; i < _numberOfTickMarks; i++, y += delta, value -= deltaValue)
                {
                    tickRect = CGRectMake(x, ROUND(y - dY), width, height);

                    [_cachedTickMarksRects    addObject:tickRect];
                    [_cachedTickMarksValues   addObject:(i < _numberOfTickMarks - 1) ? value : _minValue]; // Avoid rounding problems on last tick mark
                    [_cachedTickMarksSegments addObject:(i < _numberOfTickMarks - 1) ? ROUND(y + delta/2) : boundsHeight];
                }
            }
        }
        else
        {
            // Horizontal slider

            // If there's only one tick mark, it's centered.
            // If there's more than one tick mark, there's at least one at the min value and one at the max value

            var usableWidth = boundsWidth - knobSize.width,
                dX          = (width - 1)/2;

            y = (_tickMarkPosition === CPTickMarkPositionAbove) ? topMargin : (boundsHeight - height - bottomMargin);

            if (_numberOfTickMarks === 1)
            {
                x        = (boundsWidth - width) / 2;
                value    = (_maxValue - _minValue) / 2 + _minValue;
                tickRect = CGRectMake(ROUND(x - dX), y, width, height);

                [_cachedTickMarksRects    addObject:tickRect];
                [_cachedTickMarksValues   addObject:value];
                [_cachedTickMarksSegments addObject:boundsWidth];
            }
            else
            {
                var delta      = usableWidth / (_numberOfTickMarks - 1),
                    deltaValue = (_maxValue - _minValue) / (_numberOfTickMarks - 1);

                x                    = (knobSize.width - 1) / 2;
                value                = _minValue;
                _canStickOnTickMarks = !_allowsTickMarkValuesOnly && (delta > AFFINITY+3);

                for (var i = 0; i < _numberOfTickMarks; i++, x += delta, value += deltaValue)
                {
                    tickRect = CGRectMake(ROUND(x - dX), y, width, height);

                    [_cachedTickMarksRects    addObject:tickRect];
                    [_cachedTickMarksValues   addObject:(i < _numberOfTickMarks - 1) ? value : _maxValue]; // Avoid rounding problems on last tick mark
                    [_cachedTickMarksSegments addObject:(i < _numberOfTickMarks - 1) ? ROUND(x + delta/2) : boundsWidth];
                }
            }
       }
    }

#if PLATFORM(DOM)
    // Don't do this in nib2cib !..
    if (_allowsTickMarkValuesOnly)
    {
        [self setObjectValue:[self closestTickMarkValueToValue:[self doubleValue]]];
        _currentTickMarkSegment = _closestTickMarkIndex;
        [self sendAction:[self action] to:[self target]];
    }
#endif
}

/*! @ignore */
- (float)_valueAtPoint:(CGPoint)aPoint
{
    var bounds    = [self bounds],
        knobSize  = [self currentValueForThemeAttribute:@"knob-size"],
        trackRect = [self trackRectForBounds:bounds],
        value;

    if (_isCircular)
    {
        var dx    = aPoint.x - CGRectGetMidX(trackRect),
            dy    = CGRectGetMidY(trackRect) - aPoint.y;

        value = ((1 + (((-3 * PI_2 - ATAN2(dy, dx)) % PI2) / PI2)) * (_maxValue - _minValue) + _minValue) % _maxValue;
    }
    else if (_isVertical)
    {
        var knobHeight = knobSize.height;

        trackRect.origin.y += knobHeight / 2;
        trackRect.size.height -= knobHeight;

        value = MAX(0.0, MIN(1.0, (trackRect.origin.y + trackRect.size.height - aPoint.y) / trackRect.size.height)) * (_maxValue - _minValue) + _minValue;
    }
    else
    {
        var knobWidth = knobSize.width;

        trackRect.origin.x += knobWidth / 2;
        trackRect.size.width -= knobWidth;

        value = MAX(0.0, MIN(1.0, (aPoint.x - trackRect.origin.x) / trackRect.size.width)) * (_maxValue - _minValue) + _minValue;
    }

    return value;
}

#pragma mark - Overrides

- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    [self _refreshCachesAndStates];
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

#pragma mark -

@end

var CPSliderMinValueKey                 = "CPSliderMinValueKey",
    CPSliderMaxValueKey                 = "CPSliderMaxValueKey",
    CPSliderAltIncrValueKey             = "CPSliderAltIncrValueKey",
    CPSliderTypeKey                     = "CPSliderTypeKey",
    CPSliderAllowsTickMarkValuesOnlyKey = "CPSliderAllowsTickMarkValuesOnlyKey",
    CPSliderTickMarkPositionKey         = "CPSliderTickMarkPositionKey",
    CPSliderNumberOfTickMarksKey        = "CPSliderNumberOfTickMarksKey";

@implementation CPSlider (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    _minValue = [aCoder decodeDoubleForKey:CPSliderMinValueKey];
    _maxValue = [aCoder decodeDoubleForKey:CPSliderMaxValueKey];

    self = [super initWithCoder:aCoder];

    if (self)
    {
        _altIncrementValue        = [aCoder decodeDoubleForKey:CPSliderAltIncrValueKey];
        _sliderType               = [aCoder decodeIntForKey:   CPSliderTypeKey];
        _allowsTickMarkValuesOnly = [aCoder decodeBoolForKey:  CPSliderAllowsTickMarkValuesOnlyKey];
        _tickMarkPosition         = [aCoder decodeIntForKey:   CPSliderTickMarkPositionKey];
        _numberOfTickMarks        = [aCoder decodeIntForKey:   CPSliderNumberOfTickMarksKey];

        _isContinuous = (_sendActionOn & CPLeftMouseDraggedMask) !== 0;

        [self _refreshCachesAndStates];

        [self setNeedsLayout];
        [self setNeedsDisplay:YES];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeDouble:_minValue                 forKey:CPSliderMinValueKey];
    [aCoder encodeDouble:_maxValue                 forKey:CPSliderMaxValueKey];
    [aCoder encodeDouble:_altIncrementValue        forKey:CPSliderAltIncrValueKey];
    [aCoder encodeInt:   _sliderType               forKey:CPSliderTypeKey];
    [aCoder encodeBool:  _allowsTickMarkValuesOnly forKey:CPSliderAllowsTickMarkValuesOnlyKey];
    [aCoder encodeInt:   _tickMarkPosition         forKey:CPSliderTickMarkPositionKey];
    [aCoder encodeInt:   _numberOfTickMarks        forKey:CPSliderNumberOfTickMarksKey];
}

@end

@implementation CPSlider (Deprecated)

- (id)value
{
    CPLog.warn("[CPSlider value] is deprecated, use doubleValue or objectValue instead.");

    return [self doubleValue];
}

- (void)setValue:(id)aValue
{
    CPLog.warn("[CPSlider setValue:] is deprecated, use setDoubleValue: or setObjectValue: instead.");

    [self setObjectValue:aValue];
}

@end
