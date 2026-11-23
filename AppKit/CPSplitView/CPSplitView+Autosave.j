/*
 * CPSplitView+Autosave.j
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

@class CPUserDefaults

@implementation CPSplitView (Autosave)

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
