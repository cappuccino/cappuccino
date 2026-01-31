/*
 * CPFontPanel.j
 * AppKit
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
    kPreviewHeight = 70,
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
    _availableSizes = [@"9", @"10", @"11", @"12", @"13", @"14", @"18", @"24", @"36", @"48", @"64", @"72", @"96", @"144", @"288"];


/*!
    @ingroup appkit
    @class CPFontPanel
*/
@implementation CPFontPanel : CPPanel
{
    id      _fontBrowser;
    id      _traitBrowser;
    id      _sizeBrowser;
    
    // Preview
    _CPFontPanelPreviewView _previewView;
    
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
    return _sharedFontPanel != nil;
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

- (BOOL)acceptsFirstResponder
{
    return NO;
}

#pragma mark -
#pragma mark Init methods

/*! @ignore */
- (id)init
{
    if (self = [super initWithContentRect:CGRectMake(100, 90, 450, 420) styleMask:(CPTitledWindowMask | CPClosableWindowMask /*| CPResizableWindowMask*/ )])
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
        contentBounds = [contentView bounds];

    [contentView addSubview:_toolbarView];

    // Preview View
    var previewY = kBorderSpacing + kToolbarHeight + kInnerSpacing;
    _previewView = [[_CPFontPanelPreviewView alloc] initWithFrame:CGRectMake(10, previewY, CGRectGetWidth(contentBounds) - 20, kPreviewHeight)];
    [_previewView setAutoresizingMask:CPViewWidthSizable];
    [contentView addSubview:_previewView];

    // Browser Layout Calculations
    var browserY = previewY + kPreviewHeight + 10,
        browserHeight = CGRectGetHeight(contentBounds) - browserY - 10,
        availableWidth = CGRectGetWidth(contentBounds) - 20, // 10px padding L/R
        
        // Define Column Widths
        sizeWidth = 50,
        spacing = 5,
        remainingWidth = availableWidth - sizeWidth - (spacing * 2),
        // Split remaining roughly 60% font name, 40% trait
        fontWidth = Math.floor(remainingWidth * 0.60),
        traitWidth = remainingWidth - fontWidth;

    _fontBrowser = [[CPBrowser alloc] initWithFrame:CGRectMake(10, browserY, fontWidth, browserHeight)];
    _traitBrowser = [[CPBrowser alloc] initWithFrame:CGRectMake(10 + fontWidth + spacing, browserY, traitWidth, browserHeight)];
    _sizeBrowser = [[CPBrowser alloc] initWithFrame:CGRectMake(10 + fontWidth + traitWidth + (spacing * 2), browserY, sizeWidth, browserHeight)];
    
    [_sizeBrowser setAutoresizingMask:CPViewHeightSizable | CPViewMinXMargin];
    [_traitBrowser setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_fontBrowser setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];

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

    if (![textView respondsToSelector:@selector(_attributesForFontPanel)])
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
    
    // Update Preview
    [_previewView setPreviewFont:font];

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
    
    [_previewView setPreviewFont:font];

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
    }
    else if (aBrowser === _traitBrowser)
    {
        _fontChanges = kTypefaceChanged;
    }
    else if (aBrowser === _sizeBrowser)
    {
        _fontChanges = kSizeChanged;
    }
    
    // Apply change immediately to manager (standard behavior)
    [[CPFontManager sharedFontManager] modifyFontViaPanel:self];
    
    // Update our preview manually because convertFont: calls rely on selected rows
    // We construct a temporary font to update the preview view immediately
    var updatedFont = [self panelConvertFont:[_previewView font]];
    if (updatedFont)
         [_previewView setPreviewFont:updatedFont];
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
        return [_availableTraits count];

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

// -----------------------------------------------------------------------------
//  _CPFontPanelPreviewView
//  A helper class to display a font sample with metrics grid
// -----------------------------------------------------------------------------
@implementation _CPFontPanelPreviewView : CPView
{
    CPTextField _sampleText;
    CPColor     _gridColor;
    float       _gridSize;
}

- (id)initWithFrame:(CGRect)aRect
{
    self = [super initWithFrame:aRect];
    if (self)
    {
        [self setBackgroundColor:[CPColor whiteColor]];
        
        _gridColor = [CPColor colorWithHexString:@"e4f4ff"];
        _gridSize = 10.0;
        
        _sampleText = [[CPTextField alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(aRect), CGRectGetHeight(aRect))];
        [_sampleText setStringValue:@"Aa"];
        [_sampleText setAlignment:CPCenterTextAlignment];
        [_sampleText setVerticalAlignment:CPCenterVerticalTextAlignment];
        [_sampleText setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [_sampleText setTextColor:[CPColor blackColor]];
        
        [self addSubview:_sampleText];
    }
    return self;
}

- (void)setPreviewFont:(CPFont)aFont
{
    [_sampleText setFont:aFont];
    [self setNeedsDisplay:YES];
}

- (CPFont)font
{
    return [_sampleText font];
}

- (void)drawRect:(CGRect)dirtyRect
{
    // Draw Grid (from MetricsView inspiration)
    var context = [[CPGraphicsContext currentContext] graphicsPort],
        bounds = [self bounds],
        maxX = CGRectGetMaxX(bounds),
        maxY = CGRectGetMaxY(bounds);

    CGContextSetLineWidth(context, 1.0);
    CGContextSetStrokeColor(context, _gridColor);
    CGContextBeginPath(context);

    for (var y = 0.5; y <= maxY; y += _gridSize)
    {
        CGContextMoveToPoint(context, 0.0, y);
        CGContextAddLineToPoint(context, maxX, y);
    }

    for (var x = 0.5; x <= maxX; x += _gridSize)
    {
        CGContextMoveToPoint(context, x, 0.0);
        CGContextAddLineToPoint(context, x, maxY);
    }
    CGContextStrokePath(context);

    // Draw Baseline/Ascender/Descender (from BaselineView inspiration)
    var font = [_sampleText font];
    if (!font) return;
    
    var ascender = [font ascender],
        descender = [font descender],
        lineHeight = [font defaultLineHeightForFont];
        
    // Calculate the baseline.
    // CPTextField with CPCenterVerticalTextAlignment usually centers the line height.
    // Top of line = midY - (lineHeight / 2.0)
    // Baseline = Top of line + ascender
    var midY = maxY / 2.0,
        baselineY = midY - (lineHeight / 2.0) + ascender; 

    CGContextSetStrokeColor(context, [CPColor redColor]);
    CGContextBeginPath(context);
    
    // Baseline
    CGContextMoveToPoint(context, 0, baselineY);
    CGContextAddLineToPoint(context, maxX, baselineY);
    
    // Ascender Line
    CGContextMoveToPoint(context, 0, baselineY - ascender);
    CGContextAddLineToPoint(context, maxX, baselineY - ascender);
    
    // Descender Line
    CGContextMoveToPoint(context, 0, baselineY - descender);
    CGContextAddLineToPoint(context, maxX, baselineY - descender);

    CGContextStrokePath(context);
}

- (void)mouseDown:(CPEvent)anEvent
{
    var text = prompt("Enter sample text:", [_sampleText stringValue]);
    if (text)
        [_sampleText setStringValue:text];
}

@end


[CPFontManager setFontPanelFactory:[CPFontPanel class]];
