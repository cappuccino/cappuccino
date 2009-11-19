
@import <Foundation/CPObject.j>

#include "Platform.h"


@implementation CPPlatform : CPObject
{
}

+ (void)bootstrap
{
#if PLATFORM(DOM)
    var body = document.getElementsByTagName("body")[0];

    body.innerHTML = ""; // Get rid of anything that might be lingering in the body element.
    body.style.overflow = "hidden";

    if (document.documentElement)
        document.documentElement.style.overflow = "hidden";
#endif

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
