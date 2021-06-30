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

var environments = {};
function Environment(aName)
{
    this._name = aName;
    this._compilerFlags = [];
    this._spritesImages = false;
    environments[aName] = this;
}
Environment.environmentWithName = function(aName)
{
    return environments[aName];
};
Environment.prototype.name = function()
{
    return this._name;
};
Environment.prototype.toString = function()
{
    return this._name;
};
Environment.prototype.compilerFlags = function()
{
    return this._compilerFlags;
};
Environment.prototype.setCompilerFlags = function(flags)
{
    this._compilerFlags = flags;
};
Environment.prototype.setSpritesImages = function(shouldSpriteImages)
{
    this._spritesImages = !!shouldSpriteImages;
};
Environment.prototype.spritesImages = function()
{
    return this._spritesImages;
};
exports.Environment = Environment;
exports.ObjJ = new Environment("ObjJ");
var CommonJS = new Environment("CommonJS");
CommonJS.setCompilerFlags(["-DPLATFORM_COMMONJS"]);
exports.CommonJS = CommonJS;
var Browser = new Environment("Browser");
Browser.setCompilerFlags(["-DPLATFORM_BROWSER", "-DPLATFORM_DOM"]);
Browser.setSpritesImages(true);
exports.Browser = Browser;
