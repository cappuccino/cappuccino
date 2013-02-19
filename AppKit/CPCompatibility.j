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

@import "CPEvent_Constants.j"
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
CPCSSRGBAFeature                        = 5;

CPHTMLCanvasFeature                     = 6;
CPHTMLContentEditableFeature            = 7;
CPHTMLDragAndDropFeature                = 8;

CPJavaScriptInnerTextFeature            = 9;
CPJavaScriptTextContentFeature          = 10;
CPJavaScriptClipboardEventsFeature      = 11;
CPJavaScriptClipboardAccessFeature      = 12;
CPJavaScriptCanvasDrawFeature           = 13;
CPJavaScriptCanvasTransformFeature      = 14;

CPVMLFeature                            = 15;

CPJavaScriptRemedialKeySupport          = 16;
CPJavaScriptShadowFeature               = 20;

CPJavaScriptNegativeMouseWheelValues    = 22;
CPJavaScriptMouseWheelValues_8_15       = 23;

CPOpacityRequiresFilterFeature          = 24;

// Internet explorer does not allow dynamically changing the type of an input element
CPInputTypeCanBeChangedFeature          = 25;
CPHTML5DragAndDropSourceYOffBy1         = 26;

CPSOPDisabledFromFileURLs               = 27;

// element.style.font can be set for an element not in the DOM.
CPInputSetFontOutsideOfDOM              = 28;

// Input elements have 1 px of extra padding on the left regardless of padding setting.
CPInput1PxLeftPadding                   = 29;
CPInputOnInputEventFeature              = 30;

CPFileAPIFeature                        = 31;

/*
    When an absolutely positioned div (CPView) with an absolutely positioned canvas in it (CPView with drawRect:) moves things on top of the canvas (subviews) don't redraw correctly. E.g. if you have a bunch of text fields in a CPBox in a sheet which animates in, some of the text fields might not be visible because the CPBox has a canvas at the bottom and the box moved form offscreen to onscreen. This bug is probably very related: https://bugs.webkit.org/show_bug.cgi?id=67203
*/
CPCanvasParentDrawErrorsOnMovementBug   = 1 << 0;

var USER_AGENT                          = "",
    PLATFORM_ENGINE                     = CPUnknownBrowserEngine,
    PLATFORM_FEATURES                   = [],
    PLATFORM_BUGS                       = 0,
    PLATFORM_STYLE_JS_PROPERTIES        = {};

// default these features to true
PLATFORM_FEATURES[CPInputTypeCanBeChangedFeature] = YES;
PLATFORM_FEATURES[CPInputSetFontOutsideOfDOM] = YES;

if (typeof window !== "undefined" && typeof window.navigator !== "undefined")
    USER_AGENT = window.navigator.userAgent;

// Opera
if (typeof window !== "undefined" && window.opera)
{
    PLATFORM_ENGINE = CPOperaBrowserEngine;

    PLATFORM_FEATURES[CPJavaScriptCanvasDrawFeature] = YES;
}

// Internet Explorer
else if (typeof window !== "undefined" && window.attachEvent) // Must follow Opera check.
{
    PLATFORM_ENGINE = CPInternetExplorerBrowserEngine;

    // Features we can only be sure of with IE (no known independent tests)
    PLATFORM_FEATURES[CPVMLFeature] = YES;
    PLATFORM_FEATURES[CPJavaScriptRemedialKeySupport] = YES;
    PLATFORM_FEATURES[CPJavaScriptShadowFeature] = YES;

    PLATFORM_FEATURES[CPOpacityRequiresFilterFeature] = YES;

    PLATFORM_FEATURES[CPInputTypeCanBeChangedFeature] = NO;

    // Tested in Internet Explore 8 and 9.
    PLATFORM_FEATURES[CPInputSetFontOutsideOfDOM] = NO;
}

