@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>


@implementation AppController : CPObject <CPAnimationDelegate>
{
    @outlet CPWindow    theWindow;
    @outlet CPView      view;
    @outlet CPButton    buttonStart;
    @outlet CPButton    buttonStop;

    CPAnimation _animation;
    CGPoint     _firstPoint;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
    _firstPoint = CGPointMakeCopy([view frameOrigin]);
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];
}

- (IBAction)clickButtonStart:(id)sender
{
    [view setFrameOrigin:_firstPoint];

    _animation = [[CPViewAnimation alloc] initWithViewAnimations:[
        [CPDictionary dictionaryWithJSObject:{
            CPViewAnimationTargetKey:view,
            CPViewAnimationStartFrameKey:[view frame],
            CPViewAnimationEndFrameKey:CGRectMake([view frameOrigin].x, [view frameOrigin].y + 200, [view frameSize].width, [view frameSize].height)
        }]]];

    [_animation setAnimationCurve:CPAnimationLinear];
    [_animation setDuration:2];
    [_animation setDelegate:self];
    [_animation startAnimation];
}

- (IBAction)clickButtonStop:(id)sender
{
    [_animation stopAnimation];
}

- (void)animationDidEnd:(CPAnimation)anAnimation
{
    console.error(@"animationDidEnd");
}

- (void)animationDidStop:(CPAnimation)anAnimation
{
    console.error(@"animationDidStop");
}

- (BOOL)animationShouldStart:(CPAnimation)anAnimation
{
    console.error(@"animationShouldStart");
    return YES;
}

- (float)animation:(CPAnimation)animation valueForProgress:(float)progress
{
    console.error(@"animation:valueForProgress: " + progress);
    return progress;
}

@end
