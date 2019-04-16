/*
 * CPSplitView.j
 * AppKit
 *
 * Created by Thomas Robinson.
 * Copyright 2008, 280 North, Inc.
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
//        In order to maintain compatibility, the new implementation (based on CSS theming) lives in parallel with the previous one.
//        When, in the future, we will have decided to remove image based themes compatibility, please clean the code.
//        New code is generally protected with _isCSSBased.
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
    BOOL                        _isPaneSplitter;

    int                         _currentDivider;
    float                       _initialOffset;
    CPDictionary                _preCollapsePositions;

    CPString                    _originComponent;
    CPString                    _sizeComponent;

    CPArray                     _DOMDividerElements;
    CPString                    _dividerImagePath;
    int                         _drawingDivider;
    BOOL                        _isTracking;

    CPString                    _autosaveName;
    BOOL                        _shouldAutosave;
    CGSize                      _shouldRestoreFromAutosaveUnlessFrameSize;

    BOOL                        _needsResizeSubviews;
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

    //        _DOMDividerElements = [];
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

    [self setNeedsLayout];
}

- (CPColor)dividerColor
{
    if (_isCSSBased)
        return [self currentValueForThemeAttribute:@"divider-color"];

    // For compatibility with Aristo2
    if ([self isPaneSplitter])
        return [self currentValueForThemeAttribute:@"pane-divider-color"];

    return [self currentValueForThemeAttribute:(_isVertical ? @"vertical-divider-color" : @"horizontal-divider-color")];
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
    return [self currentValueForThemeAttribute:[self isPaneSplitter] ? @"pane-divider-thickness" : @"divider-thickness"];
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
    // FIXME: revoir
    if (![self _setVertical:shouldBeVertical])
        return;

    // Just re-adjust evenly.
    var frame = [self frame],
        dividerThickness = [self dividerThickness];

    [self _postNotificationWillResize];

    var eachSize = ROUND((frame.size[_sizeComponent] - dividerThickness * (_subviews.length - 1)) / _subviews.length),
        index = 0,
        count = _subviews.length;

    if (_isVertical)
    {
        for (; index < count; ++index)
            [_subviews[index] setFrame:CGRectMake(ROUND((eachSize + dividerThickness) * index), 0, eachSize, frame.size.height)];
    }
    else
    {
        for (; index < count; ++index)
            [_subviews[index] setFrame:CGRectMake(0, ROUND((eachSize + dividerThickness) * index), frame.size.width, eachSize)];
    }

//    if (_DOMDividerElements[_drawingDivider])
//        [self _setupDOMDivider];

    [self setNeedsDisplay:YES];
    [self _postNotificationDidResize];

}

- (BOOL)_setVertical:(BOOL)shouldBeVertical
{
    var changed = (_isVertical != shouldBeVertical);

    _isVertical = shouldBeVertical;

    _originComponent = _isVertical ? "x" : "y";
    _sizeComponent = _isVertical ? "width" : "height";
//    _dividerImagePath = _isVertical ? [[self valueForThemeAttribute:@"vertical-divider-color"] filename] : [[self valueForThemeAttribute:@"horizontal-divider-color"] filename];

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

    [self setNeedsLayout];
}

#pragma mark - Subviews management

// TODO: adapter le commentaire ci-dessous !!!
// Cocoa behavior:
// - When adding an arranged subview :
//   - the resulting sizes of arranged subviews are computed like this (here for vertical dividers) :
//     - existing total width (ETW) = sum of the widths of existing arranged subviews
//     - new view width (NVW)
//     - ETW ratio : ETWr = ETW / (ETW + NVW)
//     - NVW ratio : NVWr = NVW / (ETW + NVW)
//     - usable width UW = view width - number of dividers * divider thickness
//     - final NVW : fNVW = UW * NVWr
//     - final ETW : fETW = UW * ETWr
//     - fETW is distributed to existing arranged subviews keeping the relative ratios
//   - BUT it tries to respect non resizable instructions given by the delegate (if possible). If not possible, it tries
//     to shrink evenly all fixed size subviews (after having collapsed all flexible subviews).
//     Remark : when a fixed size subview has been shrinked, as it is marked as fixed, it won't grow back to its original size !
//
// - When removing an arranged subview :
//   - The removed arranged subview remains a subview (!) keeping its size and position at the moment of the removal
//   - The proportions of remaining arranged subviews are maintained

- (CPArray)arrangedSubviews
{
    return [_arrangedSubviews copy];
}

- (void)addArrangedSubview:(CPView)view
{
    _subviewsManagementDisabled = YES;

    // TODO: Cocoa :
    // - quand on fait un addArranged -> il fait aussi un addSubview
    // - quand pas arranges all subviews, quand on fait un addSubview -> ne fait pas un addArranged
    // - quand arranges all subviews, quand on fait un addSubview -> fait un addArranged

    [self _addArrangedSubview:view];
    [self addSubview:view];

    _subviewsManagementDisabled = NO;
//    _needsResizeSubviews        = YES;
}

- (void)_addArrangedSubview:(CPView)view
{
    // First, compute some geometry

    var thickness     = [self currentValueForThemeAttribute:@"divider-thickness"],
        newViewFrame  = [view frame],
        myFrame       = [self frame],
        flexibleSpace = 0,
        flexibleCount = 0,
        fixedSpace    = 0,
        fixedCount    = 0;

    // We have to reinitialize this cache as flexibility can change over time (determined by the delegate)
    _isFlexible = @[];

    // We temporarily set the size of the new arranged subview
    var size = CGSizeMakeCopy(myFrame.size);
    size[_sizeComponent] = newViewFrame.size[_sizeComponent];
    [view setFrameSize:size];

    [_arrangedSubviews addObject:view];
    [_realSubviews     addObject:view];
    [_initialSizes     addObject:newViewFrame.size[_sizeComponent]];
    [_ratios           addObject:0];

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

    for (var i = 0, count = _arrangedSubviews.length; i < count; i++)
        if (_isFlexible[i])
            [_ratios replaceObjectAtIndex:i withObject:(_initialSizes[i] / flexibleSpace)];
        else
            [_ratios replaceObjectAtIndex:i withObject:(_initialSizes[i] / fixedSpace)];

    // If we have more than one arranged subview, then we have to add a divider
    if (_arrangedSubviews.length > 1)
    {
        var dividerFrame = CGRectMakeZero();

        dividerFrame.size                 = CGSizeMakeCopy(myFrame.size);
        dividerFrame.size[_sizeComponent] = thickness;

        var divider = [[CPView alloc] initWithFrame:dividerFrame];

        [divider setBackgroundColor:[self currentValueForThemeAttribute:@"divider-color"]];

        [_dividerSubviews addObject:divider];
        [super            addSubview:divider];
    }

    //    if (newFixedSpace < usableSpace)
    //    {
    //        // We have enough space
    //        [self _adaptArrangedSubviewsFromIndex:0 toIndex:_arrangedSubviews.length-1 toFitSize:usableSpace withFixedSize:newFixedSpace];
    //        CPLog.trace("Case 1");
    //    }
    //    else
    //    {
    //        // We don't have enough space
    //        // FIXME: ne pas oublier de changer les initiales des fixed quand on les réduit (pas agrandit)
    //        CPLog.trace("Case 2");
    //    }

    //    [self _adaptArrangedSubviewsFromIndex:0 toIndex:_arrangedSubviews.length-1 toFitSize:usableSpace withFixedSize:newFixedSpace];

    [_realSubviews addObject:view];

    _needsResizeSubviews        = YES;

    //    [self setNeedsLayout];
    [self adjustSubviews];
    [self _layoutSubviews];
}

- (void)insertArrangedSubview:(CPView)view atIndex:(CPInteger)index
{
    // TODO: here
    // pas oublier de mettre dans les subviews
    // + gérer les dividers
}

- (void)removeArrangedSubview:(CPView)view
{
    // TODO: here
    // pas oublier de retirer dans les subviews
    // + gérer les dividers
}

- (void)addSubview:(CPView)aSubview
{
    // TODO: Cocoa : si on fait un addSubview ET si on a arrangesAllSubviews -> on doit aussi faire un addArrangedSubviews (mais sans appeler à nouveau addSubview)

    [super addSubview:aSubview];

    if (_subviewsManagementDisabled)
        return;

    // FIXME : si on a arrangesAllSubviews, on doit mettre la subview dans les arrangedSubviews ; sinon, on prévient temporairement qu'il faut peut-être utiliser l'autre

    if (_arrangesAllSubviews)
        [self _addArrangedSubview:aSubview];

    _needsResizeSubviews = YES;
}

- (void)didAddSubview:(CPView)aSubview
{
    // FIXME: ajouter ici une subview pour divider (puisqu'on vient d'ajouter une subview)
    // Peut-être conserver un tableau des vraies subviews en + de celui des dividers

//    if (aSubview === _newDividerView)
//    {
//        _newDividerView = nil;
//        return;
//    }

//    _newDividerView = [[CPView alloc] initWithFrame:CGRectMake(XXX,XXX,XXX,XXX)];

    if (_subviewsManagementDisabled)
        return;

    _needsResizeSubviews = YES;
}

- (void)willRemoveSubview:(CPView)aView
{
    // FIXME: si arrangesAllSubviews, retirer aussi des arrangedSubviews ; sinon prévenir
    // FIXME: retirer un divider

//#if PLATFORM(DOM)
//    var dividerToRemove = _DOMDividerElements.pop();
//
//    // The divider may not exist if we never rendered out the DOM.
//    if (dividerToRemove)
//        CPDOMDisplayServerRemoveChild(_DOMElement, dividerToRemove);
//#endif

    _needsResizeSubviews = YES;
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

#pragma mark - Layout subviews

- (CGRect)rectOfDividerAtIndex:(int)aDivider
{
    return [_dividerSubviews[aDivider] frame];

//    var frame = [_subviews[aDivider] frame],
//    rect = CGRectMakeZero();
//
//    rect.size = [self frame].size;
//    rect.size[_sizeComponent] = [self dividerThickness];
//    rect.origin[_originComponent] = frame.origin[_originComponent] + frame.size[_sizeComponent];
//
//    return rect;
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
    else
        [self _adjustSubviewsWithCalculatedSize];

    [super setFrameSize:aSize];

    if (_shouldRestoreFromAutosaveUnlessFrameSize)
        _shouldAutosave = YES;

    [self setNeedsDisplay:YES];

}

- (void)resizeSubviewsWithOldSize:(CGSize)oldSize
{
    if ([self _delegateRespondsToSplitViewResizeSubviewsWithOldSize])
    {
        [self _sendDelegateSplitViewResizeSubviewsWithOldSize:oldSize];
        return;
    }

//    [super resizeSubviewsWithOldSize:oldSize];

    // FIXME: utile ?
    [self adjustSubviews];
    [self _layoutSubviews];
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
    CPLog.trace("adjustSubviews");
//    - (void)_adaptArrangedSubviewsFromIndex:(CPInteger)fromIndex toIndex:(CPInteger)toIndex toFitSize:(CPInteger)sizeToFit withFixedSize:(CPInteger)fixedSize

    SPLIT_VIEW_MAYBE_POST_WILL_RESIZE();
    [self _postNotificationWillResize];

    // 2 possibilities : we have, or not, enough flexible space to accomodate fixed size subviews

    var sizeToFit  = [self frame].size[_sizeComponent] - _dividerSubviews.length * [self currentValueForThemeAttribute:@"divider-thickness"],
        fixedSize  = 0,
        nbSubviews = _arrangedSubviews.length;

    for (var i = 0, count = _arrangedSubviews.length; i < count; i++)
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

        // FIXME: here !

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


//    if (_isCSSBased)
//        return;
//
//    var count = [_subviews count];
//
//    if (!count)
//        return;
//
//    SPLIT_VIEW_MAYBE_POST_WILL_RESIZE();
//    [self _postNotificationWillResize];
//
//    var index = 0,
//        bounds = [self bounds],
//        boundsSize = bounds.size[_sizeComponent],
//        oldSize = [self _calculateSize],
//        dividerThickness = [self dividerThickness],
//        totalDividers = count - 1,
//        oldFlexibleSpace = 0,
//        totalSizablePanes = 0,
//        isSizableMap = {},
//        viewSizes = [];
//
//    // What we want to do is to preserve non resizable sizes first, and then to preserve the ratio of size to available
//    // non fixed space for every other subview. E.g. assume fixed space was 20 pixels initially, view 1 was 20 and
//    // view 2 was 30 pixels, for a total of 70 pixels. Then the new total size becomes 140 pixels. Now we want the fixed
//    // space to still be 20 pixels, view 1 to be 48 pixels and view 2 to be 72 pixels. This way the relative size of
//    // view 1 to view 2 remains the same - view 1 was 66% of view 2 initially and after the resize view 1 is still
//    // 66% of view 2's size.
//    //
//    // For this calculation, we can consider the dividers themselves to also be fixed size areas - they should remain
//    // the same size before and after.
//
//    // How much flexible size do we have in pre-resize pixels?
//    for (index = 0; index < count; ++index)
//    {
//        var view = _subviews[index],
//        isSizable = [self _sendDelegateSplitViewShouldAdjustSizeOfSubview:view],
//        size = [view frame].size[_sizeComponent];
//
//        isSizableMap[index] = isSizable;
//        viewSizes.push(size);
//
//        if (isSizable)
//        {
//            oldFlexibleSpace += size;
//            totalSizablePanes++;
//        }
//    }
//
//    // nonSizableSpace is the number of fixed pixels in pre-resize terms and the desired number post-resize.
//    var nonSizableSpace = oldSize[_sizeComponent] - oldFlexibleSpace,
//        newFlexibleSpace = boundsSize - nonSizableSpace,
//        remainingFixedPixelsToRemove = 0;
//
//    if (newFlexibleSpace < 0)
//    {
//        remainingFixedPixelsToRemove = -newFlexibleSpace;
//        newFlexibleSpace = 0;
//    }
//
//    var remainingFixedPanes = count - totalSizablePanes;
//
//    for (index = 0; index < count; ++index)
//    {
//        var view = _subviews[index],
//            viewFrame = CGRectMakeCopy(bounds),
//            isSizable = isSizableMap[index],
//            targetSize = 0;
//
//        // The last area must take up exactly the remaining space, fixed or not.
//        if (index + 1 === count)
//            targetSize = boundsSize - viewFrame.origin[_originComponent];
//        // Try to keep fixed size areas the same size.
//        else if (!isSizable)
//        {
//            var removedFixedPixels = MIN(remainingFixedPixelsToRemove / remainingFixedPanes, viewSizes[index]);
//            targetSize = viewSizes[index] - removedFixedPixels;
//            remainingFixedPixelsToRemove -= removedFixedPixels;
//            remainingFixedPanes--;
//        }
//        // (new size / flexible size available) == (old size / old flexible size available)
//        else if (oldFlexibleSpace > 0)
//            targetSize = newFlexibleSpace * viewSizes[index] / oldFlexibleSpace;
//        // oldFlexibleSpace <= 0 so all flexible areas were crushed. When we get space, allocate it evenly.
//        // totalSizablePanes cannot be 0 since isSizable.
//        else
//            targetSize = newFlexibleSpace / totalSizablePanes;
//
//        targetSize = MAX(0, ROUND(targetSize));
//        viewFrame.size[_sizeComponent] = targetSize;
//        [view setFrame:viewFrame];
//        bounds.origin[_originComponent] += targetSize + dividerThickness;
//    }

    SPLIT_VIEW_MAYBE_POST_DID_RESIZE();
}

#pragma mark - Private layout utilities

- (CPInteger)_usableSize
{
    // FIXME: utile ?
    return [self frame].size[_sizeComponent] - _dividerSubviews.length * [self currentValueForThemeAttribute:@"divider-thickness"];
}

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

- (void)_layoutSubviews
{
    //    [self _adjustSubviewsWithCalculatedSize]

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

- (void)_updateRatios
{
    // When a divider is moved, we have to compute new ratios based on new sizes

    var flexibleSpace = 0,
        flexibleCount = 0,
        fixedSpace    = 0,
        fixedCount    = 0;

    for (var i = 0, count = _arrangedSubviews.length, isFlexible; i < count; i++)
    {
        [_isFlexible replaceObjectAtIndex:i withObject:(isFlexible = [self _sendDelegateSplitViewShouldAdjustSizeOfSubview:_arrangedSubviews[i]])];

        [_initialSizes replaceObjectAtIndex:i withObject:[_arrangedSubviews[i] frame].size[_sizeComponent]];

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

    for (var i = 0, count = _arrangedSubviews.length; i < count; i++)
        if (_isFlexible[i])
            [_ratios replaceObjectAtIndex:i withObject:(_initialSizes[i] / flexibleSpace)];
        else
            [_ratios replaceObjectAtIndex:i withObject:(_initialSizes[i] / fixedSpace)];
}

- (void)_adjustSubviewsWithCalculatedSize
{
    if (!_needsResizeSubviews)
        return;

    _needsResizeSubviews = NO;

    // FIXME : revoir ! Performances ??? Mettre en cache la old size ?
    [self resizeSubviewsWithOldSize:[self _calculateSize]];
}

- (CGSize)_calculateSize
{
    var subviews = [self subviews],
        count = subviews.length,
        size = CGSizeMakeZero();

    if (_isVertical)
    {
        size.width += [self dividerThickness] * (count - 1);
        size.height = CGRectGetHeight([self frame]);
    }
    else
    {
        size.width = CGRectGetWidth([self frame]);
        size.height += [self dividerThickness] * (count - 1);
    }

    while (count--)
        size[_sizeComponent] += [subviews[count] frame].size[_sizeComponent];

    return size;
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
    Returns the CGRect of the divider at a given index.

    @param int - The index of a divider.
    @return CGRect - The rect of a divider.
*/
- (void)drawRect:(CGRect)rect
{
    if (_isCSSBased)
        return;

    var count = [_subviews count] - 1;

    while ((count--) > 0)
    {
        _drawingDivider = count;
        [self drawDividerInRect:[self rectOfDividerAtIndex:count]];
    }
}

