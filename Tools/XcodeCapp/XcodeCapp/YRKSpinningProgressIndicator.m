//
//  YRKSpinningProgressIndicator.m
//
//  Copyright 2009 Kelan Champagne. All rights reserved.
//

#import "YRKSpinningProgressIndicator.h"

// Some constants to control the animation
const CGFloat kAlphaWhenStopped = 0.15;
const CGFloat kFadeMultiplier = 0.85l;
const NSUInteger kNumberOfFins = 12;
const NSTimeInterval kFadeOutTime = 0.7;  // seconds

@interface YRKSpinningProgressIndicator ()
@end


@implementation YRKSpinningProgressIndicator
{
    
    BOOL            _isAnimating;
    BOOL            _isFadingOut;
    int             _currentPosition;
    NSMutableArray* _finColors;
    NSTimer*        _animationTimer;
    NSThread*       _animationThread;
    NSDate*         _fadeOutStartTime;
}

#pragma mark - Init

- (void)awakeFromNib
{
    [self _init];
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        [self _init];
    }
    
    return self;
}

- (void)_init
{
    _currentPosition = 0;
    _finColors = [[NSMutableArray alloc] initWithCapacity:kNumberOfFins];
    
    _isAnimating = NO;
    _isFadingOut = NO;
    
    // user setter, to generate all fin colors
    self.color = [NSColor blackColor];
    _backgroundColor = [NSColor clearColor];
    _drawsBackground = NO;
    
    _displayedWhenStopped = YES;
    _usesThreadedAnimation = YES;
    
    _indeterminate = YES;
    _currentValue = 0.0;
    _maxValue = 100.0;
}

#pragma mark - NSView overrides

- (void)viewDidMoveToWindow
{
    [super viewDidMoveToWindow];
    
    // No window? View hierarchy may be going away. Dispose timer to clear circular retain of timer to self to timer.
    if (![self window])
        [self actuallyStopAnimation];
    else if (_isAnimating)
        [self actuallyStartAnimation];
}

- (void)drawRect:(NSRect)rect
{
    const CGSize size = self.bounds.size;
    const CGFloat length = MIN(size.height, size.width);

    // fill the background, if set
    if (_drawsBackground)
    {
        [_backgroundColor set];
        [NSBezierPath fillRect:[self bounds]];
    }
    
    CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];

    // Move the CTM so 0,0 is at the center of our bounds
    CGContextTranslateCTM(ctx, size.width/2, size.height/2);
    
    if (_indeterminate)
    {
        NSBezierPath *path = [[NSBezierPath alloc] init];
        // magic constants determined empirically, to make it look like the NS version.
        const CGFloat lineWidth = 0.0859375 * length; // should be 2.75 for 32x32
        const CGFloat lineStart = 0.234375 * length; // should be 7.5 for 32x32
        const CGFloat lineEnd = 0.421875 * length; // should be 13.5 for 32x32
        [path setLineWidth:lineWidth];
        [path setLineCapStyle:NSRoundLineCapStyle];
        [path moveToPoint:NSMakePoint(0, lineStart)];
        [path lineToPoint:NSMakePoint(0, lineEnd)];

        // Draw all the fins by rotating the CTM, then just redraw the same path again.
        for (NSUInteger i = 0; i < kNumberOfFins; i++)
        {
            NSColor *c = _isAnimating ? _finColors[i] : [_color colorWithAlphaComponent:kAlphaWhenStopped];
            [c set];
            [path stroke];

            CGContextRotateCTM(ctx, 2 * M_PI/kNumberOfFins);
        }
    }
    else
    {
        CGFloat lineWidth = 1 + (0.01 * length);
        CGFloat circleRadius = (length - lineWidth) / 2.1;
        NSPoint circleCenter = NSMakePoint(0, 0);
        [_color set];
        NSBezierPath *path = [[NSBezierPath alloc] init];
        [path setLineWidth:lineWidth];
        [path appendBezierPathWithOvalInRect:NSMakeRect(-circleRadius,
                                                        -circleRadius,
                                                        circleRadius * 2,
                                                        circleRadius * 2)];
        [path stroke];
        path = [[NSBezierPath alloc] init];
        [path appendBezierPathWithArcWithCenter:circleCenter radius:circleRadius startAngle:90 endAngle:90-(360*(_currentValue/_maxValue)) clockwise:YES];
        [path lineToPoint:circleCenter] ;
        [path fill];
    }
}


#pragma mark - NSProgressIndicator API

- (void)startAnimation:(id)sender
{
    if (!_indeterminate || (_isAnimating && !_isFadingOut))
        return;

    [self actuallyStartAnimation];
}

- (void)stopAnimation:(id)sender
{
    // animate to stopped state
    _isFadingOut = YES;
    _fadeOutStartTime = [NSDate date];
}

/// Only the spinning style is implemented
- (void)setStyle:(NSProgressIndicatorStyle)style
{
    if (NSProgressIndicatorSpinningStyle != style)
        NSAssert(NO, @"Non-spinning styles not available.");
}


#pragma mark - Custom Accessors

- (void)setColor:(NSColor *)value
{
    if (_color != value)
    {
        _color = [value copy];
        
        // Set all the fin colors, with their current alpha components.
        for (NSUInteger i = 0; i < kNumberOfFins; i++)
        {
            CGFloat alpha = [self alphaValueForPosition:i];
            _finColors[i] = [_color colorWithAlphaComponent:alpha];
        }
        
        [self setNeedsDisplay:YES];
    }
}

- (void)setBackgroundColor:(NSColor *)value
{
    if (_backgroundColor != value)
    {
        _backgroundColor = [value copy];
        [self setNeedsDisplay:YES];
    }
}

