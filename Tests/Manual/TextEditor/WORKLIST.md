# TextEditor Work List

TextEditor is a document-based test application and a tutorial. When the app uses AppKit, it shows gaps in the framework. This list records those gaps and the planned additions to the app.

## AppKit gaps

### Windows and documents

- **The "save changes" alert is modal for the whole app.** `CPDocument` shows it with `runModal` (`CPDocument.j:903`). Cocoa attaches it as a sheet to the document window, so that only that document is blocked.
- **Save cannot work without a server.** With no file URL, Save uses `CPSavePanel`, which falls back to `window.prompt` (`CPSavePanel.j:79`). `CPDocument` then sends an HTTP POST. A storage facade is needed, with local (IndexedDB) and remote (HTTP) implementations.

### Clipboard

- **Paste and Cut from the Edit menu do nothing.** `-[CPTextView paste:]` (`CPTextView.j:521`) and `cut:` (`:1754`) return unless the current event is `CPAppKitDefined`. Only the browser's native clipboard events, from the keyboard, create that event.
- **Copy from the Edit menu cannot reach the system clipboard.** It fills only the internal `CPPasteboard`.
- **Fix:** when a menu item calls these methods, use the asynchronous Clipboard API (`navigator.clipboard`). Read RTF first, then plain text. Write plain text, and RTF where the browser allows it. Keep the keyboard path unchanged.

### Toolbar

- **The Fonts and Print standard items are not implemented.** `_standardItemWithItemIdentifier:` returns `nil` for both (`_CPToolbarItem.j:641`). AppKit needs `_CPToolbarShowFontsItem` (sends `orderFrontFontPanel:`) and `_CPToolbarPrintItem` (sends `printDocument:`). nib2cib needs matching classes.

### Text features not yet supported

- **Images in text.** AppKit has no general `CPTextAttachment` class, only the table attachment `_CPTableTextAttachment`. The RTF parser and producer do not handle `\pict`.
- **Lists.** There is no `CPTextList`, and `CPParagraphStyle` has no `textLists`.

### nib2cib

- **nib2cib ignores the ruler settings.** The "Uses Ruler" setting in Interface Builder does not reach the cib. `CPTextView` and `CPRulerView` also need to archive their ruler settings.
- **The content view's resizing setting does not reach the cib.** Making the document window's content view resize with the window in `DocumentWindow.xib` produces a byte-identical `DocumentWindow.cib`. CPView omits the autoresizing mask from the archive only when it is `CPViewNotSizable` (`CPView.j:4016`), so the content view is archived as not sizable. Not yet determined whether `ibtool` or nib2cib drops the setting. The app still behaves correctly, because the window resizes its content view itself.

### Menus and key equivalents (needs discussion)

- **The key equivalent of a disabled menu item reaches the browser.** `-[CPMenu performKeyEquivalent:]` (`CPMenu.j:1059`) stops the browser's default action only when the matching item is enabled. For a disabled item it reports the key as handled, but the browser still acts on it: with File > Close disabled, Cmd-W closes the browser tab. Cocoa consumes the key equivalent of a disabled item with a beep. Stopping the browser's default for disabled items as well would match Cocoa for most keys, but not all: some browsers do not let a page block certain shortcuts, such as Cmd-W, Cmd-N and Cmd-T in Chrome, and Copy, Cut and Paste must keep reaching the browser for its clipboard events. This needs careful thought, and perhaps discussion, before any change.

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
- Undo and redo over several levels, separate for each document.
- Text colour through `CPColorPanel`.
- Paragraph indents through the ruler markers.
- The "save changes" alert when a document closes.
- A minimum size for document windows, through the window delegate. The window stops at the minimum while the pointer keeps moving, as in macOS, and it can still be moved and resized afterwards.
- View > Show Toolbar and Hide Toolbar: the item's title follows the toolbar's visibility.
- The Window menu lists the open document windows, marks the main window with a check mark and brings a window to the front when chosen. Bring All to Front can be tested once documents open in separate browser windows.
- The About panel shows the display name from `CPBundleDisplayName`.
- Edit > Allow Undo turns undo on and off for the active document. With undo off, Undo and Redo stay disabled, and the check mark follows the document in front.
- The ruler: markers follow the paragraph at the selection; first line, head and right indents change the layout as shown; clicking adds a tab stop, and dragging moves or removes one; the Control-click menu on a tab stop appears (its effect is not yet verified, for lack of tabbed text); the ruler's zero lines up with the start of the text, and markers at 0 are fully visible.
- Text stays inside the visible width, with Cocoa's 5-point line fragment padding.
- Builds with both the legacy toolchain and capp-build.
