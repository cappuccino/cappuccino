/*
 * CustomTextField.j
 * CPTextFieldMovementsTest
 *
 * Created by Alexandre Wilhelm on October 29, 2013.
 */

@import <Foundation/Foundation.j>
@import <AppKit/CPTextField.j>

@implementation CustomTextField : CPTextField
{
}

- (id)init
{
    if (self = [super init])
    {
    }
    return self;
}

- (void)keyDown:(CPEvent)anEvent
{
    var key = [anEvent charactersIgnoringModifiers];

    if (key == CPLeftArrowFunctionKey)
    {
        [[self window] makeFirstResponder:[self previousKeyView]];
        return;
    }

    if (key == CPRightArrowFunctionKey  ||
        key == CPUpArrowFunctionKey     ||
        key == CPDownArrowFunctionKey   ||
        key == CPEscapeFunctionKey      ||
        [anEvent keyCode] == CPReturnKeyCode)
    {
        [[self window] makeFirstResponder:[self nextKeyView]];
        return;
    }

    [super keyDown:anEvent];
}

@end
