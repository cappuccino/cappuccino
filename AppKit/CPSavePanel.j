
@import <AppKit/CPPanel.j>


@implementation CPSavePanel : CPPanel
{
    Object result;
}

+ (id)savePanel
{
    return [[CPSavePanel alloc] init];
}

- (CPInteger)runModal
{
    // FIXME: Is this correct???
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    result = window.cpSavePanel();

    return result.button;
}

- (CPURL)URL
{
    return [CPURL URLWithString:result.URL];
}

@end
