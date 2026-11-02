/*
 * CPOpenPanel.j
 * AppKit
 *
 * Created by Ross Boucher.
 * Copyright 2009, 280 North, Inc.
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

@import <Foundation/CPException.j>
@import <Foundation/CPItemProvider.j>
@import <Foundation/CPURL.j>

@import "CPAlert.j"
@import "CPApplication.j"
@import "CPButton.j"
@import "CPPanel.j"
@import "CPPlatformFilePanel.j"
@import "CPStringDrawing.j"
@import "CPTextField.j"

@protocol CPOpenSavePanelDelegate <CPObject>

@optional
- (BOOL)panel:(id)sender validateURL:(CPURL)aURL error:(CPError)outError;

@end

var CPOpenPanelContentWidth     = 420.0,
    CPOpenPanelInset            = 20.0,
    CPOpenPanelSpacing          = 12.0,
    CPOpenPanelButtonWidth      = 90.0,
    CPOpenPanelButtonHeight     = 24.0;

/*
    TODO: Gaps against NSOpenPanel that can be filled:

    - NSOpenPanel is a subclass of NSSavePanel. CPOpenPanel is a subclass of CPPanel, so it does
      not inherit the save panel's properties.
    - The panel's layout metrics are constants in this file. CPAlert takes its metrics from
      theme attributes; the panel should do the same.
    - The alerts that report rejected files open over the modal panel. That case has not been
      verified.
*/

/*!
    @class CPOpenPanel
    @ingroup appkit
    @brief Lets the user choose files to open.

    In a browser, a page cannot open a file by its path, and cannot draw or extend the
    browser's file dialog. The panel works within those limits:

    - The panel is asynchronous. Run it with -beginWithCompletionHandler: or
      -beginSheetModalForWindow:completionHandler:. A browser cannot block while its file
      dialog is open, so -runModal raises an exception.
    - Start the panel from an action method, such as a menu item or button action. The browser
      opens its file dialog only during a user action, and refuses a request made later.
    - When the panel has a message or an accessory view, it shows a Cappuccino panel with them,
      styled by the theme. Its Open button opens the browser's file dialog. Without a message
      or an accessory view, the browser's file dialog opens at once.
    - The chosen files are available as item providers, from -itemProviders. They load the
      files' contents asynchronously.
    - The browser gives no path to a file. Each URL in -URLs holds only the file's name, or its
      path inside a chosen folder, percent-encoded.
    - Allowed file types are a hint to the browser's dialog, which may still let the user choose
      other files. Files of other types are removed from the result, and the user is told.
    - With -canChooseDirectories set and -canChooseFiles not set, the user chooses a folder,
      and the result holds every file in it. A browser gives no item for the folder itself, and
      cannot let the user choose files and folders in one dialog.
    - -directoryURL has no effect. A browser does not let a page choose where its file dialog
      starts.

    The panel's visible window is a separate CPPanel, made when the panel runs, because its
    style differs for a sheet and for a modal panel.

    The panel's delegate is its window delegate, set with -setDelegate:, as in Cocoa. It may
    implement \c panel:validateURL:error: to accept or reject each chosen file.
    Cocoa's other delegate methods, such as \c panel:shouldEnableURL:, need the browser's dialog
    to consult the application while it is open, and are not supported.
*/
@implementation CPOpenPanel : CPPanel
{
    BOOL        _canChooseFiles             @accessors(property=canChooseFiles);
    BOOL        _canChooseDirectories       @accessors(property=canChooseDirectories);
    BOOL        _allowsMultipleSelection    @accessors(property=allowsMultipleSelection);
    CPURL       _directoryURL               @accessors(property=directoryURL);
    CPArray     _allowedFileTypes           @accessors(property=allowedFileTypes);
    CPString    _message                    @accessors(property=message);
    CPString    _prompt                     @accessors(property=prompt);
    CPView      _accessoryView              @accessors(property=accessoryView);
    BOOL        _accessoryViewDisclosed     @accessors(getter=isAccessoryViewDisclosed, setter=setAccessoryViewDisclosed:);

    CPArray     _URLs;
    CPArray     _itemProviders;

    Function    _completionHandler;
    CPPanel     _panelWindow;
    CPButton    _optionsButton;
}

/*!
    Returns a new open panel.
*/
+ (id)openPanel
{
    return [[CPOpenPanel alloc] init];
}

