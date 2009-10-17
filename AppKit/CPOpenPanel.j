
@import <AppKit/CPPanel.j>
#include "Platform/Platform.h"


@implementation CPOpenPanel : CPPanel
{
    BOOL    _canChooseFiles             @accessors(property=canChooseFiles);
    BOOL    _canChooseDirectories       @accessors(property=canChooseDirectories);
    BOOL    _allowsMultipleSelection    @accessors(property=allowsMultipleSelection);
    CPURL   _directoryURL               @accessors(property=directoryURL);
    CPArray _URLs;
}

+ (id)openPanel
{
    return [[CPOpenPanel alloc] init];
}

- (CPInteger)runModal
{
    // FIXME: Is this correct???
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    var options = { directoryURL: [self directoryURL],
                    canChooseFiles: [self canChooseFiles],
                    canChooseDirectories: [self canChooseDirectories],
                    allowsMultipleSelection: [self allowsMultipleSelection] };

    var result = window.cpOpenPanel(options);

    _URLs = result.URLs;

    return result.button;
}

- (CPArray)URLs
{
    return _URLs;
}

@end
