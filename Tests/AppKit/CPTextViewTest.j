@import <AppKit/CPTextView.j>

[CPApplication sharedApplication]

@implementation CPTextViewTest : OJTestCase
{
    CPWindow    theWindow;
    CPTextView  textView;
}

- (void)setUp
{
    // setup a reasonable table
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 1024.0, 768.0) styleMask:CPWindowNotSizable];
    textView = [[CPTextView alloc] initWithFrame:CGRectMake(0,0,300,300)];

    [[theWindow contentView] addSubview:textView];
}

- (void)testMakeCPTextViewInstance
{
    [self assertNotNull:textView];
}

@end