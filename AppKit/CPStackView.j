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

/*
 * PLACEHOLDER IMPLEMENTATION — READ BEFORE USE OR MODIFICATION.
 *
 * This class lays out views by direct, procedural arithmetic. It has no
 * constraint solver. It cannot compress, expand, or negotiate space among
 * views the way NSStackView does; it only places views at their existing
 * frame size, in order, separated by fixed spacing.
 *
 * Known, accepted limitations:
 *   - `distribution` is stored but has no effect on layout. Fill,
 *     FillEqually, FillProportionally, and EqualSpacing are unimplemented.
 *   - Center-gravity views are clamped against the Leading edge only; if
 *     Leading + Center + Trailing content overflows the container, Center
 *     views can overlap Trailing views instead of compressing.
 *   - `visibilityPriority:forView:` only supports the two extreme values
 *     (MustHold / NotVisible). Intermediate priorities are accepted but
 *     have no defined effect.
 *   - No guarantee is made of correctness beyond what a single manual
 *     test (Tests/Manual/CPStackViewTest) exercises: orientation, the
 *     three gravity areas, alignment switching, spacing, and hidden-view
 *     detachment. Insertion, removal, custom spacing, and the CPCoding
 *     archive path are implemented but not verified by that test.
 *
 * This exists to give AppKit a working CPStackView symbol now, not to be
 * a durable design. It is expected to be replaced by a constraint-solver
 * based implementation (Kiwi.js) when time permits. Do not build on its
 * internal layout algorithm as if it were a stable foundation.
 */

@import "CPView.j"
@import <Foundation/CPMapTable.j>

// MARK: -
// MARK: Minimal local type definitions
//
// These types support this file only. They are not shared with the rest
// of AppKit. A future constraint-solver based Auto Layout engine will
// replace them. Numeric values match the equivalent Cocoa constants
// (NSUserInterfaceLayoutOrientation, NSLayoutAttribute) so that a later,
// solver-based CPLayoutAttribute can reuse these numbers without a
// renumbering pass.

@typedef CPUserInterfaceLayoutOrientation
    CPUserInterfaceLayoutOrientationHorizontal = 0;
    CPUserInterfaceLayoutOrientationVertical   = 1;

@typedef CPLayoutAttribute
    CPLayoutAttributeLeft      = 1;
    CPLayoutAttributeRight     = 2;
    CPLayoutAttributeTop       = 3;
    CPLayoutAttributeBottom    = 4;
    CPLayoutAttributeLeading   = 5;
    CPLayoutAttributeTrailing  = 6;
    CPLayoutAttributeWidth     = 7;
    CPLayoutAttributeHeight    = 8;
    CPLayoutAttributeCenterX   = 9;
    CPLayoutAttributeCenterY   = 10;

@typedef CPEdgeInsets

/*!
    Creates a CPEdgeInsets. Argument order matches Cocoa's NSEdgeInsetsMake
    (top, left, bottom, right). Storage reuses the existing CGInset struct,
    whose field order is (top, right, bottom, left).
*/
function CPEdgeInsetsMake(top, left, bottom, right)
{
    return CGInsetMake(top, right, bottom, left);
}

function CPEdgeInsetsEqualToEdgeInsets(lhsInsets, rhsInsets)
{
    return CGInsetEqualToInset(lhsInsets, rhsInsets);
}

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
    CPStackViewDistribution             _distribution;
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

// MARK: -
// MARK: Initialization

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
        _distribution = CPStackViewDistributionGravityAreas;
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

// MARK: -
// MARK: Configuration

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
    The distribution mode for the stack view.
    @note Not yet applied to layout. All views are laid out at their
    existing frame size regardless of this value, pending the
    constraint-solver based layout engine. The value is stored and
    returned so client code can read back what was set.
*/
- (CPStackViewDistribution)distribution
{
    return _distribution;
}