/*!
    Draws the divider at a given rect.
    @param aRect - the rect of the divider to draw.
*/
- (void)drawDividerInRect:(CGRect)aRect
{
    // FIXME: vérifier que OK
    if (_isCSSBased)
        return;

//#if PLATFORM(DOM)
//    if (!_DOMDividerElements[_drawingDivider])
//    {
//        _DOMDividerElements[_drawingDivider] = document.createElement("div");
//
//        _DOMDividerElements[_drawingDivider].style.position = "absolute";
//        _DOMDividerElements[_drawingDivider].style.backgroundRepeat = "repeat";
//
//        CPDOMDisplayServerAppendChild(_DOMElement, _DOMDividerElements[_drawingDivider]);
//        [self _setupDOMDivider];
//    }
//
//    CPDOMDisplayServerSetStyleLeftTop(_DOMDividerElements[_drawingDivider], NULL, CGRectGetMinX(aRect), CGRectGetMinY(aRect));
//    CPDOMDisplayServerSetStyleSize(_DOMDividerElements[_drawingDivider], CGRectGetWidth(aRect), CGRectGetHeight(aRect));
//#endif
}

//- (void)_setupDOMDivider
//{
//    if (_isPaneSplitter)
//    {
//        _DOMDividerElements[_drawingDivider].style.backgroundColor = "";
//        _DOMDividerElements[_drawingDivider].style.backgroundImage = "url('"+_dividerImagePath+"')";
//    }
//    else
//    {
//        _DOMDividerElements[_drawingDivider].style.backgroundColor = [[self currentValueForThemeAttribute:@"pane-divider-color"] cssString];
//        _DOMDividerElements[_drawingDivider].style.backgroundImage = "";
//    }
//}

