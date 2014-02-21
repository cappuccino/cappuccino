/*
 * CPDocument.j
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

@import <Foundation/CPString.j>
@import <Foundation/CPArray.j>

@import "CPAlert.j"
@import "CPResponder.j"
@import "CPSavePanel.j"
@import "CPViewController.j"
@import "CPWindowController.j"

@class CPDocumentController

@global CPApp


/*
    @global
    @group CPSaveOperationType
*/
CPSaveOperation             = 0;
/*
    @global
    @group CPSaveOperationType
*/
CPSaveAsOperation           = 1;
/*
    @global
    @group CPSaveOperationType
*/
CPSaveToOperation           = 2;
/*
    @global
    @group CPSaveOperationType
*/
CPAutosaveOperation         = 3;

/*
    @global
    @group CPDocumentChangeType
*/
CPChangeDone                = 0;
/*
    @global
    @group CPDocumentChangeType
*/
CPChangeUndone              = 1;
/*
    @global
    @group CPDocumentChangeType
*/
CPChangeCleared             = 2;
/*
    @global
    @group CPDocumentChangeType
*/
CPChangeReadOtherContents   = 3;
/*
    @global
    @group CPDocumentChangeType
*/
CPChangeAutosaved           = 4;

CPDocumentWillSaveNotification      = @"CPDocumentWillSaveNotification";
CPDocumentDidSaveNotification       = @"CPDocumentDidSaveNotification";
CPDocumentDidFailToSaveNotification = @"CPDocumentDidFailToSaveNotification";

var CPDocumentUntitledCount = 0;

/*!
    @ingroup appkit
    @class CPDocument

    CPDocument is used to represent a document/file in a Cappuccino application.
    In a document-based application, generally multiple documents are open simultaneously
    (multiple text documents, slide presentations, spreadsheets, etc.), and multiple
    CPDocuments should be used to represent this.
*/
@implementation CPDocument : CPResponder
{
    CPWindow            _window; // For outlet purposes.
    CPView              _view; // For outlet purposes
    CPDictionary        _viewControllersForWindowControllers;

    CPURL               _fileURL;
    CPString            _fileType;
    CPArray             _windowControllers;
    unsigned            _untitledDocumentIndex;

    BOOL                _hasUndoManager;
    CPUndoManager       _undoManager;

    int                 _changeCount;

    CPURLConnection     _readConnection;
    CPURLRequest        _writeRequest;

    CPAlert             _canCloseAlert;
}

/*!
    Initializes an empty document.
    @return the initialized document
*/
- (id)init
{
    self = [super init];

    if (self)
    {
        _windowControllers = [];
        _viewControllersForWindowControllers = @{};

        _hasUndoManager = YES;
        _changeCount = 0;

        [self setNextResponder:CPApp];
    }

    return self;
}

/*!
    Initializes the document with a specific data type.
    @param aType the type of document to initialize
    @param anError not used
    @return the initialized document
*/
- (id)initWithType:(CPString)aType error:(/*{*/CPError/*}*/)anError
{
    self = [self init];

    if (self)
        [self setFileType:aType];

    return self;
}

/*!
    Initializes a document of a specific type located at a URL. Notifies
    the provided delegate after initialization.
    @param anAbsoluteURL the url of the document content
    @param aType the type of document located at the URL
    @param aDelegate the delegate to notify
    @param aDidReadSelector the selector used to notify the delegate
    @param aContextInfo context information passed to the delegate
    after initialization
    @return the initialized document
*/
- (id)initWithContentsOfURL:(CPURL)anAbsoluteURL ofType:(CPString)aType delegate:(id)aDelegate didReadSelector:(SEL)aDidReadSelector contextInfo:(id)aContextInfo
{
    self = [self init];

    if (self)
    {
        [self setFileURL:anAbsoluteURL];
        [self setFileType:aType];

        [self readFromURL:anAbsoluteURL ofType:aType delegate:aDelegate didReadSelector:aDidReadSelector contextInfo:aContextInfo];
    }

    return self;
}

