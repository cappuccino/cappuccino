/*
 * CPStackView.j
 * AppKit
 *
 * Created by Daniel Boehringer.
 * Copyright 2025, Cappuccino Project.
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

#include "../Foundation/Foundation.h"

@import "CPView.j"

// Gravity Areas
@typedef CPStackViewGravity
    CPStackViewGravityTop       = 1;
    CPStackViewGravityLeading   = 1;
    CPStackViewGravityCenter    = 2;
    CPStackViewGravityBottom    = 3;
    CPStackViewGravityTrailing  = 3;

// Distribution (Deprecated in modern macOS, but kept for compatibility/logic)
@typedef CPStackViewDistribution
    CPStackViewDistributionGravityAreas         = 0;
    CPStackViewDistributionFill                 = 1;
    CPStackViewDistributionFillEqually          = 2;
    CPStackViewDistributionFillProportionally   = 3;
    CPStackViewDistributionEqualSpacing         = 4;
    CPStackViewDistributionEqualCentering       = 5;

// Visibility Priority
@typedef CPStackViewVisibilityPriority
    CPStackViewVisibilityPriorityMustHold       = 1000.0;
    CPStackViewVisibilityPriorityNotVisible     = 0.0;

var CPStackViewSpacingUseDefault = 3.40282347e+38; // FLT_MAX

/*!
    @ingroup appkit
    @class CPStackView

    CPStackView arranges an array of views horizontally or vertically and updates
    their placement and sizing when the window size changes.
 
    Unlike a simple list, CPStackView supports "Gravity Areas" (Leading, Center, Trailing),
    allowing you to pin groups of views to specific sections of the layout.
*/
@implementation CPStackView : CPView
{
    CPUserInterfaceLayoutOrientation    _orientation;
    CPLayoutAttribute                   _alignment;
    float                               _spacing;
    CPEdgeInsets                        _edgeInsets;
    
    BOOL                                _detachesHiddenViews;
    
    // View Storage by Gravity
    CPMutableArray                      _viewsLeading;
    CPMutableArray                      _viewsCenter;
    CPMutableArray                      _viewsTrailing;
    
    // Internal cache of all arranged subviews to maintain order for hittesting/iterating
    CPMutableArray                      _arrangedSubviews;
    
    // Custom Spacing storage
    CPMapTable                          _customSpacings;
    
    // Visibility Priorities
    CPMapTable                          _visibilityPriorities;
}

#pragma mark -
#pragma mark Initialization

+ (CPStackView)stackViewWithViews:(CPArray)views
{
    var stackView = [[CPStackView alloc] initWithFrame:CGRectMakeZero()];
    
    for (var i = 0, count = [views count]; i < count; i++)
        [stackView addView:views[i] inGravity:CPStackViewGravityLeading];
        
    return stackView;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _orientation = CPUserInterfaceLayoutOrientationHorizontal;
        _alignment = CPLayoutAttributeCenterY; // Default alignment
        _spacing = 8.0; // Default Cocoa spacing
        _edgeInsets = CPEdgeInsetsMake(0, 0, 0, 0);
        _detachesHiddenViews = YES;
        
        _viewsLeading = [[CPMutableArray alloc] init];
        _viewsCenter = [[CPMutableArray alloc] init];
        _viewsTrailing = [[CPMutableArray alloc] init];
        _arrangedSubviews = [[CPMutableArray alloc] init];
        
        _customSpacings = [[CPMapTable alloc] init];
        _visibilityPriorities = [[CPMapTable alloc] init];
    }
    return self;
}

#pragma mark -
#pragma mark Configuration

/*!
    The horizontal or vertical layout direction of the stack view.
*/
- (CPUserInterfaceLayoutOrientation)orientation
{
    return _orientation;
}

- (void)setOrientation:(CPUserInterfaceLayoutOrientation)anOrientation
{
    if (_orientation === anOrientation)
        return;
        
    _orientation = anOrientation;
    
    // Reset default alignment based on new orientation if needed, 
    // though usually developer sets alignment explicitly.
    // If switching to Vertical, CenterY makes less sense, usually CenterX.
    if (_orientation === CPUserInterfaceLayoutOrientationVertical)
    {
        if (_alignment === CPLayoutAttributeCenterY) 
            _alignment = CPLayoutAttributeCenterX;
    }
    else
    {
        if (_alignment === CPLayoutAttributeCenterX) 
            _alignment = CPLayoutAttributeCenterY;
    }

    [self setNeedsLayout:YES];
}

