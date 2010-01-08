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

#include "Platform.h"


@implementation CPPlatform : CPObject
{
}

+ (void)bootstrap
{
    [CPPlatformString bootstrap];
    [CPPlatformWindow setPrimaryPlatformWindow:[[CPPlatformWindow alloc] _init]];
}

+ (BOOL)isBrowser
{
    return typeof window.cpIsDesktop === "undefined";
}

+ (BOOL)supportsDragAndDrop
{
    return CPFeatureIsCompatible(CPHTMLDragAndDropFeature);
}

+ (BOOL)supportsNativeMainMenu
{
    return (typeof window["cpSetMainMenu"] === "function");
}

+ (void)terminateApplication
{
    if (typeof window["cpTerminate"] === "function")
        window.cpTerminate();
}

+ (void)activateIgnoringOtherApps:(BOOL)shouldIgnoreOtherApps
{
#if PLATFORM(DOM)
    if (typeof window["cpActivateIgnoringOtherApps"] === "function")
        window.cpActivateIgnoringOtherApps(!!shouldIgnoreOtherApps);
#endif
}

+ (void)hideOtherApplications:(id)aSender
{
#if PLATFORM(DOM)
    if (typeof window["cpHideOtherApplications"] === "function")
        window.cpHideOtherApplications();
#endif
}

+ (void)hide:(id)aSender
{
#if PLATFORM(DOM)
    if (typeof window["cpHide"] === "function")
        window.cpHide();
#endif
}

@end

#if PLATFORM(DOM)
@import "CPPlatform+DOM.j"
#endif