//- (void)viewWillDraw
//{
//    [self _adjustSubviewsWithCalculatedSize];
//}

- (BOOL)cursorAtPoint:(CGPoint)aPoint hitDividerAtIndex:(int)anIndex
{
    // FIXME : revoir
    var frame = [_arrangedSubviews[anIndex] frame],
        startPosition = frame.origin[_originComponent] + frame.size[_sizeComponent],
        effectiveRect = [self effectiveRectOfDividerAtIndex:anIndex],
        buttonBar = _buttonBars[anIndex],
        buttonBarRect = null,
        additionalRect = null;

    if (buttonBar != null)
    {
        buttonBarRect = [buttonBar resizeControlFrame];
        buttonBarRect.origin = [self convertPoint:buttonBarRect.origin fromView:buttonBar];
    }

    effectiveRect = [self _sendDelegateSplitViewEffectiveRect:effectiveRect forDrawnRect:effectiveRect ofDividerAtIndex:anIndex];
    additionalRect = [self _sendDelegateSplitViewAdditionalEffectiveRectOfDividerAtIndex:anIndex];

    return CGRectContainsPoint(effectiveRect, aPoint) ||
           (additionalRect && CGRectContainsPoint(additionalRect, aPoint)) ||
           (buttonBarRect && CGRectContainsPoint(buttonBarRect, aPoint));
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
    // FIXME : revoir
    var count = [_dividerSubviews count];

    for (var i = 0; i < count; i++)
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
    // FIXME: problème quand 2 collapsed à gauche : flèche OK pour le + à droite, pas OK pour le + à gauche
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
            {
                // Right/lower subview is collapsed.
                canGrow = NO;
                // It's safe to assume it can always be uncollapsed.
                canShrink = YES;
            }
            else if (!canGrow && [self _sendDelegateSplitViewCanCollapseSubview:_arrangedSubviews[i + 1]])
            {
                canGrow = YES; // Right/lower subview is collapsible.
            }

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
//    [self _adjustSubviewsWithCalculatedSize];

    var realPosition = [self _realPositionForPosition:position ofDividerAtIndex:dividerIndex],
        viewA = _arrangedSubviews[dividerIndex],
        frameA = [viewA frame],
        viewB = _arrangedSubviews[dividerIndex + 1],
        frameB = [viewB frame],
        preCollapsePosition = 0,
        preSize = frameA.size[_sizeComponent];

    frameA.size[_sizeComponent] = realPosition - frameA.origin[_originComponent];

    // We update the ratio of first view (= new size * old ratio / old size)
    // FIXME: problème quand le vue était collapsed (preSize = 0 -> ratio devient n'importe quoi)
    // FIXME: quid des initialesSizes ? ne doit-on pas les changer quand l'utilisateur intervient manuellement sur le divideur ?
//    _ratios[dividerIndex] = frameA.size[_sizeComponent] * _ratios[dividerIndex] / preSize;

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

    // We update the ratio of second view (= new size * old ratio / old size)
//    _ratios[dividerIndex+1] = frameB.size[_sizeComponent] * _ratios[dividerIndex+1] / preSize;

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

    // FIXME: recalculer tous les ratios !
//    [_ratios replaceObjectAtIndex:i withObject:(_initialSizes[i] / flexibleSpace)];
    [self _updateRatios];

//    _adjustSubviewsWithCalculatedSize
//    {
//        if (!_needsResizeSubviews

//    [self setNeedsDisplay:YES];

    if (SPLIT_VIEW_DID_SUPPRESS_RESIZE_NOTIFICATION())
        [self _postNotificationDidResize];

    SPLIT_VIEW_SUPPRESS_RESIZE_NOTIFICATIONS(NO);
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
    if (!aButtonBar)
    {
        _buttonBars[dividerIndex] = nil;
        return;
    }

    var view = [aButtonBar superview],
        subview = aButtonBar;

    while (view && view !== self)
    {
        subview = view;
        view = [view superview];
    }

    if (view !== self)
        [CPException raise:CPInvalidArgumentException
                    reason:@"CPSplitView button bar must be a subview of the split view."];

    var viewIndex = [[self subviews] indexOfObject:subview];

    [aButtonBar setHasResizeControl:YES];
    [aButtonBar setResizeControlIsLeftAligned:dividerIndex < viewIndex];

    _buttonBars[dividerIndex] = aButtonBar;
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
    This is called sometime later after a split view has been restored from a Cib.
    See notes in initWithCoder.

    @ignore
*/
- (void)_restoreFromAutosaveIfNeeded
{
    if (_shouldRestoreFromAutosaveUnlessFrameSize && !CGSizeEqualToSize([self frameSize], _shouldRestoreFromAutosaveUnlessFrameSize))
    {
        [self _restoreFromAutosave];
    }

    _shouldRestoreFromAutosaveUnlessFrameSize = nil;
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

        for (var i = 0, count = [frames count] - 1; i < count; i++)
        {
            var frame = CGRectFromString(frames[i]);
            position += frame.size[_sizeComponent];

            [self setPosition:position ofDividerAtIndex:i];

            position += dividerThickness;
        }

        _shouldAutosave = YES;
    }

    if (preCollapseArray)
    {
        _preCollapsePositions = [CPMutableDictionary new];

        for (var i = 0, count = [preCollapseArray count]; i < count; i++)
        {
            var item = preCollapseArray[i];

            if (item === nil)
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
}

// FIXME: appeler quand on modifie les subviews (arranged)
- (void)updateTrackingAreas
{
    if (_splitViewTrackingAreas)
    {
        for (var i = 0, count = _splitViewTrackingAreas.length; i < count; i++)
            [self removeTrackingArea:_splitViewTrackingAreas[i]];

        _splitViewTrackingAreas = nil;
    }

    var options = CPTrackingCursorUpdate | CPTrackingActiveInKeyWindow;

    _splitViewTrackingAreas = @[];

    // FIXME: Seems to be needed when compiling themes
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
    }

    [super updateTrackingAreas];
}

- (void)cursorUpdate:(CPEvent)anEvent
{
    if (_currentDivider === CPNotFound)
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
    if (_autosaveName)
    {
        // Schedule /before/ [super initWithCoder:]. This way this instance's _restoreFromAutosaveIfNeeded
        // will happen before that of any subviews loaded by [super initWithCoder:].
        [[CPRunLoop currentRunLoop] performSelector:@selector(_restoreFromAutosaveIfNeeded) target:self argument:nil order:0 modes:[CPDefaultRunLoopMode]];
    }

    // As subviews are often not fully ready to use at this time, we'll try to finalize the initialization after all views initializations are done

    [[CPRunLoop currentRunLoop] performSelector:@selector(_finalizeInitWithCoder) target:self argument:nil order:0 modes:[CPDefaultRunLoopMode]];

    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self _init];
        // FIXME: vérifier si pas des trucs en double avec le _init

        _suppressResizeNotificationsMask = 0;
        _preCollapsePositions = [CPMutableDictionary new];

        _currentDivider = CPNotFound;
        _shouldAutosave = YES;
        _isTracking = NO;

        _DOMDividerElements = @[];

        _buttonBars = [aCoder decodeObjectForKey:CPSplitViewButtonBarsKey] || @[];

        [self setDelegate:[aCoder decodeObjectForKey:CPSplitViewDelegateKey]];

        _isPaneSplitter = [aCoder decodeBoolForKey:CPSplitViewIsPaneSplitterKey];
        [self _setVertical:[aCoder decodeBoolForKey:CPSplitViewIsVerticalKey]];

        _dividerSubviews  = [aCoder decodeObjectForKey:CPSplitViewDividerSubviewsKey]  || @[];
        _arrangedSubviews = [aCoder decodeObjectForKey:CPSplitViewArrangedSubviewsKey] || @[];
        _realSubviews     = [aCoder decodeObjectForKey:CPSplitViewRealSubviewsKey]     || @[];

        // FIXME: pourquoi devoir faire ça ? Peut-être retirer après adaptation nib2cib
//        if (!_dividerSubviews)
//            _dividerSubviews = @[];

        CPLog.info("CODER: #arranged="+[_arrangedSubviews count]+" #divider="+[_dividerSubviews count]+" #real="+[_realSubviews count]+" #subviews="+[[self subviews] count]);

        [self setArrangesAllSubviews:[aCoder decodeBoolForKey:CPSplitViewArrangesAllSubviewsKey]];
        [self setDividerStyle:[aCoder decodeIntForKey:CPSplitViewDividerStyleKey]];

        _isCSSBased = [[self theme] isCSSBased];

        // Subviews received from Xcode IB are in fact arranged subviews
//        for (var i = 0, subviews = [self subviews], count = [subviews count]; i < count; i++)
//            [self _addArrangedSubview:subviews[i]];

        if (_autosaveName)
        {
            [self _restoreFromAutosave];
            // Remember the frame size we had at this point so that we can restore again if it changes
            // before the next runloop cycle. See above notes.
            _shouldRestoreFromAutosaveUnlessFrameSize = [self frameSize];
        }
    }

    return self;
}

