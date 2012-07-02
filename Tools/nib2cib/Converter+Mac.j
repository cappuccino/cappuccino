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

@implementation Converter (Mac)

- (void)convertedDataFromMacData:(CPData)data resourcesPath:(CPString)aResourcesPath
{
    // Unarchive the NS data
    var unarchiver = [[Nib2CibKeyedUnarchiver alloc] initForReadingWithData:data resourcesPath:aResourcesPath],
        objectData = [unarchiver decodeObjectForKey:@"IB.objectdata"],
        objects = [unarchiver allObjects],
        count = [objects count];

    // Perform a bit of post-processing on fonts and views since all CP views are flipped.
    // It's better to do this here (instead of say, in NSView::initWithCoder:),
    // because at this point all the objects and mappings are stabilized.
    while (count--)
    {
        var object = objects[count];

        [self replaceFontForObject:object];

        if (![object isKindOfClass:[CPView class]])
            continue;

        var superview = [object superview];

        if (!superview || [superview NS_isFlipped])
            continue;

        var superviewHeight = CGRectGetHeight([superview bounds]),
            frame = [object frame];

        [object setFrameOrigin:CGPointMake(CGRectGetMinX(frame), superviewHeight - CGRectGetMaxY(frame))];

        var NS_autoresizingMask = [object autoresizingMask];

        autoresizingMask = NS_autoresizingMask & ~(CPViewMaxYMargin | CPViewMinYMargin);

        if (!(NS_autoresizingMask & (CPViewMaxYMargin | CPViewMinYMargin | CPViewHeightSizable)))
            autoresizingMask |= CPViewMinYMargin;
        else
        {
            if (NS_autoresizingMask & CPViewMaxYMargin)
                autoresizingMask |= CPViewMinYMargin;
            if (NS_autoresizingMask & CPViewMinYMargin)
                autoresizingMask |= CPViewMaxYMargin;
        }

        [object setAutoresizingMask:autoresizingMask];
    }

    // Re-archive the CP data.
    var convertedData = [CPData data],
        archiver = [[CPKeyedArchiver alloc] initForWritingWithMutableData:convertedData];

    [archiver encodeObject:objectData forKey:@"CPCibObjectDataKey"];
    [archiver finishEncoding];

    return convertedData;
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

    if ([object respondsToSelector:@selector(cibFontForNibFont)])
        cibFont = [object cibFontForNibFont];
    else
        cibFont = [NSFont cibFontForNibFont:[object font]];

    if (!cibFont || ![cibFont isEqual:nibFont])
    {
        var source = "";

        // nil cibFont means try to use theme font
        if (!cibFont)
        {
            var bold = [nibFont isBold];

            for (var i = 0; i < themes.length; ++i)
            {
                cibFont = [themes[i] valueForAttributeWithName:@"font" inState:[object themeState] forClass:[object class]];

                if (cibFont)
                {
                    source = " (from " + [themes[i] name] + ")";
                    break;
                }
            }

            // Substitute legacy theme fonts for the current system font
            if (!cibFont || [cibFont familyName] === CPFontDefaultSystemFontFace)
            {
                var size = [cibFont size] || CPFontDefaultSystemFontSize,
                    bold = cibFont ? [cibFont isBold] : bold;

                if (size === CPFontDefaultSystemFontSize)
                    size = [CPFont systemFontSize];

                cibFont = bold ? [CPFont boldSystemFontOfSize:size] : [CPFont systemFontOfSize:size];
            }
        }

        [object setFont:cibFont];

        CPLog.debug("%s: substituted <%s>%s for <%fpx %s>", [object className], cibFont ? [cibFont cssString] : "theme default", source, [nibFont size], [nibFont familyName]);
    }
}

@end
