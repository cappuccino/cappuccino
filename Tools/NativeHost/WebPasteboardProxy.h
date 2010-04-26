//
//  WebPasteboardProxy.h
//  NativeHost
//
//  Created by Ross Boucher on 12/12/09.
//  Copyright 2009 280 North. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WebPasteboardProxy : NSObject 
{
    NSPasteboard *pasteboard;
}

+ (id)pasteboardWithName:(NSString *)aName;

@end
