@import <AppKit/AppKit.j>

@implementation CPTextViewTest : OJTestCase
{
    CPTextView   _textView;
}

- (void)setUp
{
    _textView = [[CPTextView alloc] initWithFrame:CGRectMake(0,0,500,500)];
    [_textView insertText:"Fusce\nlectus neque cr     as eget lectus neque cr as eget lectus cr as eget lectus"];
}

- (void)testMoveToEndOfDocument
{
    [_textView setSelectedRange:CPMakeRange(0, 0)];
    [_textView moveToEndOfDocument:self];
    var range = [_textView selectedRange];
    [self assert:range.location equals:[[_textView layoutManager] numberOfCharacters]];
    [self assert:range.length equals:0];

}
- (void)testMoveToBeginningOfDocument
{
    [_textView setSelectedRange:CPMakeRange(1, 0)];
    [_textView moveToBeginningOfDocument:self];
    var range = [_textView selectedRange];
    [self assert:range.location equals:0];
    [self assert:range.length equals:0];
}
- (void)testSelectAll
{
    [_textView setSelectedRange:CPMakeRange(1, 0)];
    [_textView selectAll:self];
    var range = [_textView selectedRange];
    [self assert:range.location equals:0];
    [self assert:range.length equals:[[_textView layoutManager] numberOfCharacters]];
}
- (void)testMoveToEndOfParagraph
{
    [_textView setSelectedRange:CPMakeRange(1, 0)];
    [_textView moveToEndOfParagraph:self];
    var range = [_textView selectedRange];
    [self assert:range.location equals:5];
    [self assert:range.length equals:0];
}
- (void)testMoveWordForward
{
    [_textView setSelectedRange:CPMakeRange(19, 0)];    // beginning of "cr"
    [_textView moveWordForward:self];
    var range = [_textView selectedRange];
    [self assert:range.location equals:21];    // should be at the end of "cr"
    [_textView moveWordForward:self];
    range = [_textView selectedRange];
    [self assert:range.location equals:28];    // should be at the end of "as"
}
- (void)testMoveWordBackward
{
    [_textView setSelectedRange:CPMakeRange(19, 0)];    // beginning of "cr"
    [_textView moveWordBackward:self];
    var range = [_textView selectedRange];
    [self assert:range.location equals:13];    // should be at the beginning of "neque"
}
- (void)testMoveWordAndExtend
{
    [_textView setSelectedRange:CPMakeRange(19, 0)];  // beginning of "cr"
    [_textView moveRight:self];   // middle of "cr"
    [_textView moveWordBackwardAndModifySelection:self];
    var range = [_textView selectedRange];
    [self assert:range.location equals:19];    // "c" of "cr" should be selected
    [self assert:range.length equals:1];
}

- (void)testCutAndPasteAreDuals
{
    [_textView setSelectedRange:CPMakeRange(19, 2)];    // select "cr"
    [_textView cut:self];
    [_textView paste:self];
    var oldString = [_textView stringValue];
    [self assert:[_textView stringValue] equals:oldString];
}

@end
