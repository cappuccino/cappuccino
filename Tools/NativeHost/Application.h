//
//  Application.h
//  NativeHost
//
//  Created by Francisco Tolmasky on 10/8/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Application : NSApplication
{
}

- (void)_reallyTerminate:(id)sender;

@end
