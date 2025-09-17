/*
 * AppController.j
 * UserlandNSTest
 *
 * Created by aparajita on April 11, 2012.
 * Copyright 2012, The Cappuccino Foundation. All rights reserved.
 */

@import <Foundation/CPObject.j>
@import "BorderView.j"

@implementation AppController : CPObject
{
    CPWindow            theWindow; //this "outlet" is connected automatically by the Cib
    @outlet CPTextField field1 @accessors(readonly);
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
}

- (void)awakeFromCib
{
}

- (void)setInitialResponderByTag:(CPInteger)tag
{
    CPLog("setInitialFirstResponder:%d", tag);
    [theWindow setInitialFirstResponder:[[theWindow contentView] viewWithTag:tag]];
}

- (void)setValue:(id)value forUndefinedKey:(CPString)key
{
    CPLog("setValue:" + value + " forKey:" + key);
}
@end
