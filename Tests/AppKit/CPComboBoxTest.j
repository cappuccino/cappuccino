@import <AppKit/CPComboBox.j>
@import <AppKit/CPApplication.j>
@import <Foundation/Foundation.j>

@import "CPNotificationCenterHelper.j"

[CPApplication sharedApplication];

@implementation CPComboBoxTest : OJTestCase
{
    CPComboBox comboBox;
    BOOL       wasClicked
}

- (void)setUp
{
    comboBox = [[CPComboBox alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
}

- (void)testCanCreate
{
    [self assertTrue:!!comboBox];
}

- (void)testPublicAccessors
{
    [comboBox setHasVerticalScroller:YES];
    [comboBox setIntercellSpacing:CGSizeMakeZero()];
    [comboBox setButtonBordered:YES];
    [comboBox setItemHeight:30];
    [comboBox setNumberOfVisibleItems:10];
}

- (void)testPerformClick
{
    [comboBox setTarget:self];
    [comboBox setAction:@selector(clickMe:)];
    [comboBox performClick:nil];
    [self assertTrue:wasClicked];
}

- (void)clickMe:(id)sender
{
    wasClicked = YES;
}

- (void)testNotificationsRegistered
{
    [self assert:[CPNotificationCenterHelper registeredNotificationsForObserver:comboBox] equals:[] message:@"Notications registered for the CPComboBox in the notification center are wrong"];
    [comboBox setListDelegate:[[_CPPopUpList alloc] initWithDataSource:comboBox]];
    [self assert:[CPNotificationCenterHelper registeredNotificationsForObserver:comboBox] equals:[] message:@"Notications registered for the CPComboBox in the notification center are wrong"];

    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, 1024.0, 768.0)
                                        styleMask:CPWindowNotSizable];

    [[theWindow contentView] addSubview:comboBox];

    var expectedNotifications = [@"_CPPopUpListWillPopUpNotification", @"_CPPopUpListWillDismissNotification", @"_CPPopUpListDidDismissNotification", @"_CPPopUpListItemWasClickedNotification", @"CPTableViewSelectionIsChangingNotification", @"CPTableViewSelectionDidChangeNotification"].sort();

    [self assert:[CPNotificationCenterHelper registeredNotificationsForObserver:comboBox] equals:expectedNotifications message:@"Notications registered for the CPComboBox in the notification center are wrong"];

    [comboBox removeFromSuperview];
    [self assert:[CPNotificationCenterHelper registeredNotificationsForObserver:comboBox] equals:[] message:@"Notications registered for the CPComboBox in the notification center are wrong"];

    [[theWindow contentView] addSubview:comboBox];
    [self assert:[CPNotificationCenterHelper registeredNotificationsForObserver:comboBox] equals:expectedNotifications message:@"Notications registered for the CPComboBox in the notification center are wrong"];

    [[theWindow contentView] addSubview:comboBox];
    [self assert:[CPNotificationCenterHelper registeredNotificationsForObserver:comboBox] equals:expectedNotifications message:@"Notications registered for the CPComboBox in the notification center are wrong"];

    [comboBox setListDelegate:nil];
    [self assert:[CPNotificationCenterHelper registeredNotificationsForObserver:comboBox] equals:[] message:@"Notications registered for the CPComboBox in the notification center are wrong"];

    [comboBox setListDelegate:[[_CPPopUpList alloc] initWithDataSource:comboBox]];
    [self assert:[CPNotificationCenterHelper registeredNotificationsForObserver:comboBox] equals:expectedNotifications message:@"Notications registered for the CPComboBox in the notification center are wrong"];
}

@end