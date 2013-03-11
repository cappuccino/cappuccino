/*
 * CPDocumentController.j
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
@import <Foundation/CPBundle.j>

@import "CPDocument.j"
@import "CPOpenPanel.j"
@import "CPMenuItem.j"
@import "CPWindowController.j"

@global CPApp


var CPSharedDocumentController = nil;

/*!
    @ingroup appkit
    @class CPDocumentController
    This class is responsible for managing an application's open documents.
*/
@implementation CPDocumentController : CPObject
{
    CPArray _documents;
    CPArray _documentTypes;
}

/*!
    Returns the singleton instance of the application's document controller. If it has not
    been created yet, it will be created then returned.
    @return a CPDocumentController
*/
+ (id)sharedDocumentController
{
    if (!CPSharedDocumentController)
        [[self alloc] init];

    return CPSharedDocumentController;
}

/*
    @ignore
*/
- (id)init
{
    self = [super init];

    if (self)
    {
        _documents = [[CPArray alloc] init];

        if (!CPSharedDocumentController)
            CPSharedDocumentController = self;

        _documentTypes = [[[CPBundle mainBundle] infoDictionary] objectForKey:@"CPBundleDocumentTypes"];
    }
    return self;
}

// Creating and Opening Documents

/*!
    Returns the document matching the specified URL. This
    method searches documents already open. It does not
    open the document at the URL if it is not already open.
    @param aURL the url of the document
    @return the document, or \c nil if such a document is not open
*/
- (CPDocument)documentForURL:(CPURL)aURL
{
    var index = 0,
        count = [_documents count];

    for (; index < count; ++index)
    {
        var theDocument = _documents[index];

        if ([[theDocument fileURL] isEqual:aURL])
            return theDocument;
    }

    return nil;
}

/*!
    Creates a new document of the specified type.
    @param aType the type of the new document
    @param shouldDisplay whether to display the document on screen
*/
- (void)openUntitledDocumentOfType:(CPString)aType display:(BOOL)shouldDisplay
{
    var theDocument = [self makeUntitledDocumentOfType:aType error:nil];

    if (theDocument)
        [self addDocument:theDocument];

    if (shouldDisplay)
    {
        [theDocument makeWindowControllers];
        [theDocument showWindows];
    }

    return theDocument;
}

/*!
    Creates a document of the specified type.
    @param aType the document type
    @param anError not used
    @return the created document
*/
- (CPDocument)makeUntitledDocumentOfType:(CPString)aType error:(/*{*/CPError/*}*/)anError
{
    return [[[self documentClassForType:aType] alloc] initWithType:aType error:anError];
}

/*!
    Opens the document at the specified URL.
    @param anAbsoluteURL the path to the document's file
    @param shouldDisplay whether to display the document on screen
    @param anError not used
    @return the opened document
*/
- (CPDocument)openDocumentWithContentsOfURL:(CPURL)anAbsoluteURL display:(BOOL)shouldDisplay error:(CPError)anError
{
    var result = [self documentForURL:anAbsoluteURL];

    if (!result)
    {
        var type = [self typeForContentsOfURL:anAbsoluteURL error:anError];

        result = [self makeDocumentWithContentsOfURL:anAbsoluteURL ofType:type delegate:self didReadSelector:@selector(document:didRead:contextInfo:) contextInfo:@{ @"shouldDisplay": shouldDisplay }];

        [self addDocument:result];

        if (result)
            [self noteNewRecentDocument:result];
    }
    else if (shouldDisplay)
        [result showWindows];

    return result;
}

/*!
    Loads a document for a specified URL with it's content
    retrieved from another URL.
    @param anAbsoluteURL the document URL
    @param absoluteContentsURL the location of the document's contents
    @param anError not used
    @return the loaded document or \c nil if there was an error
*/
- (CPDocument)reopenDocumentForURL:(CPURL)anAbsoluteURL withContentsOfURL:(CPURL)absoluteContentsURL error:(CPError)anError
{
    return [self makeDocumentForURL:anAbsoluteURL withContentsOfURL:absoluteContentsURL  ofType:[[_documentTypes objectAtIndex:0] objectForKey:@"CPBundleTypeName"] delegate:self didReadSelector:@selector(document:didRead:contextInfo:) contextInfo:nil];
}

