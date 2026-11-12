/*
 * NSStackView.j
 * nib2cib
 *
 * Created by Daniel Boehringer.
 * Copyright 2026 The Cappuccino Project.
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

@import <AppKit/CPStackView.j>


@implementation CPStackView (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    if (self = [super NS_initWithCoder:aCoder])
    {
        _orientation = [aCoder containsValueForKey:@"NSOrientation"] ? [aCoder decodeIntForKey:@"NSOrientation"] : CPUserInterfaceLayoutOrientationHorizontal;
        _alignment = [aCoder containsValueForKey:@"NSAlignment"] ? [aCoder decodeIntForKey:@"NSAlignment"] : CPLayoutAttributeCenterY;
        _spacing = [aCoder containsValueForKey:@"NSSpacing"] ? [aCoder decodeFloatForKey:@"NSSpacing"] : 8.0;

        var top = [aCoder containsValueForKey:@"NSEdgeInsetsTop"] ? [aCoder decodeFloatForKey:@"NSEdgeInsetsTop"] : 0.0,
            left = [aCoder containsValueForKey:@"NSEdgeInsetsLeft"] ? [aCoder decodeFloatForKey:@"NSEdgeInsetsLeft"] : 0.0,
            bottom = [aCoder containsValueForKey:@"NSEdgeInsetsBottom"] ? [aCoder decodeFloatForKey:@"NSEdgeInsetsBottom"] : 0.0,
            right = [aCoder containsValueForKey:@"NSEdgeInsetsRight"] ? [aCoder decodeFloatForKey:@"NSEdgeInsetsRight"] : 0.0;
        _edgeInsets = CPEdgeInsetsMake(top, left, bottom, right);

        _detachesHiddenViews = [aCoder containsValueForKey:@"NSDetachesHiddenViews"] ? [aCoder decodeBoolForKey:@"NSDetachesHiddenViews"] : YES;

        _viewsLeading = [[CPMutableArray alloc] init];
        _viewsCenter = [[CPMutableArray alloc] init];
        _viewsTrailing = [[CPMutableArray alloc] init];
        _arrangedSubviews = [[CPMutableArray alloc] init];

        _customSpacings = [[CPMapTable alloc] init];
        _visibilityPriorities = [[CPMapTable alloc] init];

        var arrangedSubviews = nil;
        if ([aCoder containsValueForKey:@"NSArrangedSubviews"])
            arrangedSubviews = [aCoder decodeObjectForKey:@"NSArrangedSubviews"];
        else if ([aCoder containsValueForKey:@"NSViews"])
            arrangedSubviews = [aCoder decodeObjectForKey:@"NSViews"];

        if (arrangedSubviews)
        {
            for (var i = 0; i < [arrangedSubviews count]; i++)
            {
                [self addArrangedSubview:arrangedSubviews[i]];
            }
        }
    }

    return self;
}

@end

@implementation NSStackView : CPStackView
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPStackView class];
}

@end