/*!
    Initializes the document from a URL.
    @param anAbsoluteURL the document location
    @param absoluteContentsURL the location of the document's contents
    @param aType the type of the contents
    @param aDelegate this object will receive a callback after the document's contents are loaded
    @param aDidReadSelector the message selector that will be sent to \c aDelegate
    @param aContextInfo passed as the argument to the message sent to the \c aDelegate
    @return the initialized document
*/
- (id)initForURL:(CPURL)anAbsoluteURL withContentsOfURL:(CPURL)absoluteContentsURL ofType:(CPString)aType delegate:(id)aDelegate didReadSelector:(SEL)aDidReadSelector contextInfo:(id)aContextInfo
{
    self = [self init];

    if (self)
    {
        [self setFileURL:anAbsoluteURL];
        [self setFileType:aType];

        [self readFromURL:absoluteContentsURL ofType:aType delegate:aDelegate didReadSelector:aDidReadSelector contextInfo:aContextInfo];
    }

    return self;
}

/*!
    Returns the receiver's data in a specified type. The default implementation just
    throws an exception.
    @param aType the format of the data
    @param anError not used
    @throws CPUnsupportedMethodException if this method hasn't been overridden by the subclass
    @return the document data
*/
- (CPData)dataOfType:(CPString)aType error:(/*{*/CPError/*}*/)anError
{
    [CPException raise:CPUnsupportedMethodException
                reason:"dataOfType:error: must be overridden by the document subclass."];
}

/*!
    Sets the content of the document by reading the provided
    data. The default implementation just throws an exception.
    @param aData the document's data
    @param aType the document type
    @param anError not used
    @throws CPUnsupportedMethodException if this method hasn't been
    overridden by the subclass
*/
- (void)readFromData:(CPData)aData ofType:(CPString)aType error:(CPError)anError
{
    [CPException raise:CPUnsupportedMethodException
                reason:"readFromData:ofType: must be overridden by the document subclass."];
}

- (void)viewControllerWillLoadCib:(CPViewController)aViewController
{
}

- (void)viewControllerDidLoadCib:(CPViewController)aViewController
{
}

// Creating and managing window controllers
/*!
    Creates the window controller for this document.
*/
- (void)makeWindowControllers
{
    [self makeViewAndWindowControllers];
}

- (void)makeViewAndWindowControllers
{
    var viewCibName = [self viewCibName],
        windowCibName = [self windowCibName],
        viewController = nil,
        windowController = nil;

    // Create our view controller if we have a cib for it.
    if ([viewCibName length])
        viewController = [[CPViewController alloc] initWithCibName:viewCibName bundle:nil owner:self];

    // From a cib if we have one.
    if ([windowCibName length])
        windowController = [[CPWindowController alloc] initWithWindowCibName:windowCibName owner:self];

    // If not you get a standard window capable of displaying multiple documents and view
    else if (viewController)
    {
        var view = [viewController view],
            viewFrame = [view frame];

        viewFrame.origin = CGPointMake(50, 50);

        var theWindow = [[CPWindow alloc] initWithContentRect:viewFrame styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask];

        windowController = [[CPWindowController alloc] initWithWindow:theWindow];
    }

    if (windowController && viewController)
        [windowController setSupportsMultipleDocuments:YES];

    if (windowController)
        [self addWindowController:windowController];

    if (viewController)
        [self addViewController:viewController forWindowController:windowController];
}

/*!
    Returns the document's window controllers
*/
- (CPArray)windowControllers
{
    return _windowControllers;
}

/*!
    Add a controller to the document's list of controllers. This should
    be called after making a new window controller.
    @param aWindowController the controller to add
*/
- (void)addWindowController:(CPWindowController)aWindowController
{
    [_windowControllers addObject:aWindowController];

    if ([aWindowController document] !== self)
        [aWindowController setDocument:self];
}

/*!
    Remove a controller to the document's list of controllers. This should
    be called after closing the controller's window.
    @param aWindowController the controller to remove
*/
- (void)removeWindowController:(CPWindowController)aWindowController
{
    if (aWindowController)
        [_windowControllers removeObject:aWindowController];

    if ([aWindowController document] === self)
        [aWindowController setDocument:nil];
}

- (CPView)view
{
    return _view;
}

- (CPArray)viewControllers
{
    return [_viewControllersForWindowControllers allValues];
}

- (void)addViewController:(CPViewController)aViewController forWindowController:(CPWindowController)aWindowController
{
    // FIXME: exception if we don't own the window controller?
    [_viewControllersForWindowControllers setObject:aViewController forKey:[aWindowController UID]];

    if ([aWindowController document] === self)
        [aWindowController setViewController:aViewController];
}

- (void)removeViewController:(CPViewController)aViewController
{
    [_viewControllersForWindowControllers removeObject:aViewController];
}

