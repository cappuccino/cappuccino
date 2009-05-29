/*
 * BKThemedObjectTemplate.j
 * BlendKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
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

@import <AppKit/CPView.j>


@implementation BKThemedObjectTemplate : CPView
{
    CPString    _label;
    id          _themedObject;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _label = [aCoder decodeObjectForKey:@"BKThemedObjectTemplateLabel"];
        _themedObject = [aCoder decodeObjectForKey:@"BKThemedObjectTemplateThemedObject"];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_label forKey:@"BKThemedObjectTemplateLabel"];
    [aCoder encodeObject:_themedObject forKey:@"BKThemedObjectTemplateThemedObject"];
}

@end
