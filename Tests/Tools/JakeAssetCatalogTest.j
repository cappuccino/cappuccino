/*
 *  JakeAssetCatalogTest.j
 *  Tools
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

var fs = require("fs"),
    os = require("os"),
    path = require("path"),
    assetCatalog = require(path.join(process.cwd(), "Jake", "assetcatalog.js"));

function JakeAssetCatalogTestWriteJSON(aPath, anObject)
{
    fs.mkdirSync(path.dirname(aPath), { recursive: true });
    fs.writeFileSync(aPath, JSON.stringify(anObject), { encoding: "utf8" });
}

function JakeAssetCatalogTestWriteFile(aPath)
{
    fs.mkdirSync(path.dirname(aPath), { recursive: true });
    fs.writeFileSync(aPath, "image", { encoding: "utf8" });
}

function JakeAssetCatalogTestColor(anIdiom, aRed)
{
    return { idiom: anIdiom, color: { "color-space": "srgb", components: { red: aRed, green: "0.000", blue: "0.000", alpha: "1.000" } } };
}

@implementation JakeAssetCatalogTest : OJTestCase
{
    CPString    _directory;
    CPString    _catalog;
}

/*
    Each test builds its catalog in a new temporary directory.
*/
- (void)setUp
{
    _directory = fs.mkdtempSync(path.join(os.tmpdir(), "JakeAssetCatalogTest-"));
    _catalog = path.join(_directory, "Resources", "Assets.xcassets");

    JakeAssetCatalogTestWriteJSON(path.join(_catalog, "Contents.json"), { info: { author: "xcode", version: 1 } });
}

- (void)tearDown
{
    fs.rmSync(_directory, { recursive: true, force: true });
}

/*
    Compiles the test catalog with resource paths relative to the Resources directory.
*/
- (JSObject)compile
{
    var resourcesPrefixLength = path.join(_directory, "Resources").length;

    return assetCatalog.compileAssetCatalogs([_catalog], function(anImagePath)
    {
        return anImagePath.substring(resourcesPrefixLength).replace(/^[\\/]+/, "");
    });
}

- (void)writeLogoImageSet
{
    var imageSet = path.join(_catalog, "Logo.imageset");

    JakeAssetCatalogTestWriteJSON(path.join(imageSet, "Contents.json"), {
        images: [
            { idiom: "universal", filename: "logo.png", scale: "1x" },
            { idiom: "universal", filename: "logo@2x.png", scale: "2x" },
            { idiom: "universal", scale: "3x" },
            { idiom: "iphone", filename: "logo-phone.png", scale: "2x" }
        ],
        properties: { "template-rendering-intent": "template" }
    });
    JakeAssetCatalogTestWriteFile(path.join(imageSet, "logo.png"));
    JakeAssetCatalogTestWriteFile(path.join(imageSet, "logo@2x.png"));
    JakeAssetCatalogTestWriteFile(path.join(imageSet, "logo-phone.png"));
}

- (void)testAColorSetKeepsTheEntriesForMacAndUniversalIdioms
{
    JakeAssetCatalogTestWriteJSON(path.join(_catalog, "Background.colorset", "Contents.json"), {
        colors: [JakeAssetCatalogTestColor("universal", "1.000"), JakeAssetCatalogTestColor("mac", "0.500"), JakeAssetCatalogTestColor("iphone", "0.250")]
    });

    var colors = [self compile].table.colors;

    [self assert:["Background"] equals:Object.keys(colors)];
    [self assert:2 equals:colors.Background.length];
    [self assert:"universal" equals:colors.Background[0].idiom];
    [self assert:"mac" equals:colors.Background[1].idiom];
}

- (void)testAnImageSetNamesItsFilesByResourcePath
{
    [self writeLogoImageSet];

    var logo = [self compile].table.images.Logo;

    [self assert:3 equals:logo.images.length];
    [self assert:"Assets.xcassets/Logo.imageset/logo.png" equals:logo.images[0].filename];
    [self assert:"Assets.xcassets/Logo.imageset/logo@2x.png" equals:logo.images[1].filename];
    [self assertFalse:logo.images[2].hasOwnProperty("filename") message:"an empty slot stays without file"];
    [self assert:"template" equals:logo.properties["template-rendering-intent"]];
}

- (void)testTheCompilationListsImageFilesAndSources
{
    [self writeLogoImageSet];

    var compilation = [self compile],
        imageSet = path.join(_catalog, "Logo.imageset");

    [self assert:[path.join(imageSet, "logo.png"), path.join(imageSet, "logo@2x.png")] equals:compilation.imageFiles];
    [self assert:[path.join(_catalog, "Contents.json"), path.join(imageSet, "Contents.json")] equals:compilation.sourceFiles];
}

