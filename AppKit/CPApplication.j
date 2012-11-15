/*
 * CPApplication.j
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

@import <Foundation/CPBundle.j>

@import "CPCompatibility.j"
@import "CPEvent.j"
@import "CPMenu.j"
@import "CPResponder.j"
@import "CPDocumentController.j"
@import "CPThemeBlend.j"
@import "CPCibLoading.j"
@import "CPPlatform.j"


var CPMainCibFile               = @"CPMainCibFile",
    CPMainCibFileHumanFriendly  = @"Main cib file base name",
    CPEventModifierFlags = 0;

CPApp = nil;

CPApplicationWillFinishLaunchingNotification    = @"CPApplicationWillFinishLaunchingNotification";
CPApplicationDidFinishLaunchingNotification     = @"CPApplicationDidFinishLaunchingNotification";
CPApplicationWillTerminateNotification          = @"CPApplicationWillTerminateNotification";
CPApplicationWillBecomeActiveNotification       = @"CPApplicationWillBecomeActiveNotification";
CPApplicationDidBecomeActiveNotification        = @"CPApplicationDidBecomeActiveNotification";
CPApplicationWillResignActiveNotification       = @"CPApplicationWillResignActiveNotification";
CPApplicationDidResignActiveNotification        = @"CPApplicationDidResignActiveNotification";

CPTerminateNow      = YES;
CPTerminateCancel   = NO;
CPTerminateLater    = -1; // not currently supported

CPRunStoppedResponse    = -1000;
CPRunAbortedResponse    = -1001;
CPRunContinuesResponse  = -1002;

/*!
    @ingroup appkit
    @class CPApplication

    CPApplication is THE way to start up the Cappuccino framework for your application to use.
    Every GUI application has exactly one instance of CPApplication (or of a custom subclass of
    CPApplication). Your program's main() function can create that instance by calling the
    \c CPApplicationMain function. A simple example looks like this:

    <pre>
    function main(args, namedArgs)
    {
        CPApplicationMain(args, namedArgs);
    }
    </pre>

    @delegate -(void)applicationDidFinishLaunching:(CPNotification)aNotification;
    Sent from the notification center after the app initializes, but before
    receiving events.
    @param aNotification contains information about the event

    @delegate -(void)applicationWillFinishLaunching:(CPNotification)aNotification;
    Sent from the notification center before the app is initialized.
    @param aNotification contains information about the event
*/
@implementation CPApplication : CPResponder
{
    CPArray                 _eventListeners;

    CPEvent                 _currentEvent;

    CPArray                 _windows;
    CPWindow                _keyWindow;
    CPWindow                _mainWindow;
    CPWindow                _previousKeyWindow;
    CPWindow                _previousMainWindow;

    CPDocumentController    _documentController;

    CPModalSession          _currentSession;

    //
    id                      _delegate;
    BOOL                    _finishedLaunching;
    BOOL                    _isActive;

    CPDictionary            _namedArgs;
    CPArray                 _args;
    CPString                _fullArgsString;

    CPImage                 _applicationIconImage;

    CPPanel                 _aboutPanel;

    CPThemeBlend            _themeBlend @accessors(property=themeBlend);
}

/*!
    Returns the singleton instance of the running application. If it
    doesn't exist, it will be created, and then returned.
    @return the application singleton
*/
+ (CPApplication)sharedApplication
{
    if (!CPApp)
        CPApp = [[CPApplication alloc] init];

    return CPApp;
}

/*!
    Initializes the Document based application with basic menu functions.
    Functions are \c New, \c Open, \c Undo, \c Redo, \c Save, \c Cut, \c Copy, \c Paste.
    @return the initialized application
*/
- (id)init
{
    self = [super init];

    CPApp = self;

    if (self)
    {
        _eventListeners = [];

        _windows = [];

        [_windows addObject:nil];
    }

    return self;
}

// Configuring Applications

/*!
    Sets the delegate for this application. The delegate will receive various notifications
    caused by user interactions during the application's run. The delegate can choose to
    react to these events.
    @param aDelegate the delegate object
*/
- (void)setDelegate:(id)aDelegate
{
    if (_delegate == aDelegate)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter],
        delegateNotifications =
        [
            CPApplicationWillFinishLaunchingNotification, @selector(applicationWillFinishLaunching:),
            CPApplicationDidFinishLaunchingNotification, @selector(applicationDidFinishLaunching:),
            CPApplicationWillBecomeActiveNotification, @selector(applicationWillBecomeActive:),
            CPApplicationDidBecomeActiveNotification, @selector(applicationDidBecomeActive:),
            CPApplicationWillResignActiveNotification, @selector(applicationWillResignActive:),
            CPApplicationDidResignActiveNotification, @selector(applicationDidResignActive:),
            CPApplicationWillTerminateNotification, @selector(applicationWillTerminate:)
        ],
        count = [delegateNotifications count];

    if (_delegate)
    {
        var index = 0;

        for (; index < count; index += 2)
        {
            var notificationName = delegateNotifications[index],
                selector = delegateNotifications[index + 1];

            if ([_delegate respondsToSelector:selector])
                [defaultCenter removeObserver:_delegate name:notificationName object:self];
        }
    }

    _delegate = aDelegate;

    var index = 0;

    for (; index < count; index += 2)
    {
        var notificationName = delegateNotifications[index],
            selector = delegateNotifications[index + 1];

        if ([_delegate respondsToSelector:selector])
            [defaultCenter addObserver:_delegate selector:selector name:notificationName object:self];
    }
}

