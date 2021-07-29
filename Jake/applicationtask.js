/*
 * Objective-J.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008-2010, 280 North, Inc.
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

var /* FILE = require("file"), */
    OS = require("os"),
    Jake = require("objj-jake"),
    BundleTask = (require("./bundletask")).BundleTask;

var fs = require("fs-extra");
var path = require("path");

function ApplicationTask(aName)
{
    BundleTask.apply(this, arguments);
    
    if (fs.existsSync("index.html"))
        this._indexFilePath = "index.html";
    else
        this._indexFilePath = null;
    if (fs.existsSync("Frameworks"))
        this._frameworksPath = "Frameworks";
    else
        this._frameworksPath = null;
    this._shouldGenerateCacheManifest = false;
}
ApplicationTask.__proto__ = BundleTask;
ApplicationTask.prototype.__proto__ = BundleTask.prototype;
ApplicationTask.prototype.packageType = function()
{
    return "APPL";
};
ApplicationTask.prototype.defineTasks = function()
{
    BundleTask.prototype.defineTasks.apply(this, arguments);
    this.defineFrameworksTask();
    this.defineIndexFileTask();
    this.defineCacheManifestTask();
};
ApplicationTask.prototype.setIndexFilePath = function(aFilePath)
{
    this._indexFilePath = aFilePath;
};
ApplicationTask.prototype.indexFilePath = function()
{
    return this._indexFilePath;
};
ApplicationTask.prototype.setFrameworksPath = function(aFrameworksPath)
{
    this._frameworksPath = aFrameworksPath;
};
ApplicationTask.prototype.frameworksPath = function()
{
    return this._frameworksPath;
};
ApplicationTask.prototype.setShouldGenerateCacheManifest = function(shouldGenerateCacheManifest)
{
    this._shouldGenerateCacheManifest = shouldGenerateCacheManifest;
};
ApplicationTask.prototype.shouldGenerateCacheManifest = function()
{
    return this._shouldGenerateCacheManifest;
};
ApplicationTask.prototype.defineFrameworksTask = function()
{
    if (!this._frameworksPath && (this.environments()).indexOf((require("./environment.js")).Browser) === -1)
        return;
    var buildPath = this.buildProductPath(),
        newFrameworks = path.join(buildPath, "Frameworks"),
        thisTask = this;
    Jake.fileCreate(newFrameworks,     function()
    {
        if (thisTask._frameworksPath === "capp")
            OS.system(["capp", "gen", "-f", "--force", buildPath]);
        else if (thisTask._frameworksPath)
        {
            if (fs.existsSync(newFrameworks))
                fs.rmSync(newFrameworks, { recursive: true });
            var sourcePath = path.join(thisTask._frameworksPath, "Source"),
                hasSource = fs.existsSync(sourcePath),
                tempPath = path.join(process.cwd(), ".__capp_Frameworks_Source__");
            if (hasSource)
                fs.moveSync(sourcePath, tempPath);
                fs.copySync(thisTask._frameworksPath, newFrameworks, { recursive: true });
            if (hasSource)
                fs.moveSync(tempPath, sourcePath);
        }    });
    this.enhance([newFrameworks]);
};
ApplicationTask.prototype.buildIndexFilePath = function()
{
    return path.join(this.buildProductPath(), path.basename(this.indexFilePath()));
};
ApplicationTask.prototype.defineIndexFileTask = function()
{
    if (!this._indexFilePath)
        return;
    var indexFilePath = this.indexFilePath(),
        buildIndexFilePath = this.buildIndexFilePath();
    Jake.filedir(buildIndexFilePath, [indexFilePath],     function()
    {
        fs.copyFileSync(indexFilePath, buildIndexFilePath);
    });
    this.enhance([buildIndexFilePath]);
};
ApplicationTask.prototype.defineCacheManifestTask = function()
{
    if (!this.shouldGenerateCacheManifest())
        return;
    var productPath = path.join(this.buildProductPath(), "");
    var indexFilePath = this.buildIndexFilePath();
    var manifestPath = path.join(productPath, "app.manifest");
    Jake.task(manifestPath,     function()
    {
        (require("../cache-manifest")).generateManifest(productPath, {index: indexFilePath});
    });
    this.enhance([manifestPath]);
};
exports.ApplicationTask = ApplicationTask;
exports.app = function(aName, aFunction)
{
    return ApplicationTask.defineTask(aName, aFunction);
};