/*!
    Creates a document from the contents at the specified URL.
    Notifies the provided delegate with the provided selector afterwards.
    @param anAbsoluteURL the location of the document data
    @param aType the document type
    @param aDelegate the delegate to notify
    @param aSelector the selector to notify with
    @param aContextInfo the context information passed to the delegate
*/
- (CPDocument)makeDocumentWithContentsOfURL:(CPURL)anAbsoluteURL ofType:(CPString)aType delegate:(id)aDelegate didReadSelector:(SEL)aSelector contextInfo:(id)aContextInfo
{
    return [[[self documentClassForType:aType] alloc] initWithContentsOfURL:anAbsoluteURL ofType:aType delegate:aDelegate didReadSelector:aSelector contextInfo:aContextInfo];
}

/*!
    Creates a document from the contents of a URL, and sets
    the document's URL location as another URL.
    @param anAbsoluteURL the document's location
    @param absoluteContentsURL the location of the document's contents
    @param aType the document's data type
    @param aDelegate receives a callback after the load has completed
    @param aSelector the selector to invoke for the callback
    @param aContextInfo an object passed as an argument for the callback
    @return a new document or \c nil if there was an error
*/
- (CPDocument)makeDocumentForURL:(CPURL)anAbsoluteURL withContentsOfURL:(CPURL)absoluteContentsURL ofType:(CPString)aType delegate:(id)aDelegate didReadSelector:(SEL)aSelector contextInfo:(id)aContextInfo
{
    return [[[self documentClassForType:aType] alloc] initForURL:anAbsoluteURL withContentsOfURL:absoluteContentsURL ofType:aType delegate:aDelegate didReadSelector:aSelector contextInfo:aContextInfo];
}

/*
    Implemented delegate method
    @ignore
*/
- (void)document:(CPDocument)aDocument didRead:(BOOL)didRead contextInfo:(id)aContextInfo
{
    if (!didRead)
        return;

    [aDocument makeWindowControllers];

    if ([aContextInfo objectForKey:@"shouldDisplay"])
        [aDocument showWindows];
}

/*!
    Opens a new document in the application.
    @param aSender the requesting object
*/
- (CFAction)newDocument:(id)aSender
{
    [self openUntitledDocumentOfType:[[_documentTypes objectAtIndex:0] objectForKey:@"CPBundleTypeName"] display:YES];
}

- (void)openDocument:(id)aSender
{
    var openPanel = [CPOpenPanel openPanel];

    [openPanel runModal];

    var URLs = [openPanel URLs],
        index = 0,
        count = [URLs count];

    for (; index < count; ++index)
        [self openDocumentWithContentsOfURL:[CPURL URLWithString:URLs[index]] display:YES error:nil];
}

// Managing Documents

/*!
    Returns the array of all documents being managed. This is
    the same as all open documents in the application.
*/
- (CPArray)documents
{
    return _documents;
}

/*!
    Adds \c aDocument under the control of the receiver.
    @param aDocument the document to add
*/
- (void)addDocument:(CPDocument)aDocument
{
    [_documents addObject:aDocument];
}

/*!
    Removes \c aDocument from the control of the receiver.
    @param aDocument the document to remove
*/
- (void)removeDocument:(CPDocument)aDocument
{
    [_documents removeObjectIdenticalTo:aDocument];
}

- (CPString)defaultType
{
    return [_documentTypes[0] objectForKey:@"CPBundleTypeName"];
}

- (CPString)typeForContentsOfURL:(CPURL)anAbsoluteURL error:(CPError)outError
{
    var index = 0,
        count = _documentTypes.length,

        extension = [[anAbsoluteURL pathExtension] lowercaseString],
        starType = nil;

    for (; index < count; ++index)
    {
        var documentType = _documentTypes[index],
            extensions = [documentType objectForKey:@"CFBundleTypeExtensions"],
            extensionIndex = 0,
            extensionCount = extensions.length;

        for (; extensionIndex < extensionCount; ++extensionIndex)
        {
            var thisExtension = [extensions[extensionIndex] lowercaseString];
            if (thisExtension === extension)
                return [documentType objectForKey:@"CPBundleTypeName"];

            if (thisExtension === "****")
                starType = [documentType objectForKey:@"CPBundleTypeName"];
        }
    }

    return starType || [self defaultType];
}

// Managing Document Types

