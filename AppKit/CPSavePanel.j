
@import "CPPanel.j"


@implementation CPSavePanel : CPPanel
{
    CPURL   _URL;

    BOOL    _isExtensionHidden @accessors(getter=isExtensionHidden, setter=setExtensionHidden:);
    BOOL    _canSelectHiddenExtension @accessors(property=canSelectHiddenExtension);
    BOOL    _allowsOtherFileTypes @accessors(property=allowsOtherFileTypes);
    BOOL    _canCreateDirectories @accessors(property=canCreateDirectories);

    CPArray _allowedFileTypes @accessors(property=allowedFileTypes);
}

+ (id)savePanel
{
    return [[CPSavePanel alloc] init];
}

- (id)init
{
    if (self = [super init])
    {
        _canCreateDirectories = YES;
    }

    return self;
}

- (CPInteger)runModal
{
    // FIXME: Is this correct???
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    if (typeof window["cpSavePanel"] === "function")
    {
        var resultObject = window.cpSavePanel({
                isExtensionHidden: _isExtensionHidden,
                canSelectHiddenExtension: _canSelectHiddenExtension,
                allowsOtherFileTypes: _allowsOtherFileTypes,
                canCreateDirectories: _canCreateDirectories,
                allowedFileTypes: _allowedFileTypes
            }),
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
