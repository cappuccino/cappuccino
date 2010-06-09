//
//  WebScripObject+Objective-J.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 9/1/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import "WebScripObject+Objective-J.h"


@implementation WebScriptObject (ObjectiveJ)

- (id)evaluateObjectiveJ:(NSString *)aString
{
    return [self evaluateWebScript:[NSString stringWithFormat:@"(ObjectiveJ.eval(decodeURIComponent(\"%@\")))", [aString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], nil]];
}

- (NSString *)evaluateObjectiveJReturningString:(NSString *)aString
{
    return [self evaluateWebScript:[NSString stringWithFormat:@"String(ObjectiveJ.eval(decodeURIComponent(\"%@\")))", [aString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], nil]];
}

- (id)bridgeSelector:(SEL)aSelector
{
    return [self bridgeSelector:aSelector withObjects:nil];
}

- (id)bridgeSelector:(SEL)aSelector withObject:(id)anObject
{
    return [self bridgeSelector:aSelector withObjects:[NSArray arrayWithObject:anObject]];
}

- (id)bridgeSelector:(SEL)aSelector withObjects:(NSArray *)objects
{
    [self evaluateWebScript:@"objj_object.prototype.__objj_msgSend = function() { return objj_msgSend.apply(null, arguments); }"];

    NSArray * arguments = [NSArray arrayWithObjects:self, NSStringFromSelector(aSelector), nil];

    if (objects)
        arguments = [arguments arrayByAddingObjectsFromArray:objects];

    return [self callWebScriptMethod:@"__objj_msgSend" withArguments:arguments];
}

@end
