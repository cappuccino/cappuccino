/*
 * AppController.j
 * test
 *
 * Created by aparajita on May 19, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    CPView      simpleColor;
    CPView      patternColor;
    CPView      threePartColor;
    CPView      ninePartColor;
    CPImage     imageView;
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
    [theWindow setFullPlatformWindow:YES];

    var color = [CPColor colorWithHexString:@"88B3FF"];
    console.log([color description]);

    [simpleColor setBackgroundColor:color];

    color = CPColorWithImages("wheel_button.png", 32, 32, [CPBundle bundleForClass:[CPView class]]);
    console.log([color description]);

    [patternColor setBackgroundColor:color];

    var bundle = [CPBundle bundleForClass:[CPView class]];

    color = CPColorWithImages([
        ["Aristo.blend/Resources/button-bezel-left.png", 4, 24, bundle],
        ["Aristo.blend/Resources/button-bezel-center.png", 1, 24, bundle],
        ["Aristo.blend/Resources/button-bezel-right.png", 4, 24, bundle]
    ]);
    console.log([color description]);

    [threePartColor setBackgroundColor:color];

    color = CPColorWithImages([
        ["Aristo.blend/Resources/textfield-bezel-square-focused-0.png", 7, 7, bundle],
        ["Aristo.blend/Resources/textfield-bezel-square-focused-1.png", 1, 7, bundle],
        ["Aristo.blend/Resources/textfield-bezel-square-focused-2.png", 7, 7, bundle],
        ["Aristo.blend/Resources/textfield-bezel-square-focused-3.png", 7, 1, bundle],
        ["Aristo.blend/Resources/textfield-bezel-square-focused-4.png", 1, 1, bundle],
        ["Aristo.blend/Resources/textfield-bezel-square-focused-5.png", 7, 1, bundle],
        ["Aristo.blend/Resources/textfield-bezel-square-focused-6.png", 7, 7, bundle],
        ["Aristo.blend/Resources/textfield-bezel-square-focused-7.png", 1, 7, bundle],
        ["Aristo.blend/Resources/textfield-bezel-square-focused-8.png", 7, 7, bundle],
    ]);
    console.log([color description]);

    [ninePartColor setBackgroundColor:color];

    var image = CPImageInBundle("add1-32.png", CGSizeMake(32, 32));

    console.log([image description]);
    [imageView setImage:image];
}

@end
