/*
 *  CPRulerView.j
 *  AppKit
 *
 *  Created by Daniel Boehringer on 11/01/2014
 *  Copyright Daniel Boehringer 2014.
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

@import <Foundation/CPDictionary.j>
@import <Foundation/CPNotificationCenter.j>
@import <Foundation/CPObject.j>

@import "CGContext.j"
@import "CGGeometry.j"
@import "CPColor.j"
@import "CPFont.j"
@import "CPGraphicsContext.j"
@import "CPImage.j"
@import "CPRulerMarker.j"
@import "CPView.j"

@class CPMenu
@class CPScrollView

@typedef CPRulerOrientation
CPHorizontalRuler = 0;
CPVerticalRuler = 1;
CPRulerOrientationHorizontal = CPHorizontalRuler;
CPRulerOrientationVertical = CPVerticalRuler;

/*!
    Names of the measurement units that every CPRulerView supports.
*/
CPRulerViewUnitInches = @"Inches";
CPRulerViewUnitCentimeters = @"Centimeters";
CPRulerViewUnitPoints = @"Points";
CPRulerViewUnitPicas = @"Picas";

/*
    The registered measurement units, by name. Each entry holds the abbreviation, the number
    of points in one unit, and the cycles used to space labels and hash marks.
*/
var CPRulerViewRegisteredUnits = @{};

/*
    The smallest distances, in points, kept between two labels and between two hash marks.
*/
var CPRulerViewMinimumLabelSpacing = 40.0,
    CPRulerViewMinimumHashMarkSpacing = 5.0;

/*!
    @ingroup appkit
    @class CPRulerView

    A CPRulerView shows a ruler along the horizontal or vertical edge of a CPScrollView's
    content, with hash marks and labels in a chosen measurement unit, and markers such as
    tab stops and paragraph indents.

    The ruler is divided across its thickness into three areas: an optional accessory view,
    the marker area, and the rule area with the hash marks and labels, which lies next to
    the scroll view's content. The baseline separates the marker area from the rule area.

    A ruler works for a client view, usually the scroll view's document view. Marker
    locations are expressed in the client view's coordinate system. The ruler asks the
    client view before and after the user adds, moves or removes a marker, through these
    optional client methods:

    <pre>
    - (BOOL)rulerView:(CPRulerView)aRulerView shouldAddMarker:(CPRulerMarker)aMarker;
    - (float)rulerView:(CPRulerView)aRulerView willAddMarker:(CPRulerMarker)aMarker atLocation:(float)aLocation;
    - (void)rulerView:(CPRulerView)aRulerView didAddMarker:(CPRulerMarker)aMarker;
    - (BOOL)rulerView:(CPRulerView)aRulerView shouldMoveMarker:(CPRulerMarker)aMarker;
    - (float)rulerView:(CPRulerView)aRulerView willMoveMarker:(CPRulerMarker)aMarker toLocation:(float)aLocation;
    - (void)rulerView:(CPRulerView)aRulerView didMoveMarker:(CPRulerMarker)aMarker;
    - (BOOL)rulerView:(CPRulerView)aRulerView shouldRemoveMarker:(CPRulerMarker)aMarker;
    - (void)rulerView:(CPRulerView)aRulerView didRemoveMarker:(CPRulerMarker)aMarker;
    - (void)rulerView:(CPRulerView)aRulerView handleMouseDown:(CPEvent)anEvent;
    - (void)rulerView:(CPRulerView)aRulerView willSetClientView:(CPView)aNewClient;
    - (float)rulerView:(CPRulerView)aRulerView locationForPoint:(CGPoint)aPoint;
    - (CGPoint)rulerView:(CPRulerView)aRulerView pointForLocation:(float)aLocation;
    </pre>
*/
@implementation CPRulerView : CPView
{
    CPScrollView        _scrollView;
    CPRulerOrientation  _orientation;
    CPView              _clientView;
    CPView              _accessoryView;
    CPArray             _markers;
    CPRulerMarker       _trackedMarker;
    CPArray             _rulerlineLocations;

    float               _ruleThickness;
    float               _reservedThicknessForMarkers;
    float               _reservedThicknessForAccessoryView;
    float               _originOffset;
    CPString            _measurementUnits;

    float               _labelStep;
    CPArray             _hashMarkSteps;
}

