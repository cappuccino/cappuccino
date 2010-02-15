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

var FileExecutableUnloadedDependencies  = 0,
    FileExecutableLoadingDependencies   = 1,
    FileExecutableLoadedDependencies    = 2,
    FileExecutablesForPaths             = { };

function FileExecutable(/*String*/ aPath)
{
    var existingFileExecutable = FileExecutablesForPaths[aPath];

    if (existingFileExecutable)
        return existingFileExecutable;

    FileExecutablesForPaths[aPath] = this;

    var fileContents = rootResource.nodeAtSubPath(aPath).contents(),
        executable = NULL;

    if (!fileContents.match(/^@STATIC;/))
        executable = preprocess(fileContents, aPath, OBJJ_PREPROCESSOR_DEBUG_SYMBOLS);

    else
        executable = decompile(fileContents, aPath);

    Executable.apply(this, [executable.code(), executable.fileDependencies(), aPath, executable._function]);

    this._path = aPath;
    this._hasExecuted = NO;
}

FileExecutable.prototype = new Executable();

FileExecutable.prototype.execute = function(/*BOOL*/ shouldForce)
{
    if (this._hasExecuted && !shouldForce)
        return;

    this._hasExecuted = YES;

    Executable.prototype.execute.apply(this, []);
}

FileExecutable.prototype.path = function()
{
    return this._path;
}

FileExecutable.prototype.hasExecuted = function()
{
    return this._hasExecuted;
}

function decompile(/*String*/ aString, /*String*/ aPath)
{
    var stream = new MarkedStream(aString);
/*
    if (stream.version !== "1.0")
        return;
*/
    var marker = NULL,
        code = "",
        dependencies = [];

    while (marker = stream.getMarker())
    {
        var text = stream.getString();

        if (marker === MARKER_TEXT)
            code += text;

        else if (marker === MARKER_IMPORT_STD)
            dependencies.push(new FileDependency(FILE.normal(text), NO));

        else if (marker === MARKER_IMPORT_LOCAL)
            dependencies.push(new FileDependency(FILE.normal(text), YES));
    }

    return new Executable(code, dependencies, aPath);
}
/*
global.objj_executeFile = executeFile;
global.objj_importFile = importFile;
global.objj_import = importFile;
*/
exports.FileExecutable = FileExecutable;
exports.FileExecutablesForPaths = FileExecutablesForPaths;