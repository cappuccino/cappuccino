/*
 * PersonDetailViewController.j
 * People
 *
 * Detail pane, the third column of the main window. It shows the person in its
 * representedObject, which the main split view controller binds to the selection of the people
 * table. Every control is bound to representedObject.<key>, which exercises
 * CPControllerSelectionProxy through a view controller, placeholder binding options (no
 * selection / multiple values / null) and a read-only binding to a KVO-dependent derived key
 * ("age").
 *
 * Controls covered: CPTextField (+formatter), CPComboBox, CPPopUpButton
 * (selectedValue binding), CPDatePicker, CPCheckBox, CPBox.
 */

@import <AppKit/AppKit.j>
@import "../Library.j"

// Layout grid. Every row is RowHeight tall; labels and controls are centred on
// the row's midline regardless of each control's intrinsic height.
var RowHeight       = 30.0,
    RowPitch        = 36.0,
    RowCount        = 10,
    Margin          = 12.0,
    LabelWidth      = 90.0,
    LabelGap        = 8.0,
    FieldWidth      = 230.0,
    ShortFieldWidth = 140.0,
    TextFieldHeight = 29.0,
    PopUpHeight     = 25.0,
    DatePickerHeight= 25.0,
    BoxHeight       = RowCount * RowPitch + 40.0;

/*
    The width the pane takes at first and after a reset, and the narrowest it can become. The
    fields take the width between the two.
*/
PersonDetailPreferredWidth  = 2 * Margin + LabelWidth + LabelGap + FieldWidth + 2 * Margin + 8.0;
PersonDetailMinimumWidth    = PersonDetailPreferredWidth - FieldWidth + ShortFieldWidth;

@implementation PersonDetailViewController : CPViewController
{
}

- (id)init
{
    return [super initWithCibName:nil bundle:nil];
}

- (CPDictionary)_placeholderOptions
{
    return [CPDictionary dictionaryWithObjectsAndKeys:
        @"No Selection", CPNoSelectionPlaceholderBindingOption,
        @"Multiple Values", CPMultipleValuesPlaceholderBindingOption,
        @"", CPNullPlaceholderBindingOption];
}

- (void)_bind:(CPView)aControl binding:(CPString)aBinding key:(CPString)aKey options:(CPDictionary)options
{
    [aControl bind:aBinding toObject:self withKeyPath:@"representedObject." + aKey options:options];
}

