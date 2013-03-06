/*
 * CPFontManager.j
 * AppKit
 *
 * Created by Tom Robinson.
 * Copyright 2008, 280 North, Inc.
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

@import <Foundation/CPObject.j>

@import "CPFont.j"

@global CPApp

CPItalicFontMask                    = 1 << 0;
CPBoldFontMask                      = 1 << 1;
CPUnboldFontMask                    = 1 << 2;
CPNonStandardCharacterSetFontMask   = 1 << 3;
CPNarrowFontMask                    = 1 << 4;
CPExpandedFontMask                  = 1 << 5;
CPCondensedFontMask                 = 1 << 6;
CPSmallCapsFontMask                 = 1 << 7;
CPPosterFontMask                    = 1 << 8;
CPCompressedFontMask                = 1 << 9;
CPFixedPitchFontMask                = 1 << 10;
CPUnitalicFontMask                  = 1 << 24;


var CPSharedFontManager     = nil,
    CPFontManagerFactory    = Nil;

/*!
    @ingroup appkit
*/
@implementation CPFontManager : CPObject
{
    CPArray         _availableFonts;

    id              _target @accessors(property=target);
    SEL             _action @accessors(property=action);

    id              _delegate @accessors(property=delegate);

    CPFont          _selectedFont;
    BOOL            _multiple @accessors(getter=isMultiple, setter=setMultiple:);

    CPDictionary    _activeChange;
}

// Getting the Shared Font Manager
/*!
    Returns the application's font manager. If the font
    manager does not exist yet, it will be created.
*/
+ (CPFontManager)sharedFontManager
{
    if (!CPSharedFontManager)
        CPSharedFontManager = [[CPFontManagerFactory alloc] init];

    return CPSharedFontManager;
}

// Changing the Default Font Conversion Classes
/*!
    Sets the class that will be used to create the application's
    font manager.
*/
+ (void)setFontManagerFactory:(Class)aClass
{
    CPFontManagerFactory = aClass;
}

- (id)init
{
    if (self = [super init])
    {
        _action = @selector(changeFont:);
    }

    return self;
}

/*!
    Returns an array of the available fonts
*/
- (CPArray)availableFonts
{
    if (!_availableFonts)
    {
        _availableFonts = [];

#if PLATFORM(DOM)
        _CPFontDetectSpan = document.createElement("span");
        _CPFontDetectSpan.fontSize = "24px";
        _CPFontDetectSpan.appendChild(document.createTextNode("mmmmmmmmmml"));
        var div = document.createElement("div");
        div.style.position = "absolute";
        div.style.top = "-1000px";
        div.appendChild(_CPFontDetectSpan);
        document.getElementsByTagName("body")[0].appendChild(div);

        _CPFontDetectReferenceFonts = _CPFontDetectPickTwoDifferentFonts(["monospace", "serif", "sans-serif", "cursive"]);

        for (var i = 0; i < _CPFontDetectAllFonts.length; i++)
        {
            var available = _CPFontDetectFontAvailable(_CPFontDetectAllFonts[i]);
            if (available)
                _availableFonts.push(_CPFontDetectAllFonts[i]);
        }
#else
        // If there's no font detection, just assume all fonts are available.
        _availableFonts = _CPFontDetectAllFonts;
#endif
    }
    return _availableFonts;
}

/*!
    Returns the available fonts matching the provided name.
    @param aFontName the name of the font
*/
- (CPArray)fontWithNameIsAvailable:(CPString)aFontName
{
    return _CPFontDetectFontAvailable(aFontName);
}

- (void)setSelectedFont:(CPFont)aFont isMultiple:(BOOL)aFlag
{
    _selectedFont = aFont;
    _multiple = aFlag;

    // TODO Notify CPFontPanel when it exists.
}

- (CPFont)selectedFont
{
    return _selectedFont;
}

- (int)weightOfFont:(CPFont)aFont
{
    // TODO Weight 5 is a normal of book weight and 9 and above is bold, but it would be nice to be more
    // precise than that.
    return [aFont isBold] ? 9 : 5;
}

- (CPFontTraitMask)traitsOfFont:(CPFont)aFont
{
    return ([aFont isBold] ? CPBoldFontMask : 0) | ([aFont isItalic] ? CPItalicFontMask : 0);
}

- (CPFont)convertFont:(CPFont)aFont
{
    if (!_activeChange)
        return aFont;

    var addTraits = [_activeChange valueForKey:@"addTraits"];

    if (addTraits)
        aFont = [self convertFont:aFont toHaveTrait:addTraits];

    return aFont;
}

