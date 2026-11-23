/*
 * CPSplitViewCore.j
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

@import "CPButtonBar.j"
@import "CPCursor.j"
@import "CPImage.j"
@import "CPTrackingArea.j"
@import "CPView.j"


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

CPSplitViewDidResizeSubviewsNotification = @"CPSplitViewDidResizeSubviewsNotification";
CPSplitViewWillResizeSubviewsNotification = @"CPSplitViewWillResizeSubviewsNotification";


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

    CPString                    _originComponent;
    CPString                    _otherOriginComponent;
    CPString                    _sizeComponent;
    CPString                    _otherSizeComponent;

    BOOL                        _isTracking;

    CPString                    _autosaveName;
    BOOL                        _shouldAutosave;

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

// MARK: - Properties

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

    // A theme may define no divider image, and a pattern needs one.
    var image = [self currentValueForThemeAttribute:(_isVertical ? @"vertical-divider-color" : @"horizontal-divider-color")];

    return image ? [CPColor colorWithPatternImage:image] : nil;
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
        /*
            All subviews except the dividers become arranged subviews, in their current order.
            The plain add and remove methods keep the dividers correct.

            2026-11-23: the list came from _realSubviews, which only
            -_insertArrangedSubview:atIndex: fills. A subview added while the split view did not
            arrange all subviews was not in it, so it did not become an arranged subview.
        */
        var subviews = [self subviews],
            views = @[];

        for (var i = 0, count = subviews.length; i < count; i++)
            if (![_dividerSubviews containsObjectIdenticalTo:subviews[i]])
                [views addObject:subviews[i]];

        // First, remove all real subviews (arranged & non arranged)
        for (var i = views.length - 1; i >= 0; i--)
            [views[i] removeFromSuperview];

        // Then add all real subviews as arranged subviews
        for (var i = 0, count = views.length; i < count; i++)
            [self addArrangedSubview:views[i]]
    }

    [self setNeedsLayout:YES];
}

// MARK: - Subviews management

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

@end

// MARK: -

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
