/*
 * CPTableView.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2009, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

/*
    CPTableView is divided by responsibility. CPTableViewCore.j holds the class, its instance
    variables, initialization and display attributes; each other file holds a category or a
    helper class, and imports CPTableViewCore.j. This file imports them all, so an import of
    CPTableView.j brings the complete class.
*/

@import "CPTableViewCore.j"
@import "CPTableRowView.j"
@import "CPTableView+Columns.j"
@import "CPTableView+Selection.j"
@import "CPTableView+Layout.j"
@import "CPTableView+Views.j"
@import "CPTableView+Drawing.j"
@import "CPTableView+Tracking.j"
@import "CPTableView+Dragging.j"
@import "CPTableView+Responder.j"
@import "CPTableView+Editing.j"
@import "CPTableView+DataSource.j"
@import "CPTableView+Delegate.j"
@import "CPTableView+Bindings.j"
@import "CPTableView+Coding.j"
@import "CPTableCellView.j"
