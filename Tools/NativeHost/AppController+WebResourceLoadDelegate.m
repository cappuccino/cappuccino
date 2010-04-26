//
//  AppController+WebResourceLoadDelegate.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 7/28/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import "AppController.h"
#import "SSCrypto.h"

NSString *authHeader = nil;

@implementation AppController (WebResourceLoadDelegate)

- (NSURLRequest *)webView:(WebView *)aSender resource:(id)anIdentifier willSendRequest:(NSURLRequest *)aRequest redirectResponse:(NSURLResponse *)aRedirectResponse fromDataSource:(WebDataSource *)aDataSource
{
    aRequest = [[aRequest mutableCopy] autorelease];

    if (!authHeader)
    {
        NSString *plaintext = [NSString stringWithFormat:@"%@:%@", SERVER_USER, SERVER_PASSWORD];
        NSData *data = [plaintext dataUsingEncoding:NSASCIIStringEncoding];
        authHeader = [[NSString alloc] initWithFormat:@"Basic %@", [data encodeBase64WithNewlines:NO]];
    }

    [(NSMutableURLRequest *)aRequest setValue:authHeader forHTTPHeaderField:@"Authorization"];

    return aRequest;
}

@end
