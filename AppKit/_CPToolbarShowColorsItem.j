/*
 * _CPToolbarShowColorsItem.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2010, 280 North, Inc.
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

@import "CPApplication.j"
@import "CPToolbarItem.j"


@implementation _CPToolbarShowColorsItem : CPToolbarItem
{
}

- (id)initWithItemIdentifier:(CPString)anIgnoredIdentifier
{
    self = [super initWithItemIdentifier:CPToolbarShowColorsItemIdentifier];

    if (self)
    {
        [self setMinSize:CGSizeMake(32.0, 32.0)];
        [self setMaxSize:CGSizeMake(32.0, 32.0)];

        [self setLabel:@"Colors"];
        [self setPaletteLabel:@"Show Colors"];

        [self setTarget:CPApp];
        [self setAction:@selector(orderFrontColorPanel:)];
        [self setImage:[CPImage imageNamed:CPImageNameColorPanel]];
        [self setAlternateImage:[CPImage imageNamed:CPImageNameColorPanelHighlighted]];
        [self setToolTip:@"Show the Colors panel."];
    }

    return self;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self init];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
}

@end
