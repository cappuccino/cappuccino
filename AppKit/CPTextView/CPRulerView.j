/*

    CPRulerView.j
    Created by Daniel Boehringer on 08/01/2016

    Copyright Daniel Boehringer 2016.
    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.
    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
    Lesser General Public License for more details.
    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
*/
@import <AppKit/CPView.j>
@import <AppKit/CPScrollView.j>
@import <AppKit/CPBezierPath.j>
@import <AppKit/CPColor.j>
@import <AppKit/CPStringDrawing.j>
@import <AppKit/CPFont.j>
@import <AppKit/CPImage.j>
@import <Foundation/CPAttributedString.j>

@class CPRulerMarker

@global CPHorizontalRuler
@global CPVerticalRuler

// Constants for layout
var DEFAULT_RULE_THICKNESS      = 16.0,
    DEFAULT_MARKER_THICKNESS    = 15.0,
    HASH_MARK_THICKNESS_FACTOR  = 0.6,
    HASH_MARK_WIDTH             = 1.0,
    LABEL_TEXT_PADDING          = 2.0;

var _measurementUnits = nil;

// -----------------------------------------------------------------------------
// Helper Class: _CPMeasurementUnit
// -----------------------------------------------------------------------------

@implementation _CPMeasurementUnit : CPObject
{
    CPString    _name @accessors(property = name);
    CPString    _abbreviation @accessors(property = abbreviation);
    float       _pointsPerUnit @accessors(property = pointsPerUnit);
    CPArray     _stepUpCycle @accessors(property = stepUpCycle);
    CPArray     _stepDownCycle @accessors(property = stepDownCycle);
}

+ (void)initialize
{
    if (self !== [_CPMeasurementUnit class])
        return;

    _measurementUnits = [];

    [self registerUnit:[_CPMeasurementUnit inchesMeasurementUnit]];
    [self registerUnit:[_CPMeasurementUnit centimetersMeasurementUnit]];
    [self registerUnit:[_CPMeasurementUnit pointsMeasurementUnit]];
    [self registerUnit:[_CPMeasurementUnit picasMeasurementUnit]];
}

+ (_CPMeasurementUnit)measurementUnitWithName:(CPString)name abbreviation:(CPString)abbreviation pointsPerUnit:(float)points stepUpCycle:(CPArray)upCycle stepDownCycle:(CPArray)downCycle
{
    return [[self alloc] initWithName:name abbreviation:abbreviation pointsPerUnit:points stepUpCycle:upCycle stepDownCycle:downCycle];
}

- (id)initWithName:(CPString)name abbreviation:(CPString)abbreviation pointsPerUnit:(float)points stepUpCycle:(CPArray)upCycle stepDownCycle:(CPArray)downCycle
{
    self = [super init];
    if (self)
    {
        _name = name;
        _abbreviation = abbreviation;
        _pointsPerUnit = points;
        _stepUpCycle = upCycle;
        _stepDownCycle = downCycle;
    }
    return self;
}

+ (_CPMeasurementUnit)inchesMeasurementUnit
{
    return [self measurementUnitWithName:@"Inches"
                            abbreviation:@"in"
                           pointsPerUnit:72.0
                             stepUpCycle:[ [CPNumber numberWithFloat:2.0], [CPNumber numberWithFloat:5.0], [CPNumber numberWithFloat:10.0] ]
                           stepDownCycle:[ [CPNumber numberWithFloat:0.5], [CPNumber numberWithFloat:0.25], [CPNumber numberWithFloat:0.125] ]];
}

+ (_CPMeasurementUnit)centimetersMeasurementUnit
{
    return [self measurementUnitWithName:@"Centimeters"
                            abbreviation:@"cm"
                           pointsPerUnit:28.3465
                             stepUpCycle:[ [CPNumber numberWithFloat:2.0], [CPNumber numberWithFloat:5.0], [CPNumber numberWithFloat:10.0] ]
                           stepDownCycle:[ [CPNumber numberWithFloat:0.5], [CPNumber numberWithFloat:0.1] ]];
}

+ (_CPMeasurementUnit)pointsMeasurementUnit
{
    return [self measurementUnitWithName:@"Points"
                            abbreviation:@"pt"
                           pointsPerUnit:1.0
                             stepUpCycle:[ [CPNumber numberWithFloat:10.0], [CPNumber numberWithFloat:50.0], [CPNumber numberWithFloat:100.0] ]
                           stepDownCycle:[ [CPNumber numberWithFloat:0.5] ]]; // Points rarely sub-divide
}

