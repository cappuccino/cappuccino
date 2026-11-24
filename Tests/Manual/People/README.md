# People

Non-document-based Cappuccino integration test, built entirely in code (no cib).

Copy `index.html`, `index-debug.html` and `Jakefile` from `Tests/Manual/SmartFoldersTest`
(they are toolchain specific and need no changes apart from the title). The toolbar glyphs
are SVG files in the asset catalog `Resources/Assets.xcassets`, each with a dark variant;
the other icons and the badges are drawn with `CPBezierPath`.

## Structure

Folders follow the parts of the application, nested where one part belongs to another. Imports
between folders are relative (`"../Library.j"`). The toolchain files (`main.j`, `Info.plist`,
`Jakefile`, `index.html`, `index-debug.html`, `Resources/`) stay at the top. Folder names have no
spaces, because the legacy toolchain does not accept them.

| File | Role |
|---|---|
| `main.j`, `Info.plist` | entry point, `CPApplicationDelegateClass` = `AppController` |
| `ApplicationLifecycle/AppController.j` | creates model, main menu, main window controller |
| `ApplicationLifecycle/Settings/SettingsWindowController.j` | settings window |
| `PrimaryInterface/MainWindow/MainWindowController.j` | bridge window, toolbar, routed actions, menu and toolbar validation |
| `PrimaryInterface/MainWindowSplitView/MainSplitViewController.j` | the window's content view controller: Navigation, Content and Detail side by side as split view items |
| `Library/Library.j`, `Library/Person.j` | model, KVO observation, `CPUserDefaults` persistence, sample data |
| `Library/Navigation/SourceListViewController.j` | view-based `CPOutlineView` source list, drop target, button bar |
| `Library/Navigation/SourceItemCell/` | outline cell view with its icon and count badge, drawn with `CPBezierPath` |
| `Library/Navigation/SmartFolderEditor/SmartFolderEditorController.j` | sheet with `CPPredicateEditor` built from row templates |
| `Library/Navigation/GroupNameSheet/NameSheetController.j` | name sheet for new and renamed groups |
| `Library/ContentViewer/PeopleViewController.j` | `CPArrayController` + bound `CPTableView`, drag source, pasteboard |
| `Library/PersonInspector/PersonDetailViewController.j` | detail column; controls bound to `representedObject.*`, which is the table's selection |

## Manual test checklist

1. Launch: sidebar shows LIBRARY / GROUPS / SMART FOLDERS with count badges; table shows 240 people.
2. Click each smart folder: table filters, status line shows "n of 240", badge equals n.
3. Double-click a smart folder: sheet opens with the stored predicate reconstructed in the editor
   (incl. nested compound and NOT). Add/remove rows: sheet resizes, match count and format update live.
4. OK: folder renamed/updated, badge updated. Cancel: nothing changes.
5. "Müller (diacritics test)" must match Müller with predicate `muller` (`[cd]`).
6. Type in the search field: filter combines with the selected folder (AND).
7. Sort by every column header; reorder and resize columns; reload: column layout restored.
8. Select people, drag onto a group: badge increases. Drag onto the GROUPS header: new group created and selected.
9. Drag groups / smart folders to reorder them within their section; reload: order persisted.
10. Edit a cell (name, salary, Mgr checkbox) and the detail pane fields: other views and badges follow;
    multi-select shows "Multiple Values"; changing Birth Date updates Age (dependent key).
11. Copy (⌘C) then Paste (⌘V): duplicated people appear selected. Delete key removes people
    (from the group only, when a group is selected).
12. The window shows three columns: sidebar, people table, detail pane. Resize the window: the table takes the
    change, the sidebar and the detail pane keep their widths. Drag both dividers; the sidebar stays between
    160 and 420 points, the detail pane does not become narrower than its fields allow. Reload: both widths and
    any hidden pane are restored (autosave).
    View menu / toolbar: hide and show sidebar and detail pane, animated; a hidden pane comes back at its
    width. Drag the sidebar resize control in the button bar.
    Toolbar items are enabled exactly when their menu items are: Edit only for a smart folder,
    New Smart Folder and New Group not while a sheet is open. In dark mode the glyphs are light.
    View ▸ Hide Toolbar hides it and the item then reads Show Toolbar.
    View ▸ Customize Toolbar… opens the customisation palette as a sheet: drag an item from the
    palette into the toolbar (a marker shows where it goes), drag a toolbar item to another place,
    drag one out of the toolbar to remove it, and drag the default set to restore it. Show sets
    Icon and Text, Icon Only or Text Only; Done closes the sheet. Reload the page: the changed
    toolbar stays (autosave). While the sheet is open, the toolbar items do not act.
    The standard Colors item opens the colour panel. In both appearances its labels, the boxes
    around the preview and the swatches, and the opacity slider's track and knob show.
13. File ▸ Reset Application…: alert sheet, then sample data, default toolbar (items, Icon and Text, regular size), sidebar width, detail pane, empty recent searches and Auto appearance restored at once, without a reload. Cancel changes nothing.
