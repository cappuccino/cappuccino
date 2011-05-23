/*
 * AppController.j
 * performKeyEquivalentTest
 *
 * Created by aparajita on May 22, 2011.
 * Copyright 2011, Victory-Heart Productions All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPEvent.j>


var usesNewCode = YES;

@implementation AppController : CPObject
{
    CPWindow    theWindow;
    CPWindow    theOtherWindow;
    CPCheckBox  useNewCode;
    CPTextField textField;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things.

    [theOtherWindow orderFront:nil];
    [theWindow setInitialFirstResponder:textField];
    [theWindow makeKeyAndOrderFront:nil];
}

- (void)setUsesNewCode:(id)sender
{
    usesNewCode = [sender state] === CPOnState;
}

@end

@implementation MyTextField : CPTextField

- (void)keyDown:(CPEvent)anEvent
{
    CPLog("keyDown:%s", [self description]);

    if (!usesNewCode)
    {
        if ([anEvent _couldBeKeyEquivalent] && [self performKeyEquivalent:anEvent])
            return;
    }

    // CPTextField uses an HTML input element to take the input so we need to
    // propagate the dom event so the element is updated. This has to be done
    // before interpretKeyEvents: though so individual commands have a chance
    // to override this (escape to clear the text in a search field for example).
    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];

    [self interpretKeyEvents:[anEvent]];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    CPLog("performKeyEquivalent:%s", [self description]);

    return [super performKeyEquivalent:anEvent];
}

@end

@implementation CPEvent (test)

- (BOOL)_couldBeKeyEquivalent
{
    if (_type !== CPKeyDown)
        return NO;

    var characterCount = _characters.length;

    if (!characterCount)
        return NO;

    if (_modifierFlags & (CPCommandKeyMask | CPControlKeyMask))
        return YES;

    // Cocoa does not consider space, backspace, or escape a key equivalent
    // if the first responder is a text field (presumably a subclass of NSText).
    var firstResponderIsText = [[_window firstResponder] isKindOfClass:[CPTextField class]];

    for (var i = 0; i < characterCount; i++)
    {
        if (usesNewCode)
        {
            var c = _characters.charAt(i);

            if ((c >= CPUpArrowFunctionKey && c <= CPModeSwitchFunctionKey) ||
                c === CPEnterCharacter ||
                c === CPNewlineCharacter ||
                c === CPCarriageReturnCharacter ||
                (!firstResponderIsText &&
                    (c === CPSpaceFunctionKey ||
                     c === CPDeleteCharacter ||
                     c === CPBackspaceCharacter ||
                     c === CPEscapeFunctionKey)))
            {
                return YES;
            }
        }
        else
        {
            switch (_characters.charAt(i))
            {
                case CPBackspaceCharacter:
                case CPDeleteCharacter:
                case CPDeleteFunctionKey:
                case CPTabCharacter:
                case CPCarriageReturnCharacter:
                case CPNewlineCharacter:
                case CPSpaceFunctionKey:
                case CPEscapeFunctionKey:
                case CPPageUpFunctionKey:
                case CPPageDownFunctionKey:
                case CPLeftArrowFunctionKey:
                case CPUpArrowFunctionKey:
                case CPRightArrowFunctionKey:
                case CPDownArrowFunctionKey:
                case CPEndFunctionKey:
                case CPHomeFunctionKey:
                    return YES;
            }
        }
    }

    // FIXME: More cases?
    return NO;
}

@end
