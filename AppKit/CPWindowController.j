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

import <Foundation/CPObject.j>
import <Foundation/CPString.j>

import "CPResponder.j"
import "CPWindow.j"
import "CPDocument.j"

#include "Platform/Platform.h"


@implementation CPWindowController : CPResponder
{
    id          _owner;
    CPWindow    _window;
    CPDocument  _document;
    CPString    _windowCibName;
}

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

- (id)initWithWindowCibName:(CPString)aWindowCibName
{
    return [self initWithWindowCibName:aWindowCibName owner:self];
}

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

- (void)loadWindow
{
    [self windowWillLoad];
    //FIXME: ACTUALLY LOAD WINDOW!!!
    [self setWindow:CPApp._keyWindow = [[CPWindow alloc] initWithContentRect:CPRectMakeZero() styleMask:CPBorderlessBridgeWindowMask|CPTitledWindowMask|CPClosableWindowMask|CPResizableWindowMask]];
    
    [self windowDidLoad];
}

- (CFAction)showWindow:(id)aSender
{
    var theWindow = [self window];

	if ([theWindow respondsToSelector:@selector(becomesKeyOnlyIfNeeded)] && [theWindow becomesKeyOnlyIfNeeded])
        [theWindow orderFront:aSender];
    else
        [theWindow makeKeyAndOrderFront:aSender];
}

- (BOOL)isWindowLoaded
{
    return _window;
}

- (CPWindow)window
{
    if (!_window)
         [self loadWindow];

    return _window;
}

- (void)setWindow:(CPWindow)aWindow
{
    _window = aWindow;
    
    [_window setWindowController:self];
    [_window setNextResponder:self];
}

- (void)windowDidLoad
{
    [_document windowControllerDidLoadNib:self];
    
    [self synchronizeWindowTitleWithDocumentName];
}

- (void)windowWillLoad
{
    [_document windowControllerWillLoadNib:self];
}

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

- (void)_documentWillSave:(CPNotification)aNotification
{
    [[self window] setDocumentSaving:YES];
}

- (void)_documentDidSave:(CPNotification)aNotification
{
    [[self window] setDocumentSaving:NO];
}

- (void)_documentDidFailToSave:(CPNotification)aNotification
{
    [[self window] setDocumentSaving:NO];
}

- (CPDocument)document
{
    return _document;
}

- (void)setDocumentEdited:(BOOL)isEdited
{
    [[self window] setDocumentEdited:isEdited];
}

// Setting and Getting Window Attributes

- (void)synchronizeWindowTitleWithDocumentName
{
    if (!_document || !_window)
        return;
    
    // [_window setRepresentedFilename:];
    [_window setTitle:[self windowTitleForDocumentDisplayName:[_document displayName]]];
}

- (CPString)windowTitleForDocumentDisplayName:(CPString)aDisplayName
{
    return aDisplayName;
}

@end
