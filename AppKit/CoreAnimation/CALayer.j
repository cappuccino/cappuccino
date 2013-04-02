/*
 * CALayer.j
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

@import <Foundation/CPObject.j>
@import <Foundation/CPRunLoop.j>

@import "CABackingStore.j"

@import "CGContext.j"
@import "CGGeometry.j"


#define DOM(aLayer) aLayer._DOMElement

var CALayerGeometryBoundsMask                   = 1,
    CALayerGeometryPositionMask                 = 2,
    CALayerGeometryAnchorPointMask              = 4,
    CALayerGeometryAffineTransformMask          = 8,
    CALayerGeometryParentSublayerTransformMask  = 16;

var USE_BUFFER = NO;

var CALayerFrameOriginUpdateMask                = 1,
    CALayerFrameSizeUpdateMask                  = 2,
    CALayerZPositionUpdateMask                  = 4,
    CALayerDisplayUpdateMask                    = 8,
    CALayerCompositeUpdateMask                  = 16,
    CALayerDOMUpdateMask                        = CALayerZPositionUpdateMask | CALayerFrameOriginUpdateMask | CALayerFrameSizeUpdateMask;

var CALayerRegisteredRunLoopUpdates             = nil;

/*! @class CALayer

    A CALayer is similar to a CPView, but with the ability
    to have a transform applied to it.

    @delegate -(void)drawLayer:(CALayer)layer inContext:(CGContextRef)ctx;
    If the delegate implements this method, the CALayer will
    call this in place of its \c -drawInContext:.
    @param layer the layer to draw for
    @param ctx the context to draw on

    @delegate  -(void)displayLayer:(CALayer)layer;
    The delegate can override the layer's \c -display method
    by implementing this method.
*/
@implementation CALayer : CPObject
{
    // Modifying the Layer Geometry

    CGRect              _frame;
    CGRect              _bounds;
    CGPoint             _position;
    unsigned            _zPosition;
    CGPoint             _anchorPoint;

    CGAffineTransform   _affineTransform;
    CGAffineTransform   _sublayerTransform;
    CGAffineTransform   _sublayerTransformForSublayers;

    CGRect              _backingStoreFrame;
    CGRect              _standardBackingStoreFrame;

    BOOL                _hasSublayerTransform;
    BOOL                _hasCustomBackingStoreFrame;

    // Style Attributes

    float               _opacity;
    BOOL                _isHidden;
    BOOL                _masksToBounds;
    CPColor             _backgroundColor;

    // Managing Layer Hierarchy

    CALayer             _superlayer;
    CPMutableArray      _sublayers;

    // Updating Layer Display

    unsigned            _runLoopUpdateMask;
    BOOL                _needsDisplayOnBoundsChange;

    // Modifying the Delegate

    id                  _delegate;

    BOOL                _delegateRespondsToDisplayLayerSelector;
    BOOL                _delegateRespondsToDrawLayerInContextSelector;

    // DOM Implementation

    DOMElement          _DOMElement;
    DOMElement          _DOMContentsElement;
    id                  _contents;
    CGContext           _context;
    CPView              _owningView;

    CGAffineTransform   _transformToLayer;
    CGAffineTransform   _transformFromLayer;
}

/*!
    Returns a new animation layer.
*/
+ (CALayer)layer
{
    return [[[self class] alloc] init];
}

/*!
    Initializes the animation layer.
*/
- (id)init
{
    self = [super init];

    if (self)
    {
        _frame = CGRectMakeZero();

        _backingStoreFrame = CGRectMakeZero();
        _standardBackingStoreFrame = CGRectMakeZero();

        _bounds = CGRectMakeZero();
        _position = CGPointMakeZero();
        _zPosition = 0.0;
        _anchorPoint = CGPointMake(0.5, 0.5);
        _affineTransform = CGAffineTransformMakeIdentity();
        _sublayerTransform = CGAffineTransformMakeIdentity();

        _transformToLayer = CGAffineTransformMakeIdentity(); // FIXME? does it matter?
        _transformFromLayer = CGAffineTransformMakeIdentity();

        _opacity = 1.0;
        _isHidden = NO;
        _masksToBounds = NO;

        _sublayers = [];

#if PLATFORM(DOM)
        _DOMElement = document.createElement("div");

        _DOMElement.style.overflow = "visible";
        _DOMElement.style.position = "absolute";
        _DOMElement.style.visibility = "visible";
        _DOMElement.style.top = "0px";
        _DOMElement.style.left = "0px";
        _DOMElement.style.zIndex = 0;
        _DOMElement.style.width = "0px";
        _DOMElement.style.height = "0px";
#endif
    }

    return self;
}

