/*
 * CPText.j
 * AppKit
 *
 * Created by Alexander Ljungberg.
 * Copyright 2010, WireLoad, LLC.
 *
 * additions from
 *
 * Daniel Boehringer on 8/02/2014.
 *  Copyright Daniel Boehringer on 8/02/2014.
 *
 *
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

@import <Foundation/Foundation.j>

@import "CPPasteboard.j"
@import "CPView.j"

@global CPStringPboardType
@class CPAttributedString
@class _CPRTFParser

@protocol CPTextDelegate <CPObject>

- (BOOL)textShouldBeginEditing:(CPText)aTextObject;
- (BOOL)textShouldEndEditing:(CPText)aTextObject;
- (void)textDidBeginEditing:(CPNotification)aNotification;
- (void)textDidChange:(CPNotification)aNotification;
- (void)textDidEndEditing:(CPNotification)aNotification;

@end

CPParagraphSeparatorCharacter   = 0x2029;
CPLineSeparatorCharacter        = 0x2028;
CPEnterCharacter                = "\u0003";
CPBackspaceCharacter            = "\u0008";
CPTabCharacter                  = "\u0009";
CPNewlineCharacter              = "\u000a";
CPFormFeedCharacter             = "\u000c";
CPCarriageReturnCharacter       = "\u000d";
CPBackTabCharacter              = "\u0019";
CPDeleteCharacter               = "\u007f";

@typedef CPTextMovement
CPIllegalTextMovement           = 0;
CPOtherTextMovement             = 0;
CPReturnTextMovement            = 16;
CPTabTextMovement               = 17;
CPBacktabTextMovement           = 18;
CPLeftTextMovement              = 19;
CPRightTextMovement             = 20;
CPUpTextMovement                = 21;
CPDownTextMovement              = 22;
CPCancelTextMovement            = 23;

@typedef CPWritingDirection
CPWritingDirectionNatural       = -1;
CPWritingDirectionLeftToRight   = 0;
CPWritingDirectionRightToLeft   = 1;

@typedef CPTextAlignment
CPLeftTextAlignment             = 0;
CPRightTextAlignment            = 1;
CPCenterTextAlignment           = 2;
CPJustifiedTextAlignment        = 3;
CPNaturalTextAlignment          = 4;

/*
    CPText notifications
*/
CPTextDidBeginEditingNotification = @"CPTextDidBeginEditingNotification";
CPTextDidChangeNotification = @"CPTextDidChangeNotification";
CPTextDidEndEditingNotification = @"CPTextDidEndEditingNotification";

/*
    CPTextView Notifications
*/
CPTextViewDidChangeSelectionNotification        = @"CPTextViewDidChangeSelectionNotification";
CPTextViewDidChangeTypingAttributesNotification = @"CPTextViewDidChangeTypingAttributesNotification";

/*
    FIXME: move these to CPAttributed string
    Make use of attributed keys in AppKit
*/
CPFontAttributeName = @"CPFontAttributeName";
CPForegroundColorAttributeName = @"CPForegroundColorAttributeName";
CPBackgroundColorAttributeName = @"CPBackgroundColorAttributeName";
CPShadowAttributeName = @"CPShadowAttributeName";
CPUnderlineStyleAttributeName = @"CPUnderlineStyleAttributeName";
CPSuperscriptAttributeName = @"CPSuperscriptAttributeName";
CPBaselineOffsetAttributeName = @"CPBaselineOffsetAttributeName";
CPAttachmentAttributeName = @"CPAttachmentAttributeName";
CPLigatureAttributeName = @"CPLigatureAttributeName";
CPKernAttributeName = @"CPKernAttributeName";

@implementation CPText : CPView
{
    BOOL       _isEditable       @accessors(getter=isEditable, setter=setEditable:);
    BOOL       _isSelectable     @accessors(getter=isSelectable, setter=setSelectable:);
    BOOL       _isRichText       @accessors(getter=isRichText, setter=setRichText:);
}

- (void)setSelectable:(BOOL)flag
{
    [self willChangeValueForKey:@"selectable"];
    _isSelectable = flag;
    [self didChangeValueForKey:@"selectable"];

    if (!flag)
        [self setEditable:flag];
}