// WebKit
else if (USER_AGENT.indexOf("AppleWebKit/") != -1)
{
    PLATFORM_ENGINE = CPWebKitBrowserEngine;

    // Features we can only be sure of with WebKit (no known independent tests)
    PLATFORM_FEATURES[CPCSSRGBAFeature] = YES;
    PLATFORM_FEATURES[CPHTMLContentEditableFeature] = YES;

    if (USER_AGENT.indexOf("Chrome") === -1)
        PLATFORM_FEATURES[CPHTMLDragAndDropFeature] = YES;

    PLATFORM_FEATURES[CPJavaScriptClipboardEventsFeature] = YES;
    PLATFORM_FEATURES[CPJavaScriptClipboardAccessFeature] = YES;
    PLATFORM_FEATURES[CPJavaScriptShadowFeature] = YES;

    var versionStart = USER_AGENT.indexOf("AppleWebKit/") + "AppleWebKit/".length,
        versionEnd = USER_AGENT.indexOf(" ", versionStart),
        versionString = USER_AGENT.substring(versionStart, versionEnd),
        versionDivision = versionString.indexOf('.'),
        majorVersion = parseInt(versionString.substring(0, versionDivision)),
        minorVersion = parseInt(versionString.substr(versionDivision + 1));

    if ((USER_AGENT.indexOf("Safari") !== CPNotFound && (majorVersion > 525 || (majorVersion === 525 && minorVersion > 14))) || USER_AGENT.indexOf("Chrome") !== CPNotFound)
        PLATFORM_FEATURES[CPJavaScriptRemedialKeySupport] = YES;

    // FIXME this is a terrible hack to get around this bug:
    // https://bugs.webkit.org/show_bug.cgi?id=21548
    if (![CPPlatform isBrowser])
        PLATFORM_FEATURES[CPJavaScriptRemedialKeySupport] = YES;

    if (majorVersion < 532 || (majorVersion === 532 && minorVersion < 6))
        PLATFORM_FEATURES[CPHTML5DragAndDropSourceYOffBy1] = YES;

    // This is supposedly fixed in webkit r123603. Seems to work in Chrome 21 but not Safari 6.0.
    if (majorVersion < 537)
        PLATFORM_FEATURES[CPInput1PxLeftPadding] = YES;

    if (USER_AGENT.indexOf("Chrome") === CPNotFound)
        PLATFORM_FEATURES[CPSOPDisabledFromFileURLs] = YES;

    // Assume this bug was introduced around Safari 5.1/Chrome 16. This could probably be tighter.
    if (majorVersion > 533)
        PLATFORM_BUGS |= CPCanvasParentDrawErrorsOnMovementBug;
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

    PLATFORM_FEATURES[CPJavaScriptCanvasDrawFeature] = YES;

    var index = USER_AGENT.indexOf("Firefox"),
        version = (index === -1) ? 2.0 : parseFloat(USER_AGENT.substring(index + "Firefox".length + 1));

    if (version >= 3.0)
        PLATFORM_FEATURES[CPCSSRGBAFeature] = YES;

    if (version < 3.0)
        PLATFORM_FEATURES[CPJavaScriptMouseWheelValues_8_15] = YES;

    // Some day this might be fixed and should be version prefixed. No known fixed version yet.
    PLATFORM_FEATURES[CPInput1PxLeftPadding] = YES;
}

// Feature-specific checks
if (typeof document != "undefined")
{
    var canvasElement = document.createElement("canvas");

    // Detect canvas support
    if (canvasElement && canvasElement.getContext)
    {
        PLATFORM_FEATURES[CPHTMLCanvasFeature] = YES;

        // Any browser that supports canvas supports CSS opacity
        PLATFORM_FEATURES[CPOpacityRequiresFilterFeature] = NO;

        // Detect canvas setTransform/transform support
        var context = document.createElement("canvas").getContext("2d");

        if (context && context.setTransform && context.transform)
            PLATFORM_FEATURES[CPJavaScriptCanvasTransformFeature] = YES;
    }

    var DOMElement = document.createElement("div");

    // Detect whether we have innerText or textContent (or neither)
    if (DOMElement.innerText != undefined)
        PLATFORM_FEATURES[CPJavaScriptInnerTextFeature] = YES;
    else if (DOMElement.textContent != undefined)
        PLATFORM_FEATURES[CPJavaScriptTextContentFeature] = YES;

    var DOMInputElement = document.createElement("input");

    if ("oninput" in DOMInputElement)
        PLATFORM_FEATURES[CPInputOnInputEventFeature] = YES;
    else if (typeof DOMInputElement.setAttribute === "function")
    {
        DOMInputElement.setAttribute("oninput", "return;");

        if (typeof DOMInputElement.oninput === "function")
            PLATFORM_FEATURES[CPInputOnInputEventFeature] = YES;
    }

    // Detect FileAPI support
    if (typeof DOMInputElement.setAttribute === "function")
    {
        DOMInputElement.setAttribute("type", "file");
        PLATFORM_FEATURES[CPFileAPIFeature] = !!DOMInputElement["files"];
    }
    else
        PLATFORM_FEATURES[CPFileAPIFeature] = NO;
}

