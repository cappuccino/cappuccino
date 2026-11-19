/*
 * _CPToolbarShowFontsItem.j
 * AppKit
 *
 * Created by David Richardson on 2026-11-19.
 * Copyright David Richardson 2026.
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

@import "_CPToolbarItem.j"

@class CPFontManager

/*
    The standard Fonts item (CPToolbarShowFontsItemIdentifier). As in AppKit, it sends
    -orderFrontFontPanel: to the shared font manager.
*/
@implementation _CPToolbarShowFontsItem : CPToolbarItem
{
}

- (id)initWithItemIdentifier:(CPString)anIgnoredIdentifier
{
    self = [super initWithItemIdentifier:CPToolbarShowFontsItemIdentifier];

    if (self)
    {
        [self setMinSize:CGSizeMake(32.0, 32.0)];
        [self setMaxSize:CGSizeMake(32.0, 32.0)];

        [self setLabel:@"Fonts"];
        [self setPaletteLabel:@"Show Fonts"];

        [self setTarget:[CPFontManager sharedFontManager]];
        [self setAction:@selector(orderFrontFontPanel:)];
        [self setImage:[CPImage imageNamed:CPImageNameFontPanel]];
        [self setToolTip:@"Show the Fonts panel."];
    }

    return self;
}

/*
    A standard item is archived by its identifier alone, so it decodes as a new standard item.
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    return [self init];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
}

@end
