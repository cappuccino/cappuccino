/*
 * NSLayoutConstraint.j
 * nib2cib
 *
 * Created by Aparajita Fishman.
 * Copyright 2013, The Cappuccino Foundation.
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

@import <Foundation/CPObject.j>
@import <Foundation/CPException.j>

@class Converter


@implementation NSLayoutConstraint : CPObject

- (id)initWithCoder:(CPCoder)aCoder
{
    [CPException raise:@"nib2cibException" format:@"Autolayout is not yet supported. Turn \"Use Auto Layout\" off in the File Inspector of %@.", [[[Converter sharedConverter] inputPath] lastPathComponent]];
}

- (Class)classForKeyedArchiver
{
    return [CPObject class];
}

@end