- (void)setDistribution:(CPStackViewDistribution)aDistribution
{
    if (_distribution === aDistribution)
        return;
        
    _distribution = aDistribution;
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

// MARK: -
// MARK: Managing Views in Gravity Areas

- (CPArray)_containerForGravity:(CPStackViewGravity)gravity
{
    if (gravity === CPStackViewGravityCenter)
        return _viewsCenter;
    else if (gravity === CPStackViewGravityTrailing) // or Bottom
        return _viewsTrailing;
        
    return _viewsLeading; // Leading or Top
}

/*!
    Rebuilds _arrangedSubviews from the three gravity containers, in
    Leading, Center, Trailing order. Call after any change to a gravity
    container so _arrangedSubviews stays a correct, single source of truth
    for ordering, rather than an incrementally and separately maintained
    (and error-prone) copy.
*/
- (void)_rebuildArrangedSubviews
{
    _arrangedSubviews = [[CPMutableArray alloc] init];
    [_arrangedSubviews addObjectsFromArray:_viewsLeading];
    [_arrangedSubviews addObjectsFromArray:_viewsCenter];
    [_arrangedSubviews addObjectsFromArray:_viewsTrailing];
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
    [self _rebuildArrangedSubviews];
    
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
        
    [self _rebuildArrangedSubviews];
    
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
    
    // Remove old views from superview
    for (var i = 0; i < [container count]; i++)
        [container[i] removeFromSuperview];
    
    [container removeAllObjects];
    
    for (var i = 0; i < [views count]; i++)
    {
        var newView = views[i];
        [container addObject:newView];
        [self addSubview:newView];
    }
    
    [self _rebuildArrangedSubviews];
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
    [self _rebuildArrangedSubviews];
    
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

// MARK: -
// MARK: Custom Spacing

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

// MARK: -
// MARK: Visibility Priority

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

// MARK: -
// MARK: Layout

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
    
    // Spacing is applied as a gap *before* placing an element (except the
    // first placed one), rather than trailing off the end after the last
    // element. This keeps the returned cursor at the true content edge,
    // with no phantom spacing past the final view.
    var hasPlacedAny = false;
    var pendingSpacing = 0;
    
    for (; i !== limit; i += step)
    {
        var view = views[i];
        
        if (_detachesHiddenViews && [view isHidden])
            continue;
            
        if (hasPlacedAny)
            cursor += (dir === 1) ? pendingSpacing : -pendingSpacing;
        
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
                cursor += sizeH;
            } else {
                cursor -= sizeH;
                originY = cursor;
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
                cursor += sizeW;
            } else {
                cursor -= sizeW;
                originX = cursor;
            }
        }
        
        [view setFrame:CGRectMake(originX, originY, sizeW, sizeH)];
        
        pendingSpacing = [self _spacingAfterView:view];
        hasPlacedAny = true;
    }
    
    return cursor;
}

// MARK: -
// MARK: CPCoding

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    if (self)
    {
        _orientation = [aCoder decodeIntForKey:@"CPStackViewOrientation"];
        _alignment = [aCoder decodeIntForKey:@"CPStackViewAlignment"];
        _distribution = [aCoder decodeIntForKey:@"CPStackViewDistribution"];
        _spacing = [aCoder decodeFloatForKey:@"CPStackViewSpacing"];
        _edgeInsets = [aCoder decodeObjectForKey:@"CPStackViewEdgeInsets"]; // Assuming CPEdgeInsets supports obj coding or manual decode
        if (!_edgeInsets) _edgeInsets = CPEdgeInsetsMake(0,0,0,0);
        
        _detachesHiddenViews = [aCoder decodeBoolForKey:@"CPStackViewDetachesHiddenViews"];
        
        _viewsLeading = [aCoder decodeObjectForKey:@"CPStackViewViewsLeading"] || [];
        _viewsCenter = [aCoder decodeObjectForKey:@"CPStackViewViewsCenter"] || [];
        _viewsTrailing = [aCoder decodeObjectForKey:@"CPStackViewViewsTrailing"] || [];
        
        // Rebuild arranged subviews cache
        [self _rebuildArrangedSubviews];
        
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
    [aCoder encodeInt:_distribution forKey:@"CPStackViewDistribution"];
    [aCoder encodeFloat:_spacing forKey:@"CPStackViewSpacing"];
    [aCoder encodeObject:_edgeInsets forKey:@"CPStackViewEdgeInsets"];
    [aCoder encodeBool:_detachesHiddenViews forKey:@"CPStackViewDetachesHiddenViews"];
    
    [aCoder encodeObject:_viewsLeading forKey:@"CPStackViewViewsLeading"];
    [aCoder encodeObject:_viewsCenter forKey:@"CPStackViewViewsCenter"];
    [aCoder encodeObject:_viewsTrailing forKey:@"CPStackViewViewsTrailing"];
    
    [aCoder encodeObject:_customSpacings forKey:@"CPStackViewCustomSpacings"];
}

@end
