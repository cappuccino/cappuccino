@import <AppKit/CPDocument.j>

@implementation Document : CPDocument
{
}

- (CPString)windowCibName
{
    return @"Document";
}

- (void)readFromURL:(CPURL)anAbsoluteURL ofType:(CPString)aType delegate:(id)aDelegate didReadSelector:(SEL)aDidReadSelector contextInfo:(id)aContextInfo
{
    // does nothing, just skip the actual URL access
    CPLog("Document#readFromURL");
}

@end
