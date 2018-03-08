/*
 * AppController.j
 * CPTextViewDelegateAndNotifications
 *
 * Created by Martin Carlberg on December 22, 2017.
 * Copyright 2017, Oops AB All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import "NotificationStatistics.j"

@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow;

    CPArray notificationStatistics @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
    [self setNotificationStatistics: @[
                                    [NotificationStatistics notificationStatisticsWithName:CPStringFromSelector(@selector(textView:willChangeSelectionFromCharacterRange:toCharacterRange:))],
                                    [NotificationStatistics notificationStatisticsWithName:CPStringFromSelector(@selector(textView:shouldChangeTextInRange:replacementString:))],
                                    [NotificationStatistics notificationStatisticsWithName:CPStringFromSelector(@selector(textView:doCommandBySelector:))],
                                    [NotificationStatistics notificationStatisticsWithName:CPStringFromSelector(@selector(textViewDidChangeSelection:))],
                                    [NotificationStatistics notificationStatisticsWithName:CPStringFromSelector(@selector(textView:shouldChangeTypingAttributes:toAttributes:))],
                                    [NotificationStatistics notificationStatisticsWithName:CPStringFromSelector(@selector(textViewDidChangeTypingAttributes:))],
                                    [NotificationStatistics notificationStatisticsWithName:CPStringFromSelector(@selector(textShouldBeginEditing:))],
                                    [NotificationStatistics notificationStatisticsWithName:CPStringFromSelector(@selector(textShouldEndEditing:))],
                                    [NotificationStatistics notificationStatisticsWithName:CPStringFromSelector(@selector(textDidBeginEditing:))],
                                    [NotificationStatistics notificationStatisticsWithName:CPStringFromSelector(@selector(textDidEndEditing:))],
                                    ]];

    self.globalOrder = 0;
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
    self.globalOrder = 0;
}

- (IBAction)resetStatistics:(id)sender {
    self.globalOrder = 0;
    for (var i = 0, array = [self notificationStatistics]; i < array.length; i++) {
        var ns = array[i];
        [ns setOrder:0];
        [ns setCount:0];
    }
}

- (NotificationStatistics)notificationStatisticsWithName:(CPString)aName
{
    for (var i = 0, array = [self notificationStatistics]; i < array.length; i++) {
        var ns = array[i];
        if ([ns.name isEqualToString:aName]) {
            return ns;
        }
    }

    return nil;
}

- (void)registerNotificationWithSelector:(SEL)selector
{
    var ns = [self notificationStatisticsWithName:CPStringFromSelector(selector)];
    if (ns) {
        [ns setCount:[ns count] + 1];
        [ns setOrder:self.globalOrder += 1];
    }
}

- (CPRange)textView:(CPTextView)textView willChangeSelectionFromCharacterRange:(CPRange)oldSelectedCharRange toCharacterRange:(CPRange)newSelectedCharRange {
    [self registerNotificationWithSelector:_cmd];
    return newSelectedCharRange;
}

- (BOOL)textView:(CPTextView)textView shouldChangeTextInRange:(CPRange)affectedCharRange replacementString:(CPString)replacementString {
    [self registerNotificationWithSelector:_cmd];
    return YES;
}

- (BOOL)textView:(CPTextView)textView doCommandBySelector:(SEL)commandSelector {
    [self registerNotificationWithSelector:_cmd];
    return NO;
}
- (CPDictionary)textView:(CPTextView)textView shouldChangeTypingAttributes:(CPDictionary)oldTypingAttributes toAttributes:(CPDictionary)newTypingAttributes {
    [self registerNotificationWithSelector:_cmd];
    return newTypingAttributes;
}

- (void)textViewDidChangeSelection:(CPNotification)notification {
    [self registerNotificationWithSelector:_cmd];
}

- (void)textViewDidChangeTypingAttributes:(CPNotification)notification {
    [self registerNotificationWithSelector:_cmd];
}

- (BOOL)textShouldBeginEditing:(CPText)textObject {
    [self registerNotificationWithSelector:_cmd];
    return YES;
}

- (BOOL)textShouldEndEditing:(CPText)textObject {
    [self registerNotificationWithSelector:_cmd];
    return YES;
}

- (void)textDidBeginEditing:(CPNotification)notification {
    [self registerNotificationWithSelector:_cmd];
}

- (void)textDidEndEditing:(CPNotification)notification {
    [self registerNotificationWithSelector:_cmd];
}

@end
