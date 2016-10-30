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
    //TODO : uncomment once ojtest will be up to date on travis
    var range;
    //
    //[delegateSpy selector:@selector(textView:willChangeSelectionFromCharacterRange:toCharacterRange:) times:1 arguments:[textView, CPMakeRange(0,0), CPMakeRange(0, 18)]];
    //[delegateSpy selector:@selector(textViewDidChangeSelection:) times:1];
    //[textView selectAll:self];
    //range = [[textView selectedRanges] firstObject];
    //[self assert:0 equals:range.location];
    //[self assert:18 equals:range.length];
    // [delegateSpy verifyThatAllExpectationsHaveBeenMet];
    //
    //
    // [delegateSpy reset];
    // [delegateSpy selector:@selector(textView:willChangeSelectionFromCharacterRange:toCharacterRange:) times:1 arguments:[textView, CPMakeRange(0, 18), CPMakeRange(3, 6)]];
    // [delegateSpy selector:@selector(textViewDidChangeSelection:) times:1];
    //[textView setSelectedRange:CPMakeRange(3, 6)];
    //range = [[textView selectedRanges] firstObject];
    //[self assert:3 equals:range.location];
    //[self assert:6 equals:range.length];
    // [delegateSpy verifyThatAllExpectationsHaveBeenMet];
}

@end

@implementation CPTextViewTest (CPTextViewTestDelegate)

- (CPRange)textView:(CPTextView)aTextView willChangeSelectionFromCharacterRange:(CPRange)oldSelectedCharRange toCharacterRange:(CPRange)newSelectedCharRange
{
    return newSelectedCharRange;
}

- (void)textViewDidChangeSelection:(CPNotification)aNotification
{

}

@end