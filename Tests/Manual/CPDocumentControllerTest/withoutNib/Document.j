@import <AppKit/CPDocument.j>

@implementation Document : CPDocument
{
}

- (CPString)windowCibName
{
    return @"Document";
}

- (void)windowControllerDidLoadCib:(CPWindowController)windowController
{
    var windowAutosaveName = @"TestDocumentWindow";
    
    [windowController setWindowFrameAutosaveName:windowAutosaveName];
    [[windowController window] setFrameUsingName:windowAutosaveName];
}


@end