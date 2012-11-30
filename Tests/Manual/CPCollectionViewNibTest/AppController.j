/*
 * AppController.j
 * CPCollectionViewNibTest
 *
 * Created by You on November 28, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
//@import "CPCollectionView.j"

@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    
    CPArray content @accessors;
}

- (id)init
{
    self = [super init];
    
    content = ["A", "B", "C", "D", "E", "F"];
    
    return self;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    //[collectionView bind:"content" toObject:ac withKeyPath:@"arrangedObjects" options:nil];
    

    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    //[theWindow setFullPlatformWindow:YES];
}

@end

@implementation RandomColorView : CPView
{
    CPColor color;
}

- (void)drawRect:(CGRect)aRect
{
    if (!color)
        color = [CPColor randomColor];
    
    var context = [[CPGraphicsContext currentContext] graphicsPort];
    CGContextSetFillColor(context, color);
    CGContextFillRect(context, aRect);
}

@end