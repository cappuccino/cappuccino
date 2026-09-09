/*
 * AppController.j
 * test
 *
 * Created by aparajita on May 19, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/CPObject.j>

function formatter(aString, aLevel, aTitle)
{
    return aString;
}

@implementation AppController : CPObject
{
    @outlet CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet CPView      simpleColor;
    @outlet CPView      patternColor;
    @outlet CPView      threePartColor;
    @outlet CPView      ninePartColor;
    @outlet CPImageView imageView;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    CPLogRegister(CPLogConsole, null, formatter);

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];

    var color = [CPColor colorWithHexString:@"88B3FF"];
    CPLog([color description]);

    [simpleColor setBackgroundColor:color];

    color = CPColorWithImages("wheel_button.png", 32, 32, [CPBundle bundleForClass:[CPView class]]);
    CPLog([color description]);

    [patternColor setBackgroundColor:color];

    var bundle = [CPBundle bundleForClass:[CPView class]];

    color = CPColorWithImages([
        ["Aristo2.blend/Resources/button-bezel-left.png", 4, 25, bundle],
        ["Aristo2.blend/Resources/button-bezel-center.png", 1, 25, bundle],
        ["Aristo2.blend/Resources/button-bezel-right.png", 4, 25, bundle]
    ]);

    CPLog([color description]);

    [threePartColor setBackgroundColor:color];

    color = CPColorWithImages([
        ["Aristo2.blend/Resources/textfield-bezel-square-focused-0.png", 4, 4, bundle],
        ["Aristo2.blend/Resources/textfield-bezel-square-focused-1.png", 1, 4, bundle],
        ["Aristo2.blend/Resources/textfield-bezel-square-focused-2.png", 4, 4, bundle],
        ["Aristo2.blend/Resources/textfield-bezel-square-focused-3.png", 4, 1, bundle],
        ["Aristo2.blend/Resources/textfield-bezel-square-focused-4.png", 1, 1, bundle],
        ["Aristo2.blend/Resources/textfield-bezel-square-focused-5.png", 4, 1, bundle],
        ["Aristo2.blend/Resources/textfield-bezel-square-focused-6.png", 4, 4, bundle],
        ["Aristo2.blend/Resources/textfield-bezel-square-focused-7.png", 1, 4, bundle],
        ["Aristo2.blend/Resources/textfield-bezel-square-focused-8.png", 4, 4, bundle],
    ]);

    CPLog([color description]);

    [ninePartColor setBackgroundColor:color];

    var image = CPImageInBundle("add1-32.png", CGSizeMake(32, 32));

    CPLog([image description]);
    [imageView setImage:image];
}

@end