// Modifying the Layer Geometry
/*!
    Sets the bounds (origin and size) of the rectangle.
    @param aBounds the new bounds for the layer
*/
- (void)setBounds:(CGRect)aBounds
{
    if (CGRectEqualToRect(_bounds, aBounds))
        return;

    var oldOrigin = _bounds.origin;

    _bounds = CGRectMakeCopy(aBounds);

    if (_hasSublayerTransform)
        _CALayerUpdateSublayerTransformForSublayers(self);

    // _hasSublayerTransform == true will handle this for us.
    /*else if (!CGPointEqualToPoint(_bounds.origin, oldOrigin))
    {
        var index = _sublayers.length;

        // FIXME: This should climb the layer tree down.
        while (index--)
            _CALayerRecalculateGeometry(_sublayers[index], CALayerGeometryPositionMask);
    }*/

    _CALayerRecalculateGeometry(self, CALayerGeometryBoundsMask);
}

/*!
    Returns the layer's bound.
*/
- (CGRect)bounds
{
    return _bounds;
}

/*!
    Sets the layer's position.
    @param aPosition the layer's new position
*/
- (void)setPosition:(CGPoint)aPosition
{
    if (CGPointEqualToPoint(_position, aPosition))
        return;

    _position = CGPointMakeCopy(aPosition);

    _CALayerRecalculateGeometry(self, CALayerGeometryPositionMask);
}

/*!
    Returns the layer's position
*/
- (CGPoint)position
{
    return _position;
}

/*!
    Sets the layer's z-ordering.
    @param aZPosition the layer's new z-ordering
*/
- (void)setZPosition:(int)aZPosition
{
    if (_zPosition == aZPosition)
        return;

    _zPosition = aZPosition;

    [self registerRunLoopUpdateWithMask:CALayerZPositionUpdateMask];
}

/*!
    Sets the layer's anchor point. The default point is [0.5, 0.5].
    @param anAnchorPoint the layer's new anchor point
*/
- (void)setAnchorPoint:(CGPoint)anAnchorPoint
{
    anAnchorPoint = CGPointMakeCopy(anAnchorPoint);
    anAnchorPoint.x = MIN(1.0, MAX(0.0, anAnchorPoint.x));
    anAnchorPoint.y = MIN(1.0, MAX(0.0, anAnchorPoint.y));

    if (CGPointEqualToPoint(_anchorPoint, anAnchorPoint))
        return;

    _anchorPoint = anAnchorPoint;

    if (_hasSublayerTransform)
        _CALayerUpdateSublayerTransformForSublayers(self);

    if (_owningView)
        _position = CGPointMake(CGRectGetWidth(_bounds) * _anchorPoint.x, CGRectGetHeight(_bounds) * _anchorPoint.y);

    _CALayerRecalculateGeometry(self, CALayerGeometryAnchorPointMask);
}

/*!
    Returns the layer's anchor point.
*/
- (CGPoint)anchorPoint
{
    return _anchorPoint;
}

/*!
    Sets the affine transform applied to this layer.
    @param anAffineTransform the new affine transform
*/
- (void)setAffineTransform:(CGAffineTransform)anAffineTransform
{
    if (CGAffineTransformEqualToTransform(_affineTransform, anAffineTransform))
        return;

    _affineTransform = CGAffineTransformMakeCopy(anAffineTransform);

    _CALayerRecalculateGeometry(self, CALayerGeometryAffineTransformMask);
}

/*!
    Returns the layer's affine transform.
*/
- (CGAffineTransform)affineTransform
{
    return _affineTransform;
}

/*!
    Sets the affine transform that gets applied to all the sublayers.
    @param anAffineTransform the transform to apply to sublayers
*/
- (void)setSublayerTransform:(CGAffineTransform)anAffineTransform
{
    if (CGAffineTransformEqualToTransform(_sublayerTransform, anAffineTransform))
        return;

    var hadSublayerTransform = _hasSublayerTransform;

    _sublayerTransform = CGAffineTransformMakeCopy(anAffineTransform);
    _hasSublayerTransform = !CGAffineTransformIsIdentity(_sublayerTransform);

    if (_hasSublayerTransform)
    {
        _CALayerUpdateSublayerTransformForSublayers(self);

        var index = _sublayers.length;

        // FIXME: This should climb the layer tree down.
        while (index--)
            _CALayerRecalculateGeometry(_sublayers[index], CALayerGeometryParentSublayerTransformMask);
    }
}

/*!
    Returns the affine transform applied to the sublayers.
*/
- (CGAffineTransform)sublayerTransform
{
    return _sublayerTransform;
}

