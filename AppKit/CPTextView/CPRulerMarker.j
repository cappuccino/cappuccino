/*
 *  CPRulerMarker.j
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

@import <Foundation/CPObject.j>

@import "CGGeometry.j"
@import "CPEvent.j"
@import "CPGraphicsContext.j"
@import "CPImage.j"

@class CPRulerView

@global CPApp
@global CPHorizontalRuler


/*!
    Distance, in points, that the pointer must move beyond the ruler before a removable
    marker is removed when it is released.
*/
var CPRulerMarkerRemovalDistance = 0.0;

/*!
    @ingroup appkit
    @class CPRulerMarker

    A CPRulerMarker shows a location on a CPRulerView, such as a tab stop or a paragraph
    indent. The marker is drawn by its ruler view as an image, positioned so that the
    image's \c imageOrigin lies at the marker's location on the ruler's baseline. The
    marker's location is expressed in the coordinate system of the ruler's client view.

    The user can drag a movable marker along the ruler, and drag a removable marker off the
    ruler to remove it. The ruler's client view is consulted through the CPRulerView client
    methods before and after each change.
*/
@implementation CPRulerMarker : CPObject
{
    CPRulerView     _ruler;
    float           _markerLocation;
    CPImage         _image;
    CGPoint         _imageOrigin;
    BOOL            _isMovable;
    BOOL            _isRemovable;
    BOOL            _isDragging;
    BOOL            _isOffRuler;
    id              _representedObject;

    float           _trackingStartLocation;
    float           _trackingStartPoint;
    float           _trackingStartCrossPoint;
    float           _trackingCrossOffset;
    BOOL            _trackingIsAdding;
    BOOL            _trackingMoved;
}

/*!
    Initializes a marker for \c aRulerView at \c aLocation, drawn with \c anImage. The
    marker is associated with the ruler view, but not added to it. A new marker is movable
    and not removable.
    @param aRulerView the ruler view the marker belongs to
    @param aLocation the marker's location, in the client view's coordinate system
    @param anImage the image drawn for the marker
    @param anImageOrigin the point in the image, measured from its top left corner, placed
    at the marker's location on the ruler's baseline
    @return the initialized marker
*/
- (id)initWithRulerView:(CPRulerView)aRulerView markerLocation:(float)aLocation image:(CPImage)anImage imageOrigin:(CGPoint)anImageOrigin
{
    self = [super init];

    if (self)
    {
        _ruler = aRulerView;
        _markerLocation = aLocation;
        _image = anImage;
        _imageOrigin = CGPointMakeCopy(anImageOrigin);
        _isMovable = YES;
        _isRemovable = NO;
        _isDragging = NO;
        _isOffRuler = NO;
    }

    return self;
}

// MARK: Getting the Ruler View

/*!
    Returns the ruler view the marker belongs to.
*/
- (CPRulerView)ruler
{
    return _ruler;
}

// MARK: Setting the Image

/*!
    Returns the image drawn for the marker.
*/
- (CPImage)image
{
    return _image;
}

/*!
    Sets the image drawn for the marker.
    @param anImage the new image
*/
- (void)setImage:(CPImage)anImage
{
    if (_image === anImage)
        return;

    _image = anImage;
    [_ruler setNeedsDisplay:YES];
}

/*!
    Returns the point in the image, measured from its top left corner, that is placed at
    the marker's location on the ruler's baseline.
*/
- (CGPoint)imageOrigin
{
    return _imageOrigin;
}

/*!
    Sets the point in the image, measured from its top left corner, that is placed at the
    marker's location on the ruler's baseline.
    @param aPoint the new image origin
*/
- (void)setImageOrigin:(CGPoint)aPoint
{
    _imageOrigin = CGPointMakeCopy(aPoint);
    [_ruler setNeedsDisplay:YES];
}

/*!
    Returns the rectangle that the marker's image occupies, in the ruler view's coordinate
    system.
*/
- (CGRect)imageRectInRuler
{
    var imageSize = [_image size] || CGSizeMakeZero(),
        point = [_ruler _rulerPointForLocation:_markerLocation],
        baseline = [_ruler baselineLocation];

    // Whole-point positions keep every marker image sharp and identical, wherever it lies on the ruler.
    // While the user drags the marker outward, it follows the pointer across the ruler.
    var crossPosition = baseline + (_isDragging ? _trackingCrossOffset : 0.0);

    if ([_ruler orientation] === CPHorizontalRuler)
        return CGRectMake(ROUND(point - _imageOrigin.x), ROUND(crossPosition - _imageOrigin.y), imageSize.width, imageSize.height);

    return CGRectMake(ROUND(crossPosition - _imageOrigin.x), ROUND(point - _imageOrigin.y), imageSize.width, imageSize.height);
}

/*!
    Returns the extent of the marker's image on the marker side of the ruler's baseline:
    above the baseline on a horizontal ruler, and to its left on a vertical ruler.
*/
- (float)thicknessRequiredInRuler
{
    return [_ruler orientation] === CPHorizontalRuler ? _imageOrigin.y : _imageOrigin.x;
}

// MARK: Setting Movability

