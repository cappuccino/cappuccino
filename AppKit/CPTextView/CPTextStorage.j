/*
 * CPTextStorage.j
 * AppKit
 *
 * Created by Emmanuel Maillard on 27/02/2010.
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


@import <Foundation/CPNotificationCenter.j>
@import <Foundation/CPAttributedString.j>

@import "CPText.j"
@import "CPFont.j"

@class CPLayoutManager;

CPTextStorageEditedAttributes = 1;
CPTextStorageEditedCharacters = 2;

CPTextStorageWillProcessEditingNotification = @"CPTextStorageWillProcessEditingNotification";
CPTextStorageDidProcessEditingNotification = @"CPTextStorageDidProcessEditingNotification";

@protocol CPTextStorageDelegate <CPObject>

- (void)textStorageWillProcessEditing:(CPNotification)aNotification;
- (void)textStorageDidProcessEditing:(CPNotification)aNotification;

@end

CPAttachmentCharacter = 65532; // "\ufffc";
_CPAttachmentCharacterAsString = String.fromCharCode(CPAttachmentCharacter);

_CPAttachmentView      = "_CPAttachmentView";
_CPAttachmentInvisible = "_CPAttachmentInvisible";

var CPTextStorageDelegate_textStorageWillProcessEditing_ = 1 << 1,
    CPTextStorageDelegate_textStorageDidProcessEditing_ = 1 << 2;

/*!
    @ingroup appkit
    @class CPTextStorage
*/
@implementation CPTextStorage : CPMutableAttributedString
{
    CPColor                         _foregroundColor @accessors(property=foregroundColor);
    CPFont                          _font            @accessors(property=font);
    CPMutableArray                  _layoutManagers  @accessors(getter=layoutManagers);
    CPRange                         _editedRange     @accessors(getter=editedRange);
    id <CPTextStorageDelegate>      _delegate        @accessors(property=delegate);
    int                             _changeInLength  @accessors(property=changeInLength);
    unsigned                        _editedMask      @accessors(property=editedMask);

    int                             _editCount; // {begin,end}Editing counter
    unsigned                        _implementedDelegateMethods;
}


#pragma mark -
#pragma mark Init methods

- (id)initWithString:(CPString)aString attributes:(CPDictionary)attributes
{
    self = [super initWithString:aString attributes:attributes];

    if (self)
    {
        _layoutManagers = [[CPMutableArray alloc] init];
        _editedRange = CPMakeRange(CPNotFound, 0);
        _changeInLength = 0;
        _editedMask = 0;
    }

    return self;
}

- (id)initWithString:(CPString)aString
{
    return [self initWithString:aString attributes:nil];
}

- (id)init
{
    return [self initWithString:@"" attributes:nil];
}


#pragma mark -
#pragma mark Delegate methods

- (void)setDelegate:(id <CPTextStorageDelegate>)aDelegate
{
    if (_delegate === aDelegate)
        return;

    _implementedDelegateMethods = 0;
    _delegate = aDelegate;

    if (_delegate)
    {
        if ([_delegate respondsToSelector:@selector(textStorageWillProcessEditing:)])
            _implementedDelegateMethods |= CPTextStorageDelegate_textStorageWillProcessEditing_;

        if ([_delegate respondsToSelector:@selector(textStorageDidProcessEditing:)])
            _implementedDelegateMethods |= CPTextStorageDelegate_textStorageDidProcessEditing_;
    }
}


#pragma mark -
#pragma mark Layout manager methods

- (void)addLayoutManager:(CPLayoutManager)aManager
{
    if ([_layoutManagers containsObject:aManager])
        return;

    [aManager setTextStorage:self];
    [_layoutManagers addObject:aManager];
}

- (void)removeLayoutManager:(CPLayoutManager)aManager
{
    if (![_layoutManagers containsObject:aManager])
        return;

    [aManager setTextStorage:nil];
    [_layoutManagers removeObject:aManager];
}

- (void)invalidateAttributesInRange:(CPRange)aRange
{
    /* FIXME: stub */
}


#pragma mark -
#pragma mark Editing methods

- (void)processEditing
{
    [self _sendDelegateWillProcessEditingNotification];
    [self invalidateAttributesInRange:[self editedRange]];
    [self _sendDelegateDidProcessEditingNotification];

    var c = [_layoutManagers count];

    for (var i = 0; i < c; i++)
    {
        [[_layoutManagers objectAtIndex:i] textStorage:self
                                                edited:_editedMask
                                                 range:_editedRange
                                        changeInLength:_changeInLength
                                      invalidatedRange:_editedRange];
    }

    _editedRange.location = CPNotFound;
    _editedMask = 0;
    _changeInLength = 0;
}

