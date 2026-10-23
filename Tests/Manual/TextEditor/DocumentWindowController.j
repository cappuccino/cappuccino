/*
 * DocumentWindowController.j
 * TextEditor
 *
 * Copyright (c) 2026 David Richardson
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "LoremIpsum.j"


/*
    The smallest size, in points, to which the user can resize a document
    window. The size includes the title bar, the toolbar and the ruler, so
    the values leave room for a few lines of text below them.

    These values are provisional. Adjust them as the window gains more
    content, such as an inspector pane.
*/
var DocumentWindowMinimumWidth  = 360.0,
    DocumentWindowMinimumHeight = 240.0;


/*!
    Owns DocumentWindow.cib. The window's delegate outlet is connected to
    File's Owner in DocumentWindow.xib, so this controller is the window's
    delegate. windowDidLoad assigns it again, so the delegate is set even if
    the connection is missing from the xib.
*/
@implementation DocumentWindowController : CPWindowController <CPWindowDelegate>
{
    /*
        The text view inside the window's scroll view. The outlet is connected
        to the text view in DocumentWindow.xib.
    */
    @outlet CPTextView  textView;
}

- (id)init
{
    return [self initWithWindowCibName:@"DocumentWindow"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    [[self window] setDelegate:self];

    /*
        Show a horizontal ruler above the text.

        A ruler is not a separate control. It belongs to the scroll view that
        encloses the text view, and the text view keeps its markers in step
        with the tab stops and indents of the paragraph at the selection.

        In Interface Builder the text view's "Uses Ruler" setting turns this
        on, but nib2cib does not yet carry the ruler settings into the cib,
        so the ruler is set up here in code.
    */
    var scrollView = [textView enclosingScrollView];

    [scrollView setHasHorizontalRuler:YES];
    [scrollView setRulersVisible:YES];
}

/*!
    Inserts the placeholder text from LoremIpsum at the text view's selection,
    replacing any selected text.

    The Edit menu item in MainMenu.xib sends this action to First Responder.
    The menu does not know about any document. AppKit passes the action along
    the responder chain of the key window, then of the main window: the text
    view, its superviews, the window, and then this controller, which is the
    window's next responder. So the text goes into the active document's
    window, and AppKit disables the menu item when no document window is
    active.

    insertText: changes the text the same way typing does. It registers the
    change with the document's undo manager, so Edit > Undo removes the
    inserted text.
*/
- (@action)insertLoremIpsum:(id)aSender
{
    [textView insertText:[LoremIpsum text]];
}

/*!
    Keeps the window at or above its minimum size while the user resizes it.

    This is a CPWindowDelegate method. The window calls it with the size it
    is about to take, and uses the size that this method returns. Returning
    a larger size than the one proposed stops the window from shrinking past
    the minimum, while it still follows the pointer in every other direction.

    A fixed minimum could also be set on the window in Interface Builder.
    The delegate method is used here because it can compute the minimum, for
    example from the content of the window.
*/
- (CGSize)windowWillResize:(CPWindow)aWindow toSize:(CGSize)aSize
{
    return CGSizeMake(Math.max(aSize.width, DocumentWindowMinimumWidth),
                      Math.max(aSize.height, DocumentWindowMinimumHeight));
}

/*!
    Turns undo on or off for this document's text view.

    This is test scaffolding, not a Cocoa convention: Cocoa apps set
    allowsUndo once, in Interface Builder or in code. The Edit > Allow Undo
    menu item exists so that both settings can be tried while the app runs.
    It will move to a Settings window.

    Like Insert Lorem Ipsum, the menu item sends its action to First
    Responder, and the responder chain delivers it to the controller of the
    active document's window. Neither the text view nor the window responds
    to toggleAllowsUndo:, so the action passes them by.
*/
- (@action)toggleAllowsUndo:(id)aSender
{
    var allowsUndo = ![textView allowsUndo];

    [textView setAllowsUndo:allowsUndo];

    /*
        A text view that does not allow undo registers no changes, and does
        not respond to undo: or redo:, so those actions go on to the window
        and its undo manager. Remove the changes the text view registered
        before undo was turned off, so that Edit > Undo cannot still undo
        them through the window.
    */
    if (!allowsUndo)
        [[[self window] undoManager] removeAllActionsWithTarget:textView];
}

/*!
    Validates the menu items whose actions this controller handles.

    AppKit calls this method before it shows a menu, for each item whose
    action reaches this controller through the responder chain. For Allow
    Undo, it sets the item's check mark from the active document's text
    view, so the mark follows the document whose window is in front. Every
    item is enabled.
*/
- (BOOL)validateMenuItem:(CPMenuItem)aMenuItem
{
    if ([aMenuItem action] === @selector(toggleAllowsUndo:))
        [aMenuItem setState:[textView allowsUndo] ? CPOnState : CPOffState];

    return YES;
}

@end
