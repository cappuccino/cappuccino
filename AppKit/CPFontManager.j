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

@import "CPControl.j"
@import "CPFont.j"
@import "CPFontDescriptor.j"

@global CPApp
@class CPFontPanel

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
    CPFontManagerFactory    = nil,
    CPFontPanelFactory      = nil;

/*
    modifyFont: sender's tag
*/
CPNoFontChangeAction    = 0;
CPViaPanelFontAction    = 1;
CPAddTraitFontAction    = 2;
CPSizeUpFontAction      = 3;
CPSizeDownFontAction    = 4;
CPHeavierFontAction     = 5;
CPLighterFontAction     = 6;
CPRemoveTraitFontAction = 7;

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

    unsigned        _fontAction;
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
/*!
    Sets the class that will be used to create the application's
    Font panel.
*/
+ (void)setFontPanelFactory:(Class)aClass
{
    CPFontPanelFactory = aClass;
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
    _activeChange = tag == nil ? @{} : @{ @"addTraits": tag };
    _fontAction = CPAddTraitFontAction;

    [self sendAction];
}

- (BOOL)sendAction
{
    return [CPApp sendAction:_action to:_target from:self];
}


/*!
    This method open the font panel, create it if necessary.
    @param sender The object that sent the message.
*/
- (CPFontPanel)fontPanel:(BOOL)createIt
{
    var panel = nil,
        panelExists = [CPFontPanelFactory sharedFontPanelExists];

    if ((panelExists) || (!panelExists && createIt))
        panel = [CPFontPanelFactory sharedFontPanel];

    return panel;
}

/*!
    Convert a font to have the specified Font traits. The font is unchanged expect for the specified Font traits.
    Using CPUnboldFontMask or CPUnitalicFontMask will respectively remove Bold and Italic traits.
    @param aFont The font to convert.
    @param fontTrait The new font traits mask.
    @result The converted font or \c aFont if the conversion failed.
*/
- (CPFont)convertFont:(CPFont)aFont toHaveTrait:(CPFontTraitMask)fontTrait
{
    var attributes = [[[aFont fontDescriptor] fontAttributes] copy],
        symbolicTrait = [[aFont fontDescriptor] symbolicTraits];

    if (fontTrait & CPBoldFontMask)
        symbolicTrait |= CPFontBoldTrait;

    if (fontTrait & CPItalicFontMask)
        symbolicTrait |= CPFontItalicTrait;

    if (fontTrait & CPUnboldFontMask) /* FIXME: this only change CPFontSymbolicTrait what about CPFontWeightTrait */
        symbolicTrait &= ~CPFontBoldTrait;

    if (fontTrait & CPUnitalicFontMask)
        symbolicTrait &= ~CPFontItalicTrait;

    if (fontTrait & CPExpandedFontMask)
        symbolicTrait |= CPFontExpandedTrait;

    if (fontTrait & CPSmallCapsFontMask)
        symbolicTrait |= CPFontSmallCapsTrait;

    if (![attributes containsKey:CPFontTraitsAttribute])
        [attributes setObject:[CPDictionary dictionaryWithObject:[CPNumber numberWithUnsignedInt:symbolicTrait]
                                                          forKey:CPFontSymbolicTrait]
                       forKey:CPFontTraitsAttribute];
    else
        [[attributes objectForKey:CPFontTraitsAttribute] setObject:[CPNumber numberWithUnsignedInt:symbolicTrait]
                                                            forKey:CPFontSymbolicTrait];

    return [[aFont class] fontWithDescriptor:[CPFontDescriptor fontDescriptorWithFontAttributes:attributes] size:0.0];
}

