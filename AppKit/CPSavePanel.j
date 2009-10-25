
@import <AppKit/CPPanel.j>


@implementation CPSavePanel : CPPanel
{
    CPURL   _URL;
}

+ (id)savePanel
{
    return [[CPSavePanel alloc] init];
}

- (CPInteger)runModal
{
    // FIXME: Is this correct???
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    if (typeof window["cpSavePanel"] === "function")
    {
        var resultObject = window.cpSavePanel(),
            result = resultObject.button;

        _URL = result ? [CPURL URLWithString:resultObject.URL] : nil;
    }
    else
    {
        // FIXME: This is not the best way to do this.
        var documentName = window.prompt("Document Name:"),
            result = documentName !== null;

        _URL = result ? [[self class] proposedFileURLWithDocumentName:documentName] : nil;
    }

    return result;
}

- (CPURL)URL
{
    return _URL;
}

@end
