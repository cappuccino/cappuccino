@import <AppKit/CPApplication.j>
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

- (void)testTextViewRespondsToUndoOnlyWhenUndoIsAllowed
{
    [textView setAllowsUndo:YES];

    [self assertTrue:[textView respondsToSelector:@selector(undo:)]];
    [self assertTrue:[textView respondsToSelector:@selector(redo:)]];

    [textView setAllowsUndo:NO];

    [self assertFalse:[textView respondsToSelector:@selector(undo:)] message:@"undo: should continue to the window"];
    [self assertFalse:[textView respondsToSelector:@selector(redo:)] message:@"redo: should continue to the window"];
}

- (void)testTextViewRegistersUndoOnlyWhenUndoIsAllowed
{
    var undoManager = [theWindow undoManager];

    [self assertTrue:[theWindow makeFirstResponder:textView]];

    [textView setAllowsUndo:NO];
    [undoManager removeAllActions];
    [textView insertText:@"Not recorded"];

    [self assertFalse:[undoManager canUndo] message:@"a text view that does not allow undo should register nothing"];

    [textView setAllowsUndo:YES];
    [textView insertText:@"Recorded"];

    [self assertTrue:[undoManager canUndo] message:@"a text view that allows undo should register its change"];
}

- (void)testSuperscriptSubscriptAndUnscript
{
    [textView setRichText:YES];
    [self assertTrue:[theWindow makeFirstResponder:textView]];
    [textView setSelectedRange:CPMakeRange(0, 2)];

    [textView superscript:nil];
    [self assert:1 equals:[[textView textStorage] attribute:CPSuperscriptAttributeName atIndex:0 effectiveRange:nil]];

    [textView superscript:nil];
    [self assert:2 equals:[[textView textStorage] attribute:CPSuperscriptAttributeName atIndex:1 effectiveRange:nil]];

    [textView subscript:nil];
    [textView subscript:nil];
    [self assertTrue:([[textView textStorage] attribute:CPSuperscriptAttributeName atIndex:0 effectiveRange:nil] == nil) message:@"a level of zero removes the attribute"];

    [textView subscript:nil];
    [textView raiseBaseline:nil];
    [self assert:-1 equals:[[textView textStorage] attribute:CPSuperscriptAttributeName atIndex:0 effectiveRange:nil]];
    [self assert:1 equals:[[textView textStorage] attribute:CPBaselineOffsetAttributeName atIndex:0 effectiveRange:nil]];

    [textView unscript:nil];
    [self assertTrue:([[textView textStorage] attribute:CPSuperscriptAttributeName atIndex:0 effectiveRange:nil] == nil)];
    [self assertTrue:([[textView textStorage] attribute:CPBaselineOffsetAttributeName atIndex:0 effectiveRange:nil] == nil)];

    [self assertTrue:([[textView textStorage] attribute:CPSuperscriptAttributeName atIndex:5 effectiveRange:nil] == nil) message:@"text outside the selection is unchanged"];
}

- (void)testSuperscriptWithoutSelectionChangesTypingAttributes
{
    [textView setRichText:YES];
    [self assertTrue:[theWindow makeFirstResponder:textView]];
    [textView setSelectedRange:CPMakeRange(3, 0)];

    [textView superscript:nil];
    [self assert:1 equals:[[textView typingAttributes] objectForKey:CPSuperscriptAttributeName]];

    [textView unscript:nil];
    [self assertTrue:([[textView typingAttributes] objectForKey:CPSuperscriptAttributeName] == nil)];
}

- (void)testTypingAttributesComeFromTheCharacterBeforeTheInsertionPoint
{
    var font = [CPFont boldSystemFontOfSize:20.0],
        length = [stringValue length];

    [textView setRichText:YES];
    [self assertTrue:[theWindow makeFirstResponder:textView]];
    [[textView textStorage] addAttribute:CPFontAttributeName value:font range:CPMakeRange(length - 4, 4)];

    [textView setSelectedRange:CPMakeRange(length, 0)];
    [self assert:[font cssString] equals:[[[textView typingAttributes] objectForKey:CPFontAttributeName] cssString] message:@"at the end of the text"];

    [textView setSelectedRange:CPMakeRange(length - 4, 0)];
    [self assertFalse:[font cssString] === [[[textView typingAttributes] objectForKey:CPFontAttributeName] cssString] message:@"before the styled text"];

    [textView setSelectedRange:CPMakeRange(length - 4, 2)];
    [self assert:[font cssString] equals:[[[textView typingAttributes] objectForKey:CPFontAttributeName] cssString] message:@"for a selection"];
}

