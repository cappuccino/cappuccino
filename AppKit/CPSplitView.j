/*
 * CPSplitView.j
 * AppKit
 *
 * Created by Thomas Robinson.
 * Copyright 2008, 280 North, Inc.
 *
 * Adapted by Didier Korthoudt
 * Copyright 2019, Cappuccino Project.
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

@import "CPButtonBar.j"
@import "CPImage.j"
@import "CPView.j"
@import "CPCursor.j"
@import "CPTrackingArea.j"

@class CPUserDefaults
@global CPApp

@protocol CPSplitViewDelegate <CPObject>

@optional
- (BOOL)splitView:(CPSplitView)splitView canCollapseSubview:(CPView)subview;
- (BOOL)splitView:(CPSplitView)splitView shouldAdjustSizeOfSubview:(CPView)subview;
- (BOOL)splitView:(CPSplitView)splitView shouldCollapseSubview:(CPView)subview forDoubleClickOnDividerAtIndex:(CPInteger)dividerIndex;
- (CGRect)splitView:(CPSplitView)splitView additionalEffectiveRectOfDividerAtIndex:(CPInteger)dividerIndex;
- (CGRect)splitView:(CPSplitView)splitView effectiveRect:(CGRect)proposedEffectiveRect forDrawnRect:(CGRect)drawnRect ofDividerAtIndex:(CPInteger)dividerIndex;
- (float)splitView:(CPSplitView)splitView constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(CPInteger)dividerIndex;
- (float)splitView:(CPSplitView)splitView constrainMinCoordinate:(float)proposedMin ofSubviewAt:(CPInteger)dividerIndex;
- (float)splitView:(CPSplitView)splitView constrainSplitPosition:(float)proposedPosition ofSubviewAt:(CPInteger)dividerIndex;
- (void)splitView:(CPSplitView)splitView resizeSubviewsWithOldSize:(CGSize)oldSize;
- (void)splitViewDidResizeSubviews:(CPNotification)aNotification;
- (void)splitViewWillResizeSubviews:(CPNotification)aNotification;
// FIXME: missing splitView:shouldHideDividerAtIndex:

@end

var CPSplitViewDelegate_splitView_canCollapseSubview_                                   = 1 << 0,
    CPSplitViewDelegate_splitView_shouldAdjustSizeOfSubview_                            = 1 << 1,
    CPSplitViewDelegate_splitView_shouldCollapseSubview_forDoubleClickOnDividerAtIndex_ = 1 << 2,
    CPSplitViewDelegate_splitView_additionalEffectiveRectOfDividerAtIndex_              = 1 << 3,
    CPSplitViewDelegate_splitView_effectiveRect_forDrawnRect_ofDividerAtIndex_          = 1 << 4,
    CPSplitViewDelegate_splitView_constrainMaxCoordinate_ofSubviewAt_                   = 1 << 5,
    CPSplitViewDelegate_splitView_constrainMinCoordinate_ofSubviewAt_                   = 1 << 6,
    CPSplitViewDelegate_splitView_constrainSplitPosition_ofSubviewAt_                   = 1 << 7,
    CPSplitViewDelegate_splitView_resizeSubviewsWithOldSize_                            = 1 << 8,
    CPSplitViewDelegate_splitViewDidResizeSubviews_                                     = 1 << 9,
    CPSplitViewDelegate_splitViewWillResizeSubviews_                                    = 1 << 10;

#define SPLIT_VIEW_MAYBE_POST_WILL_RESIZE() \
    if ((_suppressResizeNotificationsMask & DidPostWillResizeNotification) === 0) \
    { \
        [self _postNotificationWillResize]; \
        _suppressResizeNotificationsMask |= DidPostWillResizeNotification; \
    }

#define SPLIT_VIEW_MAYBE_POST_DID_RESIZE() \
    if ((_suppressResizeNotificationsMask & ShouldSuppressResizeNotifications) !== 0) \
        _suppressResizeNotificationsMask |= DidSuppressResizeNotification; \
    else \
        [self _postNotificationDidResize];

#define SPLIT_VIEW_DID_SUPPRESS_RESIZE_NOTIFICATION() \
    ((_suppressResizeNotificationsMask & DidSuppressResizeNotification) !== 0)

#define SPLIT_VIEW_SUPPRESS_RESIZE_NOTIFICATIONS(shouldSuppress) \
    if (shouldSuppress) \
        _suppressResizeNotificationsMask |= ShouldSuppressResizeNotifications; \
    else \
        _suppressResizeNotificationsMask = 0;

CPSplitViewDidResizeSubviewsNotification = @"CPSplitViewDidResizeSubviewsNotification";
CPSplitViewWillResizeSubviewsNotification = @"CPSplitViewWillResizeSubviewsNotification";

var ShouldSuppressResizeNotifications   = 1,
    DidPostWillResizeNotification       = 1 << 1,
    DidSuppressResizeNotification       = 1 << 2;

// FIXME: Previous implementation (before October 2018 and Aristo3) uses direct DOM elements manipulations to render dividers.
//
//        When we'll implement storyboards, we'll also have to implement NSSplitViewController & NSSplitViewItem
//        See https://asciiwwdc.com/2015/sessions/221 & https://developer.apple.com/documentation/appkit/nssplitviewcontroller?language=objc

@typedef CPSplitViewDividerStyle
    CPSplitViewDividerStyleThick        = 1;
    CPSplitViewDividerStyleThin         = 2;
    CPSplitViewDividerStylePaneSplitter = 3;

// Dividers specific theme states

CPThemeStateSplitViewDividerStyleThick        = CPThemeState("splitview-divider-thick");
CPThemeStateSplitViewDividerStyleThin         = CPThemeState("splitview-divider-thin");
CPThemeStateSplitViewDividerStylePaneSplitter = CPThemeState("splitview-divider-pane-splitter");

var CPThemeStatesForSplitViewDivider = @[@"dummy one as CPSplitViewDividerStyle is not zero-based",
                                         CPThemeStateSplitViewDividerStyleThick,
                                         CPThemeStateSplitViewDividerStyleThin,
                                         CPThemeStateSplitViewDividerStylePaneSplitter];

/*!
    @ingroup appkit
    @class CPSplitView

    CPSplitView is a view that allows you to stack several subviews vertically or horizontally. The user is given divider to resize the subviews.
    The divider indices are zero-based. So the divider on the top (or left for vertical dividers) will be index 0.

    CPSplitView can be supplied a delegate to provide control over the resizing of the splitview and subviews. Those methods are documented in setDelegate:

    CPSplitView will add dividers for each subview you add. So just like adding subviews to a CPView you should call addSubview: to add new resizable subviews in your splitview.
*/

@implementation CPSplitView : CPView
{
    id <CPSplitViewDelegate>    _delegate;
    BOOL                        _isVertical;

    int                         _currentDivider;
    float                       _initialOffset;
    CPDictionary                _preCollapsePositions;

    CPString                    _originComponent;
    CPString                    _otherOriginComponent;
    CPString                    _sizeComponent;
    CPString                    _otherSizeComponent;

    BOOL                        _isTracking;

    CPString                    _autosaveName;
    BOOL                        _shouldAutosave;
    CGSize                      _shouldRestoreFromAutosaveUnlessFrameSize;

    int                         _suppressResizeNotificationsMask;

    CPArray                     _buttonBars;

    unsigned                    _implementedDelegateMethods;

    CPSplitViewDividerStyle     _dividerStyle;
    BOOL                        _isCSSBased;        // Cache for [[self theme] isCSSBased]
    CPMutableArray              _dividerSubviews;
    CPMutableArray              _arrangedSubviews;  // Subset of _realSubviews
    CPMutableArray              _realSubviews;      // These are all subviews (arranged and non arranged) without divider subviews
    BOOL                        _arrangesAllSubviews;
    BOOL                        _subviewsManagementDisabled;

    // Geometry caches
    CPMutableArray              _initialSizes;
    CPMutableArray              _ratios;
    CPMutableArray              _isFlexible;
}

+ (CPString)defaultThemeClass
{
    return @"splitview";
}

+ (CPDictionary)themeAttributes
{
    return @{
            @"divider-thickness": 1.0,  // Used by CSS Theming
            @"pane-divider-thickness": 10.0,
            @"pane-divider-color": [CPColor grayColor],
            @"horizontal-divider-color": [CPNull null],
            @"vertical-divider-color": [CPNull null],
            @"divider-color": [CPColor redColor]  // Used by CSS Theming
        };
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
        [self _init];

    return self;
}

