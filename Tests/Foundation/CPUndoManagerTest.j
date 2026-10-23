
@import <Foundation/CPUndoManager.j>

@implementation CPUndoManagerTest : OJTestCase
{
    CPArray         receivedNotifications;
    CPUndoManager   undoManager;
    BOOL            itIsDone;
}

- (void)setUp
{
    undoManager = [[CPUndoManager alloc] init];
    itIsDone = NO;
    receivedNotifications = [CPMutableArray array];
}

- (void)testUndoMenuTitleForUndoActionName
{
    [self assert:[undoManager undoMenuTitleForUndoActionName:undefined] equals:@"Undo"];
    [self assert:[undoManager undoMenuTitleForUndoActionName:nil] equals:@"Undo"];
    [self assert:[undoManager undoMenuTitleForUndoActionName:""] equals:@"Undo"];

    [self assert:[undoManager undoMenuTitleForUndoActionName:0] equals:@"Undo 0"];
    [self assert:[undoManager undoMenuTitleForUndoActionName:"0"] equals:@"Undo 0"];

    [self assert:[undoManager undoMenuTitleForUndoActionName:"STRING"] equals:@"Undo STRING"];
}

- (void)testRedoMenuTitleForUndoActionName
{
    [self assert:[undoManager redoMenuTitleForUndoActionName:undefined] equals:@"Redo"];
    [self assert:[undoManager redoMenuTitleForUndoActionName:nil] equals:@"Redo"];
    [self assert:[undoManager redoMenuTitleForUndoActionName:""] equals:@"Redo"];

    [self assert:[undoManager redoMenuTitleForUndoActionName:0] equals:@"Redo 0"];
    [self assert:[undoManager redoMenuTitleForUndoActionName:"0"] equals:@"Redo 0"];

    [self assert:[undoManager redoMenuTitleForUndoActionName:"STRING"] equals:@"Redo STRING"];
}

- (void)testNotifications
{

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:)
                                                 name:CPUndoManagerDidCloseUndoGroupNotification
                                               object:undoManager];

    [self doIt];

    // The default run loop undo grouping won't be closed until the next run loop cycle.
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self assert:CPUndoManagerDidCloseUndoGroupNotification equals:[receivedNotifications[0] name]];

    [[CPNotificationCenter defaultCenter] removeObserver:self];
}

- (void)testUndoInSameRunLoopCycleAsChange
{
    [self doIt];

    // The change opened an event grouping that the run loop is scheduled to close. Undo closes it first.
    [undoManager undo];

    [self assertFalse:itIsDone message:@"undo should revert the change"];

    // The scheduled close must not run against the grouping that undo already closed.
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

    [self assert:0 equals:[undoManager groupingLevel]];
    [self assertTrue:[undoManager canRedo] message:@"the undone change should be available to redo"];

    [undoManager redo];

    [self assertTrue:itIsDone message:@"redo should reapply the change"];
}

- (void)receiveNotification:(CPNotification)aNotification
{
    [receivedNotifications addObject:aNotification];
}

- (void)doIt
{
    [undoManager registerUndoWithTarget:self
                               selector:@selector(undoIt)
                                 object:nil];

    itIsDone = YES;
}

- (void)undoIt
{
    [undoManager registerUndoWithTarget:self
                               selector:@selector(doIt)
                                 object:nil];

    itIsDone = NO;
}

@end
