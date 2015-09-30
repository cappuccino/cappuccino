@import <OJUnit/OJTestCase.j>

@import <AppKit/CPDatePicker.j>
@import <AppKit/CPApplication.j>
@import <Foundation/Foundation.j>


@implementation CPDatePickerTest : OJTestCase
{
    CPDatePicker datePicker;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    datePicker = [[CPDatePicker alloc] initWithFrame:CGRectMake(200, 28, 0, 0)];
}

- (void)testCanCreate
{
    [self assertTrue:!!datePicker];
}

- (void)testLayoutSubviews
{
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

@end
