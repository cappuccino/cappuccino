/*
 * Converter+Mac.j
 * nib2cib
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

@import "Converter.j"
@import "Nib2CibKeyedUnarchiver.j"
@import "NSFont.j"

@class Nib2Cib

@implementation Converter (Mac)

- (void)convertedDataFromMacData:(CPData)data
{
    // Unarchive the NS data
    var unarchiver = [[Nib2CibKeyedUnarchiver alloc] initForReadingWithData:data];

    [unarchiver setDelegate:self];

    var objectData = [unarchiver decodeObjectForKey:@"IB.objectdata"],
        objects = [unarchiver allObjects],
        count = [objects count];

    // Perform a bit of post-processing on fonts and views since all CP views are flipped.
    // It's better to do this here (instead of say, in NSView::initWithCoder:),
    // because at this point all the objects and mappings are stabilized.
    while (count--)
    {
        var object = objects[count];

        [self replaceFontForObject:object];

        // Give the object a chance to do any final rewiring before being saved back.
        if ([object respondsToSelector:@selector(awakeFromNib)])
            [object awakeFromNib];
    }

    // Re-archive the CP data.
    var convertedData = [CPData data],
        archiver = [[CPKeyedArchiver alloc] initForWritingWithMutableData:convertedData];

    [archiver encodeObject:objectData forKey:@"CPCibObjectDataKey"];
    [archiver finishEncoding];

    return convertedData;
}

- (Class)unarchiver:(CPKeyedUnarchiver)unarchiver cannotDecodeObjectOfClassName:(CPString)name originalClasses:(CPArray)classNames
{
    // The CPKeyedUnarchiver exception message is accurate, but not that helpful to nib2cib users.
    // We will raise our own exception.

    [CPException raise:CPInvalidUnarchiveOperationException format:@"%@ objects are not supported by nib2cib.", name];
}

- (void)replaceFontForObject:(id)object
{
    if ([object respondsToSelector:@selector(font)] &&
        [object respondsToSelector:@selector(setFont:)])
    {
        var nibFont = [object font];

        if (nibFont)
            [self replaceFont:nibFont forObject:object];
    }
    else if ([object isKindOfClass:[CPView class]])
    {
        /*
            Determine if a view is actually a container for radio buttons.
            They have to be manually iterated over because they are not
            part of the top level object data.
        */
        var subviews = [object subviews],
            count = [subviews count];

        if (count && [subviews[0] isKindOfClass:[CPRadio class]])
        {
            while (count--)
            {
                var radio = subviews[count];

                [self replaceFont:[radio font] forObject:radio];
            }
        }
    }
}

- (void)replaceFont:(CPFont)nibFont forObject:(id)object
{
    var cibFont = nil;

    if ([object respondsToSelector:@selector(cibFontForNibFont:)])
        cibFont = [object cibFontForNibFont:[object font]];
    else
        cibFont = [[object font] cibFontForNibFont];

    if (!cibFont || ![cibFont isEqual:nibFont])
    {
        var source = "";

        // nil cibFont means try to use theme font
        if (!cibFont)
        {
            var bold = [nibFont isBold],
                themes = [[Nib2Cib sharedNib2Cib] themes];

            for (var i = 0; i < themes.length; ++i)
            {
                cibFont = [themes[i] valueForAttributeWithName:@"font" inState:[object themeState] forClass:[object class]];

                if (cibFont)
                {
                    source = " (from " + [themes[i] name] + ")";
                    break;
                }
            }

            if (!cibFont || [cibFont isSystem])
            {
                var size = [cibFont size] || CPFontDefaultSystemFontSize;

                bold = cibFont ? [cibFont isBold] : bold;

                if (size === CPFontDefaultSystemFontSize)
                    size = CPFontCurrentSystemSize;

                cibFont = bold ? [CPFont boldSystemFontOfSize:size] : [CPFont systemFontOfSize:size];
            }
        }

        var replacement = "System " + (bold ? "bold " : "") + ([cibFont isSystemSize] ? "(current size)" : [cibFont size]);

        [object setFont:cibFont];

        CPLog.debug("%s: substituted <%s>%s for <%s>", [object className], replacement || [NSFont descriptorForFont:cibFont], source, [NSFont descriptorForFont:nibFont]);
    }
}

@end