/*
    Private
    @ignore
*/
- (CGAffineTransform)transformToLayer
{
    return _transformToLayer;
}

/*!
    Sets the frame of the layer. The frame defines a bounding
    rectangle in the superlayer's coordinate system.
    @param aFrame the new frame rectangle
*/
- (void)setFrame:(CGRect)aFrame
{
    // FIXME: implement this
}

/*!
    Returns the layer's frame.

    The frame defines the bounding box of the layer: the smallest
    possible rectangle that could fit this layer after transform
    properties are applied in superlayer coordinates.
*/
- (CGRect)frame
{
    if (!_frame)
        _frame = [self convertRect:_bounds toLayer:_superlayer];

    return _frame;
}

/*!
    The Backing Store Frame specifies the frame of the actual backing
    store used to contain this layer.  Naturally, by default it is the
    same as the frame, however, users can specify their own custom
    Backing Store Frame in order to speed up certain operations, such as
    live transformation.
    @return the backing store frame
*/
- (CGRect)backingStoreFrame
{
    return _backingStoreFrame;
}

/*!
    Sets the frame's backing store.
    @param aFrame the new backing store.
*/
- (void)setBackingStoreFrame:(CGRect)aFrame
{
    _hasCustomBackingStoreFrame = (aFrame != nil);

    if (aFrame == nil)
        aFrame = CGRectMakeCopy(_standardBackingStoreFrame);
    else
    {
        if (_superlayer)
        {
            aFrame = [_superlayer convertRect:aFrame toLayer:nil];

            var bounds = [_superlayer bounds],
                frame = [_superlayer convertRect:bounds toLayer:nil];

            aFrame.origin.x -= CGRectGetMinX(frame);
            aFrame.origin.y -= CGRectGetMinY(frame);
        }
        else
            aFrame = CGRectMakeCopy(aFrame);
    }

    if (!CGPointEqualToPoint(_backingStoreFrame.origin, aFrame.origin))
        [self registerRunLoopUpdateWithMask:CALayerFrameOriginUpdateMask];

    if (!CGSizeEqualToSize(_backingStoreFrame.size, aFrame.size))
        [self registerRunLoopUpdateWithMask:CALayerFrameSizeUpdateMask];

    _backingStoreFrame = aFrame;
}

// Providing Layer Content
/*!
    Returns the CGImage contents of this layer.
    The default contents are \c nil.
*/
- (CGImage)contents
{
    return _contents;
}

/*!
    Sets the image contents of this layer.
    @param contents the image to display
*/
- (void)setContents:(CGImage)contents
{
    if (_contents == contents)
        return;

    _contents = contents;

    [self composite];
}

/*
    Composites this layer onto the super layer, and draws its contents as well.
    @ignore
*/
- (void)composite
{
    if (USE_BUFFER && !_contents || !_context)
        return;

    CGContextClearRect(_context, CGRectMake(0.0, 0.0, CGRectGetWidth(_backingStoreFrame), CGRectGetHeight(_backingStoreFrame)));

    // Recomposite
    var transform;

    if (_superlayer)
    {
        var superlayerTransform = _CALayerGetTransform(_superlayer, nil),
            superlayerOrigin = CGPointApplyAffineTransform(_superlayer._bounds.origin, superlayerTransform);

        transform = CGAffineTransformConcat(_transformFromLayer, superlayerTransform);

        transform.tx -= superlayerOrigin.x;
        transform.ty -= superlayerOrigin.y;
    }

    else
        // Copy so we don't affect the original.
        transform = CGAffineTransformCreateCopy(_transformFromLayer);

    transform.tx -= CGRectGetMinX(_backingStoreFrame);
    transform.ty -= CGRectGetMinY(_backingStoreFrame);

    CGContextSaveGState(_context);

    CGContextConcatCTM(_context, transform);//_transformFromView);

    if (USE_BUFFER)
    {
//        CGContextDrawImage(_context, _bounds, _contents.context);
        _context.drawImage(_contents.buffer, CGRectGetMinX(_bounds), CGRectGetMinY(_bounds));//, CGRectGetWidth(_standardBackingStoreFrame), CGRectGetHeight(_standardBackingStoreFrame));
    }
    else
        [self drawInContext:_context];

    CGContextRestoreGState(_context);
}

