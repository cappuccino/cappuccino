/*
 * NSRuleEditor.j
 * nib2cib
 *
 * Created by cacaodev.
 * Copyright 2010.
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


@import <AppKit/CPRuleEditor.j>
@import <AppKit/CPTextField.j>

@import "NSCell.j"
@import "NSControl.j"

@implementation CPRuleEditor (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        _alignmentGridWidth      = [aCoder decodeFloatForKey:@"NSRuleEditorAlignmentGridWidth"];
        _sliceHeight             = [aCoder decodeDoubleForKey:@"NSRuleEditorSliceHeight"];
        _stringsFilename         = [aCoder decodeObjectForKey:@"NSRuleEditorStringsFileName"];
        _editable                = [aCoder decodeBoolForKey:@"NSRuleEditorEditable"];
        _allowsEmptyCompoundRows = [aCoder decodeBoolForKey:@"NSRuleEditorAllowsEmptyCompoundRows"];
        _disallowEmpty           = [aCoder decodeBoolForKey:@"NSRuleEditorDisallowEmpty"];
        _nestingMode             = [aCoder decodeIntForKey:@"NSRuleEditorNestingMode"];
        _typeKeyPath             = [aCoder decodeObjectForKey:@"NSRuleEditorRowTypeKeyPath"];
        _itemsKeyPath            = [aCoder decodeObjectForKey:@"NSRuleEditorItemsKeyPath"];
        _valuesKeyPath           = [aCoder decodeObjectForKey:@"NSRuleEditorValuesKeyPath"];
        _subrowsArrayKeyPath     = [aCoder decodeObjectForKey:@"NSRuleEditorSubrowsArrayKeyPath"];
        _boundArrayKeyPath       = [aCoder decodeObjectForKey:@"NSRuleEditorBoundArrayKeyPath"];

        //_slicesHolder          = [aCoder decodeObjectForKey:@"NSRuleEditorViewSliceHolder"];
        _boundArrayOwner         = [aCoder decodeObjectForKey:@"NSRuleEditorBoundArrayOwner"];
        _slices                  = [aCoder decodeObjectForKey:@"NSRuleEditorSlices"];
        _ruleDelegate            = [aCoder decodeObjectForKey:@"NSRuleEditorDelegate"];
    }

    return self;
}

@end

@implementation NSRuleEditor : CPRuleEditor
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [self NS_initWithCoder:aCoder];

    if (self)
    {
        var cell = [aCoder decodeObjectForKey:@"NSCell"];
        [self NS_initWithCell:cell];
    }

    return self;
}

- (Class)classForKeyedArchiver
{
    return [CPRuleEditor class];
}

@end

@implementation _NSRuleEditorViewSliceHolder : _CPRuleEditorViewSliceHolder
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPRuleEditorViewSliceHolder class];
}

@end

@implementation _NSRuleEditorViewUnboundRowHolder : _CPRuleEditorViewUnboundRowHolder
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
        boundArray = [aCoder decodeObjectForKey:@"NSBoundArray"];

    return self;
}

- (Class)classForKeyedArchiver
{
    return [_CPRuleEditorViewUnboundRowHolder class];
}

@end
