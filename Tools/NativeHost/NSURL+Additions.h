//
//  NSURL+Additions.h
//  NativeHost
//
//  Created by Francisco Tolmasky on 6/3/09.
//  Copyright 2009 280 North, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSURL (Additions)

- (NSURL *)HTTPFileSystemURL;
+ (NSURL *)fileSystemURLFromHTTPFileSystemString:(NSString *)aString;

@end
