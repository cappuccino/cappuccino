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

@import "CPResponder.j"
@import "CPWindowController.j"


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

/*! @class CPDocument

    <objj>CPDocument</objj> is used to represent a document/file in a Cappuccino application.
    In a document-based application, generally multiple documents are open simutaneously
    (multiple text documents, slide presentations, spreadsheets, etc.), and multiple
    <objj>CPDocument</objj>s should be used to represent this.
*/
@implementation CPDocument : CPResponder
{    
    CPURL           _fileURL;
    CPString        _fileType;
    CPArray         _windowControllers;
    unsigned        _untitledDocumentIndex;

    BOOL            _hasUndoManager;
    CPUndoManager   _undoManager;
    
    int             _changeCount;
    
    CPURLConnection _readConnection;
    CPURLRequest    _writeRequest;
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
- (id)initWithType:(CPString)aType error:({CPError})anError
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
        [self readFromURL:anAbsoluteURL ofType:aType delegate:aDelegate didReadSelector:aDidReadSelector contextInfo:aContextInfo];
        
        [self setFileURL:anAbsoluteURL];
        [self setFileType:aType];
    }
    
    return self;
}

/*!
    Initializes the document from a URL.
    @param anAbsoluteURL the document location
    @param absoluteContentsURL the location of the document's contents
    @param aType the type of the contents
    @param aDelegate this object will receive a callback after the document's contents are loaded
    @param aDidReadSelector the message selector that will be sent to <code>aDelegate</code>
    @param aContextInfo passed as the argument to the message sent to the <code>aDelegate</code>
    @return the initialized document
*/
- (id)initForURL:(CPURL)anAbsoluteURL withContentsOfURL:(CPURL)absoluteContentsURL ofType:(CPString)aType delegate:(id)aDelegate didReadSelector:(SEL)aDidReadSelector contextInfo:(id)aContextInfo
{
    self = [self init];
    
    if (self)
    {
        [self readFromURL:absoluteContentsURL ofType:aType delegate:aDelegate didReadSelector:aDidReadSelector contextInfo:aContextInfo];
        
        [self setFileURL:anAbsoluteURL];
        [self setFileType:aType];
    }
    
    return self;
}

/*!
    Returns the receiver's data in a specified type. The default implementation just
    throws an exception.
    @param aType the format of the data
    @param anError not used
    @throws CPUnsupportedMethodException if this method hasn't been overriden by the subclass
    @return the document data
*/
- (CPData)dataOfType:(CPString)aType error:({CPError})anError
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

// Creating and managing window controllers
/*!
    Creates the window controller for this document.
*/
- (void)makeWindowControllers
{
    var controller = [[CPWindowController alloc] initWithWindowCibName:nil];
    
    [self addWindowController:controller];
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
    
    if ([aWindowController document] != self)
    {
        [aWindowController setNextResponder:self];
        [aWindowController setDocument:self];
    }
}

// Managing Document Windows
/*!
    Shows all the document's windows.
*/
- (void)showWindows
{
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

/*!
    Returns the document's Cib name
*/
- (CPString)windowCibName
{
    return nil;
}

/*!
    Called after <code>aWindowController<code> loads the document's Nib file.
    @param aWindowController the controller that loaded the Nib file
*/
- (void)windowControllerDidLoadNib:(CPWindowController)aWindowController
{
}

/*!
    Called before <code>aWindowController</code> will load the document's Nib file.
    @param aWindowController the controller that will load the Nib file
*/
- (void)windowControllerWillLoadNib:(CPWindowController)aWindowController
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
    if (_fileURL == aFileURL)
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

    [_writeRequest setHTTPMethod:@"POST"];
    [_writeRequest setHTTPBody:[data string]];
    
    [_writeRequest setValue:@"close" forHTTPHeaderField:@"Connection"];

    if (aSaveOperation == CPSaveOperation)
        [_writeRequest setValue:@"true" forHTTPHeaderField:@"x-cappuccino-overwrite"];
    
    if (aSaveOperation != CPSaveToOperation)
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
    var statusCode = [aResponse statusCode];
    
    // Nothing to do if everything is hunky dory.
    if (statusCode == 200)
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
        [self readFromData:[CPData dataWithString:aData] ofType:session.fileType error:nil];

        objj_msgSend(session.delegate, session.didReadSelector, self, YES, session.contextInfo);
    }
    else
    {
        if (session.saveOperation != CPSaveToOperation)
            [self setFileURL:session.absoluteURL];
            
        _writeRequest = nil;
        
        objj_msgSend(session.delegate, session.didSaveSelector, self, YES, session.contextInfo);
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
    Returns <code>YES</code> if there are any unsaved changes.
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
    Returns <code>YES</code> if the document has a
    <objj>CPUndoManager</objj>.
*/
- (BOOL)hasUndoManager
{
    return _hasUndoManager;
}

/*!
    Sets whether the document should have a <objj>CPUndoManager</objj>.
    @param aFlag <code>YES</code> makes the document have an undo manager
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
    should have one, but the manager is <code>nil</code>, it
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
    Implemented as a delegate of a <objj>CPWindow</objj>
    @ignore
*/
- (CPUndoManager)windowWillReturnUndoManager:(CPWindow)aWindow
{
    return [self undoManager];
}

// Handling User Actions
/*!
    Saves the document. If the document does not
    have a file path to save to (<code>fileURL</code>)
    then <code>saveDocumentAs:</code> will be called.
    @param aSender the object requesting the save
*/
- (void)saveDocument:(id)aSender
{
    if (_fileURL)
    {
        [[CPNotificationCenter defaultCenter]
            postNotificationName:CPDocumentWillSaveNotification
                          object:self];
        
        [self saveToURL:_fileURL ofType:[self fileType] forSaveOperation:CPSaveOperation delegate:self didSaveSelector:@selector(document:didSave:contextInfo:) contextInfo:NULL];
    }
    else
        [self saveDocumentAs:self];
}

/*!
    Saves the document to a user specified path.
    @param aSender the object requesting the operation
*/
- (void)saveDocumentAs:(id)aSender
{
    _documentName = window.prompt("Document Name:");

    if (!_documentName)
        return;
        
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPDocumentWillSaveNotification
                      object:self];
    
    [self saveToURL:[self proposedFileURL] ofType:[self fileType] forSaveOperation:CPSaveAsOperation delegate:self didSaveSelector:@selector(document:didSave:contextInfo:) contextInfo:NULL];
}

/*
    @ignore
*/
- (void)document:(id)aDocument didSave:(BOOL)didSave contextInfo:(id)aContextInfo
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

var _CPReadSessionMake = function(aType, aDelegate, aDidReadSelector, aContextInfo)
{
    return { fileType:aType, delegate:aDelegate, didReadSelector:aDidReadSelector, contextInfo:aContextInfo };
}

var _CPSaveSessionMake = function(anAbsoluteURL, aSaveOperation, aChangeCount, aDelegate, aDidSaveSelector, aContextInfo, aConnection)
{
    return { absoluteURL:anAbsoluteURL, saveOperation:aSaveOperation, changeCount:aChangeCount, delegate:aDelegate, didSaveSelector:aDidSaveSelector, contextInfo:aContextInfo, connection:aConnection };
}