/* @ignore */
- (CPDictionary)_infoForType:(CPString)aType
{
    var i = 0,
        count = [_documentTypes count];

    for (;i < count; ++i)
    {
        var documentType = _documentTypes[i];

        if ([documentType objectForKey:@"CPBundleTypeName"] == aType)
            return documentType;
    }

    return nil;
}

/*!
    Returns the CPDocument subclass associated with \c aType.
    @param aType the type of document
    @return a Cappuccino Class object, or \c nil if no match was found
*/
- (Class)documentClassForType:(CPString)aType
{
    var className = [[self _infoForType:aType] objectForKey:@"CPDocumentClass"];

    return className ? CPClassFromString(className) : nil;
}

@end

@implementation CPDocumentController (Closing)

- (void)closeAllDocumentsWithDelegate:(id)aDelegate didCloseAllSelector:(SEL)didCloseSelector contextInfo:(Object)info
{
    var context = {
            delegate: aDelegate,
            selector: didCloseSelector,
            context: info
        };

    [self _closeDocumentsStartingWith:nil shouldClose:YES context:context];
}

// Recursive callback method. Start it by passing in a document of nil.
- (void)_closeDocumentsStartingWith:(CPDocument)aDocument shouldClose:(BOOL)shouldClose context:(Object)context
{
    if (shouldClose)
    {
        [aDocument close];

        if ([[self documents] count] > 0)
        {
            [[[self documents] lastObject] canCloseDocumentWithDelegate:self
                                                    shouldCloseSelector:@selector(_closeDocumentsStartingWith:shouldClose:context:)
                                                            contextInfo:context];
            return;
        }
    }

    if ([context.delegate respondsToSelector:context.selector])
        objj_msgSend(context.delegate, context.selector, self, [[self documents] count] === 0, context.context);
}

@end

@implementation CPDocumentController (Recents)

- (CPArray)recentDocumentURLs
{
    // FIXME move this to CP land
    if (typeof window["cpRecentDocumentURLs"] === 'function')
        return window.cpRecentDocumentURLs();

    return [];
}

- (void)clearRecentDocuments:(id)sender
{
    if (typeof window["cpClearRecentDocuments"] === 'function')
        window.cpClearRecentDocuments();

   [self _updateRecentDocumentsMenu];
}

- (void)noteNewRecentDocument:(CPDocument)aDocument
{
    [self noteNewRecentDocumentURL:[aDocument fileURL]];
}

- (void)noteNewRecentDocumentURL:(CPURL)aURL
{
    var urlAsString = [aURL isKindOfClass:CPString] ? aURL : [aURL absoluteString];
    if (typeof window["cpNoteNewRecentDocumentPath"] === 'function')
        window.cpNoteNewRecentDocumentPath(urlAsString);

   [self _updateRecentDocumentsMenu];
}

- (void)_removeAllRecentDocumentsFromMenu:(CPMenu)aMenu
{
    var items = [aMenu itemArray],
        count = [items count];

    while (count--)
    {
        var item = items[count];

        if ([item action] === @selector(_openRecentDocument:))
            [aMenu removeItemAtIndex:count];
    }
}

- (void)_updateRecentDocumentsMenu
{
    var menu = [[CPApp mainMenu] _menuWithName:@"_CPRecentDocumentsMenu"],
        recentDocuments = [self recentDocumentURLs],
        menuItems = [menu itemArray],
        documentCount = [recentDocuments count],
        menuItemCount = [menuItems count];

    [self _removeAllRecentDocumentsFromMenu:menu];

    if (menuItemCount)
    {
        if (!documentCount)
        {
            if ([menuItems[0] isSeparatorItem])
                [menu removeItemAtIndex:0];
        }
        else
        {
            if (![menuItems[0] isSeparatorItem])
                [menu insertItem:[CPMenuItem separatorItem] atIndex:0];
        }
    }

    while (documentCount--)
    {
        var path = recentDocuments[documentCount],
            item = [[CPMenuItem alloc] initWithTitle:[path lastPathComponent] action:@selector(_openRecentDocument:) keyEquivalent:nil];

        [item setTag:path];
        [menu insertItem:item atIndex:0];
    }
}

- (void)_openRecentDocument:(id)sender
{
    [self openDocumentWithContentsOfURL:[sender tag] display:YES error:nil];
}

@end