/*!
    The view alignment within the stack view.
    Common values:
    Horizontal: CPLayoutAttributeTop, CPLayoutAttributeBottom, CPLayoutAttributeCenterY, CPLayoutAttributeHeight (fill)
    Vertical:   CPLayoutAttributeLeading, CPLayoutAttributeTrailing, CPLayoutAttributeCenterX, CPLayoutAttributeWidth (fill)
*/
- (CPLayoutAttribute)alignment
{
    return _alignment;
}

- (void)setAlignment:(CPLayoutAttribute)anAlignment
{
    if (_alignment === anAlignment)
        return;
    
    _alignment = anAlignment;
    [self setNeedsLayout:YES];
}

/*!
    The minimum spacing, in points, between adjacent views in the stack view.
*/
- (float)spacing
{
    return _spacing;
}

- (void)setSpacing:(float)aSpacing
{
    if (_spacing === aSpacing)
        return;
        
    _spacing = aSpacing;
    [self setNeedsLayout:YES];
}

/*!
    The geometric padding, in points, inside the stack view, surrounding its views.
*/
- (CPEdgeInsets)edgeInsets
{
    return _edgeInsets;
}

- (void)setEdgeInsets:(CPEdgeInsets)insets
{
    if (CPEdgeInsetsEqualToEdgeInsets(_edgeInsets, insets))
        return;
        
    _edgeInsets = insets;
    [self setNeedsLayout:YES];
}

/*!
    A Boolean value that indicates whether the stack view removes hidden views from its view hierarchy.
*/
- (BOOL)detachesHiddenViews
{
    return _detachesHiddenViews;
}

- (void)setDetachesHiddenViews:(BOOL)shouldDetach
{
    if (_detachesHiddenViews === shouldDetach)
        return;
        
    _detachesHiddenViews = shouldDetach;
    [self setNeedsLayout:YES];
}

#pragma mark -
#pragma mark Managing Views in Gravity Areas

- (CPArray)_containerForGravity:(CPStackViewGravity)gravity
{
    if (gravity === CPStackViewGravityCenter)
        return _viewsCenter;
    else if (gravity === CPStackViewGravityTrailing) // or Bottom
        return _viewsTrailing;
        
    return _viewsLeading; // Leading or Top
}

/*!
    Adds a view to the end of the stack view gravity area.
*/
- (void)addView:(CPView)aView inGravity:(CPStackViewGravity)gravity
{
    var container = [self _containerForGravity:gravity];
    
    // Check if view is already in a container
    if ([_arrangedSubviews containsObject:aView])
        [self removeView:aView];
        
    [container addObject:aView];
    [_arrangedSubviews addObject:aView];
    
    // Add as actual subview
    if ([aView superview] !== self)
        [self addSubview:aView];
        
    [self setNeedsLayout:YES];
}

/*!
    Adds a view to a stack view gravity area at a specified index position.
*/
- (void)insertView:(CPView)aView atIndex:(CPInteger)index inGravity:(CPStackViewGravity)gravity
{
    var container = [self _containerForGravity:gravity];
    
    if ([_arrangedSubviews containsObject:aView])
        [self removeView:aView];
        
    if (index >= [container count])
        [container addObject:aView];
    else
        [container insertObject:aView atIndex:index];
        
    [_arrangedSubviews addObject:aView];
    
    if ([aView superview] !== self)
        [self addSubview:aView];
        
    [self setNeedsLayout:YES];
}

/*!
    Specifies an array of views for a specified gravity area in the stack view, replacing any previous views in that area.
*/
- (void)setViews:(CPArray)views inGravity:(CPStackViewGravity)gravity
{
    var container = [self _containerForGravity:gravity];
    
    // Remove old views from arranged list and superview
    for (var i = 0; i < [container count]; i++)
    {
        var oldView = container[i];
        [oldView removeFromSuperview];
        [_arrangedSubviews removeObject:oldView];
    }
    
    [container removeAllObjects];
    
    for (var i = 0; i < [views count]; i++)
    {
        var newView = views[i];
        [container addObject:newView];
        [_arrangedSubviews addObject:newView];
        [self addSubview:newView];
    }
    
    [self setNeedsLayout:YES];
}

/*!
    Removes a specified view from the stack view.
*/
- (void)removeView:(CPView)aView
{
    if (![_arrangedSubviews containsObject:aView])
        return;
        
    [_viewsLeading removeObject:aView];
    [_viewsCenter removeObject:aView];
    [_viewsTrailing removeObject:aView];
    [_arrangedSubviews removeObject:aView];
    
    [aView removeFromSuperview];
    
    [self setNeedsLayout:YES];
}

