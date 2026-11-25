/*
 * PersonDetailViewController.j
 * People
 *
 *
 * Created by David Richardson.
 * Copyright 2026, The Cappuccino Project.
 *
 *
 * Detail pane, the third column of the main window. It shows the person in its
 * representedObject, which the main split view controller binds to the selection of the people
 * table. Every control is bound to representedObject.<key>, which exercises
 * CPControllerSelectionProxy through a view controller, placeholder binding options (no
 * selection / multiple values / null) and a read-only binding to a KVO-dependent derived key
 * ("age").
 *
 * Controls covered: CPTextField (+formatter), CPComboBox, CPPopUpButton
 * (selectedValue binding), CPDatePicker, CPCheckBox, CPScrollView, CPTextView (rich text,
 * attributedString binding), and CPBox in its custom
 * type (an undrawn section container) and its separator type, CPButton in its disclosure
 * bezel style, and CPButtonBar with a toggle button.
 *
 * The pane has one flat background, the under-page background colour, which matches the source
 * list. Its fields are grouped in sections. Each section has a header with a disclosure triangle
 * and a title, and a separator line divides the sections. The sections are stacked by frame in
 * -_layoutSections, which places each visible section below the one before it; the scroll view
 * scrolls them when the pane is too short.
 *
 * A button bar at the bottom matches the bars of the other two panes. Its Edit button sets the
 * library's edit mode ("editable"), which the people table follows too. In view mode the text
 * fields are plain selectable text without a bezel, and the other controls are disabled; in
 * edit mode the text fields are bezeled and editable, and the other controls are enabled. The
 * text fields bind their editable state, and the other controls their enabled state, to
 * library.editable. The bezel is not a binding, so the controller observes the key and sets it.
 *
 * The Notes section holds a rich text CPTextView in a scroll view, bound to the person's notes
 * with the attributedString binding. The binding updates the person as the text changes, so
 * the table's notes icon follows the typing. CPTextView has no editable binding, so the
 * controller sets its editable state, and the scroll view's border, when the mode changes.
 */

@import <AppKit/AppKit.j>
@import "../Library.j"
@import "../MaskImage.j"

/*
    Layout grid. Every row is RowHeight tall and RowPitch apart; labels and controls are centred
    on the row's midline regardless of each control's intrinsic height.
*/
var RowHeight           = 30.0,
    RowPitch            = 36.0,
    Margin              = 12.0,
    LabelWidth          = 90.0,
    LabelGap            = 8.0,
    FieldWidth          = 230.0,
    ShortFieldWidth     = 140.0,
    TextFieldHeight     = 29.0,
    PopUpHeight         = 25.0,
    DatePickerHeight    = 25.0,
    HeaderHeight        = 24.0,
    DisclosureSize      = 13.0,
    SeparatorGap        = 12.0,
    SeparatorHeight     = 5.0,
    BarHeight           = 26.0,
    NotesRowCount       = 4;

/*
    The Edit button's images: a pencil in view mode and a check mark in edit mode, 16 by 16, as
    masks in the style of the Aristo3 button bar icons.
      pencil: <path d="M11.5 1.5l3 3L5 14H2v-3z"/>
      check:  <path d="M3 8.5l3.5 3.5L13 4.5" stroke-width="2" stroke="black" fill="none"/>
*/
var EditMask    = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNiAxNiI+PHBhdGggZD0iTTExLjUgMS41bDMgM0w1IDE0SDJ2LTN6Ii8+PC9zdmc+')",
    DoneMask    = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNiAxNiI+PHBhdGggZD0iTTMgOC41bDMuNSAzLjVMMTMgNC41IiBzdHJva2Utd2lkdGg9IjIiIHN0cm9rZT0iYmxhY2siIGZpbGw9Im5vbmUiLz48L3N2Zz4=')";

/*
    The width the pane takes at first and after a reset, and the narrowest it can become. The
    fields take the width between the two.
*/
PersonDetailPreferredWidth  = 2 * Margin + LabelWidth + LabelGap + FieldWidth + 2 * Margin + 8.0;
PersonDetailMinimumWidth    = PersonDetailPreferredWidth - FieldWidth + ShortFieldWidth;

@implementation PersonDetailViewController : CPViewController
{
    CPView      _documentView;
    CPArray     _sections;
    CPArray     _textFields;
    CPButton    _editButton;
    Library     _library;
    CPTextView  _notesView;
    CPScrollView _notesScrollView;
}

