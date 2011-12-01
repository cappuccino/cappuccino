@import <Foundation/CPNotificationCenter.j>

@implementation CPNotificationCenterTest : OJTestCase
{
    int notificationCount;
}

- (void)testRemoveObserversDuringNotification
{
    var center = [CPNotificationCenter defaultCenter],
        TestNotification = @"TestNotification";

    notificationCount = 0;

    [center addObserver:self selector:@selector(receiveNotification:) name:TestNotification object:nil];
    [center addObserver:self selector:@selector(receiveNotification:) name:TestNotification object:nil];
    [center addObserver:self selector:@selector(receiveNotification:) name:TestNotification object:nil];

    [center postNotificationName:TestNotification object:self];

    [self assert:1 equals:notificationCount message:@"receiveFirstNotification s.b. called once"];
}

- (void)receiveNotification:(CPNotification)aNotification
{
    notificationCount += 1;

    var center = [CPNotificationCenter defaultCenter];
    [center removeObserver:self];
}

@end
