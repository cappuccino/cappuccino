
@import <Foundation/CPObject.j>

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
    return new CFURL();
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
    return new CFURL(URLString, aBaseURL);
}

+ (id)URLWithString:(CPString)URLString relativeToURL:(CPURL)aBaseURL
{
    return [[self alloc] initWithString:URLString relativeToURL:aBaseURL];
}

- (CPURL)absoluteURL
{
    return self.absoluteURL();
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
    return [self absoluteString].path();
}

// if absolute, returns the same as path
- (CPString)relativePath
{
    return URI_RE.test(_relative) ? (parse(_relative).path || nil) : nil;
}

- (CPString)scheme
{
    return self.scheme();
}

- (CPString)user
{
    var str = [self absoluteString];
    return URI_RE.test(str) ? (parse(str).user || nil) : nil;
}

- (CPString)password
{
    var str = [self absoluteString];
    return URI_RE.test(str) ? (parse(str).password || nil) : nil;
}

- (CPString)host
{
    var str = [self absoluteString];
    return URI_RE.test(str) ? (parse(str).domain || nil) : nil;
}

- (Number)port
{
    var str = [self absoluteString];
    if (URI_RE.test(str)) {
        var port = parse(str).port;
        if (port)
            return parseInt(port, 10);
    }
    return nil;
}

- (CPString)parameterString
{
    var str = [self absoluteString];
    return URI_RE.test(str) ? (parse(str).query || nil) : nil;
}

- (CPString)fragment
{
    var str = [self absoluteString];
    return URI_RE.test(str) ? (parse(str).anchor || nil) : nil;
}

- (BOOL)isEqual:(id)anObject
{
    // Is checking if baseURL isEqual correct? Does "identical" mean same object or equivalent values?
    return [self relativeString] === [anObject relativeString] &&
        ([self baseURL] === [anObject baseURL] || [[self baseURL] isEqual:[anObject baseURL]]);
}

- (CPString)lastPathComponent
{
    return [self absoluteURL].lastPathComponent();
}

- (CPString)pathExtension
{
    return self.pathExtension();
}

- (CPURL)standardizedURL
{
    return [CPURL URLWithString:format(parse(_relative)) relativeToURL:_base];
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

- (CPString)staticResourceData
{
    return self.staticResourceData();
}

@end

var CPURLURLStringKey   = @"CPURLURLStringKey",
    CPURLBaseURLKey     = @"CPURLBaseURLKey";

@implementation CPURL (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self initWithURLString:[aCoder decodeObjectForKey:CPURLURLStringKey]
                           baseURL:[aCoder decodeObjectForKey:CPURLBaseURLKey]];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_baseURL forKey:CPURLBaseURLKey];
    [aCoder encodeObject:_string forKey:CPURLURLStringKey];
}

@end

CFURL.prototype.isa = [CPURL class];
