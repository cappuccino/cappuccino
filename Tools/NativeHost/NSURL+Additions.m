//
//  NSURL+Additions.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 6/3/09.
//  Copyright 2009 280 North, Inc. All rights reserved.
//

#import "NSURL+Additions.h"
#import "AppController.h"

@implementation NSURL (Additions)

- (NSURL *)HTTPFileSystemURL
{
    if ([[self scheme] caseInsensitiveCompare:@"file"] == NSOrderedSame)
        return [[[NSURL alloc] initWithScheme:@"http"
										 host:[NSString stringWithFormat:@"127.0.0.1:%d", SERVER_PORT] 
										 path:[@"/filesystem/" stringByAppendingString:[self path]]] autorelease];

    return [[self copy] autorelease];
}

+ (NSURL *)fileSystemURLFromHTTPFileSystemString:(NSString *)aString
{
    NSURL *httpURL = [NSURL URLWithString:aString];
    NSString *path = [httpURL path];
    NSRange range = [path rangeOfString:@"/filesystem"];

    if (range.location == 0 && NSMaxRange(range) < [path length])
        path = [path substringFromIndex:[@"/filesystem" length]];

    return [[[NSURL alloc] initFileURLWithPath:path] autorelease];
}

@end
