/*
 * NameSheetController.j
 * SmartFoldersDemo
 *
 * Minimal reusable sheet asking for a name (new group, rename group).
 * Exercises a second, independent CPWindowController-owned sheet, first
 * responder handling and default/escape key equivalents.
 */

@import <AppKit/AppKit.j>

@implementation NameSheetController : CPWindowController
{
    CPTextField     _titleField;
    CPTextField     _nameField;
    CPButton        _okButton;
    Function        _completion;
}

- (id)init
{
    var window = [[CPWindow alloc] initWithContentRect:CGRectMake(0, 0, 380, 140) styleMask:CPDocModalWindowMask];

    if (self = [super initWithWindow:window])
        [self _buildInterface];

    return self;
}

- (void)_buildInterface
{
    var content = [[self window] contentView],
        width = CGRectGetWidth([content bounds]),
        height = CGRectGetHeight([content bounds]);

    _titleField = [CPTextField labelWithTitle:@""];
    [_titleField setFont:[CPFont boldSystemFontOfSize:13.0]];
    [_titleField setFrame:CGRectMake(20, 16, width - 40, 20)];
    [content addSubview:_titleField];

    _nameField = [[CPTextField alloc] initWithFrame:CGRectMake(20, 46, width - 40, 29)];
    [_nameField setEditable:YES];
    [_nameField setBezeled:YES];
    [content addSubview:_nameField];

    var cancelButton = [CPButton buttonWithTitle:@"Cancel"];
    [cancelButton setFrame:CGRectMake(width - 200, height - 44, 85, 25)];
    [cancelButton setTag:CPCancelButton];
    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(closeSheet:)];
    [cancelButton setKeyEquivalent:CPEscapeFunctionKey];
    [content addSubview:cancelButton];

    _okButton = [CPButton buttonWithTitle:@"OK"];
    [_okButton setFrame:CGRectMake(width - 105, height - 44, 85, 25)];
    [_okButton setTag:CPOKButton];
    [_okButton setTarget:self];
    [_okButton setAction:@selector(closeSheet:)];
    [content addSubview:_okButton];

    [[self window] setDefaultButton:_okButton];
}

// aCallback(name) is invoked only when the user confirms with a non-empty name.
- (void)beginWithTitle:(CPString)aTitle name:(CPString)aName okTitle:(CPString)anOKTitle modalForWindow:(CPWindow)aWindow completion:(Function)aCallback
{
    _completion = aCallback;

    [_titleField setStringValue:aTitle];
    [_nameField setStringValue:aName || @""];
    [_okButton setTitle:anOKTitle || @"OK"];

    [CPApp beginSheet:[self window]
       modalForWindow:aWindow
        modalDelegate:self
       didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];

    [[self window] makeFirstResponder:_nameField];
    [_nameField selectText:self];
}

- (void)closeSheet:(id)sender
{
    if ([sender tag] === CPOKButton && ![[[_nameField stringValue] stringByTrimmingWhitespace] length])
        return;

    [CPApp endSheet:[self window] returnCode:[sender tag]];
}

- (void)sheetDidEnd:(CPWindow)aSheet returnCode:(int)aReturnCode contextInfo:(id)aContext
{
    [aSheet orderOut:self];

    var callback = _completion;
    _completion = nil;

    if (aReturnCode === CPOKButton && callback)
        callback([[_nameField stringValue] stringByTrimmingWhitespace]);
}

@end