- (id)initWithLibrary:(Library)aLibrary
{
    if (self = [super initWithCibName:nil bundle:nil])
    {
        _library = aLibrary;
        [_library addObserver:self forKeyPath:@"editable" options:0 context:nil];
    }

    return self;
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
    var frame = CGRectMake(0, 0, PersonDetailPreferredWidth, 10 * RowPitch + 3 * HeaderHeight),
        view = [[CPView alloc] initWithFrame:frame];

    [view setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [view setBackgroundColor:[CPColor underPageBackgroundColor]];

    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame) - BarHeight)];

    [scrollView setBorderType:CPNoBorder];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [view addSubview:scrollView];

    _documentView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), 0)];
    [_documentView setAutoresizingMask:CPViewWidthSizable];
    [scrollView setDocumentView:_documentView];

    _sections = [];
    _textFields = [];

    var options = [self _placeholderOptions],
        fieldX = Margin + LabelWidth + LabelGap,
        content = [self _addSectionWithTitle:@"Name" rowCount:3],
        row = 0;

    [self _bind:[self _textFieldInRow:row++ label:@"First Name:" in:content] binding:CPValueBinding key:@"firstName" options:options];
    [self _bind:[self _textFieldInRow:row++ label:@"Last Name:" in:content] binding:CPValueBinding key:@"lastName" options:options];
    [self _bind:[self _textFieldInRow:row++ label:@"Email:" in:content] binding:CPValueBinding key:@"email" options:options];

    content = [self _addSectionWithTitle:@"Details" rowCount:7];
    row = 0;

    [self _labelInRow:row title:@"Department:" in:content];
    var department = [[CPPopUpButton alloc] initWithFrame:CGRectMakeZero() pullsDown:NO];
    [department addItemsWithTitles:LibraryDepartments];
    [self _place:department row:row++ x:fieldX width:FieldWidth height:PopUpHeight in:content];
    [department setAutoresizingMask:CPViewWidthSizable];
    [self _bind:department binding:CPSelectedValueBinding key:@"department" options:nil];
    [self _bindEnabledToEditing:department];

    var manager = [CPCheckBox checkBoxWithTitle:@"Manager"];
    [manager setAllowsMixedState:YES];
    [manager sizeToFit];
    [self _place:manager row:row++ x:fieldX width:CGRectGetWidth([manager frame]) height:CGRectGetHeight([manager frame]) in:content];
    [self _bind:manager binding:CPValueBinding key:@"isManager" options:nil];
    [self _bindEnabledToEditing:manager];

    [self _labelInRow:row title:@"City:" in:content];
    var city = [[CPComboBox alloc] initWithFrame:CGRectMakeZero()];
    [city addItemsWithObjectValues:LibraryCities];
    [city setEditable:YES];
    [self _place:city row:row++ x:fieldX width:FieldWidth height:TextFieldHeight in:content];
    [city setAutoresizingMask:CPViewWidthSizable];
    [self _bind:city binding:CPValueBinding key:@"city" options:options];
    [self _bindEnabledToEditing:city];

    [self _labelInRow:row title:@"Birth Date:" in:content];
    var birthDate = [[CPDatePicker alloc] initWithFrame:CGRectMake(0, 0, ShortFieldWidth, DatePickerHeight)];
    [birthDate setDatePickerStyle:CPTextFieldAndStepperDatePickerStyle];
    [birthDate setDatePickerElements:CPYearMonthDayDatePickerElementFlag];
    [self _place:birthDate row:row++ x:fieldX width:ShortFieldWidth height:CGRectGetHeight([birthDate frame]) in:content];
    [self _bind:birthDate binding:CPValueBinding key:@"birthDate" options:nil];
    [self _bindEnabledToEditing:birthDate];

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

    content = [self _addSectionWithTitle:@"Notes" rowCount:NotesRowCount];
    [self _addNotesViewIn:content];

    [self _layoutSections];
    [view addSubview:[self _buttonBarWithFrame:CGRectMake(0, CGRectGetHeight(frame) - BarHeight, CGRectGetWidth(frame), BarHeight)]];
    [self setView:view];
    [self _updateEditingAppearance];
}

// ---------------------------------------------------------------- Notes