/*!
    Returns the application's delegate. The app can only have one delegate at a time.
*/
- (id)delegate
{
    return _delegate;
}

/*!
    This method is called by \c -run before the event loop begins.
    When it successfully completes, it posts the notification
    CPApplicationDidFinishLaunchingNotification. If you override
    \c -finishLaunching, the subclass method should invoke the superclass method.
*/
- (void)finishLaunching
{
    // At this point we clear the window.status to eliminate Safari's "Cancelled" error message
    // The message shouldn't be displayed, because only an XHR is cancelled, but it is a usability issue.
    // We do it here so that applications can change it in willFinish or didFinishLaunching
#if PLATFORM(DOM)
    window.status = " ";
#endif

    // We also want to set the default cursor on the body, so that buttons and things don't have an iBeam
    [[CPCursor arrowCursor] set];

    var bundle = [CPBundle mainBundle],
        delegateClassName = [bundle objectForInfoDictionaryKey:@"CPApplicationDelegateClass"];

    if (delegateClassName)
    {
        var delegateClass = objj_getClass(delegateClassName);

        if (delegateClass)
            [self setDelegate:[[delegateClass alloc] init]];
    }

    var defaultCenter = [CPNotificationCenter defaultCenter];

    [defaultCenter
        postNotificationName:CPApplicationWillFinishLaunchingNotification
        object:self];

    var types = [bundle objectForInfoDictionaryKey:@"CPBundleDocumentTypes"];

    if ([types count] > 0)
        _documentController = [CPDocumentController sharedDocumentController];

    var needsUntitled = !!_documentController,
        URLStrings = window.cpOpeningURLStrings && window.cpOpeningURLStrings(),
        index = 0,
        count = [URLStrings count];

    for (; index < count; ++index)
        needsUntitled = ![self _openURL:[CPURL URLWithString:URLStrings[index]]] && needsUntitled;

    if (needsUntitled && [_delegate respondsToSelector:@selector(applicationShouldOpenUntitledFile:)])
        needsUntitled = [_delegate applicationShouldOpenUntitledFile:self];

    if (needsUntitled)
        [_documentController newDocument:self];

    [_documentController _updateRecentDocumentsMenu];

    [defaultCenter
        postNotificationName:CPApplicationDidFinishLaunchingNotification
        object:self];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    _finishedLaunching = YES;
}

- (void)terminate:(id)aSender
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPApplicationWillTerminateNotification
                      object:self];

    if (![CPPlatform isBrowser])
    {
        [[CPDocumentController sharedDocumentController] closeAllDocumentsWithDelegate:self
                                                                  didCloseAllSelector:@selector(_documentController:didCloseAll:context:)
                                                                          contextInfo:nil];
    }
    else
    {
        [[[self keyWindow] platformWindow] _propagateCurrentDOMEvent:YES];
    }
}

/*!
    Sets the applications icon image. This image is used in the default "About" window.
    By default this value is pulled from the CPApplicationIcon key in your info.plist file.

    @param anImage - The image to set.
*/
- (void)setApplicationIconImage:(CPImage)anImage
{
    _applicationIconImage = anImage;
}

/*!
    Returns the application icon image. By default this is pulled from the CPApplicationIcon key of info.plist.
    @return CPImage - Your application icon image.
*/
- (CPImage)applicationIconImage
{
    if (_applicationIconImage)
        return _applicationIconImage;

    var imagePath = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPApplicationIcon"];
    if (imagePath)
        _applicationIconImage = [[CPImage alloc] initWithContentsOfFile:imagePath];

    return _applicationIconImage;
}

/*!
    Opens the standard about panel with no options.
*/
- (void)orderFrontStandardAboutPanel:(id)sender
{
    [self orderFrontStandardAboutPanelWithOptions:nil];
}

