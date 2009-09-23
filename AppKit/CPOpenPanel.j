
@import <AppKit/CPPanel.j>
#include "Platform/Platform.h"


@implementation CPOpenPanel : CPPanel
{
    JSObject    _openPanel;
}

+ (id)openPanel
{
    return [[CPOpenPanel alloc] init];
}

- (id)init
{
    if (self = [super init])
        _openPanel = window.application.createOpenPanel();

    return self;
}

- (BOOL)canChooseFiles
{
    return _openPanel.canChooseFiles;
}

- (void)setCanChooseFiles:(BOOL)shouldChooseFiles
{
    _openPanel.canChooseFiles = shouldChooseFiles;
}

- (BOOL)canChooseDirectories
{
    return _openPanel.canChooseDirectories;
}

- (void)setCanChooseDirectories:(BOOL)shouldChooseDirectories
{
    _openPanel.canChooseDirectories = shouldChooseDirectories;
}

- (BOOL)resolvesAliases
{
    return _openPanel.resolvesAliases;
}

- (BOOL)setResolvesAliases:(BOOL)shouldResolveAliases
{
    return _openPanel.resolvesAliases = shouldResolveAliases;
}

- (BOOL)allowsMultipleSelections
{
    return _openPanel.resolvesAliases;
}

- (BOOL)setAllowsMultipleSelections:(BOOL)shouldAllowMultipleSelection
{
    return _openPanel.allowsMultipleSelection = shouldAllowMultipleSelection;
}

- (void)filenames
{
    return _openPanel.filenames;
}

- (CPInteger)runModalForDirectory:(CPString)anAbsoluteDirectoryPath file:(CPString)aFilename types:(CPArray)fileTypes
{
    // FIXME: Is this correct???
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    return _openPanel.runModal(anAbsoluteDirectoryPath, aFilename, fileTypes);
}

- (CPInteger)runModalForTypes:(CPArray)fileTypes 
{
    // FIXME: Is this correct???
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    return _openPanel.runModal(fileTypes);
}

@end
