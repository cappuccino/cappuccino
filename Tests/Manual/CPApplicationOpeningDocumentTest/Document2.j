@import <AppKit/CPDocument.j>

@implementation Document2 : CPDocument
{
}

- (CPString)windowCibName
{
    return @"Document2";
}

- (void)readFromURL:(CPURL)anAbsoluteURL ofType:(CPString)aType delegate:(id)aDelegate didReadSelector:(SEL)aDidReadSelector contextInfo:(id)aContextInfo
{
    // does nothing, just skip the actual URL access
    CPLog("Document2#readFromURL");
}

@end
