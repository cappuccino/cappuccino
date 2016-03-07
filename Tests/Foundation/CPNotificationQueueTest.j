@import <Foundation/CPNotificationQueue.j>

var TestNotification = @"TestNotification";

@implementation CPNotificationQueueTest : OJTestCase
{
    int notificationCount;
}

- (void)setUp
{
    notificationCount = 0;
}

/*!
    Test ceation
*/
- (void)testCreate
{
    var queue = [CPNotificationQueue defaultQueue];
    [self assert:queue._notificationCenter equals:[CPNotificationCenter defaultCenter]];

    var notificationCenter = [CPNotificationCenter new],
        secondQueue = [[CPNotificationQueue alloc] initWithNotificationCenter:notificationCenter];
    [self assert:secondQueue._notificationCenter equals:notificationCenter];
}

- (void)testNotificationPostNow
{
    var queue = [CPNotificationQueue defaultQueue],
        notification = [[CPNotification alloc] initWithName:@"TestNotification" object:self userInfo:nil];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(countNotification:) name:@"TestNotification" object:self];
    [queue enqueueNotification:notification postingStyle:CPPostNow];
    [self assert:notificationCount equals:1];

    [queue enqueueNotification:notification postingStyle:CPPostNow];
    [self assert:notificationCount equals:2];

    [queue enqueueNotification:notification postingStyle:CPPostASAP];
    [queue enqueueNotification:notification postingStyle:CPPostWhenIdle];
    [queue enqueueNotification:notification postingStyle:CPPostNow];
    [self assert:notificationCount equals:3];

    [queue enqueueNotification:notification postingStyle:CPPostNow];
    [queue enqueueNotification:notification postingStyle:CPPostNow];
    [self assert:notificationCount equals:5];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assert:notificationCount equals:5];
}

- (void)testNotificationPostASAP
{
    var queue = [CPNotificationQueue defaultQueue],
        notification = [[CPNotification alloc] initWithName:@"TestNotification" object:self userInfo:nil],
        notification2 = [[CPNotification alloc] initWithName:@"TestNotification" object:self userInfo:@{}];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(countNotification:) name:@"TestNotification" object:self];
    [queue enqueueNotification:notification postingStyle:CPPostASAP];
    [self assert:notificationCount equals:0];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assert:notificationCount equals:1];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assert:notificationCount equals:1];

    [queue enqueueNotification:notification postingStyle:CPPostASAP];
    [queue enqueueNotification:notification postingStyle:CPPostASAP];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assert:notificationCount equals:2];

    [queue enqueueNotification:notification postingStyle:CPPostASAP];
    [queue enqueueNotification:notification2 postingStyle:CPPostASAP coalesceMask:CPNotificationNoCoalescing forModes:nil];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assert:notificationCount equals:4];

    [queue enqueueNotification:notification postingStyle:CPPostASAP];
    [queue enqueueNotification:notification2 postingStyle:CPPostASAP coalesceMask:CPNotificationNoCoalescing forModes:nil];
    [queue dequeueNotificationsMatching:notification2 coalesceMask:CPNotificationNoCoalescing];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assert:notificationCount equals:5];

    [queue enqueueNotification:notification postingStyle:CPPostASAP];
    [queue enqueueNotification:notification2 postingStyle:CPPostASAP coalesceMask:CPNotificationNoCoalescing forModes:nil];
    [queue dequeueNotificationsMatching:notification coalesceMask:CPNotificationCoalescingOnName];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assert:notificationCount equals:5];

    [queue enqueueNotification:notification postingStyle:CPPostASAP];
    [queue enqueueNotification:notification2 postingStyle:CPPostASAP coalesceMask:CPNotificationNoCoalescing forModes:nil];
    [queue dequeueNotificationsMatching:notification coalesceMask:CPNotificationCoalescingOnSender];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assert:notificationCount equals:5];
}

- (void)testNotificationWhenIdle
{
    var queue = [CPNotificationQueue defaultQueue],
        notification = [[CPNotification alloc] initWithName:@"TestNotification" object:self userInfo:nil],
        notification2 = [[CPNotification alloc] initWithName:@"TestNotificationIdle" object:self userInfo:@{}];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(countNotification:) name:@"TestNotification" object:self];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(countNotificationIdle:) name:@"TestNotificationIdle" object:self];

    [queue enqueueNotification:notification postingStyle:CPPostASAP];
    [queue enqueueNotification:notification2 postingStyle:CPPostWhenIdle];
    [self assert:notificationCount equals:0];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assert:notificationCount equals:1];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    [self assert:notificationCount equals:2];
}

- (void)countNotification:(CPNotification)aNotification
{
    notificationCount++;
}

- (void)countNotificationIdle:(CPNotification)aNotification
{
    notificationCount++;
}

@end