/*!
    Returns the array of views in the specified gravity area in the stack view.
*/
- (CPArray)viewsInGravity:(CPStackViewGravity)gravity
{
    return [[self _containerForGravity:gravity] copy];
}

/*!
    The array of views arranged by the stack view.
*/
- (CPArray)arrangedSubviews
{
    return [_arrangedSubviews copy];
}

/*!
    Adds the specified view to the end of the arranged subviews list.
    (Defaults to Leading gravity if not specified).
*/
- (void)addArrangedSubview:(CPView)view
{
    [self addView:view inGravity:CPStackViewGravityLeading];
}

/*!
    Removes the provided view from the stack’s array of arranged subviews.
*/
- (void)removeArrangedSubview:(CPView)view
{
    [self removeView:view];
}

#pragma mark -
#pragma mark Custom Spacing

- (float)customSpacingAfterView:(CPView)aView
{
    var val = [_customSpacings objectForKey:aView];
    if (val)
        return [val floatValue];
        
    return CPStackViewSpacingUseDefault;
}

- (void)setCustomSpacing:(float)spacing afterView:(CPView)aView
{
    if (spacing === CPStackViewSpacingUseDefault)
        [_customSpacings removeObjectForKey:aView];
    else
        [_customSpacings setObject:spacing forKey:aView];
        
    [self setNeedsLayout:YES];
}

- (float)_spacingAfterView:(CPView)aView
{
    var custom = [self customSpacingAfterView:aView];
    if (custom !== CPStackViewSpacingUseDefault)
        return custom;
    return _spacing;
}

#pragma mark -
#pragma mark Visibility Priority

- (void)setVisibilityPriority:(float)priority forView:(CPView)aView
{
    [_visibilityPriorities setObject:priority forKey:aView];
    
    if (priority === CPStackViewVisibilityPriorityNotVisible)
    {
        [aView setHidden:YES];
    }
    else if (priority === CPStackViewVisibilityPriorityMustHold)
    {
        [aView setHidden:NO];
    }
    // Note: Intermediate priorities require complex constraint logic 
    // or a multi-pass layout system to determine fitting, which is 
    // simplified here to basic Hidden/Visible states.
    
    [self setNeedsLayout:YES];
}

- (float)visibilityPriorityForView:(CPView)aView
{
    var val = [_visibilityPriorities objectForKey:aView];
    if (val)
        return [val floatValue];
    return CPStackViewVisibilityPriorityMustHold;
}

#pragma mark -
#pragma mark Layout

- (void)resizeSubviewsWithOldSize:(CGSize)oldSize
{
    [self layoutSubviews];
}

- (void)layoutSubviews
{
    if (_orientation === CPUserInterfaceLayoutOrientationVertical)
        [self _layoutVertical];
    else
        [self _layoutHorizontal];
}

- (void)_layoutHorizontal
{
    var bounds = [self bounds],
        availWidth = CGRectGetWidth(bounds) - _edgeInsets.left - _edgeInsets.right,
        availHeight = CGRectGetHeight(bounds) - _edgeInsets.top - _edgeInsets.bottom,
        currentX = _edgeInsets.left;
        
    // 1. Layout Leading Views
    currentX = [self _layoutViews:_viewsLeading startOffset:currentX availableOrthogonalSize:availHeight direction:1];
    
    // 2. Layout Trailing Views
    // We layout backwards from the right
    var startRight = CGRectGetWidth(bounds) - _edgeInsets.right;
    [self _layoutViews:_viewsTrailing startOffset:startRight availableOrthogonalSize:availHeight direction:-1];
    
    // 3. Layout Center Views
    if ([_viewsCenter count] > 0)
    {
        // Calculate total width of center stack
        var centerStackWidth = 0.0;
        for (var i = 0; i < [_viewsCenter count]; i++)
        {
            var view = _viewsCenter[i];
            if (_detachesHiddenViews && [view isHidden]) continue;
            
            centerStackWidth += CGRectGetWidth([view frame]);
            if (i < [_viewsCenter count] - 1)
                centerStackWidth += [self _spacingAfterView:view];
        }
        
        var centerStart = (CGRectGetWidth(bounds) / 2.0) - (centerStackWidth / 2.0);
        
        // Clamp to prevent overlap with Leading (simplified collision logic)
        // ideally stack view compresses views, but here we just shift/clip
        if (centerStart < currentX) 
            centerStart = currentX;
            
        [self _layoutViews:_viewsCenter startOffset:centerStart availableOrthogonalSize:availHeight direction:1];
    }
}