/*!
    Opens the standard about panel. This method takes a single argument \c options.
    Options is a dictionary that can contain any of the following keys:
    <pre>
    ApplicationName - The name of your application.
    ApplicationIcon - Application icon image.
    Version - The full version of your application
    ApplicationVersion - The shorter version number of your application.
    Copyright - Human readable copyright information.
    </pre>

    If you choose not the include any of the above keys, they will default
    to the following respective keys in your info.plist file.

    <pre>
    CPBundleName
    CPApplicationIcon (through a call to -applicationIconImage, see documentation for that method for more details)
    CPBundleVersion
    CPBundleShortVersionString
    CPHumanReadableCopyright
    </pre>

    @param options - A dictionary with the aboe listed keys. You can pass nil to default to your plist values.
*/
- (void)orderFrontStandardAboutPanelWithOptions:(CPDictionary)options
{
    if (!_aboutPanel)
    {
        var mainInfo = [[CPBundle mainBundle] infoDictionary],
            applicationTitle = [options objectForKey:"ApplicationName"] || [mainInfo objectForKey:@"CPBundleName"],
            applicationIcon = [options objectForKey:@"ApplicationIcon"] || [self applicationIconImage],
            version = [options objectForKey:@"Version"] || [mainInfo objectForKey:@"CPBundleVersion"],
            applicationVersion = [options objectForKey:@"ApplicationVersion"] || [mainInfo objectForKey:@"CPBundleShortVersionString"],
            copyright = [options objectForKey:@"Copyright"] || [mainInfo objectForKey:@"CPHumanReadableCopyright"];

        var aboutPanelPath = [[CPBundle bundleForClass:[CPWindowController class]] pathForResource:@"AboutPanel.cib"],
            aboutPanelController = [CPWindowController alloc],
            aboutPanelController = [aboutPanelController initWithWindowCibPath:aboutPanelPath owner:aboutPanelController],
            aboutPanel = [aboutPanelController window],
            contentView = [aboutPanel contentView],
            imageView = [contentView viewWithTag:1],
            applicationLabel = [contentView viewWithTag:2],
            versionLabel = [contentView viewWithTag:3],
            copyrightLabel = [contentView viewWithTag:4],
            standardPath = [[CPBundle bundleForClass:[self class]] pathForResource:@"standardApplicationIcon.png"];

        // FIXME move this into the CIB eventually
        [applicationLabel setFont:[CPFont boldSystemFontOfSize:[CPFont systemFontSize] + 2]];
        [applicationLabel setAlignment:CPCenterTextAlignment];
        [versionLabel setAlignment:CPCenterTextAlignment];
        [copyrightLabel setAlignment:CPCenterTextAlignment];

        [imageView setImage:applicationIcon || [[CPImage alloc] initWithContentsOfFile:standardPath
                                                                                  size:CGSizeMake(256, 256)]];

        [applicationLabel setStringValue:applicationTitle || ""];

        if (applicationVersion && version)
            [versionLabel setStringValue:@"Version " + applicationVersion + " (" + version + ")"];
        else if (applicationVersion || version)
            [versionLabel setStringValue:@"Version " + (applicationVersion || version)];
        else
            [versionLabel setStringValue:@""];

        [copyrightLabel setStringValue:copyright || ""];
        [aboutPanel center];

        _aboutPanel = aboutPanel;
    }

    [_aboutPanel orderFront:self];
}


- (void)_documentController:(NSDocumentController *)docController didCloseAll:(BOOL)didCloseAll context:(Object)info
{
    // callback method for terminate:
    if (didCloseAll)
    {
        if ([_delegate respondsToSelector:@selector(applicationShouldTerminate:)])
            [self replyToApplicationShouldTerminate:[_delegate applicationShouldTerminate:self]];
        else
            [self replyToApplicationShouldTerminate:YES];
    }
}

- (void)replyToApplicationShouldTerminate:(BOOL)terminate
{
    if (terminate == CPTerminateNow)
    {
        [[CPNotificationCenter defaultCenter] postNotificationName:CPApplicationWillTerminateNotification object:self];
        [CPPlatform terminateApplication];
    }
}

- (void)activateIgnoringOtherApps:(BOOL)shouldIgnoreOtherApps
{
    [self _willBecomeActive];

    [CPPlatform activateIgnoringOtherApps:shouldIgnoreOtherApps];
    _isActive = YES;

    [self _willResignActive];
}

- (void)deactivate
{
    [self _willResignActive];

    [CPPlatform deactivate];
    _isActive = NO;

    [self _didResignActive];
}

- (void)isActive
{
    return _isActive;
}

- (void)hideOtherApplications:(id)aSender
{
    [CPPlatform hideOtherApplications:self];
}

/*!
    Calls \c -finishLaunching method which results in starting
    the main event loop.
*/
- (void)run
{
    [self finishLaunching];
}

// Managing the Event Loop
/*!
    Starts a modal event loop for \c aWindow
    @param aWindow the window to start the event loop for
*/
- (void)runModalForWindow:(CPWindow)aWindow
{
    [self runModalSession:[self beginModalSessionForWindow:aWindow]];
}

/*!
    Stops the event loop started by \c -runModalForWindow: and
    sets the code that \c -runModalForWindow: will return.
    @param aCode the return code for the modal event
*/
- (void)stopModalWithCode:(int)aCode
{
    if (!_currentSession)
    {
        return;
        // raise exception;
    }

    _currentSession._state = aCode;
    _currentSession = _currentSession._previous;

//    if (aCode == CPRunAbortedResponse)
        [self _removeRunModalLoop];
}

/* @ignore */
- (void)_removeRunModalLoop
{
    var count = _eventListeners.length;

    while (count--)
        if (_eventListeners[count]._callback === _CPRunModalLoop)
        {
            _eventListeners.splice(count, 1);

            return;
        }
}

/*!
    Stops the modal event loop
*/
- (void)stopModal
{
    [self stopModalWithCode:CPRunStoppedResponse]
}

