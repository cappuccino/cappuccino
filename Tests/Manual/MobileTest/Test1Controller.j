@import <AppKit/AppKit.j>
@import "Test1Controller.j"


@implementation Test1Controller : CPViewController
{
}

- (id)init
{
    return [super initWithCibName:@"Test1View" bundle:nil];
}

- (void)viewDidLoad
{
    CPLog("Loaded %@ view %@", self, [self view]);
}

@end