/*!
    Displays the contents of this layer.
*/
- (void)display
{
    if (!_context)
    {
        _context = CGBitmapGraphicsContextCreate();

        _DOMContentsElement = _context.DOMElement;

        _DOMContentsElement.style.zIndex = -100;

        _DOMContentsElement.style.overflow = "hidden";
        _DOMContentsElement.style.position = "absolute";
        _DOMContentsElement.style.visibility = "visible";

        _DOMContentsElement.width = ROUND(CGRectGetWidth(_backingStoreFrame));
        _DOMContentsElement.height = ROUND(CGRectGetHeight(_backingStoreFrame));

        _DOMContentsElement.style.top = "0px";
        _DOMContentsElement.style.left = "0px";
        _DOMContentsElement.style.width = ROUND(CGRectGetWidth(_backingStoreFrame)) + "px";
        _DOMContentsElement.style.height = ROUND(CGRectGetHeight(_backingStoreFrame)) + "px";

        _DOMElement.appendChild(_DOMContentsElement);
    }

    if (USE_BUFFER)
    {
        if (_delegateRespondsToDisplayLayerSelector)
            return [_delegate displayInLayer:self];

        if (CGRectGetWidth(_backingStoreFrame) == 0.0 || CGRectGetHeight(_backingStoreFrame) == 0.0)
            return;

        if (!_contents)
            _contents = CABackingStoreCreate();

        CABackingStoreSetSize(_contents, _bounds.size);

        [self drawInContext:CABackingStoreGetContext(_contents)];
    }

    [self composite];
}

/*!
    Draws this layer's contents into the specified context.
    @param aContext the context to draw the layer into
*/
- (void)drawInContext:(CGContext)aContext
{
    if (_backgroundColor)
    {
        CGContextSetFillColor(aContext, _backgroundColor);
        CGContextFillRect(aContext, _bounds);
    }

    if (_delegateRespondsToDrawLayerInContextSelector)
        [_delegate drawLayer:self inContext:aContext];
}


// Style Attributes
/*!
    Returns the opacity of the layer. The value is between
    \c 0.0 (transparent) and \c 1.0 (opaque).
*/
- (float)opacity
{
    return _opacity;
}

/*!
    Sets the opacity for the layer.
    @param anOpacity the new opacity (between \c 0.0 (transparent) and \c 1.0 (opaque)).
*/
- (void)setOpacity:(float)anOpacity
{
    if (_opacity == anOpacity)
        return;

    _opacity = anOpacity;

    _DOMElement.style.opacity = anOpacity;
    _DOMElement.style.filter = "alpha(opacity=" + anOpacity * 100 + ")";
}

/*!
    Sets whether the layer is hidden.
    @param isHidden \c YES means the layer will be hidden. \c NO means the layer will be visible.
*/
- (void)setHidden:(BOOL)isHidden
{
    _isHidden = isHidden;
    _DOMElement.style.display = isHidden ? "none" : "block";
}

/*!
    Returns \c YES if the layer is hidden.
*/
- (BOOL)hidden
{
    return _isHidden;
}

/*!
    Returns \c YES if the layer is hidden.
*/
- (BOOL)isHidden
{
    return _isHidden;
}

/*!
    Sets whether content that goes lies outside the bounds is hidden or visible.
    @param masksToBounds \c YES hides the excess content. \c NO makes it visible.
*/
- (void)setMasksToBounds:(BOOL)masksToBounds
{
    if (_masksToBounds == masksToBounds)
        return;

    _masksToBounds = masksToBounds;
    _DOMElement.style.overflow = _masksToBounds ? "hidden" : "visible";
}

/*!
    Sets the layer's background color.
    @param aColor the new background color
*/
- (void)setBackgroundColor:(CPColor)aColor
{
    _backgroundColor = aColor;

    [self setNeedsDisplay];
}

/*!
    Returns the layer's background color.
*/
- (CPColor)backgroundColor
{
    return _backgroundColor;
}

// Managing Layer Hierarchy
/*!
    Returns an array of the receiver's sublayers.
*/
- (CPArray)sublayers
{
    return _sublayers;
}

/*!
    Returns the receiver's superlayer.
*/
- (CALayer)superlayer
{
    return _superlayer;
}

#define ADJUST_CONTENTS_ZINDEX(aLayer)\
if (_DOMContentsElement && aLayer._zPosition > _DOMContentsElement.style.zIndex)\
    _DOMContentsElement.style.zIndex -= 100.0;\

/*!
    Adds the specified layer as a sublayer of the receiver.
*/
- (void)addSublayer:(CALayer)aLayer
{
    [self insertSublayer:aLayer atIndex:_sublayers.length];
}

/*!
    Removes the receiver from its superlayer.
*/
- (void)removeFromSuperlayer
{
    if (_owningView)
        [_owningView setLayer:nil];

    if (!_superlayer)
        return;

    _superlayer._DOMElement.removeChild(_DOMElement);
    [_superlayer._sublayers removeObject:self];

    _superlayer = nil;
}

