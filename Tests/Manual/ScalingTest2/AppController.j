/*
 * AppController.j
 * CappScalingTest
 *
 * Created by David Richardson on March 15, 2021.
 * Copyright 2021, David Richardson All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "PagePreviewController.j"
@import "WidgetsLayout.j"

@implementation AppController : CPObject
{
    @outlet  CPWindow      theWindow;
    @outlet  CPScrollView  scrollView      @accessors;
    @outlet  id            pagePreviewBox  @accessors;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    [theWindow setFullPlatformWindow:YES];
    // Load the page preview from cib file
    var pagePreviewController = [[PagePreviewController alloc] initWithCibName:@"WidgetsLayout" bundle:[CPBundle mainBundle]];
    var pagePreview = [pagePreviewController view];
    [[self scrollView] setDocumentView:pagePreview];
}

#pragma mark - Window delegate methods
- (CGSize)windowWillResize:(CPWindow)theWindow toSize:(CPSize)frameSize
{
    if (![self pagePreviewBox])
    {
        [self setPagePreviewBox:[[self scrollView] documentView]];
    }
    [[self pagePreviewBox] scaleViewToFitContainer];
    return frameSize;
}
@end
