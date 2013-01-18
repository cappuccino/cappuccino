/*
 * NSObjectController.j
 * nib2cib
 *
 * Created by Ross Boucher.
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

@import <AppKit/CPObjectController.j>

@global CP_NSMapClassName


@implementation CPObjectController (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _declaredKeys = [aCoder decodeObjectForKey:@"NSDeclaredKeys"];

        var className = [aCoder decodeObjectForKey:@"NSObjectClassName"];
        if (className)
            _objectClassName = CP_NSMapClassName(className);
        else
            _objectClass = [CPMutableDictionary class];

        _isEditable = [aCoder decodeBoolForKey:@"NSEditable"];
        _automaticallyPreparesContent = [aCoder decodeBoolForKey:@"NSAutomaticallyPreparesContent"];
    }

    return self;
}

@end

@implementation NSObjectController : CPObjectController
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPObjectController class];
}

@end
