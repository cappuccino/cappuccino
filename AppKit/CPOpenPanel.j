
@import <AppKit/CPPanel.j>
#include "Platform/Platform.h"

var SharedOpenPanel = nil;

@implementation CPOpenPanel : CPPanel
{
    CPArray _files;
    BOOL    _canChooseFiles @accessors(property=canChooseFiles);
    BOOL    _canChooseDirectories @accessors(property=canChooseDirectories);
    BOOL    _allowsMultipleSelection @accessors(property=allowsMultipleSelection);
}

+ (id)openPanel
{
    if (!SharedOpenPanel)
        SharedOpenPanel = [[CPOpenPanel alloc] init];

    return SharedOpenPanel;
}

- (id)init
{
    if (self = [super init])
    {
        _files = [];
        _canChooseFiles = YES;
    }

    return self;
}

- (void)filenames
{
    return _files;
}

- (unsigned)runModalForDirectory:(CPString)absoluteDirectoryPath file:(CPString)filename types:(CPArray)fileTypes
{
#if PLATFORM(DOM)
    if (window.Titanium)
    {
        _files = Titanium.Desktop.openFiles({
            path:absoluteDirectoryPath,
            types:fileTypes,
            multiple:_allowsMultipleSelection,
            filename:filename,
            directories:_canChooseDirectories,
            files:_canChooseFiles
        });
    }
#endif
}

- (unsigned)runModalForTypes:(CPArray)fileTypes 
{alert("HERE");
    [self runModalForDirectory:"/" file:nil types:fileTypes];
}

@end