/*!
    Inserts the specified layer as a sublayer into the specified index.
    @param aLayer the layer to insert
    @param anIndex the index to insert the layer at
*/
- (void)insertSublayer:(CALayer)aLayer atIndex:(unsigned)anIndex
{
    if (!aLayer)
        return;

    var superlayer = [aLayer superlayer];

    if (superlayer == self)
    {
        var index = [_sublayers indexOfObjectIdenticalTo:aLayer];

        if (index == anIndex)
            return;

        [_sublayers removeObjectAtIndex:index];

        if (index < anIndex)
            --anIndex;
    }
    else if (superlayer != nil)
        [aLayer removeFromSuperlayer];

    ADJUST_CONTENTS_ZINDEX(aLayer);

    [_sublayers insertObject:aLayer atIndex:anIndex];

#if PLATFORM(DOM)
    if (anIndex >= _sublayers.length - 1)
        _DOMElement.appendChild(DOM(aLayer));
    else
        _DOMElement.insertBefore(DOM(aLayer), _sublayers[anIndex + 1]._DOMElement);
#endif

    aLayer._superlayer = self;

    if (self != superlayer)
        _CALayerRecalculateGeometry(aLayer, 0xFFFFFFF);
}

/*!
    Inserts a layer below another layer.
    @param aLayer the layer to insert
    @param aSublayer the layer to insert below
    @throws CALayerNotFoundException if \c aSublayer is not in the array of sublayers
*/
- (void)insertSublayer:(CALayer)aLayer below:(CALayer)aSublayer
{
    var index = aSublayer ? [_sublayers indexOfObjectIdenticalTo:aSublayer] : 0;

    [self insertSublayer:aLayer atIndex:index == CPNotFound ? _sublayers.length : index];
}

/*!
    Inserts a layer above another layer.
    @param aLayer the layer to insert
    @param aSublayer the layer to insert above
    @throws CALayerNotFoundException if \c aSublayer is not in the array of sublayers
*/
- (void)insertSublayer:(CALayer)aLayer above:(CALayer)aSublayer
{
    var index = aSublayer ? [_sublayers indexOfObjectIdenticalTo:aSublayer] : _sublayers.length;

    if (index == CPNotFound)
        [CPException raise:"CALayerNotFoundException" reason:"aSublayer is not a sublayer of this layer"];

    [_sublayers insertObject:aLayer atIndex:index == CPNotFound ? _sublayers.length : index + 1];
}

/*!
    Replaces a sublayer.
    @param aSublayer the layer to insert
    @param aLayer the layer to replace
*/
- (void)replaceSublayer:(CALayer)aSublayer with:(CALayer)aLayer
{
    if (aSublayer == aLayer)
        return;

    if (aSublayer._superlayer != self)
    {
        CPLog.warn("Attempt to replace a sublayer (%s) which is not in the sublayers of the receiver (%s).", [aSublayer description], [self description]);
        return;
    }

    ADJUST_CONTENTS_ZINDEX(aLayer);

    [_sublayers replaceObjectAtIndex:[_sublayers indexOfObjectIdenticalTo:aSublayer] withObject:aLayer];
    _DOMElement.replaceChild(DOM(aSublayer), DOM(aLayer));
}

// Updating Layer Display
/*
    Updates the layers on screen.
    @ignore
*/
+ (void)runLoopUpdateLayers
{
    for (UID in CALayerRegisteredRunLoopUpdates)
    {
        var layer = CALayerRegisteredRunLoopUpdates[UID],
            mask = layer._runLoopUpdateMask;

        if (mask & CALayerDOMUpdateMask)
            _CALayerUpdateDOM(layer, mask);

        if (mask & CALayerDisplayUpdateMask)
            [layer display];

        else if (mask & CALayerFrameSizeUpdateMask || mask & CALayerCompositeUpdateMask)
            [layer composite];

        layer._runLoopUpdateMask = 0;
    }

    window.loop = false;
    CALayerRegisteredRunLoopUpdates = nil;
}

/*
    @ignore
*/
- (void)registerRunLoopUpdateWithMask:(unsigned)anUpdateMask
{
    if (CALayerRegisteredRunLoopUpdates == nil)
    {
        CALayerRegisteredRunLoopUpdates = {};

        [[CPRunLoop currentRunLoop] performSelector:@selector(runLoopUpdateLayers)
            target:CALayer argument:nil order:0 modes:[CPDefaultRunLoopMode]];
    }

    _runLoopUpdateMask |= anUpdateMask;
    CALayerRegisteredRunLoopUpdates[[self UID]] = self;
}

