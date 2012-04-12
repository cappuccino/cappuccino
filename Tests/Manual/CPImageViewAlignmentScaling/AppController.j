/*
 * AppController.j
 * CPImageViewScaling
 *
 * Created by aparajita on April 12, 2012.
 * Copyright 2012, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
}

- (void)awakeFromCib
{
}

@end


@implementation MyImageView : CPImageView

- (void)drawRect:(CGRect)aRect
{
    var path = [CPBezierPath bezierPathWithRect:[self bounds]];

    [[CPColor greenColor] set];
    [path setLineWidth:1];
    [path stroke];
}

@end
