/*
 * AppController.j
 * CPMenuCALayerTest
 *
 * Created by Mathieu Monney on December 19, 2014.
 * Copyright 2014, Vidinoti SA, All rights reserved.
 */

@import <Foundation/CPObject.j>

@implementation MyLayer : CALayer 
{
}

- (void)drawInContext:(CGContext)aContext {
    CGContextSetFillColor(aContext, [CPColor blackColor]);
    CGContextFillRect(aContext, _bounds);
}

@end

@implementation AppController : CPObject
{
    MyLayer layer;
}

-(void)changeSize:(id)sender {
    var scale = [[sender selectedItem] title];
    scale = scale.substr(0,scale.length-1);
    
    // Change the affine transform of the layer to make sure it is updated due to 
    // https://github.com/cappuccino/cappuccino/pull/2018
    var af = CGAffineTransformMakeScale(scale/100.0,scale/100.0);
    [layer setAffineTransform:af];
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        popupButton = [[CPPopUpButton alloc] initWithFrame:CGRectMakeZero()];

    // Changing the button should change the size of the layer if #2018 is fixed.
    [popupButton addItemsWithTitles:[@"100%",@"50%",@"25%"]];
    [popupButton sizeToFit];
    [popupButton  setAction:@selector(changeSize:)];
    [popupButton  setTarget:self];

    [popupButton setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
    [popupButton setCenter:[contentView center]];

    [contentView addSubview:popupButton];

    [theWindow orderFront:self];

    var layerRoot = [[CALayer alloc ] init];
    [layerRoot setBounds:CGRectMake(0,0,[contentView bounds].size.width,[contentView bounds].size.height)];
    [layerRoot setPosition:CGPointMake(0,0)];
    [contentView setWantsLayer:YES];

    [contentView setLayer:layerRoot];

    layer = [[MyLayer alloc ] init];
    [layer setBounds:CGRectMake(0,0,100,100)];
    [layer setPosition:CGPointMake([contentView bounds].size.width/2,[contentView bounds].size.height/2-100)];
    [layer setNeedsDisplay];

    [layerRoot addSublayer:layer];

    // Uncomment the following line to turn on the standard menu bar.
    //[CPMenu setMenuBarVisible:YES];
}


@end