- (void)_finalizeInitWithCoder
{
    CPLog.info("_finalizeInitWithCoder");

    // Subviews received from Xcode IB are in fact arranged subviews

    _subviewsManagementDisabled = YES;

    for (var i = 0, subviews = [self subviews], count = subviews.length; i < count; i++)
        [self _addArrangedSubview:subviews[i]];

    _subviewsManagementDisabled = NO;

    // FIXME: vérifier qu'il n'y a pas d'interférence avec le autosave quand il y en a un
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
    [aCoder encodeBool:  _isPaneSplitter      forKey:CPSplitViewIsPaneSplitterKey];
    [aCoder encodeInt:   _dividerStyle        forKey:CPSplitViewDividerStyleKey];
    [aCoder encodeObject:_dividerSubviews     forKey:CPSplitViewDividerSubviewsKey];
    [aCoder encodeObject:_arrangedSubviews    forKey:CPSplitViewArrangedSubviewsKey];
    [aCoder encodeObject:_realSubviews        forKey:CPSplitViewRealSubviewsKey];
    [aCoder encodeBool:  _arrangesAllSubviews forKey:CPSplitViewArrangesAllSubviewsKey];
    [aCoder encodeObject:_autosaveName        forKey:CPSplitViewAutosaveNameKey];

    CPLog.info("CPSPlitView encodeWithCoder arranged="+_arrangedSubviews+" count="+(_arrangedSubviews ? [_arrangedSubviews count] : @"--"));
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

    return _isPaneSplitter;
}

/*!
 Used to set if the split view dividers should be the larger pane splitter.

 @param shouldBePaneSplitter - YES if the dividers should be the thicker pane splitter, otherwise NO.
 */
- (void)setIsPaneSplitter:(BOOL)shouldBePaneSplitter
{
    CPLog.warn("setIsPaneSplitter is now deprecated. Use setDividerStyle instead.");

    if (_isPaneSplitter == shouldBePaneSplitter)
        return;

    _isPaneSplitter = shouldBePaneSplitter;

//    if (_DOMDividerElements[_drawingDivider])
//        [self _setupDOMDivider];

    // The divider changes size when pane splitter mode is toggled, so the
    // subviews need to change size too.
    _needsResizeSubviews = YES;
    [self setNeedsDisplay:YES];
}

@end

