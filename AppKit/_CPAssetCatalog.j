/*
 *  _CPAssetCatalog.j
 *  AppKit
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

@import <Foundation/CPBundle.j>
@import <Foundation/CPObject.j>
@import <Foundation/CPURL.j>

@import "CPAppearance.j"

/*
    CPColor.j and CPImage.j import this file, so it refers to their classes by name only and
    imports neither.
*/
@class CPColor
@class CPImage
@class _CPAssetColor
@class _CPAssetImage
@class _CPScaledImage

@global window

/*
    The asset catalog of a bundle. The build compiles the bundle's .xcassets directories into
    one table, a JSON resource that the Info.plist key CPAssetCatalog names. The table keeps
    the vocabulary of Apple's asset catalogs:

        {
            "version": 1,
            "colors": { "<name>": [ <colour entry>, ... ] },
            "images": { "<name>": { "properties": { ... }, "images": [ <image entry>, ... ] } }
        }

    A colour entry and an image entry are entries of the asset's Contents.json. An image
    entry's "filename" is the path of the image resource, relative to the bundle's Resources
    directory.
*/

var _CPAssetCatalogInfoKey = @"CPAssetCatalog",
    _CPAssetCatalogs = {},

    /*
        The components of a Display P3 colour, linear, convert to linear sRGB by this matrix.
        Both spaces use the D65 white point and the sRGB transfer function.
    */
    _CPDisplayP3ToSRGBMatrix = [
        [ 1.2249401, -0.2249404,  0.0000000],
        [-0.0420569,  1.0420571,  0.0000000],
        [-0.0196376, -0.0786361,  1.0982735]
    ];

/// @cond IGNORE

/*
    Returns the luminosity ("light" or "dark") and contrast ("normal" or "high") of the
    appearance named aName. A vibrant appearance and light content take the luminosity of their
    lightness.
*/
function _CPAssetTraitsForAppearanceName(aName)
{
    switch (aName)
    {
        case CPAppearanceNameDarkAqua:
        case CPAppearanceNameVibrantDark:
            return { luminosity: "dark", contrast: "normal" };

        case CPAppearanceNameAccessibilityHighContrastAqua:
        case CPAppearanceNameAccessibilityHighContrastVibrantLight:
            return { luminosity: "light", contrast: "high" };

        case CPAppearanceNameAccessibilityHighContrastDarkAqua:
        case CPAppearanceNameAccessibilityHighContrastVibrantDark:
            return { luminosity: "dark", contrast: "high" };

        default:
            return { luminosity: "light", contrast: "normal" };
    }
}

/*
    Returns the luminosity ("light", "dark" or "any") and contrast ("normal" or "high") that
    the "appearances" of anEntry name. An entry without luminosity applies to any luminosity,
    and an entry without contrast applies to normal contrast.
*/
function _CPAssetTraitsOfEntry(anEntry)
{
    var traits = { luminosity: "any", contrast: "normal" },
        appearances = anEntry.appearances || [];

    for (var i = 0, count = appearances.length; i < count; i++)
    {
        var appearance = appearances[i];

        if (appearance.appearance === "luminosity")
            traits.luminosity = appearance.value;
        else if (appearance.appearance === "contrast")
            traits.contrast = appearance.value;
    }

    return traits;
}

/*
    Returns the entries of someEntries that best suit the appearance named aName, or an empty
    array. The order of preference: the exact luminosity and contrast, then the same luminosity
    at normal contrast, then any luminosity at the same contrast, then any luminosity at normal
    contrast.
*/
function _CPAssetEntriesForAppearanceName(someEntries, aName)
{
    var wanted = _CPAssetTraitsForAppearanceName(aName),
        candidates = [[wanted.luminosity, wanted.contrast]];

    if (wanted.contrast !== "normal")
        candidates.push([wanted.luminosity, "normal"]);

    candidates.push(["any", wanted.contrast]);

    if (wanted.contrast !== "normal")
        candidates.push(["any", "normal"]);

    for (var i = 0, count = candidates.length; i < count; i++)
    {
        var matches = [];

        for (var j = 0, entryCount = someEntries.length; j < entryCount; j++)
        {
            var entry = someEntries[j],
                traits = _CPAssetTraitsOfEntry(entry);

            if (traits.luminosity === candidates[i][0] && traits.contrast === candidates[i][1])
                matches.push(entry);
        }

        if (matches.length)
            return matches;
    }

    return [];
}

