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

import <Foundation/CPObject.j>
import <Foundation/CPBundle.j>

import "CPDocument.j"

var CPSharedDocumentController = nil;

@implementation CPDocumentController : CPObject
{
    CPArray _documents;
    CPArray _documentTypes;
}

+ (id)sharedDocumentController
{
    if (!CPSharedDocumentController)
        [[self alloc] init];
    
    return CPSharedDocumentController;
}

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

- (void)openUntitledDocumentOfType:(CPString)aType display:(BOOL)shouldDisplay
{
    var document = [self makeUntitledDocumentOfType:aType error:nil];
    
    if (document)
        [self addDocument:document];
    
    if (shouldDisplay)
    {
        [document makeWindowControllers];
        [document showWindows];
    }
        
    return document;
}

- (CPDocument)makeUntitledDocumentOfType:(CPString)aType error:({CPError})anError
{
    return [[[self documentClassForType:aType] alloc] initWithType:aType error:anError];
}

- (CPDocument)openDocumentWithContentsOfURL:(CPURL)anAbsoluteURL display:(BOOL)shouldDisplay error:(CPError)anError
{
    var result = [self documentForURL:anAbsoluteURL];
    
    if (!result)
        // FIXME: type(!)
        result = [self makeDocumentWithContentsOfURL:anAbsoluteURL ofType:[[_documentTypes objectAtIndex:0] objectForKey:@"CPBundleTypeName"] delegate:self didReadSelector:@selector(document:didRead:contextInfo:) contextInfo:nil];
    
    else if (shouldDisplay)
        [result showWindows];
    
    return result;
}

- (CPDocument)reopenDocumentForURL:(CPURL)anAbsoluteURL withContentsOfURL:(CPURL)absoluteContentsURL error:(CPError)anError
{
    return [self makeDocumentForURL:anAbsoluteURL withContentsOfURL:absoluteContentsURL  ofType:[[_documentTypes objectAtIndex:0] objectForKey:@"CPBundleTypeName"] delegate:self didReadSelector:@selector(document:didRead:contextInfo:) contextInfo:nil];
}

- (CPDocument)makeDocumentWithContentsOfURL:(CPURL)anAbsoluteURL ofType:(CPString)aType delegate:(id)aDelegate didReadSelector:(SEL)aSelector contextInfo:(id)aContextInfo
{
    return [[[self documentClassForType:aType] alloc] initWithContentsOfURL:anAbsoluteURL ofType:aType delegate:aDelegate didReadSelector:aSelector contextInfo:aContextInfo];
}

- (CPDocument)makeDocumentForURL:(CPURL)anAbsoluteURL withContentsOfURL:(CPURL)absoluteContentsURL ofType:(CPString)aType delegate:(id)aDelegate didReadSelector:(SEL)aSelector contextInfo:(id)aContextInfo
{
    return [[[self documentClassForType:aType] alloc] initForURL:anAbsoluteURL withContentsOfURL:absoluteContentsURL ofType:aType delegate:aDelegate didReadSelector:aSelector contextInfo:aContextInfo];
}

- (void)document:(CPDocument)aDocument didRead:(BOOL)didRead contextInfo:(id)aContextInfo
{
    if (!didRead)
        return;

    [self addDocument:aDocument];
    [aDocument makeWindowControllers];
}

- (CFAction)newDocument:(id)aSender
{
    [self openUntitledDocumentOfType:[[_documentTypes objectAtIndex:0] objectForKey:@"CPBundleTypeName"] display:YES];
}

// Managing Documents

- (CPArray)documents
{
    return _documents;
}

- (void)addDocument:(CPDocument)aDocument
{
    [_documents addObject:aDocument];
}

- (void)removeDocument:(CPDocument)aDocument
{
    [_documents removeObjectIdenticalTo:aDocument];
}

// Managing Document Types

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

- (Class)documentClassForType:(CPString)aType
{
    var className = [[self _infoForType:aType] objectForKey:@"CPDocumentClass"];

    return className ? CPClassFromString(className) : Nil;
}

@end