- (CPViewController)viewControllerForWindowController:(CPWindowController)aWindowController
{
    return [_viewControllersForWindowControllers objectForKey:[aWindowController UID]];
}

// Managing Document Windows
/*!
    Shows all the document's windows.
*/
- (void)showWindows
{
    [_windowControllers makeObjectsPerformSelector:@selector(setDocument:) withObject:self];
    [_windowControllers makeObjectsPerformSelector:@selector(showWindow:) withObject:self];
}

/*!
    Returns the name of the document as displayed in the title bar.
*/
- (CPString)displayName
{
    if (_fileURL)
        return [_fileURL lastPathComponent];

    if (!_untitledDocumentIndex)
        _untitledDocumentIndex = ++CPDocumentUntitledCount;

    if (_untitledDocumentIndex == 1)
       return @"Untitled";

    return @"Untitled " + _untitledDocumentIndex;
}

- (CPString)viewCibName
{
    return nil;
}

/*!
    Returns the document's Cib name
*/
- (CPString)windowCibName
{
    return nil;
}

/*!
    Called after \c aWindowController loads the document's Nib file.
    @param aWindowController the controller that loaded the Nib file
*/
- (void)windowControllerDidLoadCib:(CPWindowController)aWindowController
{
}

/*!
    Called before \c aWindowController will load the document's Nib file.
    @param aWindowController the controller that will load the Nib file
*/
- (void)windowControllerWillLoadCib:(CPWindowController)aWindowController
{
}

// Reading from and Writing to URLs
/*!
    Set the document's data from a URL. Notifies the provided delegate afterwards.
    @param anAbsoluteURL the URL to the document's content
    @param aType the document type
    @param aDelegate delegate to notify after reading the data
    @param aDidReadSelector message that will be sent to the delegate
    @param aContextInfo context information that gets sent to the delegate
*/
- (void)readFromURL:(CPURL)anAbsoluteURL ofType:(CPString)aType delegate:(id)aDelegate didReadSelector:(SEL)aDidReadSelector contextInfo:(id)aContextInfo
{
    [_readConnection cancel];

    // FIXME: Oh man is this every looking for trouble, we need to handle login at the Cappuccino level, with HTTP Errors.
    _readConnection = [CPURLConnection connectionWithRequest:[CPURLRequest requestWithURL:anAbsoluteURL] delegate:self];

    _readConnection.session = _CPReadSessionMake(aType, aDelegate, aDidReadSelector, aContextInfo);
}

/*!
    Returns the path to the document's file.
*/
- (CPURL)fileURL
{
    return _fileURL;
}