+ (void)initialize
{
    if (self !== [CPRulerView class])
        return;

    [self registerUnitWithName:CPRulerViewUnitInches abbreviation:@"in" unitToPointsConversionFactor:72.0 stepUpCycle:[2.0] stepDownCycle:[0.5]];
    [self registerUnitWithName:CPRulerViewUnitCentimeters abbreviation:@"cm" unitToPointsConversionFactor:28.35 stepUpCycle:[2.0] stepDownCycle:[0.5, 0.2]];
    [self registerUnitWithName:CPRulerViewUnitPoints abbreviation:@"pt" unitToPointsConversionFactor:1.0 stepUpCycle:[10.0] stepDownCycle:[0.5]];
    [self registerUnitWithName:CPRulerViewUnitPicas abbreviation:@"pc" unitToPointsConversionFactor:12.0 stepUpCycle:[10.0] stepDownCycle:[0.5]];
}

// MARK: Altering Measurement Units

/*!
    Registers a measurement unit that every ruler view can then use.

    The cycles control the spacing of labels and hash marks. When labels one unit apart
    would be too close, the label step is multiplied by the factors of \c upCycle in turn
    until they fit. Hash marks between labels divide the label step by the factors of
    \c downCycle in turn, for as long as they stay far enough apart.
    @param aName the unit's name
    @param anAbbreviation the unit's abbreviation
    @param aFactor the number of points in one unit
    @param upCycle the factors, each greater than 1, that enlarge the label step
    @param downCycle the factors, each less than 1, that subdivide the label step
*/
+ (void)registerUnitWithName:(CPString)aName abbreviation:(CPString)anAbbreviation unitToPointsConversionFactor:(float)aFactor stepUpCycle:(CPArray)upCycle stepDownCycle:(CPArray)downCycle
{
    [CPRulerViewRegisteredUnits setObject:{ abbreviation: anAbbreviation, factor: aFactor, upCycle: upCycle, downCycle: downCycle } forKey:aName];
}

/* @ignore */
+ (CPString)_defaultMeasurementUnits
{
    // As in Cocoa, the default follows the user's region: inches where the imperial system is in common use.
    var language = (typeof navigator !== "undefined" && navigator.language) || @"",
        region = language.split("-")[1];

    return (region === @"US" || region === @"LR" || region === @"MM") ? CPRulerViewUnitInches : CPRulerViewUnitCentimeters;
}

// MARK: Creating a Ruler View

/*!
    Initializes a ruler view for \c aScrollView with the given orientation. The scroll view
    is not retained. The ruler's client view is the scroll view's document view until
    another is set.
    @param aScrollView the scroll view that owns the ruler
    @param anOrientation \c CPHorizontalRuler or \c CPVerticalRuler
    @return the initialized ruler view
*/
- (id)initWithScrollView:(CPScrollView)aScrollView orientation:(CPRulerOrientation)anOrientation
{
    self = [super initWithFrame:CGRectMakeZero()];

    if (self)
    {
        _scrollView = aScrollView;
        _orientation = anOrientation;
        _markers = [];
        _rulerlineLocations = [];

        _ruleThickness = 16.0;
        _reservedThicknessForMarkers = anOrientation === CPHorizontalRuler ? 15.0 : 0.0;
        _reservedThicknessForAccessoryView = 0.0;
        _originOffset = 0.0;
        _measurementUnits = [[self class] _defaultMeasurementUnits];

        [self invalidateHashMarks];
    }

    return self;
}

// MARK: Ruler Layout

/*!
    Returns the scroll view that owns the ruler.
*/
- (CPScrollView)scrollView
{
    return _scrollView;
}

/*!
    Sets the scroll view that owns the ruler. The scroll view is not retained.
    @param aScrollView the owning scroll view
*/
- (void)setScrollView:(CPScrollView)aScrollView
{
    _scrollView = aScrollView;
}

/*!
    Returns the ruler's orientation: \c CPHorizontalRuler or \c CPVerticalRuler.
*/
- (CPRulerOrientation)orientation
{
    return _orientation;
}

/*!
    Sets the ruler's orientation.
    @param anOrientation \c CPHorizontalRuler or \c CPVerticalRuler
*/
- (void)setOrientation:(CPRulerOrientation)anOrientation
{
    if (_orientation === anOrientation)
        return;

    _orientation = anOrientation;
    [self _noteThicknessChanged];
}

