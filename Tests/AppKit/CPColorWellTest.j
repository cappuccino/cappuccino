@import <AppKit/CPColorWell.j>
@import <AppKit/CPApplication.j>

@implementation CPColorWellTest : OJTestCase
{
    CPColorWell colorWell;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    colorWell = [[CPColorWell alloc] initWithFrame:CGRectMakeZero()];
}

- (void)testCoding
{
    [self assertTrue:[colorWell isBordered] message:"color well bordered"];
    [self assert:[CPColor whiteColor] equals:[colorWell color] message:"color well default color"];

    [colorWell setColor:[CPColor greenColor]];
    [colorWell setBordered:NO];

    // Test archiving.
    var archived = [CPKeyedArchiver archivedDataWithRootObject:colorWell],
        unarchived = [CPKeyedUnarchiver unarchiveObjectWithData:archived];

    [self assertNotNull:unarchived];
    [self assertFalse:[unarchived isBordered] message:"color well archived bordered state"];
    [self assert:[CPColor greenColor] equals:[unarchived color] message:"color well archived color"];
}

- (void)testResponderChainChangeColor
{
    // Create a window and add the color well so it can become first responder
    var window = [[CPWindow alloc] initWithContentRect:CGRectMake(0,0,200,200) styleMask:CPBorderlessBridgeWindowMask],
        well = [[CPColorWell alloc] initWithFrame:CGRectMake(10,10,30,30)];

    [[window contentView] addSubview:well];
    [window makeKeyAndOrderFront:self];

    // Make the well first responder
    [[window makeFirstResponder:well]];

    // Prepare a fake sender that responds to -color
    var FakePanel = function(color) { this._color = color; };
    FakePanel.prototype.color = function() { return this._color; };

    var targetCalled = NO,
        target = {
            performAction:function(){ targetCalled = YES; }
        };

    [well setTarget:target];
    [well setAction:@selector(performAction)];

    var panel = new FakePanel([CPColor redColor]);

    // Send changeColor: via responder chain
    [CPApp sendAction:@selector(changeColor:) to:nil from:panel];

    [self assert:[[well color] equals:[CPColor redColor]] message:"well updated via responder chain"]; 
    [self assertTrue:targetCalled message:"target action sent from well after responder-chain update"]; 
}

- (void)testDropColorOnWell
{
    // Simulate a drop of a color onto the well
    var well = [[CPColorWell alloc] initWithFrame:CGRectMakeZero()];

    var targetCalled = NO,
        target = {
            performAction:function(){ targetCalled = YES; }
        };

    [well setTarget:target];
    [well setAction:@selector(performAction)];

    // Build a fake dragging info with a pasteboard carrying CPColorDragType
    var pasteboard = [CPPasteboard pasteboardWithName:CPDragPboard];
    [pasteboard declareTypes:[CPArray arrayWithObject:CPColorDragType] owner:nil];
    [pasteboard setData:[CPKeyedArchiver archivedDataWithRootObject:[CPColor blueColor]] forType:CPColorDragType];

    var draggingInfo = {
        draggingPasteboard:function(){ return pasteboard; },
        draggingLocation:function(){ return CGPointMake(0,0); }
    };

    var op = [well draggingEntered:draggingInfo];
    [self assertEquals:op CPDragOperationCopy message:"accepts color drag as copy operation"]; 

    var ok = [well performDragOperation:draggingInfo];
    [self assertTrue:ok message:"performed drop"]; 
    [self assert:[[well color] equals:[CPColor blueColor]] message:"color updated from drop"]; 
    [self assertTrue:targetCalled message:"target action sent after drop"]; 
}

@end

