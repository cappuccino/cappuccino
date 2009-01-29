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


CPApp = nil;

CPApplicationWillFinishLaunchingNotification    = @"CPApplicationWillFinishLaunchingNotification";
CPApplicationDidFinishLaunchingNotification     = @"CPApplicationDidFinishLaunchingNotification";

CPRunStoppedResponse    = -1000;
CPRunAbortedResponse    = -1001;
CPRunContinuesResponse  = -1002;

/*! @class CPApplication

    CPApplication is THE way to start up the Cappucino framework for your application to use.
    Every GUI application has exactly one instance of CPApplication (or of a custom subclass of
    CPApplication). Your program's main() function can create that instance by calling the
    <code>CPApplicationMain</code> function. A simple example looks like this:
    
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
    
    CPMenu                  _mainMenu;
    CPDocumentController    _documentController;
    
    CPModalSession          _currentSession;
    
    //
    id                      _delegate;
    
    CPDictionary            _namedArgs;
    CPArray                 _args;
    CPString                _fullArgsString;
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
    Functions are <code>New, Open, Undo, Redo, Save, Cut, Copy, Paste</code>.
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
}

/*!
    Returns the application's delegate. The app can only have one delegate at a time.
*/
- (id)delegate
{
    return _delegate;
}

/*!
    This method is called by <code>run</code> before the event loop begins.
    When it successfully completes, it posts the notification
    CPApplicationDidFinishLaunchingNotification. If you override
    <code>finishLaunching</code>, the subclass method should invoke the superclass method.
*/
- (void)finishLaunching
{
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
    
    if (_documentController)
        [_documentController newDocument:self];
    
    [defaultCenter
        postNotificationName:CPApplicationDidFinishLaunchingNotification
        object:self];
    
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

/*!
    Calls <code>finishLaunching</code> method which results in starting
    the main event loop.
*/
- (void)run
{
    [self finishLaunching];
}

// Managing the Event Loop
/*!
    Starts a modal event loop for <code>aWindow</code>
    @param aWindow the window to start the event loop for
*/
- (void)runModalForWindow:(CPWindow)aWindow
{
    [self runModalSession:[self beginModalSessionForWindow:aWindow]];
}

/*!
    Stops the event loop started by <code>runModalForWindow:</code> and
    sets the code that <code>runModalForWindow:</code> will return.
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
    Aborts the event loop started by <code>runModalForWindow:</code>
*/
- (void)abortModal
{
    [self stopModalWithCode:CPRunAbortedResponse];
}

/*!
    Sets up a modal session with <code>theWindow</code>.
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
    modal session, it returns <code>nil</code>.
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
    if ([_mainMenu performKeyEquivalent:anEvent])
        return YES;
    
    return NO;
}

/*!
    Dispatches events to other objects.
    @param anEvent the event to dispatch
*/
- (void)sendEvent:(CPEvent)anEvent
{
    // Check if this is a candidate for key equivalent...
    if ([anEvent type] == CPKeyDown &&
        [anEvent modifierFlags] & (CPCommandKeyMask | CPControlKeyMask) && 
        [[anEvent characters] length] > 0 &&
        [self _handleKeyEquivalent:anEvent])
        return;

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
    Returns the CPWindow object corresponding to <code>aWindowNumber</code>.
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
    _mainMenu = aMenu;
}

// Posting Actions
/*!
    Tries to perform the action with an argument. Performs
    the action on itself (if it responds to it), then
    tries to perform the action on the delegate.
    @param anAction the action to perform.
    @param anObject the argument for the action
    method
    @return <code>YES</code> if the action was performed
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
    @return <code>YES</code>
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
    action is <code>nil</code>, returns <code>nil</code>.
    If the target is not <code>nil</code>, <code>aTarget</code> is
    returned. Otherwise, it calls <code>targetForAction:</code>
    to search for a target.
    @param anAction the action to find a target for
    @param aTarget if not <code>nil</code>, this will be returned
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
    @return the object that responds to the action, or <code>nil</code>
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
    
    if (theDocument != delegate && [theDocument respondsToSelector:anAction])
        return theDocument;
    
    return nil;
}

/*!
    Looks for a target that can handle the specified action.
    Checks for a target in the following order:
    <ol>
        <li>a responder from the key window</li>
        <li>a responder frmo the main window</li>
        <li>the CPApplication instance</li>
        <li>the application delegate</li>
        <li>the document controller</li>
    </ol>
    @param anAction the action to handle
    @return a target that can respond, or <code>nil</code>
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
    
    if (_eventListeners.length == 3) objj_debug_print_backtrace();
}

- (CPEvent)setTarget:(id)aTarget selector:(SEL)aSelector forNextEventMatchingMask:(unsigned int)aMask untilDate:(CPDate)anExpiration inMode:(CPString)aMode dequeue:(BOOL)shouldDequeue
{
    _eventListeners.push(_CPEventListenerMake(aMask, function (anEvent) { objj_msgSend(aTarget, aSelector, anEvent); }));
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
    [aWindow _attachSheet:aSheet modalDelegate:aModalDelegate didEndSelector:aDidEndSelector contextInfo:aContextInfo];
}

- (CPArray)arguments
{
    if(_fullArgsString != window.location.hash)
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
    var args = _fullArgsString.replace("#", "").split("/").slice(0);
    
    for(var i=0, count = args.length; i<count; i++) 
        args[i] = decodeURIComponent(args[i]);
    
    _args = args;
}

- (CPDictionary)namedArguments
{
    return _namedArgs;
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
    called from the <code>main()</code> function of your program.
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
    
    //[NSBundle loadNibNamed:@"myMain" owner:NSApp];
    
    //FIXME?
    if (!args && !namedArgs)
    {
        var args = [CPApp arguments],
            searchParams = window.location.search.substring(1).split("&");
            namedArgs = [CPDictionary dictionary];
        
        if([args containsObject:"debug"])
            CPLogRegister(CPLogPopup);
    
        for(var i=0; i<searchParams.length; i++)
        {
            var index = searchParams[i].indexOf('=');
            if(index == -1)
                [namedArgs setObject: "" forKey:searchParams[i]];
            else
                [namedArgs setObject: searchParams[i].substring(index+1) forKey: searchParams[i].substring(0, index)];
        }
    }
    
    CPApp._args = args;
    CPApp._namedArgs = namedArgs;
    
    [CPApp run];
}