/*!
    Returns the thickness of the rule area, where hash marks and labels are drawn.
*/
- (float)ruleThickness
{
    return _ruleThickness;
}

/*!
    Sets the thickness of the rule area.
    @param aThickness the new thickness
*/
- (void)setRuleThickness:(float)aThickness
{
    if (_ruleThickness === aThickness)
        return;

    _ruleThickness = aThickness;
    [self _noteThicknessChanged];
}

/*!
    Returns the thickness reserved for markers, between the accessory view and the rule area.
*/
- (float)reservedThicknessForMarkers
{
    return _reservedThicknessForMarkers;
}

/*!
    Sets the thickness reserved for markers. A client view usually sets it to the largest
    \c thicknessRequiredInRuler of the markers it uses.
    @param aThickness the new thickness
*/
- (void)setReservedThicknessForMarkers:(float)aThickness
{
    if (_reservedThicknessForMarkers === aThickness)
        return;

    _reservedThicknessForMarkers = aThickness;
    [self _noteThicknessChanged];
}

/*!
    Returns the thickness reserved for the accessory view.
*/
- (float)reservedThicknessForAccessoryView
{
    return _reservedThicknessForAccessoryView;
}

/*!
    Sets the thickness reserved for the accessory view.
    @param aThickness the new thickness
*/
- (void)setReservedThicknessForAccessoryView:(float)aThickness
{
    if (_reservedThicknessForAccessoryView === aThickness)
        return;

    _reservedThicknessForAccessoryView = aThickness;
    [self _noteThicknessChanged];
}

/*!
    Returns the total thickness the ruler needs: the accessory view, the markers and the
    rule area together.
*/
- (float)requiredThickness
{
    var accessoryThickness = _reservedThicknessForAccessoryView;

    if (_accessoryView)
    {
        var accessorySize = [_accessoryView frameSize];
        accessoryThickness = MAX(accessoryThickness, _orientation === CPHorizontalRuler ? accessorySize.height : accessorySize.width);
    }

    return accessoryThickness + _reservedThicknessForMarkers + _ruleThickness;
}

/*!
    Returns the location of the baseline, which separates the marker area from the rule
    area, in the ruler's coordinate system.
*/
- (float)baselineLocation
{
    return [self requiredThickness] - _ruleThickness;
}

/*!
    Returns \c YES. The ruler's coordinate system has its origin at the top left.
*/
- (BOOL)isFlipped
{
    return YES;
}

/* @ignore */
- (void)_noteThicknessChanged
{
    [_scrollView tile];
    [self setNeedsDisplay:YES];
}

// MARK: Setting the Client View

/*!
    Returns the ruler's client view, or the scroll view's document view if no client view
    has been set.
*/
- (CPView)clientView
{
    return _clientView || [_scrollView documentView];
}

/*!
    Sets the ruler's client view. The current client view is told first, through
    \c rulerView:willSetClientView:, and the ruler's markers are removed.
    @param aView the new client view
*/
- (void)setClientView:(CPView)aView
{
    if (_clientView === aView)
        return;

    var currentClient = [self clientView];

    if ([currentClient respondsToSelector:@selector(rulerView:willSetClientView:)])
        [currentClient rulerView:self willSetClientView:aView];

    _clientView = aView;
    [self setMarkers:nil];
}

// MARK: Setting an Accessory View

/*!
    Returns the ruler's accessory view.
*/
- (CPView)accessoryView
{
    return _accessoryView;
}

/*!
    Sets the ruler's accessory view, which is shown in the area on the far side of the
    markers from the rule area.
    @param aView the new accessory view
*/
- (void)setAccessoryView:(CPView)aView
{
    if (_accessoryView === aView)
        return;

    [_accessoryView removeFromSuperview];
    _accessoryView = aView;

    if (_accessoryView)
    {
        [_accessoryView setFrameOrigin:CGPointMakeZero()];
        [self addSubview:_accessoryView];
    }

    [self _noteThicknessChanged];
}

// MARK: Setting the Zero Mark Position

/*!
    Returns the distance from the origin of the scroll view's document view to the ruler's
    zero hash mark.
*/
- (float)originOffset
{
    return _originOffset;
}

