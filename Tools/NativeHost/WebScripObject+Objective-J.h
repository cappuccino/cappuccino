//
//  WebScripObject+Objective-J.h
//  NativeHost
//
//  Created by Francisco Tolmasky on 9/1/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface WebScriptObject (ObjectiveJ)

- (id)evaluateObjectiveJ:(NSString *)aString;
- (NSString *)evaluateObjectiveJReturningString:(NSString *)aString;

- (id)bridgeSelector:(SEL)aSelector;
- (id)bridgeSelector:(SEL)aSelector withObject:(id)anObject;
- (id)bridgeSelector:(SEL)aSelector withObjects:(NSArray *)array;

@end
