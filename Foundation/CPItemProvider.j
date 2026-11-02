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
@import "CPProgress.j"
@import "CPRunLoop.j"
@import "CPString.j"
@import "CPString+Encoding.j"

@global FileReader

CPItemProviderErrorDomain                   = @"CPItemProviderErrorDomain";

CPItemProviderUnknownError                  = -1;
CPItemProviderItemUnavailableError          = -1000;
CPItemProviderUnexpectedValueClassError     = -1100;

var CPItemProviderChunkSize = 32768;

/*
    Returns a binary string for an array buffer: one character for each byte, of the same value.
    The buffer is converted in chunks, because a very long argument list exceeds the JavaScript
    engine's limit.

    CPData holds a binary string compactly, one byte for each character in current JavaScript
    engines. Its byte array would hold one JavaScript number for each byte, many times the size,
    because CFData stores bytes that way. File contents are given to CPData as a binary string.
*/
var CPItemProviderBinaryStringFromArrayBuffer = function(anArrayBuffer)
{
    var bytes = new Uint8Array(anArrayBuffer),
        chunks = [];

    for (var i = 0, count = bytes.length; i < count; i += CPItemProviderChunkSize)
        chunks.push(String.fromCharCode.apply(null, bytes.subarray(i, i + CPItemProviderChunkSize)));

    return chunks.join("");
};

