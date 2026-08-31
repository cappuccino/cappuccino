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

@global document

/*!
    @global
    Font trait mask constants used to specify font characteristics.
*/
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

/* @ignore */
var CPSharedFontManager     = nil,
    CPFontManagerFactory    = nil,
    CPFontPanelFactory      = nil;

/*!
    @global
    Font modification action tags for \c modifyFont:.
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
    @class CPFontManager
    The CPFontManager class manages font conversion, font selection, available fonts detection,
    and interaction with the shared \c CPFontPanel.
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
    Returns the shared font manager for the application, creating it if it does not yet exist.
    @return the shared \c CPFontManager instance
*/
+ (CPFontManager)sharedFontManager
{
    if (!CPSharedFontManager)
        CPSharedFontManager = [[CPFontManagerFactory alloc] init];

    return CPSharedFontManager;
}

// Changing the Default Font Conversion Classes

/*!
    Sets the class used to instantiate the application's shared font manager.
    @param aClass the font manager subclass
*/
+ (void)setFontManagerFactory:(Class)aClass
{
    CPFontManagerFactory = aClass;
}

/*!
    Sets the class used to instantiate the application's font panel.
    @param aClass the font panel subclass
*/
+ (void)setFontPanelFactory:(Class)aClass
{
    CPFontPanelFactory = aClass;
}

/*!
    Initializes a newly allocated font manager instance.
    @return the initialized font manager
*/
- (id)init
{
    if (self = [super init])
    {
        _action = @selector(changeFont:);
    }

    return self;
}

/*!
    Returns an array of names of all fonts available in the current environment.
    @return an array of available font family name strings
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
    Returns whether the font matching the provided name is available.
    @param aFontName the name of the font
    @return \c YES if available, otherwise \c NO
*/
- (CPArray)fontWithNameIsAvailable:(CPString)aFontName
{
    return _CPFontDetectFontAvailable(aFontName);
}

/*!
    Sets the currently selected font and indicates whether multiple fonts are selected.
    @param aFont the selected font
    @param aFlag \c YES if multiple fonts are in the current selection
*/
- (void)setSelectedFont:(CPFont)aFont isMultiple:(BOOL)aFlag
{
    _selectedFont = aFont;
    _multiple = aFlag;

    // TODO Notify CPFontPanel when it exists.
}

/*!
    Returns the currently selected font.
    @return the selected \c CPFont
*/
- (CPFont)selectedFont
{
    return _selectedFont;
}

/*!
    Returns the approximate weight of the given font.
    @param aFont the font to evaluate
    @return the font weight (e.g. 5 for normal, 9 for bold)
*/
- (int)weightOfFont:(CPFont)aFont
{
    return [aFont isBold] ? 9 : 5;
}

/*!
    Returns the trait mask for the specified font.
    @param aFont the font to inspect
    @return the bitmask of font traits
*/
- (CPFontTraitMask)traitsOfFont:(CPFont)aFont
{
    return ([aFont isBold] ? CPBoldFontMask : 0) | ([aFont isItalic] ? CPItalicFontMask : 0);
}

/*!
    Converts a font to use the specified typeface while preserving size and styling traits.
    @param aFont the original font
    @param aTypeface the new typeface name
    @return the converted \c CPFont
*/
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

/*!
    Action method that adds traits to the current font selection.
    @param sender the object triggering the action
*/
- (@action)addFontTrait:(id)sender
{
    var tag = sender;

    if ([sender respondsToSelector:@selector(tag)])
        tag = [sender tag];

    _activeChange = tag == nil ? @{} : @{ @"addTraits": tag };
    _fontAction = CPAddTraitFontAction;

    [self sendAction];
}

/*!
    Sends the font change action message to the target object.
    @return \c YES if the action was sent successfully
*/
- (BOOL)sendAction
{
    return [CPApp sendAction:_action to:_target from:self];
}