- (void)_init
{
    _suppressResizeNotificationsMask = 0;
    _preCollapsePositions = @{};
    _currentDivider = CPNotFound;

    _buttonBars = [];

    _shouldAutosave = YES;
    _isTracking = NO;

    _isCSSBased          = [[self theme] isCSSBased];
    _dividerSubviews     = @[];
    _arrangedSubviews    = @[];
    _realSubviews        = @[];
    _initialSizes        = @[];
    _ratios              = @[];
    _isFlexible          = @[];
    _arrangesAllSubviews = YES; // Default for previous behavior compatibility

    [self setDividerStyle:CPSplitViewDividerStyleThick]; // Default of Xcode IB

    [self _setVertical:YES];
}

#pragma mark - Properties

- (CPSplitViewDividerStyle)dividerStyle
{
    return _dividerStyle;
}

- (void)setDividerStyle:(CPSplitViewDividerStyle)aStyle
{
    if (aStyle === _dividerStyle)
        return;

    _dividerStyle = aStyle;

    [self unsetThemeStates:@[CPThemeStateSplitViewDividerStyleThick, CPThemeStateSplitViewDividerStyleThin, CPThemeStateSplitViewDividerStylePaneSplitter]];
    [self setThemeState:CPThemeStatesForSplitViewDivider[_dividerStyle]];

    [self setNeedsLayout:YES];
}

- (CPColor)dividerColor
{
    if (_isCSSBased)
        return [self currentValueForThemeAttribute:@"divider-color"];

    // For compatibility with Aristo2
    if (_dividerStyle === CPSplitViewDividerStyleThin)
        return [self currentValueForThemeAttribute:@"pane-divider-color"];

    return [CPColor colorWithPatternImage:[self currentValueForThemeAttribute:(_isVertical ? @"vertical-divider-color" : @"horizontal-divider-color")]];
}

/*!
    Returns the thickness of the divider.
    @return float - the thickness of the divider.
*/
- (float)dividerThickness
{
    if (_isCSSBased)
        return [self currentValueForThemeAttribute:@"divider-thickness"];

    // For compatibility with Aristo2
    return [self currentValueForThemeAttribute:(_dividerStyle === CPSplitViewDividerStyleThin ? @"divider-thickness" : @"pane-divider-thickness")];
}

/*!
    Returns YES if the dividers are vertical, otherwise NO.
    @return YES if vertical, otherwise NO.
*/
- (BOOL)isVertical
{
    return _isVertical;
}

/*!
    Sets if the splitview dividers are vertical.
    @param shouldBeVertical - YES if the splitview dividers should be vertical, otherwise NO.
*/
- (void)setVertical:(BOOL)shouldBeVertical
{
    if (![self _setVertical:shouldBeVertical])
        return;

    // Just re-adjust evenly.
    var frame = [self frame],
        dividerThickness = [self dividerThickness],
        previousArrangedSubviews = [_arrangedSubviews copy],
        nbArrangedSubviews = previousArrangedSubviews.length,
        previousTotalSize = frame.size[_otherSizeComponent],
        previousRatios = [_ratios copy],
        totalSize = frame.size[_sizeComponent] - (nbArrangedSubviews - 1) * dividerThickness;

    [self _postNotificationWillResize];

    _subviewsManagementDisabled = YES;

    var i = _arrangedSubviews.length;

    while (i > 0)
        [self removeArrangedSubview:_arrangedSubviews[--i]];

    for (var i = 0, theView, theViewSize; i < nbArrangedSubviews; i++)
    {
        theView = previousArrangedSubviews[i];
        theViewSize = CGSizeMakeCopy([theView frameSize]);
        theViewSize[_sizeComponent] = totalSize * previousRatios[i];
        theViewSize[_otherSizeComponent] = frame.size[_otherSizeComponent];
        [theView setFrameSize:theViewSize];

        [self _addArrangedSubview:theView];
    }

    _subviewsManagementDisabled = NO;

    [self _postNotificationDidResize];

    return;
}

- (BOOL)_setVertical:(BOOL)shouldBeVertical
{
    var changed = (_isVertical != shouldBeVertical);

    _isVertical = shouldBeVertical;

    _originComponent      = _isVertical ? "x" : "y";
    _otherOriginComponent = _isVertical ? "y" : "x";
    _sizeComponent        = _isVertical ? "width" : "height";
    _otherSizeComponent   = _isVertical ? "height" : "width";

    if (_isVertical)
        [self setThemeState:CPThemeStateVertical];
    else
        [self unsetThemeState:CPThemeStateVertical];

    return changed;
}

- (BOOL)arrangesAllSubviews
{
    return _arrangesAllSubviews;
}

- (void)setArrangesAllSubviews:(BOOL)shouldArrangeAllSubviews
{
    if (shouldArrangeAllSubviews == _arrangesAllSubviews)
        return;

    _arrangesAllSubviews = shouldArrangeAllSubviews;

    if (_arrangesAllSubviews)
    {
        // We take all real subviews and put them in arranged subviews in the same order
        // Using plain add/remove methods will ensure a correct dividers management
        var views = [_realSubviews copy];

        // First, remove all real subviews (arranged & non arranged)
        for (var i = views.length - 1; i >= 0; i--)
            [views[i] removeFromSuperview];

        // Then add all real subviews as arranged subviews
        for (var i = 0, count = views.length; i < count; i++)
            [self addArrangedSubview:views[i]]
    }

    [self setNeedsLayout:YES];
}

/*!
 Sets the delegate of the receiver.
 Possible delegate methods to implement are listed below.

 Notifies the delegate when the subviews have resized.
 @code
 - (void)splitViewDidResizeSubviews:(CPNotification)aNotification;
 @endcode

 Notifies the delegate when the subviews will be resized.
 @code
 - (void)splitViewWillResizeSubviews:(CPNotification)aNotification;
 @endcode

 Allows the delegate to specify which of the CPSplitView's subviews should adjust if the window is resized.
 @code
 - (BOOL)splitView:(CPSplitView)aSplitView shouldAdjustSizeOfSubview:(CPView)aSubView
 @endcode

 Lets the delegate specify a different rect for which the user can drag the splitView divider.
 @code
 - (CGRect)splitView:(CPSplitView)aSplitView effectiveRect:(CGRect)aRect forDrawnRect:(CGRect)aDrawnRect ofDividerAtIndex:(int)aDividerIndex;
 @endcode

 Lets the delegate specify an additional rect for which the user can drag the splitview divider.
 @code
 - (CGRect)splitView:(CPSplitView)aSplitView additionalEffectiveRectOfDividerAtIndex:(int)indexOfDivider;
 @endcode

 Notifies the delegate that the splitview is about to be collapsed. This usually happens when the user
 Double clicks on the divider. Return YES if the subview can be collapsed, otherwise NO.
 @code
 - (BOOL)splitView:(CPSplitView)aSplitView canCollapseSubview:(CPView)aSubview;
 @endcode

 Notifies the delegate that the subview at indexOfDivider is about to be collapsed. This usually happens when the user
 Double clicks on the divider. Return YES if the subview should be collapsed, otherwise NO.
 @code
 - (BOOL)splitView:(CPSplitView)aSplitView shouldCollapseSubview:(CPView)aSubview forDoubleClickOnDividerAtIndex:(int)indexOfDivider;
 @endcode

 Allows the delegate to constrain the subview beings resized. This method is called continuously as the user resizes the divider.
 For example if the subview needs to have a width which is a multiple of a certain number you could return that multiple with this method.
 @code
 - (float)splitView:(CPSplitView)aSpiltView constrainSplitPosition:(float)proposedPosition ofSubviewAt:(int)subviewIndex;
 @endcode

 Allows the delegate to constrain the minimum position of a subview.
 @code
 - (float)splitView:(CPSplitView)aSplitView constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)subviewIndex;
 @endcode

 Allows the delegate to constrain the maximum position of a subview.
 @code
 - (float)splitView:(CPSplitView)aSplitView constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)subviewIndex;
 @endcode

 Allows the splitview to specify a custom resizing behavior. This is called when the splitview is resized.
 The sum of the views and the sum of the dividers should be equal to the size of the splitview.
 @code
 - (void)splitView:(CPSplitView)aSplitView resizeSubviewsWithOldSize:(CGSize)oldSize;
 @endcode

 @param delegate - The delegate of the splitview.
 */
