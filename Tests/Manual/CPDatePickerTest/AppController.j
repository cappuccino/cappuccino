/*
 * AppController.j
 * CPDatePickerTest
 *
 * Created by You on March 15, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>



@implementation AppController : CPObject
{
    @outlet CPWindow        theWindow;

    @outlet CPDatePicker    pickerTarget;
    @outlet CPDatePicker    pickerMinDate;
    @outlet CPDatePicker    pickerMaxDate;
    @outlet CPDatePicker    pickerCurrentDate;
    @outlet CPPopUpButton   buttonStyle;
    @outlet CPPopUpButton   buttonElementsDate;
    @outlet CPPopUpButton   buttonElementsTime;
}

// - (void)awakeFromCib
// {
//     [theWindow setFullPlatformWindow:YES];
// }

- (IBAction)updateHasMinConstraint:(id)aSender
{
    [pickerMinDate setDateValue:[CPDate distantPast]];

    if ([aSender state] == CPOffState)
        [pickerMinDate setEnabled:NO];
    else
        [pickerMinDate setEnabled:YES];

}

- (IBAction)updateHasMaxConstraint:(id)aSender
{
    [pickerMaxDate setDateValue:[CPDate distantFuture]];

    if ([aSender state] == CPOffState)
        [pickerMaxDate setEnabled:NO];
    else
        [pickerMaxDate setEnabled:YES];
}

- (IBAction)updateElements:(id)aSender
{
    var elemDate = [[buttonElementsDate selectedItem] tag],
        elemTime = [[buttonElementsTime selectedItem] tag],
        mask;

    mask = 0x0;

    if (elemDate == 1)
        mask |= CPYearMonthDatePickerElementFlag;
    if (elemDate == 2)
        mask |= CPYearMonthDayDatePickerElementFlag;

    if (elemTime == 1)
        mask |= CPHourMinuteDatePickerElementFlag;
    if (elemTime == 2)
        mask |= CPHourMinuteSecondDatePickerElementFlag;

    [pickerTarget setDatePickerElements:mask];
}



@end
