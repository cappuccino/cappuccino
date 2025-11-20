/*
 * CAAnimationGroup.j
 * AppKit
 *
 * Implements grouping for Core Animation.
 */

@import <Foundation/CPArray.j>
@import "CAAnimation.j"

@implementation CAAnimationGroup : CAAnimation
{
    CPArray     _animations;
}

+ (id)group
{
    return [[self alloc] init];
}

- (id)init
{
    if (self = [super init])
    {
        _animations = [];
    }
    return self;
}

- (void)setAnimations:(CPArray)anArray
{
    if (_animations === anArray)
        return;
        
    _animations = anArray;
}

- (CPArray)animations
{
    return _animations;
}

/*
    Iterates through children and executes them recursively.
    This effectively runs all grouped animations concurrently.
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