- (void)setEditable:(BOOL)flag
{
    [self willChangeValueForKey:@"editable"];
    _isEditable = flag;
    [self didChangeValueForKey:@"editable"];

    if (flag)
        [self setSelectable:flag];
}

- (void)changeFont:(id)sender
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (void)copy:(id)sender
{
    var selectedRange = [self selectedRange];

    if (selectedRange.length < 1)
            return;

    var pasteboard = [CPPasteboard generalPasteboard];

    // put plain representation on the pasteboad unconditionally
    [pasteboard declareTypes:[CPStringPboardType] owner:nil];
    [pasteboard setString:[[self stringValue] substringWithRange:selectedRange] forType:CPStringPboardType];
}

- (id)_plainStringForPasting
{
    return [[CPPasteboard generalPasteboard] stringForType:CPStringPboardType];
}

- (id)_stringForPasting
{
    var pasteboard = [CPPasteboard generalPasteboard],
        dataForPasting = [pasteboard stringForType:CPRTFPboardType],
        stringForPasting = [pasteboard stringForType:CPStringPboardType];

    if (dataForPasting || [stringForPasting hasPrefix:"{\\rtf1\\ansi"])
        stringForPasting = [[_CPRTFParser new] parseRTF:dataForPasting ? dataForPasting : stringForPasting];

    if (![self isRichText] && [stringForPasting isKindOfClass:[CPAttributedString class]])
        stringForPasting = stringForPasting._string;

    return stringForPasting;
}

- (void)paste:(id)sender
{
    var stringForPasting = [self _stringForPasting];

    if (stringForPasting)
        [self insertText:stringForPasting];
}

- (void)copyFont:(id)sender
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (void)delete:(id)sender
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (CPFont)font:(CPFont)aFont
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);

    return nil;
}

- (BOOL)isHorizontallyResizable
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);

    return NO;
}

- (BOOL)isRulerVisible
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);

    return NO;
}

- (BOOL)isVerticallyResizable
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);

    return NO;
}

- (CGSize)maxSize
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);

    return CGSizeMake(0,0);
}

- (CGSize)minSize
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
    return CGSizeMake(0,0);
}

- (void)pasteFont:(id)sender
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (void)replaceCharactersInRange:(CPRange)aRange withString:(CPString)aString
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (void)scrollRangeToVisible:(CPRange)aRange
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (void)selectedAll:(id)sender
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (CPRange)selectedRange
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);

    return CPMakeRange(CPNotFound, 0);
}

- (void)setFont:(CPFont)aFont
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (void)setFont:(CPFont)aFont range:(CPRange)aRange
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (void)setHorizontallyResizable:(BOOL)flag
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (void)setMaxSize:(CGSize)aSize
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (void)setMinSize:(CGSize)aSize
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (void)setString:(CPString)aString
{
    [self replaceCharactersInRange:CPMakeRange(0, [[self string] length]) withString:aString];
}

- (void)setUsesFontPanel:(BOOL)flag
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (void)setVerticallyResizable:(BOOL)flag
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (CPString)string
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);

    return nil;
}

- (void)underline:(id)sender
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
}

- (BOOL)usesFontPanel
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);

    return NO;
}

@end

var CPTextViewIsEditableKey = @"CPTextViewIsEditableKey",
    CPTextViewIsSelectableKey = @"CPTextViewIsSelectableKey",
    CPTextViewIsRichTextKey = @"CPTextViewIsRichTextKey";

@implementation CPText (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        [self setSelectable:[aCoder decodeBoolForKey:CPTextViewIsSelectableKey]];
        [self setEditable:[aCoder decodeBoolForKey:CPTextViewIsEditableKey]];
        [self setRichText:[aCoder decodeBoolForKey:CPTextViewIsRichTextKey]];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeBool:_isEditable forKey:CPTextViewIsEditableKey];
    [aCoder encodeBool:_isSelectable forKey:CPTextViewIsSelectableKey];
    [aCoder encodeBool:_isRichText forKey:CPTextViewIsRichTextKey];
}

@end
