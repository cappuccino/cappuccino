Run this application with the current master, and note the following bugs:

- When you click on any item, there are two selection change notifications instead of one.

- If you compare the order of the notifications with Cocoa, they are slightly different.

- The right hand table is configured to allow an empty selection. If you click in the
empty area below the names, there is an empty selection notification, but then the
the current selection changes to the first item and generates another notification.

- If you select multiple items on the left, there is an error. This is a bug that will
have to be fixed in a later commit.

If you apply the changes in these commits, the first three bugs are fixed.
