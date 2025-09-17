@implementation DocumentView : CPView
{
    BOOL                            _showHeaderView @accessors(property=showHeaderView);

    CPView                          _headerView @accessors(property=headerView);
    CPView                          _cornerView @accessors(property=cornerView);
}

- (void)awakeFromCib
{
    [self setFrame:CGRectMake(0.0, 0.0, 2000.0, 2000.0)];
}

- (CPView)headerView
{
    if (![self showHeaderView])
        return nil;

    if (!_headerView)
    {
        _headerView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth([self bounds]), 30.0)];
        [_headerView setAutoresizingMask:CPViewWidthSizable];
        [_headerView setAlphaValue:0.3];
        [_headerView setBackgroundColor:[CPColor greenColor]];
    }

    return _headerView;
}

- (CPView)cornerView
{
    if (![self showHeaderView])
        return nil;

    if (!_cornerView)
    {
        _cornerView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 15.0, 30.0)];
        [_cornerView setAutoresizingMask:CPViewWidthSizable];
        [_cornerView setAlphaValue:0.3];
        [_cornerView setBackgroundColor:[CPColor blueColor]];
    }

    return _cornerView;
}

@end