/*
 * CPPlatform.j
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

@import <Foundation/CPObject.j>


@implementation CPBasePlatform : CPObject
{
}

+ (void)bootstrap
{
    [CPPlatformString bootstrap];
    [CPPlatformWindow setPrimaryPlatformWindow:[[CPPlatformWindow alloc] _init]];
}

+ (BOOL)isBrowser
{
    return NO;
}

+ (BOOL)supportsDragAndDrop
{
    return NO;
}

+ (BOOL)supportsNativeMainMenu
{
    return NO;
}

+ (void)terminateApplication
{
}

+ (void)activateIgnoringOtherApps:(BOOL)shouldIgnoreOtherApps
{
}

+ (void)deactivate
{
}

+ (void)hideOtherApplications:(id)aSender
{
}

+ (void)hide:(id)aSender
{
}

@end

#if PLATFORM(DOM)
#include "DOM/CPPlatform.j"
#else
@implementation CPPlatform : CPBasePlatform
{
}
@end
#endif
