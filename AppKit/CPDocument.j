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

import <Foundation/CPString.j>
import <Foundation/CPArray.j>

import "CPResponder.j"
import "CPWindowController.j"


CPSaveOperation             = 0;
CPSaveAsOperation           = 1;
CPSaveToOperation           = 2;
CPAutosaveOperation         = 3;

CPChangeDone                = 0;
CPChangeUndone              = 1;
CPChangeCleared             = 2;
CPChangeReadOtherContents   = 3;
CPChangeAutosaved           = 4;

CPDocumentWillSaveNotification      = @"CPDocumentWillSaveNotification";
CPDocumentDidSaveNotification       = @"CPDocumentDidSaveNotification";
CPDocumentDidFailToSaveNotification = @"CPDocumentDidFailToSaveNotification";

var CPDocumentUntitledCount = 0;

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

- (id)initWithType:(CPString)aType error:({CPError})anError
{
    self = [self init];
    
    if (self)
        [self setFileType:aType];
    
    return self;
}

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

- (CPData)dataOfType:(CPString)aType error:({CPError})anError
{
    // FIXME: Throw Exception.
    return nil;
}

- (void)readFromData:(CPData)aData ofType:(CPString)aType error:(CPError)anError
{
}

// Creating and managing window controllers

- (void)makeWindowControllers
{
    var controller = [[CPWindowController alloc] initWithWindowCibName:nil];
    
    [self addWindowController:controller];
}

- (CPArray)windowControllers
{
    return _windowControllers;
}

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

- (void)showWindows
{
    [_windowControllers makeObjectsPerformSelector:@selector(showWindow:) withObject:self];
}

- (CPString)displayName
{
    //  FIXME: By default, return last path component of fileURL
    if (!_untitledDocumentIndex)
        _untitledDocumentIndex = ++CPDocumentUntitledCount;
	
	if (_untitledDocumentIndex == 1)
	   return @"Untitled";
	
	return @"Untitled " + _untitledDocumentIndex;
}

- (CPString)windowCibName
{
    return nil;
}

- (void)windowControllerDidLoadNib:(CPWindowController)aWindowController
{
}

- (void)windowControllerWillLoadNib:(CPWindowController)aWindowController
{
}

// Reading from and Writing to URLs

- (void)readFromURL:(CPURL)anAbsoluteURL ofType:(CPString)aType delegate:(id)aDelegate didReadSelector:(SEL)aDidReadSelector contextInfo:(id)aContextInfo
{
    [_readConnection cancel];

    // FIXME: Oh man is this every looking for trouble, we need to handle login at the Cappuccino level, with HTTP Errors.
    _readConnection = [CPURLConnection connectionWithRequest:[CPURLRequest requestWithURL:anAbsoluteURL] delegate:self];
    
    _readConnection.session = _CPReadSessionMake(aType, aDelegate, aDidReadSelector, aContextInfo);
}

- (CPURL)fileURL
{
    return _fileURL;
}

- (void)setFileURL:(CPURL)aFileURL
{
    if (_fileURL == aFileURL)
        return;
    
    _fileURL = aFileURL;
    
    [_windowControllers makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
}

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

- (void)connectionDidFinishLoading:(CPURLConnection)aConnection
{
    if (_readConnection == aConnection)
        _readConnection = nil;
}

// Managing Document Status

- (BOOL)isDocumentEdited
{
    return _changeCount != 0;
}

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

- (void)setFileType:(CPString)aType
{
    _fileType = aType;
}

- (CPString)fileType
{
    return _fileType;
}

// Working with Undo Manager

- (BOOL)hasUndoManager
{
    return _hasUndoManager;
}

- (void)setHashUndoManager:(BOOL)aFlag
{
    if (_hasUndoManager == aFlag)
        return;
    
    _hasUndoManager = aFlag;
    
    if (!_hasUndoManager)
        [self setUndoManager:nil];
}

- (void)_undoManagerWillCloseGroup:(CPNotification)aNotification
{
    var undoManager = [aNotification object];
    
    if ([undoManager isUndoing] || [undoManager isRedoing])
        return;

    [self updateChangeCount:CPChangeDone];
}

- (void)_undoManagerDidUndoChange:(CPNotification)aNotification
{
    [self updateChangeCount:CPChangeUndone];
}

- (void)_undoManagerDidRedoChange:(CPNotification)aNotification
{
    [self updateChangeCount:CPChangeDone];
}

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

- (CPUndoManager)undoManager
{
    if (_hasUndoManager && !_undoManager)
        [self setUndoManager:[[CPUndoManager alloc] init]];

    return _undoManager;
}

- (CPUndoManager)windowWillReturnUndoManager:(CPWindow)aWindow
{
    return [self undoManager];
}

// Handling User Actions

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
