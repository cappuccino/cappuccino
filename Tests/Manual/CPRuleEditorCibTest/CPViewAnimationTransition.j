/*
 *     Created by cacaodev@gmail.com.
 *     Copyright (c) 2008 Pear, Inc. All rights reserved.
 */

@import <AppKit/CPView.j>
@import <AppKit/CPAnimation.j>

CPViewAnimationStartFrameKey    = "CPViewAnimationStartFrameKey";
CPViewAnimationEndFrameKey      = "CPViewAnimationEndFrameKey";
CPViewAnimationTargetKey        = "CPViewAnimationTargetKey";
CPViewAnimationEffectKey        = "CPViewAnimationEffectKey";

CPViewAnimationFadeInEffect     = "CPViewAnimationFadeInEffect";
CPViewAnimationFadeOutEffect    = "CPViewAnimationFadeOutEffect";

@implementation CPViewAnimationTransition : CPAnimation
{
	CPArray    _viewAnimations;
	Function   endListener;
	BOOL       _isAnimating;
}

// INSTANCE METHODS
- (id)initWithViewAnimations:(CPArray)animations
{
    self = [super initWithDuration:0.5 animationCurve:CPAnimationEaseInOut];
    if (self)
    {
        [self setViewAnimations:animations];
        _isAnimating = NO;
    }

    return self;
}

- (id)initWithDuration:(CPInteger)duration animationCurve:(id)curve
{
    self = [super initWithDuration:duration animationCurve:curve];
    if (self)
    {
        _isAnimating = NO;
    }

    return self;
}

- (CPArray)viewAnimations
{
    return _viewAnimations;
}

- (void)setViewAnimations:(CPArray)animations
{
    _viewAnimations = animations;

    var count = [_viewAnimations count];
    for (var i = 0; i < count; i++)
    {
    	var animation = [_viewAnimations objectAtIndex:i],
            target = [animation objectForKey:CPViewAnimationTargetKey];

        [self _updateAnimationCurve:[self animationCurve] forView:target];
        [self _updateAnimationDuration:[self duration] forView:target];
    }

	endListener = function(event){[self _animationDidEnd:_viewAnimations]};
}

- (void)_updateTransitionPropertiesForView:(CPView)target
{
    target._DOMElement.style.webkitTransitionProperty = "left, top, width, height, opacity";
}

// SUBCLASSING
- (BOOL)isAnimating
{
    return _isAnimating;
}

- (void)setAnimationCurve:(CPAnimationCurve)anAnimationCurve
{
    var i,
        count = [_viewAnimations count];

    for (i = 0; i < count; i++)
    {
        var animation   = [_viewAnimations objectAtIndex:i],
            target      = [animation objectForKey:CPViewAnimationTargetKey];

        [self _updateAnimationCurve:anAnimationCurve forView:target];
    }

    [super setAnimationCurve:anAnimationCurve];
}

- (void)setAnimationDuration:(int)duration
{
    var i,
        count = [_viewAnimations count];

    for (i = 0; i < count; i++)
    {
        var animation   = [_viewAnimations objectAtIndex:i],
            target      = [animation objectForKey:CPViewAnimationTargetKey];

        [self _updateAnimationDuration:duration forView:target];
    }

    [super setAnimationDuration:duration];
}

- (void)startAnimation
{
    if (![self _animationShouldStart])
        return;

    var count = [_viewAnimations count];
    if (count > 0)
    {
        _isAnimating = YES;
        document.addEventListener("webkitTransitionEnd", endListener, false);
    }

    for (var i = 0; i < count; i++)
    {
        var animation = [_viewAnimations objectAtIndex:i],
            target = [animation objectForKey:CPViewAnimationTargetKey],
            startFrame = [animation objectForKey:CPViewAnimationStartFrameKey],
            endFrame = [animation objectForKey:CPViewAnimationEndFrameKey],
            effect;

        [target setFrame:startFrame];

        [self _updateTransitionPropertiesForView:target];

        if (effect = [animation objectForKey:CPViewAnimationEffectKey])
        {
        	var opacity;
        	switch (effect)
        	{
        		case CPViewAnimationFadeInEffect:  opacity = 1;
        		                                   break;
        		case CPViewAnimationFadeOutEffect: opacity = 0;
        		                                   break;
        		default : opacity = 1;
        	}

        	[target setAlphaValue:opacity];
        }

        [target setFrame:endFrame];
    }
}

// PRIVATE METHODS
- (void)_updateAnimationCurve:(CPAnimationCurve)anAnimationCurve forView:(CPView)view
{
    var webkitTimingFunction;

    switch (anAnimationCurve)
    {
        case CPAnimationEaseInOut:  webkitTimingFunction = "ease-in-out";
                                    break;

        case CPAnimationEaseIn:     webkitTimingFunction = "ease-in";
                                    break;

        case CPAnimationEaseOut:    webkitTimingFunction = "ease-out";
                                    break;

        case CPAnimationLinear:     webkitTimingFunction = "linear";
                                    break;

        default:                    [CPException raise:CPInvalidArgumentException
                                                reason:"Invalid value provided for animation curve"];
                                    break;
    }

    view._DOMElement.style.webkitTransitionTimingFunction = webkitTimingFunction;
}

- (void)_updateAnimationDuration:(int)duration forView:(CPView)view
{
    view._DOMElement.style.webkitTransitionDuration = duration + "s";
}

- (BOOL)_animationShouldStart
{
    if (_delegate && [_delegate respondsToSelector:@selector(animationShouldStart:)])
        return [_delegate animationShouldStart:self];

    return YES;
}

- (void)_animationDidEnd:(CPArray)viewAnimations
{
    var count = [viewAnimations count];

    if (this.counter == null)
        this.counter = count;

    this.counter--;

    if (this.counter == 0)
    {
        document.removeEventListener("webkitTransitionEnd", endListener, false);
        this.counter = null;
        _isAnimating = NO;

        while(count--)
        {
            var target = [viewAnimations[count] objectForKey:CPViewAnimationTargetKey];
            target._DOMElement.style.removeProperty("-webkit-transition");
        }

        if (_delegate && [_delegate respondsToSelector:@selector(animationDidEnd:)])
            [_delegate animationDidEnd:self];
    }
}

- (void)_stopAnimation:(int)value
{
}

- (void)setCurrentProgress:(float)progress
{
}

@end

