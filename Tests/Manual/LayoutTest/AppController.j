/*
 * AppController.j
 * LayoutTest
 *
 * Created by Alexander Ljungberg on March 13, 2012.
 * Copyright 2012, SlevenBits Ltd. All rights reserved.
 */

@import <Foundation/CPObject.j>


@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib

    @outlet CPView verticalView0;
    @outlet CPView verticalView1;
    @outlet CPView verticalView2;
    @outlet CPView verticalView3;
    @outlet CPView verticalView4;
    @outlet CPView verticalView5;

    @outlet CPView horizontalView0;
    @outlet CPView horizontalView1;
    @outlet CPView horizontalView2;
    @outlet CPView horizontalView3;
    @outlet CPView horizontalView4;
    @outlet CPView horizontalView5;

    @outlet CPView ninePartView0;
    @outlet CPView ninePartView1;
    @outlet CPView ninePartView2;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    var threePartHorizontalColor = CPColorWithImages([
                [@"horizontal-border-0.png", 11, 35],
                [@"horizontal-border-1.png", 1, 35],
                [@"horizontal-border-2.png", 11, 35],
            ], CPColorPatternIsHorizontal),
        threePartHorizontalColor2 = CPColorWithImages([
                [@"round-border-3.png", 11, 1],
                [@"round-border-4.png", 1, 1],
                [@"round-border-5.png", 11, 1],
            ], CPColorPatternIsHorizontal),
        threePartVerticalColor = CPColorWithImages([
                [@"vertical-border-0.png", 35, 11],
                [@"vertical-border-1.png", 35, 1],
                [@"vertical-border-2.png", 35, 11],
            ], CPColorPatternIsVertical),
        threePartVerticalColor2 = CPColorWithImages([
                [@"round-border-1.png", 1, 11],
                [@"round-border-4.png", 1, 1],
                [@"round-border-7.png", 1, 11],
            ], CPColorPatternIsVertical),
        ninePartColor = CPColorWithImages([
                [@"round-border-0.png", 11, 11],
                [@"round-border-1.png", 1, 11],
                [@"round-border-2.png", 11, 11],
                [@"round-border-3.png", 11, 1],
                [@"round-border-4.png", 1, 1],
                [@"round-border-5.png", 11, 1],
                [@"round-border-6.png", 11, 11],
                [@"round-border-7.png", 1, 11],
                [@"round-border-8.png", 11, 11],
            ]);

    [horizontalView0 setBackgroundColor:threePartHorizontalColor];
    [horizontalView1 setBackgroundColor:threePartHorizontalColor];
    [horizontalView2 setBackgroundColor:threePartHorizontalColor];
    [horizontalView3 setBackgroundColor:threePartHorizontalColor2];
    [horizontalView4 setBackgroundColor:threePartHorizontalColor2];
    [horizontalView5 setBackgroundColor:threePartHorizontalColor2];

    [verticalView0 setBackgroundColor:threePartVerticalColor];
    [verticalView1 setBackgroundColor:threePartVerticalColor];
    [verticalView2 setBackgroundColor:threePartVerticalColor];
    [verticalView3 setBackgroundColor:threePartVerticalColor2];
    [verticalView4 setBackgroundColor:threePartVerticalColor2];
    [verticalView5 setBackgroundColor:threePartVerticalColor2];

    [ninePartView0 setBackgroundColor:ninePartColor];
    [ninePartView1 setBackgroundColor:ninePartColor];
    [ninePartView2 setBackgroundColor:ninePartColor];

    // Change the view sizes to verify the parts are laid out correctly.
    changeSizeAndRevert(horizontalView0, CGSizeMake(65, 65));
    changeSizeAndRevert(horizontalView2, CGSizeMake(11, 11));
    changeSizeAndRevert(horizontalView3, CGSizeMake(65, 65));
    changeSizeAndRevert(horizontalView5, CGSizeMake(11, 11));

    changeSizeAndRevert(verticalView0, CGSizeMake(65, 65));
    changeSizeAndRevert(verticalView2, CGSizeMake(11, 11));
    changeSizeAndRevert(verticalView3, CGSizeMake(65, 65));
    changeSizeAndRevert(verticalView5, CGSizeMake(11, 11));

    changeSizeAndRevert(ninePartView0, CGSizeMake(65, 65));
    changeSizeAndRevert(ninePartView2, CGSizeMake(11, 11));
}

@end

function changeSizeAndRevert(aView, tempSize)
{
    var originalSize = [aView frameSize];
    if (originalSize.width == tempSize.width && originalSize.height == tempSize.height)
        return;
    [aView setFrameSize:tempSize];
    var color = [aView backgroundColor];
    [aView setBackgroundColor:nil];
    [aView setBackgroundColor:color];
    // Make sure everything is laid out.
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [aView setFrameSize:originalSize];
}