/*
    @ignore
*/
- (void)setNeedsComposite
{
    [self registerRunLoopUpdateWithMask:CALayerCompositeUpdateMask];
}

/*!
    Marks the layer as needing to be redrawn.
*/
- (void)setNeedsDisplay
{
    [self registerRunLoopUpdateWithMask:CALayerDisplayUpdateMask];
}

/*!
    Sets whether the layer needs to be redrawn when its bounds are changed.
    @param needsDisplayOnBoundsChange \c YES means the display is redraw on a bounds change.
*/
- (void)setNeedsDisplayOnBoundsChange:(BOOL)needsDisplayOnBoundsChange
{
    _needsDisplayOnBoundsChange = needsDisplayOnBoundsChange;
}

/*!
    Returns \c YES if the display should be redrawn on a bounds change.
*/
- (BOOL)needsDisplayOnBoundsChange
{
    return _needsDisplayOnBoundsChange;
}

/*!
    Marks the specified rectangle as needing to be redrawn.
    @param aRect the area that needs to be redrawn.
*/
- (void)setNeedsDisplayInRect:(CGRect)aRect
{
//    _dirtyRect = aRect;
    [self display];
}

// Mapping Between Coordinate and Time Spaces
/*!
    Converts the point from the specified layer's coordinate system into the receiver's coordinate system.
    @param aPoint the point to convert
    @param aLayer the layer coordinate system to convert from
    @return the converted point
*/
- (CGPoint)convertPoint:(CGPoint)aPoint fromLayer:(CALayer)aLayer
{
    return CGPointApplyAffineTransform(aPoint, _CALayerGetTransform(aLayer, self));
}

/*!
    Converts the point from the receiver's coordinate system to the specified layer's coordinate system.
    @param aPoint the point to convert
    @param aLayer the layer coordinate system to convert to
    @return the converted point
*/
- (CGPoint)convertPoint:(CGPoint)aPoint toLayer:(CALayer)aLayer
{
    return CGPointApplyAffineTransform(aPoint, _CALayerGetTransform(self, aLayer));
}

/*!
    Converts the rectangle from the specified layer's coordinate system to the receiver's coordinate system.
    @param aRect the rectangle to convert
    @param aLayer the layer coordinate system to convert from
    @return the converted rectangle
*/
- (CGRect)convertRect:(CGRect)aRect fromLayer:(CALayer)aLayer
{
    return CGRectApplyAffineTransform(aRect, _CALayerGetTransform(aLayer, self));
}

/*!
    Converts the rectangle from the receiver's coordinate system to the specified layer's coordinate system.
    @param aRect the rectangle to convert
    @param aLayer the layer coordinate system to convert to
    @return the converted rectangle
*/
- (CGRect)convertRect:(CGRect)aRect toLayer:(CALayer)aLayer
{
    return CGRectApplyAffineTransform(aRect, _CALayerGetTransform(self, aLayer));
}

// Hit Testing
/*!
    Returns \c YES if the layer contains the point.
    @param aPoint the point to test
*/
- (BOOL)containsPoint:(CGPoint)aPoint
{
    return CGRectContainsPoint(_bounds, aPoint);
}

/*!
    Returns the farthest descendant of this layer that contains the specified point.
    @param aPoint the point to test
    @return the containing layer or \c nil if there was no hit.
*/
- (CALayer)hitTest:(CGPoint)aPoint
{
    if (_isHidden)
        return nil;

    var point = CGPointApplyAffineTransform(aPoint, _transformToLayer);

    if (!CGRectContainsPoint(_bounds, point))
        return nil;

    var layer = nil,
        index = _sublayers.length;

    // FIXME: this should take into account zPosition.
    while (index--)
        if (layer = [_sublayers[index] hitTest:point])
            return layer;

    return self;
}

// Modifying the Delegate
/*!
    Sets the delegate for this layer.
    @param aDelegate the delegate
*/
- (void)setDelegate:(id)aDelegate
{
    if (_delegate == aDelegate)
        return;

    _delegate = aDelegate;

    _delegateRespondsToDisplayLayerSelector         = [_delegate respondsToSelector:@selector(displayLayer:)];
    _delegateRespondsToDrawLayerInContextSelector   = [_delegate respondsToSelector:@selector(drawLayer:inContext:)];

    if (_delegateRespondsToDisplayLayerSelector || _delegateRespondsToDrawLayerInContextSelector)
        [self setNeedsDisplay];
}

/*!
    Returns the layer's delegate
*/
- (id)delegate
{
    return _delegate;
}

