/*
 * CPFontPanel.j
 * AppKit
 *
 * TODOs:
 *  1. make browser-width for size smaller and fix columns
 *  2. add all the missing features from the MacOS X counterpart (sampleview)
 *
 *
 * Created by Daniel Boehringer on 2/JAN/2014.
 * All modifications copyright Daniel Boehringer 2013.
 * Extensive code formatting and review by Andrew Hankinson
 * Based on original work by
 * Created by Emmanuel Maillard on 06/03/2010.
 * Copyright Emmanuel Maillard 2010.
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


@import "CPPanel.j"
@import "CPColorWell.j"
@import "CPColorPanel.j"
@import "CPBrowser.j"
@import "CPText.j"
@import "CPFontManager.j"


@class CPTextStorage
@class CPLayoutManager
@class CPTextContainer
@class CPFontManager

/*
    Collection indexes
*/
var kTypefaceIndex_Normal = 0,
    kTypefaceIndex_Italic = 1,
    kTypefaceIndex_Bold = 2,
    kTypefaceIndex_BoldItalic = 3,
    kToolbarHeight = 32,
    kBorderSpacing = 6,
    kInnerSpacing = 2,
    kNothingChanged = 0,
    kFontNameChanged = 1,
    kTypefaceChanged = 2,
    kSizeChanged = 3,
    kTextColorChanged = 4,
    kBackgroundColorChanged = 5,
    kUnderlineChanged = 6,
    kWeightChanged = 7,
    _sharedFontPanel;

// FIXME<!> Locale support
var _availableTraits= [@"Normal", @"Italic", @"Bold", @"Bold Italic"],
    _availableSizes = [@"9", @"10", @"11", @"12", @"13", @"14", @"18", @"24", @"36", @"48", @"72", @"96"];


/*!
    @ingroup appkit
    @class CPFontPanel
*/
@implementation CPFontPanel : CPPanel
{
    id      _fontBrowser;
    id      _traitBrowser;
    id      _sizeBrowser;
    CPArray _availableFonts;
    id      _textColorWell;
    CPColor _textColor;
    int     _currentColorButtonTag;
    BOOL    _setupDone;
    int     _fontChanges;
}


#pragma mark -
#pragma mark Class methods

/*!
    Check if the shared Font panel exists.
*/
+ (BOOL)sharedFontPanelExists
{
    return _sharedFontPanel !== nil;
}

/*!
    Return the shared Font panel.
*/
+ (CPFontPanel)sharedFontPanel
{
    if (!_sharedFontPanel)
        _sharedFontPanel = [[CPFontPanel alloc] init];

    return _sharedFontPanel;
}


#pragma mark -
#pragma mark Init methods

/*! @ignore */
- (id)init
{
    if (self = [super initWithContentRect:CGRectMake(100, 90, 450, 394) styleMask:(CPTitledWindowMask | CPClosableWindowMask /*| CPResizableWindowMask*/ )])
    {
        [[self contentView] setBackgroundColor:[CPColor colorWithWhite:0.95 alpha:1.0]];
        [self setTitle:@"Font Panel"];
        [self setLevel:CPFloatingWindowLevel];
        [self setFloatingPanel:YES];
        [self setBecomesKeyOnlyIfNeeded:YES];
        [self setMinSize:CGSizeMake(378, 394)];

        _availableFonts = [[CPFontManager sharedFontManager] availableFonts];
        _textColor      = [CPColor blackColor];
        _setupDone      = NO;
        _fontChanges    = kNothingChanged;
    }

    return self;
}

/*! @ignore */
- (void)_setupToolbarView
{
    _toolbarView = [[CPView alloc] initWithFrame:CGRectMake(0, kBorderSpacing, CGRectGetWidth([self frame]), kToolbarHeight)];
    [_toolbarView setAutoresizingMask:CPViewWidthSizable];

    // Text color
    _textColorWell = [[CPColorWell alloc] initWithFrame:CGRectMake(10, 0, 25, 25)];
    [_textColorWell setColor:_textColor];
    [_toolbarView addSubview:_textColorWell];
}

- (void)_setupBrowser:(CPBrowser)aBrowser
{
    [aBrowser setTarget:self];
    [aBrowser setAction:@selector(browserClicked:)];
    [aBrowser setDoubleAction:@selector(dblClicked:)];
    [aBrowser setAllowsEmptySelection:NO];
    [aBrowser setAllowsMultipleSelection:NO];
    [aBrowser setDelegate:self];
    [[self contentView] addSubview:aBrowser];
}