- (void)_layoutVertical
{
    var bounds = [self bounds],
        availWidth = CGRectGetWidth(bounds) - _edgeInsets.left - _edgeInsets.right,
        availHeight = CGRectGetHeight(bounds) - _edgeInsets.top - _edgeInsets.bottom,
        currentY = _edgeInsets.top;
        
    // 1. Layout Top (Leading) Views
    currentY = [self _layoutViews:_viewsLeading startOffset:currentY availableOrthogonalSize:availWidth direction:1];
    
    // 2. Layout Bottom (Trailing) Views
    var startBottom = CGRectGetHeight(bounds) - _edgeInsets.bottom;
    [self _layoutViews:_viewsTrailing startOffset:startBottom availableOrthogonalSize:availWidth direction:-1];
    
    // 3. Layout Center Views
    if ([_viewsCenter count] > 0)
    {
        var centerStackHeight = 0.0;
        for (var i = 0; i < [_viewsCenter count]; i++)
        {
            var view = _viewsCenter[i];
            if (_detachesHiddenViews && [view isHidden]) continue;
            
            centerStackHeight += CGRectGetHeight([view frame]);
            if (i < [_viewsCenter count] - 1)
                centerStackHeight += [self _spacingAfterView:view];
        }
        
        var centerStart = (CGRectGetHeight(bounds) / 2.0) - (centerStackHeight / 2.0);
        
        if (centerStart < currentY)
            centerStart = currentY;
            
        [self _layoutViews:_viewsCenter startOffset:centerStart availableOrthogonalSize:availWidth direction:1];
    }
}

// Helper to layout a specific array of views in one direction
// Returns the ending offset
- (float)_layoutViews:(CPArray)views startOffset:(float)offset availableOrthogonalSize:(float)orthoSize direction:(int)dir
{
    var cursor = offset;
    var isVert = (_orientation === CPUserInterfaceLayoutOrientationVertical);
    
    // If direction is -1 (Trailing/Bottom), we iterate backwards
    // However, the standard behavior for trailing gravity is that the *last* view added is at the *end*.
    // Leading: [A] [B] ->
    // Trailing: -> [C] [D] (where D is rightmost)
    // To support Trailing logic: We start at Right Edge, move left by Width(D), place D, move left by Spacing...
    
    var count = [views count];
    if (count === 0) return cursor;
    
    // If direction is negative (Trailing), we process list in reverse order to stack them from edge inwards
    var i = (dir === 1) ? 0 : count - 1;
    var limit = (dir === 1) ? count : -1;
    var step = (dir === 1) ? 1 : -1;
    
    for (; i !== limit; i += step)
    {
        var view = views[i];
        
        if (_detachesHiddenViews && [view isHidden])
            continue;
            
        var viewFrame = [view frame];
        var viewSizePrimary = isVert ? CGRectGetHeight(viewFrame) : CGRectGetWidth(viewFrame);
        
        // Handle Alignment (Orthogonal Axis)
        var orthoPos = 0.0;
        var viewOrthoSize = isVert ? CGRectGetWidth(viewFrame) : CGRectGetHeight(viewFrame);
        
        // Apply Stretch/Fill Alignment
        if (isVert)
        {
            // Vertical Stack, dealing with Width
            if (_alignment === CPLayoutAttributeWidth || _alignment === CPLayoutAttributeLeading || _alignment === CPLayoutAttributeTrailing) 
            {
                // Note: CPLayoutAttributeLeading/Trailing in this context implies filling width usually, 
                // or aligning to edges. Let's assume Width/Fill for Leading/Trailing/Left/Right 
                // in this simplified implementation, or strictly left/right.
                
                if (_alignment === CPLayoutAttributeWidth || _alignment === CPLayoutAttributeLeft || _alignment === CPLayoutAttributeLeading)
                {
                    // Fill width if explicit, or just align left
                    if (_alignment === CPLayoutAttributeWidth) viewOrthoSize = orthoSize;
                    orthoPos = _edgeInsets.left;
                }
                else if (_alignment === CPLayoutAttributeRight || _alignment === CPLayoutAttributeTrailing)
                {
                    orthoPos = _edgeInsets.left + (orthoSize - viewOrthoSize);
                }
                else // CenterX
                {
                    orthoPos = _edgeInsets.left + (orthoSize - viewOrthoSize) / 2.0;
                }
            }
            else // Default CenterX
            {
                 orthoPos = _edgeInsets.left + (orthoSize - viewOrthoSize) / 2.0;
            }
        }
        else
        {
            // Horizontal Stack, dealing with Height
            if (_alignment === CPLayoutAttributeHeight || _alignment === CPLayoutAttributeTop || _alignment === CPLayoutAttributeBottom)
            {
                if (_alignment === CPLayoutAttributeHeight)
                {
                    viewOrthoSize = orthoSize;
                    orthoPos = _edgeInsets.top;
                }
                else if (_alignment === CPLayoutAttributeTop)
                {
                    orthoPos = _edgeInsets.top;
                }
                else if (_alignment === CPLayoutAttributeBottom)
                {
                    orthoPos = _edgeInsets.top + (orthoSize - viewOrthoSize);
                }
                else // CenterY
                {
                    orthoPos = _edgeInsets.top + (orthoSize - viewOrthoSize) / 2.0;
                }
            }
            else // Default CenterY
            {
                orthoPos = _edgeInsets.top + (orthoSize - viewOrthoSize) / 2.0;
            }
        }
        
        // Calculate Position
        var originX = 0.0, originY = 0.0;
        var sizeW = 0.0, sizeH = 0.0;
        
        if (isVert)
        {
            // Vertical
            sizeH = viewSizePrimary;
            sizeW = viewOrthoSize;
            originX = orthoPos;
            
            if (dir === 1) {
                originY = cursor;
                cursor += sizeH + [self _spacingAfterView:view];
            } else {
                cursor -= sizeH;
                originY = cursor;
                cursor -= [self _spacingAfterView:view];
            }
        }
        else
        {
            // Horizontal
            sizeW = viewSizePrimary;
            sizeH = viewOrthoSize;
            originY = orthoPos;
            
            if (dir === 1) {
                originX = cursor;
                cursor += sizeW + [self _spacingAfterView:view];
            } else {
                cursor -= sizeW;
                originX = cursor;
                cursor -= [self _spacingAfterView:view];
            }
        }
        
        [view setFrame:CGRectMake(originX, originY, sizeW, sizeH)];
    }
    
    return cursor;
}