/*!
    Aborts the event loop started by \c -runModalForWindow:
*/
- (void)abortModal
{
    [self stopModalWithCode:CPRunAbortedResponse];
}

/*!
    Sets up a modal session with \c theWindow.
    @param aWindow the window to set up the modal session for
*/
- (CPModalSession)beginModalSessionForWindow:(CPWindow)aWindow
{
    return _CPModalSessionMake(aWindow, 0);
}

/*!
    Runs a modal session
    @param CPModalSession the session to run
*/
- (void)runModalSession:(CPModalSession)aModalSession
{
    aModalSession._previous = _currentSession;
    _currentSession = aModalSession;

    var theWindow = aModalSession._window;

    [theWindow center];
    [theWindow makeKeyWindow];
    [theWindow orderFront:self];

//    [theWindow._bridge _obscureWindowsBelowModalWindow];

    [CPApp setCallback:_CPRunModalLoop forNextEventMatchingMask:CPAnyEventMask untilDate:nil inMode:0 dequeue:NO];
}

/*!
    Returns the window for the current modal session. If there is no
    modal session, it returns \c nil.
*/
- (CPWindow)modalWindow
{
    if (!_currentSession)
        return nil;

    return _currentSession._window;
}

/* @ignore */
- (BOOL)_handleKeyEquivalent:(CPEvent)anEvent
{
    return  [[self keyWindow] performKeyEquivalent:anEvent] ||
            [[self mainMenu] performKeyEquivalent:anEvent];
}

/*!
    Dispatches events to other objects.
    @param anEvent the event to dispatch
*/
- (void)sendEvent:(CPEvent)anEvent
{
    _currentEvent = anEvent;
    CPEventModifierFlags = [anEvent modifierFlags];

#if PLATFORM(DOM)
    var willPropagate = [[[anEvent window] platformWindow] _willPropagateCurrentDOMEvent];

    // temporarily pretend we won't propagate the event. we'll restore the saved value later
    // we do this outside the if so that changes user code might make in _handleKeyEquiv. are preserved
    [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:NO];
#endif

    // Check if this is a candidate for key equivalent...
    if ([anEvent _couldBeKeyEquivalent] && [self _handleKeyEquivalent:anEvent])
    {
#if PLATFORM(DOM)
        var characters = [anEvent characters],
            modifierFlags = [anEvent modifierFlags];

        // Unconditionally propagate on these keys to solve browser copy paste bugs
        if ((characters == "c" || characters == "x" || characters == "v") && (modifierFlags & CPPlatformActionKeyMask))
            [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:YES];
#endif

        return;
    }

#if PLATFORM(DOM)
    // if we make it this far, then restore the original willPropagate value
    [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:willPropagate];
#endif

    if (_eventListeners.length)
    {
        if (_eventListeners[_eventListeners.length - 1]._mask & (1 << [anEvent type]))
            _eventListeners.pop()._callback(anEvent);

        return;
    }

    [[anEvent window] sendEvent:anEvent];
}

/*!
    If the delegate responds to the given selector it will call the method on the delegate,
    otherwise the method will be passed to CPResponder.
*/
- (void)doCommandBySelector:(SEL)aSelector
{
    if ([_delegate respondsToSelector:aSelector])
        [_delegate performSelector:aSelector];
    else
        [super doCommandBySelector:aSelector];
}

/*!
    Returns the key window.
*/
- (CPWindow)keyWindow
{
    return _keyWindow;
}

/*!
    Returns the main window.
*/
- (CPWindow)mainWindow
{
    return _mainWindow;
}

/*!
    Returns the CPWindow object corresponding to \c aWindowNumber.
*/
- (CPWindow)windowWithWindowNumber:(int)aWindowNumber
{
    return _windows[aWindowNumber];
}

/*!
    Returns an array of the application's CPWindows
*/
- (CPArray)windows
{
    return _windows;
}

/*!
    Returns an array of visible CPWindow objects, ordered by their front to back order on the screen.
*/
- (CPArray)orderedWindows
{
#if PLATFORM(DOM)
    return CPWindowObjectList();
#else
    return [];
#endif
}

- (void)hide:(id)aSender
{
    [CPPlatform hide:self];
}

// Accessing the Main Menu
/*!
    Returns the application's main menu
*/
- (CPMenu)mainMenu
{
    return [self menu];
}

/*!
    Sets the main menu for the application
    @param aMenu the menu to set for the application
*/
- (void)setMainMenu:(CPMenu)aMenu
{
    [self setMenu:aMenu];
}

- (void)setMenu:(CPMenu)aMenu
{
    if ([aMenu _menuName] === "CPMainMenu")
    {
        if ([self menu] === aMenu)
            return;

        [super setMenu:aMenu];

        if ([CPPlatform supportsNativeMainMenu])
            window.cpSetMainMenu([self menu]);
    }
    else
        [aMenu _setMenuName:@"CPMainMenu"];
}

/*!
    Opens the shared color panel.
    @param aSender
*/
- (void)orderFrontColorPanel:(id)aSender
{
    [[CPColorPanel sharedColorPanel] orderFront:self];
}