- (void)_setupContents
{
    if (_setupDone)
        return;

    _setupDone = YES;

    [self _setupToolbarView];

    var contentView = [self contentView],
        label = [CPTextField labelWithTitle:@"Font name"],
        contentBounds = [contentView bounds],
        upperView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(contentBounds), CGRectGetHeight(contentBounds) - (kBorderSpacing + kToolbarHeight + kInnerSpacing))];

    [contentView addSubview:_toolbarView];

    _fontBrowser = [[CPBrowser alloc] initWithFrame:CGRectMake(10,  35, 150, 350)];
    _traitBrowser = [[CPBrowser alloc] initWithFrame:CGRectMake(155, 35, 150, 350)];
    _sizeBrowser = [[CPBrowser alloc] initWithFrame:CGRectMake(300, 35, 140, 350)];

    [self _setupBrowser:_fontBrowser];
    [self _setupBrowser:_traitBrowser];
    [self _setupBrowser:_sizeBrowser];

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textViewDidChangeSelection:)
                                                 name:CPTextViewDidChangeSelectionNotification
                                               object:nil];
}

- (void)textViewDidChangeSelection:(CPNotification)notification
{
   [self _refreshWithTextView:[notification object]];

}

- (void)_refreshWithTextView:(CPTextView)textView
{
    if (![self isVisible])
        return;

    var attribs = [textView _attributesForFontPanel],
        font = [attribs objectForKey:CPFontAttributeName] || [[textView textStorage] font] || [CPFont systemFontOfSize:12.0],
        color = [attribs objectForKey:CPForegroundColorAttributeName];

    if (!font)
        return;

    var trait = kTypefaceIndex_Normal;

    if ([font isItalic] && [font isBold])
        trait = kTypefaceIndex_BoldItalic;
    else if ([font isItalic])
        trait = kTypefaceIndex_Italic;
    else if ([font isBold])
        trait = kTypefaceIndex_Bold;

    [self setCurrentFont:font];
    [self setCurrentTrait:trait];
    [self setCurrentSize:[font size] + ""];  //cast to string

    if (!color)
        return;

    [_textColorWell setColor:color];
}

- (void)orderFront:(id)sender
{
    [self _setupContents];
    [super orderFront:sender];
    [self _refreshWithTextView:[[CPApp keyWindow] firstResponder]];
}

- (void)reloadDefaultFontFamilies
{
    _availableFonts = [[CPFontManager sharedFontManager] availableFonts];
}

- (BOOL)worksWhenModal
{
    return YES;
}

/*!
    @param aFont the font to convert.
    @return The converted font or \c aFont if failed to convert.
*/
- (CPFont)panelConvertFont:(CPFont)aFont
{
    var newFont = aFont,
        index = 0;

    switch (_fontChanges)
    {
        case kFontNameChanged:
            newFont = [CPFont fontWithDescriptor:[[aFont fontDescriptor] fontDescriptorByAddingAttributes:
                      [CPDictionary dictionaryWithObject:[self currentFont] forKey:CPFontNameAttribute]] size:0.0];
            break;

        case kTypefaceChanged:
            index = [self currentTrait];
            if (index == kTypefaceIndex_BoldItalic)
                newFont = [[CPFontManager sharedFontManager] convertFont:aFont toHaveTrait:CPBoldFontMask | CPItalicFontMask];
            else if (index == kTypefaceIndex_Bold)
                newFont = [[CPFontManager sharedFontManager] convertFont:aFont toHaveTrait:CPBoldFontMask];
            else if (index == kTypefaceIndex_Italic)
                newFont = [[CPFontManager sharedFontManager] convertFont:aFont toHaveTrait:CPItalicFontMask];
            else
                newFont = [[CPFontManager sharedFontManager] convertFont:aFont toNotHaveTrait:CPBoldFontMask | CPItalicFontMask];
            break;

        case kSizeChanged:
            newFont = [[CPFontManager sharedFontManager] convertFont:aFont toSize:[self currentSize]];
            break;

         case kNothingChanged:
            break;

        default:
            CPLog.trace(@"FIXME: -[" + [self className] + " " + _cmd + "] unhandled _fontChanges: " + _fontChanges);
            break;
    }

    return newFont;
}

