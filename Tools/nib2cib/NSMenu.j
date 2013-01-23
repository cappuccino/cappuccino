/*
 * NSMenu.j
 * nib2cib
 *
 * Created by Thomas Robinson.
 * Copyright 2008, 280 North, Inc.
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

@import <AppKit/CPMenu.j>


NS_CPMenuNameMap =
{
    _NSMainMenu             : @"_CPMainMenu",
    _NSAppleMenu            : @"_CPApplicationMenu",
    _NSServicesMenu         : @"_CPServicesMenu",
    _NSWindowsMenu          : @"_CPWindowsMenu",
    _NSFontMenu             : @"_CPFontMenu",
    _NSRecentDocumentsMenu  : @"_CPRecentDocumentsMenu",
    _NSOpenDocumentsMenu    : @"_CPOpenDocumentsMenu"
};

@implementation CPMenu (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _title = [aCoder decodeObjectForKey:@"NSTitle"];
        _items = [aCoder decodeObjectForKey:@"NSMenuItems"];
        _name = [aCoder decodeObjectForKey:@"NSName"];

        var mappedName = NS_CPMenuNameMap[_name];

        if (mappedName)
            _name = mappedName;

        _showsStateColumn = ![aCoder containsValueForKey:@"NSMenuExcludeMarkColumn"] || ![aCoder decodeBoolForKey:@"NSMenuExcludeMarkColumn"];
    }

    return self;
}

@end

@implementation NSMenu : CPMenu
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPMenu class];
}

@end
