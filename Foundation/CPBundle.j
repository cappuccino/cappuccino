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

@import "CPObject.j"
@import "CPDictionary.j"

@import "CPURLRequest.j"

/*!
    @class CPBundle
    @ingroup foundation
    @brief Groups information about an application's code & resources.
*/

var CPBundlesForPaths = { };

@implementation CPBundle : CPObject
{
    CFBundle    _bundle;
    id          _delegate;
}

+ (CPBundle)bundleWithPath:(CPString)aPath
{
    return [[self alloc] initWithPath:aPath];
}

+ (CPBundle)bundleForClass:(Class)aClass
{
    return [self bundleWithPath:CFBundle.bundleForClass(aClass).path()];
}

+ (CPBundle)mainBundle
{
    return [CPBundle bundleWithPath:CFBundle.mainBundle().path()];
}

- (id)initWithPath:(CPString)aPath
{
    var existingBundle = CPBundlesForPaths[aPath];

    if (existingBundle)
        return existingBundle;

    self = [super init];

    if (self)
    {
        _bundle = new CFBundle(aPath);
        CPBundlesForPaths[aPath] = self;
    }

    return self;
}

- (Class)classNamed:(CPString)aString
{
    // ???
}

- (CPString)bundlePath
{
    return _bundle.path();
}

- (CPString)resourcePath
{
    var resourcePath = [self bundlePath];

    if (resourcePath.length)
        resourcePath += '/';

    return resourcePath + "Resources";
}

- (Class)principalClass
{
    var className = [self objectForInfoDictionaryKey:@"CPPrincipalClass"];

    //[self load];

    return className ? CPClassFromString(className) : Nil;
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
    return _bundle.valueForInfoDictionary(aKey);
}

//

- (void)loadWithDelegate:(id)aDelegate
{
    _delegate = aDelegate;

    _bundle.addEventListener("load", function()
    {
        [_delegate bundleDidFinishLoading:self];
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
        [staticResourceURLs addObject:[CPURL URLWithString:staticResources[index].path()]];

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
