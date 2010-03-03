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

function FileExecutableSearch(/*CFURL*/ aURL, /*BOOL*/ isQuoted)
{
//    if (isQuoted && !aURL.protocol())
//        throw "Local searches cannot be relative: " + aPath;
    var URLString = aURL.absoluteString(),
        existingSearch = FileExecutableSearchesForPaths[isQuoted ? 1 : 0][URLString];

    if (existingSearch)
        return existingSearch;

    FileExecutableSearchesForPaths[isQuoted ? 1 : 0][URLString] = this;

    this._UID = objj_generateObjectUID();

    this._URL = aURL;
    this._isComplete = NO;
    this._eventDispatcher = new EventDispatcher(this);

    this._result = NULL;

    var self = this;

    function completed(/*String*/ aStaticResource)
    {
        if (!aStaticResource)
            throw new Error("Could not load file at " + aURL);

        self._result = new FileExecutable(aStaticResource.URL());
        self._isComplete = YES;

        self._eventDispatcher.dispatchEvent(
        {
            type:"complete",
            fileExecutableSearch:self
        });
    }

    if (isQuoted)
        StaticResource.resolveResourceAtURL(aURL, NO, completed);
    else
        StaticResource.resolveResourceAtURLSearchingIncludeURLs(aURL, completed);
}

exports.FileExecutableSearch = FileExecutableSearch;

FileExecutableSearch.prototype.URL = function()
{
    return this._URL;
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

#if DEPENDENCY_LOGGING
FileExecutableSearch.prototype.toString = function()
{
    return "<FileExecutableSearch: " + this.path() + ">";
}
#endif
