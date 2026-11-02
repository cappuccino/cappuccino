/*
 *  CPItemProvider.j
 *  Foundation
 *
 *  Created by David Richardson on 2026-11-02.
 *  Copyright David Richardson 2026.
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

@import "CPObject.j"
@import "CPArray.j"
@import "CPData.j"
@import "CPDictionary.j"
@import "CPError.j"
@import "CPRunLoop.j"
@import "CPString.j"

@global FileReader

CPItemProviderErrorDomain                   = @"CPItemProviderErrorDomain";

CPItemProviderUnknownError                  = -1;
CPItemProviderItemUnavailableError          = -1000;
CPItemProviderUnexpectedValueClassError     = -1100;

/*
    TODO: Gaps against NSItemProvider that can be filled:

    - -loadDataRepresentationForTypeIdentifier:completionHandler: returns an NSProgress in Cocoa,
      which reports reading progress and cancels the load. Foundation has no CPProgress yet.
      Cancelling a file read would call FileReader's abort().
    - Object loading: -canLoadObjectOfClass:, -loadObjectOfClass:completionHandler:,
      -registerObject:visibility:, -initWithObject: and -initWithItem:typeIdentifier:, with the
      reading and writing protocols. Loading a CPString this way could decode the browser's
      buffer directly with TextDecoder.
    - Files are read into a plain JavaScript array with one number per byte, because CFData
      stores bytes that way. A large file needs many times its own size in memory.
*/

/*!
    @class CPItemProvider
    @ingroup foundation
    @brief Supplies data, such as the contents of a file, to the application asynchronously.

    An item provider stands for one item: a file the user chose in an open panel, or pasted. It
    registers one or more representations of the item, each identified by a type identifier,
    and loads a representation on request.

    This class is modelled on NSItemProvider. It differs from it where the browser requires:

    - Type identifiers are MIME types, such as \c "image/png", because the browser identifies
      files that way. A type identifier given to a query may also be a wildcard of the form
      \c "image/*", which matches every type of that kind.
    - Loading is always asynchronous. A browser reads a file in the background and reports the
      result later, from outside the run loop. The completion handler is called inside a run
      loop pass, so that undo groups close, bindings update and the display changes as they do
      after any other event.
    - There is no file representation. A browser gives the page no path to a file, so the item
      is available only as data.
    - Representations have no visibility. A page is one process, so Cocoa's visibility levels
      have no meaning.

    A completion handler receives the data, or nil and an error:

    <pre>
    [anItemProvider loadDataRepresentationForTypeIdentifier:@"image/*" completionHandler:function(data, error)
    {
        if (data)
            [self useData:data];
    }];
    </pre>
*/
@implementation CPItemProvider : CPObject
{
    CPArray         _registeredTypeIdentifiers;
    CPDictionary    _loadHandlers;
    CPString        _suggestedName  @accessors(property=suggestedName);
}

/*!
    Returns YES if \c aRegisteredTypeIdentifier matches \c aTypeIdentifier, which may be a
    wildcard of the form "image/*". A star on both sides of the slash matches every type.
    @ignore
*/
+ (BOOL)_typeIdentifier:(CPString)aRegisteredTypeIdentifier conformsToTypeIdentifier:(CPString)aTypeIdentifier
{
    if (!aRegisteredTypeIdentifier || !aTypeIdentifier)
        return NO;

    var registered = aRegisteredTypeIdentifier.toLowerCase(),
        requested = aTypeIdentifier.toLowerCase();

    if (requested === registered || requested === "*/*")
        return YES;

    var slashIndex = requested.indexOf("/");

    if (slashIndex < 0 || requested.substring(slashIndex) !== "/*")
        return NO;

    return registered.indexOf(requested.substring(0, slashIndex + 1)) === 0;
}

/*!
    Returns an item provider for a browser File object. The provider registers the file's MIME
    type, or "application/octet-stream" when the browser does not know it, and suggests the
    file's name. A file chosen from a folder is named by its path inside that folder.
    @ignore
*/
+ (CPItemProvider)_itemProviderWithFile:(File)aFile
{
    var itemProvider = [[self alloc] init],
        typeIdentifier = aFile.type || @"application/octet-stream";

    [itemProvider setSuggestedName:aFile.webkitRelativePath || aFile.name];
    [itemProvider registerDataRepresentationForTypeIdentifier:typeIdentifier loadHandler:function(completionHandler)
    {
        [CPItemProvider _readFile:aFile completionHandler:completionHandler];
    }];

    return itemProvider;
}

/*!
    Returns item providers for a browser FileList, or an array of File objects, in their
    original order.
    @ignore
*/
+ (CPArray)_itemProvidersWithFiles:(FileList)someFiles
{
    var itemProviders = [];

    for (var i = 0, count = someFiles ? someFiles.length : 0; i < count; i++)
        itemProviders.push([self _itemProviderWithFile:someFiles[i]]);

    return itemProviders;
}

