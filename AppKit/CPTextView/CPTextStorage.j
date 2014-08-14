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

@class CPLayoutManager;

CPTextStorageEditedAttributes = 1;
CPTextStorageEditedCharacters = 2;

CPTextStorageWillProcessEditingNotification = @"CPTextStorageWillProcessEditingNotification";
CPTextStorageDidProcessEditingNotification = @"CPTextStorageDidProcessEditingNotification";


/*!
    @ingroup appkit
    @class CPTextStorage
*/
@implementation CPTextStorage : CPMutableAttributedString
{
    CPColor        _foregroundColor @accessors(property=foregroundColor);
    CPFont         _font            @accessors(property=font);
    CPMutableArray _layoutManagers  @accessors(getter=layoutManagers);
    CPRange        _editedRange     @accessors(getter=editedRange);
    id             _delegate        @accessors(property=delegate);
    int            _changeInLength  @accessors(property=changeInLength);
    unsigned       _editedMask      @accessors(property=editedMask);

    int            _editCount; // {begin,end}Editing counter
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

- (void)setDelegate:(id)aDelegate
{
    if (_delegate === aDelegate)
        return;

    var notificationCenter = [CPNotificationCenter defaultCenter];

    if (_delegate && aDelegate === nil)
    {
        [notificationCenter removeObserver:_delegate name:CPTextStorageWillProcessEditingNotification object:self];
        [notificationCenter removeObserver:_delegate name:CPTextStorageDidProcessEditingNotification object:self];
    }

    _delegate = aDelegate;

    if (_delegate)
    {
        if ([_delegate respondsToSelector:@selector(textStorageWillProcessEditing:)])
            [notificationCenter addObserver:_delegate selector:@selector(textStorageWillProcessEditing:) name:CPTextStorageWillProcessEditingNotification object:self];

        if ([_delegate respondsToSelector:@selector(textStorageDidProcessEditing:)])
            [notificationCenter addObserver:_delegate selector:@selector(textStorageDidProcessEditing:) name:CPTextStorageDidProcessEditingNotification object:self];
    }
}


#pragma mark -
#pragma mark Layout manager methods

- (void)addLayoutManager:(CPLayoutManager)aManager
{
    if (![_layoutManagers containsObject:aManager])
    {
        [aManager setTextStorage:self];
        [_layoutManagers addObject:aManager];
    }
}
- (void)removeLayoutManager:(CPLayoutManager)aManager
{
    if ([_layoutManagers containsObject:aManager])
    {
        [aManager setTextStorage:nil];
        [_layoutManagers removeObject:aManager];
    }
}

- (void)invalidateAttributesInRange:(CPRange)aRange
{
    /* FIXME: stub */
}


#pragma mark -
#pragma mark Editing methods

- (void)processEditing
{
    var notificationCenter = [CPNotificationCenter defaultCenter];

    [notificationCenter postNotificationName:CPTextStorageWillProcessEditingNotification
                                      object:self];

    [self invalidateAttributesInRange:[self editedRange]];

    [notificationCenter postNotificationName:CPTextStorageDidProcessEditingNotification
                                      object:self];

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
    if (_editCount == 0) /* used outside a beginEditing/endEditing */
    {
        _editedMask = editedMask;
        _changeInLength = lengthChange;
        aRange.length += lengthChange;
        _editedRange = aRange;
        [self processEditing];
    }
    else
    {
        _editedMask |= editedMask;
        _changeInLength += lengthChange;
        aRange.length += lengthChange;

        if (_editedRange.location === CPNotFound)
            _editedRange = aRange;
        else
            _editedRange = CPUnionRange(_editedRange,aRange);
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

@end