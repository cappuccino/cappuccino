/*
 *  assetcatalog.js
 *  Jake
 *
 *  Created by David Richardson on 2026-11-09.
 *  Copyright David Richardson 2026.
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

const fs = require("fs");
const path = require("path");

/*
    The name of the asset table in a bundle's Resources directory, which the Info.plist key
    CPAssetCatalog names (see AppKit/_CPAssetCatalog.j).
*/
const AssetCatalogResourceName = "Assets.json";

/*
    The idioms of a Cappuccino application. Entries for other devices stay out of the table.
*/
const SupportedIdioms = ["universal", "mac"];

/*
    Returns the path of the .xcassets directory that holds aPath, or the .xcassets directory
    that aPath names, or null.
*/
function assetCatalogPathOf(aPath)
{
    var match = /^(.*?\.xcassets)(?:[\\/]|$)/.exec(aPath);

    return match ? match[1] : null;
}

/*
    Returns true when the directory aDirectoryPath holds an .xcassets directory at any depth.
*/
function containsAssetCatalog(aDirectoryPath)
{
    return fs.readdirSync(aDirectoryPath).some(function(anEntryName)
    {
        var entryPath = path.join(aDirectoryPath, anEntryName);

        if (!fs.statSync(entryPath).isDirectory())
            return false;

        return path.extname(anEntryName) === ".xcassets" || containsAssetCatalog(entryPath);
    });
}

/*
    Returns the parsed Contents.json of aDirectory and records it as a source of the table, or
    null when aDirectory has none. A missing Contents.json stops the build when isRequired.
*/
function readContents(aCompilation, aDirectory, isRequired)
{
    var contentsPath = path.join(aDirectory, "Contents.json");

    if (!fs.existsSync(contentsPath))
    {
        if (isRequired)
            throw new Error("Asset catalog: " + aDirectory + " has no Contents.json");

        return null;
    }

    aCompilation.sourceFiles.push(contentsPath);

    return JSON.parse(fs.readFileSync(contentsPath, { encoding: "utf8" }));
}

function hasSupportedIdiom(anEntry)
{
    return !anEntry.idiom || SupportedIdioms.indexOf(anEntry.idiom) !== -1;
}

/*
    Records the asset aName of aKind ("colors" or "images") at aPath. Two assets of one kind
    and one name stop the build.
*/
function registerAssetName(aCompilation, aKind, aName, aPath)
{
    var origins = aCompilation.origins[aKind];

    if (origins.hasOwnProperty(aName))
        throw new Error("Asset catalog: " + origins[aName] + " and " + aPath + " have the same name, " + aName);

    origins[aName] = aPath;
}

function compileColorSet(aCompilation, aColorSetPath, aName)
{
    var contents = readContents(aCompilation, aColorSetPath, true);

    registerAssetName(aCompilation, "colors", aName, aColorSetPath);
    aCompilation.table.colors[aName] = (contents.colors || []).filter(hasSupportedIdiom);
}

/*
    Returns a copy of the image entry anEntry with its file name replaced by the file's
    resource path, and records the file for copying. An entry without a file name is an empty
    slot, which stays as it is. A missing file stops the build.
*/
function compileImageEntry(aCompilation, anImageSetPath, anEntry)
{
    var entry = Object.assign({}, anEntry);

    if (!entry.filename)
        return entry;

    var imagePath = path.join(anImageSetPath, entry.filename);

    if (!fs.existsSync(imagePath))
        throw new Error("Asset catalog: " + anImageSetPath + " names " + entry.filename + ", which does not exist");

    entry.filename = aCompilation.resourcePathForFile(imagePath);

    /*
        Two entries may name one file; the bundle copies it once.
    */
    if (aCompilation.imageFiles.indexOf(imagePath) === -1)
        aCompilation.imageFiles.push(imagePath);

    return entry;
}

function compileImageSet(aCompilation, anImageSetPath, aName)
{
    var contents = readContents(aCompilation, anImageSetPath, true),
        entries = (contents.images || []).filter(hasSupportedIdiom);

    registerAssetName(aCompilation, "images", aName, anImageSetPath);

    aCompilation.table.images[aName] = {
        properties: contents.properties || {},
        images: entries.map(function(anEntry)
        {
            return compileImageEntry(aCompilation, anImageSetPath, anEntry);
        })
    };
}

/*
    Compiles the assets in aFolderPath. A directory with an extension is an asset of that kind;
    a directory without one is a folder, which adds its name to the names of its assets when its
    Contents.json sets "provides-namespace".
*/
function compileFolder(aCompilation, aFolderPath, aNamePrefix)
{
    fs.readdirSync(aFolderPath).sort().forEach(function(anEntryName)
    {
        var entryPath = path.join(aFolderPath, anEntryName);

        if (!fs.statSync(entryPath).isDirectory())
            return;

        var extension = path.extname(anEntryName),
            assetName = aNamePrefix + path.basename(anEntryName, extension);

        switch (extension)
        {
            case "":
                var contents = readContents(aCompilation, entryPath, false),
                    providesNamespace = !!(contents && contents.properties && contents.properties["provides-namespace"]);

                compileFolder(aCompilation, entryPath, providesNamespace ? aNamePrefix + anEntryName + "/" : aNamePrefix);
                break;

            case ".colorset":
                compileColorSet(aCompilation, entryPath, assetName);
                break;

            case ".imageset":
                compileImageSet(aCompilation, entryPath, assetName);
                break;

            default:
                aCompilation.warnings.push("Asset catalog: skipping " + entryPath + "; Cappuccino supports colour sets and image sets only");
        }
    });
}

/*
    Compiles the .xcassets directories catalogPaths into one asset table (see
    AppKit/_CPAssetCatalog.j). resourcePathForFile returns the path of an image file relative to
    the bundle's Resources directory.

    Returns:
    - table: { version: 1, colors: { name: [entry] }, images: { name: { properties, images: [entry] } } },
      the Contents.json entries of each asset for the supported idioms, with image file names
      replaced by resource paths;
    - imageFiles: the image files that the bundle copies;
    - sourceFiles: every Contents.json that the table comes from;
    - warnings: one for each asset of a kind that the table does not hold.

    Throws an Error when two assets of one kind share a name, when an asset has no
    Contents.json, or when an image entry names a missing file.
*/
function compileAssetCatalogs(catalogPaths, resourcePathForFile)
{
    var compilation = {
            table: { version: 1, colors: {}, images: {} },
            imageFiles: [],
            sourceFiles: [],
            warnings: [],
            origins: { colors: {}, images: {} },
            resourcePathForFile: resourcePathForFile
        };

    catalogPaths.forEach(function(aCatalogPath)
    {
        readContents(compilation, aCatalogPath, false);
        compileFolder(compilation, aCatalogPath, "");
    });

    return {
        table: compilation.table,
        imageFiles: compilation.imageFiles,
        sourceFiles: compilation.sourceFiles,
        warnings: compilation.warnings
    };
}

exports.AssetCatalogResourceName = AssetCatalogResourceName;
exports.assetCatalogPathOf = assetCatalogPathOf;
exports.containsAssetCatalog = containsAssetCatalog;
exports.compileAssetCatalogs = compileAssetCatalogs;
