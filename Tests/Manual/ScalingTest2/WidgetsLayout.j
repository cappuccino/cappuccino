/*
 * WidgetsLayout.j
 * CappScalingTest
 *
 * Created by David Richardson on March 15, 2021.
 * Copyright 2021, David Richardson All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation WidgetsLayout : CPBox
{
    CPWindow      activeWindow         @accessors;
    CPScrollView  scrollView           @accessors;
    id            pagePreviewBox       @accessors;
    CPNumber      requiredAspectRatio  @accessors;
}

- (void)awakeFromCib
{
}

- (void)scaleViewToFitContainer
{
    // Lazy initialization
    // Calculate required aspect ratio for selected page size and orientation
    if (![self requiredAspectRatio])
    {
        [self setRequiredAspectRatio:(792.0/612.0)];
    }
    
    if (![self scrollView])
    {
        [self setScrollView:[[self superview] superview]];
    }
    
    
    // Content view geometry
    var contentViewFrame = [[[self scrollView] contentView] frame];
    var availableHeight = contentViewFrame.size.height;
    var availableWidth = contentViewFrame.size.width;
    var contentViewAspectRatio = availableWidth / availableHeight;
    
    // Determine size to fit pagePreview in visible content view
    var newHeight = availableHeight - 20.0;
    var newWidth = availableWidth - 20.0;
    var scaleFactor = 1.0;
    if (contentViewAspectRatio <= requiredAspectRatio)
    {
        // Height dominates, use it to calculate required scaleSize
        scaleFactor = newWidth / 792.0;
        newHeight = newWidth / requiredAspectRatio;
    }
    else
    {
        // Width dominates, use it to calculate required scaleSize
        scaleFactor = newHeight / 612.0;
        newWidth = newHeight * requiredAspectRatio;
    }
    var newSize = CGSizeMake(newWidth, newHeight);
 
    // Set new geometry parameters
    [self setFrameSize:newSize];
    [self setBoundsSize:newSize];
    [self scaleUnitSquareToSize:CGSizeMake(scaleFactor, scaleFactor)];
    
    // Set the pagePreview origin to center it in the content view
    var newOriginX = (availableWidth - newWidth) / 2;
    var newOriginY = (availableHeight - newHeight) / 2;
    
    // View needs to re-display using new values
    [self setNeedsDisplay:YES];

    console.log("scaleViewToFitContainer");
}

@end