/*!
    Sets the distance from the origin of the scroll view's document view to the ruler's
    zero hash mark. A text view sets it to the start of its text, so that the ruler's
    zero lines up with the left edge of the text.
    @param anOffset the new offset
*/
- (void)setOriginOffset:(float)anOffset
{
    if (_originOffset === anOffset)
        return;

    _originOffset = anOffset;
    [self setNeedsDisplay:YES];
}

// MARK: Measurement Units

/*!
    Returns the name of the measurement unit the ruler shows.
*/
- (CPString)measurementUnits
{
    return _measurementUnits;
}

/*!
    Sets the measurement unit the ruler shows. The unit must have been registered.
    @param aUnitName the name of a registered unit
*/
- (void)setMeasurementUnits:(CPString)aUnitName
{
    if (_measurementUnits === aUnitName || ![CPRulerViewRegisteredUnits objectForKey:aUnitName])
        return;

    _measurementUnits = aUnitName;
    [self invalidateHashMarks];
}

/*!
    Discards the cached spacing of labels and hash marks, so that it is computed again the
    next time the ruler is drawn.
*/
- (void)invalidateHashMarks
{
    _labelStep = nil;
    _hashMarkSteps = nil;
    [self setNeedsDisplay:YES];
}

// MARK: Adding and Removing Markers

/*!
    Returns the ruler's markers.
*/
- (CPArray)markers
{
    return _markers;
}

/*!
    Replaces the ruler's markers with \c newMarkers, without consulting the client view.
    @param newMarkers the new markers, or \c nil to remove all markers
*/
- (void)setMarkers:(CPArray)newMarkers
{
    _markers = newMarkers ? [newMarkers copy] : [];
    [self setNeedsDisplay:YES];
}

/*!
    Adds \c aMarker to the ruler, without consulting the client view.
    @param aMarker the marker to add
*/
- (void)addMarker:(CPRulerMarker)aMarker
{
    if ([_markers containsObjectIdenticalTo:aMarker])
        return;

    _markers.push(aMarker);
    [self setNeedsDisplay:YES];
}

/*!
    Removes \c aMarker from the ruler, without consulting the client view.
    @param aMarker the marker to remove
*/
- (void)removeMarker:(CPRulerMarker)aMarker
{
    [_markers removeObjectIdenticalTo:aMarker];
    [self setNeedsDisplay:YES];
}

/*!
    Lets the user add \c aMarker to the ruler by dragging it, starting with \c anEvent. The
    client view is consulted before the marker is added. A client view usually calls this
    method from \c rulerView:handleMouseDown:.
    @param aMarker the marker to add, which is not yet in the ruler
    @param anEvent the mouse-down event
    @return \c YES if tracking started
*/
- (BOOL)trackMarker:(CPRulerMarker)aMarker withMouseEvent:(CPEvent)anEvent
{
    return [aMarker trackMouse:anEvent adding:YES];
}

// MARK: Drawing Temporary Ruler Lines

/*!
    Moves a temporary line drawn across the ruler from \c oldLocation to \c newLocation,
    both in the client view's coordinate system. Passing -1 as \c oldLocation draws a new
    line, and passing -1 as \c newLocation removes the line.
    @param oldLocation the line's current location, or -1
    @param newLocation the line's new location, or -1
*/
- (void)moveRulerlineFromLocation:(float)oldLocation toLocation:(float)newLocation
{
    if (oldLocation >= 0.0)
        [_rulerlineLocations removeObject:oldLocation];

    if (newLocation >= 0.0)
        _rulerlineLocations.push(newLocation);

    [self setNeedsDisplay:YES];
}

// MARK: HUD Appearance

/*!
    Returns \c YES if the ruler is drawn with the dark HUD appearance.
*/
- (BOOL)isHUD
{
    return [self hasThemeState:CPThemeStateHUD];
}

/* @ignore */
- (BOOL)setThemeState:(ThemeState)aState
{
    var result = [super setThemeState:aState];
    [self setNeedsDisplay:YES];

    return result;
}

/* @ignore */
- (BOOL)unsetThemeState:(ThemeState)aState
{
    var result = [super unsetThemeState:aState];
    [self setNeedsDisplay:YES];

    return result;
}

/* @ignore */
- (CPColor)_backgroundColorForDrawing
{
    return [CPColor colorWithWhite:([self isHUD] ? 0.18 : 0.96) alpha:1.0];
}