/*!
    Sets the path to the document's file.
    @param aFileURL the path to the document's file
*/
- (void)setFileURL:(CPURL)aFileURL
{
    if (_fileURL === aFileURL)
        return;

    _fileURL = aFileURL;

    [_windowControllers makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
}

/*!
    Saves the document to the specified URL. Notifies the provided delegate
    with the provided selector and context info afterwards.
    @param anAbsoluteURL the url to write the document data to
    @param aTypeName the document type
    @param aSaveOperation the type of save operation
    @param aDelegate the delegate to notify after saving
    @param aDidSaveSelector the selector to send the delegate
    @param aContextInfo context info that gets passed to the delegate
*/
- (void)saveToURL:(CPURL)anAbsoluteURL ofType:(CPString)aTypeName forSaveOperation:(CPSaveOperationType)aSaveOperation delegate:(id)aDelegate didSaveSelector:(SEL)aDidSaveSelector contextInfo:(id)aContextInfo
{
    var data = [self dataOfType:[self fileType] error:nil],
        oldChangeCount = _changeCount;

    _writeRequest = [CPURLRequest requestWithURL:anAbsoluteURL];

    // FIXME: THIS IS WRONG! We need a way to decide
    if ([CPPlatform isBrowser])
        [_writeRequest setHTTPMethod:@"POST"];
    else
        [_writeRequest setHTTPMethod:@"PUT"];

    [_writeRequest setHTTPBody:[data rawString]];

    [_writeRequest setValue:@"close" forHTTPHeaderField:@"Connection"];

    if (aSaveOperation === CPSaveOperation)
        [_writeRequest setValue:@"true" forHTTPHeaderField:@"x-cappuccino-overwrite"];

    if (aSaveOperation !== CPSaveToOperation)
        [self updateChangeCount:CPChangeCleared];

    // FIXME: Oh man is this every looking for trouble, we need to handle login at the Cappuccino level, with HTTP Errors.
    var connection = [CPURLConnection connectionWithRequest:_writeRequest delegate:self];

    connection.session = _CPSaveSessionMake(anAbsoluteURL, aSaveOperation, oldChangeCount, aDelegate, aDidSaveSelector, aContextInfo, connection);
}

/*
    Implemented as a delegate method for CPURLConnection
    @ignore
*/
- (void)connection:(CPURLConnection)aConnection didReceiveResponse:(CPURLResponse)aResponse
{
    // If we got this far and it wasn't an HTTP request, then everything is fine.
    if (![aResponse isKindOfClass:[CPHTTPURLResponse class]])
        return;

    var statusCode = [aResponse statusCode];

    // Nothing to do if everything is hunky dory.
    if (statusCode === 200)
        return;

    var session = aConnection.session;

    if (aConnection == _readConnection)
    {
        [aConnection cancel];

        alert("There was an error retrieving the document.");

        objj_msgSend(session.delegate, session.didReadSelector, self, NO, session.contextInfo);
    }
    else
    {
        // 409: Conflict, in Cappuccino, overwrite protection for documents.
        if (statusCode == 409)
        {
            [aConnection cancel];

            if (confirm("There already exists a file with that name, would you like to overwrite it?"))
            {
                [_writeRequest setValue:@"true" forHTTPHeaderField:@"x-cappuccino-overwrite"];

                [aConnection start];
            }
            else
            {
                if (session.saveOperation != CPSaveToOperation)
                {
                    _changeCount += session.changeCount;
                    [_windowControllers makeObjectsPerformSelector:@selector(setDocumentEdited:) withObject:[self isDocumentEdited]];
                }

                _writeRequest = nil;

                objj_msgSend(session.delegate, session.didSaveSelector, self, NO, session.contextInfo);
                [self _sendDocumentSavedNotification:NO];
            }
        }
    }
}

/*
    Implemented as a delegate method for CPURLConnection
    @ignore
*/
- (void)connection:(CPURLConnection)aConnection didReceiveData:(CPString)aData
{
    var session = aConnection.session;

    // READ
    if (aConnection == _readConnection)
    {
        [self readFromData:[CPData dataWithRawString:aData] ofType:session.fileType error:nil];

        objj_msgSend(session.delegate, session.didReadSelector, self, YES, session.contextInfo);
    }
    else
    {
        if (session.saveOperation != CPSaveToOperation)
            [self setFileURL:session.absoluteURL];

        _writeRequest = nil;

        objj_msgSend(session.delegate, session.didSaveSelector, self, YES, session.contextInfo);
        [self _sendDocumentSavedNotification:YES];
    }
}

/*
    Implemented as a delegate method for CPURLConnection
    @ignore
*/
- (void)connection:(CPURLConnection)aConnection didFailWithError:(CPError)anError
{
    var session = aConnection.session;

    if (_readConnection == aConnection)
        objj_msgSend(session.delegate, session.didReadSelector, self, NO, session.contextInfo);

    else
    {
        if (session.saveOperation != CPSaveToOperation)
        {
            _changeCount += session.changeCount;
            [_windowControllers makeObjectsPerformSelector:@selector(setDocumentEdited:) withObject:[self isDocumentEdited]];
        }

        _writeRequest = nil;

        alert("There was an error saving the document.");

        objj_msgSend(session.delegate, session.didSaveSelector, self, NO, session.contextInfo);
        [self _sendDocumentSavedNotification:NO];
    }
}

/*
    Implemented as a delegate method for CPURLConnection
    @ignore
*/
- (void)connectionDidFinishLoading:(CPURLConnection)aConnection
{
    if (_readConnection == aConnection)
        _readConnection = nil;
}

// Managing Document Status
/*!
    Returns \c YES if there are any unsaved changes.
*/
- (BOOL)isDocumentEdited
{
    return _changeCount != 0;
}

/*!
    Updates the number of unsaved changes to the document.
    @param aChangeType a new document change to apply
*/
- (void)updateChangeCount:(CPDocumentChangeType)aChangeType
{
    if (aChangeType == CPChangeDone)
        ++_changeCount;
    else if (aChangeType == CPChangeUndone)
        --_changeCount;
    else if (aChangeType == CPChangeCleared)
        _changeCount = 0;
    /*else if (aChangeType == CPCHangeReadOtherContents)

    else if (aChangeType == CPChangeAutosaved)*/

    [_windowControllers makeObjectsPerformSelector:@selector(setDocumentEdited:) withObject:[self isDocumentEdited]];
}

// Managing File Types
/*!
    Sets the document's file type
    @param aType the document's type
*/
- (void)setFileType:(CPString)aType
{
    _fileType = aType;
}

/*!
    Returns the document's file type
*/
- (CPString)fileType
{
    return _fileType;
}

// Working with Undo Manager
/*!
    Returns \c YES if the document has a
    CPUndoManager.
*/
- (BOOL)hasUndoManager
{
    return _hasUndoManager;
}

/*!
    Sets whether the document should have a CPUndoManager.
    @param aFlag \c YES makes the document have an undo manager
*/
- (void)setHasUndoManager:(BOOL)aFlag
{
    if (_hasUndoManager == aFlag)
        return;

    _hasUndoManager = aFlag;

    if (!_hasUndoManager)
        [self setUndoManager:nil];
}

/* @ignore */
- (void)_undoManagerWillCloseGroup:(CPNotification)aNotification
{
    var undoManager = [aNotification object];

    if ([undoManager isUndoing] || [undoManager isRedoing])
        return;

    [self updateChangeCount:CPChangeDone];
}

/* @ignore */
- (void)_undoManagerDidUndoChange:(CPNotification)aNotification
{
    [self updateChangeCount:CPChangeUndone];
}

/* @ignore */
- (void)_undoManagerDidRedoChange:(CPNotification)aNotification
{
    [self updateChangeCount:CPChangeDone];
}

/*
    Sets the document's undo manager. This method will add the
    undo manager as an observer to the notification center.
    @param anUndoManager the new undo manager for the document
*/
- (void)setUndoManager:(CPUndoManager)anUndoManager
{
    var defaultCenter = [CPNotificationCenter defaultCenter];

    if (_undoManager)
    {
        [defaultCenter removeObserver:self
                                 name:CPUndoManagerDidUndoChangeNotification
                               object:_undoManager];

        [defaultCenter removeObserver:self
                                 name:CPUndoManagerDidRedoChangeNotification
                               object:_undoManager];

        [defaultCenter removeObserver:self
                                 name:CPUndoManagerWillCloseUndoGroupNotification
                               object:_undoManager];
    }

    _undoManager = anUndoManager;

    if (_undoManager)
    {

        [defaultCenter addObserver:self
                          selector:@selector(_undoManagerDidUndoChange:)
                              name:CPUndoManagerDidUndoChangeNotification
                            object:_undoManager];

        [defaultCenter addObserver:self
                          selector:@selector(_undoManagerDidRedoChange:)
                              name:CPUndoManagerDidRedoChangeNotification
                            object:_undoManager];

        [defaultCenter addObserver:self
                          selector:@selector(_undoManagerWillCloseGroup:)
                              name:CPUndoManagerWillCloseUndoGroupNotification
                            object:_undoManager];
    }
}

/*!
    Returns the document's undo manager. If the document
    should have one, but the manager is \c nil, it
    will be created and then returned.
    @return the document's undo manager
*/
- (CPUndoManager)undoManager
{
    if (_hasUndoManager && !_undoManager)
        [self setUndoManager:[[CPUndoManager alloc] init]];

    return _undoManager;
}

/*
    Implemented as a delegate of a CPWindow
    @ignore
*/
- (CPUndoManager)windowWillReturnUndoManager:(CPWindow)aWindow
{
    return [self undoManager];
}

// Handling User Actions
/*!
    Saves the document. If the document does not
    have a file path to save to (\c fileURL)
    then \c -saveDocumentAs: will be called.
    @param aSender the object requesting the save
*/
- (void)saveDocument:(id)aSender
{
    [self saveDocumentWithDelegate:nil didSaveSelector:nil contextInfo:nil];
}

- (void)saveDocumentWithDelegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(Object)contextInfo
{
    if (_fileURL)
    {
        [[CPNotificationCenter defaultCenter]
            postNotificationName:CPDocumentWillSaveNotification
                          object:self];

        [self saveToURL:_fileURL ofType:[self fileType] forSaveOperation:CPSaveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
    }
    else
        [self _saveDocumentAsWithDelegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

/*!
    Saves the document to a user specified path.
    @param aSender the object requesting the operation
*/
- (void)saveDocumentAs:(id)aSender
{
    [self _saveDocumentAsWithDelegate:nil didSaveSelector:nil contextInfo:nil];
}

- (void)_saveDocumentAsWithDelegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(Object)contextInfo
{
    var savePanel = [CPSavePanel savePanel],
        response = [savePanel runModal];

    if (!response)
        return;

    var saveURL = [savePanel URL];

    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPDocumentWillSaveNotification
                      object:self];

    [self saveToURL:saveURL ofType:[self fileType] forSaveOperation:CPSaveAsOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}

/*
    @ignore
*/
- (void)_sendDocumentSavedNotification:(BOOL)didSave
{
    if (didSave)
        [[CPNotificationCenter defaultCenter]
            postNotificationName:CPDocumentDidSaveNotification
                          object:self];
    else
        [[CPNotificationCenter defaultCenter]
            postNotificationName:CPDocumentDidFailToSaveNotification
                          object:self];
}

@end

@implementation CPDocument (ClosingDocuments)

- (void)close
{
    [_windowControllers makeObjectsPerformSelector:@selector(removeDocumentAndCloseIfNecessary:) withObject:self];
    [[CPDocumentController sharedDocumentController] removeDocument:self];
}

- (void)shouldCloseWindowController:(CPWindowController)controller delegate:(id)delegate shouldCloseSelector:(SEL)selector contextInfo:(Object)info
{
    if ([controller shouldCloseDocument] || ([_windowControllers count] < 2 && [_windowControllers indexOfObject:controller] !== CPNotFound))
        [self canCloseDocumentWithDelegate:self shouldCloseSelector:@selector(_document:shouldClose:context:) contextInfo:{delegate:delegate, selector:selector, context:info}];

    else if ([delegate respondsToSelector:selector])
        objj_msgSend(delegate, selector, self, YES, info);
}

- (void)_document:(CPDocument)aDocument shouldClose:(BOOL)shouldClose context:(Object)context
{
    if (aDocument === self && shouldClose)
        [self close];

    objj_msgSend(context.delegate, context.selector, aDocument, shouldClose, context.context);
}

- (void)canCloseDocumentWithDelegate:(id)aDelegate shouldCloseSelector:(SEL)aSelector contextInfo:(Object)context
{
    if (![self isDocumentEdited])
        return [aDelegate respondsToSelector:aSelector] && objj_msgSend(aDelegate, aSelector, self, YES, context);

    _canCloseAlert = [[CPAlert alloc] init];

    [_canCloseAlert setDelegate:self];
    [_canCloseAlert setAlertStyle:CPWarningAlertStyle];
    [_canCloseAlert setTitle:@"Unsaved Document"];
    [_canCloseAlert setMessageText:@"Do you want to save the changes you've made to the document \"" + ([self displayName] || [self fileName]) + "\"?"];

    [_canCloseAlert addButtonWithTitle:@"Save"];
    [_canCloseAlert addButtonWithTitle:@"Cancel"];
    [_canCloseAlert addButtonWithTitle:@"Don't Save"];

    _canCloseAlert._context = {delegate:aDelegate, selector:aSelector, context:context};

    [_canCloseAlert runModal];
}

- (void)alertDidEnd:(CPAlert)alert returnCode:(int)returnCode
{
    if (alert !== _canCloseAlert)
        return;

    var delegate = alert._context.delegate,
        selector = alert._context.selector,
        context = alert._context.context;

    if (returnCode === 0)
        [self saveDocumentWithDelegate:delegate didSaveSelector:selector contextInfo:context];
    else
        objj_msgSend(delegate, selector, self, returnCode === 2, context);

    _canCloseAlert = nil;
}

@end

var _CPReadSessionMake = function(aType, aDelegate, aDidReadSelector, aContextInfo)
{
    return { fileType:aType, delegate:aDelegate, didReadSelector:aDidReadSelector, contextInfo:aContextInfo };
};

var _CPSaveSessionMake = function(anAbsoluteURL, aSaveOperation, aChangeCount, aDelegate, aDidSaveSelector, aContextInfo, aConnection)
{
    return { absoluteURL:anAbsoluteURL, saveOperation:aSaveOperation, changeCount:aChangeCount, delegate:aDelegate, didSaveSelector:aDidSaveSelector, contextInfo:aContextInfo, connection:aConnection };
};
