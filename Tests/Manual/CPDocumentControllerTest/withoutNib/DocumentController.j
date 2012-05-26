@import <AppKit/CPDocumentController.j>
@import <AppKit/CPAlert.j>

@implementation DocumentController : CPDocumentController
{
}

- (id)init
{
    self = [super init];

    return self;
}

/* Instead of throwing error in browser environment, show an alert
 */
- (void)openDocument:(id)aSender
{
    var anAlert = [CPAlert alertWithError:@"Opening a document is not available!"];
    [anAlert beginSheetModalForWindow:[[CPApplication sharedApplication] mainWindow]];
}

@end