/* @ignore */
- (CPColor)_edgeColorForDrawing
{
    return [CPColor colorWithWhite:([self isHUD] ? 0.10 : 0.75) alpha:1.0];
}

/* @ignore */
- (CPColor)_hashMarkColorForDrawing
{
    return [CPColor colorWithWhite:([self isHUD] ? 0.60 : 0.55) alpha:1.0];
}

/* @ignore */
- (CPColor)_labelColorForDrawing
{
    return [CPColor colorWithWhite:([self isHUD] ? 0.75 : 0.55) alpha:1.0];
}

/* @ignore */
- (CPColor)_rulerlineColorForDrawing
{
    return [CPColor colorWithWhite:([self isHUD] ? 0.85 : 0.3) alpha:1.0];
}

// MARK: Drawing

/*!
    Draws the ruler: its background, hash marks and labels, temporary ruler lines and markers.
    @param aRect the rectangle to draw
*/
- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds];

    CGContextSetFillColor(context, [self _backgroundColorForDrawing]);
    CGContextFillRect(context, bounds);

    // The edge next to the scroll view's content.
    CGContextSetFillColor(context, [self _edgeColorForDrawing]);

    if (_orientation === CPHorizontalRuler)
        CGContextFillRect(context, CGRectMake(CGRectGetMinX(bounds), CGRectGetMaxY(bounds) - 1.0, CGRectGetWidth(bounds), 1.0));
    else
        CGContextFillRect(context, CGRectMake(CGRectGetMaxX(bounds) - 1.0, CGRectGetMinY(bounds), 1.0, CGRectGetHeight(bounds)));

    [self drawHashMarksAndLabelsInRect:aRect];
    [self _drawRulerlinesInRect:aRect];
    [self drawMarkersInRect:aRect];
}

/*!
    Draws the hash marks and labels that lie within \c aRect, in the rule area.
    @param aRect the rectangle to draw, in the ruler's coordinate system
*/
- (void)drawHashMarksAndLabelsInRect:(CGRect)aRect
{
    [self _computeHashMarkSpacing];

    var unit = [CPRulerViewRegisteredUnits objectForKey:_measurementUnits],
        context = [[CPGraphicsContext currentContext] graphicsPort],
        isHorizontal = _orientation === CPHorizontalRuler,
        bounds = [self bounds],
        zero = [self _rulerPointForDocumentLocation:_originOffset],
        firstPoint = isHorizontal ? CGRectGetMinX(aRect) : CGRectGetMinY(aRect),
        lastPoint = isHorizontal ? CGRectGetMaxX(aRect) : CGRectGetMaxY(aRect),
        ruleEdge = isHorizontal ? CGRectGetMaxY(bounds) - 1.0 : CGRectGetMaxX(bounds) - 1.0,
        smallestStep = _hashMarkSteps.length ? _hashMarkSteps[_hashMarkSteps.length - 1] : _labelStep,
        stepPoints = smallestStep * unit.factor,
        firstIndex = Math.floor((firstPoint - zero) / stepPoints),
        lastIndex = Math.ceil((lastPoint - zero) / stepPoints),
        hashMarkColor = [self _hashMarkColorForDrawing],
        labelColor = [self _labelColorForDrawing];

    CGContextSetFillColor(context, hashMarkColor);
    CGContextSelectFont(context, [CPFont systemFontOfSize:8.0]);

    for (var index = firstIndex; index <= lastIndex; index++)
    {
        var value = index * smallestStep,
            point = zero + value * unit.factor,
            length = [self _hashMarkLengthForValue:value];

        if (isHorizontal)
            CGContextFillRect(context, CGRectMake(ROUND(point), ruleEdge - length, 1.0, length));
        else
            CGContextFillRect(context, CGRectMake(ruleEdge - length, ROUND(point), length, 1.0));

        if (![self _value:value isMultipleOf:_labelStep])
            continue;

        var label = [self _labelForValue:value];

        CGContextSetFillColor(context, labelColor);

        // Labels sit in the half of the rule area away from the baseline, clear of markers that reach below it.
        if (isHorizontal)
            CGContextShowTextAtPoint(context, ROUND(point) + 2.0, ruleEdge - 4.5, label);
        else
            CGContextShowTextAtPoint(context, ruleEdge - _ruleThickness + 1.0, ROUND(point) + 6.0, label);

        CGContextSetFillColor(context, hashMarkColor);
    }
}

