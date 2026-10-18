/*
 * SmartFolderEditorController.j
 * SmartFoldersDemo
 *
 * Document-modal sheet for creating / editing a smart folder. Exercises:
 *   - CPWindowController owning a CPDocModalWindowMask window, run as a sheet
 *     with -beginSheet:modalForWindow:modalDelegate:didEndSelector:contextInfo:
 *   - CPPredicateEditor (CPRuleEditor subclass) built entirely from
 *     CPPredicateEditorRowTemplate instances: compound (AND/OR/NOT),
 *     key path + string attribute type with [cd] options, key path + integer
 *     attribute type, key path + constant right expressions (pop-up)
 *   - round trip predicate -> editor (setObjectValue:) -> predicate
 *   - CPRuleEditorRowsDidChangeNotification + target/action for live preview
 *   - resizing a sheet while it is attached
 *   - default button / escape key equivalent
 */

@import <AppKit/AppKit.j>
@import "Library.j"

var EditorWidth         = 680.0,
    EditorChromeHeight  = 200.0,
    EditorMinHeight     = 300.0,
    EditorMaxHeight     = 600.0,
    EditorRowHeight     = 28.0,
    EditorTitles        = {
        "firstName"  : "First Name",
        "lastName"   : "Last Name",
        "email"      : "Email",
        "city"       : "City",
        "department" : "Department",
        "age"        : "Age",
        "salary"     : "Salary"
    };


// --------------------------------------------------------------------------------
// LabeledRowTemplate – shows human readable titles for key path expressions
// --------------------------------------------------------------------------------

@implementation LabeledRowTemplate : CPPredicateEditorRowTemplate
{
}

- (CPArray)templateViews
{
    var views = [super templateViews],
        first = [views firstObject];

    if ([first isKindOfClass:[CPPopUpButton class]])
    {
        var items = [first itemArray];

        for (var i = 0; i < items.length; i++)
        {
            var expression = [items[i] representedObject];

            if ([expression respondsToSelector:@selector(expressionType)] && [expression expressionType] === CPKeyPathExpressionType)
            {
                var title = EditorTitles[[expression keyPath]];

                if (title && [items[i] title] !== title)
                    [items[i] setTitle:title];
            }
        }
    }

    return views;
}

@end


// --------------------------------------------------------------------------------
// SmartFolderEditorController
// --------------------------------------------------------------------------------

@implementation SmartFolderEditorController : CPWindowController
{
    Library             _library;
    CPTextField         _nameField;
    CPScrollView        _editorScrollView;
    CPPredicateEditor   _predicateEditor;
    CPTextField         _formatField;
    CPTextField         _matchField;
    CPButton            _okButton;

    SmartFolder         _folder;
    Function            _completion;
}

