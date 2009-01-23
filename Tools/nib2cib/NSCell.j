/*
 * NSCell.j
 * nib2cib
 *
 * Portions based on NSCell.m (09/09/2008) in Cocotron (http://www.cocotron.org/)
 * Copyright (c) 2006-2007 Christopher J. W. Lloyd
 *
 * Created by Francisco Tolmasky.
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

@import "NSFont.j"

@implementation NSCell : CPObject
{
    int             _state          @accessors(readonly, getter=state);
    BOOL            _isHighlighted  @accessors(readonly, getter=isHighlighted);
    BOOL            _isEnabled      @accessors(readonly, getter=isEnabled);
    BOOL            _isEditable     @accessors(readonly, getter=isEditable);
    BOOL            _isBordered     @accessors(readonly, getter=isBordered);
    BOOL            _isBezeled      @accessors(readonly, getter=isBezeled);
    BOOL            _isSelectable   @accessors(readonly, getter=isSelectable);
    BOOL            _isScrollable   @accessors(readonly, getter=isScrollable);
    BOOL            _isContinuous   @accessors(readonly, getter=isContinuous);
    BOOL            _wraps          @accessors(readonly, getter=wraps);
    CPTextAlignment _alignment      @accessors(readonly, getter=alignment);
    CPControlSize   _controlSize    @accessors(readonly, getter=controlSize);
    id              _objectValue    @accessors(readonly, getter=objectValue);
    CPFont          _font           @accessors(readonly, getter=font);
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        var flags  = [aCoder decodeIntForKey:@"NSCellFlags"],
            flags2 = [aCoder decodeIntForKey:@"NSCellFlags2"];
            
        _state          = (flags & 0x80000000) ? CPOnState : CPOffState;
        _isHighlighted  = (flags & 0x40000000) ? YES : NO;
        _isEnabled      = (flags & 0x20000000) ? NO : YES;
        _isEditable     = (flags & 0x10000000) ? YES : NO;
        _isBordered     = (flags & 0x00800000) ? YES : NO;
        _isBezeled      = (flags & 0x00400000) ? YES : NO;
        _isSelectable   = (flags & 0x00200000) ? YES : NO;
        _isScrollable   = (flags & 0x00100000) ? YES : NO;
        _isContinuous   = (flags & 0x00080100) ? YES : NO;
        _wraps          = (flags & 0x00100000) ? NO : YES;
        _alignment      = (flags2 & 0x1c000000) >> 26;
        _controlSize    = (flags2 & 0xE0000) >> 17;
                        
        _objectValue    = [aCoder decodeObjectForKey:@"NSContents"];
        _font           = [aCoder decodeObjectForKey:@"NSSupport"];
    }
    
    return self;
}

- (id)replacementObjectForCoder:(CPCoder)aCoder
{
    return nil;
}

- (CPString)stringValue
{
    if ([_objectValue isKindOfClass:[CPString class]])
        return _objectValue;
        
    if ([_objectValue respondsToSelector:@selector(attributedStringValue)])
        return [_objectValue attributedStringValue];
        
    return "";
}

@end


@implementation NSActionCell : NSCell
{
}

@end