- (void)testAFileThatTwoEntriesNameIsCopiedOnce
{
    var imageSet = path.join(_catalog, "Mark.imageset");

    JakeAssetCatalogTestWriteJSON(path.join(imageSet, "Contents.json"), {
        images: [
            { idiom: "universal", filename: "mark.png", scale: "1x" },
            { idiom: "mac", filename: "mark.png", scale: "1x" }
        ]
    });
    JakeAssetCatalogTestWriteFile(path.join(imageSet, "mark.png"));

    var compilation = [self compile];

    [self assert:2 equals:compilation.table.images.Mark.images.length];
    [self assert:[path.join(imageSet, "mark.png")] equals:compilation.imageFiles];
}

- (void)testANamespaceFolderPrefixesTheNamesOfItsAssets
{
    JakeAssetCatalogTestWriteJSON(path.join(_catalog, "Icons", "Contents.json"), { properties: { "provides-namespace": true } });
    JakeAssetCatalogTestWriteJSON(path.join(_catalog, "Icons", "Add.colorset", "Contents.json"), { colors: [JakeAssetCatalogTestColor("universal", "1.000")] });
    JakeAssetCatalogTestWriteJSON(path.join(_catalog, "Plain", "Remove.colorset", "Contents.json"), { colors: [JakeAssetCatalogTestColor("universal", "1.000")] });

    [self assert:["Icons/Add", "Remove"] equals:Object.keys([self compile].table.colors).sort()];
}

- (void)testTwoAssetsOfOneKindAndNameStopTheBuild
{
    JakeAssetCatalogTestWriteJSON(path.join(_catalog, "Accent.colorset", "Contents.json"), { colors: [JakeAssetCatalogTestColor("universal", "1.000")] });
    JakeAssetCatalogTestWriteJSON(path.join(_catalog, "Plain", "Accent.colorset", "Contents.json"), { colors: [JakeAssetCatalogTestColor("universal", "0.500")] });

    [self assertThrows:function()
    {
        [self compile];
    }];
}

- (void)testAColorAndAnImageMayShareAName
{
    JakeAssetCatalogTestWriteJSON(path.join(_catalog, "Accent.colorset", "Contents.json"), { colors: [JakeAssetCatalogTestColor("universal", "1.000")] });
    JakeAssetCatalogTestWriteJSON(path.join(_catalog, "Accent.imageset", "Contents.json"), { images: [] });

    var table = [self compile].table;

    [self assertTrue:table.colors.hasOwnProperty("Accent")];
    [self assertTrue:table.images.hasOwnProperty("Accent")];
}

- (void)testAMissingImageFileStopsTheBuild
{
    JakeAssetCatalogTestWriteJSON(path.join(_catalog, "Logo.imageset", "Contents.json"), { images: [{ idiom: "universal", filename: "missing.png" }] });

    [self assertThrows:function()
    {
        [self compile];
    }];
}

- (void)testAnAssetWithoutContentsStopsTheBuild
{
    fs.mkdirSync(path.join(_catalog, "Empty.colorset"), { recursive: true });

    [self assertThrows:function()
    {
        [self compile];
    }];
}

- (void)testAnUnsupportedAssetKindGivesAWarning
{
    JakeAssetCatalogTestWriteJSON(path.join(_catalog, "AppIcon.appiconset", "Contents.json"), { images: [] });

    var compilation = [self compile];

    [self assert:1 equals:compilation.warnings.length];
    [self assert:[] equals:Object.keys(compilation.table.images)];
}

- (void)testTheCatalogPathOfAResource
{
    [self assert:"Resources/Assets.xcassets" equals:assetCatalog.assetCatalogPathOf("Resources/Assets.xcassets/Logo.imageset/logo.png")];
    [self assert:"Resources/Assets.xcassets" equals:assetCatalog.assetCatalogPathOf("Resources/Assets.xcassets")];
    [self assertNull:assetCatalog.assetCatalogPathOf("Resources/logo.png")];
}

- (void)testADirectoryHoldsAnAssetCatalogAtAnyDepth
{
    var images = path.join(_directory, "Images"),
        icons = path.join(_directory, "Icons");

    fs.mkdirSync(path.join(images, "Shared", "Images.xcassets"), { recursive: true });
    JakeAssetCatalogTestWriteFile(path.join(icons, "icon.png"));

    [self assertTrue:assetCatalog.containsAssetCatalog(path.join(_directory, "Resources")) message:"a catalog as a direct entry"];
    [self assertTrue:assetCatalog.containsAssetCatalog(images) message:"a catalog two levels down"];
    [self assertFalse:assetCatalog.containsAssetCatalog(icons) message:"no catalog"];
}

@end
