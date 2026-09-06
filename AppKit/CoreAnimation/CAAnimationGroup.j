/*
 * CAAnimationGroup.j
 * AppKit
 *
 * Created by Daniel Boehringer.
 * Copyright 2025.
 *
 * Implements grouping for Core Animation.
 */

@import <Foundation/CPArray.j>
@import "CAAnimation.j"

/*!
    @ingroup appkit
    @class CAAnimationGroup
    An object that allows multiple animations to be grouped and run concurrently.
*/
@implementation CAAnimationGroup : CAAnimation
{
    CPArray     _animations;
}

/*!
    Creates and returns a new \c CAAnimationGroup instance.
    @return a new \c CAAnimationGroup instance
*/
+ (id)group
{
    return [[self alloc] init];
}

/*!
    Initializes a newly allocated animation group with default values.
    @return the initialized animation group instance
*/
- (id)init
{
    if (self = [super init])
    {
        _animations = [];
    }
    return self;
}

/*!
    Sets the array of \c CAAnimation objects to be grouped together.
    @param anArray the array of animations
*/
- (void)setAnimations:(CPArray)anArray
{
    if (_animations === anArray)
        return;

    _animations = anArray;
}

/*!
    Returns the array of \c CAAnimation objects grouped together.
    @return the array of animations
*/
- (CPArray)animations
{
    return _animations;
}

/*!
    Executes the action on the given object by recursively running all grouped animations.
    @param aKey the identifier of the action
    @param anObject the target object of the animation
    @param arguments additional arguments for the action
*/
- (void)runActionForKey:(CPString)aKey object:(id)anObject arguments:(CPDictionary)arguments
{
    var count = [_animations count],
        i = 0;

    for (; i < count; i++)
    {
        var animation = [_animations objectAtIndex:i];

        // Recursively call runActionForKey on the child.
        // If the child is a CABasicAnimation, it will call [anObject addAnimation:...]
        // If the child is another Group, it will recurse here.
        if ([animation respondsToSelector:@selector(runActionForKey:object:arguments:)])
        {
            [animation runActionForKey:aKey object:anObject arguments:arguments];
        }
    }
}

@end
