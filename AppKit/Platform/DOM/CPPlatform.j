/*
 * CPPlatform+DOM.j
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

@global CPApp

if (typeof window["CPPlatformEnableHTMLDragAndDrop"] === "undefined")
    CPPlatformEnableHTMLDragAndDrop = NO;

CPPlatformDidClearBodyElementNotification   = @"CPPlatformDidClearBodyElementNotification";
CPPlatformWillClearBodyElementNotification  = @"CPPlatformWillClearBodyElementNotification";

var screenNeedsInitialization   = NO,
    mainBodyElement = nil,
    elementRemovalTest = new RegExp("\\bcpdontremove\\b", "g");

@implementation CPPlatform : CPBasePlatform
{
}

+ (void)initialize
{
    if (self !== [CPPlatform class])
        return;

    screenNeedsInitialization = [CPPlatform isBrowser];

    // We do this here because doing it later breaks IE.
    if (document.documentElement)
        document.documentElement.style.overflow = "hidden";

    if ([CPPlatform isBrowser])
        window.onunload = function()
        {
            [CPApp terminate:nil];
        };
}

+ (BOOL)isBrowser
{
    return typeof window.cpIsDesktop === "undefined";
}

+ (BOOL)supportsDragAndDrop
{
    return CPFeatureIsCompatible(CPHTMLDragAndDropFeature) && (CPPlatformEnableHTMLDragAndDrop || ![self isBrowser]);
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
    if (typeof window["cpActivateIgnoringOtherApps"] === "function")
        window.cpActivateIgnoringOtherApps(!!shouldIgnoreOtherApps);
}

+ (void)deactivate
{
    if (typeof window["cpDeactivate"] === "function")
        window.cpDeactivate();
}

+ (void)hideOtherApplications:(id)aSender
{
    if (typeof window["cpHideOtherApplications"] === "function")
        window.cpHideOtherApplications();
}

+ (void)hide:(id)aSender
{
    if (typeof window["cpHide"] === "function")
        window.cpHide();
}

+ (DOMElement)mainBodyElement
{
    if (!mainBodyElement)
        mainBodyElement = document.getElementById("cappuccino-body") || document.body;

    return mainBodyElement;
}

+ (void)initializeScreenIfNecessary
{
    if (!screenNeedsInitialization)
        return;

    screenNeedsInitialization = NO;

    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPPlatformWillClearBodyElementNotification
                      object:self];

    var bodyElement = [self mainBodyElement];

    // Get rid of any of the original contents of the page.
    var children = bodyElement.childNodes,
        length = children.length;

    while (length--)
    {
        var element = children[length];
        if (!element.className || element.className.match(elementRemovalTest) === null)
            bodyElement.removeChild(element);
    }

    bodyElement.style.overflow = "hidden";

    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPPlatformDidClearBodyElementNotification
                      object:self];
}

@end
