/*
 * CPSplitView+Coding.j
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

@import "CPSplitViewCore.j"

var CPSplitViewDelegateKey            = @"CPSplitViewDelegateKey",
    CPSplitViewIsVerticalKey          = @"CPSplitViewIsVerticalKey",
    CPSplitViewIsPaneSplitterKey      = @"CPSplitViewIsPaneSplitterKey",
    CPSplitViewButtonBarsKey          = @"CPSplitViewButtonBarsKey",
    CPSplitViewAutosaveNameKey        = @"CPSplitViewAutosaveNameKey",
    CPSplitViewDividerStyleKey        = @"CPSplitViewDividerStyleKey",
    CPSplitViewDividerSubviewsKey     = @"CPSplitViewDividerSubviewsKey",
    CPSplitViewArrangedSubviewsKey    = @"CPSplitViewArrangedSubviewsKey",
    CPSplitViewArrangesAllSubviewsKey = @"CPSplitViewArrangesAllSubviewsKey",
    CPSplitViewRealSubviewsKey        = @"CPSplitViewRealSubviewsKey",
    CPSplitViewHoldingPrioritiesKey   = @"CPSplitViewHoldingPrioritiesKey";

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

        _currentDivider = CPNotFound;
        _shouldAutosave = NO;
        _isTracking = NO;

        _buttonBars = [aCoder decodeObjectForKey:CPSplitViewButtonBarsKey] || @[];

        [self setDelegate:[aCoder decodeObjectForKey:CPSplitViewDelegateKey]];

        [self _setVertical:[aCoder decodeBoolForKey:CPSplitViewIsVerticalKey]];

        _dividerSubviews  = [aCoder decodeObjectForKey:CPSplitViewDividerSubviewsKey]  || @[];
        _arrangedSubviews = [aCoder decodeObjectForKey:CPSplitViewArrangedSubviewsKey] || @[];
        _realSubviews     = [aCoder decodeObjectForKey:CPSplitViewRealSubviewsKey]     || @[];

        /*
            A cib has no arranged subviews yet: its priorities are kept as archived until
            -_cibInstantiate arranges the subviews.
        */
        var holdingPriorities = [aCoder decodeObjectForKey:CPSplitViewHoldingPrioritiesKey];

        if (_arrangedSubviews.length > 0)
            [self _setHoldingPrioritiesFromArchive:holdingPriorities];
        else
            _holdingPriorities = holdingPriorities ? [holdingPriorities mutableCopy] : @[];

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

    /*
        A cib has no arranged subviews when it is decoded, so the archived holding priorities
        are applied once the subviews are arranged.
    */
    var archivedPriorities = [_holdingPriorities copy];

    _holdingPriorities = @[];

    _subviewsManagementDisabled = YES;

    for (var i = 0, subviews = [self subviews], count = subviews.length; i < count; i++)
        [self _addArrangedSubview:subviews[i]];

    _subviewsManagementDisabled = NO;

    [self _setHoldingPrioritiesFromArchive:archivedPriorities];
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
    [aCoder encodeObject:_holdingPriorities   forKey:CPSplitViewHoldingPrioritiesKey];
    [aCoder encodeBool:  _arrangesAllSubviews forKey:CPSplitViewArrangesAllSubviewsKey];
    [aCoder encodeObject:_autosaveName        forKey:CPSplitViewAutosaveNameKey];
}

@end
