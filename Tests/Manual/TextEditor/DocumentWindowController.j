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
@import "TableExample.j"


/*
    The smallest size, in points, to which the user can resize a document
    window. The size includes the title bar, the toolbar and the ruler, so
    the values leave room for a few lines of text below them.

    These values are provisional. Adjust them as the window gains more
    content, such as an inspector pane.
*/
var DocumentWindowMinimumWidth  = 360.0,
    DocumentWindowMinimumHeight = 240.0;


/*
    Orders two zoom levels, smallest first, for sorting.
*/
function compareZoomLevels(aLevel, anotherLevel)
{
    return aLevel - anotherLevel;
}


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
        setRulerVisible: asks the text view to show the ruler, and the
        Format menu's Show Ruler item sends toggleRuler: to hide or show it
        again.

        In Interface Builder the text view's "Uses Ruler" setting decides
        whether the text view may show a ruler at all, but nib2cib does not
        yet carry the ruler settings into the cib, so the ruler is shown here
        in code.
    */
    [textView setRulerVisible:YES];
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
    Inserts the sample document from TableExample at the text view's
    selection, replacing any selected text. The sample contains a table.

    Like Insert Lorem Ipsum, the Edit menu item sends this action to First
    Responder, and the responder chain delivers it to the controller of the
    active document's window.

    The sample is an attributed string, so insertText: keeps its fonts and
    its table, but only in a rich text view. A plain text view would keep
    only the characters, so the table needs rich text. Edit > Undo removes
    the inserted text, with the table.
*/
- (@action)insertTableExample:(id)aSender
{
    [textView insertText:[TableExample attributedString]];
}

/*!
    Returns the scroll view that encloses the text view.

    The zoom commands do not change the text view itself. They change the
    magnification of its scroll view, as TextEdit does: the scroll view
    scales its clip view, which draws the text view, with everything inside
    it, larger or smaller. The text wraps to the window at every
    magnification, because the text view takes the width of the clip view.
*/
- (CPScrollView)documentScrollView
{
    return [textView enclosingScrollView];
}

/*!
    Sets the magnification to the zoom level in the sender's tag, a
    percentage. Each item of View > Zoom Level sends this action, with its
    level as its tag, for example 75 for 75%.
*/
- (@action)zoomToLevel:(id)aSender
{
    [[self documentScrollView] setMagnification:[aSender tag] / 100.0];
}

/*!
    Returns the text to actual size, a magnification of 1.0.
*/
- (@action)zoomToActualSize:(id)aSender
{
    [[self documentScrollView] setMagnification:1.0];
}

/*!
    Moves to the next zoom level above the current magnification.
*/
- (@action)zoomIn:(id)aSender
{
    var level = [self zoomLevelFrom:[[self documentScrollView] magnification] direction:1];

    if (level)
        [[self documentScrollView] setMagnification:level];
}

/*!
    Moves to the next zoom level below the current magnification.
*/
- (@action)zoomOut:(id)aSender
{
    var level = [self zoomLevelFrom:[[self documentScrollView] magnification] direction:-1];

    if (level)
        [[self documentScrollView] setMagnification:level];
}

/*!
    Returns the zoom levels, as magnifications in ascending order.

    The menu items of View > Zoom Level are the only definition of the
    levels: each item that sends zoomToLevel: carries its level as a
    percentage in its tag. Zoom In and Zoom Out step through the same items,
    so adding, removing or changing an item in MainMenu.xib changes all
    three commands together.
*/
- (CPArray)zoomLevels
{
    var levels = [];

    [self collectZoomLevelsFromMenu:[CPApp mainMenu] into:levels];

    return levels.sort(compareZoomLevels);
}

/*!
    Adds to someLevels the level of every item in aMenu, and in its
    submenus, that sends zoomToLevel:.
*/
- (void)collectZoomLevelsFromMenu:(CPMenu)aMenu into:(CPArray)someLevels
{
    var items = [aMenu itemArray],
        count = [items count];

    for (var i = 0; i < count; i++)
    {
        var item = items[i];

        if ([item action] === @selector(zoomToLevel:))
            someLevels.push([item tag] / 100.0);

        if ([item hasSubmenu])
            [self collectZoomLevelsFromMenu:[item submenu] into:someLevels];
    }
}

/*!
    Returns the next zoom level above aMagnification, with a direction of 1,
    or below it, with a direction of -1. Returns nil when there is none. The
    comparison allows for rounding in the magnification.
*/
- (float)zoomLevelFrom:(float)aMagnification direction:(int)aDirection
{
    var levels = [self zoomLevels],
        count = levels.length;

    for (var i = 0; i < count; i++)
    {
        var level = levels[aDirection > 0 ? i : count - 1 - i];

        if (aDirection > 0 ? level > aMagnification + 0.001 : level < aMagnification - 0.001)
            return level;
    }

    return nil;
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
    view, so the mark follows the document whose window is in front. For the
    zoom commands, it checks the current zoom level and disables commands
    that would not change the magnification. Every other item is enabled.
*/
- (BOOL)validateMenuItem:(CPMenuItem)aMenuItem
{
    var action = [aMenuItem action],
        magnification = [[self documentScrollView] magnification];

    if (action === @selector(toggleAllowsUndo:))
        [aMenuItem setState:[textView allowsUndo] ? CPOnState : CPOffState];

    /*
        The zoom level that matches the current magnification is checked.
        Zoom In and Zoom Out are disabled at the highest and lowest levels,
        and Actual Size at actual size.
    */
    if (action === @selector(zoomToLevel:))
        [aMenuItem setState:ABS(magnification - [aMenuItem tag] / 100.0) < 0.001 ? CPOnState : CPOffState];

    if (action === @selector(zoomIn:))
        return !![self zoomLevelFrom:magnification direction:1];

    if (action === @selector(zoomOut:))
        return !![self zoomLevelFrom:magnification direction:-1];

    if (action === @selector(zoomToActualSize:))
        return ABS(magnification - 1.0) >= 0.001;

    return YES;
}

@end
