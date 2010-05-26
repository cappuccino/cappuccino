//
//  Application.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 10/8/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import "Application.h"
#import "AppController.h"
#import "WebScripObject+Objective-J.h"
#import "WebWindow.h"

@implementation Application

- (void)sendEvent:(NSEvent *)anEvent
{
    NSWindow * window = [anEvent window];

    if (!window || [window isKindOfClass:[WebWindow class]])
    {
        NSResponder * firstResponder = window ? [window firstResponder] : [(AppController *)[self delegate] keyView];

        switch ([anEvent type])
        {
            case NSKeyDown: return [firstResponder keyDown:anEvent];
            case NSKeyUp:   return [firstResponder keyUp:anEvent];
        }
    }

    [super sendEvent:anEvent];
}

- (void)terminate:(id)sender
{
    if ([[[self delegate] windowScriptObject] evaluateObjectiveJ:@"(CPApp)"] == [WebUndefined undefined])
        [self _reallyTerminate:sender];
    else
        [[(AppController *)[self delegate] windowScriptObject] evaluateObjectiveJ:@"[CPApp terminate:nil]"];
}

- (void)_reallyTerminate:(id)sender
{
    [super terminate:sender];
}

@end