/* @ignore */
- (void)_setOwningView:(CPView)anOwningView
{
    _owningView = anOwningView;

    if (_owningView)
    {
        _owningView = anOwningView;

        _bounds.size = CGSizeMakeCopy([_owningView bounds].size);
        _position = CGPointMake(CGRectGetWidth(_bounds) * _anchorPoint.x, CGRectGetHeight(_bounds) * _anchorPoint.y);
    }

    _CALayerRecalculateGeometry(self, CALayerGeometryPositionMask | CALayerGeometryBoundsMask);
}

/* @ignore */
- (void)_owningViewBoundsChanged
{
    _bounds.size = CGSizeMakeCopy([_owningView bounds].size);
    _position = CGPointMake(CGRectGetWidth(_bounds) * _anchorPoint.x, CGRectGetHeight(_bounds) * _anchorPoint.y);

    _CALayerRecalculateGeometry(self, CALayerGeometryPositionMask | CALayerGeometryBoundsMask);
}

/* @ignore */
- (void)_update
{
    window.loop = true;

    var mask = _runLoopUpdateMask;

    if (mask & CALayerDOMUpdateMask)
        _CALayerUpdateDOM(self, mask);

    if (mask & CALayerDisplayUpdateMask)
        [self display];

    else if (mask & CALayerFrameSizeUpdateMask || mask & CALayerCompositeUpdateMask)
        [self composite];

    _runLoopUpdateMask = 0;

    window.loop = false;
}

@end

function _CALayerUpdateSublayerTransformForSublayers(aLayer)
{
    var bounds = aLayer._bounds,
        anchorPoint = aLayer._anchorPoint,
        translateX = CGRectGetWidth(bounds) * anchorPoint.x,
        translateY = CGRectGetHeight(bounds) * anchorPoint.y;

    aLayer._sublayerTransformForSublayers = CGAffineTransformConcat(
        CGAffineTransformMakeTranslation(-translateX, -translateY),
        CGAffineTransformConcat(aLayer._sublayerTransform,
        CGAffineTransformMakeTranslation(translateX, translateY)));
}

function _CALayerUpdateDOM(aLayer, aMask)
{
    var DOMElementStyle = aLayer._DOMElement.style;

    if (aMask & CALayerZPositionUpdateMask)
        DOMElementStyle.zIndex = aLayer._zPosition;

    var frame = aLayer._backingStoreFrame;

    if (aMask & CALayerFrameOriginUpdateMask)
    {
        DOMElementStyle.top = ROUND(CGRectGetMinY(frame)) + "px";
        DOMElementStyle.left = ROUND(CGRectGetMinX(frame)) + "px";
    }

    if (aMask & CALayerFrameSizeUpdateMask)
    {
        var width = MAX(0.0, ROUND(CGRectGetWidth(frame))),
            height = MAX(0.0, ROUND(CGRectGetHeight(frame))),
            DOMContentsElement = aLayer._DOMContentsElement;

        DOMElementStyle.width = width + "px";
        DOMElementStyle.height = height + "px";

        if (DOMContentsElement)
        {
            DOMContentsElement.width = width;
            DOMContentsElement.height = height;
            DOMContentsElement.style.width = width + "px";
            DOMContentsElement.style.height = height + "px";
        }
    }
}

