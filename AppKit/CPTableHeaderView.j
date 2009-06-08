
@import <AppKit/CPView.j>


@implementation CPTableHeaderView : CPView
{
}

- (void)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];

    if (self)
        [self setBackgroundColor:[CPColor redColor]];

    return self;
}

@end