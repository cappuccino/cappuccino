
@import <Foundation/CPUndoManager.j>

@implementation CPUndoManagerTest : OJTestCase
{
    CPUndoManager undoManager;
}

- (void)setUp
{
    undoManager = [[CPUndoManager alloc] init];
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

@end