// Posting Actions
/*!
    Tries to perform the action with an argument. Performs
    the action on itself (if it responds to it), then
    tries to perform the action on the delegate.
    @param anAction the action to perform.
    @param anObject the argument for the action
    method
    @return \c YES if the action was performed
*/
- (BOOL)tryToPerform:(SEL)anAction with:(id)anObject
{
    if (!anAction)
        return NO;

    if ([super tryToPerform:anAction with:anObject])
        return YES;

    if ([_delegate respondsToSelector:anAction])
    {
        [_delegate performSelector:anAction withObject:anObject];

        return YES;
    }

    return NO;
}

/*!
    Sends an action to a target.
    @param anAction the action to send
    @param aTarget the target for the action
    @param aSender the action sender
    @return \c YES
*/
- (BOOL)sendAction:(SEL)anAction to:(id)aTarget from:(id)aSender
{
    var target = [self targetForAction:anAction to:aTarget from:aSender];

    if (!target)
        return NO;

    [target performSelector:anAction withObject:aSender];

    return YES;
}

/*!
    Finds a target for the specified action. If the
    action is \c nil, returns \c nil.
    If the target is not \c nil, \c aTarget is
    returned. Otherwise, it calls \c -targetForAction:
    to search for a target.
    @param anAction the action to find a target for
    @param aTarget if not \c nil, this will be returned
    @aSender not used
    @return a target for the action
*/
- (id)targetForAction:(SEL)anAction to:(id)aTarget from:(id)aSender
{
    if (!anAction)
        return nil;

    if (aTarget)
        return aTarget;

    return [self targetForAction:anAction];
}

/*!
    Finds an action-target for a specified window.
    It finds a matching target in the following order:
    <ol>
        <li>the window's first responder</li>
        <li>all the next responders after first responder</li>
        <li>the window</li>
        <li>the window's delegate</li>
        <li>the window's controller</li>
        <li>the window's associated document</li>
    </ol>
    @param aWindow the window to search for a target
    @param anAction the action to find a responder to
    @return the object that responds to the action, or \c nil
    if no matching target was found
    @ignore
*/
- (id)_targetForWindow:(CPWindow)aWindow action:(SEL)anAction
{
    var responder = [aWindow firstResponder],
        checkWindow = YES;

    while (responder)
    {
        if ([responder respondsToSelector:anAction])
            return responder;

        if (responder == aWindow)
            checkWindow = NO;

        responder = [responder nextResponder];
    }

    if (checkWindow && [aWindow respondsToSelector:anAction])
        return aWindow;

    var delegate = [aWindow delegate];

    if ([delegate respondsToSelector:anAction])
        return delegate;

    var windowController = [aWindow windowController];

    if ([windowController respondsToSelector:anAction])
        return windowController;

    var theDocument = [windowController document];
    if (theDocument !== delegate && [theDocument respondsToSelector:anAction])
        return theDocument;

    return nil;
}

/*!
    Looks for a target that can handle the specified action.
    Checks for a target in the following order:
    <ol>
        <li>a responder from the key window</li>
        <li>a responder from the main window</li>
        <li>the CPApplication instance</li>
        <li>the application delegate</li>
        <li>the document controller</li>
    </ol>
    @param anAction the action to handle
    @return a target that can respond, or \c nil
    if no match could be found
*/
- (id)targetForAction:(SEL)anAction
{
    if (!anAction)
        return nil;

    var target = [self _targetForWindow:[self keyWindow] action:anAction];

    if (target)
        return target;

    target = [self _targetForWindow:[self mainWindow] action:anAction];

    if (target)
        return target;

    if ([self respondsToSelector:anAction])
        return self;

    if ([_delegate respondsToSelector:anAction])
        return _delegate;

    if ([_documentController respondsToSelector:anAction])
        return _documentController;

    return nil;
}

/*!
    Fires a callback function when an event matching a given mask occurs.
    @param aCallback - A js function to be fired.
    @prarm aMask - An event mask for the next event.
    @param anExpiration - The date for which this callback expires (not implemented).
    @param inMode (not implemented).
    @param shouldDequeue (not implemented).
*/
- (void)setCallback:(Function)aCallback forNextEventMatchingMask:(unsigned int)aMask untilDate:(CPDate)anExpiration inMode:(CPString)aMode dequeue:(BOOL)shouldDequeue
{
    _eventListeners.push(_CPEventListenerMake(aMask, aCallback));
}

/*!
    Assigns a target and action for the next event matching a given event mask.
    The callback method called will be passed the CPEvent when it fires.

    @param aTarget - The target object for the callback.
    @param aSelector - The selector which should be called on the target object.
    @param aMask - The mask for a given event which should trigger the callback.
    @param anExpiration - The date for which the callback expires (not implemented).
    @param aMode (not implemented).
    @param shouldDequeue (not implemented).
*/
- (void)setTarget:(id)aTarget selector:(SEL)aSelector forNextEventMatchingMask:(unsigned int)aMask untilDate:(CPDate)anExpiration inMode:(CPString)aMode dequeue:(BOOL)shouldDequeue
{
    _eventListeners.push(_CPEventListenerMake(aMask, function (anEvent) { objj_msgSend(aTarget, aSelector, anEvent); }));
}

