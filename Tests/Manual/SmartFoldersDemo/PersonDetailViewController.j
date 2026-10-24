/*
 * PersonDetailViewController.j
 * SmartFoldersDemo
 *
 * Detail pane below the people table. Every control is bound to
 * arrayController.selection.<key>, which exercises CPControllerSelectionProxy,
 * placeholder binding options (no selection / multiple values / null) and a
 * read-only binding to a KVO-dependent derived key ("age").
 *
 * Controls covered: CPTextField (+formatter), CPComboBox, CPPopUpButton
 * (selectedValue binding), CPDatePicker, CPCheckBox, CPBox.
 */

@import <AppKit/AppKit.j>
@import "Library.j"

// Layout grid. Every row is RowHeight tall; labels and controls are centred on
// the row's midline regardless of each control's intrinsic height.
var RowHeight       = 30.0,
    RowPitch        = 36.0,
    LabelWidth      = 90.0,
    LabelGap        = 8.0,
    FieldWidth      = 230.0,
    ColumnGap       = 40.0,
    TextFieldHeight = 29.0,
    PopUpHeight     = 25.0,
    DatePickerHeight= 25.0;

PersonDetailPreferredHeight = 5 * RowPitch + 52.0;

@implementation PersonDetailViewController : CPViewController
{
    CPArrayController   _arrayController;
}

- (id)initWithArrayController:(CPArrayController)anArrayController
{
    if (self = [super initWithCibName:nil bundle:nil])
        _arrayController = anArrayController;

    return self;
}

- (CPDictionary)_placeholderOptions
{
    return [CPDictionary dictionaryWithObjectsAndKeys:
        @"No Selection", CPNoSelectionPlaceholderBindingOption,
        @"Multiple Values", CPMultipleValuesPlaceholderBindingOption,
        @"", CPNullPlaceholderBindingOption];
}

- (void)loadView
{
    var frame = CGRectMake(0, 0, 800, PersonDetailPreferredHeight),
        view = [[CPView alloc] initWithFrame:frame];

    [view setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [view setBackgroundColor:[CPColor colorWithWhite:0.96 alpha:1.0]];

    var box = [[CPBox alloc] initWithFrame:CGRectInset(frame, 12, 8)];
    [box setTitle:@"Selected Person"];
    [box setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [view addSubview:box];

    var content = [box contentView],
        options = [self _placeholderOptions],
        left = 12.0,
        right = left + LabelWidth + LabelGap + FieldWidth + ColumnGap;

    // ---- Left column
    [[self _textFieldInRow:0 column:left label:@"First Name:" in:content]
        bind:CPValueBinding toObject:_arrayController withKeyPath:@"selection.firstName" options:options];

    [[self _textFieldInRow:1 column:left label:@"Last Name:" in:content]
        bind:CPValueBinding toObject:_arrayController withKeyPath:@"selection.lastName" options:options];

    [[self _textFieldInRow:2 column:left label:@"Email:" in:content]
        bind:CPValueBinding toObject:_arrayController withKeyPath:@"selection.email" options:options];

    [self _labelInRow:3 column:left title:@"Department:" in:content];
    var department = [[CPPopUpButton alloc] initWithFrame:CGRectMakeZero() pullsDown:NO];
    [department addItemsWithTitles:LibraryDepartments];
    [self _place:department row:3 x:left + LabelWidth + LabelGap width:FieldWidth height:PopUpHeight in:content];
    [department bind:CPSelectedValueBinding toObject:_arrayController withKeyPath:@"selection.department" options:nil];

    var manager = [CPCheckBox checkBoxWithTitle:@"Manager"];
    [manager setAllowsMixedState:YES];
    [manager sizeToFit];
    [self _place:manager row:4 x:left + LabelWidth + LabelGap width:CGRectGetWidth([manager frame]) height:CGRectGetHeight([manager frame]) in:content];
    [manager bind:CPValueBinding toObject:_arrayController withKeyPath:@"selection.isManager" options:nil];

    // ---- Right column
    [self _labelInRow:0 column:right title:@"City:" in:content];
    var city = [[CPComboBox alloc] initWithFrame:CGRectMakeZero()];
    [city addItemsWithObjectValues:LibraryCities];
    [city setEditable:YES];
    [self _place:city row:0 x:right + LabelWidth + LabelGap width:FieldWidth height:TextFieldHeight in:content];
    [city bind:CPValueBinding toObject:_arrayController withKeyPath:@"selection.city" options:options];

    [self _labelInRow:1 column:right title:@"Birth Date:" in:content];
    var birthDate = [[CPDatePicker alloc] initWithFrame:CGRectMake(0, 0, 140, DatePickerHeight)];
    [birthDate setDatePickerStyle:CPTextFieldAndStepperDatePickerStyle];
    [birthDate setDatePickerElements:CPYearMonthDayDatePickerElementFlag];
    [self _place:birthDate row:1 x:right + LabelWidth + LabelGap width:140 height:CGRectGetHeight([birthDate frame]) in:content];
    [birthDate bind:CPValueBinding toObject:_arrayController withKeyPath:@"selection.birthDate" options:nil];

    [self _labelInRow:2 column:right title:@"Age:" in:content];
    var age = [self _valueLabelInRow:2 x:right + LabelWidth + LabelGap in:content];
    [age bind:CPValueBinding toObject:_arrayController withKeyPath:@"selection.age" options:options];

    var salary = [self _textFieldInRow:3 column:right label:@"Salary:" in:content],
        numberFormatter = [[CPNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:CPNumberFormatterDecimalStyle];
    [salary setFormatter:numberFormatter];
    [salary setAlignment:CPRightTextAlignment];
    [salary setFrameSize:CGSizeMake(140, CGRectGetHeight([salary frame]))];
    [salary bind:CPValueBinding toObject:_arrayController withKeyPath:@"selection.salary" options:options];

    [self _labelInRow:4 column:right title:@"Record ID:" in:content];
    var uid = [self _valueLabelInRow:4 x:right + LabelWidth + LabelGap in:content];
    [uid setSelectable:YES];
    [uid setTextColor:[CPColor grayColor]];
    [uid bind:CPValueBinding toObject:_arrayController withKeyPath:@"selection.uid" options:options];

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

- (CPTextField)_labelInRow:(int)aRow column:(float)anX title:(CPString)aTitle in:(CPView)aSuperview
{
    var label = [CPTextField labelWithTitle:aTitle];

    [label setAlignment:CPRightTextAlignment];
    [label setVerticalAlignment:CPCenterVerticalTextAlignment];
    [label setTextColor:[CPColor colorWithWhite:0.25 alpha:1.0]];
    [self _place:label row:aRow x:anX width:LabelWidth height:RowHeight in:aSuperview];

    return label;
}

- (CPTextField)_valueLabelInRow:(int)aRow x:(float)anX in:(CPView)aSuperview
{
    var label = [CPTextField labelWithTitle:@""];

    [label setVerticalAlignment:CPCenterVerticalTextAlignment];
    [self _place:label row:aRow x:anX + 4 width:FieldWidth - 4 height:RowHeight in:aSuperview];

    return label;
}

- (CPTextField)_textFieldInRow:(int)aRow column:(float)anX label:(CPString)aTitle in:(CPView)aSuperview
{
    [self _labelInRow:aRow column:anX title:aTitle in:aSuperview];

    var field = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];

    [field setEditable:YES];
    [field setBezeled:YES];
    [field setVerticalAlignment:CPCenterVerticalTextAlignment];
    [self _place:field row:aRow x:anX + LabelWidth + LabelGap width:FieldWidth height:TextFieldHeight in:aSuperview];

    return field;
}

@end