- (void)beginEditing
{
    if (_editCount == 0)
        _editedRange = CPMakeRange(CPNotFound, 0);

    _editCount++;
}

- (void)endEditing
{
    _editCount--;

    if (_editCount == 0)
        [self processEditing];
}

- (void)edited:(unsigned)editedMask range:(CPRange)aRange changeInLength:(int)lengthChange
{
    var copyRange = CPMakeRangeCopy(aRange);

    if (_editCount == 0) // used outside a beginEditing/endEditing
    {
        _editedMask = editedMask;
        _changeInLength = lengthChange;
        copyRange.length += lengthChange;
        _editedRange = copyRange;
        [self processEditing];
    }
    else
    {
        _editedMask |= editedMask;
        _changeInLength += lengthChange;
        copyRange.length += lengthChange;

        if (_editedRange.location == CPNotFound)
            _editedRange = copyRange;
        else
            _editedRange = CPUnionRange(_editedRange,copyRange);
    }
}

- (void)removeAttribute:(CPString)anAttribute range:(CPRange)aRange
{
    [self beginEditing];
    [super removeAttribute:anAttribute range:aRange];
    [self edited:CPTextStorageEditedAttributes range:aRange changeInLength:0];
    [self endEditing];
}

- (void)addAttributes:(CPDictionary)aDictionary range:(CPRange)aRange
{
    [self beginEditing];
    [super addAttributes:aDictionary range:aRange];
    [self edited:CPTextStorageEditedAttributes range:aRange changeInLength:0];
    [self endEditing];
}

- (void)deleteCharactersInRange:(CPRange)aRange
{
    [self beginEditing];
    [super deleteCharactersInRange:aRange];
    [self edited:CPTextStorageEditedCharacters range:aRange changeInLength:-aRange.length];
    [self endEditing];
}

- (void)replaceCharactersInRange:(CPRange)aRange withString:(CPString)aString
{
    [self beginEditing];
    [super replaceCharactersInRange:aRange withString:aString];
    [self edited:CPTextStorageEditedCharacters range:aRange changeInLength:([aString length] - aRange.length)];
    [self endEditing];
}

- (void)replaceCharactersInRange:(CPRange)aRange withAttributedString:(CPAttributedString)aString
{
    [self beginEditing];
    [super replaceCharactersInRange:aRange withAttributedString:aString];
    [self edited:(CPTextStorageEditedAttributes | CPTextStorageEditedCharacters) range:aRange changeInLength:([aString length] - aRange.length)];
    [self endEditing];
}

- (CPAttributedString)attributedSubstringFromRange:(CPRange)aRange
{
    if (!aRange.length)
        return [CPAttributedString new];

    return [super attributedSubstringFromRange:aRange];
}

/*!
    Returns an instance of CPTextStorage that contains the provided instance of CPView.
    This can be used to insert arbitrary views into the text. These views are treated as individual characters during editing.
    This works only with views that conform to the CPCoding protocol
*/

+ (id)attributedStringWithAttachment:(CPView)someView
{
    var result = [[self alloc] initWithString:_CPAttachmentCharacterAsString];

    [result setAttributes:@{_CPAttachmentView:someView} range:CPMakeRange(0, 1)];

    return result;
}

@end


@implementation CPTextStorage (CPTextStorageDelegate)

- (void)_sendDelegateWillProcessEditingNotification
{
    if (_implementedDelegateMethods & CPTextStorageDelegate_textStorageWillProcessEditing_)
        [_delegate textStorageWillProcessEditing:[[CPNotification alloc] initWithName:CPTextStorageWillProcessEditingNotification object:self userInfo:nil]];

    [[CPNotificationCenter defaultCenter] postNotificationName:CPTextStorageWillProcessEditingNotification object:self];
}

- (void)_sendDelegateDidProcessEditingNotification
{
    if (_implementedDelegateMethods & CPTextStorageDelegate_textStorageDidProcessEditing_)
        [_delegate textStorageWillProcessEditing:[[CPNotification alloc] initWithName:CPTextStorageDidProcessEditingNotification object:self userInfo:nil]];

    [[CPNotificationCenter defaultCenter] postNotificationName:CPTextStorageDidProcessEditingNotification object:self];
}

@end
