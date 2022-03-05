/*
 * FileExecutable.js
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

var FileExecutablesForURLStrings = { };

function FileExecutable(/*CFURL|String*/ aURL, /*Dictionary*/ aFilenameTranslateDictionary, success)
{
    aURL = makeAbsoluteURL(aURL);

    var URLString = aURL.absoluteString(),
        existingFileExecutable = FileExecutablesForURLStrings[URLString];

    if (existingFileExecutable)
        return existingFileExecutable;

    FileExecutablesForURLStrings[URLString] = this;

    var aResource = StaticResource.resourceAtURL(aURL),
        fileContents = aResource.contents(),
        executable = NULL;

    this._hasExecuted = NO;

    // Use code if resource contains code. If not use the content of the resource
    executable = new Executable(fileContents, aResource._fileDependencies || [], aURL, aResource._function, aResource._compiler, aResource._compiler ? aFilenameTranslateDictionary : null, aResource._sourceMap);

    Executable.apply(this, [executable.code(), executable.fileDependencies(), aURL, executable._function, executable._compiler, aFilenameTranslateDictionary]);
}

exports.FileExecutable = FileExecutable;

FileExecutable.prototype = new Executable();

#ifdef COMMONJS
FileExecutable.allFileExecutables = function()
{
    var URLString,
        fileExecutables = [];

    for (URLString in FileExecutablesForURLStrings)
        if (hasOwnProperty.call(FileExecutablesForURLStrings, URLString))
            fileExecutables.push(FileExecutablesForURLStrings[URLString]);

    return fileExecutables;
}
#endif

FileExecutable.resetFileExecutables = function()
{
    FileExecutablesForURLStrings = { };
}

FileExecutable.prototype.execute = function(/*BOOL*/ shouldForce)
{
    if (this._hasExecuted && !shouldForce)
        return;

    this._hasExecuted = YES;

    return Executable.prototype.execute.call(this);
}

DISPLAY_NAME(FileExecutable.prototype.execute);

FileExecutable.prototype.hasExecuted = function()
{
    return this._hasExecuted;
}

DISPLAY_NAME(FileExecutable.prototype.hasExecuted);

