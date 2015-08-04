//
//  YRKSpinningProgressIndicator.h
//
//  Copyright 2009 Kelan Champagne. All rights reserved.
//

@import Cocoa;


@interface YRKSpinningProgressIndicator : NSView

@property (nonatomic, copy) NSColor *color;
@property (nonatomic, copy) NSColor *backgroundColor;
@property (nonatomic, assign) BOOL drawsBackground;

@property (nonatomic, assign, getter=isDisplayedWhenStopped) BOOL displayedWhenStopped;
@property (nonatomic, assign) BOOL usesThreadedAnimation;

@property (nonatomic, assign, getter=isIndeterminate) BOOL indeterminate;
@property (nonatomic, assign) CGFloat currentValue;
@property (nonatomic, assign) CGFloat maxValue;

- (void)stopAnimation:(id)sender;
- (void)startAnimation:(id)sender;

@end