/*
    Fills aSuperview, the Notes section's content view, with a scroll view that holds the rich
    text view, inset by Margin at the sides and by half a margin at the top and bottom.
*/
- (void)_addNotesViewIn:(CPView)aSuperview
{
    var bounds = [aSuperview bounds],
        frame = CGRectMake(Margin, Margin / 2, CGRectGetWidth(bounds) - 2 * Margin, CGRectGetHeight(bounds) - Margin);

    _notesScrollView = [[CPScrollView alloc] initWithFrame:frame];
    [_notesScrollView setHasHorizontalScroller:NO];
    [_notesScrollView setHasVerticalScroller:YES];
    [_notesScrollView setAutohidesScrollers:YES];
    [_notesScrollView setAutoresizingMask:CPViewWidthSizable];

    var contentSize = [_notesScrollView contentSize];

    _notesView = [[CPTextView alloc] initWithFrame:CGRectMake(0, 0, contentSize.width, contentSize.height)];
    [_notesView setRichText:YES];
    [_notesView setSelectable:YES];
    [_notesView setHorizontallyResizable:NO];
    [_notesView setVerticallyResizable:YES];
    [_notesView setAutoresizingMask:CPViewWidthSizable];
    [_notesScrollView setDocumentView:_notesView];

    var options = [self _placeholderOptions];
    [options setObject:YES forKey:CPContinuouslyUpdatesValueBindingOption];
    [self _bind:_notesView binding:CPAttributedStringBinding key:@"notes" options:options];

    [aSuperview addSubview:_notesScrollView];
}

// ---------------------------------------------------------------- Edit mode

