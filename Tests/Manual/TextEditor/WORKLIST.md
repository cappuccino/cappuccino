# TextEditor Work List

TextEditor is a document-based test application and a tutorial. When the app uses AppKit, it shows gaps in the framework. This list records those gaps and the planned additions to the app.

## AppKit gaps

### Windows and documents

- **The "save changes" alert is modal for the whole app.** `CPDocument` shows it with `runModal` (`CPDocument.j:903`). Cocoa attaches it as a sheet to the document window, so that only that document is blocked.
- **Save cannot work without a server.** With no file URL, Save uses `CPSavePanel`, which falls back to `window.prompt` (`CPSavePanel.j:79`). `CPDocument` then sends an HTTP POST. A storage facade is needed, with local (IndexedDB) and remote (HTTP) implementations.

### Toolbar

- **The Fonts and Print standard items are not implemented.** `_standardItemWithItemIdentifier:` returns `nil` for both (`_CPToolbarItem.j:641`). AppKit needs `_CPToolbarShowFontsItem` (sends `orderFrontFontPanel:`) and `_CPToolbarPrintItem` (sends `printDocument:`). nib2cib needs matching classes.

### Text features not yet supported

- **Images in text are not fully tested or complete.** `CPTextAttachment` holds an image as one attachment character, and Edit > Insert Image… and Command-V with an image on the clipboard insert images. Not yet tested: several images inserted at once, undoing an image change, and pasting a screenshot. Not yet implemented: dropping image files on the text view, which needs file access in the drag pasteboard (`_CPDOMDataTransferPasteboard`); pasting images with Edit > Paste from the menu, which reads plain text only; and RTF `\pict` and Markdown `![]()`, so an image is lost when text is copied to another application as RTF.
- **Tables can only be inserted from Markdown, and are not yet tested interactively.** The only source of tables is CPMarkdownParser, which builds the private `_CPTableTextAttachment`, a view in the text whose cells are text views of their own. Edit > Insert Table Example inserts a sample through it. Not yet tested: what Tab does in a cell, deleting the table and undoing, narrowing the window, and Format menu commands while a cell is being edited. Known from the code: nothing calls its `resizeToWidth:`, so it keeps its width of 500 points; and in the sample its right edge and the last row's bottom border are not drawn. A command to insert a table, with a fixed default size and no options, waits on these results.
- **Rich text does not reach native applications.** The RTF producer and parser now handle lists (`\listtable`, `\listoverridetable`, `\ls`, `\ilvl`, and Cocoa's `\levelmarker`), Unicode (`\uN`) and the first line indent as an offset from the left indent, and the unit tests round-trip them. But browsers do not put `text/rtf` from a page's clipboard event on the system clipboard in a form native applications read: text copied from TextEditor with Command-C reaches native TextEdit as plain text. RTF on the clipboard works only between Cappuccino applications in the same browser. Rich text for native applications needs an HTML producer (`text/html`) for the subset the text view makes. Not yet tested: what arrives from native TextEdit with Command-V, in each browser. RTF `\pict` is not implemented. CPMarkdownParser also writes "- item" as the literal text "  • item", with no list.

### Text view

How the text system works, for the entries below: `CPTextView` does not use CSS text layout. `CPSimpleTypesetter` measures text with the canvas `measureText` (`sizeWithFont:inWidth:` in `CPStringDrawing.j`), measuring growing substrings so that each character's advancement includes the browser's kerning. It then breaks lines, places tabs, and applies indents and alignment itself (`CPTypesetter.j`). `_CPLineFragment` (`CPLayoutManager.j`) draws each run of identical attributes as one absolutely positioned `<span>`, at the computed position, with `white-space: pre` and the run's font, colour and underline in CSS. Inside a span the browser shapes the glyphs, including its own kerning and ligatures.

- **Kerning and ligature settings are not implemented.** Format > Font > Kern sends `useStandardKerning:`, `turnOffKerning:`, `tightenKerning:` and `loosenKerning:`, and Format > Font > Ligatures sends `useStandardLigatures:`, `turnOffLigatures:` and `useAllLigatures:`. `CPTextView` implements none of them, so the items are disabled. `CPText.j` defines `CPKernAttributeName` and `CPLigatureAttributeName`, but only the RTF producer reads them. A complete implementation needs: the seven actions, changing the attributes over the selection or the typing attributes with undo, as the baseline actions do; the typesetter adding a run's `CPKernAttributeName` value to each character's advancement, and measuring with the same ligature setting it draws with; and `_CPLineFragment` setting CSS `letter-spacing` and `font-variant-ligatures` on each run's span to match.
- **The font panel needs polish.** Found during the Format menu review on 24 October: the panel works with the text view, but its appearance and behaviour need refinement. The specific problems are not yet recorded; list them here, compared with the native font panel, when the panel is reviewed. `CPFontPanel` is in `AppKit/CPTextView/CPFontPanel.j`.

### Ruler

- **Marker appearance and vertical alignment differ from TextEdit.** The marker images, and where markers sit across the ruler, are interim until Aristo3 supplies its own; adjust them to match TextEdit then. A tab stop dragged up off the ruler follows the pointer and is clipped by the ruler's edge, as in TextEdit. Dragged down off the ruler, it stays on its line and is drawn faded until release; TextEdit's behaviour in that direction has not been checked.

### nib2cib

- **nib2cib ignores the ruler settings.** The "Uses Ruler" setting in Interface Builder does not reach the cib. `CPTextView` and `CPRulerView` also need to archive their ruler settings.
- **The content view's resizing setting does not reach the cib.** Making the document window's content view resize with the window in `DocumentWindow.xib` produces a byte-identical `DocumentWindow.cib`. CPView omits the autoresizing mask from the archive only when it is `CPViewNotSizable` (`CPView.j:4016`), so the content view is archived as not sizable. Not yet determined whether `ibtool` or nib2cib drops the setting. The app still behaves correctly, because the window resizes its content view itself.

### Menus and key equivalents (needs discussion)

- **The key equivalent of a disabled menu item reaches the browser.** `-[CPMenu performKeyEquivalent:]` (`CPMenu.j:1059`) stops the browser's default action only when the matching item is enabled. For a disabled item it reports the key as handled, but the browser still acts on it: with File > Close disabled, Cmd-W closes the browser tab. Cocoa consumes the key equivalent of a disabled item with a beep. Stopping the browser's default for disabled items as well would match Cocoa for most keys, but not all: some browsers do not let a page block certain shortcuts, such as Cmd-W, Cmd-N and Cmd-T in Chrome, and Copy, Cut and Paste must keep reaching the browser for its clipboard events. This needs careful thought, and perhaps discussion, before any change.

### Platform

- **Key equivalents on platforms other than macOS.** Filed as an issue.

## Opportunities for improvement

- **Rich text through the asynchronous Clipboard API.** Edit > Copy, Cut and Paste chosen from the menu reach the system clipboard through `navigator.clipboard`, which carries plain text only. Rich text still moves between applications through the keyboard path, in the browser's clipboard events, and within the application through the internal pasteboard. Handling attributed text in general is an unbounded task, but a limited subset could be supported, for example through `text/html` in a `ClipboardItem`.

- **Justification is nominally functional, but its quality is limited.** `CPSimpleTypesetter` breaks lines greedily: it fills each line as far as it fits, as Cocoa does, and then spreads the spare width of each wrapped line evenly over that line's spaces. This naive algorithm does not and cannot produce the quality that modern typesetting expects. It decides each line alone, so word spacing varies widely from line to line, and loose lines are common. Quality needs paragraph-wide line breaking in the manner of Knuth-Plass, as Typst also uses, with language-aware hyphenation. Cappuccino measures and lays out text itself, so this belongs in the typesetter, as its only behaviour, with no setting for users or developers.

## Planned additions to the app

- Fonts through `CPFontManager` and `CPFontPanel`.
- RTF reading and writing.
- Images in text: dropping image files, and the image formats in RTF and Markdown.
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
- The ruler: markers follow the paragraph at the selection; first line, head and right indents change the layout as shown; clicking adds a tab stop, and dragging moves or removes one; the Control-click menu changes a tab stop's type; the ruler's zero lines up with the start of the text, and markers at 0 are fully visible.
- Text stays inside the visible width, with Cocoa's 5-point line fragment padding.
- Tab characters: the Tab key inserts a tab in the text view, and left, centre, right and decimal tab stops align their columns.
- Format > Text > Copy Ruler and Paste Ruler apply one paragraph's indents and tab stops to others.
- Format > Font > Baseline: superscript, subscript, raised and lowered baselines lay out correctly, and Use Default restores the text, for an exact or a wider selection.
- Format > Text > Justify: wrapped lines fill the width between the indents, with the spare width spread over the spaces; the last line of a paragraph stays left aligned. Centred text is centred between the indents, and spaces at the end of a wrapped line hang outside the alignment.
- Format > Font > Copy Style and Paste Style: the style of the first character of the selection is applied to the whole target selection, which keeps its paragraph style.
- Format > List: bulleted and numbered lists, applied to one or several paragraphs and removed with None. Return starts the next item and keeps the item's text style; Return in an empty item ends the list. Tab at the start of an item nests it, and Shift-Tab returns it. Delete at the start of an item's text removes it from the list. The items are numbered again after each change.
- Format > Text > Copy Ruler and Paste Ruler with lists: pasting adds or removes list markers, on one or several paragraphs, and a pasted item joins the neighbouring list.
- Typing at the end of styled text, and the font panel, use the style of the character before the insertion point.
- Edit > Copy, Cut and Paste from the menu: plain text moves to and from other applications through the system clipboard; text copied and pasted within the application keeps its style. Command-V pastes text copied in another application, not an earlier copy within the application.
- Edit > Insert Image…: a JPEG or PNG image is inserted inside the text and at the end of the text.
- A wide image fits the text width, and scales with the window without growing beyond its natural size. At the end of the text it is not clipped, and the scroll bars follow it.
- Format > Font > Bigger and Smaller (Command-+ and Command--) without a selection change the size of the text typed next, step by step, also in a blank document.
- Edit > Insert Table Example: the sample table appears between the surrounding sentences, with its header row and its bold and italic cells.
- Copy and paste within TextEditor with Command-C and Command-V, in one document and between documents: images, tables, including text edited in their cells, and lists are kept.
- Table cells can be edited, as a first pass.
- Builds with both the legacy toolchain and capp-build.
