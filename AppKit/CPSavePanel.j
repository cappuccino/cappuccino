
@import <AppKit/CPPanel.j>


@implementation CPSavePanel : CPPanel
{
    JSObject    _savePanel;
}

+ (id)savePanel
{
    return [[CPSavePanel alloc] init];
}

- (id)init
{
    if (self = [super init])
        _savePanel = window.application.createSavePanel();

    return self;
}

- (CPInteger)runModal
{
    // FIXME: Is this correct???
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    return _savePanel.runModal();
}

- (CPInteger)runModalForDirectory:(CPString)anAbsoluteDirectoryPath
{
    // FIXME: Is this correct???
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    return _savePanel.runModal(anAbsoluteDirectoryPath);
}

- (CPString)filename
{
    return _savePanel.filename;
}

@end
