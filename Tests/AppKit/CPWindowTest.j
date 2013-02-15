
@import <AppKit/CPWindow.j>
@import <AppKit/_CPBorderlessWindowView.j>
@import <Foundation/CPURL.j>

[CPApplication sharedApplication];

@implementation CPWindowTest : OJTestCase
{
    CPWindow                _window @accessors(property=window);
}

- (void)setUp
{
    _window = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 1024.0, 768.0)
                                          styleMask:CPWindowNotSizable];
}

- (void)testCanAllocWindow
{
    [self assertTrue:!![self window]];
}

- (void)testThatNilIsInitialFirstResponder
{
    [self assert:nil
          equals:[[self window] initialFirstResponder]
         message:@"The initial first responder must be null"];
}

- (void)testKeyViewLoop
{
    var contentView = [[self window] contentView],
        textField = [CPTextField textFieldWithStringValue:@"" placeholder:@"" width:100.0];

    [textField setFrame:CGRectMake(100.0, 100.0, 100.0, 26.0)];
    [contentView addSubview:textField];

    var nextTextField = [CPTextField textFieldWithStringValue:@"" placeholder:@"" width:100];
    [nextTextField setFrame:CGRectMake(100.0, 200.0, 100.0, 26.0)];
    [contentView addSubview:nextTextField];

    [[self window] recalculateKeyViewLoop];

    // Test nextKeyView
    [self assert:textField
          equals:[contentView nextKeyView]
         message:@"textField should be the next key view of contentView"];

    [self assert:nextTextField
          equals:[textField nextKeyView]
         message:@"nextTextField should be the next key view of textField"];

    [self assert:contentView
          equals:[nextTextField nextKeyView]
         message:@"contentView should be the next key view of nextTextField"];

    // Test previousKeyView
    [self assert:contentView
          equals:[textField previousKeyView]
         message:@"contentView should be the previous key view of textField"];

    [self assert:textField
          equals:[nextTextField previousKeyView]
         message:@"textField should be the previous key view of nextTextField"];

    [self assert:nextTextField
          equals:[contentView previousKeyView]
         message:@"nextTextField should be the previous key view of contentView"];
}

- (void)testValiKeyViewLoop
{
    var contentView = [[self window] contentView],
        textField = [CPTextField textFieldWithStringValue:@"" placeholder:@"" width:100.0];

    [textField setFrame:CGRectMake(100.0, 100.0, 100.0, 26.0)];
    [contentView addSubview:textField];
    [[self window] recalculateKeyViewLoop];

    var nextTextField = [CPTextField textFieldWithStringValue:@"" placeholder:@"" width:100];
    [nextTextField setFrame:CGRectMake(100.0, 200.0, 100.0, 26.0)];
    [contentView addSubview:nextTextField];
    [[self window] recalculateKeyViewLoop];

    // Test nextValidKeyView
    [self assert:textField
          equals:[contentView nextValidKeyView]
         message:@"textField should be the next valid key view of contentView"];

    [self assert:nextTextField
          equals:[textField nextValidKeyView]
         message:@"nextTextField should be the next valid key view of textField"];

    [self assert:textField
          equals:[nextTextField nextValidKeyView]
         message:@"textField should be the next key valid view of nextTextField"];

    // Test previousValidKeyView
    [self assert:nextTextField
          equals:[textField previousValidKeyView]
         message:@"nextTextField should be the previous valid key view of textField"];

    [self assert:textField
          equals:[nextTextField previousValidKeyView]
         message:@"textField should be the previous key valid view of nextTextField"];

    [self assert:nextTextField
          equals:[contentView previousValidKeyView]
         message:@"nextTextField should be the previous valid key view of contentView"];
}

- (void)testRepresentedFilename
{
    /*
        representedURL and representedFilename
        are drawn from the _representedURL variable.
    */
    var aURL = @"http://www.cappuccino-project.org";

    [[self window] setRepresentedURL:[CPURL URLWithString:aURL]];
    [self assertTrue:[[[self window] representedURL] class] === [CPURL class]];
    /*
        Test for Issue 1633
        Make sure that changing it via setRepresentedFilename doesn't change the type
    */
    [[self window] setRepresentedFilename:aURL];
    [self assertTrue:[[[self window] representedURL] class] === [CPURL class]];
}

@end
