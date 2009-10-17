
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
    return [self runModalForDirectory:nil];
}

- (CPInteger)runModalForDirectory:(CPString)anAbsoluteDirectoryPath
{
    // FIXME: Is this correct???
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    var result = window.cpSavePanel(anAbsoluteDirectoryPath);

    return result.button;
}

- (CPURL)URL
{
    return [CPURL URLWithString:result.URL];
}

@end
