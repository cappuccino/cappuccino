@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

[CPApplication sharedApplication];


@implementation CPAutosizePerformance : OJTestCase
{
    CPInteger NUMBER_OF_VIEWS;
    CPInteger RESIZES_COUNT;
}

- (void)setUp
{
    NUMBER_OF_VIEWS = 50;
    RESIZES_COUNT = 250;
}

- (void)testAutosizePerf
{
    var dur = 0,
        masks = [0, 1, 2, 3, 4, 5, 6, 7, 8];

    for (var i = 0; i < 64; i++)
        dur += [self _testAutosizePerfWithMask:i];

    CPLog.warn(dur + " ms when autosizing " + RESIZES_COUNT + " times a window with " + NUMBER_OF_VIEWS + " views, using masks " + masks);
}

- (CPInteger)_testAutosizePerfWithMask:(CPInteger)aMask
{
    var windowRect = CGRectMake(0, 0, 500, 500),
        _autoSizeWindow = [[CPWindow alloc] initWithContentRect:windowRect styleMask:CPResizableWindowMask];

    for (var i = 0; i < NUMBER_OF_VIEWS; i++)
    {
        var x = (i % 10) * 50,
            y = FLOOR(i / 10) * 50,
            rect = CGRectMake(x, y, 50, 50);

        var autosizeView = [[CPView alloc] initWithFrame:rect];
        [autosizeView setAutoresizingMask:aMask];
        [[_autoSizeWindow contentView] addSubview:autosizeView];
    }

    [_autoSizeWindow setFrame:CGRectMake(0, 0, 600, 600)];

    var start = new Date();

    for (var k = 1; k <= RESIZES_COUNT; k++)
    {
        var size = 600 + k;
        [_autoSizeWindow setFrame:CGRectMake(0, 0, size, size)];
    }

    var total = new Date() - start;

    //CPLog.warn("AutosizingMask " + aMask + " -setFrame: avg=" + (total/ RESIZES_COUNT) + " ms. Total = " + total + " ms.");

    return total;
}

@end