/*!
    Draws the markers that lie within \c aRect, including a marker the user is adding.
    @param aRect the rectangle to draw, in the ruler's coordinate system
*/
- (void)drawMarkersInRect:(CGRect)aRect
{
    var markers = _trackedMarker ? _markers.concat([_trackedMarker]) : _markers,
        count = markers.length;

    for (var i = 0; i < count; i++)
    {
        var marker = markers[i];

        [self _redrawWhenImageLoads:[marker image]];
        [marker drawRect:aRect];
    }
}

/* @ignore */
- (void)_drawRulerlinesInRect:(CGRect)aRect
{
    var count = _rulerlineLocations.length;

    if (!count)
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds];

    CGContextSetFillColor(context, [self _rulerlineColorForDrawing]);

    for (var i = 0; i < count; i++)
    {
        var point = ROUND([self _rulerPointForLocation:_rulerlineLocations[i]]);

        if (_orientation === CPHorizontalRuler)
            CGContextFillRect(context, CGRectMake(point, CGRectGetMinY(bounds), 1.0, CGRectGetHeight(bounds)));
        else
            CGContextFillRect(context, CGRectMake(CGRectGetMinX(bounds), point, CGRectGetWidth(bounds), 1.0));
    }
}

/* @ignore */
- (void)_redrawWhenImageLoads:(CPImage)anImage
{
    if (!anImage || [anImage loadStatus] === CPImageLoadStatusCompleted)
        return;

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_markerImageDidLoad:) name:CPImageDidLoadNotification object:anImage];
}

/* @ignore */
- (void)_markerImageDidLoad:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:CPImageDidLoadNotification object:[aNotification object]];
    [self setNeedsDisplay:YES];
}

/* @ignore */
- (void)_computeHashMarkSpacing
{
    if (_labelStep)
        return;

    var unit = [CPRulerViewRegisteredUnits objectForKey:_measurementUnits],
        labelStep = 1.0,
        cycleIndex = 0;

    while (labelStep * unit.factor < CPRulerViewMinimumLabelSpacing)
        labelStep *= unit.upCycle[cycleIndex++ % unit.upCycle.length];

    var steps = [],
        step = labelStep;

    cycleIndex = 0;

    while (YES)
    {
        var nextStep = step * unit.downCycle[cycleIndex++ % unit.downCycle.length];

        if (nextStep * unit.factor < CPRulerViewMinimumHashMarkSpacing)
            break;

        steps.push(nextStep);
        step = nextStep;
    }

    _labelStep = labelStep;
    _hashMarkSteps = steps;
}

/* @ignore */
- (float)_hashMarkLengthForValue:(float)aValue
{
    // Hash marks fill only the half of the rule area away from the baseline, like the labels.
    var fullLength = ROUND(_ruleThickness / 2.0);

    if ([self _value:aValue isMultipleOf:_labelStep])
        return fullLength;

    // Each finer subdivision of the label step draws a shorter mark.
    for (var i = 0; i < _hashMarkSteps.length; i++)
        if ([self _value:aValue isMultipleOf:_hashMarkSteps[i]])
            return MAX(2.0, ROUND(fullLength * (0.65 - 0.2 * i)));

    return 2.0;
}

/* @ignore */
- (BOOL)_value:(float)aValue isMultipleOf:(float)aStep
{
    var quotient = aValue / aStep;

    return Math.abs(quotient - ROUND(quotient)) < 0.0001;
}

/* @ignore */
- (CPString)_labelForValue:(float)aValue
{
    var rounded = ROUND(aValue * 100.0) / 100.0;

    return String(rounded);
}

// MARK: Coordinate Conversion

/* @ignore
    Converts a location in the client view's coordinate system to a position along the
    ruler, in the ruler's coordinate system.
*/
- (float)_rulerPointForLocation:(float)aLocation
{
    var client = [self clientView];

    if ([client respondsToSelector:@selector(rulerView:pointForLocation:)])
    {
        var clientPoint = [client rulerView:self pointForLocation:aLocation];
        return [self _axisValueOfPoint:[self convertPoint:clientPoint fromView:client]];
    }

    return [self _axisValueOfPoint:[self convertPoint:[self _pointOnAxis:aLocation] fromView:client]];
}