function _CALayerRecalculateGeometry(aLayer, aGeometryChange)
{
    var bounds = aLayer._bounds,
        superlayer = aLayer._superlayer,
        width = CGRectGetWidth(bounds),
        height = CGRectGetHeight(bounds),
        position = aLayer._position,
        anchorPoint = aLayer._anchorPoint,
        affineTransform = aLayer._affineTransform,
        backingStoreFrameSize = CGSizeMakeCopy(aLayer._backingStoreFrame),
        hasCustomBackingStoreFrame = aLayer._hasCustomBackingStoreFrame;

    // Go to anchor, transform, go back to bounds.
    aLayer._transformFromLayer =  CGAffineTransformConcat(
        CGAffineTransformMakeTranslation(-width * anchorPoint.x - CGRectGetMinX(aLayer._bounds), -height * anchorPoint.y - CGRectGetMinY(aLayer._bounds)),
        CGAffineTransformConcat(affineTransform,
        CGAffineTransformMakeTranslation(position.x, position.y)));

    if (superlayer && superlayer._hasSublayerTransform)
    {
        // aLayer._transformFromLayer = CGAffineTransformConcat(aLayer._transformFromLayer, superlayer._sublayerTransformForSublayers);
        CGAffineTransformConcatTo(aLayer._transformFromLayer, superlayer._sublayerTransformForSublayers, aLayer._transformFromLayer);
    }

    aLayer._transformToLayer = CGAffineTransformInvert(aLayer._transformFromLayer);

    //aLayer._transformFromLayer.tx = ROUND(aLayer._transformFromLayer.tx);
    //aLayer._transformFromLayer.ty = ROUND(aLayer._transformFromLayer.ty);

    aLayer._frame = nil;
    aLayer._standardBackingStoreFrame = [aLayer convertRect:bounds toLayer:nil];

    if (superlayer)
    {
        var bounds = [superlayer bounds],
            frame = [superlayer convertRect:bounds toLayer:nil];

        aLayer._standardBackingStoreFrame.origin.x -= CGRectGetMinX(frame);
        aLayer._standardBackingStoreFrame.origin.y -= CGRectGetMinY(frame);
    }

    // We used to use CGRectIntegral here, but what we actually want, is the largest integral
    // rect that would ever contain this box, since for any width/height, there are 2 (4)
    // possible integral rects for it depending on it's position.  It's OK that this is sometimes
    // bigger than the "optimal" bounding integral rect since that doesn't change drawing.

    var origin = aLayer._standardBackingStoreFrame.origin,
        size = aLayer._standardBackingStoreFrame.size;

    origin.x = FLOOR(origin.x);
    origin.y = FLOOR(origin.y);
    size.width = CEIL(size.width) + 1.0;
    size.height = CEIL(size.height) + 1.0;

    // FIXME: This avoids the central issue that a position change is sometimes a display and sometimes
    // a div move, and sometimes both.

    // Only use this frame if we don't currently have a custom backing store frame.
    if (!hasCustomBackingStoreFrame)
    {
        var backingStoreFrame = CGRectMakeCopy(aLayer._standardBackingStoreFrame);

        // These values get rounded in the DOM, so don't both updating them if they're
        // not going to be different after rounding.
        if (ROUND(CGRectGetMinX(backingStoreFrame)) != ROUND(CGRectGetMinX(aLayer._backingStoreFrame)) ||
            ROUND(CGRectGetMinY(backingStoreFrame)) != ROUND(CGRectGetMinY(aLayer._backingStoreFrame)))
            [aLayer registerRunLoopUpdateWithMask:CALayerFrameOriginUpdateMask];

        // Any change in size due to a geometry change is purely due to rounding error.
        if ((CGRectGetWidth(backingStoreFrame) != ROUND(CGRectGetWidth(aLayer._backingStoreFrame)) ||
            CGRectGetHeight(backingStoreFrame) != ROUND(CGRectGetHeight(aLayer._backingStoreFrame))))
            [aLayer registerRunLoopUpdateWithMask:CALayerFrameSizeUpdateMask];

        aLayer._backingStoreFrame = backingStoreFrame;
    }

    if (aGeometryChange & CALayerGeometryBoundsMask && aLayer._needsDisplayOnBoundsChange)
        [aLayer setNeedsDisplay];
    // We need to recompose if we have a custom backing store frame, OR
    // If the change is not solely composed of position and anchor points changes.
    // Anchor point and position changes simply move the object, requiring
    // no re-rendering.
    else if (hasCustomBackingStoreFrame || (aGeometryChange & ~(CALayerGeometryPositionMask | CALayerGeometryAnchorPointMask)))
        [aLayer setNeedsComposite];

    var sublayers = aLayer._sublayers,
        index = 0,
        count = sublayers.length;

    for (; index < count; ++index)
        _CALayerRecalculateGeometry(sublayers[index], aGeometryChange);
}

function _CALayerGetTransform(fromLayer, toLayer)
{
    var transform = CGAffineTransformMakeIdentity();

    if (fromLayer)
    {
        var layer = fromLayer;

        // If we have a fromLayer, "climb up" the layer tree until
        // we hit the root node or we hit the toLayer.
        while (layer && layer != toLayer)
        {
            var transformFromLayer = layer._transformFromLayer;

            //transform = CGAffineTransformConcat(transform, layer._transformFromLayer);
            CGAffineTransformConcatTo(transform, transformFromLayer, transform);

            layer = layer._superlayer;
        }

        // If we hit toLayer, then we're done.
        if (layer == toLayer)
            return transform;
    }

    var layers = [],
        layer = toLayer;

    while (layer)
    {
        layers.push(layer);
        layer = layer._superlayer;
    }

    var index = layers.length;

    while (index--)
    {
        var transformToLayer = layers[index]._transformToLayer;

        CGAffineTransformConcatTo(transform, transformToLayer, transform);
    }

    return transform;
}
