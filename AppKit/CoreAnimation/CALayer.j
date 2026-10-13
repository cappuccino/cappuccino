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
@import "CPColor.j"
@import "CPView.j"
@import "CAMediaTimingFunction.j"


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

/*!
    @ingroup appkit
    @class CALayer
    A CALayer is an object that manages image-based content and allows transforms,
    animations, and visual styling to be applied.

    @delegate -(void)drawLayer:(CALayer)layer inContext:(CGContextRef)ctx;
    If the delegate implements this method, the CALayer will call this in place of its \c -drawInContext:.
    @param layer the layer to draw for
    @param ctx the context to draw on

    @delegate -(void)displayLayer:(CALayer)layer;
    The delegate can override the layer's \c -display method by implementing this method.
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

    CPMutableDictionary _activeAnimations;
}

@global document

/*!
    Creates and returns a new \c CALayer instance.
    @return a new \c CALayer instance
*/
+ (CALayer)layer
{
    return [[[self class] alloc] init];
}

/*!
    Initializes a newly allocated layer instance with default properties.
    @return the initialized layer instance
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

        _activeAnimations = [CPMutableDictionary dictionary];

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
    Sets the bounds rectangle of the layer in its own coordinate system.
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

    _CALayerRecalculateGeometry(self, CALayerGeometryBoundsMask);
}

/*!
    Returns the layer's bounds rectangle in its own coordinate system.
    @return the bounds rectangle
*/
- (CGRect)bounds
{
    return _bounds;
}

/*!
    Sets the position of the layer in its superlayer's coordinate space.
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
    Returns the position of the layer in its superlayer's coordinate space.
    @return the position point
*/
- (CGPoint)position
{
    return _position;
}

/*!
    Sets the layer's position on the z-axis (z-index ordering).
    @param aZPosition the layer's new z-position
*/
- (void)setZPosition:(int)aZPosition
{
    if (_zPosition == aZPosition)
        return;

    _zPosition = aZPosition;

    [self registerRunLoopUpdateWithMask:CALayerZPositionUpdateMask];
}

/*!
    Sets the anchor point for the layer's bounds rectangle (normalized from 0.0 to 1.0).
    The default point is [0.5, 0.5].
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
    Returns the anchor point for the layer's bounds rectangle.
    @return the anchor point
*/
- (CGPoint)anchorPoint
{
    return _anchorPoint;
}

/*!
    Sets the affine transform applied to this layer relative to the anchor point.
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
    Returns the affine transform applied to the layer.
    @return the affine transform
*/
- (CGAffineTransform)affineTransform
{
    return _affineTransform;
}

/*!
    Sets the affine transform that gets applied to all sublayers.
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
    @return the sublayer transform
*/
- (CGAffineTransform)sublayerTransform
{
    return _sublayerTransform;
}

/* @ignore */
- (CGAffineTransform)transformToLayer
{
    return _transformToLayer;
}

/*!
    Sets the frame of the layer in the superlayer's coordinate system.
    @param aFrame the new frame rectangle
*/
- (void)setFrame:(CGRect)aFrame
{
    // FIXME: implement this
}

/*!
    Returns the layer's bounding box in the superlayer's coordinate system after transforms are applied.
    @return the frame rectangle
*/
- (CGRect)frame
{
    if (!_frame)
        _frame = [self convertRect:_bounds toLayer:_superlayer];

    return _frame;
}

/*!
    Returns the frame of the backing store used to contain this layer.
    @return the backing store frame
*/
- (CGRect)backingStoreFrame
{
    return _backingStoreFrame;
}

/*!
    Sets a custom frame for the layer's backing store.
    @param aFrame the new backing store frame
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
    Returns the image contents of this layer.
    @return the contents image, or \c nil
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

/* @ignore */
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
    {
        // Copy so we don't affect the original.
        transform = CGAffineTransformCreateCopy(_transformFromLayer);
    }

    transform.tx -= CGRectGetMinX(_backingStoreFrame);
    transform.ty -= CGRectGetMinY(_backingStoreFrame);

    CGContextSaveGState(_context);
    CGContextConcatCTM(_context, transform);

    if (USE_BUFFER)
    {
        _context.drawImage(_contents.buffer, CGRectGetMinX(_bounds), CGRectGetMinY(_bounds));
    }
    else
    {
        [self drawInContext:_context];
    }

    CGContextRestoreGState(_context);
}

/*!
    Displays the contents of this layer, creating contexts and requesting delegate rendering if needed.
*/
- (void)display
{
#if PLATFORM(DOM)
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
            return [_delegate displayLayer:self];

        if (CGRectGetWidth(_backingStoreFrame) == 0.0 || CGRectGetHeight(_backingStoreFrame) == 0.0)
            return;

        if (!_contents)
            _contents = CABackingStoreCreate();

        CABackingStoreSetSize(_contents, _bounds.size);

        [self drawInContext:CABackingStoreGetContext(_contents)];
    }
