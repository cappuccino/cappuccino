//
//  Console.h
//  NativeHost
//
//  Created by Francisco Tolmasky on 6/16/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Console : NSObject
{
    NSMutableAttributedString * contents;
}

+ (id)sharedConsole;

- (NSAttributedString *)contents;

@end