- (CPFont)convertFont:(CPFont)aFont toHaveTrait:(CPFontTraitMask)addTraits
{
    if (!aFont)
        return nil;

    var shouldBeBold = ([aFont isBold] || (addTraits & CPBoldFontMask)) && !(addTraits & CPUnboldFontMask),
        shouldBeItalic = ([aFont isItalic] || (addTraits & CPItalicFontMask)) && !(addTraits & CPUnitalicFontMask),
        shouldBeSize = [aFont size];

    // XXX On the current platform there will always be a bold/italic version of each font, but still leave
    // || aFont in here for future platforms.
    aFont = [CPFont _fontWithName:[aFont familyName] size:shouldBeSize bold:shouldBeBold italic:shouldBeItalic] || aFont;

    return aFont;
}

- (CPFont)convertFont:(CPFont)aFont toFace:(CPString)aTypeface
{
    if (!aFont)
        return nil;

    var shouldBeBold = [aFont isBold],
        shouldBeItalic = [aFont isItalic],
        shouldBeSize = [aFont size];

    aFont = [CPFont _fontWithName:aTypeface size:shouldBeSize bold:shouldBeBold italic:shouldBeItalic] || aFont;

    return aFont;
}

- (@action)addFontTrait:(id)sender
{
    var tag = [sender tag];
    _activeChange = tag === nil ? @{} : @{ @"addTraits": tag };

    [self sendAction];
}

- (BOOL)sendAction
{
    return [CPApp sendAction:_action to:_target from:self];
}

@end

var _CPFontDetectSpan,
    _CPFontDetectReferenceFonts,
    _CPFontDetectAllFonts = [
        /* "04b_21", "A Charming Font", "Abadi MT Condensed", "Abadi MT Condensed Extra Bold", "Abadi MT Condensed Light", "Academy Engraved LET", "Agency FB", "Alba", "Alba Matter", "Alba Super", "Algerian",*/
        "American Typewriter",
        /* "Andale Mono", "Andale Mono IPA", "Andy", */
        "Apple Chancery", "Arial", "Arial Black", "Arial Narrow", "Arial Rounded MT Bold", "Arial Unicode MS",
        /* "Avant Garde", "Avantgarde", "Baby Kruffy", "Base 02", "Baskerville", "Baskerville Old Face", "Bauhaus 93", "Beesknees ITC", "Bell MT", "Berlin Sans FB", "Berlin Sans FB Demi", "Bernard MT Condensed", "Bickley Script",*/
        "Big Caslon", "Bitstream Vera Sans", "Bitstream Vera Sans Mono", "Bitstream Vera Serif",
        /* "Blackadder ITC", "Blackletter686 BT", "Bodoni MT", "Bodoni MT Black", "Bodoni MT Condensed", "Bodoni MT Poster Compressed", "Book Antiqua", "Bookman", "Bookman Old Style", "Bradley Hand ITC", "Braggadocio", "Britannic Bold", "Broadway", "Broadway BT",*/
        "Brush Script MT",
        /* "BudHand", "CAMPBELL", "Calibri", "Californian FB", "Calisto MT", "Calligraph421 BT",*/
        "Cambria",
        /* "Candara", "Capitals",*/
        "Caslon", "Castellar", "Cataneo BT", "Centaur", "Century Gothic", "Century Schoolbook", "Century Schoolbook L",
        /* "Champignon", "Charcoal", "Charter", "Charter BT", "Chicago", "Chick", "Chiller", "ClearlyU", "Colonna MT",*/
        "Comic Sans", "Comic Sans MS", "Consolas", "Constantia", "Cooper Black", "Copperplate", "Copperplate Gothic Bold", "Copperplate Gothic Light", "Corbel", "Courier", "Courier New",
        /* "Croobie", "Curlz MT", "Desdemona", "Didot", "DomBold BT", "Edwardian Script ITC", "Engravers MT", "Eras Bold ITC", "Eras Demi ITC", "Eras Light ITC", "Eras Medium ITC", "Eurostile", "FIRSTHOME", "Fat", "Felix Titling", "Fine Hand", "Fixed", "Footlight MT Light", "Forte", "Franklin Gothic Book", "Franklin Gothic Demi", "Franklin Gothic Demi Cond", "Franklin Gothic Heavy", "Franklin Gothic Medium", "Franklin Gothic Medium Cond", "Freestyle Script", "French Script MT", "Freshbot", "Frosty",*/
        "Futura",
        /* "GENUINE", "Gadget", "Garamond",*/
        "Geneva", "Georgia", "Georgia Ref", "Geeza Pro", "Gigi", "Gill Sans", "Gill Sans MT", "Gill Sans MT Condensed", "Gill Sans MT Ext Condensed Bold", "Gill Sans Ultra Bold", "Gill Sans Ultra Bold Condensed",
        /* "GlooGun", "Gloucester MT Extra Condensed", "Goudy Old Style", "Goudy Stout", "Haettenschweiler", "Harlow Solid Italic", "Harrington",*/
        "Helvetica", "Helvetica Narrow", "Helvetica Neue", "Herculanum", "High Tower Text", "Highlight LET", "Hoefler Text", "Impact", "Imprint MT Shadow",
        /* "Informal Roman", "Jenkins v2.0", "John Handy LET", "Jokerman", "Jokerman LET", "Jokewood", "Juice ITC", "Kabel Ult BT", "Kartika", "Kino MT", "Kristen ITC", "Kunstler Script", "La Bamba LET", */
        "Lucida", "Lucida Bright", "Lucida Calligraphy", "Lucida Console", "Lucida Fax", "Lucida Grande", "Lucida Handwriting", "Lucida Sans", "Lucida Sans Typewriter", "Lucida Sans Unicode",
        /* "Luxi Mono", "Luxi Sans", "Luxi Serif", "MARKETPRO", "MS Reference Sans Serif", "MS Reference Serif", "Magneto", "Maiandra GD", */
        "Marker Felt",
        /* "Matisse ITC", "Matura MT Script Capitals", "Mead Bold", "Mekanik LET", "Mercurius Script MT Bold", */
        "Microsoft Sans Serif", "Milano LET", "Minion Web", "MisterEarl BT", "Mistral", "Monaco", "Monotype Corsiva", "Monotype.com", "New Century Schoolbook", "New York", "News Gothic MT",
        /* "Niagara Engraved", "Niagara Solid", "Nimbus Mono L", "Nimbus Roman No9 L", "OCR A Extended", "OCRB", "Odessa LET", "Old English Text MT", "OldDreadfulNo7 BT", "One Stroke Script LET", "Onyx", "Optima", "Orange LET", "Palace Script MT", "Palatino", "Palatino Linotype", */
        "Papyrus",
        /* "ParkAvenue BT", "Pepita MT", "Perpetua", "Perpetua Titling MT", "Placard Condensed", "Playbill", "Poornut", "Pristina", "Pump Demi Bold LET", "Pussycat", "Quixley LET", "Rage Italic", "Rage Italic LET", "Ravie", "Rockwell", "Rockwell Condensed", "Rockwell Extra Bold", "Ruach LET", "Runic MT Condensed", "Sand", "Script MT Bold", "Scruff LET", "Segoe UI", "Showcard Gothic", "Skia", "Smudger LET", "Snap ITC", "Square721 BT", "Staccato222 BT", "Stencil", "Sylfaen", */
        "Tahoma", "Techno", "Tempus Sans ITC", "Terminal", "Textile", "Times", "Times New Roman", "Tiranti Solid LET", "Trebuchet MS",
        /* "Tw Cen MT", "Tw Cen MT Condensed", "Tw Cen MT Condensed Extra Bold", "URW Antiqua T", "URW Bookman L", "URW Chancery L", "URW Gothic L", "URW Palladio L", "Univers", "University Roman LET", "Utopia", */
        "Verdana", "Verdana Ref", /* "Victorian LET", "Viner Hand ITC", "Vivaldi", "Vladimir Script", "Vrinda", "Weltron Urban", "Westwood LET", "Wide Latin", "Zapf Chancery", */
        "Zapfino"];