/*!
    Convert a font to not have the specified Font traits. The font is unchanged expect for the specified Font traits.
    @param aFont The font to convert.
    @param fontTrait The font traits mask to remove.
    @result The converted font or \c aFont if the conversion failed.
*/
- (CPFont)convertFont:(CPFont)aFont toNotHaveTrait:(CPFontTraitMask)fontTrait
{
    var attributes = [[[aFont fontDescriptor] fontAttributes] copy],
        symbolicTrait = [[aFont fontDescriptor] symbolicTraits];

    if ((fontTrait & CPBoldFontMask) || (fontTrait & CPUnboldFontMask)) /* FIXME: see convertFont:toHaveTrait: about CPFontWeightTrait */
        symbolicTrait &= ~CPFontBoldTrait;

    if ((fontTrait & CPItalicFontMask) || (fontTrait & CPUnitalicFontMask))
        symbolicTrait &= ~CPFontItalicTrait;

    if (fontTrait & CPExpandedFontMask)
        symbolicTrait &= ~CPFontExpandedTrait;

    if (fontTrait & CPSmallCapsFontMask)
        symbolicTrait &= ~CPFontSmallCapsTrait;

    if (![attributes containsKey:CPFontTraitsAttribute])
        [attributes setObject:[CPDictionary dictionaryWithObject:[CPNumber numberWithUnsignedInt:symbolicTrait]
                                                          forKey:CPFontSymbolicTrait]
                       forKey:CPFontTraitsAttribute];
    else
        [[attributes objectForKey:CPFontTraitsAttribute] setObject:[CPNumber numberWithUnsignedInt:symbolicTrait]
                                                            forKey:CPFontSymbolicTrait];

    return [[aFont class] fontWithDescriptor:[CPFontDescriptor fontDescriptorWithFontAttributes:attributes] size:0.0];
}

/*!
    Convert a font to have specified size. The font is unchanged expect for the specified size.
    @param aFont The font to convert.
    @param aSize The new font size.
    @result The converted font or \c aFont if the conversion failed.
*/
- (CPFont)convertFont:(CPFont)aFont toSize:(float)aSize
{
    var descriptor = [aFont fontDescriptor];

    return [[aFont class] fontWithDescriptor: descriptor size:aSize]
}

- (void)orderFrontFontPanel:(id)sender
{
    [[self fontPanel:YES] orderFront:sender];
}

- (void)modifyFont:(id)sender
{
    _fontAction = [sender tag];
    [self sendAction];

    if (_selectedFont)
        [self setSelectedFont:[self convertFont:_selectedFont] isMultiple:NO];
}

/*!
    This method causes the receiver to send its action message.
    @param sender The object that sent the message. (a Font panel)
*/
- (void)modifyFontViaPanel:(id)sender
{
    _fontAction = CPViaPanelFontAction;
    if (_selectedFont)
        [self setSelectedFont:[self convertFont:_selectedFont] isMultiple:NO];

    [self sendAction];
}

/*!
    Convert a font according to current font changes, provided by the object that initiated the font change.
    @param aFont The font to convert.
    @result The converted font or \c aFont if the conversion failed.
*/
- (CPFont)convertFont:(CPFont)aFont
{
    var newFont = nil;

    switch (_fontAction)
    {
        case CPNoFontChangeAction:
            newFont = aFont;
            break;

        case CPViaPanelFontAction:
            newFont = [[self fontPanel:NO] panelConvertFont:aFont];
            break;

        case CPAddTraitFontAction:
            newFont = aFont;

            if (!_activeChange)
                break;

            var addTraits = [_activeChange valueForKey:@"addTraits"];

            if (addTraits)
                newFont = [self convertFont:aFont toHaveTrait:addTraits];
            break;

        case CPSizeUpFontAction:
            newFont = [self convertFont:aFont toSize:[aFont size] + 1.0]; /* any limit ? */
            break;

        case CPSizeDownFontAction:
            if ([aFont size] > 1)
                newFont = [self convertFont:aFont toSize:[aFont size] - 1.0];
            /* else CPBeep() :-p */
            break;

        default:
            CPLog.trace(@"-[" + [self className] + " " + _cmd + "] unsupported font action: " + _fontAction + " aFont unchanged");
            newFont = aFont;
            break;
    }

    return newFont;
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