/*!
    Returns the last event recieved by your application.
*/
- (CPEvent)currentEvent
{
    return _currentEvent;
}

// Managing Sheets

/*!
    Displays a window as a sheet.
    @param aSheet the window to display as a sheet
    @param aWindow the window that will hold the sheet as a child
    @param aModalDelegate
    @param aDidEndSelector
    @param aContextInfo
*/
- (void)beginSheet:(CPWindow)aSheet modalForWindow:(CPWindow)aWindow modalDelegate:(id)aModalDelegate didEndSelector:(SEL)aDidEndSelector contextInfo:(id)aContextInfo
{
    if ([aWindow isSheet])
    {
        [CPException raise:CPInternalInconsistencyException reason:@"The target window of beginSheet: cannot be a sheet"];
        return;
    }

    [aSheet._windowView _enableSheet:YES];

    // -dw- if a sheet is already visible, we skip this since it serves no purpose and causes
    // orderOut: to be called on the sheet, which is not what we want.
    if (![aWindow isVisible])
    {
        [aWindow orderFront:self];
        [aSheet setPlatformWindow:[aWindow platformWindow]];
    }
    [aWindow _attachSheet:aSheet modalDelegate:aModalDelegate didEndSelector:aDidEndSelector contextInfo:aContextInfo];
}

/*!
    Ends a sheet modal.
    The following are predefined return codes:

    <pre>
    CPRunStoppedResponse
    CPRunAbortedResponse
    CPRunContinuesResponse
    </pre>

    @param sheet - The window object (sheet) to dismiss.
    @param returnCode - The return code to send to the delegate. You can use one of the return codes above or a custom value that you define.
*/
- (void)endSheet:(CPWindow)sheet returnCode:(int)returnCode
{
    var count = [_windows count];

    while (--count >= 0)
    {
        var aWindow = [_windows objectAtIndex:count],
            context = aWindow._sheetContext;

        if (context != nil && context["sheet"] === sheet)
        {
            context["returnCode"] = returnCode;
            [aWindow _endSheet];
            return;
        }
    }
}

/*!
    Ends a sheet and sends the return code "0".
    @param sheet - The CPWindow object (sheet) that should be dismissed.
*/
- (void)endSheet:(CPWindow)sheet
{
    // FIX ME: this is wrong: by Cocoa this should be: CPRunStoppedResponse.
   [self endSheet:sheet returnCode:0];
}

/*!
    Returns and array of slash seperated arugments to your application.
    These values are pulled from your window location hash.

    For exampled if your application loaded:
    <pre>
    index.html#280north/cappuccino/issues
    </pre>
    The follow array would be returned:
    <pre>
    ["280north", "cappuccino", "issues"]
    </pre>

    @return CPArray - The array of arguments.
*/
- (CPArray)arguments
{
    if (_fullArgsString !== window.location.hash)
        [self _reloadArguments];

    return _args;
}

/*!
    Sets the arguments of your application.
    That is, set the slash seperated values of an array as the window location hash.

    For example if you pass an array:
    <pre>
    ["280north", "cappuccino", "issues"]
    </pre>

    The new window location would be
    <pre>
    index.html#280north/cappuccino/issues
    </pre>

    @param args - An array of arguments.
*/
- (void)setArguments:(CPArray)args
{
    if (!args || args.length == 0)
    {
        _args = [];
        window.location.hash = @"#";

        return;
    }

    if (![args isKindOfClass:CPArray])
        args = [CPArray arrayWithObject:args];

    _args = args;

    var toEncode = [_args copy];
    for (var i = 0, count = toEncode.length; i < count; i++)
        toEncode[i] = encodeURIComponent(toEncode[i]);

    var hash = [toEncode componentsJoinedByString:@"/"];

    window.location.hash = @"#" + hash;
}

- (void)_reloadArguments
{
    _fullArgsString = window.location.hash;

    if (_fullArgsString.length)
    {
        var args = _fullArgsString.substring(1).split("/");

        for (var i = 0, count = args.length; i < count; i++)
            args[i] = decodeURIComponent(args[i]);

        _args = args;
    }
    else
        _args = [];
}

/*!
    Returns a dictionary of the window location named arguments.
    For example if your location was:
    <pre>
    index.html?owner=280north&repo=cappuccino&type=issues
    </pre>

    a CPDictionary with the keys:
    <pre>
    owner, repo, type
    </pre>
    and respective values:
    <pre>
    280north, cappuccino, issues
    </pre>
    Will be returned.
*/
- (CPDictionary)namedArguments
{
    return _namedArgs;
}

- (BOOL)_openURL:(CPURL)aURL
{
    if (_delegate && [_delegate respondsToSelector:@selector(application:openFile:)])
    {
        CPLog.warn("application:openFile: is deprecated, use application:openURL: instead.");
        return [_delegate application:self openFile:[aURL absoluteString]];
    }

    if (_delegate && [_delegate respondsToSelector:@selector(application:openURL:)])
        return [_delegate application:self openURL:aURL];

    return !![_documentController openDocumentWithContentsOfURL:aURL display:YES error:NULL];
}