/*!
    Returns \c YES if the user can drag the marker along the ruler.
*/
- (BOOL)isMovable
{
    return _isMovable;
}

/*!
    Sets whether the user can drag the marker along the ruler.
    @param shouldBeMovable \c YES to let the user move the marker
*/
- (void)setMovable:(BOOL)shouldBeMovable
{
    _isMovable = shouldBeMovable;
}

/*!
    Returns \c YES if the user can remove the marker by dragging it off the ruler.
*/
- (BOOL)isRemovable
{
    return _isRemovable;
}

/*!
    Sets whether the user can remove the marker by dragging it off the ruler.
    @param shouldBeRemovable \c YES to let the user remove the marker
*/
- (void)setRemovable:(BOOL)shouldBeRemovable
{
    _isRemovable = shouldBeRemovable;
}

// MARK: Setting the Location

/*!
    Returns the marker's location, in the client view's coordinate system.
*/
- (float)markerLocation
{
    return _markerLocation;
}

/*!
    Sets the marker's location, in the client view's coordinate system.
    @param aLocation the new location
*/
- (void)setMarkerLocation:(float)aLocation
{
    if (_markerLocation === aLocation)
        return;

    _markerLocation = aLocation;
    [_ruler setNeedsDisplay:YES];
}

// MARK: Setting the Represented Object

/*!
    Returns the object the marker represents, such as a CPTextTab.
*/
- (id)representedObject
{
    return _representedObject;
}

/*!
    Sets the object the marker represents.
    @param anObject the represented object
*/
- (void)setRepresentedObject:(id)anObject
{
    _representedObject = anObject;
}

// MARK: Drawing and Event Handling

/*!
    Returns \c YES while the user is dragging the marker.
*/
- (BOOL)isDragging
{
    return _isDragging;
}

/*!
    Draws the marker's image if it lies within \c aRect, in the ruler view's coordinate
    system. While a removable marker is dragged off the ruler, it is drawn faded.
    @param aRect the rectangle being drawn
*/
- (void)drawRect:(CGRect)aRect
{
    if (!_image || [_image loadStatus] !== CPImageLoadStatusCompleted)
        return;

    var imageRect = [self imageRectInRuler];

    if (!CGRectIntersectsRect(imageRect, aRect))
        return;

    var context = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSaveGState(context);

    // Off the ruler's outer edge the marker follows the pointer and is clipped by the ruler.
    // Off its inner edge it stays on its line, so it is drawn faded instead.
    if (_isOffRuler && _trackingCrossOffset === 0.0)
        CGContextSetAlpha(context, 0.4);

    CGContextDrawImage(context, imageRect, _image);
    CGContextRestoreGState(context);
}

/*!
    Starts tracking the user's manipulation of the marker, from the mouse-down event
    \c anEvent. Tracking continues until the mouse button is released.

    If \c isAdding is \c YES, the marker is not yet in the ruler: it is added when the user
    releases it over the ruler, if the client view agrees. Otherwise the marker is moved,
    and removed if it is removable and released away from the ruler.
    @param anEvent the mouse-down event that started the manipulation
    @param isAdding \c YES if the marker is being added to the ruler
    @return \c YES if tracking started, or \c NO if the marker cannot be moved or removed,
    or the client view refused
*/
- (BOOL)trackMouse:(CPEvent)anEvent adding:(BOOL)isAdding
{
    if (!isAdding && !_isMovable && !_isRemovable)
        return NO;

    if (isAdding && ![_ruler _clientShouldAddMarker:self])
        return NO;

    if (!isAdding && _isMovable && ![_ruler _clientShouldMoveMarker:self])
        return NO;

    _trackingIsAdding = isAdding;
    _trackingMoved = NO;
    _trackingStartLocation = _markerLocation;
    _trackingStartPoint = [self _axisPointForEvent:anEvent];
    _trackingStartCrossPoint = [self _crossPointForEvent:anEvent];
    _trackingCrossOffset = 0.0;
    _isDragging = YES;
    _isOffRuler = NO;

    if (isAdding)
    {
        _markerLocation = [_ruler _clientWillAddMarker:self atLocation:_markerLocation];
        [_ruler _setTrackedMarker:self];
    }

    [_ruler setNeedsDisplay:YES];

    [CPApp setTarget:self
            selector:@selector(_trackMouseWithEvent:)
            forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask
           untilDate:nil
              inMode:nil
             dequeue:YES];

    return YES;
}

