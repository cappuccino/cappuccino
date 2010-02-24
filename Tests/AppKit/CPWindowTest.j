
@import <AppKit/CPWindow.j>

[CPApplication sharedApplication]

@implementation CPWindowTest : OJTestCase
{
    CPWindow theWindow;
}

-(void)testCanAllocWindow
{
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0,0,200,150) 
                                            styleMask:CPWindowNotSizable];

    [self assertTrue:!!theWindow];
}

@end