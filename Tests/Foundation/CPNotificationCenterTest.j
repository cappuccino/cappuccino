@import <Foundation/CPNotificationCenter.j>

var TestNotification = @"TestNotification";

@implementation CPNotificationCenterTest : OJTestCase
{
    int notificationCount;
}

/*!
    Test various filter parameters.
*/
- (void)testNotify
{
    var center = [CPNotificationCenter defaultCenter];

    notificationCount = 0;

    [center addObserver:self selector:@selector(countNotification:) name:TestNotification object:2];
    [center addObserver:self selector:@selector(countNotification:) name:TestNotification object:25];
    [center postNotificationName:TestNotification object:self];
    [self assert:0 equals:notificationCount message:@"observer should only be notified for object '2'"];

    [center postNotificationName:TestNotification object:2];
    [self assert:1 equals:notificationCount message:@"observer should be notified for object '2'"];

    [center addObserver:self selector:@selector(countNotification:) name:TestNotification object:nil];
    [center postNotificationName:TestNotification object:2];
    [self assert:3 equals:notificationCount message:@"observer should be notified for object '2' and for any object"];

    [center removeObserver:self name:TestNotification object:2];
    [center postNotificationName:TestNotification object:2];
    [self assert:4 equals:notificationCount message:@"observer should be notified only for any object"];

    // At this point we have TestNofication:nil observer and a TestNotification:25 observer.
    [center addObserver:self selector:@selector(countNotification:) name:nil object:2];
    [center postNotificationName:TestNotification object:2];
    [self assert:6 equals:notificationCount message:@"observer should be notified for TestNofication and for object '2' (TestNotification)"];
    [center postNotificationName:@"RandomNotification" object:2];
    [self assert:7 equals:notificationCount message:@"observer should be notified for object '2' (RandomNotification)"];

    [center removeObserver:self name:TestNotification object:nil];
    [center postNotificationName:TestNotification object:nil];
    [center postNotificationName:TestNotification object:2];
    [center postNotificationName:TestNotification object:25];
    [self assert:8 equals:notificationCount message:@"observer should be notified only for object '2'"];

    [center removeObserver:self];
    [center postNotificationName:TestNotification object:nil];
    [center postNotificationName:TestNotification object:2];
    [center postNotificationName:TestNotification object:25];
    [self assert:8 equals:notificationCount message:@"observer should not be notified"];
}

- (void)testNotifyWithBlocks
{
    var center = [CPNotificationCenter defaultCenter];

    notificationCount = 0;

    var notificationBlock = function(notification){
        notificationCount += 1;
    };

    var observer2 = [center addObserverForName:TestNotification object:2 queue:nil usingBlock:notificationBlock],
        observer25 = [center addObserverForName:TestNotification object:25 queue:nil usingBlock:notificationBlock];

    [center postNotificationName:TestNotification object:self];
    [self assert:0 equals:notificationCount message:@"observer should only be notified for object '2'"];

    [center postNotificationName:TestNotification object:2];
    [self assert:1 equals:notificationCount message:@"observer should be notified for object '2'"];

    var observerNil = [center addObserverForName:TestNotification object:nil queue:nil usingBlock:notificationBlock];

    [center postNotificationName:TestNotification object:2];
    [self assert:3 equals:notificationCount message:@"observer should be notified for object '2' and for any object"];

    [center removeObserver:observer2 name:TestNotification object:2];
    [center postNotificationName:TestNotification object:2];
    [self assert:4 equals:notificationCount message:@"observer should be notified only for any object"];

    // At this point we have TestNofication:nil observer and a TestNotification:25 observer.
    observer2 = [center addObserverForName:nil object:2 queue:nil usingBlock:notificationBlock];

    [center postNotificationName:TestNotification object:2];
    [self assert:6 equals:notificationCount message:@"observer should be notified for TestNofication and for object '2' (TestNotification)"];
    [center postNotificationName:@"RandomNotification" object:2];
    [self assert:7 equals:notificationCount message:@"observer should be notified for object '2' (RandomNotification)"];

    [center removeObserver:observer2];
    [center removeObserver:observer25];
    [center removeObserver:observerNil];
    [center postNotificationName:TestNotification object:nil];
    [center postNotificationName:TestNotification object:2];
    [center postNotificationName:TestNotification object:25];
    [self assert:7 equals:notificationCount message:@"observer should not be notified"];
}

- (void)testAddObserversDuringNotification
{
    var center = [CPNotificationCenter defaultCenter];

    notificationCount = 0;

    [center addObserver:self selector:@selector(addObserversNotification:) name:TestNotification object:nil];

    [center postNotificationName:TestNotification object:self];

    [self assert:1 equals:notificationCount message:@"the new observers in addObserversNotification: should not be notified"];

    [center postNotificationName:TestNotification object:self];

    [self assert:5 equals:notificationCount message:@"the new observers from the first addObserversNotification should now be active"];
}

- (void)testRemoveObserversDuringNotification
{
    var center = [CPNotificationCenter defaultCenter];

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

- (void)addObserversNotification:(CPNotification)aNotification
{
    notificationCount += 1;

    var center = [CPNotificationCenter defaultCenter];
    // These should not be notified.
    [center addObserver:self selector:@selector(countNotification:) name:TestNotification object:nil];
    [center addObserver:self selector:@selector(countNotification:) name:TestNotification object:nil];
    [center addObserver:self selector:@selector(countNotification:) name:TestNotification object:nil];
}

- (void)countNotification:(CPNotification)aNotification
{
    notificationCount += 1;
}

@end