/* @ignore
    Converts a position along the ruler, in the ruler's coordinate system, to a location in
    the client view's coordinate system.
*/
- (float)_locationForRulerPoint:(float)aPoint
{
    var client = [self clientView],
        clientPoint = [self convertPoint:[self _pointOnAxis:aPoint] toView:client];

    if ([client respondsToSelector:@selector(rulerView:locationForPoint:)])
        return [client rulerView:self locationForPoint:clientPoint];

    return [self _axisValueOfPoint:clientPoint];
}

/* @ignore */
- (float)_rulerPointForDocumentLocation:(float)aLocation
{
    return [self _axisValueOfPoint:[self convertPoint:[self _pointOnAxis:aLocation] fromView:[_scrollView documentView]]];
}

/* @ignore */
- (CGPoint)_pointOnAxis:(float)aValue
{
    return _orientation === CPHorizontalRuler ? CGPointMake(aValue, 0.0) : CGPointMake(0.0, aValue);
}

/* @ignore */
- (float)_axisValueOfPoint:(CGPoint)aPoint
{
    return _orientation === CPHorizontalRuler ? aPoint.x : aPoint.y;
}

// MARK: Event Handling

/*!
    Starts tracking a marker under the pointer. When no marker is under the pointer, the
    client view handles the event through \c rulerView:handleMouseDown:, for example to add
    a marker.
    @param anEvent the mouse-down event
*/
- (void)mouseDown:(CPEvent)anEvent
{
    var marker = [self _markerAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil]];

    if (marker)
    {
        [marker trackMouse:anEvent adding:NO];
        return;
    }

    var client = [self clientView];

    if ([client respondsToSelector:@selector(rulerView:handleMouseDown:)])
        [client rulerView:self handleMouseDown:anEvent];
}

/*!
    Returns the menu for the marker under the pointer, if the client view supplies one.
    @param anEvent the event that requested the menu
    @return the menu, or \c nil
*/
- (CPMenu)menuForEvent:(CPEvent)anEvent
{
    var marker = [self _markerAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil]],
        client = [self clientView];

    if (marker && [client respondsToSelector:@selector(_rulerView:menuForMarker:)])
        return [client _rulerView:self menuForMarker:marker];

    return [super menuForEvent:anEvent];
}

/* @ignore */
- (CPRulerMarker)_markerAtPoint:(CGPoint)aPoint
{
    // The last marker is drawn on top, so it is hit first.
    for (var i = _markers.length - 1; i >= 0; i--)
    {
        var marker = _markers[i];

        if (CGRectContainsPoint(CGRectInset([marker imageRectInRuler], -2.0, -2.0), aPoint))
            return marker;
    }

    return nil;
}

/* @ignore */
- (void)_setTrackedMarker:(CPRulerMarker)aMarker
{
    _trackedMarker = aMarker;
    [self setNeedsDisplay:YES];
}

// MARK: Client View Methods

/* @ignore */
- (BOOL)_clientShouldAddMarker:(CPRulerMarker)aMarker
{
    var client = [self clientView];

    return ![client respondsToSelector:@selector(rulerView:shouldAddMarker:)] || [client rulerView:self shouldAddMarker:aMarker];
}

/* @ignore */
- (float)_clientWillAddMarker:(CPRulerMarker)aMarker atLocation:(float)aLocation
{
    var client = [self clientView];

    return [client respondsToSelector:@selector(rulerView:willAddMarker:atLocation:)] ? [client rulerView:self willAddMarker:aMarker atLocation:aLocation] : aLocation;
}

/* @ignore */
- (void)_clientDidAddMarker:(CPRulerMarker)aMarker
{
    var client = [self clientView];

    if ([client respondsToSelector:@selector(rulerView:didAddMarker:)])
        [client rulerView:self didAddMarker:aMarker];
}

/* @ignore */
- (BOOL)_clientShouldMoveMarker:(CPRulerMarker)aMarker
{
    var client = [self clientView];

    return ![client respondsToSelector:@selector(rulerView:shouldMoveMarker:)] || [client rulerView:self shouldMoveMarker:aMarker];
}

/* @ignore */
- (float)_clientWillMoveMarker:(CPRulerMarker)aMarker toLocation:(float)aLocation
{
    var client = [self clientView];

    return [client respondsToSelector:@selector(rulerView:willMoveMarker:toLocation:)] ? [client rulerView:self willMoveMarker:aMarker toLocation:aLocation] : aLocation;
}