/*
    Returns the entries of someEntries for the most specific idiom: "mac" before "universal".
*/
function _CPAssetEntriesForIdiom(someEntries)
{
    var macEntries = someEntries.filter(function(anEntry) { return anEntry.idiom === "mac"; });

    return macEntries.length ? macEntries : someEntries;
}

/*
    Returns the entries of someEntries for the display gamut: entries for wantedGamut
    ("sRGB" or "display-P3") or for any gamut, preferring the first.
*/
function _CPAssetEntriesForGamut(someEntries, wantedGamut)
{
    var gamutEntries = someEntries.filter(function(anEntry) { return anEntry["display-gamut"] === wantedGamut; });

    if (gamutEntries.length)
        return gamutEntries;

    var anyGamutEntries = someEntries.filter(function(anEntry) { return !anEntry["display-gamut"]; });

    return anyGamutEntries.length ? anyGamutEntries : someEntries;
}

/*
    Returns the value of a colour component as Xcode writes it: floating point ("0.502"),
    8-bit hexadecimal ("0x80") or an 8-bit integer ("128"). An alpha component without a
    decimal point is an 8-bit integer only when it exceeds 1.
*/
function _CPAssetComponentValue(aComponent, isAlpha)
{
    if (aComponent === undefined || aComponent === null)
        return isAlpha ? 1.0 : 0.0;

    if (typeof aComponent === "number")
        return aComponent;

    var string = String(aComponent).trim();

    if (/^[-+]?0x/i.test(string))
        return parseInt(string, 16) / 255.0;

    var value = parseFloat(string);

    if (string.indexOf(".") === -1 && (!isAlpha || value > 1))
        return value / 255.0;

    return value;
}

function _CPSRGBToLinear(aValue)
{
    var magnitude = Math.abs(aValue),
        linear = magnitude <= 0.04045 ? magnitude / 12.92 : Math.pow((magnitude + 0.055) / 1.055, 2.4);

    return aValue < 0 ? -linear : linear;
}

function _CPLinearToSRGB(aValue)
{
    var magnitude = Math.abs(aValue),
        encoded = magnitude <= 0.0031308 ? magnitude * 12.92 : 1.055 * Math.pow(magnitude, 1 / 2.4) - 0.055;

    return aValue < 0 ? -encoded : encoded;
}

function _CPClampComponent(aValue)
{
    return MIN(1.0, MAX(0.0, aValue));
}

/*
    Returns the CPColor for the "color" object of a colour entry, or nil when the entry names
    an unknown colour space or an unknown System catalog colour.
*/
function _CPAssetColorFromDescription(aDescription)
{
    if (aDescription.reference)
    {
        var referencedColor = [CPColor colorWithCatalogName:@"System" colorName:aDescription.reference];

        if (!referencedColor)
            CPLog.warn("Asset catalog: unknown System colour \"" + aDescription.reference + "\"");

        return referencedColor;
    }

    var components = aDescription.components || {},
        colorSpace = aDescription["color-space"] || "srgb",
        alpha = _CPClampComponent(_CPAssetComponentValue(components.alpha, YES));

    switch (colorSpace)
    {
        case "srgb":
        case "extended-srgb":
            return [CPColor colorWithSRGBRed:_CPClampComponent(_CPAssetComponentValue(components.red, NO))
                                       green:_CPClampComponent(_CPAssetComponentValue(components.green, NO))
                                        blue:_CPClampComponent(_CPAssetComponentValue(components.blue, NO))
                                       alpha:alpha];

        case "extended-linear-srgb":
            return [CPColor colorWithSRGBRed:_CPClampComponent(_CPLinearToSRGB(_CPAssetComponentValue(components.red, NO)))
                                       green:_CPClampComponent(_CPLinearToSRGB(_CPAssetComponentValue(components.green, NO)))
                                        blue:_CPClampComponent(_CPLinearToSRGB(_CPAssetComponentValue(components.blue, NO)))
                                       alpha:alpha];

        case "display-p3":
            var linear = [_CPSRGBToLinear(_CPAssetComponentValue(components.red, NO)),
                          _CPSRGBToLinear(_CPAssetComponentValue(components.green, NO)),
                          _CPSRGBToLinear(_CPAssetComponentValue(components.blue, NO))],
                srgb = _CPDisplayP3ToSRGBMatrix.map(function(aRow)
                {
                    return _CPClampComponent(_CPLinearToSRGB(aRow[0] * linear[0] + aRow[1] * linear[1] + aRow[2] * linear[2]));
                });

            return [CPColor colorWithSRGBRed:srgb[0] green:srgb[1] blue:srgb[2] alpha:alpha];

        case "gray-gamma-22":
        case "extended-gray":
            /*
                Gray components carry gamma 2.2; the sRGB value encodes the same linear
                luminance.
            */
            var white = _CPAssetComponentValue(components.white, NO),
                linearWhite = (white < 0 ? -1 : 1) * Math.pow(Math.abs(white), 2.2),
                srgbWhite = _CPClampComponent(_CPLinearToSRGB(linearWhite));

            return [CPColor colorWithSRGBRed:srgbWhite green:srgbWhite blue:srgbWhite alpha:alpha];

        default:
            CPLog.warn("Asset catalog: unsupported colour space \"" + colorSpace + "\"");
            return nil;
    }
}

