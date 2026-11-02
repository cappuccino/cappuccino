/*
 *  CPPlatformFilePanel.j
 *  AppKit
 *
 *  Created by David Richardson on 2026-11-02.
 *  Copyright David Richardson 2026.
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
@import <Foundation/CPItemProvider.j>
@import <Foundation/CPRunLoop.j>

@import "CPCompatibility.j"

@global document

var CPPlatformFilePanelPendingRun = nil;

/*
    This class runs the browser's file dialog for CPOpenPanel. It isolates the DOM details:

    - A page cannot draw or extend the browser's file dialog. It can only open it, through a
      hidden file input element.
    - The browser opens the dialog only during a user action, such as a click or a key press.
      Cappuccino handles events synchronously inside the DOM event handler, so an action method
      may open the dialog. A request made later, from a timer or after any asynchronous step, is
      refused. The browser gives no error for a refused click(), so showPicker() is used where
      it exists, because it reports the refusal.
    - The dialog reports its result from outside the run loop: "change" with the chosen files,
      or "cancel". The completion handler is called inside a run loop pass.
    - The dialog is modal to the page, so only one can be open. A new request ends an earlier
      one that never reported a result, as cancelled.
*/
/*
    TODO: Browsers that do not send "cancel" to a file input, such as Safari before 16.4 and
    Chrome before 113, never report a cancelled dialog. The run then stays pending until the next
    run ends it. Decide whether to support them with a fallback, such as watching for the window
    to regain focus.
*/
@implementation CPPlatformFilePanel : CPObject
{
}

/*!
    Returns the value of the file input's accept attribute for a list of file types. A file
    type that contains a slash is a MIME type, or a wildcard such as "image/*", and is used as
    it is. Any other file type is a file name extension, with or without its leading dot.
    @ignore
*/
+ (CPString)_acceptStringForFileTypes:(CPArray)someFileTypes
{
    if (!someFileTypes)
        return @"";

    var accept = [];

    for (var i = 0, count = [someFileTypes count]; i < count; i++)
    {
        var fileType = someFileTypes[i];

        if (!fileType)
            continue;

        if (fileType.indexOf("/") >= 0 || fileType.charAt(0) === ".")
            accept.push(fileType);
        else
            accept.push("." + fileType);
    }

    return accept.join(",");
}

/*!
    Opens the browser's file dialog. When it closes, \c aCompletionHandler is called with an
    array of item providers for the chosen files, in the order the browser gives them, or with
    nil when the user cancels.

    This method must be called during a user action. Where no DOM is available, the completion
    handler is called at once with nil.

    @param someFileTypes MIME types, wildcards such as "image/*", or file name extensions. This
           is a hint to the dialog: the user may still choose other files.
    @param allowsMultipleSelection YES to let the user choose more than one file
    @param choosesDirectory YES to let the user choose a folder. The result then holds every
           file in the folder, each named by its path inside the folder.
    @param aCompletionHandler a function that takes an array of item providers, or nil
*/
+ (void)runWithFileTypes:(CPArray)someFileTypes allowsMultipleSelection:(BOOL)allowsMultipleSelection choosesDirectory:(BOOL)choosesDirectory completionHandler:(Function /*(CPArray itemProviders)*/)aCompletionHandler
{
    if (!CPDOMAvailable)
    {
        aCompletionHandler(nil);
        return;
    }

    if (CPPlatformFilePanelPendingRun)
        [self _finishRun:CPPlatformFilePanelPendingRun withFiles:nil];

    var input = document.createElement("input"),
        style = input.style,
        run = { input: input, completionHandler: aCompletionHandler };

    input.type = "file";
    input.accept = [self _acceptStringForFileTypes:someFileTypes];
    input.multiple = !!allowsMultipleSelection;

    if (choosesDirectory)
        input.webkitdirectory = YES;

    /*
        The input is placed in the document, outside the visible area, rather than hidden with
        display: none. Some browsers do not open the dialog for an input that is not rendered,
        and do not send "cancel" to an input that is not in the document.
    */
    style.position = "absolute";
    style.left = "-10000px";
    style.top = "0px";
    style.width = "1px";
    style.height = "1px";
    style.opacity = "0";

    input.addEventListener("change", function()
    {
        [CPPlatformFilePanel _finishRun:run withFiles:input.files];
    });

    input.addEventListener("cancel", function()
    {
        [CPPlatformFilePanel _finishRun:run withFiles:nil];
    });

    CPPlatformFilePanelPendingRun = run;
    document.body.appendChild(input);

    if (typeof input.showPicker === "function")
    {
        try
        {
            input.showPicker();
        }
        catch (anException)
        {
            CPLog.warn("CPOpenPanel: the browser refused to open its file dialog. It must be opened during a user action, such as a click. " + anException);
            [self _finishRun:run withFiles:nil];
        }
    }
    else
        input.click();
}

/*!
    Ends a run of the file dialog, and calls its completion handler with item providers for the
    files, or with nil when there are none. A run ends only once.
    @ignore
*/
+ (void)_finishRun:(JSObject)aRun withFiles:(FileList)someFiles
{
    if (aRun.isFinished)
        return;

    aRun.isFinished = YES;

    if (CPPlatformFilePanelPendingRun === aRun)
        CPPlatformFilePanelPendingRun = nil;

    if (aRun.input.parentNode)
        aRun.input.parentNode.removeChild(aRun.input);

    var itemProviders = someFiles && someFiles.length ? [CPItemProvider _itemProvidersWithFiles:someFiles] : nil;

    aRun.completionHandler(itemProviders);

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

@end