/*!
    Returns YES if a file's name or MIME type matches one of the file types. A file type that
    contains a slash is a MIME type, or a wildcard such as "image/*". Any other file type is a
    file name extension, with or without its leading dot. An empty list matches every file.
    @ignore
*/
+ (BOOL)_fileName:(CPString)aFileName typeIdentifiers:(CPArray)someTypeIdentifiers matchesFileTypes:(CPArray)someFileTypes
{
    if (![someFileTypes count])
        return YES;

    var dotIndex = aFileName ? aFileName.lastIndexOf(".") : -1,
        extension = dotIndex >= 0 ? aFileName.substring(dotIndex + 1).toLowerCase() : nil;

    for (var i = 0, count = [someFileTypes count]; i < count; i++)
    {
        var fileType = someFileTypes[i];

        if (!fileType)
            continue;

        if (fileType.indexOf("/") >= 0)
        {
            for (var j = 0, typeCount = [someTypeIdentifiers count]; j < typeCount; j++)
                if ([CPItemProvider _typeIdentifier:someTypeIdentifiers[j] conformsToTypeIdentifier:fileType])
                    return YES;
        }
        else if (extension && extension === fileType.replace(/^\./, "").toLowerCase())
            return YES;
    }

    return NO;
}

/*!
    Returns a URL that holds a file's name, or its path inside a chosen folder, with each path
    component percent-encoded.
    @ignore
*/
+ (CPURL)_URLForSuggestedName:(CPString)aName
{
    var components = (aName || @"").split("/");

    for (var i = 0; i < components.length; i++)
        components[i] = encodeURIComponent(components[i]);

    return [CPURL URLWithString:components.join("/")];
}

/*!
    Initializes an open panel. It lets the user choose one file, of any type.
*/
- (id)init
{
    if (self = [super init])
    {
        _canChooseFiles = YES;
        _canChooseDirectories = NO;
        _allowsMultipleSelection = NO;
        _accessoryViewDisclosed = NO;
        _URLs = [];
        _itemProviders = [];
    }

    return self;
}

// MARK: Results

/*!
    Returns a URL for each chosen file. A browser gives no path to a file, so each URL holds
    only the file's name, or its path inside a chosen folder. Use -itemProviders to load the
    files' contents.
*/
- (CPArray)URLs
{
    return [_URLs copy];
}

/*!
    Returns the URL of the first chosen file, or nil.
*/
- (CPURL)URL
{
    return [_URLs firstObject];
}

/*!
    Returns an item provider for each chosen file, in the same order as -URLs. Each item
    provider loads its file's contents asynchronously.
*/
- (CPArray)itemProviders
{
    return [_itemProviders copy];
}

// MARK: Running the Panel

/*!
    Raises an exception. A browser cannot block while its file dialog is open. Use
    -beginWithCompletionHandler: or -beginSheetModalForWindow:completionHandler:.
*/
- (CPInteger)runModal
{
    [CPException raise:CPUnsupportedMethodException
                reason:@"-[CPOpenPanel runModal] is not available, because a browser cannot block while its file dialog is open. Use -beginWithCompletionHandler: or -beginSheetModalForWindow:completionHandler:."];
}

/*!
    Runs the panel as a modal panel. When the user chooses files or cancels, \c aHandler is
    called with CPOKButton or CPCancelButton. This method must be called during a user action,
    such as from an action method.

    @param aHandler a function that takes the response
*/
- (void)beginWithCompletionHandler:(Function /*(CPInteger response)*/)aHandler
{
    [self _beginForWindow:nil completionHandler:aHandler];
}

/*!
    Runs the panel as a sheet on \c aWindow. When the user chooses files or cancels, \c aHandler
    is called with CPOKButton or CPCancelButton. This method must be called during a user
    action, such as from an action method.

    @param aWindow the window the sheet is attached to
    @param aHandler a function that takes the response
*/
- (void)beginSheetModalForWindow:(CPWindow)aWindow completionHandler:(Function /*(CPInteger response)*/)aHandler
{
    [self _beginForWindow:aWindow completionHandler:aHandler];
}

