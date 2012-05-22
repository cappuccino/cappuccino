/*
 * CPRuleEditorCriterion.j
 * AppKit
 *
 * Created by JC Bordes [jcbordes at gmail dot com] Copyright 2012 JC Bordes
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
@import <AppKit/CPView.j>
@import <AppKit/CPMenuItem.j>

@implementation CPRuleEditorCriterion : CPObject
{
	CPArray _items @accessors(property=items);
	id _displayValue @accessors(property=displayValue);
	int _currentIndex @accessors(property=currentIndex);
	BOOL _hidden @accessors(property=hidden);
}

-(id)init
{
	self=[super init];
	if(!self)
		return nil;

	_items=nil;
	_displayValue=nil;
	_currentIndex=-1;
	_hidden=NO;

	return self;
}

-(id)initWithItems:(CPArray)items displayValue:(id)value
{
	self=[super init];
	if(!self)
		return nil;

	_items=items;
	_displayValue=value;
	_currentIndex=[self isEmpty]?-1:0;

	return self;
}

-(id)currentItem
{
	if(_currentIndex==-1)
		return nil;
		
	var count=_items?[_items count]:0;
	if(!count||_currentIndex>=count)
		return nil;
	return [_items objectAtIndex:_currentIndex];
}

-(BOOL)isEmpty
{
	return !_items||[_items count]==0;
}

-(BOOL)isStandaloneView
{
	return _items&&[_items count]==1&&!([_items[0] isKindOfClass:CPMenuItem]);
}

-(BOOL)isValid
{
	if([self isEmpty])
		return NO;

	if([self isStandaloneView])
		return YES;
	
	var item;
	var count=[_items count];
	for(var i=0;i<count;i++)
	{
		item=_items[i];
		if(!([item isKindOfClass:CPMenuItem]||[item isKindOfClass:CPString]))
			return NO;
	}
	
	return YES;
}

-(BOOL)isMenu
{
	return ![self isStandaloneView]&&[self isValid];
}

-(CPView)standaloneView
{
	if(![self isStandaloneView])
		return nil;
	return _items[0];
}


@end

var ItemsKey=@"items";
var DisplayValueKey=@"displayValue";
var CurrentIndexKey=@"currentIndex";
var HiddenKey=@"hidden";

@implementation CPRuleEditorCriterion(CPCoding)

- (id)initWithCoder:(id)coder
{
    self=[super init];
    if(!self)
    	return nil;

    _items=[coder decodeObjectForKey:ItemsKey];
    _displayValue=[coder decodeObjectForKey:DisplayValueKey];
    _currentIndex=[coder decodeIntForKey:CurrentIndexKey];
    _hidden=[coder decodeBoolForKey:HiddenKey];

    return self;
}

- (void)encodeWithCoder:(id)coder
{
    [coder encodeObject:_items forKey:ItemsKey];
    [coder encodeObject:_displayValue forKey:DisplayValueKey];
    [coder encodeInt:_currentIndex forKey:CurrentIndexKey];
    [coder encodeBool:_hidden forKey:HiddenKey];
}

@end

