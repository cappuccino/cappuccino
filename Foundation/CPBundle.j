/*
 * CPBundle.j
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

@import "CPDictionary.j"
@import "CPNotification.j"
@import "CPNotificationCenter.j"
@import "CPObject.j"

CPBundleDidLoadNotification = @"CPBundleDidLoadNotification";

/*!
    @class CPBundle
    @ingroup foundation
    @brief Groups information about an application's code & resources.
*/

var CPBundlesForURLStrings = { };

@implementation CPBundle : CPObject
{
    CFBundle    _bundle;
    id          _delegate;
}

+ (CPBundle)bundleWithURL:(CPURL)aURL
{
    return [[self alloc] initWithURL:aURL];
}

+ (CPBundle)bundleWithPath:(CPString)aPath
{
    return [self bundleWithURL:aPath];
}

+ (CPBundle)bundleWithIdentifier:(CPString)anIdentifier
{
    var bundle = CFBundle.bundleWithIdentifier(anIdentifier);

    if (bundle)
    {
        var url = bundle.bundleURL(),
            cpBundle = CPBundlesForURLStrings[url.absoluteString()];

        if (!cpBundle)
            cpBundle = [self bundleWithURL:url];

        return cpBundle;
    }

    return nil;
}

+ (CPBundle)bundleForClass:(Class)aClass
{
    return [self bundleWithURL:CFBundle.bundleForClass(aClass).bundleURL()];
}

+ (CPBundle)mainBundle
{
    return [CPBundle bundleWithPath:CFBundle.mainBundle().bundleURL()];
}

- (id)initWithURL:(CPURL)aURL
{
    aURL = new CFURL(aURL);

    var URLString = aURL.absoluteString(),
        existingBundle = CPBundlesForURLStrings[URLString];

    if (existingBundle)
        return existingBundle;

    self = [super init];

    if (self)
    {
        _bundle = new CFBundle(aURL);
        CPBundlesForURLStrings[URLString] = self;
    }

    return self;
}

- (id)initWithPath:(CPString)aPath
{
    return [self initWithURL:aPath];
}

- (Class)classNamed:(CPString)aString
{
    // ???
}

- (CPURL)bundleURL
{
    return _bundle.bundleURL();
}

- (CPString)bundlePath
{
    return [[self bundleURL] path];
}

- (CPString)resourcePath
{
    return [[self resourceURL] path];
}

- (CPURL)resourceURL
{
    return _bundle.resourcesDirectoryURL();
}

- (Class)principalClass
{
    var className = [self objectForInfoDictionaryKey:@"CPPrincipalClass"];

    //[self load];

    return className ? CPClassFromString(className) : nil;
}

- (CPString)bundleIdentifier
{
    return _bundle.identifier();
}

- (BOOL)isLoaded
{
    return _bundle.isLoaded();
}

- (CPString)pathForResource:(CPString)aFilename
{
    return _bundle.pathForResource(aFilename);
}

- (CPDictionary)infoDictionary
{
    return _bundle.infoDictionary();
}

- (id)objectForInfoDictionaryKey:(CPString)aKey
{
    return _bundle.valueForInfoDictionaryKey(aKey);
}

- (void)loadWithDelegate:(id)aDelegate
{
    _delegate = aDelegate;

    _bundle.addEventListener("load", function()
    {
        [_delegate bundleDidFinishLoading:self];
        // userInfo should contain a list of all classes loaded from this bundle. When writing this there
        // seems to be no efficient way to get it though.
        [[CPNotificationCenter defaultCenter] postNotificationName:CPBundleDidLoadNotification object:self userInfo:nil];
    });

    _bundle.addEventListener("error", function()
    {
        CPLog.error("Could not find bundle: " + self);
    });

    _bundle.load(YES);
}

- (CPArray)staticResourceURLs
{
    var staticResourceURLs = [],
        staticResources = _bundle.staticResources(),
        index = 0,
        count = [staticResources count];

    for (; index < count; ++index)
        [staticResourceURLs addObject:staticResources[index].URL()];

    return staticResourceURLs;
}

- (CPArray)environments
{
    return _bundle.environments();
}

- (CPString)mostEligibleEnvironment
{
    return _bundle.mostEligibleEnvironment();
}

- (CPString)description
{
    return [super description] + "(" + [self bundlePath] + ")";
}

@end
