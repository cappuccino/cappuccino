@import <AppKit/CPApplication.j>
@import <AppKit/CPTextAttachment.j>
@import <AppKit/CPTextView.j>

@implementation CPTextAttachmentTest : OJTestCase
{
    CPWindow    theWindow;
    CPTextView  textView;
}

- (void)setUp
{
    [[CPApplication alloc] init];

    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 1024.0, 768.0) styleMask:CPWindowNotSizable];
    textView = [[CPTextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 300.0)];

    [textView setRichText:YES];
    [[theWindow contentView] addSubview:textView];
    [theWindow makeFirstResponder:textView];
}

/*
    Returns an attachment with a fixed size and no image, so that no image needs to load.
*/
- (CPTextAttachment)attachmentWithSize:(CGSize)aSize
{
    var attachment = [[CPTextAttachment alloc] initWithData:nil ofType:@"image/png"];

    [attachment setBounds:CGRectMake(0.0, 0.0, aSize.width, aSize.height)];

    return attachment;
}

- (void)testAttachmentWithDataURL
{
    var attachment = [CPTextAttachment _attachmentWithDataURL:@"data:image/gif;base64,R0lGODlhAQABAAAAACw="];

    [self assert:@"image/gif" equals:[attachment fileType]];
    [self assert:@"R0lGODlhAQABAAAAACw=" equals:[[attachment contents] base64]];
    [self assertNull:[CPTextAttachment _attachmentWithDataURL:@"not a data URL"]];
}

- (void)testArchiving
{
    var attachment = [[CPTextAttachment alloc] initWithData:[CPData dataWithBase64:@"R0lGODlhAQABAAAAACw="] ofType:@"public.png"];

    [attachment setBounds:CGRectMake(0.0, 0.0, 40.0, 30.0)];

    var decoded = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:attachment]];

    [self assert:@"R0lGODlhAQABAAAAACw=" equals:[[decoded contents] base64]];
    [self assert:@"public.png" equals:[decoded fileType]];
    [self assert:40.0 equals:[decoded bounds].size.width];
    [self assert:@"image/png" equals:[decoded _MIMEType]];
}

- (void)testDisplaySizeFitsTheMaximumWidth
{
    var attachment = [self attachmentWithSize:CGSizeMake(400.0, 200.0)],
        view = [attachment _attachmentView];

    [self assert:400.0 equals:[view frameSize].width];

    [self assertTrue:[attachment _setMaximumWidth:100.0]];
    [self assert:100.0 equals:[view frameSize].width];
    [self assert:50.0 equals:[view frameSize].height message:@"the image keeps its proportions"];

    [self assertTrue:[attachment _setMaximumWidth:1000.0]];
    [self assert:400.0 equals:[view frameSize].width message:@"an image is not enlarged beyond its size"];
}

- (void)testAttributedStringWithAttachment
{
    var attachment = [self attachmentWithSize:CGSizeMake(20.0, 10.0)],
        string = [CPTextStorage attributedStringWithAttachment:attachment],
        view = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 10.0, 10.0)],
        viewString = [CPTextStorage attributedStringWithAttachment:view];

    [self assert:_CPAttachmentCharacterAsString equals:[string string]];
    [self assert:attachment equals:[string attribute:CPAttachmentAttributeName atIndex:0 effectiveRange:nil]];
    [self assert:[attachment _attachmentView] equals:[string attribute:_CPAttachmentView atIndex:0 effectiveRange:nil]];

    [self assert:view equals:[viewString attribute:_CPAttachmentView atIndex:0 effectiveRange:nil] message:@"a view is still inserted directly"];
    [self assertNull:[viewString attribute:CPAttachmentAttributeName atIndex:0 effectiveRange:nil]];
}

- (void)testInsertedAttachmentFitsTheText
{
    var attachment = [self attachmentWithSize:CGSizeMake(1000.0, 500.0)];

    [textView setString:@"ab"];
    [textView setSelectedRange:CPMakeRange(1, 0)];
    [textView insertText:[CPTextStorage attributedStringWithAttachment:attachment]];

    var maximumWidth = [textView _textAttachmentMaximumWidth];

    [self assert:@"a" + _CPAttachmentCharacterAsString + @"b" equals:[textView string]];
    [self assert:maximumWidth equals:[[attachment _attachmentView] frameSize].width];
    [self assert:1 equals:[textView _indexOfTextAttachment:attachment]];
}

- (void)testArchivedTextHasNoAttachmentViews
{
    var attachment = [self attachmentWithSize:CGSizeMake(20.0, 10.0)],
        archived = [textView _attributedStringForArchiving:[CPTextStorage attributedStringWithAttachment:attachment]];

    [self assert:attachment equals:[archived attribute:CPAttachmentAttributeName atIndex:0 effectiveRange:nil]];
    [self assertNull:[archived attribute:_CPAttachmentView atIndex:0 effectiveRange:nil]];

    // Inserting the text gives the attachment its view again.
    [textView setString:@""];
    [textView insertText:archived];

    [self assert:[attachment _attachmentView] equals:[[textView textStorage] attribute:_CPAttachmentView atIndex:0 effectiveRange:nil]];
}

@end