/*
    Returns the scale of an image entry ("2x" gives 2), or nil for a single-scale entry.
*/
function _CPAssetScaleOfEntry(anEntry)
{
    return anEntry.scale ? parseFloat(anEntry.scale) : nil;
}

/*
    Returns the entry of someEntries for aDisplayScale: a single-scale entry when there is one,
    else the entry of the smallest scale not below aDisplayScale, else the entry of the largest
    scale.
*/
function _CPAssetEntryForDisplayScale(someEntries, aDisplayScale)
{
    var bestAbove = nil,
        largest = nil;

    for (var i = 0, count = someEntries.length; i < count; i++)
    {
        var entry = someEntries[i],
            scale = _CPAssetScaleOfEntry(entry);

        if (scale === nil)
            return entry;

        if (scale >= aDisplayScale && (!bestAbove || scale < _CPAssetScaleOfEntry(bestAbove)))
            bestAbove = entry;

        if (!largest || scale > _CPAssetScaleOfEntry(largest))
            largest = entry;
    }

    return bestAbove || largest;
}

function _CPAssetDisplayScale()
{
    return (typeof window !== "undefined" && window.devicePixelRatio) || 1;
}

function _CPAssetDisplayGamut()
{
    if (typeof window !== "undefined" && window.matchMedia && window.matchMedia("(color-gamut: p3)").matches)
        return "display-P3";

    return "sRGB";
}

/// @endcond


@implementation _CPAssetCatalog : CPObject
{
    CPBundle    _bundle @accessors(getter=bundle);
    JSObject    _colorEntries;
    JSObject    _imageAssets;
    JSObject    _colors;
    JSObject    _images;
}

/*
    Returns the asset catalog of aBundle (the main bundle when aBundle is nil), or nil when the
    bundle has none.
*/
+ (_CPAssetCatalog)catalogForBundle:(CPBundle)aBundle
{
    var bundle = aBundle || [CPBundle mainBundle],
        key = [bundle bundlePath];

    if (_CPAssetCatalogs.hasOwnProperty(key))
        return _CPAssetCatalogs[key];

    var catalog = [self _catalogFromBundle:bundle];

    /*
        A bundle that has not finished loading may still gain its Info.plist, so only a loaded
        bundle without a catalog is remembered as having none.
    */
    if (catalog || [bundle isLoaded])
        _CPAssetCatalogs[key] = catalog;

    return catalog;
}

/*
    Makes aCatalog the asset catalog of aBundle; a nil catalog makes the bundle load its own
    catalog again on next use.
*/
+ (void)_setCatalog:(_CPAssetCatalog)aCatalog forBundle:(CPBundle)aBundle
{
    var key = [(aBundle || [CPBundle mainBundle]) bundlePath];

    if (aCatalog)
        _CPAssetCatalogs[key] = aCatalog;
    else
        delete _CPAssetCatalogs[key];
}