+ (_CPMeasurementUnit)picasMeasurementUnit
{
    return [self measurementUnitWithName:@"Picas"
                            abbreviation:@"pc"
                           pointsPerUnit:12.0
                             stepUpCycle:[ [CPNumber numberWithFloat:2.0], [CPNumber numberWithFloat:5.0], [CPNumber numberWithFloat:10.0] ]
                           stepDownCycle:[ [CPNumber numberWithFloat:0.5], [CPNumber numberWithFloat:0.0833] ]]; // 6p and 1pt
}

+ (CPArray)allMeasurementUnits
{
    return _measurementUnits;
}

+ (_CPMeasurementUnit)measurementUnitNamed:(CPString)name
{
    var i = 0, count = [_measurementUnits count];
    for (; i < count; ++i)
        if ([[[_measurementUnits objectAtIndex:i] name] isEqualToString:name])
            return [_measurementUnits objectAtIndex:i];
    return nil;
}

+ (void)registerUnit:(_CPMeasurementUnit)unit
{
    if (!_measurementUnits) _measurementUnits = [];
    [_measurementUnits addObject:unit];
}

@end

// -----------------------------------------------------------------------------
// Class: CPRulerView
// -----------------------------------------------------------------------------

@implementation CPRulerView : CPView
{
    CPScrollView        _scrollView;
    CPView              _clientView;
    CPView              _accessoryView;
    CPArray             _markers;
    _CPMeasurementUnit  _measurementUnit;
    CPMutableArray      _rulerlineLocations;

    float               _originOffset;
    float               _ruleThickness;
    float               _thicknessForMarkers;
    float               _thicknessForAccessoryView;

    CPRulerOrientation  _orientation;
    
    // Cache attributes
    CPDictionary        _labelAttributes;
}

// MARK: - Class Methods

+ (void)registerUnitWithName:(CPString)name abbreviation:(CPString)abbreviation unitToPointsConversionFactor:(float)conversionFactor stepUpCycle:(CPArray)stepUpCycle stepDownCycle:(CPArray)stepDownCycle
{
    [_CPMeasurementUnit registerUnit:[_CPMeasurementUnit measurementUnitWithName:name abbreviation:abbreviation pointsPerUnit:conversionFactor stepUpCycle:stepUpCycle stepDownCycle:stepDownCycle]];
}

// MARK: - Initialization

- (id)initWithFrame:(CPRect)frame
{
    return [self initWithScrollView:nil orientation:CPHorizontalRuler];
}