- (void)setDrawsBackground:(BOOL)value
{
    if (_drawsBackground != value)
        _drawsBackground = value;
    
    [self setNeedsDisplay:YES];
}

- (void)setIsIndeterminate:(BOOL)isIndeterminate
{
    _indeterminate = isIndeterminate;
    
    if (!_indeterminate && _isAnimating)
        [self stopAnimation:self];
    
    [self setNeedsDisplay:YES];
}

- (void)setCurrentValue:(CGFloat)currentValue
{
    // Automatically put it into determinate mode if it's not already.
    if (_indeterminate)
        self.indeterminate = NO;

    _currentValue = currentValue;
    [self setNeedsDisplay:YES];
}

- (void)setMaxValue:(CGFloat)maxValue
{
    _maxValue = maxValue;
    [self setNeedsDisplay:YES];
}

- (void)setUsesThreadedAnimation:(BOOL)useThreaded
{
    if (_usesThreadedAnimation != useThreaded)
    {
        _usesThreadedAnimation = useThreaded;
        
        if (_isAnimating) {
            // restart the timer to use the new mode
            [self stopAnimation:self];
            [self startAnimation:self];
        }
    }
}

- (void)setDisplayedWhenStopped:(BOOL)displayedWhenStopped
{
    _displayedWhenStopped = displayedWhenStopped;
    
    // Show/hide ourself if necessary
    if (!_isAnimating)
        self.hidden = !_displayedWhenStopped;
}


#pragma mark - Private

- (void)updateFrameFromTimer:(NSTimer *)timer
{
    // update the colors
    const CGFloat minAlpha = _displayedWhenStopped ? kAlphaWhenStopped : 0.0;
    
    for (NSUInteger i = 0; i < kNumberOfFins; i++)
    {
        CGFloat newAlpha = MAX([self alphaValueForPosition:i], minAlpha);
        _finColors[i] = [_color colorWithAlphaComponent:newAlpha];
    }
    
    if (_isFadingOut)
    {
        // check if the fadeout is done
        if ([_fadeOutStartTime timeIntervalSinceNow] < -kFadeOutTime)
            [self actuallyStopAnimation];
    }

    // draw now instead of waiting for setNeedsDisplay (that's the whole reason
    // we're animating from background thread)
    if (_usesThreadedAnimation)
        [self display];
    else
        [self setNeedsDisplay:YES];

    // update the currentPosition for next time, unless fading out
    if (!_isFadingOut)
        _currentPosition = (_currentPosition + 1) % kNumberOfFins;
}

/// Returns the alpha value for the given position.
/// Each fin should fade exponentially over _numberOfFins frames of animation.
/// @param position is [0,kNumberOfFins)
- (CGFloat)alphaValueForPosition:(NSUInteger)position
{
    CGFloat normalValue = pow(kFadeMultiplier, (position + _currentPosition) % kNumberOfFins);
    
    if (_isFadingOut)
    {
        NSTimeInterval timeSinceStop = -[_fadeOutStartTime timeIntervalSinceNow];
        normalValue *= kFadeOutTime - timeSinceStop;
    }
    
    return normalValue;
}

- (void)actuallyStartAnimation
{
    // Just to be safe kill any existing timer.
    [self actuallyStopAnimation];
    
    _isAnimating = YES;
    _isFadingOut = NO;
    
    // always start from the top
    _currentPosition = 0;
    
    if (!_displayedWhenStopped)
        [self setHidden:NO];
    
    if ([self window])
    {
        // Why animate if not visible? viewDidMoveToWindow will re-call this method when needed.
        if (_usesThreadedAnimation)
        {
            _animationThread = [[NSThread alloc] initWithTarget:self selector:@selector(animateInBackgroundThread) object:nil];
            [_animationThread start];
        }
        else
        {
            _animationTimer = [NSTimer timerWithTimeInterval:(NSTimeInterval)0.05
                                                      target:self
                                                    selector:@selector(updateFrameFromTimer:)
                                                    userInfo:nil
                                                     repeats:YES];
            
            [[NSRunLoop currentRunLoop] addTimer:_animationTimer forMode:NSRunLoopCommonModes];
            [[NSRunLoop currentRunLoop] addTimer:_animationTimer forMode:NSDefaultRunLoopMode];
            [[NSRunLoop currentRunLoop] addTimer:_animationTimer forMode:NSEventTrackingRunLoopMode];
        }
    }
}

- (void)actuallyStopAnimation
{
    _isAnimating = NO;
    _isFadingOut = NO;
    
    if (!_displayedWhenStopped)
        [self setHidden:YES];
    
    if (_animationThread)
    {
        // we were using threaded animation
        [_animationThread cancel];
        
        if (![_animationThread isFinished]) {
            [[NSRunLoop currentRunLoop] runMode:NSModalPanelRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        }
        
        _animationThread = nil;
    }
    else if (_animationTimer)
    {
        // we were using timer-based animation
        [_animationTimer invalidate];
        _animationTimer = nil;
    }
    
    [self setNeedsDisplay:YES];
}

- (void)animateInBackgroundThread
{
    @autoreleasepool
    {
        // Set up the animation speed to subtly change with size > 32.
        // int animationDelay = 38000 + (2000 * ([self bounds].size.height / 32));
        
        // Set the rev per minute here
        int omega = 100; // RPM
        int animationDelay = 60 * 1000000 / omega / kNumberOfFins;
        int poolFlushCounter = 0;
        
        do {
            [self updateFrameFromTimer:nil];
            usleep(animationDelay);
            poolFlushCounter++;
            if (poolFlushCounter > 256) {
                poolFlushCounter = 0;
            }
        } while (![[NSThread currentThread] isCancelled]);
    }
}

@end
