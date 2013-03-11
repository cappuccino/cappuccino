/*
 * CPWebDAVManager.j
 * Foundation
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

@import "CPArray.j"
@import "CPDictionary.j"
@import "CPObject.j"
@import "CPString.j"
@import "CPURL.j"
@import "CPURLConnection.j"
@import "CPURLRequest.j"

var setURLResourceValuesForKeysFromProperties = function(aURL, keys, properties)
{
    var resourceType = [properties objectForKey:@"resourcetype"];

    if (resourceType === CPWebDAVManagerCollectionResourceType)
    {
        [aURL setResourceValue:YES forKey:CPURLIsDirectoryKey];
        [aURL setResourceValue:NO forKey:CPURLIsRegularFileKey];
    }
    else if (resourceType === CPWebDAVManagerNonCollectionResourceType)
    {
        [aURL setResourceValue:NO forKey:CPURLIsDirectoryKey];
        [aURL setResourceValue:YES forKey:CPURLIsRegularFileKey];
    }

    var displayName = [properties objectForKey:@"displayname"];

    if (displayName !== nil)
    {
        [aURL setResourceValue:displayName forKey:CPURLNameKey];
        [aURL setResourceValue:displayName forKey:CPURLLocalizedNameKey];
    }
};

CPWebDAVManagerCollectionResourceType       = 1;
CPWebDAVManagerNonCollectionResourceType    = 0;

@implementation CPWebDAVManager : CPObject
{
    CPDictionary _blocksForConnections;
}

- (id)init
{
    self = [super init];

    if (self)
        _blocksForConnections = @{};

    return self;
}

- (CPArray)contentsOfDirectoryAtURL:(CPURL)aURL includingPropertiesForKeys:(CPArray)keys options:(CPDirectoryEnumerationOptions)aMask block:(Function)aBlock
{
    var properties = [],
        count = [keys count];

    while (count--)
        properties.push(WebDAVPropertiesForURLKeys[keys[count]]);

    var makeContents = function(aURL, response)
    {
        var contents = [],
            URLString = nil,
            URLStrings = [response keyEnumerator];

        while ((URLString = [URLStrings nextObject]) !== nil)
        {
            var URL = [CPURL URLWithString:URLString],
                properties = [response objectForKey:URLString];

            // FIXME: We need better way of comparing URLs.
            if (![[URL absoluteString] isEqual:[aURL absoluteString]])
            {
                contents.push(URL);

                setURLResourceValuesForKeysFromProperties(URL, keys, properties);
            }
        }

        return contents;
    };

    if (!aBlock)
        return makeContents(aURL, [self PROPFIND:aURL properties:properties depth:1 block:nil]);

    [self PROPFIND:aURL properties:properties depth:1 block:function(aURL, response)
    {
        aBlock(aURL, makeContents(aURL, response));
    }];
}

- (CPDictionary)PROPFIND:(CPURL)aURL properties:(CPDictionary)properties depth:(CPString)aDepth block:(Function)aBlock
{
    var request = [CPURLRequest requestWithURL:aURL];

    [request setHTTPMethod:@"PROPFIND"];
    [request setValue:aDepth forHTTPHeaderField:@"Depth"];

    var HTTPBody = ["<?xml version=\"1.0\"?><a:propfind xmlns:a=\"DAV:\">"],
        index = 0,
        count = properties.length;

    for (; index < count; ++index)
        HTTPBody.push("<a:prop><a:", properties[index], "/></a:prop>");

    HTTPBody.push("</a:propfind>");

    [request setHTTPBody:HTTPBody.join("")];

    if (!aBlock)
        return parsePROPFINDResponse([[CPURLConnection sendSynchronousRequest:request returningResponse:nil] rawString]);

    else
    {
        var connection = [CPURLConnection connectionWithRequest:request delegate:self];

        [_blocksForConnections setObject:aBlock forKey:[connection UID]];
    }
}

- (void)connection:(CPURLConnection)aURLConnection didReceiveData:(CPString)aString
{
    var block = [_blocksForConnections objectForKey:[aURLConnection UID]];

    // FIXME: get the request...
    block([aURLConnection._request URL], parsePROPFINDResponse(aString));
}

@end

var WebDAVPropertiesForURLKeys = { };

WebDAVPropertiesForURLKeys[CPURLNameKey]            = @"displayname";
WebDAVPropertiesForURLKeys[CPURLLocalizedNameKey]   = @"displayname";
WebDAVPropertiesForURLKeys[CPURLIsRegularFileKey]   = @"resourcetype";
WebDAVPropertiesForURLKeys[CPURLIsDirectoryKey]     = @"resourcetype";
//CPURLIsSymbolicLinkKey              = @"CPURLIsSymbolicLinkKey";
//CPURLIsVolumeKey                    = @"CPURLIsVolumeKey";
//CPURLIsPackageKey                   = @"CPURLIsPackageKey";
//CPURLIsSystemImmutableKey           = @"CPURLIsSystemImmutableKey";
//CPURLIsUserImmutableKey             = @"CPURLIsUserImmutableKey";
//CPURLIsHiddenKey                    = @"CPURLIsHiddenKey";
//CPURLHasHiddenExtensionKey          = @"CPURLHasHiddenExtensionKey";
//CPURLCreationDateKey                = @"CPURLCreationDateKey";
//CPURLContentAccessDateKey           = @"CPURLContentAccessDateKey";
//CPURLContentModificationDateKey     = @"CPURLContentModificationDateKey";
//CPURLAttributeModificationDateKey   = @"CPURLAttributeModificationDateKey";
//CPURLLinkCountKey                   = @"CPURLLinkCountKey";
//CPURLParentDirectoryURLKey          = @"CPURLParentDirectoryURLKey";
//CPURLVolumeURLKey                   = @"CPURLVolumeURLKey";
//CPURLTypeIdentifierKey              = @"CPURLTypeIdentifierKey";
//CPURLLocalizedTypeDescriptionKey    = @"CPURLLocalizedTypeDescriptionKey";
//CPURLLabelNumberKey                 = @"CPURLLabelNumberKey";
//CPURLLabelColorKey                  = @"CPURLLabelColorKey";
//CPURLLocalizedLabelKey              = @"CPURLLocalizedLabelKey";
//CPURLEffectiveIconKey               = @"CPURLEffectiveIconKey";
//CPURLCustomIconKey                  = @"CPURLCustomIconKey";

var XMLDocumentFromString = function(anXMLString)
{
    if (typeof window["ActiveXObject"] !== "undefined")
    {
        var XMLDocument = new ActiveXObject("Microsoft.XMLDOM");

        XMLDocument.async = false;
        XMLDocument.loadXML(anXMLString);

        return XMLDocument;
    }

    return new DOMParser().parseFromString(anXMLString,"text/xml");
};

var parsePROPFINDResponse = function(anXMLString)
{
    var XMLDocument = XMLDocumentFromString(anXMLString),
        responses = XMLDocument.getElementsByTagNameNS("*", "response"),
        responseIndex = 0,
        responseCount = responses.length,
        propertiesForURLs = @{};

    for (; responseIndex < responseCount; ++responseIndex)
    {
        var response = responses[responseIndex],
            elements = response.getElementsByTagNameNS("*", "prop").item(0).childNodes,
            index = 0,
            count = elements.length,
            properties = @{};

        for (; index < count; ++index)
        {
            var element = elements[index];

            if (element.nodeType === 8 || element.nodeType === 3)
                continue;

            var nodeName = element.nodeName,
                colonIndex = nodeName.lastIndexOf(':');

            if (colonIndex > -1)
                nodeName = nodeName.substr(colonIndex + 1);

            if (nodeName === @"resourcetype")
                [properties setObject:element.firstChild ? CPWebDAVManagerCollectionResourceType : CPWebDAVManagerNonCollectionResourceType forKey:nodeName];
            else
                [properties setObject:element.firstChild.nodeValue forKey:nodeName];
        }

        var href = response.getElementsByTagNameNS("*", "href").item(0);

        [propertiesForURLs setObject:properties forKey:href.firstChild.nodeValue];
    }

    return propertiesForURLs;
};

var mapURLsAndProperties = function(/*CPDictionary*/ properties, /*CPURL*/ ignoredURL)
{

};
