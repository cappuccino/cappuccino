/*
 * __filename__
 * __project.name__
 *
 * Created by __user.name__ on __project.date__.
 *
 * Copyright __project.year__, __organization.name__. All rights reserved.
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


/*!
    This class is defined to make it easier to find the bundle,
    for example to get an image from the framework like this:

    @code
    var path = [[CPBundle bundleForClass:__project.nameasidentifier__] pathForResource:@"email-action.png"];
    @endcode

    You can also use [__project.nameasidentifier__ version] to get the current version.
*/
@implementation __project.nameasidentifier__ : CPObject

+ (CPString)version
{
    var bundle = [CPBundle bundleForClass:[self class]];

    return [bundle objectForInfoDictionaryKey:@"CPBundleVersion"];
}

@end