- (void)setDelegate:(id <CPSplitViewDelegate>)aDelegate
{
    if (_delegate === aDelegate)
        return;

    _delegate = aDelegate;
    _implementedDelegateMethods = 0;

    if ([_delegate respondsToSelector:@selector(splitViewWillResizeSubviews:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitViewWillResizeSubviews_;

    if ([_delegate respondsToSelector:@selector(splitViewDidResizeSubviews:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitViewDidResizeSubviews_;

    if ([_delegate respondsToSelector:@selector(splitView:canCollapseSubview:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_canCollapseSubview_;

    if ([_delegate respondsToSelector:@selector(splitView:shouldAdjustSizeOfSubview:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_shouldAdjustSizeOfSubview_;

    if ([_delegate respondsToSelector:@selector(splitView:shouldCollapseSubview:forDoubleClickOnDividerAtIndex:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_shouldCollapseSubview_forDoubleClickOnDividerAtIndex_;

    if ([_delegate respondsToSelector:@selector(splitView:additionalEffectiveRectOfDividerAtIndex:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_additionalEffectiveRectOfDividerAtIndex_;

    if ([_delegate respondsToSelector:@selector(splitView:effectiveRect:forDrawnRect:ofDividerAtIndex:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_effectiveRect_forDrawnRect_ofDividerAtIndex_;

    if ([_delegate respondsToSelector:@selector(splitView:constrainMaxCoordinate:ofSubviewAt:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_constrainMaxCoordinate_ofSubviewAt_;

    if ([_delegate respondsToSelector:@selector(splitView:constrainMinCoordinate:ofSubviewAt:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_constrainMinCoordinate_ofSubviewAt_;

    if ([_delegate respondsToSelector:@selector(splitView:constrainSplitPosition:ofSubviewAt:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_constrainSplitPosition_ofSubviewAt_;

    if ([_delegate respondsToSelector:@selector(splitView:resizeSubviewsWithOldSize:)])
        _implementedDelegateMethods |= CPSplitViewDelegate_splitView_resizeSubviewsWithOldSize_;

    // We have to recompute flexible/fixed caches as the new delegate could consider things differently...
    [self _updateRatios];
}

- (id <CPSplitViewDelegate>)delegate
{
    return _delegate;
}

#pragma mark - Subviews management

// FIXME: il faut également tenir compte des button bars quand on ajouter / insert une vue.
// Par exemple, si une button bar est placée sur la dernière vue, pas de resize à droite mais
// si après on ajoute une nouvelle dernière vue, il va y avoir un nouveau divider -> il faudrait
// un resize à droite

- (CPArray)arrangedSubviews
{
    return [_arrangedSubviews copy];
}

- (void)addArrangedSubview:(CPView)view
{
    // If the view is already an arranged subview, just return quietly as Cocoa does
    if ([_arrangedSubviews containsObject:view])
        return;

    _subviewsManagementDisabled = YES;

    [self _addArrangedSubview:view];
    [self addSubview:view];

    _subviewsManagementDisabled = NO;
}

- (void)_addArrangedSubview:(CPView)view
{
    [self _insertArrangedSubview:view atIndex:_arrangedSubviews.length];
}

- (void)insertArrangedSubview:(CPView)view atIndex:(CPInteger)index
{
    // If the view is already an arranged subview, just return quietly as Cocoa does
    if ([_arrangedSubviews containsObject:view])
        return;

    if ((index > _arrangedSubviews.length) || (index < 0))
    {
        CPLog.error("CPSplitView -insertArrangedSubview:"+view+" atIndex:"+index+" is out of range ("+self+")");
        return;
    }

    _subviewsManagementDisabled = YES;

    [self _insertArrangedSubview:view atIndex:index];
    [self addSubview:view];

    _subviewsManagementDisabled = NO;
}

- (void)_insertArrangedSubview:(CPView)view atIndex:(CPInteger)index
{
    var thickness     = [self dividerThickness],
        newViewFrame  = [view frame],
        myFrame       = [self frame],
        flexibleSpace = 0,
        flexibleCount = 0,
        fixedSpace    = 0,
        fixedCount    = 0;

    // We temporarily set the size of the new arranged subview
    var size = CGSizeMakeCopy(myFrame.size);
    size[_sizeComponent] = newViewFrame.size[_sizeComponent];
    [view setFrameSize:size];

    [_arrangedSubviews insertObject:view atIndex:index];
    [_realSubviews     addObject:view];
    [_initialSizes     insertObject:newViewFrame.size[_sizeComponent] atIndex:index];

    // We have to reinitialize this cache as flexibility can change over time (determined by the delegate)
    _isFlexible = @[];

    for (var i = 0, count = _arrangedSubviews.length, isFlexible; i < count; i++)
    {
        [_isFlexible addObject:(isFlexible = [self _sendDelegateSplitViewShouldAdjustSizeOfSubview:_arrangedSubviews[i]])];

        if (isFlexible)
        {
            flexibleSpace += _initialSizes[i];
            flexibleCount++;
        }
        else
        {
            fixedSpace += _initialSizes[i];
            fixedCount++;
        }
    }

    _ratios = @[];

    for (var i = 0, count = _arrangedSubviews.length; i < count; i++)
        if (_isFlexible[i])
            [_ratios addObject:(_initialSizes[i] / flexibleSpace)];
        else
            [_ratios addObject:(_initialSizes[i] / fixedSpace)];

    // If we have more than one arranged subview, then we have to add a divider
    if (_arrangedSubviews.length > 1)
    {
        var dividerFrame = CGRectMakeZero();

        dividerFrame.size                 = CGSizeMakeCopy(myFrame.size);
        dividerFrame.size[_sizeComponent] = thickness;

        var divider = [[CPView alloc] initWithFrame:dividerFrame];

        [divider setBackgroundColor:[self dividerColor]];

        [_dividerSubviews addObject:divider];
        [super            addSubview:divider];
    }
}

- (void)removeArrangedSubview:(CPView)view
{
    // The view remains a subview, keeping its size and position at the moment of the removal.
    // Remaining arranged subviews keep their ratios.

    var arrangedIndex = [_arrangedSubviews indexOfObject:view];

    if (arrangedIndex == CPNotFound)
    {
        CPLog.error("CPSplitView -removeArrangedSubview: view ("+view+") is not an arranged subview of split view ("+self+")");
        return;
    }

    [_arrangedSubviews removeObjectAtIndex:arrangedIndex];

    if (_dividerSubviews.length > 0)
    {
        [[_dividerSubviews lastObject] removeFromSuperview];
        [_dividerSubviews removeLastObject];
    }

    [self _updateRatios];
}

- (void)addSubview:(CPView)aSubview
{
    [super addSubview:aSubview];

    if (!_subviewsManagementDisabled && _arrangesAllSubviews)
        [self _addArrangedSubview:aSubview];
}

- (void)willRemoveSubview:(CPView)aView
{
    if (!_subviewsManagementDisabled && [_arrangedSubviews containsObject:aView])
        [self removeArrangedSubview:aView];
}

- (void)replaceSubview:(CPView)aSubview with:(CPView)aView
{
    if (aSubview._superview !== self || aSubview === aView)
        return;

    _subviewsManagementDisabled = YES;

    var arrangedIndex = [_arrangedSubviews indexOfObjectIdenticalTo:aSubview],
        realIndex     = [_realSubviews     indexOfObjectIdenticalTo:aSubview];

    [super replaceSubview:aSubview with:aView];

    if (arrangedIndex < 0)
        return;

    [_arrangedSubviews replaceObjectAtIndex:arrangedIndex withObject:aView];
    [_realSubviews     replaceObjectAtIndex:realIndex     withObject:aView];

    _subviewsManagementDisabled = NO;
}

#pragma mark - Layout subviews

- (CGRect)rectOfDividerAtIndex:(int)aDivider
{
    return [_dividerSubviews[aDivider] frame];
}

/*!
 Returns the rect of the divider which the user is able to drag to resize.

 @param int - The index of the divider.
 @return CGRect - The rect the user can drag.
 */
- (CGRect)effectiveRectOfDividerAtIndex:(int)aDivider
{
    var realRect = [self rectOfDividerAtIndex:aDivider],
        padding = 2;

    realRect.size[_sizeComponent] += padding * 2;
    realRect.origin[_originComponent] -= padding;

    return realRect;
}

- (void)setFrameSize:(CGSize)aSize
{
    if (_shouldRestoreFromAutosaveUnlessFrameSize)
        _shouldAutosave = NO;

    [super setFrameSize:aSize];

    if (_shouldRestoreFromAutosaveUnlessFrameSize)
        _shouldAutosave = YES;
}

- (void)resizeSubviewsWithOldSize:(CGSize)oldSize
{
    if ([self _delegateRespondsToSplitViewResizeSubviewsWithOldSize])
    {
        [self _sendDelegateSplitViewResizeSubviewsWithOldSize:oldSize];
        return;
    }

    // We adapt here only the "other" size (that is height for a vertical split view / width for an horizontal split view)
    // The complicated size will be treated in adjustSubviews

    var myOtherSize = [self frame].size[_otherSizeComponent];

    for (var i = 0, count = _arrangedSubviews.length, size; i < count; i++)
    {
        size = CGSizeMakeCopy([_arrangedSubviews[i] frameSize]);

        size[_otherSizeComponent] = myOtherSize;

        [_arrangedSubviews[i] setFrameSize:size];
    }

    for (var i = 0, count = _dividerSubviews.length, size; i < count; i++)
    {
        size = CGSizeMakeCopy([_dividerSubviews[i] frameSize]);

        size[_otherSizeComponent] = myOtherSize;

        [_dividerSubviews[i] setFrameSize:size];
    }

    [self adjustSubviews];
}

/*!
 Adjusts the sizes of the split view’s subviews so they (plus the dividers) fill the split view.

 When you call this method, the split view’s subviews are resized proportionally; the relative sizes of the subviews do not change.

 The default implementation of this method resizes subviews proportionally so that the ratio of heights (when using horizontal dividers)
 or widths (when using vertical dividers) does not change, even though the absolute sizes change.

 Call this method on split views from which subviews have been added or removed, to reestablish the consistency of subview placement.

 This method invalidates the cursor when it is over a divider, ensuring the cursor is always of the correct type during and after resizing animations.
 */
- (void)adjustSubviews
{
    SPLIT_VIEW_MAYBE_POST_WILL_RESIZE();
    [self _postNotificationWillResize];

    // 2 possibilities : we have, or not, enough flexible space to accomodate fixed size subviews

    var sizeToFit   = [self frame].size[_sizeComponent] - _dividerSubviews.length * [self dividerThickness],
        fixedSize   = 0,
        nbSubviews  = _arrangedSubviews.length;

    for (var i = 0; i < nbSubviews; i++)
        if (!_isFlexible[i])
            fixedSize += [_arrangedSubviews[i] frameSize][_sizeComponent];

    if (fixedSize < sizeToFit)
    {
        // There's enough space to maintain fixed and flexible subviews
        // So we only deal with flexible subviews, resizing them while keeping all ratios

        var newFlexibleSize = sizeToFit - fixedSize,
            remainingSpace  = newFlexibleSize,
            flexibleCount   = 0;

        for (var i = 0, size, floatSize, intSize, cumulativeFloatSize = 0.0, cumulativeIntSize = 0; i < nbSubviews; i++)
            if (_isFlexible[i])
            {
                flexibleCount++;

                // Cocoa doesn't seem to round arranged subviews sizes.
                // So the next computation ensures we get the same results but with rounded sizes.
                size = CGSizeMakeCopy([_arrangedSubviews[i] frameSize]);
                floatSize = MIN((newFlexibleSize * _ratios[i]), remainingSpace);
                cumulativeFloatSize += floatSize;

                intSize = ROUND(cumulativeFloatSize) - cumulativeIntSize;
                cumulativeIntSize += intSize;

                remainingSpace -= size[_sizeComponent] = intSize;

                [_arrangedSubviews[i] setFrameSize:size];
            }

        if (remainingSpace > 0)
            // Due to roundings, some pixels remain to attribute. We do this in reverse order of views.
            // For example, if we have 9px to distribute on 4 views, we do : +2 +2 +2 +3
            [self _distribute:remainingSpace amoung:flexibleCount onFlexible:YES fromIndex:0 toIndex:nbSubviews-1];
    }
    else
    {
        // There's not enough space to maintain fixed and flexible subviews
        // So we collapse all flexible subviews and shrink evenly fixed subviews

        var remainingSpace = sizeToFit,
            fixedCount     = 0;

        for (var i = 0, size, floatSize, intSize, cumulativeFloatSize = 0.0, cumulativeIntSize = 0; i < nbSubviews; i++)
        {
            size = CGSizeMakeCopy([_arrangedSubviews[i] frameSize]);

            if (_isFlexible[i])
                size[_sizeComponent] = 0;
            else
            {
                fixedCount++;

                // Cocoa doesn't seem to round arranged subviews sizes.
                // So the next computation ensures we get the same results but with rounded sizes.
                floatSize = MIN((sizeToFit * _ratios[i]), remainingSpace);
                cumulativeFloatSize += floatSize;

                intSize = ROUND(cumulativeFloatSize) - cumulativeIntSize;
                cumulativeIntSize += intSize;

                remainingSpace -= size[_sizeComponent] = intSize;
            }

            [_arrangedSubviews[i] setFrameSize:size];
        }

        if (remainingSpace > 0)
            [self _distribute:remainingSpace amoung:fixedCount onFlexible:NO fromIndex:0 toIndex:nbSubviews-1];
    }

    SPLIT_VIEW_MAYBE_POST_DID_RESIZE();

    [self layoutSubviews];
}

- (void)layoutSubviews
{
    for (var i = 0, count = _arrangedSubviews.length, position = 0, origin; i < count; i++)
    {
        origin                   = CGPointMakeZero();
        origin[_originComponent] = position;
        position                += [_arrangedSubviews[i] frame].size[_sizeComponent];

        [_arrangedSubviews[i] setFrameOrigin:origin];

        if (i < count - 1)
        {
            origin                   = CGPointMakeZero();
            origin[_originComponent] = position;
            position                += [_dividerSubviews[i] frame].size[_sizeComponent];

            [_dividerSubviews[i] setFrameOrigin:origin];
        }
    }

    [self updateTrackingAreas];
}

#pragma mark - Private layout utilities

- (void)_distribute:(CPInteger)remainingSpace amoung:(CPInteger)count onFlexible:(BOOL)onFlexible fromIndex:(CPInteger)fromIndex toIndex:(CPInteger)toIndex
{
    for (var i = toIndex, size, supplement; i >= fromIndex; i--)
        if (_isFlexible[i] == onFlexible)
        {
            size = CGSizeMakeCopy([_arrangedSubviews[i] frameSize]);
            remainingSpace -= supplement = CEIL(remainingSpace / count);
            size[_sizeComponent] += supplement;
            [_arrangedSubviews[i] setFrameSize:size];

            count--;
        }
}

- (void)_updateRatios
{
    // Compute new ratios based on new sizes

    var flexibleSpace = 0,
        flexibleCount = 0,
        fixedSpace    = 0,
        fixedCount    = 0;

    // We have to reinitialize this cache as flexibility can change over time (determined by the delegate)
    _isFlexible   = @[];
    _initialSizes = @[];

    for (var i = 0, count = _arrangedSubviews.length, isFlexible; i < count; i++)
    {
        [_isFlexible   addObject:(isFlexible = [self _sendDelegateSplitViewShouldAdjustSizeOfSubview:_arrangedSubviews[i]])];
        [_initialSizes addObject:[_arrangedSubviews[i] frame].size[_sizeComponent]];

        if (isFlexible)
        {
            flexibleSpace += _initialSizes[i];
            flexibleCount++;
        }
        else
        {
            fixedSpace += _initialSizes[i];
            fixedCount++;
        }
    }

    _ratios = @[];

    for (var i = 0, count = _arrangedSubviews.length; i < count; i++)
        if (_isFlexible[i])
            [_ratios addObject:(_initialSizes[i] / flexibleSpace)];
        else
            [_ratios addObject:(_initialSizes[i] / fixedSpace)];
}

#pragma mark -

/*!
    Returns YES if the supplied subview is collapsed, otherwise NO.
    @param aSubview - the subview you are interested in.
    @return BOOL - YES if the subview is collapsed, otherwise NO.
*/
- (BOOL)isSubviewCollapsed:(CPView)subview
{
    return ([subview frame].size[_sizeComponent] < 1);
}

/*!
    Draws the divider at a given rect.
    @param aRect - the rect of the divider to draw.
*/
- (void)drawDividerInRect:(CGRect)aRect
{
    // This is declared for Cocoa compatibility but has no effect in Cappuccino
}

- (BOOL)cursorAtPoint:(CGPoint)aPoint hitDividerAtIndex:(int)anIndex
{
    var effectiveRect      = [self effectiveRectOfDividerAtIndex:anIndex],
        leftButtonBar      = _buttonBars[anIndex],
        rightButtonBar     = _buttonBars[anIndex+1],
        leftButtonBarRect  = nil,
        rightButtonBarRect = nil,
        additionalRect     = nil;

    if (leftButtonBar && [leftButtonBar hasRightResizeControl])
    {
        leftButtonBarRect        = [leftButtonBar rightResizeControlFrame];
        leftButtonBarRect.origin = [self convertPoint:leftButtonBarRect.origin fromView:leftButtonBar];
    }

    if (rightButtonBar && [rightButtonBar hasLeftResizeControl])
    {
        rightButtonBarRect        = [rightButtonBar leftResizeControlFrame];
        rightButtonBarRect.origin = [self convertPoint:rightButtonBarRect.origin fromView:rightButtonBar];
    }

    effectiveRect = [self _sendDelegateSplitViewEffectiveRect:effectiveRect forDrawnRect:effectiveRect ofDividerAtIndex:anIndex];
    additionalRect = [self _sendDelegateSplitViewAdditionalEffectiveRectOfDividerAtIndex:anIndex];

    return CGRectContainsPoint(effectiveRect, aPoint) ||
           (additionalRect && CGRectContainsPoint(additionalRect, aPoint)) ||
           (leftButtonBarRect && CGRectContainsPoint(leftButtonBarRect, aPoint)) ||
           (rightButtonBarRect && CGRectContainsPoint(rightButtonBarRect, aPoint));
}

- (CPView)hitTest:(CGPoint)aPoint
{
    if ([self isHidden] || ![self hitTests] || !CGRectContainsPoint([self frame], aPoint))
        return nil;

    var point = [self convertPoint:aPoint fromView:[self superview]],
        dividerIndex = [self _dividerAtPoint:point];

    if (dividerIndex !== CPNotFound)
        return self;

    return [super hitTest:aPoint];
}

- (CPInteger)_dividerAtPoint:(CGPoint)aPoint
{
    for (var i = 0, count = [_dividerSubviews count]; i < count; i++)
    {
        if ([self cursorAtPoint:aPoint hitDividerAtIndex:i])
            return i;
    }

    return CPNotFound;
}
/*
    Tracks the divider.
    @param anEvent the input event
*/
- (void)trackDivider:(CPEvent)anEvent
{
    var type = [anEvent type];

    if (type == CPLeftMouseUp)
    {
        if ([anEvent clickCount] == 2 || (_isTracking && _currentDivider != CPNotFound))
        {
            // We disabled autosaving during tracking.
            _shouldAutosave = YES;
            _currentDivider = CPNotFound;
            _isTracking = NO;

            [self _autosave];
            [self _updateResizeCursor:anEvent];
        }

        return;
    }

    if (type == CPLeftMouseDown)
    {
        var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];
        _currentDivider = [self _dividerAtPoint:point];

        var frame = [_arrangedSubviews[_currentDivider] frame],
            startPosition = frame.origin[_originComponent] + frame.size[_sizeComponent];

        if ([anEvent clickCount] == 2 &&
            [self _delegateRespondsToSplitViewCanCollapseSubview] &&
            [self _delegateRespondsToSplitViewshouldCollapseSubviewForDoubleClickOnDividerAtIndex])
        {
            var minPosition = [self minPossiblePositionOfDividerAtIndex:_currentDivider],
                maxPosition = [self maxPossiblePositionOfDividerAtIndex:_currentDivider],
                preCollapsePosition = [_preCollapsePositions objectForKey:"" + _currentDivider] || 0;

            if ([self _sendDelegateSplitViewCanCollapseSubview:_arrangedSubviews[_currentDivider]] && [self _sendDelegateSplitViewShouldCollapseSubview:_arrangedSubviews[_currentDivider] forDoubleClickOnDividerAtIndex:_currentDivider])
            {
                if ([self isSubviewCollapsed:_arrangedSubviews[_currentDivider]])
                    [self setPosition:preCollapsePosition ? preCollapsePosition : (minPosition + (maxPosition - minPosition) / 2) ofDividerAtIndex:_currentDivider];
                else
                    [self setPosition:minPosition ofDividerAtIndex:_currentDivider];
            }
            else if ([self _sendDelegateSplitViewCanCollapseSubview:_arrangedSubviews[_currentDivider + 1]] && [self _sendDelegateSplitViewShouldCollapseSubview:_arrangedSubviews[_currentDivider + 1] forDoubleClickOnDividerAtIndex:_currentDivider])
            {
                if ([self isSubviewCollapsed:_arrangedSubviews[_currentDivider + 1]])
                    [self setPosition:preCollapsePosition ? preCollapsePosition : (minPosition + (maxPosition - minPosition) / 2) ofDividerAtIndex:_currentDivider];
                else
                    [self setPosition:maxPosition ofDividerAtIndex:_currentDivider];
            }
        }
        else
        {
            _initialOffset = startPosition - point[_originComponent];
            // Don't autosave during a resize. We'll wait until it's done.
            _shouldAutosave = NO;
            [self _postNotificationWillResize];
        }

    }
    else if (type == CPLeftMouseDragged && _currentDivider != CPNotFound)
    {
        if (!_isTracking)
        {
            // Don't autosave during a resize. We'll wait until it's done.
            _shouldAutosave = NO;
            [self _postNotificationWillResize];

            _isTracking = YES;
        }

        var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];

        [self setPosition:(point[_originComponent] + _initialOffset) ofDividerAtIndex:_currentDivider];
        // Cursor might change if we reach a resize limit.
        [self _updateResizeCursor:anEvent];
    }

    [CPApp setTarget:self selector:@selector(trackDivider:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
}

- (void)mouseDown:(CPEvent)anEvent
{
    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil],
        dividerIndex = [self _dividerAtPoint:point];

    if (dividerIndex !== CPNotFound)
        [self trackDivider:anEvent];
}

- (void)viewDidMoveToWindow
{
    // Enable split view resize cursors. Commented out pending CPTrackingArea implementation.
    //[[self window] setAcceptsMouseMovedEvents:YES];
}

- (void)_updateResizeCursor:(CPEvent)anEvent
{
    var point = [self convertPoint:[anEvent locationInWindow] fromView:nil];

    if ([anEvent type] === CPLeftMouseUp && ![[self window] acceptsMouseMovedEvents])
    {
        [[CPCursor arrowCursor] set];
        return;
    }

    for (var i = 0, count = [_arrangedSubviews count] - 1; i < count; i++)
    {
        // If we are currently tracking, keep the resize cursor active even outside of hit areas.
        if (_currentDivider === i || (_currentDivider == CPNotFound && [self cursorAtPoint:point hitDividerAtIndex:i]))
        {
            var frameA = [_arrangedSubviews[i] frame],
                sizeA = frameA.size[_sizeComponent],
                startPosition = frameA.origin[_originComponent] + sizeA,
                frameB = [_arrangedSubviews[i + 1] frame],
                sizeB = frameB.size[_sizeComponent],
                canShrink = [self _realPositionForPosition:startPosition - 1 ofDividerAtIndex:i] < startPosition,
                canGrow = [self _realPositionForPosition:startPosition + 1 ofDividerAtIndex:i] > startPosition,
                cursor = [CPCursor arrowCursor];

            if (sizeA === 0)
                canGrow = YES; // Subview is collapsed.
            else if (!canShrink && [self _sendDelegateSplitViewCanCollapseSubview:_arrangedSubviews[i]])
                canShrink = YES; // Subview is collapsible.

            if (sizeB === 0)
                // Right/lower subview is collapsed.
                canGrow = NO;
            else if (!canGrow && [self _sendDelegateSplitViewCanCollapseSubview:_arrangedSubviews[i + 1]])
                canGrow = YES; // Right/lower subview is collapsible.

            if (_isVertical && canShrink && canGrow)
                cursor = [CPCursor resizeLeftRightCursor];
            else if (_isVertical && canShrink)
                cursor = [CPCursor resizeLeftCursor];
            else if (_isVertical && canGrow)
                cursor = [CPCursor resizeRightCursor];
            else if (canShrink && canGrow)
                cursor = [CPCursor resizeUpDownCursor];
            else if (canShrink)
                cursor = [CPCursor resizeUpCursor];
            else if (canGrow)
                cursor = [CPCursor resizeDownCursor];

            [cursor set];
            return;
        }
    }

    [[CPCursor arrowCursor] set];
}

/*!
    Returns the maximum possible position of a divider at a given index.
    @param the index of the divider.
    @return float - the max possible position.
*/
- (float)maxPossiblePositionOfDividerAtIndex:(int)dividerIndex
{
    var frame = [_arrangedSubviews[dividerIndex + 1] frame];

    if (dividerIndex + 1 < [_arrangedSubviews count] - 1)
        return frame.origin[_originComponent] + frame.size[_sizeComponent] - [self dividerThickness];
    else
        return [self frame].size[_sizeComponent] - [self dividerThickness];
}

/*!
    Returns the minimum possible position of a divider at a given index.
    @param the index of the divider.
    @return float - the min possible position.
*/
- (float)minPossiblePositionOfDividerAtIndex:(int)dividerIndex
{
    if (dividerIndex > 0)
    {
        var frame = [_arrangedSubviews[dividerIndex - 1] frame];

        return frame.origin[_originComponent] + frame.size[_sizeComponent] + [self dividerThickness];
    }
    else
        return 0;
}

- (int)_realPositionForPosition:(float)position ofDividerAtIndex:(int)dividerIndex
{
    // not sure where this should override other positions?
    var proposedPosition = [self _sendDelegateSplitViewConstrainSplitPosition:position ofSubviewAt:dividerIndex];

    // Silently ignore bad positions which could result from odd delegate responses. We don't want these
    // bad results to go into the system and cause havoc with frame sizes as the split view tries to resize
    // its subviews.
    if (_IS_NUMERIC(proposedPosition))
        position = proposedPosition;

    var proposedMax = [self maxPossiblePositionOfDividerAtIndex:dividerIndex],
        proposedMin = [self minPossiblePositionOfDividerAtIndex:dividerIndex],
        actualMax = proposedMax,
        actualMin = proposedMin,
        proposedActualMin = [self _sendDelegateSplitViewConstrainMinCoordinate:proposedMin ofSubviewAt:dividerIndex],
        proposedActualMax = [self _sendDelegateSplitViewConstrainMaxCoordinate:proposedMax ofSubviewAt:dividerIndex];

    if (_IS_NUMERIC(proposedActualMin))
        actualMin = proposedActualMin;

    if (_IS_NUMERIC(proposedActualMax))
        actualMax = proposedActualMax;

    var viewA = _arrangedSubviews[dividerIndex],
        viewB = _arrangedSubviews[dividerIndex + 1],
        realPosition = MAX(MIN(position, actualMax), actualMin);

    // Is this position past the halfway point to collapse?
    if ((position < proposedMin + (actualMin - proposedMin) / 2) && [self _sendDelegateSplitViewCanCollapseSubview:viewA])
        realPosition = proposedMin;

    // We can also collapse to the right.
    if ((position > proposedMax - (proposedMax - actualMax) / 2) && [self _sendDelegateSplitViewCanCollapseSubview:viewB])
        realPosition = proposedMax;

    return realPosition;
}

/*!
    Sets the position of a divider at a given index.
    @param position - The float value of the position to place the divider.
    @param dividerIndex - The index of the divider to position.
*/
- (void)setPosition:(float)position ofDividerAtIndex:(int)dividerIndex
{
    // Any manual changes to the divider position should override anything we are restoring from
    // autosave.
    _shouldRestoreFromAutosaveUnlessFrameSize = nil;

    SPLIT_VIEW_SUPPRESS_RESIZE_NOTIFICATIONS(YES);

    var realPosition = [self _realPositionForPosition:position ofDividerAtIndex:dividerIndex],
        viewA = _arrangedSubviews[dividerIndex],
        frameA = [viewA frame],
        viewB = _arrangedSubviews[dividerIndex + 1],
        frameB = [viewB frame],
        preCollapsePosition = 0,
        preSize = frameA.size[_sizeComponent];

    frameA.size[_sizeComponent] = realPosition - frameA.origin[_originComponent];

    if (preSize !== 0 && frameA.size[_sizeComponent] === 0)
        preCollapsePosition = preSize;

    if (preSize !== frameA.size[_sizeComponent])
    {
        SPLIT_VIEW_MAYBE_POST_WILL_RESIZE();
        [_arrangedSubviews[dividerIndex] setFrame:frameA];
        SPLIT_VIEW_MAYBE_POST_DID_RESIZE();
    }

    preSize = frameB.size[_sizeComponent];

    var preOrigin = frameB.origin[_originComponent];
    frameB.size[_sizeComponent] = frameB.origin[_originComponent] + frameB.size[_sizeComponent] - realPosition - [self dividerThickness];

    if (preSize !== 0 && frameB.size[_sizeComponent] === 0)
        preCollapsePosition = frameB.origin[_originComponent];

    frameB.origin[_originComponent] = realPosition + [self dividerThickness];

    if (preSize !== frameB.size[_sizeComponent] || preOrigin !== frameB.origin[_originComponent])
    {
        SPLIT_VIEW_MAYBE_POST_WILL_RESIZE();
        [_arrangedSubviews[dividerIndex + 1] setFrame:frameB];
        SPLIT_VIEW_MAYBE_POST_DID_RESIZE();
    }

    if (preCollapsePosition)
        [_preCollapsePositions setObject:preCollapsePosition forKey:"" + dividerIndex];

    // Update the divider position
    var dividerOrigin = [_dividerSubviews[dividerIndex] frameOrigin];
    dividerOrigin[_originComponent] = realPosition;
    [_dividerSubviews[dividerIndex] setFrameOrigin:dividerOrigin];

    [self _updateRatios];

    if (SPLIT_VIEW_DID_SUPPRESS_RESIZE_NOTIFICATION())
        [self _postNotificationDidResize];

    SPLIT_VIEW_SUPPRESS_RESIZE_NOTIFICATIONS(NO);
}

/*!
    Set the button bar who's resize control should act as a control for this splitview.
    Each divider can have at most one button bar assigned to it, and that button bar must be
    a subview of one of the split view's subviews.

    Calling this method with nil as the button bar will remove any currently assigned button bar
    for the divider at that index. Indexes will not be adjusted as new subviews are added, so you
    should usually call this method after adding all the desired subviews to the split view.

    This method will automatically configure the hasResizeControl and resizeControlIsLeftAligned
    parameters of the button bar, and will override any currently set values.

    @param CPButtonBar - The supplied button bar.
    @param unsigned int - The divider index the button bar will be assigned to.
*/
// FIXME Should be renamed to setButtonBar:ofDividerAtIndex:.
- (void)setButtonBar:(CPButtonBar)aButtonBar forDividerAtIndex:(CPUInteger)dividerIndex
{
    // For compatibility with previous behavior
    [aButtonBar setAutomaticResizeControl:YES];
    [self attachButtonBar:aButtonBar];
}

- (void)attachButtonBar:(CPButtonBar)aButtonBar
{
    // Search the subview containing the button bar
    var view    = [aButtonBar superview],
        subview = aButtonBar;

    while (view && (view !== self))
    {
        subview = view;
        view    = [view superview];
    }

    if (view !== self)
        [CPException raise:CPInvalidArgumentException
                    reason:@"CPSplitView button bar must be a subview of the split view."];

    // ATTENTION !
    // If the button bar is created via IB, at this moment, the split view may not be ready : subviews are OK but
    // not arrangedSubviews. We can then assume that all subviews will be arranged subviews (as subviews declared
    // in IB are, in fact, arranged subviews).
    // BUT if the split view is ready, when must work on arranged subviews.
    //
    // To determine if the split view is ready, we have to make an hypothesis :
    //      if the number of subviews > 0 and the number of arranged subviews = 0, then the split view is not ready
    //
    // This hypothesis could be false if the split view doesn't arrange all subviews and if all subviews are not
    // arranged subviews. BUT this would mean that the split view has no real panes. And this should never happen
    // in real life.

    var arrangedSubviews      = [self arrangedSubviews],
        arrangedSubviewsCount = [arrangedSubviews count],
        subviews              = [self subviews],
        subviewsCount         = [subviews count],
        splitViewIsNotReady   = (subviewsCount > 0) && (arrangedSubviewsCount == 0),
        viewIndex             = [(splitViewIsNotReady ? subviews : arrangedSubviews) indexOfObject:subview];

    _buttonBars[viewIndex] = aButtonBar;

    // If needed, add resize control(s)
    if ([aButtonBar automaticResizeControl])
    {
        [aButtonBar setHasLeftResizeControl:(viewIndex > 0)];
        [aButtonBar setHasRightResizeControl:(viewIndex < (splitViewIsNotReady ? subviewsCount : arrangedSubviewsCount) - 1)];
    }
}

- (void)_postNotificationWillResize
{
    [self _sendDelegateSplitViewWillResizeSubviews];
}

- (void)_postNotificationDidResize
{
    [self _sendDelegateSplitViewDidResizeSubviews];

    // TODO Cocoa always autosaves on "viewDidEndLiveResize". If Cappuccino adds support for this we
    // should do the same.
    [self _autosave];
}

/*!
    Set the name under which the split view divider positions is automatically saved to CPUserDefaults.

    @param autosaveName the name to save under or nil to not save
*/
- (void)setAutosaveName:(CPString)autosaveName
{
    if (_autosaveName == autosaveName)
        return;

    _autosaveName = autosaveName;
}

/*!
    Get the name under which the split view divider position is automatically saved to CPUserDefaults.

    @return the name to save under or nil if no autosave is active
*/
- (CPString)autosaveName
{
    return _autosaveName;
}

/*!
    @ignore
*/
- (void)_autosave
{
    if (_shouldRestoreFromAutosaveUnlessFrameSize || !_shouldAutosave || !_autosaveName)
        return;

    var userDefaults = [CPUserDefaults standardUserDefaults],
        autosaveName = [self _framesKeyForAutosaveName:[self autosaveName]],
        autosavePrecollapseName = [self _precollapseKeyForAutosaveName:[self autosaveName]],
        count = [_arrangedSubviews count],
        positions = [CPMutableArray new],
        preCollapseArray = [CPMutableArray new];

    for (var i = 0; i < count; i++)
    {
        var frame = [_arrangedSubviews[i] frame];
        [positions addObject:CGStringFromRect(frame)];
        [preCollapseArray addObject:[_preCollapsePositions objectForKey:"" + i]];
    }

    [userDefaults setObject:positions forKey:autosaveName];
    [userDefaults setObject:preCollapseArray forKey:autosavePrecollapseName];
}

/*!
    @ignore
*/
- (void)_restoreFromAutosave
{
    if (!_autosaveName)
        return;

    var autosaveName = [self _framesKeyForAutosaveName:[self autosaveName]],
        autosavePrecollapseName = [self _precollapseKeyForAutosaveName:[self autosaveName]],
        userDefaults = [CPUserDefaults standardUserDefaults],
        frames = [userDefaults objectForKey:autosaveName],
        preCollapseArray = [userDefaults objectForKey:autosavePrecollapseName];

    if (frames)
    {
        var dividerThickness = [self dividerThickness],
            position = 0;

        _shouldAutosave = NO;

        // We adapt here only the "other" size (that is height for a vertical split view / width for an horizontal split view)
        // The complicated size will be treated in adjustSubviews

        var myOtherSize = [self frame].size[_otherSizeComponent];

        for (var i = 0, count = _arrangedSubviews.length, frame; i < count; i++)
        {
            frame = CGRectFromString(frames[i]);

            frame.size[_otherSizeComponent] = myOtherSize;

            [_arrangedSubviews[i] setFrame:frame];
        }

        for (var i = 0, count = _dividerSubviews.length, size; i < count; i++)
        {
            size = CGSizeMakeCopy([_dividerSubviews[i] frameSize]);

            size[_otherSizeComponent] = myOtherSize;

            [_dividerSubviews[i] setFrameSize:size];
        }

        _shouldAutosave = YES;
    }

    if (preCollapseArray)
    {
        _preCollapsePositions = [CPMutableDictionary new];

        for (var i = 0, count = [preCollapseArray count]; i < count; i++)
        {
            var item = preCollapseArray[i];

            if (item == nil)
                [_preCollapsePositions removeObjectForKey:String(i)];
            else
                [_preCollapsePositions setObject:item forKey:String(i)];
        }
    }
}

/*!
    @ignore
*/
- (CPString)_framesKeyForAutosaveName:(CPString)theAutosaveName
{
    if (!theAutosaveName)
        return nil;

    return @"CPSplitView Subview Frames " + theAutosaveName;
}

/*!
    @ignore
*/
- (CPString)_precollapseKeyForAutosaveName:(CPString)theAutosaveName
{
    if (!theAutosaveName)
        return nil;

    return @"CPSplitView Subview Precollapse Positions " + theAutosaveName;
}

@end

#pragma mark -

@implementation CPSplitView (CPTrackingArea)
{
    CPMutableArray  _splitViewTrackingAreas;
    CPMutableArray  _splitViewResizeControlTrackingAreas;
}

- (void)updateTrackingAreas
{
    if (_splitViewTrackingAreas)
    {
        for (var i = 0, count = _splitViewTrackingAreas.length; i < count; i++)
            [self removeTrackingArea:_splitViewTrackingAreas[i]];

        _splitViewTrackingAreas = nil;
    }

    if (_splitViewResizeControlTrackingAreas)
    {
        for (var i = 0, count = _splitViewResizeControlTrackingAreas.length; i < count; i++)
            [self removeTrackingArea:_splitViewResizeControlTrackingAreas[i]];

        _splitViewResizeControlTrackingAreas = nil;
    }

    var options = CPTrackingCursorUpdate | CPTrackingActiveInKeyWindow;

    _splitViewTrackingAreas = @[];
    _splitViewResizeControlTrackingAreas = @[];

    // Seems to be needed when compiling themes
    if (_dividerSubviews)
    {
        for (var i = 0, count = _dividerSubviews.length; i < count; i++)
        {
            [_splitViewTrackingAreas addObject:[[CPTrackingArea alloc] initWithRect:[self effectiveRectOfDividerAtIndex:i]
                                                                            options:options
                                                                              owner:self
                                                                           userInfo:nil]];

            [self addTrackingArea:_splitViewTrackingAreas[i]];
        }

        for (var i = 0, count = _arrangedSubviews.length; i < count; i++)
        {
            if ([_buttonBars[i] hasLeftResizeControl])
            {
                var trackingArea = [[CPTrackingArea alloc] initWithRect:[self convertRect:[_buttonBars[i] leftResizeControlFrame] fromView:_buttonBars[i]]
                                                                options:options
                                                                  owner:self
                                                               userInfo:nil];

                [_splitViewResizeControlTrackingAreas addObject:trackingArea];
                [self addTrackingArea:trackingArea];
            }

            if ([_buttonBars[i] hasRightResizeControl])
            {
                var trackingArea = [[CPTrackingArea alloc] initWithRect:[self convertRect:[_buttonBars[i] rightResizeControlFrame] fromView:_buttonBars[i]]
                                                                options:options
                                                                  owner:self
                                                               userInfo:nil];

                [_splitViewResizeControlTrackingAreas addObject:trackingArea];
                [self addTrackingArea:trackingArea];
            }
        }
    }

    [super updateTrackingAreas];
}

- (void)cursorUpdate:(CPEvent)anEvent
{
    [self _updateResizeCursor:anEvent];
}

@end

#pragma mark -

@implementation CPSplitView (CPSplitViewDelegate)

/*!
    @ignore
    Return YES if the delegate implements splitView:resizeSubviewsWithOldSize:
*/
- (BOOL)_delegateRespondsToSplitViewResizeSubviewsWithOldSize
{
    return _implementedDelegateMethods & CPSplitViewDelegate_splitView_resizeSubviewsWithOldSize_;
}

/*!
    @ignore
    Return YES if the delegate implements splitView:canCollapseSubview:
*/
- (BOOL)_delegateRespondsToSplitViewCanCollapseSubview
{
    return _implementedDelegateMethods & CPSplitViewDelegate_splitView_canCollapseSubview_;
}

/*!
    @ignore
    Return YES if the delegate implements splitView:shouldCollapseSubview:forDoubleClickOnDividerAtIndex
*/
- (BOOL)_delegateRespondsToSplitViewshouldCollapseSubviewForDoubleClickOnDividerAtIndex
{
    return _implementedDelegateMethods & CPSplitViewDelegate_splitView_shouldCollapseSubview_forDoubleClickOnDividerAtIndex_;
}


/*!
    @ignore
    Call the delegate splitView:canCollapseSubview:
*/
- (BOOL)_sendDelegateSplitViewCanCollapseSubview:(CPView)aView
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_canCollapseSubview_))
        return NO;

    return [_delegate splitView:self canCollapseSubview:aView];
}

/*!
    @ignore
    Call the delegate splitView:shouldAdjustSizeOfSubview:
*/
- (BOOL)_sendDelegateSplitViewShouldAdjustSizeOfSubview:(CPView)aView
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_shouldAdjustSizeOfSubview_))
        return YES;

    return [_delegate splitView:self shouldAdjustSizeOfSubview:aView];
}

/*!
    @ignore
    Call the delegate splitView:shouldCollapseSubview:forDoubleClickOnDividerAtIndex:
*/
- (BOOL)_sendDelegateSplitViewShouldCollapseSubview:(CPView)aView forDoubleClickOnDividerAtIndex:(int)anIndex
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_shouldCollapseSubview_forDoubleClickOnDividerAtIndex_))
        return NO;

    return [_delegate splitView:self shouldCollapseSubview:aView forDoubleClickOnDividerAtIndex:anIndex];
}

/*!
    @ignore
    Call the delegate splitView:additionalEffectiveRectOfDividerAtIndex:
*/
- (CGRect)_sendDelegateSplitViewAdditionalEffectiveRectOfDividerAtIndex:(int)anIndex
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_additionalEffectiveRectOfDividerAtIndex_))
        return nil;

    return [_delegate splitView:self additionalEffectiveRectOfDividerAtIndex:anIndex];
}

/*!
    @ignore
    Call the delegate splitView:effectiveRect:forDrawnRect:ofDividerAtIndex:
*/
- (CGRect)_sendDelegateSplitViewEffectiveRect:(CGRect)proposedEffectiveRect forDrawnRect:(CGRect)drawnRect ofDividerAtIndex:(CPInteger)dividerIndex
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_effectiveRect_forDrawnRect_ofDividerAtIndex_))
        return proposedEffectiveRect;

    return [_delegate splitView:self effectiveRect:proposedEffectiveRect forDrawnRect:drawnRect ofDividerAtIndex:dividerIndex];
}

/*!
    @ignore
    Call the delegate splitView:constrainMaxCoordinate:ofSubviewAt:
*/
- (float)_sendDelegateSplitViewConstrainMaxCoordinate:(float)proposedMax ofSubviewAt:(CPInteger)dividerIndex
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_constrainMaxCoordinate_ofSubviewAt_))
        return nil;

    return [_delegate splitView:self constrainMaxCoordinate:proposedMax ofSubviewAt:dividerIndex];
}

/*!
    @ignore
    Call the delegate splitView:constrainMinCoordinate:ofSubviewAt:
*/
- (float)_sendDelegateSplitViewConstrainMinCoordinate:(float)proposedMin ofSubviewAt:(CPInteger)dividerIndex
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_constrainMinCoordinate_ofSubviewAt_))
        return nil;

    return [_delegate splitView:self constrainMinCoordinate:proposedMin ofSubviewAt:dividerIndex];
}

/*!
    @ignore
    Call the delegate splitView:constrainSplitPosition:ofSubviewAt:
*/
- (float)_sendDelegateSplitViewConstrainSplitPosition:(float)proposedMax ofSubviewAt:(CPInteger)dividerIndex
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_constrainSplitPosition_ofSubviewAt_))
        return nil;

    return [_delegate splitView:self constrainSplitPosition:proposedMax ofSubviewAt:dividerIndex];
}

/*!
    @ignore
    Call the delegate splitView:resizeSubviewsWithOldSize:
*/
- (void)_sendDelegateSplitViewResizeSubviewsWithOldSize:(CGSize)oldSize
{
    if (!(_implementedDelegateMethods & CPSplitViewDelegate_splitView_resizeSubviewsWithOldSize_))
        return;

    [_delegate splitView:self resizeSubviewsWithOldSize:oldSize];
}

/*!
    @ignore
    Call the delegate splitViewWillResizeSubviews:
*/
- (void)_sendDelegateSplitViewWillResizeSubviews
{
    var userInfo = nil;

    if (_currentDivider !== CPNotFound)
        userInfo = @{ @"CPSplitViewDividerIndex": _currentDivider };

    if (_implementedDelegateMethods & CPSplitViewDelegate_splitViewWillResizeSubviews_)
        [_delegate splitViewWillResizeSubviews:[[CPNotification alloc] initWithName:CPSplitViewWillResizeSubviewsNotification object:self userInfo:userInfo]];

    [[CPNotificationCenter defaultCenter] postNotificationName:CPSplitViewWillResizeSubviewsNotification object:self userInfo:userInfo];
}

/*!
    @ignore
    Call the delegate splitViewDidResizeSubviews:
*/
- (void)_sendDelegateSplitViewDidResizeSubviews
{
    var userInfo = nil;

    if (_currentDivider !== CPNotFound)
        userInfo = @{ @"CPSplitViewDividerIndex": _currentDivider };

    if (_implementedDelegateMethods & CPSplitViewDelegate_splitViewDidResizeSubviews_)
        [_delegate splitViewDidResizeSubviews:[[CPNotification alloc] initWithName:CPSplitViewDidResizeSubviewsNotification object:self userInfo:userInfo]];

    [[CPNotificationCenter defaultCenter] postNotificationName:CPSplitViewDidResizeSubviewsNotification object:self userInfo:userInfo];

    [self updateTrackingAreas];
}

@end

#pragma mark -

var CPSplitViewDelegateKey            = @"CPSplitViewDelegateKey",
    CPSplitViewIsVerticalKey          = @"CPSplitViewIsVerticalKey",
    CPSplitViewIsPaneSplitterKey      = @"CPSplitViewIsPaneSplitterKey",
    CPSplitViewButtonBarsKey          = @"CPSplitViewButtonBarsKey",
    CPSplitViewAutosaveNameKey        = @"CPSplitViewAutosaveNameKey",
    CPSplitViewDividerStyleKey        = @"CPSplitViewDividerStyleKey",
    CPSplitViewDividerSubviewsKey     = @"CPSplitViewDividerSubviewsKey",
    CPSplitViewArrangedSubviewsKey    = @"CPSplitViewArrangedSubviewsKey",
    CPSplitViewArrangesAllSubviewsKey = @"CPSplitViewArrangesAllSubviewsKey",
    CPSplitViewRealSubviewsKey        = @"CPSplitViewRealSubviewsKey";

@implementation CPSplitView (CPCoding)

/*
    Initializes the split view by unarchiving data from \c aCoder.
    @param aCoder the coder containing the archived CPSplitView.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    // We need to restore this property before calling super's initWithCoder:.
    _autosaveName = [aCoder decodeObjectForKey:CPSplitViewAutosaveNameKey];

    /*

    It is common for the main window of a Cappuccino app window to be resized to match the browser
    window size at the end of the UI being loaded from a cib. But at decoding time (now) whatever
    window size was originally saved will be in place, so if we try to restore the autosaved divider
    positions now they might be constrained to the wrong positions due to the difference in frame size,
    and in addition they might move later when the window is resized.

    The workaround is to restore the position once now (so it's approximately correct during loading),
    and then once more in the next runloop cycle when any `setFullPlatformWindow` calls are done.

    (However if the frame size doesn't change before the next cycle, we should not restore the position
    again because that would overwrite any changes the app developer might have made in user code.)

    The other consideration is that any parent split views need to be restored before any child
    subviews, otherwise the parent restore will also change the positioning of the child.

    */

    // As subviews are often not fully ready to use at this time, we'll try to finalize the
    // initialization after all views initializations are done, in _cibInstantiate.

    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self _init];

        _suppressResizeNotificationsMask = 0;
        _preCollapsePositions = [CPMutableDictionary new];

        _currentDivider = CPNotFound;
        _shouldAutosave = NO;
        _isTracking = NO;

        _buttonBars = [aCoder decodeObjectForKey:CPSplitViewButtonBarsKey] || @[];

        [self setDelegate:[aCoder decodeObjectForKey:CPSplitViewDelegateKey]];

        [self _setVertical:[aCoder decodeBoolForKey:CPSplitViewIsVerticalKey]];

        _dividerSubviews  = [aCoder decodeObjectForKey:CPSplitViewDividerSubviewsKey]  || @[];
        _arrangedSubviews = [aCoder decodeObjectForKey:CPSplitViewArrangedSubviewsKey] || @[];
        _realSubviews     = [aCoder decodeObjectForKey:CPSplitViewRealSubviewsKey]     || @[];

        [self setArrangesAllSubviews:[aCoder decodeBoolForKey:CPSplitViewArrangesAllSubviewsKey]];
        [self setDividerStyle:[aCoder decodeIntForKey:CPSplitViewDividerStyleKey]];

        _isCSSBased = [[self theme] isCSSBased];

        // Final operations will be performed in _finalizeInitWithCoder
    }

    return self;
}

- (id)_cibInstantiate
{
    // Subviews received from Xcode IB are in fact arranged subviews

    _subviewsManagementDisabled = YES;

    for (var i = 0, subviews = [self subviews], count = subviews.length; i < count; i++)
        [self _addArrangedSubview:subviews[i]];

    _subviewsManagementDisabled = NO;
    _shouldAutosave = YES;

    if (_autosaveName)
        [self _restoreFromAutosave];

    [self _updateRatios];
    [self adjustSubviews];

    return self;
}

/*
    Archives this split view into the provided coder.
    @param aCoder the coder to which the button's instance data will be written.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    //FIXME how should we handle this?
    //[aCoder encodeObject:_buttonBars forKey:CPSplitViewButtonBarsKey];

    [aCoder encodeConditionalObject:_delegate forKey:CPSplitViewDelegateKey];

    [aCoder encodeBool:  _isVertical          forKey:CPSplitViewIsVerticalKey];
    [aCoder encodeInt:   _dividerStyle        forKey:CPSplitViewDividerStyleKey];
    [aCoder encodeObject:_dividerSubviews     forKey:CPSplitViewDividerSubviewsKey];
    [aCoder encodeObject:_arrangedSubviews    forKey:CPSplitViewArrangedSubviewsKey];
    [aCoder encodeObject:_realSubviews        forKey:CPSplitViewRealSubviewsKey];
    [aCoder encodeBool:  _arrangesAllSubviews forKey:CPSplitViewArrangesAllSubviewsKey];
    [aCoder encodeObject:_autosaveName        forKey:CPSplitViewAutosaveNameKey];
}

@end

#pragma mark -

@implementation CPSplitView (Deprecated)

/*!
 Use to find if the divider is a larger pane splitter.

 @return BOOL - YES if the dividers are the larger pane splitters. Otherwise NO.
 */
- (BOOL)isPaneSplitter
{
    CPLog.warn("isPaneSplitter is now deprecated. Use dividerStyle instead.");

    return (_dividerStyle === CPSplitViewDividerStylePaneSplitter);
}

/*!
 Used to set if the split view dividers should be the larger pane splitter.

 @param shouldBePaneSplitter - YES if the dividers should be the thicker pane splitter, otherwise NO.
 */
- (void)setIsPaneSplitter:(BOOL)shouldBePaneSplitter
{
    CPLog.warn("setIsPaneSplitter is now deprecated. Use setDividerStyle instead.");

    [self setDividerStyle:(shouldBePaneSplitter ? CPSplitViewDividerStylePaneSplitter : CPSplitViewDividerStyleThin)];
}

@end