/* @ignore */
- (void)_clientDidMoveMarker:(CPRulerMarker)aMarker
{
    var client = [self clientView];

    if ([client respondsToSelector:@selector(rulerView:didMoveMarker:)])
        [client rulerView:self didMoveMarker:aMarker];
}

/* @ignore */
- (BOOL)_clientShouldRemoveMarker:(CPRulerMarker)aMarker
{
    var client = [self clientView];

    return ![client respondsToSelector:@selector(rulerView:shouldRemoveMarker:)] || [client rulerView:self shouldRemoveMarker:aMarker];
}

/* @ignore */
- (void)_clientDidRemoveMarker:(CPRulerMarker)aMarker
{
    var client = [self clientView];

    if ([client respondsToSelector:@selector(rulerView:didRemoveMarker:)])
        [client rulerView:self didRemoveMarker:aMarker];
}

@end


var CPRulerViewOrientationKey                       = @"CPRulerViewOrientationKey",
    CPRulerViewClientViewKey                        = @"CPRulerViewClientViewKey",
    CPRulerViewAccessoryViewKey                     = @"CPRulerViewAccessoryViewKey",
    CPRulerViewMarkersKey                           = @"CPRulerViewMarkersKey",
    CPRulerViewRuleThicknessKey                     = @"CPRulerViewRuleThicknessKey",
    CPRulerViewReservedThicknessForMarkersKey       = @"CPRulerViewReservedThicknessForMarkersKey",
    CPRulerViewReservedThicknessForAccessoryViewKey = @"CPRulerViewReservedThicknessForAccessoryViewKey",
    CPRulerViewOriginOffsetKey                      = @"CPRulerViewOriginOffsetKey",
    CPRulerViewMeasurementUnitsKey                  = @"CPRulerViewMeasurementUnitsKey";

@implementation CPRulerView (CPCoding)

/*!
    Initializes a ruler view from an archive. The scroll view that owns the ruler is not
    archived; it sets itself as the ruler's scroll view when it is decoded.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _orientation = [aCoder decodeIntForKey:CPRulerViewOrientationKey];
        _clientView = [aCoder decodeObjectForKey:CPRulerViewClientViewKey];
        _accessoryView = [aCoder decodeObjectForKey:CPRulerViewAccessoryViewKey];
        _markers = [aCoder decodeObjectForKey:CPRulerViewMarkersKey] || [];
        _rulerlineLocations = [];

        _ruleThickness = [aCoder decodeFloatForKey:CPRulerViewRuleThicknessKey];
        _reservedThicknessForMarkers = [aCoder decodeFloatForKey:CPRulerViewReservedThicknessForMarkersKey];
        _reservedThicknessForAccessoryView = [aCoder decodeFloatForKey:CPRulerViewReservedThicknessForAccessoryViewKey];
        _originOffset = [aCoder decodeFloatForKey:CPRulerViewOriginOffsetKey];
        _measurementUnits = [aCoder decodeObjectForKey:CPRulerViewMeasurementUnitsKey] || [[self class] _defaultMeasurementUnits];

        [self invalidateHashMarks];
    }

    return self;
}

/*!
    Archives the ruler view. The client view is archived conditionally.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInt:_orientation forKey:CPRulerViewOrientationKey];
    [aCoder encodeConditionalObject:_clientView forKey:CPRulerViewClientViewKey];
    [aCoder encodeObject:_accessoryView forKey:CPRulerViewAccessoryViewKey];
    [aCoder encodeObject:_markers forKey:CPRulerViewMarkersKey];
    [aCoder encodeFloat:_ruleThickness forKey:CPRulerViewRuleThicknessKey];
    [aCoder encodeFloat:_reservedThicknessForMarkers forKey:CPRulerViewReservedThicknessForMarkersKey];
    [aCoder encodeFloat:_reservedThicknessForAccessoryView forKey:CPRulerViewReservedThicknessForAccessoryViewKey];
    [aCoder encodeFloat:_originOffset forKey:CPRulerViewOriginOffsetKey];
    [aCoder encodeObject:_measurementUnits forKey:CPRulerViewMeasurementUnitsKey];
}

@end