+ (_CPAssetCatalog)_catalogFromBundle:(CPBundle)aBundle
{
    var resourceName = [aBundle objectForInfoDictionaryKey:_CPAssetCatalogInfoKey];

    if (!resourceName)
        return nil;

    var data = [[CPURL URLWithString:[aBundle pathForResource:resourceName]] staticResourceData];

    if (!data)
    {
        CPLog.warn("Asset catalog: bundle " + [aBundle bundlePath] + " names \"" + resourceName + "\", which is not in its static file");
        return nil;
    }

    return [[self alloc] _initWithContents:JSON.parse([data rawString]) bundle:aBundle];
}

/*
    Initializes the catalog of aBundle with the compiled table someContents.
*/
- (id)_initWithContents:(JSObject)someContents bundle:(CPBundle)aBundle
{
    self = [super init];

    if (self)
    {
        _bundle = aBundle;
        _colorEntries = someContents.colors || {};
        _imageAssets = someContents.images || {};
        _colors = {};
        _images = {};
    }

    return self;
}

// MARK: Colours

/*
    Returns the shared asset colour named aName, or nil when the catalog has no colour of that
    name.
*/
- (CPColor)colorNamed:(CPString)aName
{
    if (!_colorEntries.hasOwnProperty(aName))
        return nil;

    var color = _colors[aName];

    if (!color)
        color = _colors[aName] = [[_CPAssetColor alloc] _initWithAssetName:aName catalog:self];

    return color;
}

/*
    Returns the value of the colour named aName in anAppearance, or nil when no entry suits the
    appearance. The catalog keeps each entry's colour once made.
*/
- (CPColor)_colorValueForAssetNamed:(CPString)aName appearance:(CPAppearance)anAppearance
{
    var entries = _CPAssetEntriesForAppearanceName(_colorEntries[aName] || [], [anAppearance name]);

    /*
        CPColor holds sRGB values only, so an entry for the sRGB gamut serves better than an
        entry for Display P3 converted to sRGB.
    */
    entries = _CPAssetEntriesForGamut(_CPAssetEntriesForIdiom(entries), "sRGB");

    var entry = entries[0];

    if (!entry)
        return nil;

    if (!entry.hasOwnProperty("_CPColorValue"))
        entry._CPColorValue = entry.color ? _CPAssetColorFromDescription(entry.color) : nil;

    return entry._CPColorValue;
}

// MARK: Images

/*
    Returns the shared asset image named aName, or nil when the catalog has no image of that
    name.
*/
- (CPImage)imageNamed:(CPString)aName
{
    if (!_imageAssets.hasOwnProperty(aName))
        return nil;

    var image = _images[aName];

    if (!image)
        image = _images[aName] = [[_CPAssetImage alloc] _initWithAssetName:aName catalog:self];

    return image;
}

/*
    Returns the properties of the image named aName, such as "template-rendering-intent".
*/
- (JSObject)_propertiesOfImageNamed:(CPString)aName
{
    var asset = _imageAssets[aName];

    return (asset && asset.properties) || {};
}

/*
    Returns the image named aName for anAppearance and the display scale, or nil when no entry
    suits the appearance. The catalog keeps each entry's image once made.
*/
- (CPImage)_imageValueForAssetNamed:(CPString)aName appearance:(CPAppearance)anAppearance
{
    var asset = _imageAssets[aName],
        entries = ((asset && asset.images) || []).filter(function(anEntry) { return !!anEntry.filename; });

    entries = _CPAssetEntriesForAppearanceName(entries, [anAppearance name]);
    entries = _CPAssetEntriesForGamut(_CPAssetEntriesForIdiom(entries), _CPAssetDisplayGamut());

    var entry = _CPAssetEntryForDisplayScale(entries, _CPAssetDisplayScale());

    if (!entry)
        return nil;

    if (!entry._CPImageValue)
        entry._CPImageValue = [[_CPScaledImage alloc] _initWithContentsOfFile:[_bundle pathForResource:entry.filename]
                                                                        scale:_CPAssetScaleOfEntry(entry) || 1.0];

    return entry._CPImageValue;
}

@end