- (id)initWithScrollView:(CPScrollView)scrollView orientation:(CPRulerOrientation)orientation
{
    var frame = CPMakeRect(0, 0, 1, 1);
    
    // Determine initial frame based on standard thickness
    if (orientation == CPHorizontalRuler)
        frame.size.height = DEFAULT_RULE_THICKNESS;
    else
        frame.size.width = DEFAULT_RULE_THICKNESS;

    self = [super initWithFrame:frame];
    
    if (self)
    {
        _scrollView = scrollView;
        _orientation = orientation;
        _measurementUnit = [_CPMeasurementUnit measurementUnitNamed:@"Inches"];
        
        _ruleThickness = DEFAULT_RULE_THICKNESS;
        _thicknessForMarkers = 0.0; // Grows as needed
        _thicknessForAccessoryView = 0.0;
        _originOffset = 0.0;
        
        _markers = [];
        _rulerlineLocations = [];

        var style = [[CPParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setLineBreakMode:CPLineBreakByClipping];
        [style setAlignment:CPLeftTextAlignment];
        _labelAttributes = @{
            CPFontAttributeName: [CPFont systemFontOfSize:9.0], 
            CPParagraphStyleAttributeName: style,
            CPForegroundColorAttributeName: [CPColor blackColor]
        };
    }
    
    return self;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    if (self)
    {
        _scrollView = [aCoder decodeObjectForKey:@"CPScrollView"];
        _orientation = [aCoder decodeIntForKey:@"CPOrientation"];
        _markers = [aCoder decodeObjectForKey:@"CPMarkers"];
        if (!_markers) _markers = [];
        
        // Defaults
        _ruleThickness = DEFAULT_RULE_THICKNESS;
        _measurementUnit = [_CPMeasurementUnit measurementUnitNamed:@"Inches"];
        _rulerlineLocations = [];
    }
    return self;
}

// MARK: - Layout & Metrics

- (float)reservedThicknessForMarkers
{
    if ([_markers count] > 0 && _thicknessForMarkers < DEFAULT_MARKER_THICKNESS)
        return DEFAULT_MARKER_THICKNESS;
        
    return _thicknessForMarkers;
}

- (float)reservedThicknessForAccessoryView
{
    return _thicknessForAccessoryView;
}

- (float)ruleThickness
{
    return _ruleThickness;
}

- (float)requiredThickness
{
    var result = [self ruleThickness];

    if ([_markers count] > 0)
        result += [self reservedThicknessForMarkers];

    if (_accessoryView)
        result += [self reservedThicknessForAccessoryView];

    return result;
}

- (float)baselineLocation
{
    // The baseline is the line separating the ruler from the content.
    // In a horizontal ruler, it's the bottom edge (height). 
    // Usually, the hash marks grow upwards from this baseline.
    return [self bounds].size.height;
}

// MARK: - Accessors

- (CPScrollView)scrollView
{
    return _scrollView;
}

- (void)setScrollView:(CPScrollView)scrollView
{
    _scrollView = scrollView;
    [self setNeedsDisplay:YES];
}

- (CPRulerOrientation)orientation
{
    return _orientation;
}

- (void)setOrientation:(CPRulerOrientation)orientation
{
    _orientation = orientation;
    [self setNeedsDisplay:YES];
}

- (CPView)clientView
{
    return _clientView;
}

- (void)setClientView:(CPView)view
{
    if (_clientView === view) return;
    
    if ([_clientView respondsToSelector:@selector(rulerView:willSetClientView:)])
        [_clientView rulerView:self willSetClientView:view];
        
    // Standard behavior: clear markers when client changes unless preserved
    [_markers removeAllObjects];
    _clientView = view;

    [self invalidateHashMarks];
    [[self enclosingScrollView] tile];
}

- (CPView)accessoryView
{
    return _accessoryView;
}

- (void)setAccessoryView:(CPView)view
{
    if (_accessoryView === view) return;
    
    [_accessoryView removeFromSuperview];
    _accessoryView = view;
    
    if (_accessoryView)
    {
        [self addSubview:_accessoryView];
        // Usually you'd set the frame here based on thickness
    }

    [[self enclosingScrollView] tile];
}

- (CPArray)markers
{
    return _markers;
}

- (void)setMarkers:(CPArray)markers
{
    if (_markers === markers) return;
    _markers = [markers mutableCopy];
    [[self enclosingScrollView] tile];
    [self setNeedsDisplay:YES];
}

- (void)addMarker:(CPRulerMarker)marker
{
    [_markers addObject:marker];
    [marker setRulerView:self]; // Ensure marker knows its ruler
    [[self enclosingScrollView] tile];
    [self setNeedsDisplay:YES];
}

- (void)removeMarker:(CPRulerMarker)marker
{
    [_markers removeObject:marker];
    [[self enclosingScrollView] tile];
    [self setNeedsDisplay:YES];
}

- (void)setMeasurementUnits:(CPString)unitName
{
    var unit = [_CPMeasurementUnit measurementUnitNamed:unitName];
    if (unit)
    {
        _measurementUnit = unit;
        [self setNeedsDisplay:YES];
    }
}

- (CPString)measurementUnits
{
    return [_measurementUnit name];
}

- (void)setOriginOffset:(float)value
{
    _originOffset = value;
    [self setNeedsDisplay:YES];
}

- (float)originOffset
{
    return _originOffset;
}

- (void)setRuleThickness:(float)value
{
    _ruleThickness = value;
    [[self enclosingScrollView] tile];
}

- (void)setReservedThicknessForMarkers:(float)value
{
    _thicknessForMarkers = value;
    [[self enclosingScrollView] tile];
}

- (void)setReservedThicknessForAccessoryView:(float)value
{
    _thicknessForAccessoryView = value;
    [[self enclosingScrollView] tile];
}

// MARK: - Event Handling

- (BOOL)trackMarker:(CPRulerMarker)marker withMouseEvent:(CPEvent)event
{
    // Convert event location to ruler coordinates
    var point = [self convertPoint:[event locationInWindow] fromView:nil];

    // Basic hit testing logic
    if (CPPointInRect(point, [self bounds]))
    {
        // Marker implements trackMouse:adding:
        if ([marker respondsToSelector:@selector(trackMouse:adding:)])
        {
            [marker trackMouse:event adding:YES];
        }
        [self setNeedsDisplay:YES];
        return YES;
    }

    return NO;
}

- (void)mouseDown:(CPEvent)event
{
    var point = [self convertPoint:[event locationInWindow] fromView:nil],
        i = 0, count = [_markers count];

    // 1. Check if an existing marker was clicked
    for (; i < count; ++i)
    {
        var marker = [_markers objectAtIndex:i];
        if (CPPointInRect(point, [marker imageRectInRuler]))
        {
            [marker trackMouse:event adding:NO];
            [self setNeedsDisplay:YES];
            return;
        }
    }

    // 2. Delegate to Client View (e.g. to create a new guide/marker)
    if ([_clientView respondsToSelector:@selector(rulerView:handleMouseDown:)])
        [_clientView rulerView:self handleMouseDown:event];
}

// MARK: - Drawing Support

- (void)moveRulerlineFromLocation:(float)fromLocation toLocation:(float)toLocation
{
    var oldLoc = [CPNumber numberWithFloat:fromLocation],
        newLoc = [CPNumber numberWithFloat:toLocation];

    [_rulerlineLocations removeObject:oldLoc];
    
    // Only add if it's not effectively "off" (using -1 as a convention for hiding)
    if (toLocation >= 0)
        [_rulerlineLocations addObject:newLoc];

    [self setNeedsDisplay:YES];
}

- (void)invalidateHashMarks
{
    [self setNeedsDisplay:YES];
}

// MARK: - Drawing Implementation

- (BOOL)isFlipped
{
    if (_orientation == CPHorizontalRuler)
        return YES; // Horizontal rulers usually draw top-down or match standard flipped views

    // For vertical rulers, we usually want to match the document view's flip state
    // so numbers increase going down if the document does.
    if (_clientView)
        return [_clientView isFlipped];
        
    return YES;
}

- (float)_drawingScale
{
    // Zoom support
    var scale = 1.0,
        docView = [_scrollView documentView];
        
    if (docView && [docView superview])
    {
        // Calculate scale based on bounds vs frame
        var bounds = [docView bounds],
            frame = [docView frame];
            
        if (_orientation == CPHorizontalRuler)
            scale = frame.size.width / bounds.size.width;
        else
            scale = frame.size.height / bounds.size.height;
    }
    return scale;
}

- (float)_drawingOrigin
{
    // Calculate the point in the ruler that corresponds to "0" in the client view
    var origin = 0.0,
        trackedView = _clientView;

    if (!trackedView)
        trackedView = [_scrollView documentView];
        
    if (!trackedView) return 0.0;

    // Convert (0,0) of the tracked view to the ruler's coordinate space
    var viewZero = [self convertPoint:CGPointMake(0,0) fromView:trackedView];
    
    if (_orientation == CPHorizontalRuler)
        origin = viewZero.x;
    else
        origin = viewZero.y;
        
    // Apply user-defined offset (e.g. if the user dragged the zero-point)
    // Note: originOffset is in client coordinates, so we scale it.
    origin += (_originOffset * [self _drawingScale]);
    
    return origin;
}

- (void)drawHashMarksAndLabelsInRect:(CPRect)dirtyRect
{
    var bounds = [self bounds],
        scale = [self _drawingScale],
        zeroLocation = [self _drawingOrigin], // x position (horiz) or y position (vert) where 0 is
        pointsPerUnit = [_measurementUnit pointsPerUnit] * scale;
        
    // Avoid divide by zero
    if (pointsPerUnit <= 0) return;

    var isHorizontal = (_orientation == CPHorizontalRuler),
        ruleSize = isHorizontal ? bounds.size.height : bounds.size.width;

    // Adjust for markers/accessory thickness area
    var reserved = 0.0;
    if ([_markers count] > 0) reserved += [self reservedThicknessForMarkers];
    if (_accessoryView) reserved += [self reservedThicknessForAccessoryView];
    
    // The actual area for hashes
    var hashAreaSize = ruleSize - reserved,
        hashBaseline = reserved; // Drawing starts after reserved area

    // Calculate range of units to draw based on dirtyRect
    var startPos = isHorizontal ? dirtyRect.origin.x : dirtyRect.origin.y,
        endPos = isHorizontal ? CPReectGetMaxX(dirtyRect) : CPReectGetMaxY(dirtyRect);

    // Convert view coordinates to Unit coordinates
    // pos = zeroLocation + (unit * pointsPerUnit)
    // unit = (pos - zeroLocation) / pointsPerUnit
    var startUnit = Math.floor((startPos - zeroLocation) / pointsPerUnit),
        endUnit   = Math.ceil((endPos - zeroLocation) / pointsPerUnit);

    var stepDowns = [_measurementUnit stepDownCycle],
        numSteps = [stepDowns count];

    [[CPColor grayColor] setStroke];
    
    // Iterate through units
    for (var u = startUnit; u <= endUnit; u++)
    {
        var unitPos = zeroLocation + (u * pointsPerUnit);
        
        // 1. Draw Major Mark
        var majorHeight = hashAreaSize * HASH_MARK_THICKNESS_FACTOR;
        [self _drawHashAt:unitPos length:majorHeight offset:hashBaseline horizontal:isHorizontal];
        
        // 2. Draw Label (only for major units)
        var labelStr = [CPString stringWithFormat:@"%d", u];
        
        // Simple label positioning
        var labelPoint;
        if (isHorizontal)
            labelPoint = CPMakePoint(unitPos + LABEL_TEXT_PADDING, hashBaseline);
        else
            labelPoint = CPMakePoint(hashBaseline + LABEL_TEXT_PADDING, unitPos);

        [labelStr drawAtPoint:labelPoint withAttributes:_labelAttributes];

        // 3. Draw Subdivisions
        // We handle a simple single-level subdivision for performance, 
        // or iterate the cycle. Let's do a simple iterative cycle.
        
        // E.g. stepDownCycle: [0.5, 0.25, 0.125] implies 1/2, then 1/4, etc.
        // But the CPMeasurementUnit spec in the prompt suggests relative steps.
        // Let's assume the array contains fractions of the unit: e.g. [0.5, 0.1]
        
        for (var s = 0; s < numSteps; s++)
        {
            var stepFraction = [[stepDowns objectAtIndex:s] floatValue];
            if (stepFraction <= 0) continue;
            
            // Determine visual spacing. If marks are too close, stop recursing.
            var pixelsPerStep = pointsPerUnit * stepFraction;
            if (pixelsPerStep < 4.0) break; 
            
            // Calculate height: gradually smaller
            var subHeight = majorHeight * (0.7 / (s + 1)); 

            // How many marks fit in one unit? 1 / fraction.
            // e.g. 0.5 -> 2 marks (at 0.0 and 0.5). 0.0 is major, so we draw at 0.5.
            var subCount = Math.round(1.0 / stepFraction);
            
            for (var k = 1; k < subCount; k++)
            {
                // We only draw if this position wasn't covered by a higher-level step.
                // Simplified: Just draw everything, simpler logic for UI.
                // Optimization: Skip if integer check passes? No, keep it simple.
                
                var subUnitOffset = k * stepFraction;
                // Only draw if this isn't a whole integer (covered by major)
                if (subUnitOffset % 1.0 === 0) continue; 
                
                var subPos = unitPos + (subUnitOffset * pointsPerUnit);
                
                // Bounds check optimization
                if (subPos < startPos || subPos > endPos) continue;

                [self _drawHashAt:subPos length:subHeight offset:hashBaseline horizontal:isHorizontal];
            }
        }
    }
}

- (void)_drawHashAt:(float)pos length:(float)length offset:(float)offset horizontal:(BOOL)isHorizontal
{
    var path = [CPBezierPath bezierPath];
    [path setLineWidth:1.0];
    
    if (isHorizontal)
    {
        // Draw vertical line at 'pos'
        [path moveToPoint:CPMakePoint(pos + 0.5, offset + [self bounds].size.height - length)]; // Draw from bottom up
        [path lineToPoint:CPMakePoint(pos + 0.5, [self bounds].size.height)];
        
        // Or if flipped (top-down), draw from offset down
        // Since we force isFlipped=YES for horizontal, y=0 is top.
        // Typically rulers align marks to the edge touching the content.
        [path moveToPoint:CPMakePoint(pos + 0.5, offset + [self bounds].size.height - length)];
        [path lineToPoint:CPMakePoint(pos + 0.5, offset + [self bounds].size.height)];
    }
    else
    {
        // Draw horizontal line at 'pos'
        [path moveToPoint:CPMakePoint(offset + [self bounds].size.width - length, pos + 0.5)];
        [path lineToPoint:CPMakePoint(offset + [self bounds].size.width, pos + 0.5)];
    }
    
    [path stroke];
}

- (void)drawMarkersInRect:(CPRect)dirtyRect
{
    var count = [_markers count];
    for (var i = 0; i < count; i++)
    {
        var m = [_markers objectAtIndex:i];
        if (CPRectIntersectsRect([m imageRectInRuler], dirtyRect))
            [m drawRect:dirtyRect];
    }
}

- (void)drawRulerlineLocationsInRect:(CPRect)rect
{
    var count = [_rulerlineLocations count];
    if (count === 0) return;

    [[CPColor controlShadowColor] setStroke];
    
    var bounds = [self bounds];
    
    for (var i = 0; i < count; ++i)
    {
        var loc = [[_rulerlineLocations objectAtIndex:i] floatValue];
        
        var path = [CPBezierPath bezierPath];
        if (_orientation == CPHorizontalRuler)
        {
            [path moveToPoint:CPMakePoint(loc + 0.5, 0)];
            [path lineToPoint:CPMakePoint(loc + 0.5, bounds.size.height)];
        }
        else
        {
            [path moveToPoint:CPMakePoint(0, loc + 0.5)];
            [path lineToPoint:CPMakePoint(bounds.size.width, loc + 0.5)];
        }
        [path stroke];
    }
}

- (void)drawRect:(CPRect)dirtyRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];

    // 1. Draw Background
    [[CPColor colorWithCalibratedWhite:0.96 alpha:1.0] setFill];
    CGContextFillRect(context, dirtyRect);

    // 2. Draw Bottom/Right Border (Baseline)
    [[CPColor darkGrayColor] setStroke];
    var borderPath = [CPBezierPath bezierPath];
    var bounds = [self bounds];

    if (_orientation == CPHorizontalRuler)
    {
        [borderPath moveToPoint:CPMakePoint(0, bounds.size.height - 0.5)];
        [borderPath lineToPoint:CPMakePoint(bounds.size.width, bounds.size.height - 0.5)];
    }
    else
    {
        [borderPath moveToPoint:CPMakePoint(bounds.size.width - 0.5, 0)];
        [borderPath lineToPoint:CPMakePoint(bounds.size.width - 0.5, bounds.size.height)];
    }
    [borderPath stroke];

    // 3. Draw Contents
    [self drawHashMarksAndLabelsInRect:dirtyRect];

    if ([_markers count] > 0)
        [self drawMarkersInRect:dirtyRect];

    if ([_rulerlineLocations count] > 0)
        [self drawRulerlineLocationsInRect:dirtyRect];
}