/*!
    Returns the shared font panel, optionally creating it if it does not yet exist.
    @param createIt \c YES to create the panel if it does not exist
    @return the \c CPFontPanel instance, or \c nil
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

    if (fontTrait & CPUnboldFontMask)
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
    Converts a font to remove the specified traits while preserving other attributes.
    @param aFont the font to convert
    @param fontTrait the font traits mask to remove
    @return the converted font, or \c aFont if conversion failed
*/
- (CPFont)convertFont:(CPFont)aFont toNotHaveTrait:(CPFontTraitMask)fontTrait
{
    var attributes = [[[aFont fontDescriptor] fontAttributes] copy],
        symbolicTrait = [[aFont fontDescriptor] symbolicTraits];

    if ((fontTrait & CPBoldFontMask) || (fontTrait & CPUnboldFontMask))
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
    Converts a font to have the specified size in points.
    @param aFont the font to convert
    @param aSize the new font size
    @return the converted \c CPFont
*/
- (CPFont)convertFont:(CPFont)aFont toSize:(float)aSize
{
    var descriptor = [aFont fontDescriptor];

    return [[aFont class] fontWithDescriptor:descriptor size:aSize];
}

/*!
    Orders the shared font panel to the front.
    @param sender the object requesting the action
*/
- (void)orderFrontFontPanel:(id)sender
{
    [[self fontPanel:YES] orderFront:sender];
}

/*!
    Modifies the current font according to the sender's tag action.
    @param sender the UI element triggering the modification
*/
- (void)modifyFont:(id)sender
{
    _fontAction = [sender tag];
    [self sendAction];

    if (_selectedFont)
        [self setSelectedFont:[self convertFont:_selectedFont] isMultiple:NO];
}

/*!
    Notifies the receiver that a font modification was made via the font panel and sends the action.
    @param sender the font panel initiating the modification
*/
- (void)modifyFontViaPanel:(id)sender
{
    _fontAction = CPViaPanelFontAction;
    if (_selectedFont)
        [self setSelectedFont:[self convertFont:_selectedFont] isMultiple:NO];

    [self sendAction];
}

/*!
    Converts the provided font according to the current active font action.
    @param aFont the font to convert
    @return the converted \c CPFont
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
            newFont = [self convertFont:aFont toSize:[aFont size] + 1.0];
            break;

        case CPSizeDownFontAction:
            if ([aFont size] > 1)
                newFont = [self convertFont:aFont toSize:[aFont size] - 1.0];
            break;

        default:
            CPLog.trace(@"-[" + [self className] + " " + _cmd + "] unsupported font action: " + _fontAction + " aFont unchanged");
            newFont = aFont;
            break;
    }

    return newFont;
}

@end

/* @ignore */
var _CPFontDetectSpan,
    _CPFontDetectReferenceFonts,
    _CPFontDetectAllFonts = [
        "American Typewriter",
        "Apple Chancery", "Arial", "Arial Black", "Arial Narrow", "Arial Rounded MT Bold", "Arial Unicode MS",
        "Big Caslon", "Bitstream Vera Sans", "Bitstream Vera Sans Mono", "Bitstream Vera Serif",
        "Brush Script MT",
        "Cambria",
        "Caslon", "Castellar", "Cataneo BT", "Centaur", "Century Gothic", "Century Schoolbook", "Century Schoolbook L",
        "Comic Sans", "Comic Sans MS", "Consolas", "Constantia", "Cooper Black", "Copperplate", "Copperplate Gothic Bold", "Copperplate Gothic Light", "Corbel", "Courier", "Courier New",
        "Futura",
        "Geneva", "Georgia", "Georgia Ref", "Geeza Pro", "Gigi", "Gill Sans", "Gill Sans MT", "Gill Sans MT Condensed", "Gill Sans MT Ext Condensed Bold", "Gill Sans Ultra Bold", "Gill Sans Ultra Bold Condensed",
        "Helvetica", "Helvetica Narrow", "Helvetica Neue", "Herculanum", "High Tower Text", "Highlight LET", "Hoefler Text", "Impact", "Imprint MT Shadow",
        "Lucida", "Lucida Bright", "Lucida Calligraphy", "Lucida Console", "Lucida Fax", "Lucida Grande", "Lucida Handwriting", "Lucida Sans", "Lucida Sans Typewriter", "Lucida Sans Unicode",
        "Marker Felt",
        "Microsoft Sans Serif", "Milano LET", "Minion Web", "MisterEarl BT", "Mistral", "Monaco", "Monotype Corsiva", "Monotype.com", "New Century Schoolbook", "New York", "News Gothic MT",
        "Papyrus",
        "Tahoma", "Techno", "Tempus Sans ITC", "Terminal", "Textile", "Times", "Times New Roman", "Tiranti Solid LET", "Trebuchet MS",
        "Verdana", "Verdana Ref",
        "Zapfino"];

/* @ignore */
var _CPFontDetectFontAvailable = function(font)
{
    for (var i = 0; i < _CPFontDetectReferenceFonts.length; i++)
        if (_CPFontDetectCompareFonts(_CPFontDetectReferenceFonts[i], font))
            return true;
    return false;
};

/* @ignore */
var _CPFontDetectCache = {};

/* @ignore */
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

/* @ignore */
var _CPFontDetectPickTwoDifferentFonts = function(candidates)
{
    for (var i = 0; i < candidates.length; i++)
        for (var j = 0; j < i; j++)
            if (_CPFontDetectCompareFonts(candidates[i], candidates[j]))
                return [candidates[i], candidates[j]];
    return [candidates[0]];
};

[CPFontManager setFontManagerFactory:[CPFontManager class]];
