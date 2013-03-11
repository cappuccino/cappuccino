/*
 * NSPredicateEditor.j
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

@import <AppKit/CPPredicateEditor.j>

@implementation CPPredicateEditor (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super NS_initWithCoder:aCoder];

    if (self)
    {
        _allTemplates = [aCoder decodeObjectForKey:@"NSPredicateTemplates"];
    }

    return self;
}

@end

@implementation NSPredicateEditor : CPPredicateEditor
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
    return [CPPredicateEditor class];
}

@end

@implementation CPPredicateEditorRowTemplate (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _templateType = [aCoder decodeIntForKey:@"NSPredicateTemplateType"];
        _predicateOptions = [aCoder decodeIntForKey:@"NSPredicateTemplateOptions"];
        _predicateModifier = [aCoder decodeIntForKey:@"NSPredicateTemplateModifier"];
        _leftAttributeType = [aCoder decodeIntForKey:@"NSPredicateTemplateLeftAttributeType"];
        _rightAttributeType = [aCoder decodeIntForKey:@"NSPredicateTemplateRightAttributeType"];
        _leftIsWildcard = [aCoder decodeBoolForKey:@"NSPredicateTemplateLeftIsWildcard"];
        _rightIsWildcard = [aCoder decodeBoolForKey:@"NSPredicateTemplateRightIsWildcard"];
        _views = [aCoder decodeObjectForKey:@"NSPredicateTemplateViews"];
    }

    return self;
}

@end

@implementation NSPredicateEditorRowTemplate : CPPredicateEditorRowTemplate
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [CPPredicateEditorRowTemplate class];
}

@end
