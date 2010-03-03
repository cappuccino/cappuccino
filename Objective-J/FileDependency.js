/*
 * FileDependency.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
 * Copyright 2010, 280 North, Inc.
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

function FileDependency(/*CFURL*/ aURL, /*BOOL*/ isLocal)
{
    this._URL = aURL;
    this._isLocal = isLocal;
}

exports.FileDependency = FileDependency;

FileDependency.prototype.URL = function()
{
    return this._URL;
}

FileDependency.prototype.isLocal = function()
{
    return this._isLocal;
}

FileDependency.prototype.toMarkedString = function()
{
    var URLString = this.URL().absoluteString();

    return  (this.isLocal() ? MARKER_IMPORT_LOCAL : MARKER_IMPORT_STD) + ";" +
            URLString.length + ";" + URLString;
}

FileDependency.prototype.toString = function()
{
    return (this.isLocal() ? "LOCAL: " : "STD: ") + this.URL();
}