- (void)setCurrentSize:(CGSize)aSize
{
    [_sizeBrowser selectRow:[_availableSizes indexOfObject:aSize]  inColumn:0];
}

- (CPString)currentSize
{
    return [_sizeBrowser selectedItem];
}

- (void)setCurrentFont:(CPFont)aFont
{
    [_fontBrowser selectRow:[_availableFonts indexOfObject:[aFont familyName]]  inColumn:0];
}

- (CPString)currentFont
{
    return [_fontBrowser selectedItem];
}

- (void)setCurrentTrait:(unsigned)aTrait
{
    var row = 0;

    switch (aTrait)
    {
        case kTypefaceIndex_Italic:
            row = 1;
            break;

        case kTypefaceIndex_Bold:
            row = 2;
            break;

        case kTypefaceIndex_BoldItalic:
            row = 3;
            break;
    }

    [_traitBrowser selectRow:row  inColumn:0];
}

// FIXME<!> Locale support
- (unsigned)currentTrait
{
    var sel = [_traitBrowser selectedItem];

    if (sel === "Italic")
        return kTypefaceIndex_Italic;

    if (sel === "Bold")
        return kTypefaceIndex_Bold;

    if (sel === "Bold Italic")
        return kTypefaceIndex_BoldItalic;

    return kTypefaceIndex_Normal;
}

/*!
    Set the selected font in Font panel.
    @param font the selected font
    @param flag if \c the current selection have multiple fonts.
*/
- (void)setPanelFont:(CPFont)font isMultiple:(BOOL)flag
{
    [self _setupContents];

    if ([self currentFont] !== [font familyName])
        [self setCurrentFont:[font familyName]];

    if ([self currentSize] != [font size])
        [self setCurrentSize:[font size]];

    var typefaceIndex = kTypefaceIndex_Normal,
        symbolicTraits = [[font fontDescriptor] symbolicTraits];

    if ((symbolicTraits & CPFontItalicTrait) && (symbolicTraits & CPFontBoldTrait))
        typefaceIndex = kTypefaceIndex_BoldItalic;
    else if (symbolicTraits & CPFontItalicTrait)
        typefaceIndex = kTypefaceIndex_Italic;
    else if (symbolicTraits & CPFontBoldTrait)
        typefaceIndex = kTypefaceIndex_Bold;

    if ([self currentTrait] != typefaceIndex)
        [self setCurrentTrait:typefaceIndex ];

    _fontChanges = kNothingChanged;
}

- (void)changeColor:(id)sender
{
    _textColor = [sender color];
    _fontChanges = kTextColorChanged;
    [[CPFontManager sharedFontManager] modifyFontViaPanel:self];
}

////////////////////////////////////////////////////////////////////
// TODO: ask CPFontManager for traits //
- (void)browserClicked:(id)aBrowser
{
    if (aBrowser === _fontBrowser)
    {
        _fontChanges = kFontNameChanged;
        [[CPFontManager sharedFontManager] modifyFontViaPanel:self];
    }
    else if (aBrowser === _traitBrowser)
    {
        _fontChanges = kTypefaceChanged;
        [[CPFontManager sharedFontManager] modifyFontViaPanel:self];
    }
    else if (aBrowser === _sizeBrowser)
    {
        _fontChanges = kSizeChanged;
        [[CPFontManager sharedFontManager] modifyFontViaPanel:self];
    }
}

- (void)dblClicked:(id)sender
{
    //   alert("DOUBLE");
}

- (id)browser:(id)aBrowser numberOfChildrenOfItem:(id)anItem
{
    if (aBrowser === _fontBrowser)
        return [_availableFonts count];

    if (aBrowser === _traitBrowser)
        return [_availableTraits count]

    return [_availableSizes count]
}

- (id)browser:(id)aBrowser child:(int)index ofItem:(id)anItem
{
    if (aBrowser === _fontBrowser)
        return [_availableFonts objectAtIndex:index];

    if (aBrowser === _traitBrowser)
        return [_availableTraits objectAtIndex:index];

    return [_availableSizes objectAtIndex:index];
}

- (id)browser:(id)aBrowser objectValueForItem:(id)anItem
{
    return anItem;
}

- (BOOL)browser:(id)aBrowser isLeafItem:(id)anItem
{
    return YES;
}

@end

[CPFontManager setFontPanelFactory:[CPFontPanel class]];
