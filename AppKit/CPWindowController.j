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

@import "CPCib.j"
@import "CPResponder.j"
@import "CPWindow.j"

@class CPDocument

@global CPApp
@global CPDocumentWillSaveNotification
@global CPDocumentDidSaveNotification
@global CPDocumentDidFailToSaveNotification


/*!
    @ingroup appkit
    @class CPWindowController

    An instance of a CPWindowController manages a CPWindow. Windows are typically loaded via a cib,
    but they can also manage windows created in code. A CPWindowController can manage a window by
    itself or work with AppKit's document-based architecture.

    In a Document based app, a CPWindowController instance is created and managed by a CPDocument subclass.

    If the CPWindowController is managing a CPWindow created in a cib the \c owner of the CPWindow is this controller.

    @note When creating the window programatically (instead of a cib) you should override the \c loadWindow method.\c loadWindow is called the first time the window object is needed. @endnote
*/
@implementation CPWindowController : CPResponder
{
    CPWindow            _window;

    CPArray             _documents;
    CPDocument          _document;
    BOOL                _shouldCloseDocument;
    BOOL                _supportsMultipleDocuments;

    id                  _cibOwner;
    CPString            _windowCibName;
    CPString            _windowCibPath;

    CPViewController    _viewController;
    CPView              _viewControllerContainerView;
}

- (id)init
{
    return [self initWithWindow:nil];
}

/*!
    Initializes the controller with a window.
    @param aWindow the window to control
    @return the initialized window controller
*/
- (id)initWithWindow:(CPWindow)aWindow
{
    self = [super init];

    if (self)
    {
        [self setWindow:aWindow];
        [self setShouldCloseDocument:NO];

        [self setNextResponder:CPApp];

        _documents = [];
    }

    return self;
}

/*!
    Initializes the controller with a Cappuccino Interface Builder name.
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
    self = [self initWithWindow:nil];

    if (self)
    {
        _cibOwner = anOwner;
        _windowCibName = aWindowCibName;
    }

    return self;
}

- (id)initWithWindowCibPath:(CPString)aWindowCibPath owner:(id)anOwner
{
    self = [self initWithWindow:nil];

    if (self)
    {
        _cibOwner = anOwner;
        _windowCibPath = aWindowCibPath;
    }

    return self;
}

/*!
    Loads the window. This method should never be called directly. Instead call \c window which will in turn call windowWillLoad and windowDidLoad.
    This method should be overwritten if you are creating the view programatically.
*/
- (void)loadWindow
{
    if (_window)
        return;

    [[CPBundle mainBundle] loadCibFile:[self windowCibPath] externalNameTable:@{ CPCibOwner: _cibOwner }];
}

/*!
    Shows the window.
    @param aSender the object requesting the show
*/
- (@action)showWindow:(id)aSender
{
    var theWindow = [self window];

    if ([theWindow respondsToSelector:@selector(becomesKeyOnlyIfNeeded)] && [theWindow becomesKeyOnlyIfNeeded])
        [theWindow orderFront:aSender];
    else
        [theWindow makeKeyAndOrderFront:aSender];
}

/*!
    Returns \c YES if the window has been loaded. Specifically,
    if loadWindow has been called.
*/
- (BOOL)isWindowLoaded
{
    return _window !== nil;
}

/*!
    Returns the CPWindow the reciever controls.
    This will cause \c loadWindow to be called if no window object exists yet.
*/
- (CPWindow)window
{
    if (!_window)
    {
        [self windowWillLoad];
        [_document windowControllerWillLoadCib:self];

        [self loadWindow];

        if (_window === nil && [_cibOwner isKindOfClass:[CPDocument class]])
            [self setWindow:[_cibOwner valueForKey:@"window"]];

        if (!_window)
        {
            var reason = [CPString stringWithFormat:@"Window for %@ could not be loaded from Cib or no window specified. Override loadWindow to load the window manually.", self];

            [CPException raise:CPInternalInconsistencyException reason:reason];
        }

        [self windowDidLoad];
        [_document windowControllerDidLoadCib:self];

        [self synchronizeWindowTitleWithDocumentName];
    }

    return _window;
}

/*!
    Sets the window to be controlled.
    @param aWindow the new window to control
*/
- (void)setWindow:(CPWindow)aWindow
{
    [_window setWindowController:nil];

    _window = aWindow;

    [_window setWindowController:self];
    [_window setNextResponder:self];
}

/*!
    The method notifies the controller that it's window has loaded.
*/
- (void)windowDidLoad
{
}

/*!
    The method notifies the controller that it's window is about to load.
*/
- (void)windowWillLoad
{
}