// Compare against the reference fonts. Return true if it produces a different size than at least one of them.
var _CPFontDetectFontAvailable = function(font)
{
    for (var i = 0; i < _CPFontDetectReferenceFonts.length; i++)
        if (_CPFontDetectCompareFonts(_CPFontDetectReferenceFonts[i], font))
            return true;
    return false;
};

var _CPFontDetectCache = {};

// Compares two given fonts. Returns true if they produce different sizes (i.e. fontA didn't fallback to fontB)
var _CPFontDetectCompareFonts = function(fontA, fontB)
{
    var a;
    if (_CPFontDetectCache[fontA])
        a = _CPFontDetectCache[fontA];

    else
    {
        _CPFontDetectSpan.style.fontFamily = '"' + fontA + '"';
        _CPFontDetectCache[fontA] = a = { w: _CPFontDetectSpan.offsetWidth, h: _CPFontDetectSpan.offsetHeight };
    }

    _CPFontDetectSpan.style.fontFamily = '"' + fontB + '", "' + fontA + '"';
    var bWidth = _CPFontDetectSpan.offsetWidth,
        bHeight = _CPFontDetectSpan.offsetHeight;

    return (a.w != bWidth || a.h != bHeight);
};

// Test the candidate fonts pairwise until we find two that are different. Otherwise return the first.
var _CPFontDetectPickTwoDifferentFonts = function(candidates)
{
    for (var i = 0; i < candidates.length; i++)
        for (var j = 0; j < i; j++)
            if (_CPFontDetectCompareFonts(candidates[i], candidates[j]))
                return [candidates[i], candidates[j]];
    return [candidates[0]];
};

[CPFontManager setFontManagerFactory:[CPFontManager class]];
