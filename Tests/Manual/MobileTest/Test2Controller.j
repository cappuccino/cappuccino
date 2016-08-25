@import <AppKit/AppKit.j>
@import "Test1Controller.j"


@implementation Test2Controller : CPViewController
{
}

- (id)init
{
    return [super initWithCibName:@"Test2View" bundle:nil];
}

- (void)viewDidLoad
{
    CPLog("Loaded %@ view %@", self, [self view]);
}

@end