/*!
    @ignore
*/
- (void)_beginForWindow:(CPWindow)aWindow completionHandler:(Function)aHandler
{
    _completionHandler = aHandler;
    _URLs = [];
    _itemProviders = [];

    if (!_message && !_accessoryView)
    {
        [self _runFileDialog];
        return;
    }

    [self _createPanelWindowForSheet:!!aWindow];

    if (aWindow)
        [CPApp beginSheet:_panelWindow modalForWindow:aWindow modalDelegate:self didEndSelector:@selector(_sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
    else
    {
        [_panelWindow center];
        [CPApp runModalForWindow:_panelWindow];
    }
}

// MARK: The Panel Window

/*!
    Makes the visible panel: the message, the accessory view, or an Options button that shows
    it, and the Cancel and Open buttons.
    @ignore
*/
- (void)_createPanelWindowForSheet:(BOOL)isSheet
{
    var styleMask = isSheet ? CPDocModalWindowMask : CPTitledWindowMask;

    _panelWindow = [[CPPanel alloc] initWithContentRect:CGRectMake(0.0, 0.0, CPOpenPanelContentWidth, 100.0) styleMask:styleMask];
    [_panelWindow setTitle:[self title] || @"Open"];

    if ([CPApp keyWindow])
        [_panelWindow setPlatformWindow:[[CPApp keyWindow] platformWindow]];

    [self _layoutPanelWindow];
}

/*!
    Lays out the visible panel from the top down, and sizes it to fit.
    @ignore
*/
- (void)_layoutPanelWindow
{
    var contentView = [_panelWindow contentView],
        width = MAX(CPOpenPanelContentWidth, _accessoryView ? CGRectGetWidth([_accessoryView frame]) + 2 * CPOpenPanelInset : 0),
        innerWidth = width - 2 * CPOpenPanelInset,
        y = CPOpenPanelInset;

    [[contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    if (_message)
    {
        var messageField = [CPTextField labelWithTitle:_message],
            messageHeight = [_message sizeWithFont:[messageField font] inWidth:innerWidth].height;

        [messageField setLineBreakMode:CPLineBreakByWordWrapping];
        [messageField setFrame:CGRectMake(CPOpenPanelInset, y, innerWidth, messageHeight + 4.0)];
        [contentView addSubview:messageField];

        y = CGRectGetMaxY([messageField frame]) + CPOpenPanelSpacing;
    }

    if (_accessoryView)
    {
        if (!_optionsButton)
        {
            _optionsButton = [CPButton buttonWithTitle:@"Options"];
            [_optionsButton setTarget:self];
            [_optionsButton setAction:@selector(_toggleAccessoryView:)];
        }

        [_optionsButton setTitle:_accessoryViewDisclosed ? @"Hide Options" : @"Options"];
        [_optionsButton sizeToFit];
        [_optionsButton setFrameOrigin:CGPointMake(CPOpenPanelInset, y)];
        [contentView addSubview:_optionsButton];

        y = CGRectGetMaxY([_optionsButton frame]) + CPOpenPanelSpacing;

        if (_accessoryViewDisclosed)
        {
            [_accessoryView setFrameOrigin:CGPointMake(FLOOR((width - CGRectGetWidth([_accessoryView frame])) / 2), y)];
            [contentView addSubview:_accessoryView];

            y = CGRectGetMaxY([_accessoryView frame]) + CPOpenPanelSpacing;
        }
    }

    var openButton = [CPButton buttonWithTitle:_prompt || @"Open"],
        cancelButton = [CPButton buttonWithTitle:@"Cancel"],
        buttonY = y + CPOpenPanelSpacing;

    [openButton setFrame:CGRectMake(width - CPOpenPanelInset - CPOpenPanelButtonWidth, buttonY, CPOpenPanelButtonWidth, CPOpenPanelButtonHeight)];
    [openButton setTarget:self];
    [openButton setAction:@selector(_open:)];
    [contentView addSubview:openButton];

    [cancelButton setFrame:CGRectMake(CGRectGetMinX([openButton frame]) - CPOpenPanelSpacing - CPOpenPanelButtonWidth, buttonY, CPOpenPanelButtonWidth, CPOpenPanelButtonHeight)];
    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(_cancel:)];
    [cancelButton setKeyEquivalent:CPEscapeFunctionKey];
    [contentView addSubview:cancelButton];

    [_panelWindow setDefaultButton:openButton];

    var contentSize = CGSizeMake(width, CGRectGetMaxY([openButton frame]) + CPOpenPanelInset),
        frame = [[_panelWindow class] frameRectForContentRect:CGRectMake(0.0, 0.0, contentSize.width, contentSize.height) styleMask:[_panelWindow styleMask]];

    [_panelWindow setFrameSize:frame.size];
}

/*!
    Shows or hides the accessory view.
    @ignore
*/
- (@action)_toggleAccessoryView:(id)aSender
{
    _accessoryViewDisclosed = !_accessoryViewDisclosed;
    [self _layoutPanelWindow];
}

/*!
    Opens the browser's file dialog. The click on the Open button is the user action the
    browser requires.
    @ignore
*/
- (@action)_open:(id)aSender
{
    [self _runFileDialog];
}

/*!
    @ignore
*/
- (@action)_cancel:(id)aSender
{
    [self _endWithResponse:CPCancelButton];
}

// MARK: The Browser's File Dialog

/*!
    @ignore
*/
- (void)_runFileDialog
{
    var choosesDirectory = _canChooseDirectories && !_canChooseFiles;

    [CPPlatformFilePanel runWithFileTypes:_allowedFileTypes
                  allowsMultipleSelection:_allowsMultipleSelection
                         choosesDirectory:choosesDirectory
                        completionHandler:function(itemProviders)
    {
        [self _fileDialogDidEndWithItemProviders:itemProviders];
    }];
}

/*!
    Handles the result of the browser's file dialog. When the user cancels it, a visible panel
    stays open, so the user may choose again or cancel the panel. Without a visible panel, the
    panel ends.
    @ignore
*/
- (void)_fileDialogDidEndWithItemProviders:(CPArray)someItemProviders
{
    if (![someItemProviders count])
    {
        if (!_panelWindow)
            [self _endWithResponse:CPCancelButton];

        return;
    }

    var acceptedItemProviders = [],
        rejectedNames = [];

    for (var i = 0, count = [someItemProviders count]; i < count; i++)
    {
        var itemProvider = someItemProviders[i];

        if ([CPOpenPanel _fileName:[itemProvider suggestedName] typeIdentifiers:[itemProvider registeredTypeIdentifiers] matchesFileTypes:_allowedFileTypes])
            acceptedItemProviders.push(itemProvider);
        else
            rejectedNames.push([itemProvider suggestedName]);
    }

    if ([rejectedNames count])
    {
        [self _showRejectionOfNames:rejectedNames thenAcceptItemProviders:acceptedItemProviders];
        return;
    }

    [self _validateAndAcceptItemProviders:acceptedItemProviders];
}

/*!
    Tells the user which files were removed because their type is not allowed, then goes on
    with the other files.
    @ignore
*/
- (void)_showRejectionOfNames:(CPArray)someNames thenAcceptItemProviders:(CPArray)someItemProviders
{
    var alert = [CPAlert alertWithError:@"These files cannot be opened here: " + someNames.join(", ")];

    [alert setInformativeText:@"Choose files of these types: " + _allowedFileTypes.join(", ")];
    [alert runModalWithDidEndBlock:function(anAlert, aReturnCode)
    {
        [self _validateAndAcceptItemProviders:someItemProviders];
    }];
}

/*!
    Asks the delegate to validate each file. If every file is accepted, the panel ends with
    CPOKButton. If the delegate rejects a file, the user is told why.
    @ignore
*/
- (void)_validateAndAcceptItemProviders:(CPArray)someItemProviders
{
    if (![someItemProviders count])
    {
        if (!_panelWindow)
            [self _endWithResponse:CPCancelButton];

        return;
    }

    var URLs = [];

    for (var i = 0, count = [someItemProviders count]; i < count; i++)
    {
        var URL = [CPOpenPanel _URLForSuggestedName:[someItemProviders[i] suggestedName]],
            error = nil;

        if ([_delegate respondsToSelector:@selector(panel:validateURL:error:)] && ![_delegate panel:self validateURL:URL error:@ref(error)])
        {
            var alert = [CPAlert alertWithError:[error localizedDescription] || @"The file " + [someItemProviders[i] suggestedName] + @" cannot be opened."];

            [alert runModalWithDidEndBlock:function(anAlert, aReturnCode)
            {
                if (!_panelWindow)
                    [self _endWithResponse:CPCancelButton];
            }];

            return;
        }

        URLs.push(URL);
    }

    _URLs = URLs;
    _itemProviders = someItemProviders;

    [self _endWithResponse:CPOKButton];
}

/*!
    Closes the visible panel, if there is one, and calls the completion handler once.
    @ignore
*/
- (void)_endWithResponse:(CPInteger)aResponse
{
    if (_panelWindow && [_panelWindow isSheet])
    {
        [_panelWindow orderOut:nil];
        [CPApp endSheet:_panelWindow returnCode:aResponse];
        return;
    }

    if (_panelWindow)
    {
        [CPApp abortModal];
        [_panelWindow close];
        _panelWindow = nil;
    }

    [self _callCompletionHandlerWithResponse:aResponse];
}

/*!
    @ignore
*/
- (void)_sheetDidEnd:(CPWindow)aSheet returnCode:(CPInteger)aResponse contextInfo:(id)contextInfo
{
    _panelWindow = nil;
    [self _callCompletionHandlerWithResponse:aResponse];
}

/*!
    @ignore
*/
- (void)_callCompletionHandlerWithResponse:(CPInteger)aResponse
{
    var handler = _completionHandler;

    _completionHandler = nil;

    if (aResponse !== CPOKButton)
    {
        _URLs = [];
        _itemProviders = [];
    }

    if (handler)
        handler(aResponse);
}

@end