/*!
    Sets the document that is inside the controlled window.
    @param aDocument the document in the controlled window
*/
- (void)setDocument:(CPDocument)aDocument
{
    if (_document === aDocument)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter];

    if (_document)
    {
        if (![self supportsMultipleDocuments])
            [self removeDocument:_document];

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
        [self addDocument:_document];

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

    var viewController = [_document viewControllerForWindowController:self];

    if (viewController)
        [self setViewController:viewController];

    [self synchronizeWindowTitleWithDocumentName];

    // Change of document means toolbar items may no longer make sense.
    // FIXME: DOCUMENT ARCHITECTURE Should we setToolbar: as well?
    [[[self window] toolbar] _autoValidateVisibleItems];
}

- (void)setSupportsMultipleDocuments:(BOOL)shouldSupportMultipleDocuments
{
    _supportsMultipleDocuments = shouldSupportMultipleDocuments;
}

- (BOOL)supportsMultipleDocuments
{
    return _supportsMultipleDocuments;
}

- (void)addDocument:(CPDocument)aDocument
{
    if (aDocument && ![_documents containsObject:aDocument])
        [_documents addObject:aDocument];
}

- (void)removeDocument:(CPDocument)aDocument
{
    var index = [_documents indexOfObjectIdenticalTo:aDocument];

    if (index === CPNotFound)
        return;

    [_documents removeObjectAtIndex:index];

    if (_document === aDocument && [_documents count])
        [self setDocument:[_documents objectAtIndex:MIN(index, [_documents count] - 1)]];
}

- (void)removeDocumentAndCloseIfNecessary:(CPDocument)aDocument
{
    [self removeDocument:aDocument];

    if (![_documents count])
        [self close];
}

- (CPArray)documents
{
    return _documents;
}

- (void)setViewControllerContainerView:(CPView)aView
{
    if (!_viewControllerContainerView && !aView)
        return;

    var viewController = [self viewController],
        viewControllerView = [viewController isViewLoaded] ? [viewController view] : nil,
        contentView = [[self window] contentView];

    if (aView)
    {
        [aView setFrame:[contentView frame]];
        [aView setAutoresizingMask:[contentView autoresizingMask]];

        if (viewControllerView)
        {
            [viewControllerView removeFromSuperview];
            [aView addSubview:viewControllerView];
        }

        [[self window] setContentView:aView];
    }
    else if (viewControllerView)
    {
        [viewControllerView removeFromSuperview];
        [viewControllerView setFrame:[contentView frame]];
        [viewControllerView setAutoresizingMask:[contentView autoresizingMask]]
        [[self window] setContentView:viewControllerView];
    }
    else
    {
        var view = [[CPView alloc] init];
        [view setFrame:[contentView frame]];
        [view setAutoresizingMask:[contentView autoresizingMask]];
        [[self window] setContentView:view]
    }

    _viewControllerContainerView = aView;
}

- (void)viewControllerContainerView
{
    return _viewControllerContainerView;
}

- (void)setViewController:(CPViewController)aViewController
{
    if (!_viewController && !aViewController)
        return;

    var containerView = [self viewControllerContainerView],
        newView = [aViewController isViewLoaded] ? [aViewController view] : nil;

    if (containerView)
    {
        var oldView = [_viewController isViewLoaded] ? [_viewController view] : nil;

        if (oldView)
        {
            [newView setFrame:[oldView frame]];
            [newView setAutoresizingMask:[oldView autoresizingMask]];
        }

        if (oldView && newView)
            [containerView replaceSubview:oldView with:newView];
        else if (oldView)
            [oldView removeFromSuperview];
        else if (newView)
            [containerView addSubview:newView];
    }
    else if (newView)
    {
        var contentView = [[self window] contentView];
        [newView setFrame:[contentView frame]];
        [newView setAutoresizingMask:[contentView autoresizingMask]];
        [[self window] setContentView:newView];
    }
    else
    {
        var view = [[CPView alloc] init],
            contentView = [[self window] contentView];

        [view setFrame:[contentView frame]];
        [view setAutoresizingMask:[contentView autoresizingMask]];
        [[self window] setContentView:view]
    }

    _viewController = aViewController;
}

- (CPViewController)viewController
{
    return _viewController;
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
    Returns the CPDocument in the controlled window.
*/
- (CPDocument)document
{
    return _document;
}

/*!
    Sets whether the document has unsaved changes. The window can use this as a hint to
    @param isEdited \c YES means the document has unsaved changes.
*/
- (void)setDocumentEdited:(BOOL)isEdited
{
    [[self window] setDocumentEdited:isEdited];
}

- (void)close
{
    [[self window] close];
}

- (void)setShouldCloseDocument:(BOOL)shouldCloseDocument
{
    _shouldCloseDocument = shouldCloseDocument;
}

- (BOOL)shouldCloseDocument
{
    return _shouldCloseDocument;
}

- (id)owner
{
    return _cibOwner;
}

- (CPString)windowCibName
{
    if (_windowCibName)
        return _windowCibName;

    return [[_windowCibPath lastPathComponent] stringByDeletingPathExtension];
}

- (CPString)windowCibPath
{
    if (_windowCibPath)
        return _windowCibPath;

    return [[CPBundle mainBundle] pathForResource:_windowCibName + @".cib"];
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