- (void)loadView
{
    var frame = CGRectMake(0, 0, PersonDetailPreferredWidth, BoxHeight + 2 * 8.0),
        view = [[CPView alloc] initWithFrame:frame];

    [view setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    var box = [[CPBox alloc] initWithFrame:CGRectMake(Margin, 8.0, CGRectGetWidth(frame) - 2 * Margin, BoxHeight)];
    [box setTitle:@"Selected Person"];
    [box setAutoresizingMask:CPViewWidthSizable | CPViewMaxYMargin];
    [view addSubview:box];

    var content = [box contentView],
        options = [self _placeholderOptions],
        x = Margin,
        fieldX = x + LabelWidth + LabelGap,
        row = 0;

    [self _bind:[self _textFieldInRow:row++ label:@"First Name:" in:content] binding:CPValueBinding key:@"firstName" options:options];
    [self _bind:[self _textFieldInRow:row++ label:@"Last Name:" in:content] binding:CPValueBinding key:@"lastName" options:options];
    [self _bind:[self _textFieldInRow:row++ label:@"Email:" in:content] binding:CPValueBinding key:@"email" options:options];

    [self _labelInRow:row title:@"Department:" in:content];
    var department = [[CPPopUpButton alloc] initWithFrame:CGRectMakeZero() pullsDown:NO];
    [department addItemsWithTitles:LibraryDepartments];
    [self _place:department row:row++ x:fieldX width:FieldWidth height:PopUpHeight in:content];
    [department setAutoresizingMask:CPViewWidthSizable];
    [self _bind:department binding:CPSelectedValueBinding key:@"department" options:nil];

    var manager = [CPCheckBox checkBoxWithTitle:@"Manager"];
    [manager setAllowsMixedState:YES];
    [manager sizeToFit];
    [self _place:manager row:row++ x:fieldX width:CGRectGetWidth([manager frame]) height:CGRectGetHeight([manager frame]) in:content];
    [self _bind:manager binding:CPValueBinding key:@"isManager" options:nil];

    [self _labelInRow:row title:@"City:" in:content];
    var city = [[CPComboBox alloc] initWithFrame:CGRectMakeZero()];
    [city addItemsWithObjectValues:LibraryCities];
    [city setEditable:YES];
    [self _place:city row:row++ x:fieldX width:FieldWidth height:TextFieldHeight in:content];
    [city setAutoresizingMask:CPViewWidthSizable];
    [self _bind:city binding:CPValueBinding key:@"city" options:options];

    [self _labelInRow:row title:@"Birth Date:" in:content];
    var birthDate = [[CPDatePicker alloc] initWithFrame:CGRectMake(0, 0, ShortFieldWidth, DatePickerHeight)];
    [birthDate setDatePickerStyle:CPTextFieldAndStepperDatePickerStyle];
    [birthDate setDatePickerElements:CPYearMonthDayDatePickerElementFlag];
    [self _place:birthDate row:row++ x:fieldX width:ShortFieldWidth height:CGRectGetHeight([birthDate frame]) in:content];
    [self _bind:birthDate binding:CPValueBinding key:@"birthDate" options:nil];

    [self _labelInRow:row title:@"Age:" in:content];
    [self _bind:[self _valueLabelInRow:row++ in:content] binding:CPValueBinding key:@"age" options:options];

    var salary = [self _textFieldInRow:row++ label:@"Salary:" in:content],
        numberFormatter = [[CPNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:CPNumberFormatterDecimalStyle];
    [salary setFormatter:numberFormatter];
    [salary setAlignment:CPRightTextAlignment];
    [salary setFrameSize:CGSizeMake(ShortFieldWidth, CGRectGetHeight([salary frame]))];
    [salary setAutoresizingMask:CPViewNotSizable];
    [self _bind:salary binding:CPValueBinding key:@"salary" options:options];

    [self _labelInRow:row title:@"Record ID:" in:content];
    var uid = [self _valueLabelInRow:row++ in:content];
    [uid setSelectable:YES];
    [uid setTextColor:[CPColor secondaryLabelColor]];
    [self _bind:uid binding:CPValueBinding key:@"uid" options:options];

    [self setView:view];
}

// ---------------------------------------------------------------- Layout helpers

- (float)_rowTop:(int)aRow
{
    return 10.0 + aRow * RowPitch;
}

// Centres aView vertically on the row's midline.
- (void)_place:(CPView)aView row:(int)aRow x:(float)anX width:(float)aWidth height:(float)aHeight in:(CPView)aSuperview
{
    var y = [self _rowTop:aRow] + Math.round((RowHeight - aHeight) / 2);

    [aView setFrame:CGRectMake(anX, y, aWidth, aHeight)];
    [aSuperview addSubview:aView];
}

- (CPTextField)_labelInRow:(int)aRow title:(CPString)aTitle in:(CPView)aSuperview
{
    var label = [CPTextField labelWithTitle:aTitle];

    [label setAlignment:CPRightTextAlignment];
    [label setVerticalAlignment:CPCenterVerticalTextAlignment];
    [self _place:label row:aRow x:Margin width:LabelWidth height:RowHeight in:aSuperview];

    return label;
}

- (CPTextField)_valueLabelInRow:(int)aRow in:(CPView)aSuperview
{
    var label = [CPTextField labelWithTitle:@""];

    [label setVerticalAlignment:CPCenterVerticalTextAlignment];
    [self _place:label row:aRow x:Margin + LabelWidth + LabelGap + 4 width:FieldWidth - 4 height:RowHeight in:aSuperview];
    [label setAutoresizingMask:CPViewWidthSizable];

    return label;
}

- (CPTextField)_textFieldInRow:(int)aRow label:(CPString)aTitle in:(CPView)aSuperview
{
    [self _labelInRow:aRow title:aTitle in:aSuperview];

    var field = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

    [field setEditable:YES];
    [field setBezeled:YES];
    [field setVerticalAlignment:CPCenterVerticalTextAlignment];
    [self _place:field row:aRow x:Margin + LabelWidth + LabelGap width:FieldWidth height:TextFieldHeight in:aSuperview];
    [field setAutoresizingMask:CPViewWidthSizable];

    return field;
}

@end
