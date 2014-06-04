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
@import "_CPRTFParser.j"
@import "_CPRTFProducer.j"

@global CPStringPboardType
@class CPAttributedString

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
    int _previousSelectionGranularity;
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

    var pasteboard = [CPPasteboard generalPasteboard],
        stringForPasting = [[self stringValue] substringWithRange:selectedRange];

    [pasteboard declareTypes:[CPStringPboardType] owner:nil];

    if ([self isRichText])
    {
       // crude hack to make rich pasting possible in chrome and firefox. this requires a RTF roundtrip, unfortunately
        var richData =  [_CPRTFProducer produceRTF:[[self textStorage] attributedSubstringFromRange:selectedRange] documentAttributes:@{}];
        [pasteboard setString:richData forType:CPStringPboardType];
    }
    else
    {
        [pasteboard setString:stringForPasting forType:CPStringPboardType];
    }
}
- (void)paste:(id)sender
{
    var pasteboard = [CPPasteboard generalPasteboard],
      //  dataForPasting = [pasteboard dataForType:CPRichStringPboardType],
        stringForPasting = [pasteboard stringForType:CPStringPboardType];

    if ([stringForPasting hasPrefix:"{\\rtf1\\ansi"])
        stringForPasting = [[_CPRTFParser new] parseRTF:stringForPasting];

    if (![self isRichText] && [stringForPasting isKindOfClass:[CPAttributedString class]])
        stringForPasting = stringForPasting._string;

    if (_previousSelectionGranularity > 0)
    {
        // FIXME: handle smart pasting
    }

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

- (BOOL)isRichText
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

- (void)setFont:(CPFont)aFont rang:(CPRange)aRange
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