#endif

    [self composite];
}

/*!
    Draws the layer's contents into the specified graphics context.
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
    Returns the opacity of the layer, between \c 0.0 (transparent) and \c 1.0 (opaque).
    @return the opacity
*/
- (float)opacity
{
    return _opacity;
}

/*!
    Sets the opacity for the layer.
    @param anOpacity the new opacity (between \c 0.0 (transparent) and \c 1.0 (opaque))
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
    @param isHidden \c YES to hide the layer, \c NO to make it visible
*/
- (void)setHidden:(BOOL)isHidden
{
    _isHidden = isHidden;
    _DOMElement.style.display = isHidden ? "none" : "block";
}

/*!
    Returns whether the layer is hidden.
    @return \c YES if the layer is hidden, otherwise \c NO
*/
- (BOOL)hidden
{
    return _isHidden;
}

/*!
    Returns whether the layer is hidden.
    @return \c YES if the layer is hidden, otherwise \c NO
*/
- (BOOL)isHidden
{
    return _isHidden;
}

/*!
    Sets whether sublayers and contents are clipped to the layer's bounds.
    @param masksToBounds \c YES to clip to bounds, \c NO to allow overflow
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
    @return the background color
*/
- (CPColor)backgroundColor
{
    return _backgroundColor;
}

// Managing Layer Hierarchy

/*!
    Returns an array containing the receiver's sublayers.
    @return the array of sublayers
*/
- (CPArray)sublayers
{
    return _sublayers;
}

/*!
    Returns the receiver's superlayer.
    @return the superlayer, or \c nil if none
*/
- (CALayer)superlayer
{
    return _superlayer;
}

#define ADJUST_CONTENTS_ZINDEX(aLayer)\
if (_DOMContentsElement && aLayer._zPosition > _DOMContentsElement.style.zIndex)\
    _DOMContentsElement.style.zIndex -= 100.0;\

/*!
    Appends the specified layer to the end of the receiver's sublayers array.
    @param aLayer the layer to add
*/
- (void)addSublayer:(CALayer)aLayer
{
    [self insertSublayer:aLayer atIndex:_sublayers.length];
}

/*!
    Detaches the receiver from its parent layer.
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
    Inserts the specified layer into the sublayers array at the specified index.
    @param aLayer the layer to insert
    @param anIndex the index where the layer should be inserted
*/
- (void)insertSublayer:(CALayer)aLayer atIndex:(CPUInteger)anIndex
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
    Inserts the layer below an existing sublayer.
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
    Inserts the layer above an existing sublayer.
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
    Replaces an existing sublayer with a new layer.
    @param aSublayer the existing sublayer to be replaced
    @param aLayer the new layer to insert
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

/* @ignore */
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

/* @ignore */
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

/* @ignore */
- (void)setNeedsComposite
{
    [self registerRunLoopUpdateWithMask:CALayerCompositeUpdateMask];
}

/*!
    Marks the layer's contents as needing to be redrawn.
*/
- (void)setNeedsDisplay
{
    [self registerRunLoopUpdateWithMask:CALayerDisplayUpdateMask];
}

/*!
    Sets whether the layer is automatically marked as needing display when its bounds change.
    @param needsDisplayOnBoundsChange \c YES to redraw on bounds change
*/
- (void)setNeedsDisplayOnBoundsChange:(BOOL)needsDisplayOnBoundsChange
{
    _needsDisplayOnBoundsChange = needsDisplayOnBoundsChange;
}

/*!
    Returns whether the layer is automatically marked as needing display when its bounds change.
    @return \c YES if redrawn on bounds change
*/
- (BOOL)needsDisplayOnBoundsChange
{
    return _needsDisplayOnBoundsChange;
}

/*!
    Marks the specified region within the layer as needing to be redrawn.
    @param aRect the area that needs display
*/
- (void)setNeedsDisplayInRect:(CGRect)aRect
{
    [self display];
}

// Mapping Between Coordinate and Time Spaces

/*!
    Converts a point from the specified layer's coordinate system into the receiver's coordinate system.
    @param aPoint the point to convert
    @param aLayer the layer coordinate system to convert from
    @return the converted point
*/
- (CGPoint)convertPoint:(CGPoint)aPoint fromLayer:(CALayer)aLayer
{
    return CGPointApplyAffineTransform(aPoint, _CALayerGetTransform(aLayer, self));
}

