# TextEditor Work List

TextEditor is a document-based test application and a tutorial. When the app uses AppKit, it shows gaps in the framework. This list records those gaps and the planned additions to the app.

## AppKit gaps

### Windows and documents

- **The Window menu does not list document windows.** It has no items to show or change the active window. AppKit has no equivalent of the Cocoa windows menu support in `NSApplication`: `windowsMenu`, `addWindowsItem:title:filename:`, `changeWindowsItem:title:filename:`, `removeWindowsItem:` and `arrangeInFront:`. nib2cib marks the menu as `_CPWindowsMenu` (`Tools/nib2cib/NSMenu.j:31`), but nothing in AppKit reads that name.
- **The window ignores the delegate's size for its own frame.** In `_setFrame:display:animate:constrainWidth:constrainHeight:`, `size` refers to `_frame.size`, which already holds the proposed size. The result of `windowWillResize:toSize:` replaces the local variable only, and goes to the window view (`CPWindow.j:799` to `811`). So when the delegate returns a different size, the window view takes that size, but `_frame` keeps the proposed size.
- **The "save changes" alert is modal for the whole app.** `CPDocument` shows it with `runModal` (`CPDocument.j:903`). Cocoa attaches it as a sheet to the document window, so that only that document is blocked.
- **Save cannot work without a server.** With no file URL, Save uses `CPSavePanel`, which falls back to `window.prompt` (`CPSavePanel.j:79`). `CPDocument` then sends an HTTP POST. A storage facade is needed, with local (IndexedDB) and remote (HTTP) implementations.

### Text view and ruler

- **The ruler markers do not update at the right times.** `CPTextView` calls `updateRuler` only when it becomes first responder (`CPTextView.j:547`) and when its typing attributes change (`:1819`). It must also update the ruler when the selection changes and when the ruler is first shown.
- **Indent markers at location 0 are half hidden.** `_positionMarker:` centres each marker on its location, so a marker at 0 starts at x = -6 (`CPRulerView.j`).
- **The ruler scale is offset from the text.** The text starts at the text container inset (2 points). The ruler has no origin offset for it.
- **Text runs past the right edge.** When the text view resizes, the text container takes the full width of the text view and ignores the inset (`CPTextContainer.j:199`).
- **There is no right indent.** `CPParagraphStyle` stores `tailIndent`, and `CPTextView` handles a moved `CPTailIndent` marker (`CPTextView.j:2630`). But `updateRuler` never creates that marker, and the typesetter ignores `tailIndent`.
- **nib2cib ignores the ruler settings.** The "Uses Ruler" setting in Interface Builder does not reach the cib.
- **`CPTextView` has no ruler control API.** `usesRuler`, `setUsesRuler:`, `setRulerVisible:` and `toggleRuler:` do not exist. `isRulerVisible` always returns `NO` (`CPTextView.j:2088`).
- **`CPRulerMarker` ignores `markerLocation`.** `initWithRulerView:markerLocation:imageValue:representedObject:` uses `imageValue` as the location.

### Undo and redo

- **Redo is unreliable or does not work.** Not yet investigated.
- **Undo stays enabled when `allowsUndo` is `NO`.** `-[CPTextView undo:]` then does nothing (`CPTextView.j:679`). The text view must disable the menu item in that case.

### Clipboard

- **Paste and Cut from the Edit menu do nothing.** `-[CPTextView paste:]` (`CPTextView.j:521`) and `cut:` (`:1754`) return unless the current event is `CPAppKitDefined`. Only the browser's native clipboard events, from the keyboard, create that event.
- **Copy from the Edit menu cannot reach the system clipboard.** It fills only the internal `CPPasteboard`.
- **Fix:** when a menu item calls these methods, use the asynchronous Clipboard API (`navigator.clipboard`). Read RTF first, then plain text. Write plain text, and RTF where the browser allows it. Keep the keyboard path unchanged.

### Toolbar

- **The Fonts and Print standard items are not implemented.** `_standardItemWithItemIdentifier:` returns `nil` for both (`_CPToolbarItem.j:641`). AppKit needs `_CPToolbarShowFontsItem` (sends `orderFrontFontPanel:`) and `_CPToolbarPrintItem` (sends `printDocument:`). nib2cib needs matching classes.

### Text features not yet supported

- **Images in text.** AppKit has no general `CPTextAttachment` class, only the table attachment `_CPTableTextAttachment`. The RTF parser and producer do not handle `\pict`.
- **Lists.** There is no `CPTextList`, and `CPParagraphStyle` has no `textLists`.

### Platform

- **Key equivalents on platforms other than macOS.** Filed as an issue.

## Planned additions to the app

- Fonts through `CPFontManager` and `CPFontPanel`.
- RTF reading and writing.
- Images and lists in text.
- A storage facade, with saving and opening in IndexedDB and through HTTP.
- An asynchronous fetch test: fetch the text of a page and show it for editing. The page must allow cross-origin requests.
- An inspector pane with `CPSplitViewController` and `CPViewController`, with a View menu item that sends `toggleInspector:`.
- Documents in separate browser windows with `CPPlatformWindow`.
- A Settings window. The first setting is the minimum size of document windows, now the constants `DocumentWindowMinimumWidth` and `DocumentWindowMinimumHeight` in `DocumentWindowController.j`.

## Tests done

- One window for each document, each loaded from its own cib.
- Insert Lorem Ipsum through the responder chain.
- Undo over several levels, separate for each document.
- Text colour through `CPColorPanel`.
- Paragraph indents through the ruler markers.
- The "save changes" alert when a document closes.
- A minimum size for document windows, through the window delegate.
- Builds with both the legacy toolchain and capp-build.
