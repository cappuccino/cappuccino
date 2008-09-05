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

import <Foundation/CPBundle.j>

import "CPCompatibility.j"
import "CPEvent.j"
import "CPMenu.j"
import "CPResponder.j"
import "CPDocumentController.j"

CPApp = nil;

CPApplicationWillFinishLaunchingNotification    = @"CPApplicationWillFinishLaunchingNotification";
CPApplicationDidFinishLaunchingNotification     = @"CPApplicationDidFinishLaunchingNotification";

CPRunStoppedResponse    = -1000;
CPRunAbortedResponse    = -1001;
CPRunContinuesResponse  = -1002;

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
}

+ (CPApplication)sharedApplication
{
    if (!CPApp)
        CPApp = [[CPApplication alloc] init];
    
    return CPApp;
}

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
            saveMenuItem = [[CPMenuItem alloc] initWithTitle:@"Save" action:@selector(saveDocument:) keyEquivalent:@""];
        
        [saveMenuItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPApplication/Save.png"] size:CGSizeMake(16.0, 16.0)]];
        [saveMenuItem setAlternateImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CPApplication/SaveHighlighted.png"] size:CGSizeMake(16.0, 16.0)]];        
        
        [saveMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Save" action:@selector(saveDocument:) keyEquivalent:@"S"]];
        [saveMenu addItem:[[CPMenuItem alloc] initWithTitle:@"Save As" action:@selector(saveDocumentAs:) keyEquivalent:@""]];
        
        [saveMenuItem setSubmenu:saveMenu];
        
        [_mainMenu addItem:saveMenuItem];
        
        var editMenuItem = [[CPMenuItem alloc] initWithTitle:@"Edit" action:nil keyEquivalent:@""],
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

- (id)delegate
{
    return _delegate;
}

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
    
    [[CPRunLoop currentRunLoop] performSelectors];
}

- (void)run
{
    [self finishLaunching];
}

// Managing the Event Loop

- (void)runModalForWindow:(CPWindow)aWindow
{
    [self runModalSession:[self beginModalSessionForWindow:aWindow]];
}

- (void)stopModalWithCode:(int)aCode
{
    if (!_currentSession)
    {
        return;
        // raise exception;
    }
    
    _currentSession._state = aCode;
    _currentSession = _currentSession._previous;
    
    if (aCode == CPRunAbortedResponse)
        [self _removeRunModalLoop];
}

- (void)_removeRunModalLoop
{
    var count = _eventListeners.length;
    
    while (count--)
        if (_eventListeners[count]._callback == _CPRunModalLoop)
        {
            _eventListeners.splice(count, 1);
            
            return;
        }
}

- (void)stopModal
{
    [self stopModalWithCode:CPRunStoppedResponse]
}

- (void)abortModal
{
    [self stopModalWithCode:CPRunAbortedResponse];
}

- (CPModalSession)beginModalSessionForWindow:(CPWindow)aWindow
{
    return _CPModalSessionMake(aWindow, 0);
}

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

- (CPWindow)modalWindow
{
    if (!_currentSession)
        return nil;
    
    return _currentSession._window;
}

- (BOOL)_handleKeyEquivalent:(CPEvent)anEvent
{
    if ([_mainMenu performKeyEquivalent:anEvent])
        return YES;
    
    return NO;
}

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

- (CPWindow)keyWindow
{
    return _keyWindow;
}

- (CPWindow)mainWindow
{
    return _mainWindow;
}

- (CPWindow)windowWithWindowNumber:(int)aWindowNumber
{
    return _windows[aWindowNumber];
}

- (CPArray)windows
{
    return _windows;
}

// Accessing the Main Menu

- (CPMenu)mainMenu
{
    return _mainMenu;
}

- (void)setMainMenu:(CPMenu)aMenu
{
    _mainMenu = aMenu;
}

// Posting Actions

- (BOOL)tryToPerform:(SEL)anAction with:(id)anObject
{
    if (!anAction)
        return NO;

    if ([self tryToPerform:anAction with:anObject])
        return YES;
    
    if([_delegate respondsToSelector:aSelector])
    {
        [_delegate performSelector:aSelector withObject:anObject];
        
        return YES;
    }

    return NO;
}

- (BOOL)sendAction:(SEL)anAction to:(id)aTarget from:(id)aSender
{
    var target = [self targetForAction:anAction to:aTarget from:aSender];
    
    if (!target)
        return NO;
    
    [target performSelector:anAction withObject:aSender];
    
    return YES;
}

- (id)targetForAction:(SEL)anAction to:(id)aTarget from:(id)aSender
{
    if (!anAction)
        return nil;
        
    if (aTarget)
        return aTarget;
        
    return [self targetForAction:anAction];
}

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
    
    if ([aWindow respondsToSelector:anAction])
        return delegate;

    var windowController = [aWindow windowController];
    
    if ([windowController respondsToSelector:anAction])
        return windowController;
    
    var theDocument = [windowController document];
    
    if (theDocument != delegate && [theDocument respondsToSelector:anAction])
        return theDocument;
    
    return nil;
}

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

- (void)beginSheet:(CPWindow)aSheet modalForWindow:(CPWindow)aWindow modalDelegate:(id)aModalDelegate didEndSelector:(SEL)aDidEndSelector contextInfo:(id)aContextInfo
{    
    [aWindow _attachSheet:aSheet modalDelegate:aModalDelegate didEndSelector:aDidEndSelector contextInfo:aContextInfo];
}

- (CPArray)arguments
{
    return _args;
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
        
    // FIXME: abortModal from event loop?
    var theWindow = [anEvent window],
        modalSession = CPApp._currentSession;
    
    if (theWindow == modalSession._window || [theWindow worksWhenModal])
        [theWindow sendEvent:anEvent];
    /*else
        [[session modalWindow] makeKeyAndOrderFront:]*/

    if (modalSession._state != CPRunContinuesResponse)
        [CPApp _removeRunModalLoop];
}

function CPApplicationMain(args, namedArgs)
{
    var mainBundle = [CPBundle mainBundle],
        principalClass = [mainBundle principalClass];
        
    if (!principalClass)
        principalClass = [CPApplication class];

    [principalClass sharedApplication];
    
    //[NSBundle loadNibNamed:@"myMain" owner:NSApp];
    
    //FIXME?
    CPApp._args = args;
    CPApp._namedArgs = namedArgs;
    
    [CPApp run];
}
