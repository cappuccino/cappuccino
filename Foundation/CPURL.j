/*
 * CPURL.j
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
@import "CPString.j"

CPURLNameKey                        = @"CPURLNameKey";
CPURLLocalizedNameKey               = @"CPURLLocalizedNameKey";
CPURLIsRegularFileKey               = @"CPURLIsRegularFileKey";
CPURLIsDirectoryKey                 = @"CPURLIsDirectoryKey";
CPURLIsSymbolicLinkKey              = @"CPURLIsSymbolicLinkKey";
CPURLIsVolumeKey                    = @"CPURLIsVolumeKey";
CPURLIsPackageKey                   = @"CPURLIsPackageKey";
CPURLIsSystemImmutableKey           = @"CPURLIsSystemImmutableKey";
CPURLIsUserImmutableKey             = @"CPURLIsUserImmutableKey";
CPURLIsHiddenKey                    = @"CPURLIsHiddenKey";
CPURLHasHiddenExtensionKey          = @"CPURLHasHiddenExtensionKey";
CPURLCreationDateKey                = @"CPURLCreationDateKey";
CPURLContentAccessDateKey           = @"CPURLContentAccessDateKey";
CPURLContentModificationDateKey     = @"CPURLContentModificationDateKey";
CPURLAttributeModificationDateKey   = @"CPURLAttributeModificationDateKey";
CPURLLinkCountKey                   = @"CPURLLinkCountKey";
CPURLParentDirectoryURLKey          = @"CPURLParentDirectoryURLKey";
CPURLVolumeURLKey                   = @"CPURLTypeIdentifierKey";
CPURLTypeIdentifierKey              = @"CPURLTypeIdentifierKey";
CPURLLocalizedTypeDescriptionKey    = @"CPURLLocalizedTypeDescriptionKey";
CPURLLabelNumberKey                 = @"CPURLLabelNumberKey";
CPURLLabelColorKey                  = @"CPURLLabelColorKey";
CPURLLocalizedLabelKey              = @"CPURLLocalizedLabelKey";
CPURLEffectiveIconKey               = @"CPURLEffectiveIconKey";
CPURLCustomIconKey                  = @"CPURLCustomIconKey";

@implementation CPURL : CPObject
{
}

+ (id)alloc
{
    var result = new CFURL();
    result.isa = [self class];
    return result;
}

- (id)init
{
    return nil;
}

- (id)initWithScheme:(CPString)aScheme host:(CPString)aHost path:(CPString)aPath
{
    var URLString = (aScheme ? aScheme + ":" : "") + (aHost ? aHost + "//" : "") + (aPath || "");

    return [self initWithString:URLString];
}

- (id)initWithString:(CPString)URLString
{
    return [self initWithString:URLString relativeToURL:nil];
}

+ (id)URLWithString:(CPString)URLString
{
    return [[self alloc] initWithString:URLString];
}

- (id)initWithString:(CPString)URLString relativeToURL:(CPURL)aBaseURL
{
    var result = new CFURL(URLString, aBaseURL);
    result.isa = [self class];
    return result;
}

+ (id)URLWithString:(CPString)URLString relativeToURL:(CPURL)aBaseURL
{
    return [[self alloc] initWithString:URLString relativeToURL:aBaseURL];
}

- (CPURL)absoluteURL
{
    return self.absoluteURL();
}

- (CPURL)baseURL
{
    return self.baseURL();
}

- (CPString)absoluteString
{
    return self.absoluteString();
}

// if absolute, returns same as absoluteString
- (CPString)relativeString
{
    return self.string();
}

- (CPString)path
{
    return [self absoluteURL].path();
}

- (CPArray)pathComponents
{
    var components = self.pathComponents();
    return [components copy];
}

// if absolute, returns the same as path
- (CPString)relativePath
{
    return self.path();
}

- (CPString)scheme
{
    return self.scheme();
}

- (CPString)user
{
    return [self absoluteURL].user();
}

- (CPString)password
{
    return [self absoluteURL].password();
}

- (CPString)host
{
    return [self absoluteURL].domain();
}

- (Number)port
{
    var portNumber = [self absoluteURL].portNumber();

    if (portNumber === -1)
        return nil;

    return portNumber;
}

- (CPString)parameterString
{
    return self.queryString();
}

- (CPString)fragment
{
    return self.fragment();
}

- (BOOL)isEqual:(id)anObject
{
    if (self === anObject)
        return YES;

    if (!anObject || ![anObject isKindOfClass:[CPURL class]])
        return NO;

    return [self isEqualToURL:anObject];
}

- (BOOL)isEqualToURL:(id)aURL
{
    if (self === aURL)
        return YES;

    // Is checking if baseURL isEqual correct? Does "identical" mean same object or equivalent values?
    return [[self absoluteString] isEqual:[aURL absoluteString]];
}

- (CPString)lastPathComponent
{
    return [self absoluteURL].lastPathComponent();
}

- (CPString)pathExtension
{
    return self.pathExtension();
}

- (CPURL)URLByDeletingLastPathComponent
{
    var result = self.createCopyDeletingLastPathComponent();
    result.isa = [self class];
    return result;
}

- (CPURL)standardizedURL
{
    return self.standardizedURL();
}

- (BOOL)isFileURL
{
    return [self scheme] === "file";
}

- (CPString)description
{
    return [self absoluteString];
}

- (id)resourceValueForKey:(CPString)aKey
{
    return self.resourcePropertyForKey(aKey);
}

- (id)setResourceValue:(id)anObject forKey:(CPString)aKey
{
    return self.setResourcePropertyForKey(aKey, anObject);
}

- (CPData)staticResourceData
{
    return self.staticResourceData();
}

@end

var CPURLURLStringKey   = @"CPURLURLStringKey",
    CPURLBaseURLKey     = @"CPURLBaseURLKey";

@implementation CPURL (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self initWithString:[aCoder decodeObjectForKey:CPURLURLStringKey]
                  relativeToURL:[aCoder decodeObjectForKey:CPURLBaseURLKey]];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:self._baseURL forKey:CPURLBaseURLKey];
    [aCoder encodeObject:self._string forKey:CPURLURLStringKey];
}

@end

CFURL.prototype.isa = [CPURL class];