- (void)_willBecomeActive
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPApplicationWillBecomeActiveNotification
                                                        object:self
                                                      userInfo:nil];
}

- (void)_didBecomeActive
{
    if (![self keyWindow] && _previousKeyWindow &&
        [[self windows] indexOfObjectIdenticalTo:_previousKeyWindow] !== CPNotFound)
        [_previousKeyWindow makeKeyWindow];

    if (![self mainWindow] && _previousMainWindow &&
        [[self windows] indexOfObjectIdenticalTo:_previousMainWindow] !== CPNotFound)
        [_previousMainWindow makeMainWindow];

    if ([self keyWindow])
        [[self keyWindow] orderFront:self];
    else if ([self mainWindow])
        [[self mainWindow] makeKeyAndOrderFront:self];
    else
        [[self mainMenu]._menuWindow makeKeyWindow]; //FIXME this may not actually work

    _previousKeyWindow = nil;
    _previousMainWindow = nil;

    [[CPNotificationCenter defaultCenter] postNotificationName:CPApplicationDidBecomeActiveNotification
                                                        object:self
                                                      userInfo:nil];
}

- (void)_willResignActive
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPApplicationWillResignActiveNotification
                                                        object:self
                                                      userInfo:nil];
}

- (void)_didResignActive
{
    if (self._activeMenu)
        [self._activeMenu cancelTracking];

    if ([self keyWindow])
    {
        _previousKeyWindow = [self keyWindow];
        [_previousKeyWindow resignKeyWindow];
    }

    if ([self mainWindow])
    {
        _previousMainWindow = [self mainWindow];
        [_previousMainWindow resignMainWindow];
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:CPApplicationDidResignActiveNotification
                                                        object:self
                                                      userInfo:nil];
}

+ (CPString)defaultThemeName
{
    return ([[CPBundle mainBundle] objectForInfoDictionaryKey:"CPDefaultTheme"] || @"Aristo");
}

@end

var _CPModalSessionMake = function(aWindow, aStopCode)
{
    return { _window:aWindow, _state:CPRunContinuesResponse , _previous:nil };
};

var _CPEventListenerMake = function(anEventMask, aCallback)
{
    return { _mask:anEventMask, _callback:aCallback };
};

// Make this a global for use in CPPlatformWindow+DOM.j.
_CPRunModalLoop = function(anEvent)
{
    [CPApp setCallback:_CPRunModalLoop forNextEventMatchingMask:CPAnyEventMask untilDate:nil inMode:0 dequeue:NO];

    var theWindow = [anEvent window],
        modalSession = CPApp._currentSession;

    // The special case for popovers here is not clear. In Cocoa the popover window does not respond YES to worksWhenModal,
    // yet it works when there is a modal window. Maybe it starts its own modal session, but interaction with the original
    // modal window seems to continue working as well. Regardless of correctness, this solution beats popovers not working
    // at all from sheets.
    if (theWindow == modalSession._window ||
        [theWindow worksWhenModal] ||
        [theWindow attachedSheet] == modalSession._window || // -dw- allow modal parent of sheet to be repositioned
        ([theWindow isKindOfClass:_CPAttachedWindow] && [[theWindow targetView] window] === modalSession._window))
        [theWindow sendEvent:anEvent];
};

/*!
    Starts the GUI and Cappuccino frameworks. This function should be
    called from the \c main() function of your program.
    @class CPApplication
    @return void
*/

function CPApplicationMain(args, namedArgs)
{

#if PLATFORM(DOM)
    // hook to allow recorder, etc to manipulate things before starting AppKit
    if (window.parent !== window && typeof window.parent._childAppIsStarting === "function")
    {
        try
        {
            window.parent._childAppIsStarting(window);
        }
        catch(err)
        {
            // This could happen if we're in an iframe without access to the parent frame.
            CPLog.warn("Failed to call parent frame's _childAppIsStarting().");
        }
    }
#endif

    var mainBundle = [CPBundle mainBundle],
        principalClass = [mainBundle principalClass];

    if (!principalClass)
        principalClass = [CPApplication class];

    [principalClass sharedApplication];

    if ([args containsObject:"debug"])
        CPLogRegister(CPLogPopup);

    CPApp._args = args;
    CPApp._namedArgs = namedArgs;

    [_CPAppBootstrapper performActions];
}

var _CPAppBootstrapperActions = nil;

@implementation _CPAppBootstrapper : CPObject
{
}

+ (CPArray)actions
{
    return [@selector(bootstrapPlatform), @selector(loadDefaultTheme), @selector(loadMainCibFile)];
}

+ (void)performActions
{
    if (!_CPAppBootstrapperActions)
        _CPAppBootstrapperActions = [self actions];

    while (_CPAppBootstrapperActions.length)
    {
        var action = _CPAppBootstrapperActions.shift();

        if (objj_msgSend(self, action))
            return;
    }

    [CPApp run];
}

+ (BOOL)bootstrapPlatform
{
    return [CPPlatform bootstrap];
}

