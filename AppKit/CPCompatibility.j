/*
 * CPCompatibility.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
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

@import "CPEvent.j"
@import "CPPlatform.j"


// Browser Engines
CPUnknownBrowserEngine                  = 0;
CPGeckoBrowserEngine                    = 1;
CPInternetExplorerBrowserEngine         = 2;
CPKHTMLBrowserEngine                    = 3;
CPOperaBrowserEngine                    = 4;
CPWebKitBrowserEngine                   = 5;

// Operating Systems
CPMacOperatingSystem                    = 0;
CPWindowsOperatingSystem                = 1;
CPOtherOperatingSystem                  = 2;

// Features
CPCSSRGBAFeature                        = 1 << 5;

CPHTMLCanvasFeature                     = 1 << 6;
CPHTMLContentEditableFeature            = 1 << 7;
CPHTMLDragAndDropFeature                = 1 << 8;

CPJavascriptInnerTextFeature            = 1 << 9;
CPJavascriptTextContentFeature          = 1 << 10;
CPJavascriptClipboardEventsFeature      = 1 << 11;
CPJavascriptClipboardAccessFeature      = 1 << 12;
CPJavaScriptCanvasDrawFeature           = 1 << 13;
CPJavaScriptCanvasTransformFeature      = 1 << 14;

CPVMLFeature                            = 1 << 15;

CPJavascriptRemedialKeySupport          = 1 << 16;
CPJavaScriptShadowFeature               = 1 << 20;

CPJavaScriptNegativeMouseWheelValues    = 1 << 22;
CPJavaScriptMouseWheelValues_8_15       = 1 << 23

CPOpacityRequiresFilterFeature          = 1 << 24;

//Internet explorer does not allow dynamically changing the type of an input element
CPInputTypeCanBeChangedFeature          = 1 << 25;
CPHTML5DragAndDropSourceYOffBy1         = 1 << 26;


var USER_AGENT                          = "",
    PLATFORM_ENGINE                     = CPUnknownBrowserEngine,
    PLATFORM_FEATURES                   = 0;

// default these features to true

PLATFORM_FEATURES |= CPInputTypeCanBeChangedFeature;

if (typeof window !== "undefined" && typeof window.navigator !== "undefined")
    USER_AGENT = window.navigator.userAgent;

// Opera
if (typeof window !== "undefined" && window.opera)
{
    PLATFORM_ENGINE = CPOperaBrowserEngine;

    PLATFORM_FEATURES |= CPJavaScriptCanvasDrawFeature;
}

// Internet Explorer
else if (typeof window !== "undefined" && window.attachEvent) // Must follow Opera check.
{
    PLATFORM_ENGINE = CPInternetExplorerBrowserEngine;

    // Features we can only be sure of with IE (no known independent tests)
    PLATFORM_FEATURES |= CPVMLFeature;
    PLATFORM_FEATURES |= CPJavascriptRemedialKeySupport;
    PLATFORM_FEATURES |= CPJavaScriptShadowFeature;

    PLATFORM_FEATURES |= CPOpacityRequiresFilterFeature;

    PLATFORM_FEATURES &= ~CPInputTypeCanBeChangedFeature;
}

// WebKit
else if (USER_AGENT.indexOf("AppleWebKit/") != -1)
{
    PLATFORM_ENGINE = CPWebKitBrowserEngine;

    // Features we can only be sure of with WebKit (no known independent tests)
    PLATFORM_FEATURES |= CPCSSRGBAFeature;
    PLATFORM_FEATURES |= CPHTMLContentEditableFeature;

    if (USER_AGENT.indexOf("Chrome") === -1)
        PLATFORM_FEATURES |= CPHTMLDragAndDropFeature;

    PLATFORM_FEATURES |= CPJavascriptClipboardEventsFeature;
    PLATFORM_FEATURES |= CPJavascriptClipboardAccessFeature;
    PLATFORM_FEATURES |= CPJavaScriptShadowFeature;

    var versionStart = USER_AGENT.indexOf("AppleWebKit/") + "AppleWebKit/".length,
        versionEnd = USER_AGENT.indexOf(" ", versionStart),
        versionString = USER_AGENT.substring(versionStart, versionEnd),
        versionDivision = versionString.indexOf('.'),
        majorVersion = parseInt(versionString.substring(0, versionDivision)),
        minorVersion = parseInt(versionString.substr(versionDivision + 1));

    if ((USER_AGENT.indexOf("Safari") !== CPNotFound && (majorVersion > 525 || (majorVersion === 525 && minorVersion > 14))) || USER_AGENT.indexOf("Chrome") !== CPNotFound)
        PLATFORM_FEATURES |= CPJavascriptRemedialKeySupport;

    // FIXME this is a terrible hack to get around this bug:
    // https://bugs.webkit.org/show_bug.cgi?id=21548
    if (![CPPlatform isBrowser])
        PLATFORM_FEATURES |= CPJavascriptRemedialKeySupport;

    if (majorVersion < 532 || (majorVersion === 532 && minorVersion < 6))
        PLATFORM_FEATURES |= CPHTML5DragAndDropSourceYOffBy1;
}

// KHTML
else if (USER_AGENT.indexOf("KHTML") != -1) // Must follow WebKit check.
{
    PLATFORM_ENGINE = CPKHTMLBrowserEngine;
}

// Gecko
else if (USER_AGENT.indexOf("Gecko") !== -1) // Must follow KHTML check.
{
    PLATFORM_ENGINE = CPGeckoBrowserEngine;

    PLATFORM_FEATURES |= CPJavaScriptCanvasDrawFeature;

    var index = USER_AGENT.indexOf("Firefox"),
        version = (index === -1) ? 2.0 : parseFloat(USER_AGENT.substring(index + "Firefox".length + 1));

    if (version >= 3.0)
        PLATFORM_FEATURES |= CPCSSRGBAFeature;

    if (version < 3.0)
        PLATFORM_FEATURES |= CPJavaScriptMouseWheelValues_8_15;
}

// Feature Specific Checks
if (typeof document != "undefined")
{
    var canvasElement = document.createElement("canvas");
    // Detect Canvas Support
    if (canvasElement && canvasElement.getContext)
    {
        PLATFORM_FEATURES |= CPHTMLCanvasFeature;

        // Detect Canvas setTransform/transform support
        var context = document.createElement("canvas").getContext("2d");

        if (context && context.setTransform && context.transform)
            PLATFORM_FEATURES |= CPJavaScriptCanvasTransformFeature;
    }

    var DOMElement = document.createElement("div");

    // Detect whether we have innerText or textContent (or neither)
    if (DOMElement.innerText != undefined)
        PLATFORM_FEATURES |= CPJavascriptInnerTextFeature;
    else if (DOMElement.textContent != undefined)
        PLATFORM_FEATURES |= CPJavascriptTextContentFeature;
}

function CPFeatureIsCompatible(aFeature)
{
    return PLATFORM_FEATURES & aFeature;
}

function CPBrowserIsEngine(anEngine)
{
    return PLATFORM_ENGINE === anEngine;
}

function CPBrowserIsOperatingSystem(anOperatingSystem)
{
    return OPERATING_SYSTEM === anOperatingSystem;
}

OPERATING_SYSTEM = CPOtherOperatingSystem;

if (USER_AGENT.indexOf("Mac") !== -1)
{
    OPERATING_SYSTEM = CPMacOperatingSystem;

    CPPlatformActionKeyMask = CPCommandKeyMask;

    CPUndoKeyEquivalent = @"z";
    CPRedoKeyEquivalent = @"Z";

    CPUndoKeyEquivalentModifierMask = CPCommandKeyMask;
    CPRedoKeyEquivalentModifierMask = CPCommandKeyMask;
}
else
{
    if (USER_AGENT.indexOf("Windows") !== -1)
        OPERATING_SYSTEM = CPWindowsOperatingSystem;

    CPPlatformActionKeyMask = CPControlKeyMask;

    CPUndoKeyEquivalent = @"z";
    CPRedoKeyEquivalent = @"y";

    CPUndoKeyEquivalentModifierMask = CPControlKeyMask;
    CPRedoKeyEquivalentModifierMask = CPControlKeyMask;
}
