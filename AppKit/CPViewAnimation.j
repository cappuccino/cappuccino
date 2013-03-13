/*
 * CPViewAnimation.j
 * AppKit
 *
 * Created by Klaas Pieter Annema on September 3, 2009.
 * Copyright 2009, Sofa BV
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "CPAnimation.j"

@class CPWindow

CPViewAnimationTargetKey = @"CPViewAnimationTargetKey";
CPViewAnimationStartFrameKey = @"CPViewAnimationStartFrameKey";
CPViewAnimationEndFrameKey = @"CPViewAnimationEndFrameKey";
CPViewAnimationEffectKey = @"CPViewAnimationEffectKey";

CPViewAnimationFadeInEffect = @"CPViewAnimationFadeInEffect";
CPViewAnimationFadeOutEffect = @"CPViewAnimationFadeOutEffect";

/*!
    @class CPViewAnimation

    CPViewAnimation is a subclass of CPAnimation that makes it easy to do
    basic animations on views.
*/

@implementation CPViewAnimation : CPAnimation
{
    CPArray _viewAnimations;
}

/*!
    Designated initializer.

    This method takes an array of CPDictionaries. Each dictionary should
    contain values for the following keys:

    <pre>
    CPViewAnimationTargetKey - (Required) The view to animate.
    CPViewAnimationStartFrameKey - (Optional) The start frame of the target.
    CPViewAnimationEndFrameKey - (Optional) The end frame of the target.
    CPViewAnimationEffectKey - (Optional) a fade effect to use for the animation.
    </pre>

    For example:
    <pre>
    var animation = @{
            CPViewAnimationTargetKey: myViewToAnimate,
            CPViewAnimationStartFrameKey: aStartFrame,
            CPViewAnimationEndFrameKey: anEndFrame,
            CPViewAnimationEffectKey: CPViewAnimationFadeInEffect,
        };
    </pre>

    If you pass nil instead of an array of dictionaries you should later call setViewAnimations:.

    @param viewAnimations - An array of CPDictionaries for each animation.
*/
- (id)initWithViewAnimations:(CPArray)viewAnimations
{
    if (self = [super initWithDuration:0.5 animationCurve:CPAnimationLinear])
    {
        [self setViewAnimations:viewAnimations];
    }

    return self;
}

- (void)startAnimation
{
    var animationIndex = [_viewAnimations count];
    while (animationIndex--)
    {
        var dictionary = [_viewAnimations objectAtIndex:animationIndex],
            view = [self _targetView:dictionary],
            startFrame = [self _startFrame:dictionary];

        [view setFrame:startFrame];

        var effect = [self _effect:dictionary];
        if (effect === CPViewAnimationFadeInEffect)
        {
            [view setAlphaValue:0.0];
            [self _targetView:view setHidden:NO];
        }
        else if (effect === CPViewAnimationFadeOutEffect)
            [view setAlphaValue:1.0];
    }

    [super startAnimation];
}

- (void)setCurrentProgress:(CPAnimationProgress)progress
{
    [super setCurrentProgress:progress];

    var animationIndex = [_viewAnimations count];
    while (animationIndex--)
    {
        var dictionary = [_viewAnimations objectAtIndex:animationIndex],
            view = [self _targetView:dictionary],
            startFrame = [self _startFrame:dictionary],
            endFrame = [self _endFrame:dictionary],
            differenceFrame = CGRectMakeZero(),
            value = [super currentValue];

        differenceFrame.origin.x = endFrame.origin.x - startFrame.origin.x;
        differenceFrame.origin.y = endFrame.origin.y - startFrame.origin.y;
        differenceFrame.size.width = endFrame.size.width - startFrame.size.width;
        differenceFrame.size.height = endFrame.size.height - startFrame.size.height;

        var intermediateFrame = CGRectMakeZero();
        intermediateFrame.origin.x = startFrame.origin.x + differenceFrame.origin.x * value;
        intermediateFrame.origin.y = startFrame.origin.y + differenceFrame.origin.y * value;
        intermediateFrame.size.width = startFrame.size.width + differenceFrame.size.width * value;
        intermediateFrame.size.height = startFrame.size.height + differenceFrame.size.height * value;

        [view setFrame:intermediateFrame];

        // Update the view's alpha value
        var effect = [self _effect:dictionary];
        if (effect === CPViewAnimationFadeInEffect)
            [view setAlphaValue:1.0 * value];
        else if (effect === CPViewAnimationFadeOutEffect)
            [view setAlphaValue:1.0 + ( 0.0 - 1.0 ) * value];

        if (progress === 1.0)
            [self _targetView:view setHidden:CGRectIsEmpty(endFrame) || [view alphaValue] === 0.0];
    }
}

- (void)stopAnimation
{
    var animationIndex = [_viewAnimations count];
    while (animationIndex--)
    {
        var dictionary = [_viewAnimations objectAtIndex:animationIndex],
            view = [self _targetView:dictionary],
            endFrame = [self _endFrame:dictionary];

        [view setFrame:endFrame];

        var effect = [self _effect:dictionary];
        if (effect === CPViewAnimationFadeInEffect)
            [view setAlphaValue:1.0];
        else if (effect === CPViewAnimationFadeOutEffect)
            [view setAlphaValue:0.0];

        [self _targetView:view setHidden:CGRectIsEmpty(endFrame) || [view alphaValue] === 0.0];
    }

    [super stopAnimation];
}

- (void)_targetView:(id)theView setHidden:(BOOL)isHidden
{
    if ([theView isKindOfClass:[CPWindow class]])
    {
        if (isHidden)
            [theView orderOut:self];
        else
            [theView orderFront:self];
    }
    else
        [theView setHidden:isHidden];
}

- (id)_targetView:(CPDictionary)dictionary
{
    var targetView = [dictionary valueForKey:CPViewAnimationTargetKey];
    if (!targetView)
        [CPException raise:CPInternalInconsistencyException reason:[CPString stringWithFormat:@"view animation: %@ does not have a target view", [dictionary description]]];

    return targetView;
}

- (CGRect)_startFrame:(CPDictionary)dictionary
{
    var startFrame = [dictionary valueForKey:CPViewAnimationStartFrameKey];
    if (!startFrame)
        return [[self _targetView:dictionary] frame];

    return startFrame;
}

- (CGRect)_endFrame:(CPDictionary)dictionary
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

- (CPArray)viewAnimations
{
    return _viewAnimations;
}

/*!
    Takes an array of CPDictionaries as documented in initWithViewAnimations:.

    @param viewAnimations - An array of dictionaries describing the animation.
*/
- (void)setViewAnimations:(CPArray)viewAnimations
{
    if (viewAnimations != _viewAnimations)
    {
        [self stopAnimation];
        _viewAnimations = [viewAnimations copy];
    }
}

@end