@end

@implementation CPRulerMarker : CPObject
{
    CPRulerView     _ruler;
    float           _markerLocation;
    CPImage         _image;
    CPPoint         _imageOrigin;
    
    BOOL            _movable @accessors(property=movable);
    BOOL            _removable @accessors(property=removable);
    
    id              _representedObject @accessors(property=representedObject);
    
    // Internal state
    BOOL            _dragging @accessors(getter=isDragging);
}

// MARK: - Initialization

- (id)initWithRulerView:(CPRulerView)aRuler markerLocation:(float)location image:(CPImage)anImage imageOrigin:(CPPoint)anImageOrigin
{
    self = [super init];
    if (self)
    {
        _ruler = aRuler;
        _markerLocation = location;
        _image = anImage;
        _imageOrigin = anImageOrigin;
        
        _movable = NO;
        _removable = NO;
        _dragging = NO;
    }
    return self;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    if (self)
    {
        // Ruler is usually assigned after decoding by the view hierarchy
        _markerLocation = [aCoder decodeFloatForKey:@"CPMarkerLocation"];
        _image = [aCoder decodeObjectForKey:@"CPImage"];
        _imageOrigin = [aCoder decodePointForKey:@"CPImageOrigin"];
        _movable = [aCoder decodeBoolForKey:@"CPMovable"];
        _removable = [aCoder decodeBoolForKey:@"CPRemovable"];
        _representedObject = [aCoder decodeObjectForKey:@"CPRepresentedObject"];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeFloat:_markerLocation forKey:@"CPMarkerLocation"];
    [aCoder encodeObject:_image forKey:@"CPImage"];
    [aCoder encodePoint:_imageOrigin forKey:@"CPImageOrigin"];
    [aCoder encodeBool:_movable forKey:@"CPMovable"];
    [aCoder encodeBool:_removable forKey:@"CPRemovable"];
    [aCoder encodeObject:_representedObject forKey:@"CPRepresentedObject"];
}

