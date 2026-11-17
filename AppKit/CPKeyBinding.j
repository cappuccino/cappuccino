/*
 * CPKeyBinding.j
 * AppKit
 *
 * Created by Nicholas Small.
 * Copyright 2010, 280 North, Inc.
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
@import <Foundation/CPArray.j>

@import "CPCompatibility.j"
@import "CPEvent_Constants.j"
@import "CPText.j"

var isMac = CPBrowserIsOperatingSystem(CPMacOperatingSystem),
    actionModifier = CPPlatformActionKeyMask === CPCommandKeyMask ? @"@" : @"^";

CPStandardKeyBindings = isMac ? {
    @"@.": @"cancelOperation:",
    @"@~$v": @"pasteAsPlainText:",
    @"^a": @"moveToBeginningOfParagraph:",
    @"^$a": @"moveToBeginningOfParagraphAndModifySelection:",
    @"^b": @"moveBackward:",
    @"^$b": @"moveBackwardAndModifySelection:",
    @"^~b": @"moveWordBackward:",
    @"^~$b": @"moveWordBackwardAndModifySelection:",
    @"^d": @"deleteForward:",
    @"^e": @"moveToEndOfParagraph:",
    @"^$e": @"moveToEndOfParagraphAndModifySelection:",
    @"^f": @"moveForward:",
    @"^$f": @"moveForwardAndModifySelection:",
    @"^~f": @"moveWordForward:",
    @"^~$f": @"moveWordForwardAndModifySelection:",
    @"^h": @"deleteBackward:",
    @"^k": @"deleteToEndOfParagraph:",
    @"^l": @"centerSelectionInVisibleArea:",
    @"^n": @"moveDown:",
    @"^$n": @"moveDownAndModifySelection:",
    @"^o": [@"insertNewlineIgnoringFieldEditor:", @"moveBackward:"],
    @"^p": @"moveUp:",
    @"^$p": @"moveUpAndModifySelection:",
    @"^t": @"transpose:",
    @"^v": @"pageDown:",
    @"^$v": @"pageDownAndModifySelection:",
    @"^y": @"yank:"
} : {
    @"^v": @"paste:",
    @"^$v": @"pasteAsPlainText:",
    @"^y": @"redo:"
};

CPStandardKeyBindings[actionModifier + @"a"] = @"selectAll:";

CPStandardKeyBindings[CPNewlineCharacter] = @"insertNewline:";
CPStandardKeyBindings[CPCarriageReturnCharacter] = @"insertNewline:";
CPStandardKeyBindings[CPEnterCharacter] = @"insertNewline:";
CPStandardKeyBindings[@"^" + CPNewlineCharacter] = @"insertLineBreak:";
CPStandardKeyBindings[@"^" + CPCarriageReturnCharacter] = @"insertLineBreak:";
CPStandardKeyBindings[@"^" + CPEnterCharacter] = @"insertLineBreak:";

CPStandardKeyBindings[CPBackspaceCharacter] = @"deleteBackward:";
CPStandardKeyBindings[CPDeleteCharacter] = @"deleteBackward:";
CPStandardKeyBindings[CPDeleteFunctionKey] = @"deleteForward:";

CPStandardKeyBindings[CPTabCharacter] = @"insertTab:";
CPStandardKeyBindings[@"^" + CPTabCharacter] = @"selectNextKeyView:";
CPStandardKeyBindings[@"$" + CPTabCharacter] = @"insertBacktab:";
CPStandardKeyBindings[CPBackTabCharacter] = @"insertBacktab:";
CPStandardKeyBindings[@"^" + CPBackTabCharacter] = @"selectPreviousKeyView:";

CPStandardKeyBindings[CPEscapeFunctionKey] = @"cancelOperation:";

CPStandardKeyBindings[CPLeftArrowFunctionKey] = @"moveLeft:";
CPStandardKeyBindings[@"$" + CPLeftArrowFunctionKey] = @"moveLeftAndModifySelection:";

CPStandardKeyBindings[CPRightArrowFunctionKey] = @"moveRight:";
CPStandardKeyBindings[@"$" + CPRightArrowFunctionKey] = @"moveRightAndModifySelection:";

CPStandardKeyBindings[CPUpArrowFunctionKey] = @"moveUp:";
CPStandardKeyBindings[@"$" + CPUpArrowFunctionKey] = @"moveUpAndModifySelection:";

CPStandardKeyBindings[CPDownArrowFunctionKey] = @"moveDown:";
CPStandardKeyBindings[@"$" + CPDownArrowFunctionKey] = @"moveDownAndModifySelection:";

CPStandardKeyBindings[CPPageUpFunctionKey] = @"scrollPageUp:";
CPStandardKeyBindings[@"$" + CPPageUpFunctionKey] = @"pageUpAndModifySelection:";

CPStandardKeyBindings[CPPageDownFunctionKey] = @"scrollPageDown:";
CPStandardKeyBindings[@"$" + CPPageDownFunctionKey] = @"pageDownAndModifySelection:";

if (isMac)
{
    CPStandardKeyBindings[@"~" + CPNewlineCharacter] = @"insertNewlineIgnoringFieldEditor:";
    CPStandardKeyBindings[@"~" + CPCarriageReturnCharacter] = @"insertNewlineIgnoringFieldEditor:";
    CPStandardKeyBindings[@"~" + CPEnterCharacter] = @"insertNewlineIgnoringFieldEditor:";

    CPStandardKeyBindings[@"~" + CPBackspaceCharacter] = @"deleteWordBackward:";
    CPStandardKeyBindings[@"@" + CPDeleteCharacter] = @"deleteToBeginningOfLine:";
    CPStandardKeyBindings[@"~" + CPDeleteCharacter] = @"deleteWordBackward:";
    CPStandardKeyBindings[@"^" + CPDeleteCharacter] = @"deleteBackwardByDecomposingPreviousCharacter:";
    CPStandardKeyBindings[@"^~" + CPDeleteCharacter] = @"deleteWordBackward:";
    CPStandardKeyBindings[@"~" + CPDeleteFunctionKey] = @"deleteWordForward:";

    CPStandardKeyBindings[@"~" + CPTabCharacter] = @"insertTabIgnoringFieldEditor:";

    CPStandardKeyBindings[@"~" + CPEscapeFunctionKey] = @"complete:";

    CPStandardKeyBindings[CPF5FunctionKey] = @"complete:";

    CPStandardKeyBindings[@"~" + CPLeftArrowFunctionKey] = @"moveWordLeft:";
    CPStandardKeyBindings[@"^" + CPLeftArrowFunctionKey] = @"moveToLeftEndOfLine:";
    CPStandardKeyBindings[@"@" + CPLeftArrowFunctionKey] = @"moveToLeftEndOfLine:";
    CPStandardKeyBindings[@"$~" + CPLeftArrowFunctionKey] = @"moveWordLeftAndModifySelection:";
    CPStandardKeyBindings[@"$^" + CPLeftArrowFunctionKey] = @"moveToLeftEndOfLineAndModifySelection:";
    CPStandardKeyBindings[@"$@" + CPLeftArrowFunctionKey] = @"moveToLeftEndOfLineAndModifySelection:";
    CPStandardKeyBindings[@"@^" + CPLeftArrowFunctionKey] = @"makeBaseWritingDirectionRightToLeft:";
    CPStandardKeyBindings[@"@^~" + CPLeftArrowFunctionKey] = @"makeTextWritingDirectionRightToLeft:";

    CPStandardKeyBindings[@"~" + CPRightArrowFunctionKey] = @"moveWordRight:";
    CPStandardKeyBindings[@"^" + CPRightArrowFunctionKey] = @"moveToRightEndOfLine:";
    CPStandardKeyBindings[@"@" + CPRightArrowFunctionKey] = @"moveToRightEndOfLine:";
    CPStandardKeyBindings[@"$~" + CPRightArrowFunctionKey] = @"moveWordRightAndModifySelection:";
    CPStandardKeyBindings[@"$^" + CPRightArrowFunctionKey] = @"moveToRightEndOfLineAndModifySelection:";
    CPStandardKeyBindings[@"$@" + CPRightArrowFunctionKey] = @"moveToRightEndOfLineAndModifySelection:";
    CPStandardKeyBindings[@"@^" + CPRightArrowFunctionKey] = @"makeBaseWritingDirectionLeftToRight:";
    CPStandardKeyBindings[@"@^~" + CPRightArrowFunctionKey] = @"makeTextWritingDirectionLeftToRight:";

    CPStandardKeyBindings[@"~" + CPUpArrowFunctionKey] = [@"moveBackward:", @"moveToBeginningOfParagraph:"];
    CPStandardKeyBindings[@"^" + CPUpArrowFunctionKey] = @"scrollPageUp:";
    CPStandardKeyBindings[@"@" + CPUpArrowFunctionKey] = @"moveToBeginningOfDocument:";
    CPStandardKeyBindings[@"$~" + CPUpArrowFunctionKey] = @"moveParagraphBackwardAndModifySelection:";
    CPStandardKeyBindings[@"$@" + CPUpArrowFunctionKey] = @"moveToBeginningOfDocumentAndModifySelection:";

    CPStandardKeyBindings[@"~" + CPDownArrowFunctionKey] = [@"moveForward:", @"moveToEndOfParagraph:"];
    CPStandardKeyBindings[@"^" + CPDownArrowFunctionKey] = @"scrollPageDown:";
    CPStandardKeyBindings[@"@" + CPDownArrowFunctionKey] = @"moveToEndOfDocument:";
    CPStandardKeyBindings[@"$~" + CPDownArrowFunctionKey] = @"moveParagraphForwardAndModifySelection:";
    CPStandardKeyBindings[@"$@" + CPDownArrowFunctionKey] = @"moveToEndOfDocumentAndModifySelection:";
    CPStandardKeyBindings[@"@^" + CPDownArrowFunctionKey] = @"makeBaseWritingDirectionNatural:";
    CPStandardKeyBindings[@"@^~" + CPDownArrowFunctionKey] = @"makeTextWritingDirectionNatural:";

    CPStandardKeyBindings[CPHomeFunctionKey] = @"scrollToBeginningOfDocument:";
    CPStandardKeyBindings[@"$" + CPHomeFunctionKey] = @"moveToBeginningOfDocumentAndModifySelection:";

    CPStandardKeyBindings[CPEndFunctionKey] = @"scrollToEndOfDocument:";
    CPStandardKeyBindings[@"$" + CPEndFunctionKey] = @"moveToEndOfDocumentAndModifySelection:";

    CPStandardKeyBindings[@"~" + CPPageUpFunctionKey] = @"pageUp:";

    CPStandardKeyBindings[@"~" + CPPageDownFunctionKey] = @"pageDown:";
}
else
{
    CPStandardKeyBindings[@"^" + CPBackspaceCharacter] = @"deleteWordBackward:";
    CPStandardKeyBindings[@"^" + CPDeleteCharacter] = @"deleteWordBackward:";
    CPStandardKeyBindings[@"^" + CPDeleteFunctionKey] = @"deleteWordForward:";

    CPStandardKeyBindings[@"^" + CPLeftArrowFunctionKey] = @"moveWordLeft:";
    CPStandardKeyBindings[@"^$" + CPLeftArrowFunctionKey] = @"moveWordLeftAndModifySelection:";
    CPStandardKeyBindings[@"^" + CPRightArrowFunctionKey] = @"moveWordRight:";
    CPStandardKeyBindings[@"^$" + CPRightArrowFunctionKey] = @"moveWordRightAndModifySelection:";

    CPStandardKeyBindings[CPHomeFunctionKey] = @"moveToLeftEndOfLine:";
    CPStandardKeyBindings[@"$" + CPHomeFunctionKey] = @"moveToLeftEndOfLineAndModifySelection:";
    CPStandardKeyBindings[@"^" + CPHomeFunctionKey] = @"moveToBeginningOfDocument:";
    CPStandardKeyBindings[@"^$" + CPHomeFunctionKey] = @"moveToBeginningOfDocumentAndModifySelection:";
    CPStandardKeyBindings[CPEndFunctionKey] = @"moveToRightEndOfLine:";
    CPStandardKeyBindings[@"$" + CPEndFunctionKey] = @"moveToRightEndOfLineAndModifySelection:";
    CPStandardKeyBindings[@"^" + CPEndFunctionKey] = @"moveToEndOfDocument:";
    CPStandardKeyBindings[@"^$" + CPEndFunctionKey] = @"moveToEndOfDocumentAndModifySelection:";
}

var CPKeyBindingCache = {};

@implementation CPKeyBinding : CPObject
{
    CPString    _key;
    unsigned    _modifierFlags;

    CPArray     _selectors;

    CPString    _cacheName;
}

+ (void)initialize
{
    if (self !== [CPKeyBinding class])
        return;

    [self createKeyBindingsFromJSObject:CPStandardKeyBindings];
}

+ (void)createKeyBindingsFromJSObject:(JSObject)anObject
{
    var binding;
    for (binding in anObject)
        [self cacheKeyBinding:[[CPKeyBinding alloc] initWithPhysicalKeyString:binding selectors:anObject[binding]]];
}

+ (void)cacheKeyBinding:(CPKeyBinding)aBinding
{
    if (!aBinding)
        return;

    CPKeyBindingCache[[aBinding _cacheName]] = aBinding;
}

+ (CPKeyBinding)keyBindingForKey:(CPString)aKey modifierFlags:(unsigned)aFlag
{
    var tempBinding = [[self alloc] initWithKey:aKey modifierFlags:aFlag selectors:nil];
    return CPKeyBindingCache[[tempBinding _cacheName]];
}

+ (CPArray)selectorsForKey:(CPString)aKey modifierFlags:(unsigned)aFlag
{
    return [[self keyBindingForKey:aKey modifierFlags:aFlag] selectors];
}

- (id)initWithPhysicalKeyString:(CPString)binding selectors:(CPArray)selectors
{
    var components = binding.split(@""),
        modifierFlags = ([components containsObject:@"$"] ? CPShiftKeyMask : 0) |
                        ([components containsObject:@"^"] ? CPControlKeyMask : 0) |
                        ([components containsObject:@"~"] ? CPAlternateKeyMask : 0) |
                        ([components containsObject:@"@"] ? CPCommandKeyMask : 0);

    if (![selectors isKindOfClass:CPArray])
        selectors = [selectors];

    return [self initWithKey:[components lastObject] modifierFlags:modifierFlags selectors:selectors];
}

- (id)initWithKey:(CPString)aKey modifierFlags:(unsigned)aFlag selectors:(CPArray)selectors
{
    self = [super init];

    if (self)
    {
        _key = aKey;
        _modifierFlags = aFlag;

        _selectors = selectors;

        // We normalize our key binding string in order to properly cache it.
        // We want to ensure the modifiers are always in the same order.
        var cacheName = [];

        if (_modifierFlags & CPCommandKeyMask)
            cacheName.push(@"@");
        if (_modifierFlags & CPControlKeyMask)
            cacheName.push(@"^");
        if (_modifierFlags & CPAlternateKeyMask)
            cacheName.push(@"~");
        if (_modifierFlags & CPShiftKeyMask)
            cacheName.push(@"$");

        cacheName.push(_key);

        _cacheName = cacheName.join(@"");
    }

    return self;
}

- (CPString)key
{
    return _key;
}

- (unsigned)modifierFlags
{
    return _modifierFlags;
}

- (CPArray)selectors
{
    return _selectors;
}

- (CPString)_cacheName
{
    return _cacheName;
}

- (BOOL)isEqual:(CPKeyBinding)rhs
{
    return _key === [rhs key] && _modifierFlags === [rhs modifierFlags];
}

- (CPString)description
{
    return [CPString stringWithFormat:@"<KeyBinding string: '%@' modifierFlags: 0x%lx selectors: %@>", _key, _modifierFlags, _selectors];
}

@end