/*
    The button bar at the bottom of the pane. It holds the Edit button, a toggle whose image is
    a pencil in view mode and a check mark in edit mode.

    The images are CSS masks (MaskImage.j).
*/
- (CPButtonBar)_buttonBarWithFrame:(CGRect)aFrame
{
    var buttonBar = [[CPButtonBar alloc] initWithFrame:aFrame];

    [buttonBar setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
    [buttonBar setHasResizeControl:NO];

    var iconSize = CGSizeMake(16, 16);

    _editButton = [buttonBar buttonWithImage:MaskImage(EditMask, iconSize, [CPColor labelColor])
                              alternateImage:MaskImage(DoneMask, iconSize, [CPColor labelColor])];
    [_editButton setButtonType:CPToggleButton];
    [_editButton setTarget:self];
    [_editButton setAction:@selector(toggleEditing:)];

    [buttonBar setButtons:[_editButton]];

    return buttonBar;
}

/*
    Sets the library's edit mode. Leaving edit mode first ends the editing of the field that has
    focus in this pane, so its value reaches the person before the field becomes plain text.
*/
- (@action)toggleEditing:(id)aSender
{
    var shouldEdit = [aSender state] === CPOnState;

    if (!shouldEdit)
    {
        var window = [[self view] window],
            responder = [window firstResponder];

        if ([responder isKindOfClass:[CPView class]] && [responder isDescendantOf:[self view]])
            [window makeFirstResponder:nil];
    }

    [_library setEditable:shouldEdit];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)aChange context:(id)aContext
{
    [self _updateEditingAppearance];
}

/*
    Applies the parts of the mode that are not bindings: the text field bezels, and the state
    and tooltip of the Edit button.
*/
- (void)_updateEditingAppearance
{
    var isEditable = [_library isEditable];

    for (var i = 0, count = [_textFields count]; i < count; i++)
        [_textFields[i] setBezeled:isEditable];

    [_notesView setEditable:isEditable];
    [_notesScrollView setBorderType:isEditable ? CPBezelBorder : CPNoBorder];
    [_notesView setBackgroundColor:isEditable ? [CPColor textBackgroundColor] : [CPColor clearColor]];

    [_editButton setState:isEditable ? CPOnState : CPOffState];
    [_editButton setToolTip:isEditable ? @"Finish editing" : @"Edit"];
}

- (void)_bindEnabledToEditing:(CPControl)aControl
{
    [aControl bind:CPEnabledBinding toObject:_library withKeyPath:@"editable" options:nil];
}

// ---------------------------------------------------------------- Sections

/*
    Adds a section with a header (a disclosure triangle and a title), an undrawn box for aRowCount
    rows of fields, and, after the first section, a separator line above the header. Returns the
    box's content view, which takes the fields. The section starts open.
*/
- (CPView)_addSectionWithTitle:(CPString)aTitle rowCount:(int)aRowCount
{
    var width = CGRectGetWidth([_documentView bounds]),
        separator = nil;

    if ([_sections count])
    {
        /*
            A horizontal separator is 5 points tall, as in Interface Builder; CPBox draws its line
            in the middle of that height.
        */
        separator = [[CPBox alloc] initWithFrame:CGRectMake(Margin, 0, width - 2 * Margin, SeparatorHeight)];
        [separator setBoxType:CPBoxSeparator];
        [separator setAutoresizingMask:CPViewWidthSizable];
        [_documentView addSubview:separator];
    }

    var disclosure = [[CPButton alloc] initWithFrame:CGRectMake(Margin, 0, DisclosureSize, DisclosureSize)];
    [disclosure setBezelStyle:CPDisclosureBezelStyle];
    [disclosure setButtonType:CPOnOffButton];
    [disclosure setBordered:YES];
    [disclosure setTitle:@""];
    [disclosure setState:CPOnState];
    [disclosure setTarget:self];
    [disclosure setAction:@selector(toggleSection:)];
    [_documentView addSubview:disclosure];

    var titleX = Margin + DisclosureSize + 6.0,
        title = [CPTextField labelWithTitle:aTitle];
    [title setFont:[CPFont boldSystemFontOfSize:[CPFont systemFontSize]]];
    [title setVerticalAlignment:CPCenterVerticalTextAlignment];
    [title setFrame:CGRectMake(titleX, 0, width - titleX - Margin, HeaderHeight)];
    [title setAutoresizingMask:CPViewWidthSizable];
    [_documentView addSubview:title];

    var box = [[CPBox alloc] initWithFrame:CGRectMake(Margin, 0, width - 2 * Margin, aRowCount * RowPitch)];
    [box setBoxType:CPBoxCustom];
    [box setBorderType:CPNoBorder];
    [box setTitlePosition:CPNoTitle];
    [box setContentViewMargins:CGSizeMakeZero()];
    [box setAutoresizingMask:CPViewWidthSizable];
    [_documentView addSubview:box];

    [_sections addObject:{ separator: separator, disclosure: disclosure, title: title, box: box, height: aRowCount * RowPitch }];

    return [box contentView];
}

/*
    Shows or hides the fields of the section whose disclosure triangle sent the action, and stacks
    the sections again.
*/
- (@action)toggleSection:(id)aSender
{
    [self _layoutSections];
}

/*
    Stacks the sections from the top: each separator, header and, when its triangle is open,
    box goes below the one before it. Sets the height of the document view to the stack, so the
    scroll view scrolls only when the stack is taller than the pane.
*/
- (void)_layoutSections
{
    var y = Margin / 2;

    for (var i = 0, count = [_sections count]; i < count; i++)
    {
        var section = _sections[i];

        if (section.separator)
        {
            [section.separator setFrameOrigin:CGPointMake(Margin, y + Math.round((SeparatorGap - SeparatorHeight) / 2))];
            y += SeparatorGap;
        }

        [section.disclosure setFrameOrigin:CGPointMake(Margin, y + Math.round((HeaderHeight - DisclosureSize) / 2))];
        [section.title setFrameOrigin:CGPointMake(CGRectGetMinX([section.title frame]), y)];
        y += HeaderHeight;

        var isOpen = [section.disclosure state] === CPOnState;

        [section.box setHidden:!isOpen];

        if (isOpen)
        {
            [section.box setFrameOrigin:CGPointMake(Margin, y)];
            y += section.height;
        }
    }

    [_documentView setFrameSize:CGSizeMake(CGRectGetWidth([_documentView frame]), y + Margin)];
}

// ---------------------------------------------------------------- Layout helpers

// Centres aView vertically on the midline of row aRow of a section.
- (void)_place:(CPView)aView row:(int)aRow x:(float)anX width:(float)aWidth height:(float)aHeight in:(CPView)aSuperview
{
    var y = aRow * RowPitch + Math.round((RowPitch - aHeight) / 2);

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

    [field setSelectable:YES];
    [field setVerticalAlignment:CPCenterVerticalTextAlignment];
    [self _place:field row:aRow x:Margin + LabelWidth + LabelGap width:FieldWidth height:TextFieldHeight in:aSuperview];
    [field setAutoresizingMask:CPViewWidthSizable];
    [field bind:CPEditableBinding toObject:_library withKeyPath:@"editable" options:nil];
    [_textFields addObject:field];

    return field;
}

@end
