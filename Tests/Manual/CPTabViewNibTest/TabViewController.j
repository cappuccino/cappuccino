@implementation TabViewController : CPViewController
{
}

- (void)viewDidAppear
{
    CPLog.debug(_cmd);
    var view = [self view];

    [view setFrameSize:[[view superview] frameSize]];
}

@end