- (id)initWithLibrary:(Library)aLibrary
{
    var window = [[CPWindow alloc] initWithContentRect:CGRectMake(0, 0, EditorWidth, EditorMinHeight) styleMask:CPDocModalWindowMask];

    if (self = [super initWithWindow:window])
    {
        _library = aLibrary;
        [self _buildInterface];

        [[CPNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(ruleEditorRowsDidChange:)
                                                     name:CPRuleEditorRowsDidChangeNotification
                                                   object:_predicateEditor];
    }

    return self;
}

- (void)_buildInterface
{
    var window = [self window],
        content = [window contentView],
        bounds = [content bounds],
        width = CGRectGetWidth(bounds),
        height = CGRectGetHeight(bounds);

    var title = [CPTextField labelWithTitle:@"Smart Folder"];
    [title setFont:[CPFont boldSystemFontOfSize:13.0]];
    [title setFrameOrigin:CGPointMake(20, 14)];
    [content addSubview:title];

    var nameLabel = [CPTextField labelWithTitle:@"Name:"];
    [nameLabel setAlignment:CPRightTextAlignment];
    [nameLabel setFrame:CGRectMake(20, 46, 60, 20)];
    [content addSubview:nameLabel];

    _nameField = [[CPTextField alloc] initWithFrame:CGRectMake(85, 40, width - 105, 29)];
    [_nameField setEditable:YES];
    [_nameField setBezeled:YES];
    [_nameField setAutoresizingMask:CPViewWidthSizable];
    [_nameField setPlaceholderString:@"Smart folder name"];
    [content addSubview:_nameField];

    var matchLabel = [CPTextField labelWithTitle:@"Match people where:"];
    [matchLabel setFrameOrigin:CGPointMake(20, 80)];
    [content addSubview:matchLabel];

    // --- Predicate editor inside a scroll view
    var top = 102.0,
        bottomChrome = EditorChromeHeight - top;

    _editorScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(20, top, width - 40, height - top - bottomChrome)];
    [_editorScrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_editorScrollView setAutohidesScrollers:YES];
    [_editorScrollView setHasHorizontalScroller:NO];
    [_editorScrollView setBorderType:CPBezelBorder];

    _predicateEditor = [[CPPredicateEditor alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([[_editorScrollView contentView] bounds]), EditorRowHeight)];
    [_predicateEditor setAutoresizingMask:CPViewWidthSizable];
    [_predicateEditor setRowHeight:EditorRowHeight];
    [_predicateEditor setNestingMode:CPRuleEditorNestingModeCompound];
    [_predicateEditor setCanRemoveAllRows:NO];
    [_predicateEditor setRowTemplates:[self _rowTemplates]];
    [_predicateEditor setTarget:self];
    [_predicateEditor setAction:@selector(predicateEditorChanged:)];

    [_editorScrollView setDocumentView:_predicateEditor];
    [content addSubview:_editorScrollView];

    // --- Footer
    _formatField = [CPTextField labelWithTitle:@""];
    [_formatField setFrame:CGRectMake(20, height - 88, width - 40, 18)];
    [_formatField setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
    [_formatField setFont:[CPFont fontWithName:@"Menlo, Courier" size:11.0]];
    [_formatField setTextColor:[CPColor grayColor]];
    [_formatField setLineBreakMode:CPLineBreakByTruncatingTail];
    [_formatField setSelectable:YES];
    [content addSubview:_formatField];

    _matchField = [CPTextField labelWithTitle:@""];
    [_matchField setFrame:CGRectMake(20, height - 40, 300, 20)];
    [_matchField setAutoresizingMask:CPViewMaxXMargin | CPViewMinYMargin];
    [content addSubview:_matchField];

    var cancelButton = [CPButton buttonWithTitle:@"Cancel"];
    [cancelButton setFrame:CGRectMake(width - 200, height - 44, 85, 25)];
    [cancelButton setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];
    [cancelButton setTag:CPCancelButton];
    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(closeSheet:)];
    [cancelButton setKeyEquivalent:CPEscapeFunctionKey];
    [content addSubview:cancelButton];

    _okButton = [CPButton buttonWithTitle:@"OK"];
    [_okButton setFrame:CGRectMake(width - 105, height - 44, 85, 25)];
    [_okButton setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];
    [_okButton setTag:CPOKButton];
    [_okButton setTarget:self];
    [_okButton setAction:@selector(closeSheet:)];
    [content addSubview:_okButton];

    [window setDefaultButton:_okButton];
}

- (CPArray)_rowTemplates
{
    var keyPaths = function(keys)
    {
        var result = [];

        for (var i = 0; i < keys.length; i++)
            result.push([CPExpression expressionForKeyPath:keys[i]]);

        return result;
    };

    var compound = [[CPPredicateEditorRowTemplate alloc] initWithCompoundTypes:[CPAndPredicateType, CPOrPredicateType, CPNotPredicateType]];

    var strings = [[LabeledRowTemplate alloc] initWithLeftExpressions:keyPaths([@"lastName", @"firstName", @"email", @"city"])
                                         rightExpressionAttributeType:CPStringAttributeType
                                                             modifier:CPDirectPredicateModifier
                                                            operators:[CPContainsPredicateOperatorType,
                                                                       CPBeginsWithPredicateOperatorType,
                                                                       CPEndsWithPredicateOperatorType,
                                                                       CPEqualToPredicateOperatorType,
                                                                       CPNotEqualToPredicateOperatorType,
                                                                       CPMatchesPredicateOperatorType]
                                                              options:CPCaseInsensitivePredicateOption | CPDiacriticInsensitivePredicateOption];

    var numbers = [[LabeledRowTemplate alloc] initWithLeftExpressions:keyPaths([@"age", @"salary"])
                                         rightExpressionAttributeType:CPInteger32AttributeType
                                                             modifier:CPDirectPredicateModifier
                                                            operators:[CPEqualToPredicateOperatorType,
                                                                       CPNotEqualToPredicateOperatorType,
                                                                       CPLessThanPredicateOperatorType,
                                                                       CPLessThanOrEqualToPredicateOperatorType,
                                                                       CPGreaterThanPredicateOperatorType,
                                                                       CPGreaterThanOrEqualToPredicateOperatorType]
                                                              options:0];

    var departmentValues = [];

    for (var i = 0; i < LibraryDepartments.length; i++)
        departmentValues.push([CPExpression expressionForConstantValue:LibraryDepartments[i]]);

    var departments = [[LabeledRowTemplate alloc] initWithLeftExpressions:keyPaths([@"department"])
                                                         rightExpressions:departmentValues
                                                                 modifier:CPDirectPredicateModifier
                                                                operators:[CPEqualToPredicateOperatorType, CPNotEqualToPredicateOperatorType]
                                                                  options:0];

    return [compound, strings, numbers, departments];
}