/*!
    Converts a point from the receiver's coordinate system to the specified layer's coordinate system.
    @param aPoint the point to convert
    @param aLayer the layer coordinate system to convert to
    @return the converted point
*/
- (CGPoint)convertPoint:(CGPoint)aPoint toLayer:(CALayer)aLayer
{
    return CGPointApplyAffineTransform(aPoint, _CALayerGetTransform(self, aLayer));
}

/*!
    Converts a rectangle from the specified layer's coordinate system to the receiver's coordinate system.
    @param aRect the rectangle to convert
    @param aLayer the layer coordinate system to convert from
    @return the converted rectangle
*/
- (CGRect)convertRect:(CGRect)aRect fromLayer:(CALayer)aLayer
{
    return CGRectApplyAffineTransform(aRect, _CALayerGetTransform(aLayer, self));
}

/*!
    Converts a rectangle from the receiver's coordinate system to the specified layer's coordinate system.
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
    Returns whether the layer's bounds contain the specified point in its local coordinate system.
    @param aPoint the point to test
    @return \c YES if the point is within bounds, otherwise \c NO
*/
- (BOOL)containsPoint:(CGPoint)aPoint
{
    return CGRectContainsPoint(_bounds, aPoint);
}

/*!
    Returns the farthest descendant in the layer hierarchy that contains the specified point.
    @param aPoint the point to test in the receiver's coordinate space
    @return the layer containing the point, or \c nil if not found
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
    Sets the delegate for the layer.
    @param aDelegate the delegate object
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
    Returns the delegate of the layer.
    @return the delegate object
*/
- (id)delegate
{
    return _delegate;
}

