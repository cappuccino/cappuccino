/*
 * AppController.j
 * PlatformWindows
 *
 * Created by Francisco Tolmasky on July 23, 2009.
 * Copyright 2009, 280 North, Inc. All rights reserved.
 */

@import <Foundation/CPObject.j>

@import <AppKit/CPButton.j>
@import <AppKit/CPSlider.j>
@import <AppKit/CPTextField.j>
@import <Foundation/CPKeyValueCoding.j>
@import <Foundation/CPKeyValueObserving.j>


@implementation AppController : CPObject
{
    CPPlatformWindow    platformWindow;
    CPWindow            theWindow; //this "outlet" is connected automatically by the Cib
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things. 
    
    // In this case, we want the window from Cib to become our full browser window
    //[theWindow setFullBridge:YES];

    platformWindow = [[CPPlatformWindow alloc] init];

//    [platformWindow orderFront:self];//console.log(CPStringFromRect([theWindow contentRectForFrameRect:[theWindow frame]]));
    [platformWindow setContentRect:[theWindow contentRectForFrameRect:[theWindow frame]]];

    //[platformWindow orderFront:self];

window.setTimeout(function(){
    [theWindow orderOut:self];
    [theWindow setPlatformWindow:platformWindow];
    [theWindow orderFront:self];
    [theWindow setFullBridge:YES];
    var button = [[theWindow contentView] subviews][2];

    [button setTarget:self];
    [button setAction:@selector(close)];

    window.setTimeout(function(){
    var view = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)];
    [view setBackgroundColor:[CPColor redColor]];
    
    [[theWindow contentView] addSubview:view];},1000);
    
    }, 1000);
    //window.setTimeout(function() { [platformWindow orderOut:self]; [platformWindow orderFront:self]; }, 2000);

}

- (void)close
{
    [[theWindow platformWindow] orderOut:self];
    window.setTimeout(function(){
    [[theWindow platformWindow] orderFront:self];}, 1000);
}

- (void)another:(id)aSender
{
    [platformWindow orderFront:self];
}

@end