- (id)copy
{
    var copy = [[CPRulerMarker alloc] initWithRulerView:_ruler 
                                         markerLocation:_markerLocation 
                                                  image:_image 
                                            imageOrigin:_imageOrigin];
    [copy setMovable:_movable];
    [copy setRemovable:_removable];
    [copy setRepresentedObject:_representedObject];
    return copy;
}

// MARK: - Accessors

- (CPRulerView)ruler
{
    return _ruler;
}

// Used when adding a marker to a ruler
- (void)setRulerView:(CPRulerView)aRuler
{
    _ruler = aRuler;
}

- (CPImage)image
{
    return _image;
}

- (void)setImage:(CPImage)anImage
{
    _image = anImage;
    [_ruler setNeedsDisplay:YES];
}

- (CPPoint)imageOrigin
{
    return _imageOrigin;
}

- (void)setImageOrigin:(CPPoint)aPoint
{
    _imageOrigin = aPoint;
    [_ruler setNeedsDisplay:YES];
}

- (float)markerLocation
{
    return _markerLocation;
}

- (void)setMarkerLocation:(float)location
{
    if (_markerLocation === location) return;
    
    _markerLocation = location;
    
    // Invalidate the ruler to redraw at new position
    [_ruler setNeedsDisplay:YES];
}

