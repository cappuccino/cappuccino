
@import <AppKit/CPDatePicker.j>
@import <AppKit/CPApplication.j>
@import <AppKit/CPText.j>

[CPApplication sharedApplication];

@implementation CPDatePickerTest : OJTestCase
{
    CPDatePicker datePicker;
}

- (void)setUp
{
    datePicker = [[CPDatePicker alloc] initWithFrame:CGRectMake(200, 28, 0, 0)];
}

- (void)testCanCreate
{
    [self assertTrue:!!datePicker];
}

@end