/*!
    Adds an animation to the layer identified by the specified key.
    @param anim the animation object to add
    @param key the string identifier for the animation
*/
- (void)addAnimation:(CAAnimation)anim forKey:(CPString)key
{
    if (!anim) return;

    // --- 1. Handle Animation Groups ---
    // If it's a group, we simply schedule its children individually.
    if ([anim respondsToSelector:@selector(animations)] && [anim animations])
    {
        var animations = [anim animations],
            count = [animations count],
            i = 0;

        for (; i < count; i++)
        {
            var child = [animations objectAtIndex:i];

            // Recurse: Add the child animation.
            // We pass 'nil' for the key so the child's own 'keyPath'
            // is used as the storage identifier in the dictionary.
            [self addAnimation:child forKey:nil];
        }
        return;
    }

    // --- 2. Determine KeyPath ---
    var keyPath = key;

    // If the animation object has an explicit keyPath (like CABasicAnimation), use it.
    if ([anim respondsToSelector:@selector(keyPath)] && [anim keyPath])
        keyPath = [anim keyPath];

    // If we can't determine a property to animate, we must abort.
    if (!keyPath) return;

    // --- 3. Determine Values ---
    var startValue = ([anim respondsToSelector:@selector(fromValue)]) ? [anim fromValue] : nil;

    // If startValue is missing, try to read it from the layer.
    // We wrap this in a try-catch to prevent crashes if 'keyPath' is invalid.
    if (startValue == nil)
    {
        try {
            startValue = [[self delegate] valueForKey:keyPath];
        }
        catch (e) {
            // The keyPath was likely invalid (not KVC compliant), abort.
            return;
        }
    }

    var endValue = ([anim respondsToSelector:@selector(toValue)]) ? [anim toValue] : nil;

    if (endValue == nil)
        return;

    var duration = ([anim respondsToSelector:@selector(duration)]) ? [anim duration] : 0.25;

    // Default to EaseInEaseOut if not specified
    var timingFunction = ([anim respondsToSelector:@selector(timingFunction)]) ? [anim timingFunction] : [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    // --- 4. Prepare Context ---
    var context = {
        "animation": anim,
        "keyPath": keyPath,
        "startValue": startValue,
        "endValue": endValue,
        "duration": duration * 1000.0, // ms
        "timingFunction": timingFunction,
        "startTime": null,
        "requestId": null
    };

    // --- 5. Render Loop ---
    var _self = self;

    var renderLoop = function(timestamp) {
        if ([_self _renderAnimationStep:context timestamp:timestamp])
            context.requestId = window.requestAnimationFrame(renderLoop);
        else
            context.requestId = null;
    };

    // --- 6. Storage & Kickoff ---
    // Use the keyPath as the identifier if no specific key was provided
    var storageKey = (key && key.length > 0) ? key : keyPath;

    // Remove any conflicting animation on this specific property/key
    [self removeAnimationForKey:storageKey];

    context.requestId = window.requestAnimationFrame(renderLoop);
    [_activeAnimations setObject:context forKey:storageKey];
}

/*!
    Removes the animation registered with the specified key.
    @param key the string identifier for the animation
*/
- (void)removeAnimationForKey:(CPString)key
{
    var context = [_activeAnimations objectForKey:key];
    if (context)
    {
        if (context.requestId !== null)
            window.cancelAnimationFrame(context.requestId);
        [_activeAnimations removeObjectForKey:key];
    }
}

/*!
    Removes all animations attached to the layer.
*/
- (void)removeAllAnimations
{
    var keys = [_activeAnimations allKeys],
        count = [keys count];
    while (count--)
        [self removeAnimationForKey:[keys objectAtIndex:count]];
}

/* @ignore */
- (float)_solveBezier:(float)t forTimingFunction:(CAMediaTimingFunction)tf
{
    if (!tf) return t;

    // Linear optimization
    if (tf === [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear])
        return t;

    var points = [tf controlPoints]; // [c1x, c1y, c2x, c2y]
    var p1x = points[0], p1y = points[1],
        p2x = points[2], p2y = points[3];

    // Simple polynomial evaluation (De Casteljau's algorithm/Cubic formula subset)
    // 3t^2 * (1-t) + t^3  ... standard bezier blending functions
    var cx = 3.0 * p1x;
    var bx = 3.0 * (p2x - p1x) - cx;
    var ax = 1.0 - cx - bx;

    var cy = 3.0 * p1y;
    var by = 3.0 * (p2y - p1y) - cy;
    var ay = 1.0 - cy - by;

    // Solve for X given t (time) using Newton-Raphson
    var sampleT = t;
    for (var i = 0; i < 5; i++) {
        var x = ((ax * sampleT + bx) * sampleT + cx) * sampleT - t;
        if (Math.abs(x) < 1e-3) break;
        var d = (3.0 * ax * sampleT + 2.0 * bx) * sampleT + cx;
        if (Math.abs(d) < 1e-6) break;
        sampleT = sampleT - x / d;
    }

    // Solve for Y given derived T
    return ((ay * sampleT + by) * sampleT + cy) * sampleT;
}

/* @ignore */
- (BOOL)_renderAnimationStep:(JSObject)context timestamp:(double)timestamp
{
    if (context.startTime === null)
        context.startTime = timestamp;

    var elapsed = timestamp - context.startTime,
        linearProgress = elapsed / context.duration;

    if (linearProgress > 1.0) linearProgress = 1.0;

    // Apply Timing Function
    var progress = [self _solveBezier:linearProgress forTimingFunction:context.timingFunction];

    var start = context.startValue,
        end = context.endValue,
        current = nil;

    // Number
    if (typeof start === "number")
    {
        current = start + (end - start) * progress;
    }
    // Point / Size / Rect
    else if (start && start.x !== undefined && start.y !== undefined) // CGPoint
    {
        current = CGPointMake(start.x + (end.x - start.x) * progress,
                              start.y + (end.y - start.y) * progress);
    }
    else if (start && start.width !== undefined && start.height !== undefined) // CGSize
    {
        current = CGSizeMake(start.width + (end.width - start.width) * progress,
                             start.height + (end.height - start.height) * progress);
    }
    else if (start && start.origin !== undefined && start.size !== undefined) // CGRect
    {
        current = CGRectMake(
            start.origin.x + (end.origin.x - start.origin.x) * progress,
            start.origin.y + (end.origin.y - start.origin.y) * progress,
            start.size.width + (end.size.width - start.size.width) * progress,
            start.size.height + (end.size.height - start.size.height) * progress
        );
    }

    if (current !== nil)
        [[self delegate] setValue:current forKey:context.keyPath];

    if (linearProgress >= 1.0)
    {
        var anim = context.animation;

        // Cleanup
        var shouldRemove = [anim respondsToSelector:@selector(isRemovedOnCompletion)] ? [anim isRemovedOnCompletion] : YES;

        if (shouldRemove) {
            // Find key by context identity to handle groups correctly
            var keys = [_activeAnimations allKeys];
            for (var i = 0; i < keys.length; i++) {
                if ([_activeAnimations objectForKey:keys[i]] === context) {
                    [_activeAnimations removeObjectForKey:keys[i]];
                    break;
                }
            }
        }

        // Delegate
        var delegate = [anim delegate];
        if (delegate && [delegate respondsToSelector:@selector(animationDidStop:finished:)])
            [delegate animationDidStop:anim finished:YES];

        return NO;
    }

    return YES;
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
#if PLATFORM(DOM)
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
#endif
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
        CGAffineTransformConcatTo(aLayer._transformFromLayer, superlayer._sublayerTransformForSublayers, aLayer._transformFromLayer);
    }

    aLayer._transformToLayer = CGAffineTransformInvert(aLayer._transformFromLayer);

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