// MARK: - Geometry

- (float)thicknessRequiredInRuler
{
    if (!_image) return 0.0;
    
    // If horizontal ruler, thickness is image height.
    // If vertical ruler, thickness is image width.
    var size = [_image size];
    
    if ([_ruler orientation] === CPHorizontalRuler)
        return size.height;
    else
        return size.width;
}

- (CPRect)imageRectInRuler
{
    if (!_ruler || !_image) return CPMakeRect(0,0,0,0);

    var clientView = [_ruler clientView];
    // If no client view, fallback to document view or 0
    if (!clientView) clientView = [[_ruler scrollView] documentView];
    
    var rulerBounds = [_ruler bounds],
        imageSize = [_image size],
        rect = CPMakeRect(0, 0, imageSize.width, imageSize.height);

    // 1. Convert Marker Location (Client Coords) to Ruler Coords
    var locationInRuler = 0.0;
    
    if (clientView)
    {
        // We create a point in the client view at the marker location
        var ptInClient = CPMakePoint(0, 0);
        
        if ([_ruler orientation] === CPHorizontalRuler)
            ptInClient.x = _markerLocation;
        else
            ptInClient.y = _markerLocation;
            
        // Convert that point to the ruler's coordinate system
        var ptInRuler = [_ruler convertPoint:ptInClient fromView:clientView];
        
        locationInRuler = ([_ruler orientation] === CPHorizontalRuler) ? ptInRuler.x : ptInRuler.y;
    }
    
    // Apply user offset from CPRulerView (originOffset)
    // Note: The conversion above usually handles view transforms, but if CPRulerView 
    // manually applies an extra offset property (like in the previous implementation), 
    // we should respect it implicitly via the conversion or explicitly here.
    // Assuming standard view conversion handles the scroll/bounds.
    
    // 2. Position the rect based on Orientation and Image Origin
    // imageOrigin is the point *inside* the image that aligns with 'locationInRuler'
    
    if ([_ruler orientation] === CPHorizontalRuler)
    {
        // X: Aligned by location minus the hotspot X
        rect.origin.x = locationInRuler - _imageOrigin.x;
        
        // Y: This depends on the ruler's baseline. 
        // Typically horizontal markers sit on the bottom edge (baseline).
        // If the image origin Y is the "tip", we position relative to that.
        // Usually, imageOrigin.y is 0 (bottom) or Height (top) depending on coordinate flip.
        
        // Assuming the ruler draws labels near the baseline and the marker sits on it:
        // Let's assume the baseline is the bottom of the ruler rect.
        var baseline = [_ruler baselineLocation]; 
        rect.origin.y = baseline - _imageOrigin.y;
        
        // If flipped, adjustments might be needed, but usually image drawing handles internal flip.
    }
    else
    {
        // Vertical Ruler
        // Y: Aligned by location minus hotspot Y
        rect.origin.y = locationInRuler - _imageOrigin.y;
        
        // X: Align to right edge (baseline)
        var baseline = [_ruler baselineLocation]; // Width for vertical ruler
        rect.origin.x = baseline - _imageOrigin.x;
    }

    return rect;
}

