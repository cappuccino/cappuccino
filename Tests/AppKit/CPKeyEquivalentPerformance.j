@import <AppKit/CPApplication.j>
@import <AppKit/CPWindow.j>
@import <AppKit/CPEvent.j>
@import <AppKit/CPButton.j>

[CPApplication sharedApplication];

@implementation CPKeyEquivalentPerformance : OJTestCase

- (void)testKeyEquivalentSpeed
{
    var REPEATS = 1000,
        theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0,0,200,150)
                                                styleMask:CPWindowNotSizable],
        contentView = [theWindow contentView],
        subView1 = [[CPView alloc] initWithFrame:CGRectMakeZero()],
        subView2 = [[CPView alloc] initWithFrame:CGRectMakeZero()],
        button1 = [CPButton buttonWithTitle:"when"],
        button2 = [CPButton buttonWithTitle:"you have eliminated"],
        button3 = [CPButton buttonWithTitle:"the impossible"];

    [contentView addSubview:subView1];
    [contentView addSubview:subView2];
    [subView1 addSubview:button1];
    [subView2 addSubview:button2];
    [subView2 addSubview:button3];

    [button1 setTarget:self];
    [button1 setAction:@selector(clicked:)];
    [button1 setKeyEquivalent:"a"];
    [button1 setKeyEquivalentModifierMask:CPControlKeyMask];
    button1.clicks = 0;

    [button2 setTarget:self];
    [button2 setAction:@selector(clicked:)];
    [button2 setKeyEquivalent:"a"];
    [button2 setKeyEquivalentModifierMask:CPAlternateKeyMask | CPCommandKeyMask];
    button2.clicks = 0;

    [button3 setTarget:self];
    [button3 setAction:@selector(clicked:)];
    [button3 setKeyEquivalent:"A"];
    [button3 setKeyEquivalentModifierMask:CPControlKeyMask];
    button3.clicks = 0;

    var start = (new Date).getTime();

    for (var i = 0; i < REPEATS; i++)
    {
        [theWindow sendEvent:[CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:CPControlKeyMask
            timestamp:0 windowNumber:0 context:nil
            characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0]];
        [theWindow sendEvent:[CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:CPAlternateKeyMask | CPCommandKeyMask
            timestamp:0 windowNumber:0 context:nil
            characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0]];
        [theWindow sendEvent:[CPEvent keyEventWithType:CPKeyDown location:CGPointMakeZero() modifierFlags:CPControlKeyMask | CPShiftKeyMask
            timestamp:0 windowNumber:0 context:nil
            characters:"a" charactersIgnoringModifiers:"a" isARepeat:NO keyCode:0]];
    }

    var end = (new Date).getTime();

    [self assert:REPEATS equals:button1.clicks message:"button1"];
    [self assert:REPEATS equals:button2.clicks message:"button2"];
    [self assert:REPEATS equals:button3.clicks message:"button3"];

    CPLog.warn("testKeyEquivalentSpeed: "+(end-start)+"ms");

}

- (void)clicked:(id)sender
{
    sender.clicks++;
}

@end
