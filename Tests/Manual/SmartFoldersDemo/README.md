# SmartFoldersDemo

Non-document-based Cappuccino integration test, built entirely in code (no cib).

Copy `index.html`, `index-debug.html` and `Jakefile` from `Tests/Manual/SmartFoldersTest`
(they are toolchain specific and need no changes apart from the title). No `Resources/`
are required: all icons and badges are drawn with `CPBezierPath`.

## Structure

| File | Role |
|---|---|
| `main.j`, `Info.plist` | entry point, `CPApplicationDelegateClass` = `AppController` |
| `AppController.j` | creates model, main menu, main window controller |
| `MainWindowController.j` | bridge window, toolbar, sidebar split view, routed actions, menu validation |
| `SourceListViewController.j` | view-based `CPOutlineView` source list, badges, drop target, button bar |
| `PeopleViewController.j` | `CPArrayController` + bound `CPTableView`, drag source, pasteboard, detail split |
| `PersonDetailViewController.j` | controls bound to `selection.*` |
| `SmartFolderEditorController.j` | sheet with `CPPredicateEditor` built from row templates |
| `NameSheetController.j` | small reusable name sheet |
| `Library.j`, `Person.j` | model, KVO observation, `CPUserDefaults` persistence, sample data |

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
12. View menu / toolbar: hide and show sidebar and detail pane; drag the sidebar resize control in the button bar.
13. File ▸ Reset Library…: alert sheet, then sample data restored.
