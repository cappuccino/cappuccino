/*
 * FileExecutableSearch.js
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

var FileExecutableSearchesForPaths = [{ }, { }];

function FileExecutableSearch(/*String*/ aPath, /*BOOL*/ isLocal)
{
    if (!FILE.isAbsolute(aPath) && isLocal)
        throw "Local searches cannot be relative: " + aPath;

    var existingSearch = FileExecutableSearchesForPaths[isLocal ? 1 : 0][aPath];

    if (existingSearch)
        return existingSearch;

    FileExecutableSearchesForPaths[isLocal ? 1 : 0][aPath] = this;
    
    this._UID = generateObjectUID();
    this._isComplete = NO;
    this._eventDispatcher = new EventDispatcher(this);
    this._path = aPath;

    this._result = NULL;

    var self = this;

    function completed(/*String*/ aStaticResourceNode)
    {
        if (!aStaticResourceNode)
            throw new Error("Could not load file at " + aPath);

        self._result = new FileExecutable(aStaticResourceNode.path());
        self._isComplete = YES;

        self._eventDispatcher.dispatchEvent(
        {
            type:"complete",
            fileExecutableSearch:self
        });
    }

    if (isLocal)
        rootNode.resolveSubPath(aPath, StaticResourceNode.FileType, completed);
    else
        StaticResourceNode.resolveStandardNodeAtPath(aPath, completed);
}

FileExecutableSearch.prototype.path = function()
{
    return this._path;
}

FileExecutableSearch.prototype.result = function()
{
    return this._result;
}

FileExecutableSearch.prototype.UID = function()
{
    return this._UID;
}

FileExecutableSearch.prototype.isComplete = function()
{
    return this._isComplete;
}

FileExecutableSearch.prototype.result = function()
{
    return this._result;
}

FileExecutableSearch.prototype.addEventListener = function(/*String*/ anEventName, /*Function*/ aListener)
{
    this._eventDispatcher.addEventListener(anEventName, aListener);
}

FileExecutableSearch.prototype.removeEventListener = function(/*String*/ anEventName, /*Function*/ aListener)
{
    this._eventDispatcher.removeEventListener(anEventName, aListener);
}