+ (BOOL)loadDefaultTheme
{
    var defaultThemeName = [CPApplication defaultThemeName],
        themeURL = nil;

    if (defaultThemeName === @"Aristo")
        themeURL = [[CPBundle bundleForClass:[CPApplication class]] pathForResource:defaultThemeName + @".blend"];
    else
        themeURL = [[CPBundle mainBundle] pathForResource:defaultThemeName + @".blend"];

    var blend = [[CPThemeBlend alloc] initWithContentsOfURL:themeURL];
    [blend loadWithDelegate:self];

    return YES;
}

+ (void)blendDidFinishLoading:(CPThemeBlend)aThemeBlend
{
    [[CPApplication sharedApplication] setThemeBlend:aThemeBlend];
    [CPTheme setDefaultTheme:[CPTheme themeNamed:[CPApplication defaultThemeName]]];

    [self performActions];
}

+ (BOOL)loadMainCibFile
{
    var mainBundle = [CPBundle mainBundle],
        mainCibFile = [mainBundle objectForInfoDictionaryKey:CPMainCibFile] || [mainBundle objectForInfoDictionaryKey:CPMainCibFileHumanFriendly];

    if (mainCibFile)
    {
        [mainBundle loadCibFile:mainCibFile
            externalNameTable:[CPDictionary dictionaryWithObject:CPApp forKey:CPCibOwner]
                 loadDelegate:self];

        return YES;
    }
    else
        [self loadCiblessBrowserMainMenu];

    return NO;
}

+ (void)loadCiblessBrowserMainMenu
{
    var mainMenu = [[CPMenu alloc] initWithTitle:@"MainMenu"];

    // FIXME: We should implement autoenabling.
    [mainMenu setAutoenablesItems:NO];

    var bundle = [CPBundle bundleForClass:[CPApplication class]],
        newMenuItem = [[CPMenuItem alloc] initWithTitle:@"New" action:@selector(newDocument:) keyEquivalent:@"n"];

    [newMenuItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPApplication/New.png"] size:CGSizeMake(16.0, 16.0)]];
    [newMenuItem setAlternateImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPApplication/NewHighlighted.png"] size:CGSizeMake(16.0, 16.0)]];

    [mainMenu addItem:newMenuItem];

    var openMenuItem = [[CPMenuItem alloc] initWithTitle:@"Open" action:@selector(openDocument:) keyEquivalent:@"o"];

    [openMenuItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPApplication/Open.png"] size:CGSizeMake(16.0, 16.0)]];
    [openMenuItem setAlternateImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPApplication/OpenHighlighted.png"] size:CGSizeMake(16.0, 16.0)]];

    [mainMenu addItem:openMenuItem];

    var saveMenu = [[CPMenu alloc] initWithTitle:@"Save"],
        saveMenuItem = [[CPMenuItem alloc] initWithTitle:@"Save" action:@selector(saveDocument:) keyEquivalent:nil];

    [saveMenuItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPApplication/Save.png"] size:CGSizeMake(16.0, 16.0)]];
    [saveMenuItem setAlternateImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPApplication/SaveHighlighted.png"] size:CGSizeMake(16.0, 16.0)]];

    [saveMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Save" action:@selector(saveDocument:) keyEquivalent:@"s"]];
    [saveMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Save As" action:@selector(saveDocumentAs:) keyEquivalent:nil]];

    [saveMenuItem setSubmenu:saveMenu];

    [mainMenu addItem:saveMenuItem];

    var editMenuItem = [[CPMenuItem alloc] initWithTitle:@"Edit" action:nil keyEquivalent:nil],
        editMenu = [[CPMenu alloc] initWithTitle:@"Edit"],

        undoMenuItem = [[CPMenuItem alloc] initWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:CPUndoKeyEquivalent],
        redoMenuItem = [[CPMenuItem alloc] initWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:CPRedoKeyEquivalent];

    [undoMenuItem setKeyEquivalentModifierMask:CPUndoKeyEquivalentModifierMask];
    [redoMenuItem setKeyEquivalentModifierMask:CPRedoKeyEquivalentModifierMask];

    [editMenu addItem:undoMenuItem];
    [editMenu addItem:redoMenuItem];

    [editMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"]];
    [editMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"]];
    [editMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"]];

    [editMenuItem setSubmenu:editMenu];
    [editMenuItem setHidden:YES];

    [mainMenu addItem:editMenuItem];

    [mainMenu addItem:[CPMenuItem separatorItem]];

    [CPApp setMainMenu:mainMenu];
}

+ (void)cibDidFinishLoading:(CPCib)aCib
{
    [self performActions];
}

+ (void)cibDidFailToLoad:(CPCib)aCib
{
    throw new Error("Could not load main cib file (Did you forget to nib2cib it?).");
}

+ (void)reset
{
    _CPAppBootstrapperActions = nil;
}

@end


@implementation CPEvent (CPApplicationModifierFlags)

/*!
    Returns the currently pressed modifier flags.
*/
+ (unsigned)modifierFlags
{
    return CPEventModifierFlags;
}

@end