- (void)testCopyAndPasteStyle
{
    var font = [CPFont boldSystemFontOfSize:20.0],
        color = [CPColor redColor],
        paragraphStyle = [[CPParagraphStyle defaultParagraphStyle] mutableCopy];

    [paragraphStyle setAlignment:CPCenterTextAlignment];

    [textView setRichText:YES];
    [self assertTrue:[theWindow makeFirstResponder:textView]];
    [[textView textStorage] addAttributes:@{CPFontAttributeName: font, CPForegroundColorAttributeName: color} range:CPMakeRange(0, 2)];
    [[textView textStorage] addAttribute:CPParagraphStyleAttributeName value:paragraphStyle range:CPMakeRange(3, 6)];

    [textView setSelectedRange:CPMakeRange(0, 2)];
    [textView copyFont:nil];

    [textView setSelectedRange:CPMakeRange(3, 6)];
    [textView pasteFont:nil];

    var storage = [textView textStorage];

    [self assert:[font cssString] equals:[[storage attribute:CPFontAttributeName atIndex:5 effectiveRange:nil] cssString]];
    [self assert:[color cssString] equals:[[storage attribute:CPForegroundColorAttributeName atIndex:5 effectiveRange:nil] cssString]];
    [self assert:CPCenterTextAlignment equals:[[storage attribute:CPParagraphStyleAttributeName atIndex:5 effectiveRange:nil] alignment] message:@"Paste Style keeps the paragraph style"];
    [self assertTrue:([storage attribute:CPForegroundColorAttributeName atIndex:9 effectiveRange:nil] == nil) message:@"Paste Style changes only the selection"];
}

- (void)testPasteStyleWithoutSelectionChangesTypingAttributes
{
    var font = [CPFont boldSystemFontOfSize:20.0];

    [textView setRichText:YES];
    [self assertTrue:[theWindow makeFirstResponder:textView]];
    [[textView textStorage] addAttribute:CPFontAttributeName value:font range:CPMakeRange(0, 2)];

    [textView setSelectedRange:CPMakeRange(0, 2)];
    [textView copyFont:nil];

    [textView setSelectedRange:CPMakeRange(5, 0)];
    [textView pasteFont:nil];

    [self assert:[font cssString] equals:[[[textView typingAttributes] objectForKey:CPFontAttributeName] cssString]];
}

- (void)testStyleActionsAreEnabledOnlyInRichText
{
    var copyItem = [[CPMenuItem alloc] initWithTitle:@"Copy Style" action:@selector(copyFont:) keyEquivalent:@""],
        pasteItem = [[CPMenuItem alloc] initWithTitle:@"Paste Style" action:@selector(pasteFont:) keyEquivalent:@""];

    [textView setRichText:NO];
    [self assertFalse:[textView validateUserInterfaceItem:copyItem]];
    [self assertFalse:[textView validateUserInterfaceItem:pasteItem]];

    [textView setRichText:YES];
    [textView copyFont:nil];
    [self assertTrue:[textView validateUserInterfaceItem:copyItem]];
    [self assertTrue:[textView validateUserInterfaceItem:pasteItem]];

    [textView setEditable:NO];
    [self assertFalse:[textView validateUserInterfaceItem:pasteItem]];
}

- (void)testBaselineActionsAreEnabledOnlyInEditableRichText
{
    var item = [[CPMenuItem alloc] initWithTitle:@"Superscript" action:@selector(superscript:) keyEquivalent:@""];

    [textView setRichText:NO];
    [self assertFalse:[textView validateUserInterfaceItem:item]];

    [textView setRichText:YES];
    [self assertTrue:[textView validateUserInterfaceItem:item]];

    [textView setEditable:NO];
    [self assertFalse:[textView validateUserInterfaceItem:item]];
}

- (void)testUndoItemIsEnabledOnlyWhenThereIsAChangeToUndo
{
    var undoManager = [theWindow undoManager],
        undoItem = [[CPMenuItem alloc] initWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@""],
        redoItem = [[CPMenuItem alloc] initWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@""];

    [self assertTrue:[theWindow makeFirstResponder:textView]];
    [undoManager removeAllActions];

    [self assertFalse:[textView validateUserInterfaceItem:undoItem]];
    [self assertFalse:[theWindow validateUserInterfaceItem:undoItem]];
    [self assertFalse:[textView validateUserInterfaceItem:redoItem]];

    [textView insertText:@"Recorded"];

    [self assertTrue:[textView validateUserInterfaceItem:undoItem]];
    [self assertTrue:[theWindow validateUserInterfaceItem:undoItem]];
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
