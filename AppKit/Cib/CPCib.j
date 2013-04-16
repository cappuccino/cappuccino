/*
 * CPCib.j
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
@import <Foundation/CPURLConnection.j>
@import <Foundation/CPURLRequest.j>

@import "_CPCibClassSwapper.j"
@import "_CPCibCustomObject.j"
@import "_CPCibCustomResource.j"
@import "_CPCibCustomView.j"
@import "_CPCibKeyedUnarchiver.j"
@import "_CPCibObjectData.j"
@import "_CPCibProxyObject.j"
@import "_CPCibWindowTemplate.j"

CPCibOwner              = @"CPCibOwner";
CPCibTopLevelObjects    = @"CPCibTopLevelObjects";
CPCibReplacementClasses = @"CPCibReplacementClasses";
CPCibExternalObjects    = @"CPCibExternalObjects";

var CPCibObjectDataKey  = @"CPCibObjectDataKey";

/*!
    @ingroup appkit
*/

@implementation CPCib : CPObject
{
    CPData      _data;
    CPBundle    _bundle;
    BOOL        _awakenCustomResources;

    id          _loadDelegate;
}

- (id)initWithContentsOfURL:(CPURL)aURL
{
    self = [super init];

    if (self)
    {
        _data = [CPURLConnection sendSynchronousRequest:[CPURLRequest requestWithURL:aURL] returningResponse:nil];

        if (!_data)
            return nil;

        _awakenCustomResources = YES;
    }

    return self;
}

- (id)initWithContentsOfURL:(CPURL)aURL loadDelegate:(id)aLoadDelegate
{
    self = [super init];

    if (self)
    {
        [CPURLConnection connectionWithRequest:[CPURLRequest requestWithURL:aURL] delegate:self];

        _awakenCustomResources = YES;

        _loadDelegate = aLoadDelegate;
    }

    return self;
}

- (id)initWithCibNamed:(CPString)aName bundle:(CPBundle)aBundle
{
    if (![aName hasSuffix:@".cib"])
        aName = [aName stringByAppendingString:@".cib"];

    // If aBundle is nil, use mainBundle, but ONLY for searching for the nib, not for resources later.
    self = [self initWithContentsOfURL:[aBundle || [CPBundle mainBundle] pathForResource:aName]];

    if (self)
        _bundle = aBundle;

    return self;
}

- (id)initWithCibNamed:(CPString)aName bundle:(CPBundle)aBundle loadDelegate:(id)aLoadDelegate
{
    if (![aName hasSuffix:@".cib"])
        aName = [aName stringByAppendingString:@".cib"];

    // If aBundle is nil, use mainBundle, but ONLY for searching for the nib, not for resources later.
    self = [self initWithContentsOfURL:[aBundle || [CPBundle mainBundle] pathForResource:aName] loadDelegate:aLoadDelegate];

    if (self)
        _bundle = aBundle;

    return self;
}

- (void)_setAwakenCustomResources:(BOOL)shouldAwakenCustomResources
{
    _awakenCustomResources = shouldAwakenCustomResources;
}

- (BOOL)_awakenCustomResources
{
    return _awakenCustomResources;
}

- (BOOL)instantiateCibWithExternalNameTable:(CPDictionary)anExternalNameTable
{
    var bundle = _bundle,
        owner = [anExternalNameTable objectForKey:CPCibOwner];

    if (!bundle && owner)
        bundle = [CPBundle bundleForClass:[owner class]];

    var unarchiver = [[_CPCibKeyedUnarchiver alloc] initForReadingWithData:_data bundle:bundle awakenCustomResources:_awakenCustomResources],
        replacementClasses = [anExternalNameTable objectForKey:CPCibReplacementClasses];

    if (replacementClasses)
    {
        var key = nil,
            keyEnumerator = [replacementClasses keyEnumerator];

        while ((key = [keyEnumerator nextObject]) !== nil)
            [unarchiver setClass:[replacementClasses objectForKey:key] forClassName:key];
    }

    [unarchiver setExternalObjectsForProxyIdentifiers:[anExternalNameTable objectForKey:CPCibExternalObjects]];

    var objectData = [unarchiver decodeObjectForKey:CPCibObjectDataKey];

    if (!objectData || ![objectData isKindOfClass:[_CPCibObjectData class]])
        return NO;

    var topLevelObjects = [anExternalNameTable objectForKey:CPCibTopLevelObjects];

    [objectData instantiateWithOwner:owner topLevelObjects:topLevelObjects];
    [objectData establishConnectionsWithOwner:owner topLevelObjects:topLevelObjects];
    [objectData awakeWithOwner:owner topLevelObjects:topLevelObjects];

    // Display Visible Windows.
    [objectData displayVisibleWindows];

    return YES;
}

- (BOOL)instantiateCibWithOwner:(id)anOwner topLevelObjects:(CPArray)topLevelObjects
{
    // anOwner can be nil, and we can't store nil in a dictionary. If we leave it out,
    // anyone who asks for CPCibOwner will get nil back.
    var nameTable = @{ CPCibTopLevelObjects: topLevelObjects };

    if (anOwner)
        [nameTable setObject:anOwner forKey:CPCibOwner];

    return [self instantiateCibWithExternalNameTable:nameTable];
}

@end

@implementation CPCib (CPURLConnectionDelegate)

- (void)connection:(CPURLConnection)aConnection didReceiveData:(CPString)data
{
    // FIXME: Why aren't we getting connection:didFailWithError:
    if (!data)
        return [self connection:aConnection didFailWithError:nil];

    _data = [CPData dataWithRawString:data];
}

- (void)connection:(CPURLConnection)aConnection didFailWithError:(CPError)anError
{
    if ([_loadDelegate respondsToSelector:@selector(cibDidFailToLoad:)])
        [_loadDelegate cibDidFailToLoad:self];

    _loadDelegate = nil;
}

- (void)connectionDidFinishLoading:(CPURLConnection)aConnection
{
    if ([_loadDelegate respondsToSelector:@selector(cibDidFinishLoading:)])
        [_loadDelegate cibDidFinishLoading:self];

    _loadDelegate = nil;
}

@end

var CPCibDataFileKey = @"CPCibDataFileKey",
    CPCibBundleIdentifierKey = @"CPCibBundleIdentifierKey";

@implementation CPCib (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    var base64 = [aCoder decodeObjectForKey:CPCibDataFileKey];
    _data = [CPData dataWithBase64:base64];

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:[_data base64] forKey:CPCibDataFileKey];
}

@end