/*
    TODO: Gaps against NSItemProvider that can be filled:

    - Writing: -registerObject:visibility:, -registerObjectOfClass:visibility:loadHandler:,
      -initWithObject: and -initWithItem:typeIdentifier:, with a writing protocol.
    - Loading a large file still holds it several times over at its peak: the browser's
      buffer, the binary string in CPData, and the decoded text.
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

    Each load returns a CPProgress. For a file, it counts the bytes read. Cancelling it stops
    the read, and the completion handler then receives a CPUserCancelledError.

    A completion handler receives the data, or nil and an error:

    <pre>
    var progress = [anItemProvider loadDataRepresentationForTypeIdentifier:@"image/*" completionHandler:function(data, error)
    {
        if (data)
            [self useData:data];
    }];
    </pre>

    An object of a class that adopts the item provider reading methods, such as CPString, can
    be loaded with -loadObjectOfClass:completionHandler:.
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
        return [CPItemProvider _readFile:aFile completionHandler:completionHandler];
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
    contents as data, or with nil and an error. Returns a progress object that counts the bytes
    read. Cancelling it aborts the read.
    @ignore
*/
+ (CPProgress)_readFile:(File)aFile completionHandler:(Function)aCompletionHandler
{
    var progress = [CPProgress discreteProgressWithTotalUnitCount:MAX(aFile.size || 0, 1)];

    [progress setKind:CPProgressKindFile];
    [progress setFileOperationKind:CPProgressFileOperationKindReceiving];

    if (typeof FileReader === "undefined")
    {
        aCompletionHandler(nil, [self _errorWithCode:CPItemProviderItemUnavailableError description:@"Files cannot be read in this environment."]);
        return progress;
    }

    var reader = new FileReader();

    reader.onprogress = function(anEvent)
    {
        if (anEvent.lengthComputable)
            [progress setCompletedUnitCount:MIN(anEvent.loaded, [progress totalUnitCount] - 1)];
    };

    reader.onload = function()
    {
        var data = [CPData dataWithRawString:CPItemProviderBinaryStringFromArrayBuffer(reader.result)];

        [progress setCompletedUnitCount:[progress totalUnitCount]];
        aCompletionHandler(data, nil);
    };

    reader.onerror = function()
    {
        var description = @"The file " + aFile.name + @" could not be read.";

        if (reader.error && reader.error.message)
            description += @" " + reader.error.message;

        aCompletionHandler(nil, [self _errorWithCode:CPItemProviderUnknownError description:description]);
    };

    reader.onabort = function()
    {
        aCompletionHandler(nil, [self _cancelledError]);
    };

    [progress setCancellationHandler:function()
    {
        if (reader.readyState === 1)
            reader.abort();
    }];

    reader.readAsArrayBuffer(aFile);

    return progress;
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
    @ignore
*/
+ (CPError)_cancelledError
{
    return [CPError errorWithDomain:CPCocoaErrorDomain
                               code:CPUserCancelledError
                           userInfo:@{ CPLocalizedDescriptionKey: @"The operation was cancelled." }];
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
    later. It may return a CPProgress for its work; the progress object returned by
    -loadDataRepresentationForTypeIdentifier:completionHandler: then follows it, and cancelling
    that progress object cancels it.

    @param aTypeIdentifier a MIME type, such as "text/csv"
    @param aLoadHandler a function that takes a completion handler, and may return a CPProgress
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
    pass, with the data and nil, or with nil and an error. When the returned progress object is
    cancelled first, the error is a CPUserCancelledError.

    @param aTypeIdentifier the type identifier to load
    @param aCompletionHandler a function that takes the data and an error
    @return a progress object for the load
*/
- (CPProgress)loadDataRepresentationForTypeIdentifier:(CPString)aTypeIdentifier completionHandler:(Function /*(CPData data, CPError error)*/)aCompletionHandler
{
    var registeredTypeIdentifier = [self _registeredTypeIdentifierConformingToTypeIdentifier:aTypeIdentifier],
        progress = [CPProgress discreteProgressWithTotalUnitCount:1],
        didComplete = NO,
        complete = function(data, error)
        {
            if (didComplete)
                return;

            didComplete = YES;

            if ([progress isCancelled])
            {
                data = nil;
                error = [CPItemProvider _cancelledError];
            }
            else if (!data && !error)
                error = [CPItemProvider _errorWithCode:CPItemProviderUnknownError description:@"The item could not be loaded."];

            if (data && ![progress isFinished])
                [progress setCompletedUnitCount:1];

            if (aCompletionHandler)
                aCompletionHandler(data || nil, data ? nil : error);

            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        };

    if (!registeredTypeIdentifier)
    {
        complete(nil, [CPItemProvider _errorWithCode:CPItemProviderItemUnavailableError description:@"The item has no representation of type " + aTypeIdentifier + @"."]);
        return progress;
    }

    var loadHandler = [_loadHandlers objectForKey:registeredTypeIdentifier],
        loadProgress = loadHandler(function(data, error)
        {
            if (data && ![data isKindOfClass:[CPData class]])
            {
                complete(nil, [CPItemProvider _errorWithCode:CPItemProviderUnexpectedValueClassError description:@"The item's load handler returned an object that is not data."]);
                return;
            }

            complete(data, error);
        });

    if (loadProgress && [loadProgress isKindOfClass:[CPProgress class]] && !didComplete)
        [progress addChild:loadProgress withPendingUnitCount:1];

    return progress;
}

// MARK: Loading Objects

/*!
    Returns YES if an object of \c aClass can be loaded from the item. \c aClass must implement
    +readableTypeIdentifiersForItemProvider, and the item must have a representation of one of
    those types.
*/
- (BOOL)canLoadObjectOfClass:(Class)aClass
{
    return [self _typeIdentifierReadableByClass:aClass] !== nil;
}

/*!
    Loads an object of \c aClass from the item. The first representation of a type that the
    class can read is loaded, and given to +objectWithItemProviderData:typeIdentifier:error:.
    The completion handler is called once, inside a run loop pass, with the object and nil, or
    with nil and an error.

    @param aClass a class that implements the item provider reading methods, such as CPString
    @param aCompletionHandler a function that takes the object and an error
    @return a progress object for the load
*/
- (CPProgress)loadObjectOfClass:(Class)aClass completionHandler:(Function /*(id object, CPError error)*/)aCompletionHandler
{
    var typeIdentifier = [self _typeIdentifierReadableByClass:aClass];

    if (!typeIdentifier)
        return [self loadDataRepresentationForTypeIdentifier:@"" completionHandler:function(data, error)
        {
            aCompletionHandler(nil, [CPItemProvider _errorWithCode:CPItemProviderItemUnavailableError description:@"The item has no representation that " + [aClass className] + @" can read."]);
        }];

    return [self loadDataRepresentationForTypeIdentifier:typeIdentifier completionHandler:function(data, error)
    {
        if (!data)
        {
            aCompletionHandler(nil, error);
            return;
        }

        var readError = nil,
            object = [aClass objectWithItemProviderData:data typeIdentifier:typeIdentifier error:@ref(readError)];

        if (object === nil || object === undefined)
            aCompletionHandler(nil, readError || [CPItemProvider _errorWithCode:CPItemProviderUnexpectedValueClassError description:@"The item could not be read as " + [aClass className] + @"."]);
        else
            aCompletionHandler(object, nil);
    }];
}

/*!
    Returns the first registered type identifier that \c aClass can read, or nil.
    @ignore
*/
- (CPString)_typeIdentifierReadableByClass:(Class)aClass
{
    if (![aClass respondsToSelector:@selector(readableTypeIdentifiersForItemProvider)])
        return nil;

    var readableTypeIdentifiers = [aClass readableTypeIdentifiersForItemProvider];

    for (var i = 0, count = [_registeredTypeIdentifiers count]; i < count; i++)
        for (var j = 0, readableCount = [readableTypeIdentifiers count]; j < readableCount; j++)
            if ([CPItemProvider _typeIdentifier:_registeredTypeIdentifiers[i] conformsToTypeIdentifier:readableTypeIdentifiers[j]])
                return _registeredTypeIdentifiers[i];

    return nil;
}

/*!
    Returns a description of the item provider: its suggested name and its type identifiers.
*/
- (CPString)description
{
    return [super description] + @" " + (_suggestedName || @"(unnamed)") + @" " + [_registeredTypeIdentifiers componentsJoinedByString:@", "];
}

@end

/*!
    CPString reads text from an item provider. The encoding is detected, as by
    +stringEncodingForData:encodingOptions:convertedString:usedLossyConversion:.

    Browsers report some text formats under other MIME types; for example, a CSV file may be
    reported as "application/vnd.ms-excel" on Windows. Such an item is not readable as a string
    by this method, but its data can be loaded and decoded directly.
*/
@implementation CPString (CPItemProvider)

/*!
    Returns the MIME types a string can be read from: every text type, JSON, XML and JavaScript.
*/
+ (CPArray)readableTypeIdentifiersForItemProvider
{
    return [@"text/*", @"application/json", @"application/xml", @"application/javascript"];
}

/*!
    Returns a string decoded from an item provider's data, or nil with an error when no
    encoding fits the data.
*/
+ (id)objectWithItemProviderData:(CPData)someData typeIdentifier:(CPString)aTypeIdentifier error:(CPErrorRef)anErrorRef
{
    var string = nil,
        encoding = [CPString stringEncodingForData:someData encodingOptions:nil convertedString:@ref(string) usedLossyConversion:nil];

    if (encoding)
        return string;

    if (anErrorRef)
        @deref(anErrorRef) = [CPError errorWithDomain:CPItemProviderErrorDomain
                                                  code:CPItemProviderUnexpectedValueClassError
                                              userInfo:@{ CPLocalizedDescriptionKey: @"The item's data is not text in a known encoding." }];

    return nil;
}

@end
