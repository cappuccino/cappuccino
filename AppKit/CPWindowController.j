/*
 * CPWindowController.j
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

@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>

@import "CPResponder.j"
@import "CPWindow.j"
@import "CPDocument.j"

#include "Platform/Platform.h"


/*! @class CPWindowController

    An instance of a CPWindowController manages a CPWindow. It has methods
    that get called when the window is loading, and after the window has loaded. In the
    Model-View-Controller method of program design, the CPWindowController would be
    considered the 'Controller' and the CPWindow the 'Model.'
*/
@implementation CPWindowController : CPResponder
{
    id          _owner;
    CPWindow    _window;
    CPDocument  _document;
    CPString    _windowCibName;
}

/*!
    Initializes the controller with a window.
    @param aWindow the window to control
    @return the initialzed window controller
*/
- (id)initWithWindow:(CPWindow)aWindow
{
    self = [super init];
    
    if (self)
    {
        [self setWindow:aWindow];
    
        [self setNextResponder:CPApp];
    }
    
    return self;
}

/*!
    Initializes the controller with a Capppuccino Interface Builder name.
    @param aWindowCibName the cib name of the window to control
    @return the initialized window controller
*/
- (id)initWithWindowCibName:(CPString)aWindowCibName
{
    return [self initWithWindowCibName:aWindowCibName owner:self];
}

/*!
    Initializes the controller with a cafe name.
    @param aWindowCibName the cib name of the window to control
    @param anOwner the owner of the cib file
    @return the initialized window controller
*/
- (id)initWithWindowCibName:(CPString)aWindowCibName owner:(id)anOwner
{
    self = [super init];
    
    if (self)
    {
        _owner = anOwner;
        _windowCibName = aWindowCibName;
        
        [self setNextResponder:CPApp];
    }
    
    return self;
}

/*!
    Loads the window
*/
- (void)loadWindow
{
    [self windowWillLoad];
    //FIXME: ACTUALLY LOAD WINDOW!!!
    [self setWindow:CPApp._keyWindow = [[CPWindow alloc] initWithContentRect:CPRectMakeZero() styleMask:CPBorderlessBridgeWindowMask|CPTitledWindowMask|CPClosableWindowMask|CPResizableWindowMask]];
    
    [self windowDidLoad];
}

/*!
    Shows the window.
    @param aSender the object requesting the show
*/
- (CFAction)showWindow:(id)aSender
{
    var theWindow = [self window];

	if ([theWindow respondsToSelector:@selector(becomesKeyOnlyIfNeeded)] && [theWindow becomesKeyOnlyIfNeeded])
        [theWindow orderFront:aSender];
    else
        [theWindow makeKeyAndOrderFront:aSender];
}

/*!
    Returns <code>YES</code> if the window has been loaded. Specifically,
    if loadWindow has been called.
*/
- (BOOL)isWindowLoaded
{
    return _window;
}

/*!
    Returns the window this object controls.
*/
- (CPWindow)window
{
    if (!_window)
         [self loadWindow];

    return _window;
}

/*!
    Sets the window to be controlled.
    @param aWindow the new window to control
*/
- (void)setWindow:(CPWindow)aWindow
{
    _window = aWindow;
    
    [_window setWindowController:self];
    [_window setNextResponder:self];
}

/*!
    The method notifies the controller that it's window has loaded.
*/
- (void)windowDidLoad
{
    [_document windowControllerDidLoadNib:self];
    
    [self synchronizeWindowTitleWithDocumentName];
}

/*!
    The method notifies the controller that it's window is about to load.
*/
- (void)windowWillLoad
{
    [_document windowControllerWillLoadNib:self];
}

/*!
    Sets the document that is inside the controlled window.
    @param aDocument the document in the controlled window
*/
- (void)setDocument:(CPDocument)aDocument
{
    if (_document == aDocument)
        return;
    
    var defaultCenter = [CPNotificationCenter defaultCenter];
    
    if (_document)
    {
        [defaultCenter removeObserver:self
                                 name:CPDocumentWillSaveNotification
                               object:_document];
                               
        [defaultCenter removeObserver:self
                                 name:CPDocumentDidSaveNotification
                               object:_document];

        [defaultCenter removeObserver:self
                                 name:CPDocumentDidFailToSaveNotification
                               object:_document];
    }
    
    _document = aDocument;
    
    if (_document)
    {
        [defaultCenter addObserver:self
                          selector:@selector(_documentWillSave:)
                              name:CPDocumentWillSaveNotification
                            object:_document];
                            
        [defaultCenter addObserver:self
                          selector:@selector(_documentDidSave:)
                              name:CPDocumentDidSaveNotification
                            object:_document];

        [defaultCenter addObserver:self
                          selector:@selector(_documentDidFailToSave:)
                              name:CPDocumentDidFailToSaveNotification
                            object:_document];
                            
        [self setDocumentEdited:[_document isDocumentEdited]];
    }    
    
    [self synchronizeWindowTitleWithDocumentName];
}

/* @ignore */
- (void)_documentWillSave:(CPNotification)aNotification
{
    [[self window] setDocumentSaving:YES];
}

/* @ignore */
- (void)_documentDidSave:(CPNotification)aNotification
{
    [[self window] setDocumentSaving:NO];
}

/* @ignore */
- (void)_documentDidFailToSave:(CPNotification)aNotification
{
    [[self window] setDocumentSaving:NO];
}

/*!
    Returns the document in the controlled window.
*/
- (CPDocument)document
{
    return _document;
}

/*!
    Sets whether the document has unsaved changes. The window can use this as a hint to 
    @param isEdited <code>YES</code> means the document has unsaved changes.
*/
- (void)setDocumentEdited:(BOOL)isEdited
{
    [[self window] setDocumentEdited:isEdited];
}

// Setting and Getting Window Attributes

/*!
    Sets the title of the window as the name of the document.
*/
- (void)synchronizeWindowTitleWithDocumentName
{
    if (!_document || !_window)
        return;
    
    // [_window setRepresentedFilename:];
    [_window setTitle:[self windowTitleForDocumentDisplayName:[_document displayName]]];
}

/*!
    Returns the window title based on the document's name.
    @param aDisplayName the document's filename
*/
- (CPString)windowTitleForDocumentDisplayName:(CPString)aDisplayName
{
    return aDisplayName;
}

@end
