
@import <AppKit/CPControl.j>

#include "CoreGraphics/CGGeometry.h"


@implementation CPSlider : CPControl
{
    double  _minValue;
    double  _maxValue;
    double  _altIncrementValue;
    
    CPColor _verticalTrackColor;    // vertical-track-color
    CPColor _horizontalTrackColor;  // horizontal-track-color
    
    CPColor _knobColor;             // knob-color
    CPColor _highlightedKnobColor;  // knob-color-highlighted
    
    float   _trackWidth;            // track-width
    CGSize  _knobSize;              // knob-size
    
    BOOL    _isHighlighted;
    
    CPView  _trackView;
    CPView  _knobView;
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
}

- (float)maxValue
{
    return _maxValue;
}

- (void)setObjectValue:(id)aValue
{
    [super setObjectValue:MIN(MAX(aValue, _minValue), _maxValue)];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (void)setHorizontalTrackColor:(CPColor)aColor
{
    if (_horizontalTrackColor === aColor)
        return;
    
    _horizontalTrackColor = aColor;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (CPColor)horizontalTrackColor
{
    return _horizontalTrackColor;
}

- (void)setVerticalTrackColor:(CPColor)aColor
{
    if (_verticalTrackColor === aColor)
        return;
    
    _verticalTrackColor = aColor;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (CPColor)verticalTrackColor
{
    return _verticalTrackColor;
}

- (void)setTrackWidth:(float)aTrackWidth
{
    if (_trackWidth === aTrackWidth)
        return;
    
    _trackWidth = aTrackWidth;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (float)trackWidth
{
    return _trackWidth;
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    var trackWidth = [self trackWidth];
    
    if (!trackWidth)
        return _CGRectMakeZero();
    
    if ([self isVertical])
    {
        bounds.origin.x = (_CGRectGetWidth(bounds) - trackWidth) / 2.0;
        bounds.size.width = _trackWidth;
    }
    else
    {
        bounds.origin.y = (_CGRectGetHeight(bounds) - trackWidth) / 2.0;
        bounds.size.height = _trackWidth;
    }
    
    return bounds;
}

- (void)setHighlightedKnobColor:(CPColor)aColor
{
    if (_highlightedKnobColor === aColor)
        _highlightedKnobColor = aColor;
    
    _highlightedKnobColor = aColor;
}

- (CPColor)highlightedKnobColor
{
    return _highlightedKnobColor;
}

- (void)setKnobSize:(CGSize)aKnobSize
{
    if (_knobSize && (!aKnobSize || _CGSizeEqualToSize(_knobSize, aKnobSize)))
        return;
    
    _knobSize = aKnobSize ? _CGSizeMakeCopy(aKnobSize) : nil;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (void)setKnobColor:(CPColor)aColor
{
    if (_knobColor === aColor)
        return;
    
    _knobColor = aColor;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (CPColor)knobColor
{
    return _knobColor;
}

- (CGRect)knobRectForBounds:(CGRect)bounds
{
    if (!_knobSize || _knobSize.width <= 0 || _knobSize.height <= 0)
        return _CGRectMakeZero();
    
    var knobRect = _CGRectMake(0.0, 0.0, _knobSize.width, _knobSize.height),
        trackRect = [self trackRectForBounds:bounds];
    
    // No track, do our best to approximate a place for this thing.
    if (!trackRect || _CGRectIsEmpty(trackRect))
        trackRect = bounds;

    if ([self isVertical])
    {
        knobRect.origin.x = _CGRectGetMidX(trackRect) - _knobSize.width / 2.0; 
        knobRect.origin.y = (([self doubleValue] - _minValue) / (_maxValue - _minValue)) * (_CGRectGetHeight(trackRect) - _knobSize.height);
    }
    else
    {
        knobRect.origin.x = (([self doubleValue] - _minValue) / (_maxValue - _minValue)) * (_CGRectGetWidth(trackRect) - _knobSize.width);
        knobRect.origin.y = _CGRectGetMidY(trackRect) - _knobSize.height / 2.0;   
    }
    
    return knobRect;
}

- (int)isVertical
{
    var bounds = [self bounds],
        width = CGRectGetWidth(bounds),
        height = CGRectGetHeight(bounds);
    
    return width < height ? 1 : (width > height ? 0 : -1);
}

- (CPView)createTrackView
{
    var trackView = [[CPView alloc] initWithFrame:_CGRectMakeZero()];
            
    [trackView setHitTests:NO];

    return trackView;
}

- (CPView)createKnobView
{
    var knobView = [[CPView alloc] initWithFrame:_CGRectMakeZero()];
    
    [knobView setHitTests:NO];
    
    return knobView;
}

- (void)layoutSubviews
{
    var bounds = [self bounds],
        isVertical = [self isVertical],
        trackRect = nil;

    if ((trackRect = [self trackRectForBounds:_CGRectMakeCopy(bounds)]) && !_CGRectIsEmpty(trackRect))
    {
        if (!_trackView)
        {
            _trackView = [self createTrackView]
            
            if (_trackView)
                [self addSubview:_trackView positioned:CPWindowBelow relativeTo:_knobView];
        }
        
        if (_trackView)
        {
            [_trackView setFrame:trackRect];        
            
            if ([self isVertical])
            {
                if (_verticalTrackColor)
                    [_trackView setBackgroundColor:_verticalTrackColor];
            }
            else
            {
                if (_horizontalTrackColor)
                    [_trackView setBackgroundColor:_horizontalTrackColor];
            }
        }
    }
    else if (_trackView)
    {
        [_trackView removeFromSuperview];
        
        _trackView = nil;
    }
    
    var knobRect = nil;
    
    if ((knobRect = [self knobRectForBounds:bounds]) && !_CGRectIsEmpty(knobRect))
    {
        if (!_knobView)
        {
            _knobView = [self createKnobView];
            
            if (_knobView)
                [self addSubview:_knobView positioned:CPWindowAbove relativeTo:_trackView];
        }
        
        if (_knobView)
        {        
            [_knobView setFrame:knobRect];
          
            if (_isHighlighted)
            {
                if (_highlightedKnobColor)
                    [_knobView setBackgroundColor:_highlightedKnobColor];
            }
            else if (_knobColor)
                [_knobView setBackgroundColor:_knobColor];
        }
    }
    else if (_knobView)
    {
        [_knobView removeFromSuperview];
        
        _knobView = nil;
    }
}

- (BOOL)tracksMouseOutsideOfFrame
{
    return YES;
}

- (float)_valueAtPoint:(CGPoint)aPoint
{
    var bounds = [self bounds],
        knobRect = [self knobRectForBounds:bounds],
        trackRect = [self trackRectForBounds:bounds];

    if ([self isVertical])
    {
        var knobHeight = _CGRectGetHeight(knobRect);
        
        trackRect.origin.y += knobHeight / 2;
        trackRect.size.height -= knobHeight;
        
        var minValue = [self minValue];
        
        return MAX(0.0, MIN(1.0, (aPoint.y - _CGRectGetMinY(trackRect)) / _CGRectGetHeight(trackRect))) * ([self maxValue] - minValue) + minValue;
    }
    else

    var knobWidth = _CGRectGetWidth(knobRect);
    
    trackRect.origin.x += knobWidth / 2;
    trackRect.size.width -= knobWidth;
    
    var minValue = [self minValue];
    
    return MAX(0.0, MIN(1.0, (aPoint.x - _CGRectGetMinX(trackRect)) / _CGRectGetWidth(trackRect))) * ([self maxValue] - minValue) + minValue;
}

- (BOOL)startTrackingAt:(CGPoint)aPoint
{
    var bounds = [self bounds],
        knobRect = [self knobRectForBounds:_CGRectMakeCopy(bounds)];
    
    if (_CGRectContainsPoint(knobRect, aPoint))
        _dragOffset = _CGSizeMake(_CGRectGetMidX(knobRect) - aPoint.x, _CGRectGetMidY(knobRect) - aPoint.y);
    
    else 
    {
        var trackRect = [self trackRectForBounds:bounds];
        
        if (trackRect && _CGRectContainsPoint(trackRect, aPoint))
        {
            _dragOffset = _CGSizeMakeZero();
            
            [self setObjectValue:[self _valueAtPoint:aPoint]];
        }
    
        else
            return NO;
    }
    
    _isHighlighted = YES;
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
    
    return YES;   
}

- (BOOL)continueTracking:(CGPoint)lastPoint at:(CGPoint)aPoint
{
    [self setObjectValue:[self _valueAtPoint:_CGPointMake(aPoint.x + _dragOffset.width, aPoint.y + _dragOffset.height)]];
    
    return YES;
}

- (void)stopTracking:(CGPoint)lastPoint at:(CGPoint)aPoint mouseIsUp:(BOOL)mouseIsUp
{
    _isHighlighted = NO;
    
    if ([_target respondsToSelector:@selector(sliderDidFinish:)])
        [_target sliderDidFinish:self];

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

/*!
    @ignore
    shoudl we have _continuous?
*/
- (void)setContinuous:(BOOL)flag
{
    if (flag)
        _sendActionOn |= CPLeftMouseDraggedMask;
    else 
        _sendActionOn &= ~CPLeftMouseDraggedMask;
}

@end

@implementation CPSlider (Theming)

- (void)viewDidChangeTheme
{
    [super viewDidChangeTheme];
    
    var theme = [self theme];
    
    if (!theme)
        return;

    [self setKnobSize:[theme valueForKey:@"knob-size"]];
    [self setKnobColor:[theme valueForKey:@"knob-color"]];
    [self setHighlightedKnobColor:[theme valueForKey:@"knob-color-highlighted"]];
    
    [self setTrackWidth:[theme valueForKey:@"track-width"]];
    [self setHorizontalTrackColor:[theme valueForKey:@"horizontal-track-color"]];
    [self setVerticalTrackColor:[theme valueForKey:@"vertical-track-color"]];
    
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (CPDictionary)themedValues
{
    var values = [super themedValues];
    
    [values setObject:_knobSize forKey:@"knob-size"];
    [values setObject:_knobColor forKey:@"knob-color"];
    [values setObject:_highlightedKnobColor forKey:@"knob-color-highlighted"];
    [values setObject:_trackWidth forKey:@"track-width"];
    [values setObject:_verticalTrackColor forKey:@"vertical-track-color"];
    [values setObject:_horizontalTrackColor forKey:@"horizontal-track-color"];

    return values;
}

@end

var CPSliderMinValueKey     = "CPSliderMinValueKey",
    CPSliderMaxValueKey     = "CPSliderMaxValueKey",
    CPSliderAltIncrValueKey = "CPSliderAltIncrValueKey";

@implementation CPSlider (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        _minValue = [aCoder decodeDoubleForKey:CPSliderMinValueKey];
        _maxValue = [aCoder decodeDoubleForKey:CPSliderMaxValueKey];
        _altIncrementValue = [aCoder decodeDoubleForKey:CPSliderAltIncrValueKey];
    
        [self setContinuous:YES];
        
        [self setTheme:[CPTheme defaultTheme]];
        
        [self setNeedsLayout];
        [self setNeedsDisplay:YES];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    var count = [_subviews count],
        subviews = nil;
    
    if (count)
    {
        subviews = _subviews;
            
        if (count === 2 && _trackView && _knobView)
            _subviews = [];
        else
        {
            if (_trackView)
                [_subviews removeObjectIdenticalTo:_trackView];
            if (_knobView)
                [_subviews removeObjectIdenticalTo:_knobView];
        }
    }
    
    [super encodeWithCoder:aCoder];
    
    _subviews = subviews;
    
    [aCoder encodeDouble:_minValue forKey:CPSliderMinValueKey];
    [aCoder encodeDouble:_maxValue forKey:CPSliderMaxValueKey];
    [aCoder encodeDouble:_altIncrementValue forKey:CPSliderAltIncrValueKey];
    
    // NO!
/*    [aCoder encodeObject:_verticalTrackColor forKey:"1"];
    [aCoder encodeObject:_horizontalTrackColor forKey:"2"];
    [aCoder encodeObject:_knobColor forKey:"3"];
    [aCoder encodeObject:_highlightedKnobColor forKey:"4"];*/
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