#pragma mark -
#pragma mark CPCoding

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    if (self)
    {
        _orientation = [aCoder decodeIntForKey:@"CPStackViewOrientation"];
        _alignment = [aCoder decodeIntForKey:@"CPStackViewAlignment"];
        _spacing = [aCoder decodeFloatForKey:@"CPStackViewSpacing"];
        _edgeInsets = [aCoder decodeObjectForKey:@"CPStackViewEdgeInsets"]; // Assuming CPEdgeInsets supports obj coding or manual decode
        if (!_edgeInsets) _edgeInsets = CPEdgeInsetsMake(0,0,0,0);
        
        _detachesHiddenViews = [aCoder decodeBoolForKey:@"CPStackViewDetachesHiddenViews"];
        
        _viewsLeading = [aCoder decodeObjectForKey:@"CPStackViewViewsLeading"] || [];
        _viewsCenter = [aCoder decodeObjectForKey:@"CPStackViewViewsCenter"] || [];
        _viewsTrailing = [aCoder decodeObjectForKey:@"CPStackViewViewsTrailing"] || [];
        
        // Rebuild arranged subviews cache
        _arrangedSubviews = [[CPMutableArray alloc] init];
        [_arrangedSubviews addObjectsFromArray:_viewsLeading];
        [_arrangedSubviews addObjectsFromArray:_viewsCenter];
        [_arrangedSubviews addObjectsFromArray:_viewsTrailing];
        
        _customSpacings = [aCoder decodeObjectForKey:@"CPStackViewCustomSpacings"] || [[CPMapTable alloc] init];
        _visibilityPriorities = [[CPMapTable alloc] init]; // usually not persisted
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeInt:_orientation forKey:@"CPStackViewOrientation"];
    [aCoder encodeInt:_alignment forKey:@"CPStackViewAlignment"];
    [aCoder encodeFloat:_spacing forKey:@"CPStackViewSpacing"];
    [aCoder encodeObject:_edgeInsets forKey:@"CPStackViewEdgeInsets"];
    [aCoder encodeBool:_detachesHiddenViews forKey:@"CPStackViewDetachesHiddenViews"];
    
    [aCoder encodeObject:_viewsLeading forKey:@"CPStackViewViewsLeading"];
    [aCoder encodeObject:_viewsCenter forKey:@"CPStackViewViewsCenter"];
    [aCoder encodeObject:_viewsTrailing forKey:@"CPStackViewViewsTrailing"];
    
    [aCoder encodeObject:_customSpacings forKey:@"CPStackViewCustomSpacings"];
}

@end