function CPFeatureIsCompatible(aFeature)
{
    return !!PLATFORM_FEATURES[aFeature];
}

function CPPlatformHasBug(aBug)
{
    return PLATFORM_BUGS & aBug;
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

/*!
    Return the properly prefixed JS property for the given name. E.g. in a webkit browser,
    CPBrowserStyleProperty('transition') -> WebkitTransition

    While technically not a style property, style related event handler names are also supported.
    CPBrowserStyleProperty('transitionend') -> 'webkitTransitionEnd'

    CSS is only available in platform(dom), so don't rely too heavily on it.
*/
function CPBrowserStyleProperty(aProperty)
{
    var lowerProperty = aProperty.toLowerCase();

    if (PLATFORM_STYLE_JS_PROPERTIES[lowerProperty] === undefined)
    {
        var r = nil;

#if PLATFORM(DOM)
        var testElement = document.createElement('div');

        switch (lowerProperty)
        {
            case 'transitionend':
                var candidates = {
                        'WebkitTransition' : 'webkitTransitionEnd',
                        'MozTransition'    : 'transitionend',
                        'OTransition'      : 'oTransitionEnd',
                        'msTransition'     : 'MSTransitionEnd',
                        'transition'       : 'transitionend'
                    };

                r = candidates[PLATFORM_STYLE_JS_PROPERTIES['transition']] || nil;
                break;
            default:
                var prefixes = ["Webkit", "Moz", "O", "ms"],
                    strippedProperty = aProperty.split('-').join(' '),
                    capProperty = [strippedProperty capitalizedString].split(' ').join('');

                for (var i = 0; i < prefixes.length; i++)
                {
                    // First check if the property is already valid without being formatted, otherwise try the capitalized property
                    if (prefixes[i] + aProperty in testElement.style)
                    {
                        r = prefixes[i] + aProperty;
                        break;
                    }
                    else if (prefixes[i] + capProperty in testElement.style)
                    {
                        r = prefixes[i] + capProperty;
                        break;
                    }
                }

                if (!r && lowerProperty in testElement.style)
                    r = lowerProperty;

                break;
        }
#endif

        PLATFORM_STYLE_JS_PROPERTIES[lowerProperty] = r;
    }

    return PLATFORM_STYLE_JS_PROPERTIES[lowerProperty];
}

function CPBrowserCSSProperty(aProperty)
{
    var browserProperty = CPBrowserStyleProperty(aProperty);

    if (!browserProperty)
        return nil;

    var prefixes = {
            'Webkit': '-webkit-',
            'Moz': '-moz-',
            'O': '-o-',
            'ms': '-ms-'
        };

    for (var prefix in prefixes)
    {
        if (browserProperty.substring(0, prefix.length) == prefix)
        {
            var browserPropertyWithoutPrefix = browserProperty.substring(prefix.length),
                parts = browserPropertyWithoutPrefix.match(/[A-Z][a-z]+/g);

            // If there were any capitalized words in the browserProperty, insert a "-" between each one
            if (parts && parts.length > 0)
                browserPropertyWithoutPrefix = parts.join("-");

            return prefixes[prefix] + browserPropertyWithoutPrefix.toLowerCase();
        }
    }

    var parts = browserProperty.match(/[A-Z][a-z]+/g);

    if (parts && parts.length > 0)
        browserProperty = parts.join("-");

    return browserProperty.toLowerCase();
}
