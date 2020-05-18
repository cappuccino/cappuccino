@import <AppKit/CPTextView.j>
@import <OJMoq/OJMoq.j>

@implementation CPTextViewTest : OJTestCase
{
    CPWindow    theWindow;
    CPTextView  textView;

    CPString    stringValue;

    OJMoqSpy    delegateSpy
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    // setup a reasonable table
    theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 1024.0, 768.0) styleMask:CPWindowNotSizable];

    textView = [[CPTextView alloc] initWithFrame:CGRectMake(0,0,300,300)];

    stringValue = @"My string  is here";

    [textView setString:stringValue];
    [textView setDelegate:self];

    [[theWindow contentView] addSubview:textView];
    
    delegateSpy = spy(self);
}

- (void)tearDown
{
    [delegateSpy reset];
}

- (void)testMakeCPTextViewInstance
{
    [self assertNotNull:textView];
}

- (void)testTextViewSetStringMethod
{
    [self assert:stringValue equals:[textView stringValue]];
}

- (void)testTextViewSelectionRange
{
    var range;

    [delegateSpy selector:@selector(textView:willChangeSelectionFromCharacterRange:toCharacterRange:) times:1 arguments:[textView, CPMakeRange(0,0), CPMakeRange(0, 18)]];
    [delegateSpy selector:@selector(textViewDidChangeSelection:) times:1];
    [delegateSpy selector:@selector(textView:shouldChangeTypingAttributes:toAttributes:) times:1];
    [delegateSpy selector:@selector(textViewDidChangeTypingAttributes:) times:1];
    [delegateSpy selector:@selector(textDidChange:) times:0];
    [delegateSpy selector:@selector(textShouldBeginEditing:) times:0];
    [delegateSpy selector:@selector(textDidBeginEditing:) times:0];
    [delegateSpy selector:@selector(textShouldEndEditing:) times:0];
    [delegateSpy selector:@selector(textDidEndEditing:) times:0];
    [textView selectAll:self];
    range = [[textView selectedRanges] firstObject];
    [self assert:0 equals:range.location];
    [self assert:18 equals:range.length];
    [delegateSpy verifyThatAllExpectationsHaveBeenMet];

    [delegateSpy reset];
    [delegateSpy selector:@selector(textView:willChangeSelectionFromCharacterRange:toCharacterRange:) times:1 arguments:[textView, CPMakeRange(0, 18), CPMakeRange(3, 6)]];
    [delegateSpy selector:@selector(textViewDidChangeSelection:) times:1];
    [delegateSpy selector:@selector(textView:shouldChangeTypingAttributes:toAttributes:) times:1];
    [delegateSpy selector:@selector(textViewDidChangeTypingAttributes:) times:1];
    [delegateSpy selector:@selector(textDidChange:) times:0];
    [delegateSpy selector:@selector(textShouldBeginEditing:) times:0];
    [delegateSpy selector:@selector(textDidBeginEditing:) times:0];
    [delegateSpy selector:@selector(textShouldEndEditing:) times:0];
    [delegateSpy selector:@selector(textDidEndEditing:) times:0];
    [textView setSelectedRange:CPMakeRange(3, 6)];
    range = [[textView selectedRanges] firstObject];
    [self assert:3 equals:range.location];
    [self assert:6 equals:range.length];
    [delegateSpy verifyThatAllExpectationsHaveBeenMet];

    // When selecting the same range again textView:shouldChangeTypingAttributes:toAttributes: or textViewDidChangeTypingAttributes: should not be triggered
    [delegateSpy reset];
    [delegateSpy selector:@selector(textView:willChangeSelectionFromCharacterRange:toCharacterRange:) times:1 arguments:[textView, CPMakeRange(3, 6), CPMakeRange(3, 6)]];
    [delegateSpy selector:@selector(textViewDidChangeSelection:) times:1];
    [delegateSpy selector:@selector(textView:shouldChangeTypingAttributes:toAttributes:) times:0];
    [delegateSpy selector:@selector(textViewDidChangeTypingAttributes:) times:0];
    [delegateSpy selector:@selector(textDidChange:) times:0];
    [delegateSpy selector:@selector(textShouldBeginEditing:) times:0];
    [delegateSpy selector:@selector(textDidBeginEditing:) times:0];
    [delegateSpy selector:@selector(textShouldEndEditing:) times:0];
    [delegateSpy selector:@selector(textDidEndEditing:) times:0];
    [textView setSelectedRange:CPMakeRange(3, 6)];
    range = [[textView selectedRanges] firstObject];
    [self assert:3 equals:range.location];
    [self assert:6 equals:range.length];
    [delegateSpy verifyThatAllExpectationsHaveBeenMet];
}

- (void)testTextDidChange
{
    [delegateSpy selector:@selector(textDidChange:) times:1];
    [delegateSpy selector:@selector(textShouldBeginEditing:) times:0];
    [delegateSpy selector:@selector(textDidBeginEditing:) times:0];
    [delegateSpy selector:@selector(textShouldEndEditing:) times:0];
    [delegateSpy selector:@selector(textDidEndEditing:) times:0];
    [textView setString:@"New text"];
    [delegateSpy verifyThatAllExpectationsHaveBeenMet];
}

- (void)testTextBeginEditing
{
    [delegateSpy selector:@selector(textDidChange:) times:1];
    [delegateSpy selector:@selector(textShouldBeginEditing:) times:1];
    [delegateSpy selector:@selector(textDidBeginEditing:) times:1];
    [delegateSpy selector:@selector(textShouldEndEditing:) times:0];
    [delegateSpy selector:@selector(textDidEndEditing:) times:0];
    [self assertTrue:[theWindow makeFirstResponder:textView]];
    [textView insertText:@"New text"];
    [delegateSpy verifyThatAllExpectationsHaveBeenMet];
}

- (void)testTextEndEditing
{
    [self assertTrue:[theWindow makeFirstResponder:textView]];
    [textView insertText:@"New text"];
    [delegateSpy selector:@selector(textDidChange:) times:0];
    [delegateSpy selector:@selector(textShouldBeginEditing:) times:0];
    [delegateSpy selector:@selector(textDidBeginEditing:) times:0];
    [delegateSpy selector:@selector(textShouldEndEditing:) times:1];
    [delegateSpy selector:@selector(textDidEndEditing:) times:1];
    [self assertFalse:[theWindow makeFirstResponder:nil]];
    [delegateSpy verifyThatAllExpectationsHaveBeenMet];
}

@end

@implementation CPTextViewTest (CPTextViewTestDelegate)

- (CPRange)textView:(CPTextView)aTextView willChangeSelectionFromCharacterRange:(CPRange)oldSelectedCharRange toCharacterRange:(CPRange)newSelectedCharRange
{
    return newSelectedCharRange;
}

- (CPDictionary)textView:(CPTextView)textView shouldChangeTypingAttributes:(CPDictionary)oldTypingAttributes toAttributes:(CPDictionary)newTypingAttributes
{
    return newTypingAttributes;
}

- (void)textViewDidChangeSelection:(CPNotification)aNotification
{

}

- (void)textViewDidChangeTypingAttributes:(CPNotification)aNotification
{

}

- (void)textDidChange:(CPNotification)aNotification
{

}

- (BOOL)textShouldBeginEditing:(CPText)aTextObject
{
    return YES;
}

- (void)textDidBeginEditing:(CPNotification)aNotification
{

}

- (BOOL)textShouldEndEditing:(CPText)aTextObject
{
    return YES;
}

- (void)textDidEndEditing:(CPNotification)aNotification
{

}

@end
