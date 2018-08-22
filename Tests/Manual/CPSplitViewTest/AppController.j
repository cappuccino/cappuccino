/*
 * AppController.j
 * CPSplitViewTest
 *
 * Created by Alexander Ljungberg on January 27, 2012.
 * Copyright 2012, WireLoad All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject
{
    CPWindow            theWindow; //this "outlet" is connected automatically by the Cib

    @outlet CPSplitView splitViewA;
    @outlet CPSplitView splitViewB;
    @outlet CPSplitView splitViewC;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    [splitViewA setDelegate:self];
    [splitViewB setDelegate:self];
    [splitViewC setDelegate:self];
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

- (@action)deleteAutosave:(id)sender
{
    [splitViewA deleteAutosave];
    [splitViewB deleteAutosave];
    [splitViewC deleteAutosave];

    [sender setTitle:@"Autosave deleted. Reload to see original positions."];
    [sender setEnabled:NO];
    [sender sizeToFit];
}

@end

@implementation CPSplitView (Reset)

- (void)deleteAutosave
{
    var userDefaults = [CPUserDefaults standardUserDefaults],
        autosaveName = [self _framesKeyForAutosaveName:[self autosaveName]],
        autosavePrecollapseName = [self _precollapseKeyForAutosaveName:[self autosaveName]];

    [userDefaults setObject:nil forKey:autosaveName];
    [userDefaults setObject:nil forKey:autosavePrecollapseName];

    // Prevent a new autosave from being made.
    [self setAutosaveName:nil];
}

@end

@implementation AppController (Delegate)

- (void)splitViewDidResizeSubviews:(CPNotification)aNotification
{
    console.error(@"splitViewDidResizeSubviews")
}

- (void)splitViewWillResizeSubviews:(CPNotification)aNotification
{
    console.error(@"splitViewWillResizeSubviews")
}

- (BOOL)splitView:(CPSplitView)splitView shouldAdjustSizeOfSubview:(CPView)subview
{
    var subviews = [splitView subviews];
    return (subview !== [subviews objectAtIndex:1]);
}

- (BOOL)splitView:(CPSplitView)splitView canCollapseSubview:(CPView)subview
{
    return subview == [[splitView subviews] objectAtIndex:0];
}

- (BOOL)splitView:(CPSplitView)splitView shouldCollapseSubview:(CPView)subview forDoubleClickOnDividerAtIndex:(CPInteger)dividerIndex
{
    return dividerIndex == 0;
}

@end
