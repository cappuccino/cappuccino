/*
 * CPViewAnimation.j
 *
 * Created by Klaas Pieter Annema on September 3, 2009.
 * Copyright 2009, Sofa BV
 */


@import <AppKit/CPAnimation.j>

CPViewAnimationTargetKey = @"CPViewAnimationTarget";
CPViewAnimationStartFrameKey = @"CPViewAnimationStartFrame";
CPViewAnimationEndFrameKey = @"CPViewAnimationEndFrame";
CPViewAnimationEffectKey = @"CPViewAnimationEffect";

CPViewAnimationFadeInEffect = @"CPViewAnimationFadeIn";
CPViewAnimationFadeOutEffect = @"CPViewAnimationFadeOut";

@implementation CPViewAnimation : CPAnimation
{
	CPArray			_viewAnimations;
}

- (id)initWithViewAnimations:(CPArray)viewAnimations
{
	if(self = [super initWithDuration:0.5 animationCurve:CPAnimationLinear])
	{
		[self setViewAnimations:viewAnimations];
	}
	return self;
}

// =============
// = ANIMATION =
// =============
- (void)startAnimation
{
	var animationIndex = [_viewAnimations count];
		
	while (animationIndex--)
	{
		var dictionary = [_viewAnimations objectAtIndex:animationIndex];
		
		var view = [self _targetView:dictionary],
			startFrame = [self _startFrame:dictionary];
			
		[view setFrame:startFrame];
		
		var effect = [self _effect:dictionary];
		
		if (effect === CPViewAnimationFadeInEffect)
		{
			[view setAlphaValue:0.0];
			[view setHidden:NO];
		}
		else if (effect === CPViewAnimationFadeOutEffect)
			[view setAlphaValue:1.0];
	}
	
	[super startAnimation];
}

- (void)setCurrentProgress:(NSAnimationProgress)progress
{
	[super setCurrentProgress:progress];
	
	var animationIndex = [_viewAnimations count];
	while (animationIndex--)
	{
		var dictionary = [_viewAnimations objectAtIndex:animationIndex];
		
		// Update the view's frame
		var view = [self _targetView:dictionary]
			startFrame = [self _startFrame:dictionary]
			endFrame = [self _endFrame:dictionary]
			differenceFrame = CPRectMakeZero();
			
		differenceFrame.origin.x = endFrame.origin.x - startFrame.origin.x;
		differenceFrame.origin.y = endFrame.origin.y - startFrame.origin.y;
		differenceFrame.size.width = endFrame.size.width - startFrame.size.width;
		differenceFrame.size.height = endFrame.size.height - startFrame.size.height;
		
		var intermediateFrame = CPRectMakeZero();
		intermediateFrame.origin.x = startFrame.origin.x + differenceFrame.origin.x * progress;
		intermediateFrame.origin.y = startFrame.origin.y + differenceFrame.origin.y * progress;
		intermediateFrame.size.width = startFrame.size.width + differenceFrame.size.width * progress;
		intermediateFrame.size.height = startFrame.size.height + differenceFrame.size.height * progress;
		
		[view setFrame:intermediateFrame];
		
		// Update the view's alpha value
		var effect = [self _effect:dictionary];
		
		if (effect === CPViewAnimationFadeInEffect)
			[view setAlphaValue:1.0 * progress];
		else if (effect === CPViewAnimationFadeOutEffect)
			[view setAlphaValue:1.0 + ( 0.0 - 1.0 ) * progress];
			
		if (progress === 1.0)
			[view setHidden:CPRectIsNull(endFrame) || [view alphaValue] === 0.0];
	}
}

- (void)stopAnimation
{
	var animationIndex = [_viewAnimations count];
	while (animationIndex--)
	{
		var dictionary = [_viewAnimations objectAtIndex:animationIndex];
		
		var view = [self _targetView:dictionary],
			endFrame = [self _endFrame:dictionary];
			
		[view setFrame:endFrame];
		
		var effect = [self _effect:dictionary];
		
		if (effect === CPViewAnimationFadeInEffect)
			[view setAlphaValue:1.0];
		else if (effect === CPViewAnimationFadeOutEffect)
			[view setAlphaValue:0.0];
			
		[view setHidden:CPRectIsNull(endFrame) || [view alphaValue] === 0.0];
	}
	
	[super stopAnimation];
}

// ===============
// = CONVENIENCE =
// ===============
- (id)_targetView:(CPDictionary)dictionary
{
	var targetView = [dictionary valueForKey:CPViewAnimationTargetKey];
	
	if (!targetView)
		[CPException raise:CPInternalInconsistencyException reason:[CPString stringWithFormat:@"view animation: %@ does not have a target view", [dictionary description]]];
		
	return targetView;
}

- (CPRect)_startFrame:(CPDictionary)dictionary
{
	var startFrame = [dictionary valueForKey:CPViewAnimationStartFrameKey];
	
	if (!startFrame)
		return [[self _targetView:dictionary] frame];
	
	return startFrame;
}

- (CPRect)_endFrame:(CPDictionary)dictionary
{
	var endFrame = [dictionary valueForKey:CPViewAnimationEndFrameKey];
	
	if (!endFrame)
		return [[self _targetView:dictionary] frame];
		
	return endFrame;
}

- (CPString)_effect:(CPDictionary)dictionary
{
	return [dictionary valueForKey:CPViewAnimationEffectKey];
}

// =============
// = ACCESSORS =
// =============
- (CPArray)viewAnimations
{
	return _viewAnimations;
}

- (void)setViewAnimations:(CPArray)viewAnimations
{
	if (viewAnimations != _viewAnimations)
	{
		[self stopAnimation];
		_viewAnimations = [viewAnimations copy];
	}
}

@end