/*!
    Reads a browser File object with FileReader, and calls \c aCompletionHandler with its
    contents as data, or with nil and an error.
    @ignore
*/
+ (void)_readFile:(File)aFile completionHandler:(Function)aCompletionHandler
{
    if (typeof FileReader === "undefined")
    {
        aCompletionHandler(nil, [self _errorWithCode:CPItemProviderItemUnavailableError description:@"Files cannot be read in this environment."]);
        return;
    }

    var reader = new FileReader();

    reader.onload = function()
    {
        aCompletionHandler([CPData dataWithBytes:Array.from(new Uint8Array(reader.result))], nil);
    };

    reader.onerror = function()
    {
        var description = @"The file " + aFile.name + @" could not be read.";

        if (reader.error && reader.error.message)
            description += @" " + reader.error.message;

        aCompletionHandler(nil, [self _errorWithCode:CPItemProviderUnknownError description:description]);
    };

    reader.readAsArrayBuffer(aFile);
}

/*!
    @ignore
*/
+ (CPError)_errorWithCode:(int)aCode description:(CPString)aDescription
{
    return [CPError errorWithDomain:CPItemProviderErrorDomain
                               code:aCode
                           userInfo:@{ CPLocalizedDescriptionKey: aDescription }];
}

/*!
    Initializes an item provider with no representations.
*/
- (id)init
{
    if (self = [super init])
    {
        _registeredTypeIdentifiers = [];
        _loadHandlers = [CPMutableDictionary dictionary];
    }

    return self;
}

// MARK: Registering Representations

/*!
    Registers a data representation of the item. Representations are kept in the order they
    are registered, from the highest fidelity to the lowest. Registering a type identifier again
    replaces its load handler.

    The load handler is called with one argument, a completion handler. It must call that
    completion handler once, with the data, or with nil and an error. It may do so at once, or
    later.

    @param aTypeIdentifier a MIME type, such as "text/csv"
    @param aLoadHandler a function that takes a completion handler
*/
- (void)registerDataRepresentationForTypeIdentifier:(CPString)aTypeIdentifier loadHandler:(Function /*(Function completionHandler)*/)aLoadHandler
{
    if (![_registeredTypeIdentifiers containsObject:aTypeIdentifier])
        [_registeredTypeIdentifiers addObject:aTypeIdentifier];

    [_loadHandlers setObject:aLoadHandler forKey:aTypeIdentifier];
}

/*!
    Returns the registered type identifiers, from the highest fidelity to the lowest.
*/
- (CPArray)registeredTypeIdentifiers
{
    return [_registeredTypeIdentifiers copy];
}

/*!
    Returns YES if a registered representation matches \c aTypeIdentifier, which may be a
    wildcard of the form "image/*".
*/
- (BOOL)hasItemConformingToTypeIdentifier:(CPString)aTypeIdentifier
{
    return [self _registeredTypeIdentifierConformingToTypeIdentifier:aTypeIdentifier] !== nil;
}

/*!
    Returns YES if a registered representation matches \c aTypeIdentifier. In a browser every
    representation is data, so this is the same as -hasItemConformingToTypeIdentifier:.
*/
- (BOOL)hasRepresentationConformingToTypeIdentifier:(CPString)aTypeIdentifier
{
    return [self hasItemConformingToTypeIdentifier:aTypeIdentifier];
}

/*!
    Returns the first registered type identifier that matches \c aTypeIdentifier, or nil.
    @ignore
*/
- (CPString)_registeredTypeIdentifierConformingToTypeIdentifier:(CPString)aTypeIdentifier
{
    for (var i = 0, count = [_registeredTypeIdentifiers count]; i < count; i++)
    {
        var registeredTypeIdentifier = _registeredTypeIdentifiers[i];

        if ([CPItemProvider _typeIdentifier:registeredTypeIdentifier conformsToTypeIdentifier:aTypeIdentifier])
            return registeredTypeIdentifier;
    }

    return nil;
}

// MARK: Loading Representations

/*!
    Loads the first registered representation that matches \c aTypeIdentifier, which may be a
    wildcard of the form "image/*". The completion handler is called once, inside a run loop
    pass, with the data and nil, or with nil and an error.

    @param aTypeIdentifier the type identifier to load
    @param aCompletionHandler a function that takes the data and an error
*/
- (void)loadDataRepresentationForTypeIdentifier:(CPString)aTypeIdentifier completionHandler:(Function /*(CPData data, CPError error)*/)aCompletionHandler
{
    var registeredTypeIdentifier = [self _registeredTypeIdentifierConformingToTypeIdentifier:aTypeIdentifier],
        didComplete = NO,
        complete = function(data, error)
        {
            if (didComplete)
                return;

            didComplete = YES;

            if (aCompletionHandler)
                aCompletionHandler(data || nil, data ? nil : error || [CPItemProvider _errorWithCode:CPItemProviderUnknownError description:@"The item could not be loaded."]);

            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        };

    if (!registeredTypeIdentifier)
    {
        complete(nil, [CPItemProvider _errorWithCode:CPItemProviderItemUnavailableError description:@"The item has no representation of type " + aTypeIdentifier + @"."]);
        return;
    }

    var loadHandler = [_loadHandlers objectForKey:registeredTypeIdentifier];

    loadHandler(function(data, error)
    {
        if (data && ![data isKindOfClass:[CPData class]])
        {
            complete(nil, [CPItemProvider _errorWithCode:CPItemProviderUnexpectedValueClassError description:@"The item's load handler returned an object that is not data."]);
            return;
        }

        complete(data, error);
    });
}

/*!
    Returns a description of the item provider: its suggested name and its type identifiers.
*/
- (CPString)description
{
    return [super description] + @" " + (_suggestedName || @"(unnamed)") + @" " + [_registeredTypeIdentifiers componentsJoinedByString:@", "];
}

@end