// MARK: - Drawing

- (void)drawRect:(CPRect)aRect
{
    if (!_image) return;
    
    var rect = [self imageRectInRuler];
    
    // Only draw if visible
    if (CPRectIntersectsRect(rect, aRect))
    {
        // Visual feedback for dragging
        var opacity = _dragging ? 0.5 : 1.0;
        
        [_image drawInRect:rect fromRect:CPZeroRect operation:CPCompositeSourceOver fraction:opacity];
    }
}

// MARK: - Event Handling

- (BOOL)trackMouse:(CPEvent)anEvent adding:(BOOL)adding
{
    if (!adding && !_movable) return NO;

    var clientView = [_ruler clientView],
        delegate = clientView; // The client view acts as the delegate usually
        
    // Delegate Check: Should we move/add?
    if (adding)
    {
        if ([delegate respondsToSelector:@selector(rulerView:shouldAddMarker:)] && 
            ![delegate rulerView:_ruler shouldAddMarker:self])
            return NO;
    }
    else
    {
        if ([delegate respondsToSelector:@selector(rulerView:shouldMoveMarker:)] && 
            ![delegate rulerView:_ruler shouldMoveMarker:self])
            return NO;
    }
    
    // If adding, we ensure the marker is in the array so it draws
    if (adding)
        [_ruler addMarker:self];

    [self setDragging:YES];
    
    var type = [anEvent type],
        originalLocation = _markerLocation;

    // Start Event Loop
    while (type !== CPLeftMouseUp)
    {
        // 1. Calculate new location
        var locationInWindow = [anEvent locationInWindow],
            pointInClient = [clientView convertPoint:locationInWindow fromView:nil],
            newLocation = ([_ruler orientation] === CPHorizontalRuler) ? pointInClient.x : pointInClient.y;
            
        // 2. Delegate: Will Move? (Snap logic usually happens here)
        if ([delegate respondsToSelector:@selector(rulerView:willMoveMarker:toLocation:)])
        {
            newLocation = [delegate rulerView:_ruler willMoveMarker:self toLocation:newLocation];
        }
        
        // 3. Update Location
        [self setMarkerLocation:newLocation];
        
        // 4. Handle "Tearing off" (Removal visual feedback)
        // Check if mouse is far outside the ruler's bounds
        var pointInRuler = [_ruler convertPoint:locationInWindow fromView:nil];
        var rulerBounds = [_ruler bounds];
        // Expand bounds slightly for tolerance
        var expandedBounds = CPMakeRect(rulerBounds.origin.x - 20, rulerBounds.origin.y - 20, 
                                        rulerBounds.size.width + 40, rulerBounds.size.height + 40);
                                        
        var isFarAway = !CPPointInRect(pointInRuler, expandedBounds);
        
        // You might change the cursor here to a "poof" cursor if isFarAway && _removable
        
        // 5. Get next event
        anEvent = [[CPApp currentEvent] window] ? [[CPApp currentEvent] window] : [CPApp keyWindow]; // fallback
        anEvent = [CPApp nextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask
                                     untilDate:[CPDate distantFuture]
                                        inMode:CPDefaultRunLoopMode
                                       dequeue:YES];
        type = [anEvent type];
    }
    
    [self setDragging:NO];
    
    // Finalize
    var pointInRuler = [_ruler convertPoint:[anEvent locationInWindow] fromView:nil],
        rulerBounds = [_ruler bounds],
        expandedBounds = CPMakeRect(rulerBounds.origin.x - 10, rulerBounds.origin.y - 10, 
                                    rulerBounds.size.width + 20, rulerBounds.size.height + 20),
        shouldRemove = _removable && !CPPointInRect(pointInRuler, expandedBounds);

    if (shouldRemove)
    {
        var allowed = YES;
        if ([delegate respondsToSelector:@selector(rulerView:shouldRemoveMarker:)])
            allowed = [delegate rulerView:_ruler shouldRemoveMarker:self];
            
        if (allowed)
        {
            [_ruler removeMarker:self];
            // Don't call didMove or didAdd if removed
            return YES;
        }
    }

    // Success notification
    if (adding)
    {
        if ([delegate respondsToSelector:@selector(rulerView:didAddMarker:)])
            [delegate rulerView:_ruler didAddMarker:self];
    }
    else
    {
        if ([delegate respondsToSelector:@selector(rulerView:didMoveMarker:)])
            [delegate rulerView:_ruler didMoveMarker:self];
    }
    
    return YES;
}

@end
