/*
 * NSFont.j
 * nib2cib
 *
 * Created by Klaas Pieter Annema.
 * Copyright 2010 Cappuccino Foundation.
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

@import <Foundation/CPFormatter.j>

@implementation CPFormatter (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    return [self init];
}

@end

@implementation NSFormatter : CPFormatter

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPFormatter class];
}

@end

/*
    Xcode uses a proxy class called IBCustomFormatter when a "Custom Formatter"
    is placed in a xib. During nib2cib, an IBCustomFormatter instance is created
    and stringForObjectValue is eventually called, which means we have to define
    it here at least so that the conversion will work.

    At runtime, the actual formatter class is used, not IBCustomFormatter.
*/
@implementation IBCustomFormatter : NSFormatter

- (CPString)stringForObjectValue:(id)anObject
{
    return nil;
}

@end