// ---------------------------------------------------------------- Running the sheet

// aFolder == nil creates a new folder. aCallback(folderOrNil) is invoked after OK.
- (void)beginEditingFolder:(SmartFolder)aFolder modalForWindow:(CPWindow)aWindow completion:(Function)aCallback
{
    _folder = aFolder;
    _completion = aCallback;

    [_nameField setStringValue:aFolder ? [aFolder name] : @"Untitled Smart Folder"];

    var predicate = aFolder ? [aFolder predicate] : [CPPredicate predicateWithFormat:@"lastName CONTAINS[cd] %@", @""];
    [self _setEditorPredicate:predicate];

    [CPApp beginSheet:[self window]
       modalForWindow:aWindow
        modalDelegate:self
       didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];

    [[self window] makeFirstResponder:_nameField];
    [_nameField selectText:self];

    [self _updatePreview];
    [self _fitWindowToRows];
}

- (void)_setEditorPredicate:(CPPredicate)aPredicate
{
    // In compound nesting mode the root row must be a compound predicate.
    if (![aPredicate isKindOfClass:[CPCompoundPredicate class]])
        aPredicate = [CPCompoundPredicate andPredicateWithSubpredicates:[aPredicate]];

    try
    {
        [_predicateEditor setObjectValue:aPredicate];
    }
    catch (e)
    {
        CPLog.warn("SmartFoldersDemo: CPPredicateEditor could not represent " + [aPredicate predicateFormat] + ": " + e);
        [_predicateEditor setObjectValue:[CPCompoundPredicate andPredicateWithSubpredicates:[[CPPredicate predicateWithFormat:@"lastName CONTAINS[cd] %@", @""]]]];
    }
}

- (CPPredicate)_currentPredicate
{
    try
    {
        [_predicateEditor reloadPredicate];
        return [_predicateEditor predicate];
    }
    catch (e)
    {
        CPLog.warn("SmartFoldersDemo: could not build predicate: " + e);
        return nil;
    }
}

- (void)closeSheet:(id)sender
{
    if ([sender tag] === CPOKButton)
    {
        if (![[[_nameField stringValue] stringByTrimmingWhitespace] length])
        {
            [[self window] makeFirstResponder:_nameField];
            return;
        }

        if (![self _currentPredicate])
            return;
    }

    [CPApp endSheet:[self window] returnCode:[sender tag]];
}

- (void)sheetDidEnd:(CPWindow)aSheet returnCode:(int)aReturnCode contextInfo:(id)aContext
{
    [aSheet orderOut:self];

    var callback = _completion,
        folder = _folder;

    _completion = nil;
    _folder = nil;

    if (aReturnCode !== CPOKButton)
        return;

    var name = [[_nameField stringValue] stringByTrimmingWhitespace],
        predicate = [self _currentPredicate];

    if (folder)
        [_library updateSmartFolder:folder name:name predicate:predicate];
    else
        folder = [_library addSmartFolderWithName:name predicate:predicate];

    if (callback)
        callback(folder);
}

// ---------------------------------------------------------------- Live preview

- (void)predicateEditorChanged:(id)sender
{
    [self _updatePreview];
}

- (void)ruleEditorRowsDidChange:(CPNotification)aNotification
{
    [self _updatePreview];
    [self _fitWindowToRows];
}

- (void)_updatePreview
{
    var predicate = [self _currentPredicate],
        matches = predicate ? [_library peopleMatchingPredicate:predicate] : nil;

    [_formatField setStringValue:predicate ? [predicate predicateFormat] : @"(incomplete predicate)"];

    if (matches)
        [_matchField setStringValue:[CPString stringWithFormat:@"%d of %d people match", [matches count], [[_library people] count]]];
    else
        [_matchField setStringValue:@"Predicate cannot be evaluated"];

    [_okButton setEnabled:!!matches];
}

- (void)_fitWindowToRows
{
    var window = [self window],
        rows = MAX([_predicateEditor numberOfRows], 1),
        desired = EditorChromeHeight + rows * EditorRowHeight + 6,
        height = MIN(MAX(desired, EditorMinHeight), EditorMaxHeight),
        frame = [window frame];

    // Make sure the editor's own frame tracks its rows so the scroll view can scroll.
    [_predicateEditor setFrameSize:CGSizeMake(CGRectGetWidth([[_editorScrollView contentView] bounds]), rows * EditorRowHeight)];

    if (ABS(CGRectGetHeight(frame) - height) < 1)
        return;

    [window setFrame:CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), CGRectGetWidth(frame), height) display:YES animate:NO];
}

@end