/* @ignore */
- (void)_trackMouseWithEvent:(CPEvent)anEvent
{
    var type = [anEvent type];

    if (type === CPLeftMouseDragged)
    {
        _trackingMoved = YES;
        _isOffRuler = [self _isEventOffRuler:anEvent] && (_trackingIsAdding || _isRemovable);

        // As in Cocoa, the marker stays on its line while the pointer is on the ruler, and follows
        // the pointer out over the ruler's outer edge, where the ruler clips it.
        _trackingCrossOffset = (_trackingIsAdding || _isRemovable) ? MIN(0.0, [self _crossPointForEvent:anEvent] - _trackingStartCrossPoint) : 0.0;

        if (_trackingIsAdding || _isMovable)
        {
            var proposedLocation = _trackingStartLocation + [self _axisPointForEvent:anEvent] - _trackingStartPoint;

            _markerLocation = _trackingIsAdding ? [_ruler _clientWillAddMarker:self atLocation:proposedLocation]
                                                : [_ruler _clientWillMoveMarker:self toLocation:proposedLocation];
        }

        [_ruler setNeedsDisplay:YES];

        [CPApp setTarget:self
                selector:@selector(_trackMouseWithEvent:)
                forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask
               untilDate:nil
                  inMode:nil
                 dequeue:YES];

        return;
    }

    if (type !== CPLeftMouseUp)
        return;

    var wasOffRuler = _isOffRuler;

    _trackingCrossOffset = 0.0;

    _isDragging = NO;
    _isOffRuler = NO;

    if (_trackingIsAdding)
    {
        [_ruler _setTrackedMarker:nil];

        if (!wasOffRuler)
        {
            [_ruler addMarker:self];
            [_ruler _clientDidAddMarker:self];
        }
    }
    else if (wasOffRuler && [_ruler _clientShouldRemoveMarker:self])
    {
        [_ruler removeMarker:self];
        [_ruler _clientDidRemoveMarker:self];
    }
    else if (_trackingMoved)
    {
        if (wasOffRuler)
            _markerLocation = _trackingStartLocation;

        if (_markerLocation !== _trackingStartLocation)
            [_ruler _clientDidMoveMarker:self];
    }

    [_ruler setNeedsDisplay:YES];
}

/* @ignore */
- (float)_crossPointForEvent:(CPEvent)anEvent
{
    var point = [_ruler convertPoint:[anEvent locationInWindow] fromView:nil];

    return [_ruler orientation] === CPHorizontalRuler ? point.y : point.x;
}

/* @ignore */
- (float)_axisPointForEvent:(CPEvent)anEvent
{
    var point = [_ruler convertPoint:[anEvent locationInWindow] fromView:nil];

    return [_ruler orientation] === CPHorizontalRuler ? point.x : point.y;
}

/* @ignore */
- (BOOL)_isEventOffRuler:(CPEvent)anEvent
{
    // Only distance across the ruler counts. Dragging past either end of the ruler moves the marker.
    var point = [_ruler convertPoint:[anEvent locationInWindow] fromView:nil],
        bounds = [_ruler bounds];

    if ([_ruler orientation] === CPHorizontalRuler)
        return point.y < CGRectGetMinY(bounds) - CPRulerMarkerRemovalDistance || point.y > CGRectGetMaxY(bounds) + CPRulerMarkerRemovalDistance;

    return point.x < CGRectGetMinX(bounds) - CPRulerMarkerRemovalDistance || point.x > CGRectGetMaxX(bounds) + CPRulerMarkerRemovalDistance;
}

@end


var CPRulerMarkerRulerKey               = @"CPRulerMarkerRulerKey",
    CPRulerMarkerLocationKey            = @"CPRulerMarkerLocationKey",
    CPRulerMarkerImageKey               = @"CPRulerMarkerImageKey",
    CPRulerMarkerImageOriginKey         = @"CPRulerMarkerImageOriginKey",
    CPRulerMarkerMovableKey             = @"CPRulerMarkerMovableKey",
    CPRulerMarkerRemovableKey           = @"CPRulerMarkerRemovableKey",
    CPRulerMarkerRepresentedObjectKey   = @"CPRulerMarkerRepresentedObjectKey";

@implementation CPRulerMarker (CPCoding)

/*!
    Initializes a marker from an archive.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _ruler = [aCoder decodeObjectForKey:CPRulerMarkerRulerKey];
        _markerLocation = [aCoder decodeFloatForKey:CPRulerMarkerLocationKey];
        _image = [aCoder decodeObjectForKey:CPRulerMarkerImageKey];
        _imageOrigin = [aCoder decodePointForKey:CPRulerMarkerImageOriginKey];
        _isMovable = [aCoder decodeBoolForKey:CPRulerMarkerMovableKey];
        _isRemovable = [aCoder decodeBoolForKey:CPRulerMarkerRemovableKey];
        _representedObject = [aCoder decodeObjectForKey:CPRulerMarkerRepresentedObjectKey];
        _isDragging = NO;
        _isOffRuler = NO;
        _trackingCrossOffset = 0.0;
    }

    return self;
}

/*!
    Archives the marker. The ruler is archived conditionally.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeConditionalObject:_ruler forKey:CPRulerMarkerRulerKey];
    [aCoder encodeFloat:_markerLocation forKey:CPRulerMarkerLocationKey];
    [aCoder encodeObject:_image forKey:CPRulerMarkerImageKey];
    [aCoder encodePoint:_imageOrigin forKey:CPRulerMarkerImageOriginKey];
    [aCoder encodeBool:_isMovable forKey:CPRulerMarkerMovableKey];
    [aCoder encodeBool:_isRemovable forKey:CPRulerMarkerRemovableKey];
    [aCoder encodeObject:_representedObject forKey:CPRulerMarkerRepresentedObjectKey];
}

@end
