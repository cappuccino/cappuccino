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
    CPMainCibFileHumanFriendly  = @"Main cib file base name";

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

    CPApplication is THE way to start up the Cappucino framework for your application to use.
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
    
    CPMenu                  _mainMenu;
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
    
    if (self)
    {
        _eventListeners = [];
        
        _windows = [];
        
        [_windows addObject:nil];
    
        // FIXME: This should be read from the cib.
        _mainMenu = [[CPMenu alloc] initWithTitle:@"MainMenu"];
        
        // FIXME: We should implement autoenabling.
        [_mainMenu setAutoenablesItems:NO];

        var bundle = [CPBundle bundleForClass:[CPApplication class]],
            newMenuItem = [[CPMenuItem alloc] initWithTitle:@"New" action:@selector(newDocument:) keyEquivalent:@"N"];

        [newMenuItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPApplication/New.png"] size:CGSizeMake(16.0, 16.0)]];
        [newMenuItem setAlternateImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPApplication/NewHighlighted.png"] size:CGSizeMake(16.0, 16.0)]];

        [_mainMenu addItem:newMenuItem];
        
        var openMenuItem = [[CPMenuItem alloc] initWithTitle:@"Open" action:@selector(openDocument:) keyEquivalent:@"O"];
        
        [openMenuItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPApplication/Open.png"] size:CGSizeMake(16.0, 16.0)]];
        [openMenuItem setAlternateImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPApplication/OpenHighlighted.png"] size:CGSizeMake(16.0, 16.0)]];
        
        [_mainMenu addItem:openMenuItem];
        
        var saveMenu = [[CPMenu alloc] initWithTitle:@"Save"],
            saveMenuItem = [[CPMenuItem alloc] initWithTitle:@"Save" action:@selector(saveDocument:) keyEquivalent:nil];
        
        [saveMenuItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPApplication/Save.png"] size:CGSizeMake(16.0, 16.0)]];
        [saveMenuItem setAlternateImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPApplication/SaveHighlighted.png"] size:CGSizeMake(16.0, 16.0)]];        
        
        [saveMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Save" action:@selector(saveDocument:) keyEquivalent:@"S"]];
        [saveMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Save As" action:@selector(saveDocumentAs:) keyEquivalent:nil]];
        
        [saveMenuItem setSubmenu:saveMenu];
        
        [_mainMenu addItem:saveMenuItem];
        
        var editMenuItem = [[CPMenuItem alloc] initWithTitle:@"Edit" action:nil keyEquivalent:nil],
            editMenu = [[CPMenu alloc] initWithTitle:@"Edit"],
            
            undoMenuItem = [[CPMenuItem alloc] initWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:CPUndoKeyEquivalent],
            redoMenuItem = [[CPMenuItem alloc] initWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:CPRedoKeyEquivalent];

        [undoMenuItem setKeyEquivalentModifierMask:CPUndoKeyEquivalentModifierMask];        
        [redoMenuItem setKeyEquivalentModifierMask:CPRedoKeyEquivalentModifierMask];
        
        [editMenu addItem:undoMenuItem];
        [editMenu addItem:redoMenuItem];
        
        [editMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"X"]],
        [editMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"C"]],
        [editMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"V"]];
    
        [editMenuItem setSubmenu:editMenu];
        [editMenuItem setHidden:YES];
        
        [_mainMenu addItem:editMenuItem];
        
        [_mainMenu addItem:[CPMenuItem separatorItem]];
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
    
    var defaultCenter = [CPNotificationCenter defaultCenter];
    
    if (_delegate)
    {
        [defaultCenter
            removeObserver:_delegate
                      name:CPApplicationWillFinishLaunchingNotification
                    object:self];

        [defaultCenter
            removeObserver:_delegate
                      name:CPApplicationDidFinishLaunchingNotification
                    object:self];

        [defaultCenter
            removeObserver:_delegate
                      name:CPApplicationWillBecomeActiveNotification
                    object:self];

        [defaultCenter
            removeObserver:_delegate
                      name:CPApplicationDidBecomeActiveNotification
                    object:self];

        [defaultCenter
            removeObserver:_delegate
                      name:CPApplicationWillResignActiveNotification
                    object:self];

        [defaultCenter
            removeObserver:_delegate
                      name:CPApplicationDidResignActiveNotification
                    object:self];
    }
    
    _delegate = aDelegate;
    
    if ([_delegate respondsToSelector:@selector(applicationWillFinishLaunching:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(applicationWillFinishLaunching:)
                   name:CPApplicationWillFinishLaunchingNotification
                 object:self];
    
    if ([_delegate respondsToSelector:@selector(applicationDidFinishLaunching:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(applicationDidFinishLaunching:)
                   name:CPApplicationDidFinishLaunchingNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(applicationWillBecomeActive:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(applicationWillBecomeActive:)
                   name:CPApplicationWillBecomeActiveNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(applicationDidBecomeActive:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(applicationDidBecomeActive:)
                   name:CPApplicationDidBecomeActiveNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(applicationWillResignActive:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(applicationWillResignActive:)
                   name:CPApplicationWillResignActiveNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(applicationDidResignActive:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(applicationDidResignActive:)
                   name:CPApplicationDidResignActiveNotification
                 object:self];
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
    window.status = " ";

    // We also want to set the default cursor on the body, so that buttons and things don't have an iBeam
    [[CPCursor arrowCursor] set];
    
    var bundle = [CPBundle mainBundle],
        types = [bundle objectForInfoDictionaryKey:@"CPBundleDocumentTypes"];
        
    if ([types count] > 0)
        _documentController = [CPDocumentController sharedDocumentController];
        
    var delegateClassName = [bundle objectForInfoDictionaryKey:@"CPApplicationDelegateClass"];
    
    if (delegateClassName)
    {
        var delegateClass = objj_getClass(delegateClassName);
        
        if (delegateClass)
            if ([_documentController class] == delegateClass)
                [self setDelegate:_documentController];
            else
                [self setDelegate:[[delegateClass alloc] init]];
    }
    
    var defaultCenter = [CPNotificationCenter defaultCenter];
    
    [defaultCenter
        postNotificationName:CPApplicationWillFinishLaunchingNotification
        object:self];

    var needsUntitled = !!_documentController,
        URLStrings = window.cpOpeningURLStrings && window.cpOpeningURLStrings(),
        index = 0,
        count = [URLStrings count];

    for (; index < count; ++index)
        needsUntitled = ![self _openURL:[CPURL URLWithString:URLStrings[index]]] || needsUntitled;

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

- (void)setApplicationIconImage:(CPImage)anImage
{
    _applicationIconImage = anImage;
}

- (CPImage)applicationIconImage
{
    if (_applicationIconImage)
        return _applicationIconImage;

    var imagePath = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPApplicationIcon"];
    if (imagePath)
        _applicationIconImage = [[CPImage alloc] initWithContentsOfFile:imagePath];

    return _applicationIconImage;
}

- (void)orderFrontStandardAboutPanel:(id)sender
{
    [self orderFrontStandardAboutPanelWithOptions:nil];
}

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

        var aboutPanelController = [[CPWindowController alloc] initWithWindowCibName:@"AboutPanel"],
            aboutPanel = [aboutPanelController window],
            contentView = [aboutPanel contentView],
            imageView = [contentView viewWithTag:1],
            applicationLabel = [contentView viewWithTag:2],
            versionLabel = [contentView viewWithTag:3],
            copyrightLabel = [contentView viewWithTag:4],
            standardPath = [[CPBundle bundleForClass:[self class]] pathForResource:@"standardApplicationIcon.png"];
    
        // FIXME move this into the CIB eventually
        [applicationLabel setFont:[CPFont boldSystemFontOfSize:14.0]];
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
    [theWindow makeKeyAndOrderFront:self];
    
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
            [_mainMenu performKeyEquivalent:anEvent];
}

/*!
    Dispatches events to other objects.
    @param anEvent the event to dispatch
*/
- (void)sendEvent:(CPEvent)anEvent
{
    _currentEvent = anEvent;

    var willPropagate = [[[anEvent window] platformWindow] _willPropagateCurrentDOMEvent];

    // temporarily pretend we won't propagate the event. we'll restore the saved value later
    // we do this outside the if so that changes user code might make in _handleKeyEquiv. are preserved
    [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:NO];

    // Check if this is a candidate for key equivalent...
    if ([anEvent _couldBeKeyEquivalent] && [self _handleKeyEquivalent:anEvent])
    {
        var characters = [anEvent characters],
            modifierFlags = [anEvent modifierFlags];

        // Unconditionally propagate on these keys to solve browser copy paste bugs
        if ((characters == "c" || characters == "x" || characters == "v") && (modifierFlags & CPPlatformActionKeyMask))
            [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:YES];

        return;
    }

    // if we make it this far, then restore the original willPropagate value
    [[[anEvent window] platformWindow] _propagateCurrentDOMEvent:willPropagate];

    if (_eventListeners.length)
    {
        if (_eventListeners[_eventListeners.length - 1]._mask & (1 << [anEvent type]))
            _eventListeners.pop()._callback(anEvent);
        
        return;
    }

    [[anEvent window] sendEvent:anEvent];
}

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
    return CPWindowObjectList();
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
    return _mainMenu;
}

/*!
    Sets the main menu for the application
    @param aMenu the menu to set for the application
*/
- (void)setMainMenu:(CPMenu)aMenu
{
    if ([aMenu _menuName] === "CPMainMenu")
    {
        if (_mainMenu === aMenu)
            return;

        _mainMenu = aMenu;

        if ([CPPlatform supportsNativeMainMenu])
            window.cpSetMainMenu(_mainMenu);
    }
    else
        [aMenu _setMenuName:@"CPMainMenu"];
}

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
    
    if([_delegate respondsToSelector:anAction])
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

- (void)setCallback:(Function)aCallback forNextEventMatchingMask:(unsigned int)aMask untilDate:(CPDate)anExpiration inMode:(CPString)aMode dequeue:(BOOL)shouldDequeue
{
    _eventListeners.push(_CPEventListenerMake(aMask, aCallback));
}

- (CPEvent)setTarget:(id)aTarget selector:(SEL)aSelector forNextEventMatchingMask:(unsigned int)aMask untilDate:(CPDate)anExpiration inMode:(CPString)aMode dequeue:(BOOL)shouldDequeue
{
    _eventListeners.push(_CPEventListenerMake(aMask, function (anEvent) { objj_msgSend(aTarget, aSelector, anEvent); }));
}

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
    var styleMask = [aSheet styleMask];
    if (!(styleMask & CPDocModalWindowMask))
    {
        [CPException raise:CPInternalInconsistencyException reason:@"Currently only CPDocModalWindowMask style mask is supported for attached sheets"];
        return;
    }
    
    [aWindow orderFront:self];
    [aWindow _attachSheet:aSheet modalDelegate:aModalDelegate didEndSelector:aDidEndSelector contextInfo:aContextInfo];
}

- (void)endSheet:(CPWindow)sheet returnCode:(int)returnCode
{
    var count = [_windows count];
    
    while (--count >= 0)
    {
        var aWindow = [_windows objectAtIndex:count];
        var context = aWindow._sheetContext;
    
        if (context != nil && context["sheet"] === sheet)
        {
            context["returnCode"] = returnCode; 
            [aWindow _detachSheetWindow];
            return;
        }
    }
}

- (void)endSheet:(CPWindow)sheet
{
   [self endSheet:sheet returnCode:0];
}

- (CPArray)arguments
{
    if(_fullArgsString !== window.location.hash)
        [self _reloadArguments];
    
    return _args;
}

- (void)setArguments:(CPArray)args
{
    if(!args || args.length == 0)
    {
        _args = [];
        window.location.hash = @"#";
        
        return;
    }
    
    if([args class] != CPArray)
        args = [CPArray arrayWithObject:args];
    
    _args = args;
    
    var toEncode = [_args copy];
    for(var i=0, count = toEncode.length; i<count; i++)
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
    // FIXME: don't hardcode
    return ([[CPBundle mainBundle] objectForInfoDictionaryKey:"CPDefaultTheme"] || @"Aristo");
}

@end

var _CPModalSessionMake = function(aWindow, aStopCode)
{
    return { _window:aWindow, _state:CPRunContinuesResponse , _previous:nil };
}

var _CPEventListenerMake = function(anEventMask, aCallback)
{
    return { _mask:anEventMask, _callback:aCallback };
}

var _CPRunModalLoop = function(anEvent)
{
    [CPApp setCallback:_CPRunModalLoop forNextEventMatchingMask:CPAnyEventMask untilDate:nil inMode:0 dequeue:NO];

    var theWindow = [anEvent window],
        modalSession = CPApp._currentSession;
    
    if (theWindow == modalSession._window || [theWindow worksWhenModal])
        [theWindow sendEvent:anEvent];
}

/*!
    Starts the GUI and Cappuccino frameworks. This function should be
    called from the \c main() function of your program.
    @class CPApplication
    @return void
*/

function CPApplicationMain(args, namedArgs)
{
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
    var blend = [[CPThemeBlend alloc] initWithContentsOfURL:[[CPBundle bundleForClass:[CPApplication class]] pathForResource:[CPApplication defaultThemeName] + ".blend"]];

    [blend loadWithDelegate:self];

    return YES;
}

+ (void)blendDidFinishLoading:(CPThemeBlend)aThemeBlend
{
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

    return NO;
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
