/*
 *  CPItemProviderTest.j
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

@import <Foundation/CPData.j>
@import <Foundation/CPItemProvider.j>

@global globalThis

@implementation CPItemProviderTest : OJTestCase
{
}

- (void)tearDown
{
    delete globalThis.FileReader;
}

/*
    Installs a FileReader stand-in, because the command-line runtime has none. It reports the
    given bytes, or an error when bytes is nil.
*/
- (void)installFileReaderWithBytes:(CPArray)bytes
{
    globalThis.FileReader = function() {};
    globalThis.FileReader.prototype.readAsArrayBuffer = function(aFile)
    {
        if (bytes)
        {
            this.result = new Uint8Array(bytes).buffer;
            this.onload();
        }
        else
        {
            this.error = { message: "denied" };
            this.onerror();
        }
    };
}

- (CPItemProvider)providerWithType:(CPString)aType data:(CPData)someData
{
    var provider = [[CPItemProvider alloc] init];

    [provider registerDataRepresentationForTypeIdentifier:aType loadHandler:function(completionHandler)
    {
        completionHandler(someData, nil);
    }];

    return provider;
}

- (void)testRegisteredTypeIdentifiersKeepOrder
{
    var provider = [self providerWithType:@"text/csv" data:nil];

    [provider registerDataRepresentationForTypeIdentifier:@"text/plain" loadHandler:function(completionHandler) {}];
    [provider registerDataRepresentationForTypeIdentifier:@"text/csv" loadHandler:function(completionHandler) {}];

    [self assert:[@"text/csv", @"text/plain"] equals:[provider registeredTypeIdentifiers]];
}

- (void)testConformance
{
    var provider = [self providerWithType:@"image/PNG" data:nil];

    [self assertTrue:[provider hasItemConformingToTypeIdentifier:@"image/png"]];
    [self assertTrue:[provider hasItemConformingToTypeIdentifier:@"image/*"]];
    [self assertTrue:[provider hasItemConformingToTypeIdentifier:@"*/*"]];
    [self assertFalse:[provider hasItemConformingToTypeIdentifier:@"text/*"]];
    [self assertFalse:[provider hasItemConformingToTypeIdentifier:@"image/gif"]];
    [self assertFalse:[provider hasItemConformingToTypeIdentifier:@"image"]];
}

- (void)testLoadData
{
    var data = [CPData dataWithRawString:@"a,b"],
        provider = [self providerWithType:@"text/csv" data:data],
        result = nil,
        resultError = nil;

    [provider loadDataRepresentationForTypeIdentifier:@"text/*" completionHandler:function(someData, anError)
    {
        result = someData;
        resultError = anError;
    }];

    [self assert:data same:result];
    [self assertNull:resultError];
}

- (void)testLoadUnavailableType
{
    var provider = [self providerWithType:@"text/csv" data:nil],
        resultError = nil;

    [provider loadDataRepresentationForTypeIdentifier:@"image/*" completionHandler:function(someData, anError)
    {
        resultError = anError;
    }];

    [self assert:CPItemProviderErrorDomain equals:[resultError domain]];
    [self assert:CPItemProviderItemUnavailableError equals:[resultError code]];
}

- (void)testLoadHandlerReturningOtherObject
{
    var provider = [self providerWithType:@"text/csv" data:@"not data"],
        resultError = nil;

    [provider loadDataRepresentationForTypeIdentifier:@"text/csv" completionHandler:function(someData, anError)
    {
        resultError = anError;
    }];

    [self assert:CPItemProviderUnexpectedValueClassError equals:[resultError code]];
}

- (void)testCompletionHandlerCalledOnce
{
    var provider = [[CPItemProvider alloc] init],
        calls = 0;

    [provider registerDataRepresentationForTypeIdentifier:@"text/plain" loadHandler:function(completionHandler)
    {
        completionHandler([CPData dataWithRawString:@"a"], nil);
        completionHandler([CPData dataWithRawString:@"b"], nil);
    }];

    [provider loadDataRepresentationForTypeIdentifier:@"text/plain" completionHandler:function(someData, anError)
    {
        calls++;
    }];

    [self assert:1 equals:calls];
}

- (void)testFileProvider
{
    [self installFileReaderWithBytes:[104, 105]];

    var provider = [CPItemProvider _itemProviderWithFile:{ name: "notes.csv", type: "text/csv" }],
        result = nil;

    [self assert:@"notes.csv" equals:[provider suggestedName]];
    [self assert:[@"text/csv"] equals:[provider registeredTypeIdentifiers]];

    [provider loadDataRepresentationForTypeIdentifier:@"text/csv" completionHandler:function(someData, anError)
    {
        result = someData;
    }];

    [self assert:[104, 105] equals:[result bytes]];
}

- (void)testFileProviderDefaults
{
    var provider = [CPItemProvider _itemProviderWithFile:{ name: "data", type: "", webkitRelativePath: "folder/data" }];

    [self assert:@"folder/data" equals:[provider suggestedName]];
    [self assert:[@"application/octet-stream"] equals:[provider registeredTypeIdentifiers]];
}

- (void)testFileProviderReadError
{
    [self installFileReaderWithBytes:nil];

    var provider = [CPItemProvider _itemProviderWithFile:{ name: "notes.csv", type: "text/csv" }],
        resultError = nil;

    [provider loadDataRepresentationForTypeIdentifier:@"text/csv" completionHandler:function(someData, anError)
    {
        resultError = anError;
    }];

    [self assert:CPItemProviderUnknownError equals:[resultError code]];
}

- (void)testFileProviderWithoutFileReader
{
    var provider = [CPItemProvider _itemProviderWithFile:{ name: "notes.csv", type: "text/csv" }],
        resultError = nil;

    [provider loadDataRepresentationForTypeIdentifier:@"text/csv" completionHandler:function(someData, anError)
    {
        resultError = anError;
    }];

    [self assert:CPItemProviderItemUnavailableError equals:[resultError code]];
}

- (void)testItemProvidersWithFilesKeepOrder
{
    var providers = [CPItemProvider _itemProvidersWithFiles:[{ name: "b.png", type: "image/png" }, { name: "a.png", type: "image/png" }]];

    [self assert:2 equals:[providers count]];
    [self assert:@"b.png" equals:[providers[0] suggestedName]];
    [self assert:@"a.png" equals:[providers[1] suggestedName]];
}

@end
